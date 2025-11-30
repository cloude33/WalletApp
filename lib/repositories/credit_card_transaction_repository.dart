import 'package:hive/hive.dart';
import '../models/credit_card_transaction.dart';
import '../services/credit_card_box_service.dart';

class CreditCardTransactionRepository {
  Box<CreditCardTransaction> get _box => CreditCardBoxService.transactionsBox;

  /// Save a transaction
  Future<void> save(CreditCardTransaction transaction) async {
    await _box.put(transaction.id, transaction);
  }

  /// Find a transaction by ID
  Future<CreditCardTransaction?> findById(String id) async {
    return _box.get(id);
  }

  /// Find all transactions for a specific card
  Future<List<CreditCardTransaction>> findByCardId(String cardId) async {
    return _box.values
        .where((transaction) => transaction.cardId == cardId)
        .toList();
  }

  /// Find transactions by date range for a specific card
  Future<List<CreditCardTransaction>> findByDateRange(
    String cardId,
    DateTime start,
    DateTime end,
  ) async {
    return _box.values
        .where((transaction) =>
            transaction.cardId == cardId &&
            transaction.transactionDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
            transaction.transactionDate.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  /// Find active installments for a specific card
  Future<List<CreditCardTransaction>> findActiveInstallments(String cardId) async {
    return _box.values
        .where((transaction) =>
            transaction.cardId == cardId &&
            !transaction.isCompleted &&
            transaction.installmentCount > 1)
        .toList();
  }

  /// Find all active installments across all cards
  Future<List<CreditCardTransaction>> findAllActiveInstallments() async {
    return _box.values
        .where((transaction) =>
            !transaction.isCompleted &&
            transaction.installmentCount > 1)
        .toList();
  }

  /// Find transactions by category for a specific card
  Future<List<CreditCardTransaction>> findByCategory(
    String cardId,
    String category,
  ) async {
    return _box.values
        .where((transaction) =>
            transaction.cardId == cardId &&
            transaction.category == category)
        .toList();
  }

  /// Delete a transaction
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Update a transaction
  Future<void> update(CreditCardTransaction transaction) async {
    await _box.put(transaction.id, transaction);
  }

  /// Get total spending for a card
  Future<double> getTotalSpending(String cardId) async {
    final transactions = await findByCardId(cardId);
    return transactions.fold<double>(0, (sum, t) => sum + t.amount);
  }

  /// Get total spending for a card in a date range
  Future<double> getTotalSpendingInRange(
    String cardId,
    DateTime start,
    DateTime end,
  ) async {
    final transactions = await findByDateRange(cardId, start, end);
    return transactions.fold<double>(0, (sum, t) => sum + t.amount);
  }

  /// Get count of transactions for a card
  Future<int> countByCardId(String cardId) async {
    return _box.values.where((t) => t.cardId == cardId).length;
  }

  /// Clear all transactions (for testing)
  Future<void> clear() async {
    await _box.clear();
  }
}
