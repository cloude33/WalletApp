import 'package:hive/hive.dart';
import '../models/reward_points.dart';
import '../models/reward_transaction.dart';
import '../services/credit_card_box_service.dart';

class RewardPointsRepository {
  Box<RewardPoints> get _pointsBox => CreditCardBoxService.rewardPointsBox;
  Box<RewardTransaction> get _transactionsBox =>
      CreditCardBoxService.rewardTransactionsBox;

  /// Save reward points
  Future<void> save(RewardPoints points) async {
    await _pointsBox.put(points.id, points);
  }

  /// Find reward points by ID
  Future<RewardPoints?> findById(String id) async {
    return _pointsBox.get(id);
  }

  /// Find reward points by card ID
  Future<RewardPoints?> findByCardId(String cardId) async {
    final allPoints = _pointsBox.values.where((p) => p.cardId == cardId);
    return allPoints.isNotEmpty ? allPoints.first : null;
  }

  /// Find all reward points
  Future<List<RewardPoints>> findAll() async {
    return _pointsBox.values.toList();
  }

  /// Update reward points
  Future<void> update(RewardPoints points) async {
    await _pointsBox.put(points.id, points);
  }

  /// Delete reward points
  Future<void> delete(String id) async {
    await _pointsBox.delete(id);
  }

  /// Delete reward points by card ID
  Future<void> deleteByCardId(String cardId) async {
    final points = await findByCardId(cardId);
    if (points != null) {
      await delete(points.id);
    }
  }

  /// Check if reward points exist for a card
  Future<bool> existsByCardId(String cardId) async {
    final points = await findByCardId(cardId);
    return points != null;
  }

  /// Get total points balance for a card
  Future<double> getTotalPointsBalance(String cardId) async {
    final points = await findByCardId(cardId);
    return points?.pointsBalance ?? 0.0;
  }

  /// Get points value in currency for a card
  Future<double> getPointsValueInCurrency(String cardId) async {
    final points = await findByCardId(cardId);
    return points?.valueInCurrency ?? 0.0;
  }

  // ===== Reward Transaction Methods =====

  /// Add a reward transaction
  Future<void> addTransaction(RewardTransaction transaction) async {
    await _transactionsBox.put(transaction.id, transaction);
  }

  /// Find a reward transaction by ID
  Future<RewardTransaction?> findTransactionById(String id) async {
    return _transactionsBox.get(id);
  }

  /// Get all transactions for a card
  Future<List<RewardTransaction>> getTransactions(String cardId) async {
    final transactions = _transactionsBox.values
        .where((t) => t.cardId == cardId)
        .toList();

    // Sort by transaction date (newest first)
    transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    return transactions;
  }

  /// Get earning transactions for a card
  Future<List<RewardTransaction>> getEarningTransactions(String cardId) async {
    final transactions = await getTransactions(cardId);
    return transactions.where((t) => t.isEarning).toList();
  }

  /// Get spending transactions for a card
  Future<List<RewardTransaction>> getSpendingTransactions(
    String cardId,
  ) async {
    final transactions = await getTransactions(cardId);
    return transactions.where((t) => t.isSpending).toList();
  }

  /// Get transactions by date range
  Future<List<RewardTransaction>> getTransactionsByDateRange(
    String cardId,
    DateTime start,
    DateTime end,
  ) async {
    return _transactionsBox.values
        .where(
          (t) =>
              t.cardId == cardId &&
              t.transactionDate.isAfter(
                start.subtract(const Duration(seconds: 1)),
              ) &&
              t.transactionDate.isBefore(end.add(const Duration(days: 1))),
        )
        .toList();
  }

  /// Get transaction by credit card transaction ID
  Future<RewardTransaction?> findTransactionByTransactionId(
    String transactionId,
  ) async {
    final transactions = _transactionsBox.values
        .where((t) => t.transactionId == transactionId);
    return transactions.isNotEmpty ? transactions.first : null;
  }

  /// Get total points earned for a card
  Future<double> getTotalPointsEarned(String cardId) async {
    final transactions = await getTransactions(cardId);
    return transactions.fold<double>(0, (sum, t) => sum + t.pointsEarned);
  }

  /// Get total points spent for a card
  Future<double> getTotalPointsSpent(String cardId) async {
    final transactions = await getTransactions(cardId);
    return transactions.fold<double>(0, (sum, t) => sum + t.pointsSpent);
  }

  /// Delete a reward transaction
  Future<void> deleteTransaction(String id) async {
    await _transactionsBox.delete(id);
  }

  /// Delete all transactions for a card
  Future<void> deleteTransactionsByCardId(String cardId) async {
    final transactions = await getTransactions(cardId);
    for (var transaction in transactions) {
      await deleteTransaction(transaction.id);
    }
  }

  /// Get count of transactions for a card
  Future<int> countTransactions(String cardId) async {
    return _transactionsBox.values.where((t) => t.cardId == cardId).length;
  }

  /// Clear all reward points (for testing)
  Future<void> clearPoints() async {
    await _pointsBox.clear();
  }

  /// Clear all reward transactions (for testing)
  Future<void> clearTransactions() async {
    await _transactionsBox.clear();
  }

  /// Clear all data (for testing)
  Future<void> clearAll() async {
    await clearPoints();
    await clearTransactions();
  }
}
