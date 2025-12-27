import 'package:hive/hive.dart';
import '../models/credit_card_transaction.dart';
import '../services/credit_card_box_service.dart';

class CreditCardTransactionRepository {
  Box<CreditCardTransaction> get _box => CreditCardBoxService.transactionsBox;
  Future<void> save(CreditCardTransaction transaction) async {
    await _box.put(transaction.id, transaction);
  }
  Future<CreditCardTransaction?> findById(String id) async {
    return _box.get(id);
  }
  Future<List<CreditCardTransaction>> findByCardId(String cardId) async {
    return _box.values
        .where((transaction) => transaction.cardId == cardId)
        .toList();
  }
  Future<List<CreditCardTransaction>> findByDateRange(
    String cardId,
    DateTime start,
    DateTime end,
  ) async {
    return _box.values
        .where(
          (transaction) =>
              transaction.cardId == cardId &&
              transaction.transactionDate.isAfter(
                start.subtract(const Duration(seconds: 1)),
              ) &&
              transaction.transactionDate.isBefore(
                end.add(const Duration(days: 1)),
              ),
        )
        .toList();
  }
  Future<List<CreditCardTransaction>> findActiveInstallments(
    String cardId,
  ) async {
    return _box.values
        .where(
          (transaction) =>
              transaction.cardId == cardId &&
              !transaction.isCompleted &&
              transaction.installmentCount > 1,
        )
        .toList();
  }
  Future<List<CreditCardTransaction>> findAllActiveInstallments() async {
    return _box.values
        .where(
          (transaction) =>
              !transaction.isCompleted && transaction.installmentCount > 1,
        )
        .toList();
  }
  Future<List<CreditCardTransaction>> findByCategory(
    String cardId,
    String category,
  ) async {
    return _box.values
        .where(
          (transaction) =>
              transaction.cardId == cardId && transaction.category == category,
        )
        .toList();
  }
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
  Future<void> update(CreditCardTransaction transaction) async {
    await _box.put(transaction.id, transaction);
  }
  Future<double> getTotalSpending(String cardId) async {
    final transactions = await findByCardId(cardId);
    return transactions.fold<double>(0, (sum, t) => sum + t.amount);
  }
  Future<double> getTotalSpendingInRange(
    String cardId,
    DateTime start,
    DateTime end,
  ) async {
    final transactions = await findByDateRange(cardId, start, end);
    return transactions.fold<double>(0, (sum, t) => sum + t.amount);
  }
  Future<int> countByCardId(String cardId) async {
    return _box.values.where((t) => t.cardId == cardId).length;
  }
  Future<void> clear() async {
    await _box.clear();
  }
}
