import 'dart:async';
import 'recurring_transaction_service.dart';

/// Service for scheduling recurring transaction checks
/// Note: Background task scheduling has been simplified.
/// The app will check for recurring transactions when opened.
/// For true background processing, consider implementing platform-specific solutions.
class RecurringSchedulerService {
  final RecurringTransactionService _recurringService;
  Timer? _timer;

  RecurringSchedulerService(this._recurringService);

  /// Initialize the scheduler
  /// This will check for recurring transactions immediately and set up periodic checks
  Future<void> initialize() async {
    // Run initial check
    await runNow();
    
    // Schedule periodic checks while app is running (every hour)
    schedulePeriodicChecks();
  }

  /// Schedule periodic checks while the app is running
  void schedulePeriodicChecks() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(hours: 1), (timer) async {
      await runNow();
    });
  }

  /// Cancel scheduled checks
  Future<void> cancelSchedule() async {
    _timer?.cancel();
    _timer = null;
  }

  /// Run recurring transaction check immediately
  Future<void> runNow() async {
    try {
      await _recurringService.checkAndCreateTransactions();
    } catch (e) {
      print('Error checking recurring transactions: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _timer?.cancel();
  }
}
