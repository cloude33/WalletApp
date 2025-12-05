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

  // ==================== PUAN YÖNETİMİ ====================

  /// Initialize reward points for a card
  Future<RewardPoints> initializeRewards(
    String cardId,
    String rewardType,
    double conversionRate,
  ) async {
    return await ServiceErrorHandler.execute(
      operation: () async {
        // Validate inputs
        ServiceErrorHandler.validateNotEmpty(
          value: cardId,
          fieldName: 'Kart ID',
          errorCode: ErrorCodes.INVALID_CARD_DATA,
        );

        // Check if rewards already exist for this card
        final existing = await _repo.findByCardId(cardId);
        if (existing != null) {
          throw CreditCardException(
            'Bu kart için puan sistemi zaten mevcut',
            ErrorCodes.ALREADY_EXISTS,
            {'cardId': cardId},
          );
        }

        // Validate reward type
        final validTypes = ['bonus', 'worldpuan', 'miles', 'cashback'];
        ServiceErrorHandler.validateInList(
          value: rewardType.toLowerCase(),
          allowedValues: validTypes,
          fieldName: 'Puan türü',
          errorCode: ErrorCodes.INVALID_REWARD_TYPE,
        );

        // Validate conversion rate
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

  /// Add points to a card
  Future<void> addPoints(
    String cardId,
    double points,
    String description,
  ) async {
    return await ServiceErrorHandler.execute(
      operation: () async {
        // Validate inputs
        ServiceErrorHandler.validatePositive(
          value: points,
          fieldName: 'Eklenecek puan',
          errorCode: ErrorCodes.INVALID_AMOUNT,
        );

        // Get existing reward points
        final rewardPoints = await _repo.findByCardId(cardId);
        if (rewardPoints == null) {
          throw CreditCardException(
            'Bu kart için puan sistemi bulunamadı',
            ErrorCodes.REWARD_POINTS_NOT_FOUND,
            {'cardId': cardId},
          );
        }

        // Update balance
        final updatedPoints = rewardPoints.copyWith(
          pointsBalance: rewardPoints.pointsBalance + points,
          lastUpdated: DateTime.now(),
        );

        await _repo.update(updatedPoints);

        // Create transaction record
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

  /// Spend points from a card
  Future<void> spendPoints(
    String cardId,
    double points,
    String description,
  ) async {
    return await ServiceErrorHandler.execute(
      operation: () async {
        // Validate inputs
        ServiceErrorHandler.validatePositive(
          value: points,
          fieldName: 'Harcanacak puan',
          errorCode: ErrorCodes.INVALID_AMOUNT,
        );

        // Get existing reward points
        final rewardPoints = await _repo.findByCardId(cardId);
        if (rewardPoints == null) {
          throw CreditCardException(
            'Bu kart için puan sistemi bulunamadı',
            ErrorCodes.REWARD_POINTS_NOT_FOUND,
            {'cardId': cardId},
          );
        }

        // Check if sufficient balance
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

        // Update balance
        final updatedPoints = rewardPoints.copyWith(
          pointsBalance: rewardPoints.pointsBalance - points,
          lastUpdated: DateTime.now(),
        );

        await _repo.update(updatedPoints);

        // Create transaction record
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

  /// Get points balance for a card
  Future<double> getPointsBalance(String cardId) async {
    final rewardPoints = await _repo.findByCardId(cardId);
    return rewardPoints?.pointsBalance ?? 0.0;
  }

  /// Get points value in currency for a card
  Future<double> getPointsValueInCurrency(String cardId) async {
    final rewardPoints = await _repo.findByCardId(cardId);
    if (rewardPoints == null) {
      return 0.0;
    }
    return rewardPoints.pointsBalance * rewardPoints.conversionRate;
  }

  // ==================== OTOMATİK PUAN HESAPLAMA ====================

  /// Calculate points for a transaction amount
  Future<double> calculatePointsForTransaction(
    String cardId,
    double amount,
  ) async {
    if (amount <= 0) {
      return 0.0;
    }

    // Get reward points configuration
    final rewardPoints = await _repo.findByCardId(cardId);
    if (rewardPoints == null) {
      return 0.0;
    }

    // Simple calculation: 1 TL = 1 point (can be customized per reward type)
    // For now, we use a 1:1 ratio for all types
    return amount;
  }

  /// Award points for a transaction
  Future<void> awardPointsForTransaction(String transactionId) async {
    // This method would be called after a credit card transaction is created
    // It would look up the transaction, calculate points, and add them
    // For now, this is a placeholder that would be integrated with CreditCardService
    throw UnimplementedError(
      'This method should be called from CreditCardService after transaction creation',
    );
  }

  // ==================== PUAN GEÇMİŞİ VE ÖZET ====================

  /// Get points history for a card
  Future<List<RewardTransaction>> getPointsHistory(String cardId) async {
    return await _repo.getTransactions(cardId);
  }

  /// Get points summary for a card
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

  /// Get earning transactions for a card
  Future<List<RewardTransaction>> getEarningTransactions(String cardId) async {
    return await _repo.getEarningTransactions(cardId);
  }

  /// Get spending transactions for a card
  Future<List<RewardTransaction>> getSpendingTransactions(String cardId) async {
    return await _repo.getSpendingTransactions(cardId);
  }

  /// Get transactions by date range
  Future<List<RewardTransaction>> getTransactionsByDateRange(
    String cardId,
    DateTime start,
    DateTime end,
  ) async {
    return await _repo.getTransactionsByDateRange(cardId, start, end);
  }

  /// Check if reward points exist for a card
  Future<bool> hasRewardPoints(String cardId) async {
    return await _repo.existsByCardId(cardId);
  }

  /// Get reward points for a card
  Future<RewardPoints?> getRewardPoints(String cardId) async {
    return await _repo.findByCardId(cardId);
  }

  /// Update reward points configuration
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

        // Validate reward type if provided
        if (rewardType != null) {
          final validTypes = ['bonus', 'worldpuan', 'miles', 'cashback'];
          ServiceErrorHandler.validateInList(
            value: rewardType.toLowerCase(),
            allowedValues: validTypes,
            fieldName: 'Puan türü',
            errorCode: ErrorCodes.INVALID_REWARD_TYPE,
          );
        }

        // Validate conversion rate if provided
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

  /// Delete reward points for a card
  Future<void> deleteRewardPoints(String cardId) async {
    // Delete all transactions first
    await _repo.deleteTransactionsByCardId(cardId);

    // Delete reward points
    await _repo.deleteByCardId(cardId);
  }
}
