import 'package:uuid/uuid.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../repositories/recurring_transaction_repository.dart';
import 'data_service.dart';
import 'notification_service.dart';

class RecurringTransactionService {
  final RecurringTransactionRepository _repository;
  final DataService _dataService;
  final NotificationService? _notificationService;

  RecurringTransactionService(
    this._repository,
    this._dataService, [
    this._notificationService,
  ]);

  Future<RecurringTransaction> create({
    required String title,
    required double amount,
    required String category,
    String? description,
    required frequency,
    required DateTime startDate,
    DateTime? endDate,
    int? occurrenceCount,
    required bool isIncome,
    bool notificationEnabled = true,
    int? reminderDaysBefore,
  }) async {
    final transaction = RecurringTransaction(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      category: category,
      description: description,
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
      occurrenceCount: occurrenceCount,
      isIncome: isIncome,
      createdAt: DateTime.now(),
      notificationEnabled: notificationEnabled,
      reminderDaysBefore: reminderDaysBefore,
    );

    await _repository.add(transaction);
    return transaction;
  }

  Future<void> update(RecurringTransaction transaction) async {
    await _repository.update(transaction);
  }

  Future<void> delete(String id, {bool deleteCreatedTransactions = false}) async {
    if (deleteCreatedTransactions) {
      // Transaction'ları silmek için data service kullanılabilir
      // Şimdilik sadece recurring transaction'ı siliyoruz
    }
    await _repository.delete(id);
  }

  RecurringTransaction? get(String id) {
    return _repository.get(id);
  }

  List<RecurringTransaction> getAll() {
    return _repository.getAll();
  }

  List<RecurringTransaction> getActive() {
    return _repository.getActive();
  }

  List<RecurringTransaction> getInactive() {
    return _repository.getInactive();
  }

  Future<void> checkAndCreateTransactions() async {
    final now = DateTime.now();
    final dueTransactions = _repository.getDueTransactions(now);

    for (final recurring in dueTransactions) {
      await _createTransactionFromRecurring(recurring);
    }
  }

  Future<void> _createTransactionFromRecurring(RecurringTransaction recurring) async {
    final transaction = Transaction(
      id: const Uuid().v4(),
      type: recurring.isIncome ? 'income' : 'expense',
      amount: recurring.amount,
      category: recurring.category,
      walletId: 'default', // Default wallet kullanılıyor
      date: DateTime.now(),
      description: recurring.description ?? '',
      isIncome: recurring.isIncome,
      recurringTransactionId: recurring.id,
    );

    await _dataService.addTransaction(transaction);

    recurring.lastCreatedDate = DateTime.now();
    recurring.createdCount++;

    if (recurring.shouldDeactivate) {
      recurring.isActive = false;
    }

    await _repository.update(recurring);

    if (recurring.notificationEnabled && _notificationService != null) {
      // Bildirim gönder (NotificationService metoduna göre ayarlanmalı)
      // await _notificationService.showNotification(...);
    }
  }

  Map<String, double> getStatistics() {
    final active = getActive();
    
    double totalIncome = 0;
    double totalExpense = 0;
    
    for (final recurring in active) {
      if (recurring.isIncome) {
        totalIncome += recurring.amount;
      } else {
        totalExpense += recurring.amount;
      }
    }

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'net': totalIncome - totalExpense,
    };
  }

  Map<String, double> getCategoryBreakdown() {
    final active = getActive();
    final Map<String, double> breakdown = {};

    for (final recurring in active) {
      breakdown[recurring.category] = 
          (breakdown[recurring.category] ?? 0) + recurring.amount;
    }

    return breakdown;
  }
}
