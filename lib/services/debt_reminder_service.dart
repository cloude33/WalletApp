import 'package:flutter/material.dart';
import '../models/debt.dart';
import '../models/debt_reminder.dart';
import '../services/debt_service.dart';
import '../services/enhanced_notification_service.dart';
import '../utils/notification_id_manager.dart';

class DebtReminderService {
  static final DebtReminderService _instance = DebtReminderService._internal();
  factory DebtReminderService() => _instance;
  DebtReminderService._internal();

  final DebtService _debtService = DebtService();
  final EnhancedNotificationService _notificationService =
      EnhancedNotificationService();

  /// Tüm aktif borç/alacaklar için vade tarihi hatırlatmaları oluştur
  Future<void> scheduleAllDueDateReminders() async {
    final debts = await _debtService.getActiveDebts();

    for (final debt in debts) {
      if (debt.dueDate != null) {
        await scheduleDueDateReminders(debt);
      }
    }
  }

  /// Belirli bir borç/alacak için vade tarihi hatırlatmaları oluştur
  Future<void> scheduleDueDateReminders(Debt debt) async {
    if (debt.dueDate == null || debt.status == DebtStatus.paid) {
      return;
    }

    final now = DateTime.now();
    final dueDate = debt.dueDate!;

    // 3 gün öncesi hatırlatma
    final threeDaysBefore = dueDate.subtract(const Duration(days: 3));
    if (threeDaysBefore.isAfter(now)) {
      await _createReminder(
        debt: debt,
        reminderDate: threeDaysBefore,
        type: ReminderType.dueDateBefore,
        message: _buildReminderMessage(debt, 3),
      );
    }

    // 1 gün öncesi hatırlatma
    final oneDayBefore = dueDate.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(now)) {
      await _createReminder(
        debt: debt,
        reminderDate: oneDayBefore,
        type: ReminderType.dueDateBefore,
        message: _buildReminderMessage(debt, 1),
      );
    }

