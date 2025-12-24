import 'package:hive/hive.dart';
import '../models/reward_points.dart';
import '../models/reward_transaction.dart';
import '../services/credit_card_box_service.dart';

class RewardPointsRepository {
  Box<RewardPoints> get _pointsBox => CreditCardBoxService.rewardPointsBox;
  Box<RewardTransaction> get _transactionsBox =>
      CreditCardBoxService.rewardTransactionsBox;
  Future<void> save(RewardPoints points) async {
    await _pointsBox.put(points.id, points);
  }
  Future<RewardPoints?> findById(String id) async {
    return _pointsBox.get(id);
  }
  Future<RewardPoints?> findByCardId(String cardId) async {
    final allPoints = _pointsBox.values.where((p) => p.cardId == cardId);
    return allPoints.isNotEmpty ? allPoints.first : null;
  }
  Future<List<RewardPoints>> findAll() async {
    return _pointsBox.values.toList();
  }
  Future<void> update(RewardPoints points) async {
    await _pointsBox.put(points.id, points);
  }
  Future<void> delete(String id) async {
    await _pointsBox.delete(id);
  }
  Future<void> deleteByCardId(String cardId) async {
    final points = await findByCardId(cardId);
    if (points != null) {
      await delete(points.id);
    }
  }
  Future<bool> existsByCardId(String cardId) async {
    final points = await findByCardId(cardId);
    return points != null;
  }
  Future<double> getTotalPointsBalance(String cardId) async {
    final points = await findByCardId(cardId);
    return points?.pointsBalance ?? 0.0;
  }
  Future<double> getPointsValueInCurrency(String cardId) async {
    final points = await findByCardId(cardId);
    return points?.valueInCurrency ?? 0.0;
  }
  Future<void> addTransaction(RewardTransaction transaction) async {
    await _transactionsBox.put(transaction.id, transaction);
  }
  Future<RewardTransaction?> findTransactionById(String id) async {
    return _transactionsBox.get(id);
  }
  Future<List<RewardTransaction>> getTransactions(String cardId) async {
    final transactions = _transactionsBox.values
        .where((t) => t.cardId == cardId)
        .toList();
    transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    return transactions;
  }
  Future<List<RewardTransaction>> getEarningTransactions(String cardId) async {
    final transactions = await getTransactions(cardId);
    return transactions.where((t) => t.isEarning).toList();
  }
  Future<List<RewardTransaction>> getSpendingTransactions(
    String cardId,
  ) async {
    final transactions = await getTransactions(cardId);
    return transactions.where((t) => t.isSpending).toList();
  }
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
  Future<RewardTransaction?> findTransactionByTransactionId(
    String transactionId,
  ) async {
    final transactions = _transactionsBox.values
        .where((t) => t.transactionId == transactionId);
    return transactions.isNotEmpty ? transactions.first : null;
  }
  Future<double> getTotalPointsEarned(String cardId) async {
    final transactions = await getTransactions(cardId);
    return transactions.fold<double>(0, (sum, t) => sum + t.pointsEarned);
  }
  Future<double> getTotalPointsSpent(String cardId) async {
    final transactions = await getTransactions(cardId);
    return transactions.fold<double>(0, (sum, t) => sum + t.pointsSpent);
  }
  Future<void> deleteTransaction(String id) async {
    await _transactionsBox.delete(id);
  }
  Future<void> deleteTransactionsByCardId(String cardId) async {
    final transactions = await getTransactions(cardId);
    for (var transaction in transactions) {
      await deleteTransaction(transaction.id);
    }
  }
  Future<int> countTransactions(String cardId) async {
    return _transactionsBox.values.where((t) => t.cardId == cardId).length;
  }
  Future<void> clearPoints() async {
    await _pointsBox.clear();
  }
  Future<void> clearTransactions() async {
    await _transactionsBox.clear();
  }
  Future<void> clearAll() async {
    await clearPoints();
    await clearTransactions();
  }
}
