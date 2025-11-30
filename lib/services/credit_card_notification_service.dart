import '../models/credit_card.dart';
import '../models/credit_card_statement.dart';
import '../repositories/credit_card_repository.dart';
import '../repositories/credit_card_statement_repository.dart';
import '../services/credit_card_service.dart';
import 'notification_scheduler_service.dart';

class CreditCardNotificationService {
  final CreditCardRepository _cardRepo = CreditCardRepository();
  final CreditCardStatementRepository _statementRepo = CreditCardStatementRepository();
  final CreditCardService _cardService = CreditCardService();
  final NotificationSchedulerService _notificationService = NotificationSchedulerService();

  // Notification ID ranges for credit cards
  static const int _dueDateReminderBaseId = 5000;
  static const int _statementDateReminderBaseId = 6000;
  static const int _overdueNotificationBaseId = 7000;

  // ==================== DUE DATE REMINDERS ====================

  /// Schedule due date reminder (3 days before due date)
  Future<void> scheduleDueDateReminder(CreditCardStatement statement) async {
    final card = await _cardRepo.findById(statement.cardId);
    if (card == null) return;

    final reminderDate = statement.dueDate.subtract(const Duration(days: 3));
    
    // Don't schedule if date has passed
    if (reminderDate.isBefore(DateTime.now())) return;

    final notificationId = _dueDateReminderBaseId + statement.id.hashCode % 1000;

    await _notificationService.scheduleNotification(
      id: notificationId,
      title: 'Kredi Kartı Ödeme Hatırlatması',
      body: '${card.bankName} ${card.cardName} kartınızın son ödeme tarihi 3 gün sonra. '
            'Ödenecek tutar: ₺${statement.remainingDebt.toStringAsFixed(2)}',
      scheduledDate: reminderDate,
      payload: 'credit_card_due_date:${statement.id}',
    );
  }

  /// Schedule due date reminders for all active statements
  Future<void> scheduleAllDueDateReminders() async {
    final cards = await _cardRepo.findActive();
    
    for (var card in cards) {
      final currentStatement = await _statementRepo.findCurrentStatement(card.id);
      if (currentStatement != null && !currentStatement.isPaidFully) {
        await scheduleDueDateReminder(currentStatement);
      }
    }
  }

  // ==================== STATEMENT DATE REMINDERS ====================

  /// Schedule statement date reminder (2 days before statement date)
  Future<void> scheduleStatementDateReminder(CreditCard card) async {
    final nextStatementDate = await _cardService.getNextStatementDate(card.id);
    final reminderDate = nextStatementDate.subtract(const Duration(days: 2));
    
    // Don't schedule if date has passed
    if (reminderDate.isBefore(DateTime.now())) return;

    final notificationId = _statementDateReminderBaseId + card.id.hashCode % 1000;

    await _notificationService.scheduleNotification(
      id: notificationId,
      title: 'Ekstre Kesim Hatırlatması',
      body: '${card.bankName} ${card.cardName} kartınızın ekstresi 2 gün sonra kesilecek.',
      scheduledDate: reminderDate,
      payload: 'credit_card_statement_date:${card.id}',
    );
  }

  /// Schedule statement date reminders for all active cards
  Future<void> scheduleAllStatementDateReminders() async {
    final cards = await _cardRepo.findActive();
    
    for (var card in cards) {
      await scheduleStatementDateReminder(card);
    }
  }

  // ==================== OVERDUE NOTIFICATIONS ====================

  /// Send overdue notification for a statement
  Future<void> sendOverdueNotification(CreditCardStatement statement) async {
    final card = await _cardRepo.findById(statement.cardId);
    if (card == null) return;

    final notificationId = _overdueNotificationBaseId + statement.id.hashCode % 1000;
    final daysOverdue = statement.daysOverdue;

    await _notificationService.scheduleNotification(
      id: notificationId,
      title: 'Gecikmiş Ödeme Uyarısı!',
      body: '${card.bankName} ${card.cardName} kartınızın ödemesi $daysOverdue gün gecikmiş. '
            'Kalan borç: ₺${statement.remainingDebt.toStringAsFixed(2)}',
      scheduledDate: DateTime.now(),
      payload: 'credit_card_overdue:${statement.id}',
      priority: NotificationPriority.high,
    );
  }

