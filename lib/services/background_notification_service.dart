import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'enhanced_notification_service.dart';
import 'notification_preferences_service.dart';

/// Background task names
class BackgroundTasks {
  static const String budgetCheck = 'budget_check';
  static const String dailySummary = 'daily_summary';
  static const String weeklySummary = 'weekly_summary';
  static const String billReminders = 'bill_reminders';
  static const String installmentReminders = 'installment_reminders';
}

/// Background notification service for periodic tasks
class BackgroundNotificationService {
  static final BackgroundNotificationService _instance =
      BackgroundNotificationService._internal();
  factory BackgroundNotificationService() => _instance;
  BackgroundNotificationService._internal();

  final EnhancedNotificationService _notificationService =
      EnhancedNotificationService();
  final NotificationPreferencesService _prefsService =
      NotificationPreferencesService();

  /// Initialize background tasks
  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  /// Schedule all background tasks
  Future<void> scheduleAllTasks() async {
    final prefs = await _prefsService.getPreferences();

    // Schedule budget check (every 6 hours)
    if (prefs.budgetAlertsEnabled) {
      await Workmanager().registerPeriodicTask(
        BackgroundTasks.budgetCheck,
        BackgroundTasks.budgetCheck,
        frequency: const Duration(hours: 6),
        constraints: Constraints(
          networkType: NetworkType.not_required,
        ),
      );
    }

    // Schedule daily summary
    if (prefs.dailySummaryEnabled) {
      await Workmanager().registerPeriodicTask(
        BackgroundTasks.dailySummary,
        BackgroundTasks.dailySummary,
        frequency: const Duration(days: 1),
        initialDelay: _calculateInitialDelay(prefs.dailySummaryTime),
        constraints: Constraints(
          networkType: NetworkType.not_required,
        ),
      );
    }

    // Schedule weekly summary (every Monday)
    if (prefs.weeklySummaryEnabled) {
      await Workmanager().registerPeriodicTask(
        BackgroundTasks.weeklySummary,
        BackgroundTasks.weeklySummary,
        frequency: const Duration(days: 7),
        initialDelay: _calculateWeeklyDelay(prefs.weeklySummaryTime),
        constraints: Constraints(
          networkType: NetworkType.not_required,
        ),
      );
    }

    // Schedule bill reminders (daily check)
    if (prefs.billRemindersEnabled) {
      await Workmanager().registerPeriodicTask(
        BackgroundTasks.billReminders,
        BackgroundTasks.billReminders,
        frequency: const Duration(days: 1),
        constraints: Constraints(
          networkType: NetworkType.not_required,
        ),
      );
    }

    // Schedule installment reminders (daily check)
    if (prefs.installmentRemindersEnabled) {
      await Workmanager().registerPeriodicTask(
        BackgroundTasks.installmentReminders,
        BackgroundTasks.installmentReminders,
        frequency: const Duration(days: 1),
        constraints: Constraints(
          networkType: NetworkType.not_required,
        ),
      );
    }
  }

  /// Cancel all background tasks
  Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
  }

  /// Cancel specific task
  Future<void> cancelTask(String taskName) async {
    await Workmanager().cancelByUniqueName(taskName);
  }

  /// Calculate initial delay for daily task
  Duration _calculateInitialDelay(TimeOfDay time) {
    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If scheduled time has passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    return scheduledTime.difference(now);
  }

  /// Calculate initial delay for weekly task (next Monday)
  Duration _calculateWeeklyDelay(TimeOfDay time) {
    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Calculate days until next Monday
    final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
    if (daysUntilMonday == 0 && scheduledTime.isBefore(now)) {
      // If it's Monday but time has passed, schedule for next Monday
      scheduledTime = scheduledTime.add(const Duration(days: 7));
    } else {
      scheduledTime = scheduledTime.add(Duration(days: daysUntilMonday));
    }

    return scheduledTime.difference(now);
  }
}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final notificationService = EnhancedNotificationService();
      final prefsService = NotificationPreferencesService();
      final prefs = await prefsService.getPreferences();

      switch (task) {
        case BackgroundTasks.budgetCheck:
          if (prefs.budgetAlertsEnabled) {
            await notificationService.checkBudgetThresholds();
          }
          break;

        case BackgroundTasks.dailySummary:
          if (prefs.dailySummaryEnabled) {
            await notificationService.generateDailySummary();
          }
          break;

        case BackgroundTasks.weeklySummary:
          if (prefs.weeklySummaryEnabled) {
            await notificationService.generateWeeklySummary();
          }
          break;

        case BackgroundTasks.billReminders:
          if (prefs.billRemindersEnabled) {
            await notificationService.scheduleBillReminders(
              reminderDays: prefs.billReminderDays,
            );
          }
          break;

        case BackgroundTasks.installmentReminders:
          if (prefs.installmentRemindersEnabled) {
            await notificationService.scheduleInstallmentReminders(
              reminderDays: prefs.installmentReminderDays,
            );
          }
          break;
      }

      return Future.value(true);
    } catch (e) {
      debugPrint('Background task error: $e');
      return Future.value(false);
    }
  });
}
