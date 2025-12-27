import 'package:uuid/uuid.dart';
import '../models/reward_points.dart';
import '../models/reward_transaction.dart';
import '../repositories/reward_points_repository.dart';
import '../exceptions/credit_card_exception.dart';
import '../exceptions/error_codes.dart';
import '../utils/service_error_handler.dart';

class RewardPointsService {
  final RewardPointsRepository _repo = RewardPointsRepository();
  final Uuid _uuid = const Uuid();
  static const String _serviceName = 'RewardPointsService';
  Future<RewardPoints> initializeRewards(
    String cardId,
    String rewardType,
    double conversionRate,
  ) async {
    return await ServiceErrorHandler.execute(
      operation: () async {
        ServiceErrorHandler.validateNotEmpty(
          value: cardId,
          fieldName: 'Kart ID',
          errorCode: ErrorCodes.INVALID_CARD_DATA,
        );
        final existing = await _repo.findByCardId(cardId);
        if (existing != null) {
          throw CreditCardException(
            'Bu kart için puan sistemi zaten mevcut',
            ErrorCodes.ALREADY_EXISTS,
            {'cardId': cardId},
          );
        }
        final validTypes = ['bonus', 'worldpuan', 'miles', 'cashback'];
        ServiceErrorHandler.validateInList(
          value: rewardType.toLowerCase(),
          allowedValues: validTypes,
          fieldName: 'Puan türü',
          errorCode: ErrorCodes.INVALID_REWARD_TYPE,
        );
        ServiceErrorHandler.validatePositive(
          value: conversionRate,
          fieldName: 'Dönüşüm oranı',
          errorCode: ErrorCodes.INVALID_CONVERSION_RATE,
        );

        final now = DateTime.now();
        final rewardPoints = RewardPoints(
          id: _uuid.v4(),
          cardId: cardId,
          rewardType: rewardType.toLowerCase(),
          pointsBalance: 0.0,
          conversionRate: conversionRate,
          lastUpdated: now,
          createdAt: now,
        );

        await _repo.save(rewardPoints);
        return rewardPoints;
      },
      serviceName: _serviceName,
      operationName: 'initializeRewards',
      errorCode: ErrorCodes.SAVE_FAILED,
      errorMessage: 'Puan sistemi başlatılamadı',
    );
  }
  Future<void> addPoints(
    String cardId,
    double points,
    String description,
  ) async {
    return await ServiceErrorHandler.execute(
      operation: () async {
        ServiceErrorHandler.validatePositive(
          value: points,
          fieldName: 'Eklenecek puan',
          errorCode: ErrorCodes.INVALID_AMOUNT,
        );
        final rewardPoints = await _repo.findByCardId(cardId);
        if (rewardPoints == null) {
          throw CreditCardException(
            'Bu kart için puan sistemi bulunamadı',
            ErrorCodes.REWARD_POINTS_NOT_FOUND,
            {'cardId': cardId},
          );
        }
        final updatedPoints = rewardPoints.copyWith(
          pointsBalance: rewardPoints.pointsBalance + points,
          lastUpdated: DateTime.now(),
        );

        await _repo.update(updatedPoints);
        final transaction = RewardTransaction(
          id: _uuid.v4(),
          cardId: cardId,
          pointsEarned: points,
          pointsSpent: 0.0,
          description: description,
          transactionDate: DateTime.now(),
          createdAt: DateTime.now(),
        );

        await _repo.addTransaction(transaction);
      },
      serviceName: _serviceName,
      operationName: 'addPoints',
      errorCode: ErrorCodes.UPDATE_FAILED,
      errorMessage: 'Puan eklenemedi',
    );
  }
  Future<void> spendPoints(
    String cardId,
    double points,
    String description,
  ) async {
    return await ServiceErrorHandler.execute(
      operation: () async {
        ServiceErrorHandler.validatePositive(
          value: points,
          fieldName: 'Harcanacak puan',
          errorCode: ErrorCodes.INVALID_AMOUNT,
        );
        final rewardPoints = await _repo.findByCardId(cardId);
        if (rewardPoints == null) {
          throw CreditCardException(
            'Bu kart için puan sistemi bulunamadı',
            ErrorCodes.REWARD_POINTS_NOT_FOUND,
            {'cardId': cardId},
          );
        }
        if (rewardPoints.pointsBalance < points) {
          throw CreditCardException(
            'Yetersiz puan bakiyesi. Mevcut: ${rewardPoints.pointsBalance.toStringAsFixed(2)}, İstenen: ${points.toStringAsFixed(2)}',
            ErrorCodes.INSUFFICIENT_POINTS,
            {
              'cardId': cardId,
              'currentBalance': rewardPoints.pointsBalance,
              'requestedPoints': points,
            },
          );
        }
        final updatedPoints = rewardPoints.copyWith(
          pointsBalance: rewardPoints.pointsBalance - points,
          lastUpdated: DateTime.now(),
        );

        await _repo.update(updatedPoints);
        final transaction = RewardTransaction(
          id: _uuid.v4(),
          cardId: cardId,
          pointsEarned: 0.0,
          pointsSpent: points,
          description: description,
          transactionDate: DateTime.now(),
          createdAt: DateTime.now(),
        );

        await _repo.addTransaction(transaction);
      },
      serviceName: _serviceName,
      operationName: 'spendPoints',
      errorCode: ErrorCodes.UPDATE_FAILED,
      errorMessage: 'Puan harcama işlemi başarısız',
    );
  }
  Future<double> getPointsBalance(String cardId) async {
    final rewardPoints = await _repo.findByCardId(cardId);
    return rewardPoints?.pointsBalance ?? 0.0;
  }
  Future<double> getPointsValueInCurrency(String cardId) async {
    final rewardPoints = await _repo.findByCardId(cardId);
    if (rewardPoints == null) {
      return 0.0;
    }
    return rewardPoints.pointsBalance * rewardPoints.conversionRate;
  }
  Future<double> calculatePointsForTransaction(
    String cardId,
    double amount,
  ) async {
    if (amount <= 0) {
      return 0.0;
    }
    final rewardPoints = await _repo.findByCardId(cardId);
    if (rewardPoints == null) {
      return 0.0;
    }
    return amount;
  }
  Future<void> awardPointsForTransaction(String transactionId) async {
    throw UnimplementedError(
      'This method should be called from CreditCardService after transaction creation',
    );
  }
  Future<List<RewardTransaction>> getPointsHistory(String cardId) async {
    return await _repo.getTransactions(cardId);
  }
  Future<Map<String, dynamic>> getPointsSummary(String cardId) async {
    final rewardPoints = await _repo.findByCardId(cardId);
    if (rewardPoints == null) {
      return {
        'exists': false,
        'balance': 0.0,
        'valueInCurrency': 0.0,
        'rewardType': null,
        'conversionRate': 0.0,
        'totalEarned': 0.0,
        'totalSpent': 0.0,
        'transactionCount': 0,
      };
    }

    final totalEarned = await _repo.getTotalPointsEarned(cardId);
    final totalSpent = await _repo.getTotalPointsSpent(cardId);
    final transactionCount = await _repo.countTransactions(cardId);

    return {
      'exists': true,
      'balance': rewardPoints.pointsBalance,
      'valueInCurrency': rewardPoints.valueInCurrency,
      'rewardType': rewardPoints.rewardType,
      'conversionRate': rewardPoints.conversionRate,
      'totalEarned': totalEarned,
      'totalSpent': totalSpent,
      'transactionCount': transactionCount,
      'lastUpdated': rewardPoints.lastUpdated,
      'createdAt': rewardPoints.createdAt,
    };
  }
  Future<List<RewardTransaction>> getEarningTransactions(String cardId) async {
    return await _repo.getEarningTransactions(cardId);
  }
  Future<List<RewardTransaction>> getSpendingTransactions(String cardId) async {
    return await _repo.getSpendingTransactions(cardId);
  }
  Future<List<RewardTransaction>> getTransactionsByDateRange(
    String cardId,
    DateTime start,
    DateTime end,
  ) async {
    return await _repo.getTransactionsByDateRange(cardId, start, end);
  }
  Future<bool> hasRewardPoints(String cardId) async {
    return await _repo.existsByCardId(cardId);
  }
  Future<RewardPoints?> getRewardPoints(String cardId) async {
    return await _repo.findByCardId(cardId);
  }
  Future<void> updateRewardConfiguration(
    String cardId, {
    String? rewardType,
    double? conversionRate,
  }) async {
    return await ServiceErrorHandler.execute(
      operation: () async {
        final rewardPoints = await _repo.findByCardId(cardId);
        if (rewardPoints == null) {
          throw CreditCardException(
            'Bu kart için puan sistemi bulunamadı',
            ErrorCodes.REWARD_POINTS_NOT_FOUND,
            {'cardId': cardId},
          );
        }
        if (rewardType != null) {
          final validTypes = ['bonus', 'worldpuan', 'miles', 'cashback'];
          ServiceErrorHandler.validateInList(
            value: rewardType.toLowerCase(),
            allowedValues: validTypes,
            fieldName: 'Puan türü',
            errorCode: ErrorCodes.INVALID_REWARD_TYPE,
          );
        }
        if (conversionRate != null) {
          ServiceErrorHandler.validatePositive(
            value: conversionRate,
            fieldName: 'Dönüşüm oranı',
            errorCode: ErrorCodes.INVALID_CONVERSION_RATE,
          );
        }

        final updatedPoints = rewardPoints.copyWith(
          rewardType: rewardType?.toLowerCase(),
          conversionRate: conversionRate,
          lastUpdated: DateTime.now(),
        );

        await _repo.update(updatedPoints);
      },
      serviceName: _serviceName,
      operationName: 'updateRewardConfiguration',
      errorCode: ErrorCodes.UPDATE_FAILED,
      errorMessage: 'Puan yapılandırması güncellenemedi',
    );
  }
  Future<void> deleteRewardPoints(String cardId) async {
    await _repo.deleteTransactionsByCardId(cardId);
    await _repo.deleteByCardId(cardId);
  }
}