  /// Check and send overdue notifications for all cards
  Future<void> checkAndSendOverdueNotifications() async {
    final overdueStatements = await _statementRepo.findOverdueStatements();
    
    for (var statement in overdueStatements) {
      await sendOverdueNotification(statement);
    }
  }

  // ==================== GROUPED NOTIFICATIONS ====================

  /// Send grouped notification for multiple cards with same due date
  Future<void> sendGroupedDueDateNotification(
    List<CreditCardStatement> statements,
    DateTime dueDate,
  ) async {
    if (statements.isEmpty) return;

    final totalDebt = statements.fold<double>(
      0,
      (sum, s) => sum + s.remainingDebt,
    );

    final cardCount = statements.length;
    final reminderDate = dueDate.subtract(const Duration(days: 3));
    
    // Don't schedule if date has passed
    if (reminderDate.isBefore(DateTime.now())) return;

    await _notificationService.scheduleNotification(
      id: _dueDateReminderBaseId + 999, // Special ID for grouped notifications
      title: 'Çoklu Kart Ödeme Hatırlatması',
      body: '$cardCount kartınızın son ödeme tarihi 3 gün sonra. '
            'Toplam ödenecek: ₺${totalDebt.toStringAsFixed(2)}',
      scheduledDate: reminderDate,
      payload: 'credit_card_grouped_due_date',
    );
  }

  /// Group statements by due date and send grouped notifications
  Future<void> scheduleGroupedDueDateNotifications() async {
    final cards = await _cardRepo.findActive();
    final statementsByDueDate = <DateTime, List<CreditCardStatement>>{};

    // Group statements by due date
    for (var card in cards) {
      final currentStatement = await _statementRepo.findCurrentStatement(card.id);
      if (currentStatement != null && !currentStatement.isPaidFully) {
        final dueDate = DateTime(
          currentStatement.dueDate.year,
          currentStatement.dueDate.month,
          currentStatement.dueDate.day,
        );
        
        statementsByDueDate.putIfAbsent(dueDate, () => []).add(currentStatement);
      }
    }

    // Send grouped notifications for dates with multiple cards
    for (var entry in statementsByDueDate.entries) {
      if (entry.value.length > 1) {
        await sendGroupedDueDateNotification(entry.value, entry.key);
      } else {
        // Send individual notification
        await scheduleDueDateReminder(entry.value.first);
      }
    }
  }

  // ==================== NOTIFICATION PREFERENCES ====================

  /// Check if notifications are enabled for credit cards
  Future<bool> areNotificationsEnabled() async {
    // This would integrate with user preferences
    // For now, return true
    return true;
  }

  /// Schedule all credit card notifications
  Future<void> scheduleAllNotifications() async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    await scheduleGroupedDueDateNotifications();
    await scheduleAllStatementDateReminders();
    await checkAndSendOverdueNotifications();
  }

  /// Cancel all credit card notifications
  Future<void> cancelAllNotifications() async {
    // Cancel all notifications in the credit card ID ranges
    for (int i = 0; i < 1000; i++) {
      await _notificationService.cancelNotification(_dueDateReminderBaseId + i);
      await _notificationService.cancelNotification(_statementDateReminderBaseId + i);
      await _notificationService.cancelNotification(_overdueNotificationBaseId + i);
    }
  }

  /// Reschedule notifications for a specific card
  Future<void> rescheduleCardNotifications(String cardId) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) return;

    // Cancel existing notifications for this card
    final notificationId1 = _dueDateReminderBaseId + cardId.hashCode % 1000;
    final notificationId2 = _statementDateReminderBaseId + cardId.hashCode % 1000;
    
    await _notificationService.cancelNotification(notificationId1);
    await _notificationService.cancelNotification(notificationId2);

    // Reschedule
    await scheduleStatementDateReminder(card);
    
    final currentStatement = await _statementRepo.findCurrentStatement(cardId);
    if (currentStatement != null && !currentStatement.isPaidFully) {
      await scheduleDueDateReminder(currentStatement);
    }
  }
}
