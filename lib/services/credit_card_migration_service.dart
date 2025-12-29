import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/credit_card.dart';
import '../models/credit_card_transaction.dart';
import '../repositories/credit_card_repository.dart';
import '../repositories/credit_card_transaction_repository.dart';
import '../repositories/reward_points_repository.dart';
import '../models/reward_points.dart';
import 'package:uuid/uuid.dart';
class CreditCardMigrationService {
  static final CreditCardMigrationService _instance =
      CreditCardMigrationService._internal();
  factory CreditCardMigrationService() => _instance;
  CreditCardMigrationService._internal();

  final CreditCardRepository _cardRepository = CreditCardRepository();
  final CreditCardTransactionRepository _transactionRepository =
      CreditCardTransactionRepository();
  final RewardPointsRepository _rewardPointsRepository =
      RewardPointsRepository();
  final Uuid _uuid = const Uuid();

  static const String _migrationKey = 'credit_card_migration_v1_completed';
  static const String _backupKey = 'credit_card_migration_v1_backup';
  Future<bool> isMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationKey) ?? false;
  }
  Future<void> markMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, true);
    await prefs.setString(_backupKey, DateTime.now().toIso8601String());
  }
  Future<MigrationResult> migrateCreditCards() async {
    try {
      if (await isMigrationCompleted()) {
        debugPrint('Credit card migration zaten tamamlanmış, atlanıyor');
        return MigrationResult(
          success: true,
          cardsUpdated: 0,
          transactionsUpdated: 0,
          rewardPointsCreated: 0,
          message: 'Migration zaten tamamlanmış',
        );
      }

      debugPrint('Credit card migration başlatılıyor...');

      int cardsUpdated = 0;
      int transactionsUpdated = 0;
      int rewardPointsCreated = 0;
      final cards = await _cardRepository.findAll();
      debugPrint('${cards.length} adet kart bulundu');

      if (cards.isEmpty) {
        debugPrint('Migrate edilecek kart bulunamadı');
        await markMigrationCompleted();
        return MigrationResult(
          success: true,
          cardsUpdated: 0,
          transactionsUpdated: 0,
          rewardPointsCreated: 0,
          message: 'Migrate edilecek kart bulunamadı',
        );
      }
      for (var card in cards) {
        bool cardNeedsUpdate = false;
        if (card.rewardType == null) {
          card = card.copyWith(rewardType: 'bonus');
          cardNeedsUpdate = true;
        }

        if (card.pointsConversionRate == null) {
          card = card.copyWith(
            pointsConversionRate: 0.01,
          );
          cardNeedsUpdate = true;
        }

        if (card.cashAdvanceRate == null) {
          final cashAdvanceRate = card.monthlyInterestRate * 1.5;
          card = card.copyWith(cashAdvanceRate: cashAdvanceRate);
          cardNeedsUpdate = true;
        }

        if (card.cashAdvanceLimit == null) {
          final cashAdvanceLimit = card.creditLimit * 0.4;
          card = card.copyWith(cashAdvanceLimit: cashAdvanceLimit);
          cardNeedsUpdate = true;
        }
        if (cardNeedsUpdate) {
          await _cardRepository.update(card);
          cardsUpdated++;
          debugPrint('Kart güncellendi: ${card.cardName} (${card.id})');
        }
        final existingRewardPoints =
            await _rewardPointsRepository.findByCardId(card.id);
        if (existingRewardPoints == null) {
          final rewardPoints = RewardPoints(
            id: _uuid.v4(),
            cardId: card.id,
            rewardType: card.rewardType ?? 'bonus',
            pointsBalance: 0.0,
            conversionRate: card.pointsConversionRate ?? 0.01,
            lastUpdated: DateTime.now(),
            createdAt: DateTime.now(),
          );
          await _rewardPointsRepository.save(rewardPoints);
          rewardPointsCreated++;
          debugPrint('RewardPoints oluşturuldu: ${card.cardName}');
        }
        final transactions = await _transactionRepository.findByCardId(card.id);
        debugPrint('${transactions.length} adet işlem bulundu (${card.cardName})');

        for (var transaction in transactions) {
          bool transactionNeedsUpdate = false;
          if (!transaction.isCashAdvance) {
          }
          if (transaction.pointsEarned == null && !transaction.isCashAdvance) {
            final pointsEarned = transaction.amount;
            transaction = transaction.copyWith(pointsEarned: pointsEarned);
            transactionNeedsUpdate = true;
          }
          if (transaction.installmentStartDate == null &&
              transaction.installmentCount > 1) {
            DateTime startDate;
            if (transaction.deferredMonths != null &&
                transaction.deferredMonths! > 0) {
              startDate = DateTime(
                transaction.transactionDate.year,
                transaction.transactionDate.month + transaction.deferredMonths!,
                transaction.transactionDate.day,
              );
            } else {
              startDate = transaction.transactionDate;
            }
            transaction = transaction.copyWith(installmentStartDate: startDate);
            transactionNeedsUpdate = true;
          }
          if (transactionNeedsUpdate) {
            await _transactionRepository.update(transaction);
            transactionsUpdated++;
          }
        }
      }

      debugPrint(
        'Migration tamamlandı: $cardsUpdated kart, $transactionsUpdated işlem güncellendi, $rewardPointsCreated reward points oluşturuldu',
      );
      await markMigrationCompleted();

      debugPrint('Credit card migration başarıyla tamamlandı!');

      return MigrationResult(
        success: true,
        cardsUpdated: cardsUpdated,
        transactionsUpdated: transactionsUpdated,
        rewardPointsCreated: rewardPointsCreated,
        message: 'Migration başarıyla tamamlandı',
      );
    } catch (e, stackTrace) {
      debugPrint('Migration hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      return MigrationResult(
        success: false,
        cardsUpdated: 0,
        transactionsUpdated: 0,
        rewardPointsCreated: 0,
        message: 'Migration hatası: $e',
        error: e,
      );
    }
  }
  Future<RollbackResult> rollbackMigration() async {
    try {
      debugPrint('Credit card migration geri alınıyor...');

      int cardsReverted = 0;
      int transactionsReverted = 0;
      int rewardPointsDeleted = 0;
      final cards = await _cardRepository.findAll();

      for (var card in cards) {
        bool cardNeedsUpdate = false;
        if (card.rewardType != null ||
            card.pointsConversionRate != null ||
            card.cashAdvanceRate != null ||
            card.cashAdvanceLimit != null ||
            card.cardImagePath != null ||
            card.iconName != null) {
          card = CreditCard(
            id: card.id,
            bankName: card.bankName,
            cardName: card.cardName,
            last4Digits: card.last4Digits,
            creditLimit: card.creditLimit,
            statementDay: card.statementDay,
            dueDateOffset: card.dueDateOffset,
            monthlyInterestRate: card.monthlyInterestRate,
            lateInterestRate: card.lateInterestRate,
            cardColor: card.cardColor,
            createdAt: card.createdAt,
            isActive: card.isActive,
            initialDebt: card.initialDebt,
            cardImagePath: null,
            iconName: null,
            rewardType: null,
            pointsConversionRate: null,
            cashAdvanceRate: null,
            cashAdvanceLimit: null,
          );
          cardNeedsUpdate = true;
        }

        if (cardNeedsUpdate) {
          await _cardRepository.update(card);
          cardsReverted++;
        }
        final rewardPoints =
            await _rewardPointsRepository.findByCardId(card.id);
        if (rewardPoints != null) {
          await _rewardPointsRepository.delete(rewardPoints.id);
          rewardPointsDeleted++;
        }
        final transactions = await _transactionRepository.findByCardId(card.id);
        for (var transaction in transactions) {
          bool transactionNeedsUpdate = false;

          if (transaction.pointsEarned != null ||
              transaction.installmentStartDate != null) {
            transaction = CreditCardTransaction(
              id: transaction.id,
              cardId: transaction.cardId,
              amount: transaction.amount,
              description: transaction.description,
              transactionDate: transaction.transactionDate,
              category: transaction.category,
              installmentCount: transaction.installmentCount,
              installmentsPaid: transaction.installmentsPaid,
              createdAt: transaction.createdAt,
              images: transaction.images,
              deferredMonths: transaction.deferredMonths,
              isCashAdvance: transaction.isCashAdvance,
              installmentStartDate: null,
              pointsEarned: null,
            );
            transactionNeedsUpdate = true;
          }

          if (transactionNeedsUpdate) {
            await _transactionRepository.update(transaction);
            transactionsReverted++;
          }
        }
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_migrationKey);
      await prefs.remove(_backupKey);

      debugPrint(
        'Rollback tamamlandı: $cardsReverted kart, $transactionsReverted işlem geri alındı, $rewardPointsDeleted reward points silindi',
      );

      return RollbackResult(
        success: true,
        cardsReverted: cardsReverted,
        transactionsReverted: transactionsReverted,
        rewardPointsDeleted: rewardPointsDeleted,
        message: 'Rollback başarıyla tamamlandı',
      );
    } catch (e, stackTrace) {
      debugPrint('Rollback hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      return RollbackResult(
        success: false,
        cardsReverted: 0,
        transactionsReverted: 0,
        rewardPointsDeleted: 0,
        message: 'Rollback hatası: $e',
        error: e,
      );
    }
  }
  Future<MigrationStatus> getMigrationStatus() async {
    final isCompleted = await isMigrationCompleted();
    final prefs = await SharedPreferences.getInstance();
    final backupDate = prefs.getString(_backupKey);

    final cards = await _cardRepository.findAll();
    int cardsWithNewFields = 0;
    int cardsWithoutNewFields = 0;

    for (var card in cards) {
      if (card.rewardType != null &&
          card.pointsConversionRate != null &&
          card.cashAdvanceRate != null &&
          card.cashAdvanceLimit != null) {
        cardsWithNewFields++;
      } else {
        cardsWithoutNewFields++;
      }
    }

    return MigrationStatus(
      isCompleted: isCompleted,
      migrationDate: backupDate != null ? DateTime.parse(backupDate) : null,
      totalCards: cards.length,
      cardsWithNewFields: cardsWithNewFields,
      cardsWithoutNewFields: cardsWithoutNewFields,
    );
  }
}
class MigrationResult {
  final bool success;
  final int cardsUpdated;
  final int transactionsUpdated;
  final int rewardPointsCreated;
  final String message;
  final dynamic error;