    // Vade günü hatırlatma
    if (dueDate.isAfter(now)) {
      await _createReminder(
        debt: debt,
        reminderDate: dueDate,
        type: ReminderType.dueDate,
        message: _buildReminderMessage(debt, 0),
      );
    }
  }

  /// Hatırlatma mesajı oluştur
  String _buildReminderMessage(Debt debt, int daysUntilDue) {
    final isLent = debt.type == DebtType.lent;
    final action = isLent ? 'alacağınız' : 'borcunuz';

    if (daysUntilDue == 0) {
      return '${debt.personName} ile $action bugün vadesi doluyor. '
          'Tutar: ₺${debt.remainingAmount.toStringAsFixed(2)}';
    } else if (daysUntilDue == 1) {
      return '${debt.personName} ile $action yarın vadesi doluyor. '
          'Tutar: ₺${debt.remainingAmount.toStringAsFixed(2)}';
    } else {
      return '${debt.personName} ile $action $daysUntilDue gün sonra vadesi doluyor. '
          'Tutar: ₺${debt.remainingAmount.toStringAsFixed(2)}';
    }
  }

  /// Hatırlatma oluştur
  Future<DebtReminder> _createReminder({
    required Debt debt,
    required DateTime reminderDate,
    required ReminderType type,
    required String message,
  }) async {
    return await _debtService.addReminder(
      debtId: debt.id,
      reminderDate: reminderDate,
      message: message,
      type: type,
    );
  }

  /// Vadesi geçmiş borç/alacakları kontrol et ve bildirim gönder
  Future<void> checkOverdueDebts() async {
    final overdueDebts = await _debtService.getOverdueDebts();

    for (final debt in overdueDebts) {
      // Durum güncelle
      if (debt.status != DebtStatus.overdue) {
        await _debtService.updateDebtStatus(debt.id, DebtStatus.overdue);
      }

      // Vadesi geçmiş bildirimi gönder
      await _sendOverdueNotification(debt);
    }
  }

  /// Vadesi geçmiş bildirim gönder
  Future<void> _sendOverdueNotification(Debt debt) async {
    final isLent = debt.type == DebtType.lent;
    final action = isLent ? 'alacağınızın' : 'borcunuzun';
    
    final daysOverdue = DateTime.now().difference(debt.dueDate!).inDays;

    final title = 'Vadesi Geçmiş ${isLent ? 'Alacak' : 'Borç'}!';
    final message = '${debt.personName} ile $action vadesi $daysOverdue gün önce doldu. '
        'Tutar: ₺${debt.remainingAmount.toStringAsFixed(2)}';

    // Bildirim gönder (mevcut notification service kullanarak)
    // Bu kısım enhanced_notification_service ile entegre edilecek
    debugPrint('Overdue notification: $title - $message');
  }

  /// Günlük hatırlatma kontrolü (background task için)
  Future<void> dailyReminderCheck() async {
    // Vadesi geçmiş kontrol
    await checkOverdueDebts();

    // Bugünkü hatırlatmaları kontrol
    await _checkTodayReminders();

    // Yeni vade tarihi hatırlatmaları oluştur
    await scheduleAllDueDateReminders();
  }

  /// Bugünkü hatırlatmaları kontrol et
  Future<void> _checkTodayReminders() async {
    final debts = await _debtService.getActiveDebts();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final debt in debts) {
      final reminders = await _debtService.getReminders(debt.id);

      for (final reminder in reminders) {
        if (reminder.status == ReminderStatus.pending) {
          final reminderDay = DateTime(
            reminder.reminderDate.year,
            reminder.reminderDate.month,
            reminder.reminderDate.day,
          );

          if (reminderDay.isAtSameMomentAs(today) ||
              reminderDay.isBefore(today)) {
            await _sendReminderNotification(debt, reminder);
          }
        }
      }
    }
  }

  /// Hatırlatma bildirimi gönder
  Future<void> _sendReminderNotification(
      Debt debt, DebtReminder reminder) async {
    final isLent = debt.type == DebtType.lent;
    final title = isLent ? 'Alacak Hatırlatması' : 'Borç Hatırlatması';

    // Bildirim gönder
    debugPrint('Reminder notification: $title - ${reminder.message}');

    // Hatırlatma durumunu güncelle
    // Bu kısım implement edilecek
  }

  /// Özel hatırlatma oluştur
  Future<DebtReminder> createCustomReminder({
    required String debtId,
    required DateTime reminderDate,
    required String message,
    RecurrenceFrequency? recurrenceFrequency,
    int? recurrenceInterval,
    int? maxRecurrences,
  }) async {
    return await _debtService.addReminder(
      debtId: debtId,
      reminderDate: reminderDate,
      message: message,
      type: ReminderType.custom,
      recurrenceFrequency: recurrenceFrequency,
      recurrenceInterval: recurrenceInterval,
      maxRecurrences: maxRecurrences,
    );
  }

  /// Tekrarlayan hatırlatma oluştur
  Future<DebtReminder> createRecurringReminder({
    required String debtId,
    required DateTime startDate,
    required String message,
    required RecurrenceFrequency frequency,
    int interval = 1,
    int? maxRecurrences,
  }) async {
    return await _debtService.addReminder(
      debtId: debtId,
      reminderDate: startDate,
      message: message,
      type: ReminderType.recurring,
      recurrenceFrequency: frequency,
      recurrenceInterval: interval,
      maxRecurrences: maxRecurrences,
    );
  }

  /// Hatırlatmayı iptal et
  Future<void> cancelReminder(String debtId, String reminderId) async {
    await _debtService.deleteReminder(debtId, reminderId);
  }

  /// Borç/alacak ödendiğinde tüm hatırlatmaları iptal et
  Future<void> cancelAllReminders(String debtId) async {
    final reminders = await _debtService.getReminders(debtId);

    for (final reminder in reminders) {
      await _debtService.deleteReminder(debtId, reminder.id);
    }
  }

  /// Yaklaşan hatırlatmaları getir (önümüzdeki 7 gün)
  Future<List<Map<String, dynamic>>> getUpcomingReminders() async {
    final debts = await _debtService.getActiveDebts();
    final now = DateTime.now();
    final weekLater = now.add(const Duration(days: 7));
    final upcomingReminders = <Map<String, dynamic>>[];

    for (final debt in debts) {
      final reminders = await _debtService.getReminders(debt.id);

      for (final reminder in reminders) {
        if (reminder.status == ReminderStatus.pending &&
            reminder.reminderDate.isAfter(now) &&
            reminder.reminderDate.isBefore(weekLater)) {
          upcomingReminders.add({
            'debt': debt,
            'reminder': reminder,
          });
        }
      }
    }

    // Tarihe göre sırala
    upcomingReminders.sort((a, b) {
      final reminderA = a['reminder'] as DebtReminder;
      final reminderB = b['reminder'] as DebtReminder;
      return reminderA.reminderDate.compareTo(reminderB.reminderDate);
    });

    return upcomingReminders;
  }

  /// Hatırlatma istatistikleri
  Future<Map<String, int>> getReminderStats() async {
    final debts = await _debtService.getActiveDebts();
    int totalReminders = 0;
    int pendingReminders = 0;
    int overdueReminders = 0;

    for (final debt in debts) {
      final reminders = await _debtService.getReminders(debt.id);
      totalReminders += reminders.length;

      for (final reminder in reminders) {
        if (reminder.status == ReminderStatus.pending) {
          pendingReminders++;
          if (reminder.isPastDue) {
            overdueReminders++;
          }
        }
      }
    }

    return {
      'total': totalReminders,
      'pending': pendingReminders,
      'overdue': overdueReminders,
    };
  }
}
