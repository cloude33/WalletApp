import 'package:hive/hive.dart';
import '../models/kmh_transaction.dart';
import '../models/kmh_transaction_type.dart';
import '../services/kmh_box_service.dart';
import '../utils/pagination_helper.dart';

class KmhRepository {
  Box<KmhTransaction> get _box => KmhBoxService.transactionsBox;

  Future<void> addTransaction(KmhTransaction transaction) async {
    await _box.put(transaction.id, transaction);
  }

  Future<List<KmhTransaction>> getTransactions(String walletId) async {
    final transactions = _box.values
        .where((transaction) => transaction.walletId == walletId)
        .toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return transactions;
  }

  Future<PaginationHelper<KmhTransaction>> getTransactionsPaginated(
    String walletId, {
    int itemsPerPage = 20,
  }) async {
    final transactions = await getTransactions(walletId);
    return PaginationHelper(items: transactions, itemsPerPage: itemsPerPage);
  }

  Future<LazyLoadHelper<KmhTransaction>> getTransactionsLazy(
    String walletId, {
    int initialLoadCount = 20,
    int loadMoreCount = 10,
  }) async {
    final transactions = await getTransactions(walletId);
    return LazyLoadHelper(
      items: transactions,
      initialLoadCount: initialLoadCount,
      loadMoreCount: loadMoreCount,
    );
  }

  Future<List<KmhTransaction>> getTransactionsByDateRange(
    String walletId,
    DateTime start,
    DateTime end,
  ) async {
    final transactions = _box.values.where((transaction) {
      return transaction.walletId == walletId &&
          transaction.date.isAfter(
            start.subtract(const Duration(seconds: 1)),
          ) &&
          transaction.date.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return transactions;
  }

  Future<List<KmhTransaction>> getInterestTransactions(String walletId) async {
    final transactions = _box.values.where((transaction) {
      return transaction.walletId == walletId &&
          transaction.type == KmhTransactionType.interest;
    }).toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return transactions;
  }

  Future<double> getTotalWithdrawals(
    String walletId,
    DateTime start,
    DateTime end,
  ) async {
    final transactions = await getTransactionsByDateRange(walletId, start, end);

    return transactions
        .where((t) => t.type == KmhTransactionType.withdrawal)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  Future<double> getTotalDeposits(
    String walletId,
    DateTime start,
    DateTime end,
  ) async {
    final transactions = await getTransactionsByDateRange(walletId, start, end);

    return transactions
        .where((t) => t.type == KmhTransactionType.deposit)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  Future<double> getTotalInterest(
    String walletId,
    DateTime start,
    DateTime end,
  ) async {
    final transactions = await getTransactionsByDateRange(walletId, start, end);

    return transactions
        .where((t) => t.type == KmhTransactionType.interest)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  Future<void> deleteTransactionsByWallet(String walletId) async {
    final transactions = await getTransactions(walletId);
    for (var transaction in transactions) {
      await _box.delete(transaction.id);
    }
  }

  Future<KmhTransaction?> findById(String id) async {
    return _box.get(id);
  }

  Future<void> update(KmhTransaction transaction) async {
    await _box.put(transaction.id, transaction);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<List<KmhTransaction>> findAll() async {
    return _box.values.toList();
  }

  Future<int> countByWalletId(String walletId) async {
    return _box.values.where((t) => t.walletId == walletId).length;
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
