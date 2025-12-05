import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/credit_card.dart';
import '../models/credit_card_transaction.dart';
import '../repositories/credit_card_repository.dart';
import '../repositories/credit_card_transaction_repository.dart';
import '../repositories/reward_points_repository.dart';
import '../models/reward_points.dart';
import 'package:uuid/uuid.dart';

/// Kredi kartı verilerini yeni alanlara migrate eden servis
/// Mevcut CreditCard ve CreditCardTransaction verilerini yeni özelliklere uygun hale getirir
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

  /// Migration yapılmış mı kontrol et
  Future<bool> isMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationKey) ?? false;
  }

  /// Migration'ı tamamlandı olarak işaretle
  Future<void> markMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, true);
    await prefs.setString(_backupKey, DateTime.now().toIso8601String());
  }

  /// Kredi kartı verilerini migrate et
  Future<MigrationResult> migrateCreditCards() async {
    try {
      // Zaten migrate edilmiş mi kontrol et
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

      // Tüm kartları al
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

      // Her kart için migration yap
      for (var card in cards) {
        bool cardNeedsUpdate = false;

        // Yeni alanlar için varsayılan değerler ata
        if (card.rewardType == null) {
          card = card.copyWith(rewardType: 'bonus'); // Varsayılan: Bonus
          cardNeedsUpdate = true;
        }

        if (card.pointsConversionRate == null) {
          card = card.copyWith(
            pointsConversionRate: 0.01, // 1 puan = 0.01 TL (varsayılan)
          );
          cardNeedsUpdate = true;
        }

        if (card.cashAdvanceRate == null) {
          // Nakit avans faizi genellikle normal faizden %50 daha yüksektir
          final cashAdvanceRate = card.monthlyInterestRate * 1.5;
          card = card.copyWith(cashAdvanceRate: cashAdvanceRate);
          cardNeedsUpdate = true;
        }

        if (card.cashAdvanceLimit == null) {
          // Nakit avans limiti genellikle kredi limitinin %40'ıdır
          final cashAdvanceLimit = card.creditLimit * 0.4;
          card = card.copyWith(cashAdvanceLimit: cashAdvanceLimit);
          cardNeedsUpdate = true;
        }

        // Kart güncellenmişse kaydet
        if (cardNeedsUpdate) {
          await _cardRepository.update(card);
          cardsUpdated++;
          debugPrint('Kart güncellendi: ${card.cardName} (${card.id})');
        }

        // Bu kart için RewardPoints kaydı oluştur (eğer yoksa)
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

        // Bu kartın işlemlerini al ve migrate et
        final transactions = await _transactionRepository.findByCardId(card.id);
        debugPrint('${transactions.length} adet işlem bulundu (${card.cardName})');

        for (var transaction in transactions) {
          bool transactionNeedsUpdate = false;

          // isCashAdvance alanı yoksa false olarak ayarla
          if (!transaction.isCashAdvance) {
            // Bu alan zaten false, güncelleme gerekmez
            // Ancak eski verilerde bu alan olmayabilir, o yüzden kontrol ediyoruz
          }

          // pointsEarned alanı yoksa hesapla
          if (transaction.pointsEarned == null && !transaction.isCashAdvance) {
            // Nakit avans değilse puan hesapla
            // Basit hesaplama: Her 1 TL için 1 puan
            final pointsEarned = transaction.amount;
            transaction = transaction.copyWith(pointsEarned: pointsEarned);
            transactionNeedsUpdate = true;
          }

          // installmentStartDate alanı yoksa ve taksitli ise ayarla
          if (transaction.installmentStartDate == null &&
              transaction.installmentCount > 1) {
            DateTime startDate;
            if (transaction.deferredMonths != null &&
                transaction.deferredMonths! > 0) {
              // Ertelenmiş taksit: işlem tarihinden N ay sonra başlar
              startDate = DateTime(
                transaction.transactionDate.year,
                transaction.transactionDate.month + transaction.deferredMonths!,
                transaction.transactionDate.day,
              );
            } else {
              // Normal taksit: işlem tarihinde başlar
              startDate = transaction.transactionDate;
            }
            transaction = transaction.copyWith(installmentStartDate: startDate);
            transactionNeedsUpdate = true;
          }

          // İşlem güncellenmişse kaydet
          if (transactionNeedsUpdate) {
            await _transactionRepository.update(transaction);
            transactionsUpdated++;
          }
        }
      }

      debugPrint(
        'Migration tamamlandı: $cardsUpdated kart, $transactionsUpdated işlem güncellendi, $rewardPointsCreated reward points oluşturuldu',
      );

      // Migration'ı tamamlandı olarak işaretle
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

  /// Migration'ı geri al (rollback)
  /// NOT: Bu işlem yalnızca test amaçlı kullanılmalıdır
  Future<RollbackResult> rollbackMigration() async {
    try {
      debugPrint('Credit card migration geri alınıyor...');

      int cardsReverted = 0;
      int transactionsReverted = 0;
      int rewardPointsDeleted = 0;

      // Tüm kartları al
      final cards = await _cardRepository.findAll();

      for (var card in cards) {
        bool cardNeedsUpdate = false;

        // Yeni alanları null'a çevir
        if (card.rewardType != null ||
            card.pointsConversionRate != null ||
            card.cashAdvanceRate != null ||
            card.cashAdvanceLimit != null ||
            card.cardImagePath != null ||
            card.iconName != null) {
          // copyWith doesn't work for setting to null, so create a new object
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
            // Set new fields to null
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

        // RewardPoints kayıtlarını sil
        final rewardPoints =
            await _rewardPointsRepository.findByCardId(card.id);
        if (rewardPoints != null) {
          await _rewardPointsRepository.delete(rewardPoints.id);
          rewardPointsDeleted++;
        }

        // İşlemleri geri al
        final transactions = await _transactionRepository.findByCardId(card.id);
        for (var transaction in transactions) {
          bool transactionNeedsUpdate = false;

          if (transaction.pointsEarned != null ||
              transaction.installmentStartDate != null) {
            // copyWith doesn't work for setting to null, so create a new object
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
              // Set new fields to null
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

      // Migration flag'ini sıfırla
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

  /// Migration durumunu kontrol et ve rapor ver
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

/// Migration sonuç modeli
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

/// Rollback sonuç modeli
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

/// Migration durum modeli
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
