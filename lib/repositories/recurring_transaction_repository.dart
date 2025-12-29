import 'package:hive/hive.dart';
import '../models/recurring_transaction.dart';

class RecurringTransactionRepository {
  static const String _boxName = 'recurring_transactions';
  Box<RecurringTransaction>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<RecurringTransaction>(_boxName);
  }

  Box<RecurringTransaction> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('RecurringTransaction box not initialized');
    }
    return _box!;
  }

  Future<void> add(RecurringTransaction transaction) async {
    await box.put(transaction.id, transaction);
  }

  Future<void> update(RecurringTransaction transaction) async {
    await box.put(transaction.id, transaction);
  }

  Future<void> delete(String id) async {
    await box.delete(id);
  }

  RecurringTransaction? get(String id) {
    return box.get(id);
  }

  List<RecurringTransaction> getAll() {
    return box.values.toList();
  }

  List<RecurringTransaction> getActive() {
    return box.values.where((t) => t.isActive).toList();
  }

  List<RecurringTransaction> getInactive() {
    return box.values.where((t) => !t.isActive).toList();
  }

  List<RecurringTransaction> getDueTransactions(DateTime date) {
    return box.values.where((t) {
      if (!t.isActive) return false;
      final next = t.nextDate;
      if (next == null) return false;
      return next.isBefore(date) || next.isAtSameMomentAs(date);
    }).toList();
  }

  Future<void> clear() async {
    await box.clear();
  }
}