  MigrationResult({
    required this.success,
    required this.cardsUpdated,
    required this.transactionsUpdated,
    required this.rewardPointsCreated,
    required this.message,
    this.error,
  });

  @override
  String toString() {
    return 'MigrationResult(success: $success, cardsUpdated: $cardsUpdated, '
        'transactionsUpdated: $transactionsUpdated, rewardPointsCreated: $rewardPointsCreated, '
        'message: $message)';
  }
}
class RollbackResult {
  final bool success;
  final int cardsReverted;
  final int transactionsReverted;
  final int rewardPointsDeleted;
  final String message;
  final dynamic error;

  RollbackResult({
    required this.success,
    required this.cardsReverted,
    required this.transactionsReverted,
    required this.rewardPointsDeleted,
    required this.message,
    this.error,
  });

  @override
  String toString() {
    return 'RollbackResult(success: $success, cardsReverted: $cardsReverted, '
        'transactionsReverted: $transactionsReverted, rewardPointsDeleted: $rewardPointsDeleted, '
        'message: $message)';
  }
}
class MigrationStatus {
  final bool isCompleted;
  final DateTime? migrationDate;
  final int totalCards;
  final int cardsWithNewFields;
  final int cardsWithoutNewFields;

  MigrationStatus({
    required this.isCompleted,
    this.migrationDate,
    required this.totalCards,
    required this.cardsWithNewFields,
    required this.cardsWithoutNewFields,
  });

  bool get needsMigration => !isCompleted || cardsWithoutNewFields > 0;

  @override
  String toString() {
    return 'MigrationStatus(isCompleted: $isCompleted, migrationDate: $migrationDate, '
        'totalCards: $totalCards, cardsWithNewFields: $cardsWithNewFields, '
        'cardsWithoutNewFields: $cardsWithoutNewFields, needsMigration: $needsMigration)';
  }
}
