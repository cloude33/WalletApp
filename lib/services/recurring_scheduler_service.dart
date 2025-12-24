import 'dart:async';
import 'package:flutter/foundation.dart';
import 'recurring_transaction_service.dart';
class RecurringSchedulerService {
  final RecurringTransactionService _recurringService;
  Timer? _timer;

  RecurringSchedulerService(this._recurringService);
  Future<void> initialize() async {
    await runNow();
    schedulePeriodicChecks();
  }
  void schedulePeriodicChecks() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(hours: 1), (timer) async {
      await runNow();
    });
  }
  Future<void> cancelSchedule() async {
    _timer?.cancel();
    _timer = null;
  }
  Future<void> runNow() async {
    try {
      await _recurringService.checkAndCreateTransactions();
    } catch (e) {
      debugPrint('Error checking recurring transactions: $e');
    }
  }
  void dispose() {
    _timer?.cancel();
  }
}
