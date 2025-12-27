import '../models/credit_card.dart';
import '../models/credit_card_statement.dart';
import '../repositories/credit_card_repository.dart';
import '../repositories/credit_card_statement_repository.dart';
import '../services/credit_card_service.dart';
import 'notification_scheduler_service.dart';

class CreditCardNotificationService {
  final CreditCardRepository _cardRepo = CreditCardRepository();
  final CreditCardStatementRepository _statementRepo =
      CreditCardStatementRepository();
  final CreditCardService _cardService = CreditCardService();
  final NotificationSchedulerService _notificationService =
      NotificationSchedulerService();
  static const int _dueDateReminderBaseId = 5000;
  static const int _statementDateReminderBaseId = 6000;
  static const int _overdueNotificationBaseId = 7000;
  static const int _limitAlertBaseId = 8000;
  static const int _statementCutBaseId = 9000;
  static const int _installmentEndingBaseId = 10000;
  static const int _deferredInstallmentStartBaseId = 11000;
  Future<void> scheduleDueDateReminder(CreditCardStatement statement) async {
    final card = await _cardRepo.findById(statement.cardId);
    if (card == null) return;

    final reminderDate = statement.dueDate.subtract(const Duration(days: 3));
    if (reminderDate.isBefore(DateTime.now())) return;

    final notificationId =
        _dueDateReminderBaseId + statement.id.hashCode % 1000;

    await _notificationService.scheduleNotification(
      id: notificationId,
      title: 'Kredi Kartı Ödeme Hatırlatması',
      body:
          '${card.bankName} ${card.cardName} kartınızın son ödeme tarihi 3 gün sonra. '
          'Ödenecek tutar: ₺${statement.remainingDebt.toStringAsFixed(2)}',
      scheduledDate: reminderDate,
      payload: 'credit_card_due_date:${statement.id}',
    );
  }
  Future<void> scheduleAllDueDateReminders() async {
    final cards = await _cardRepo.findActive();

    for (var card in cards) {
      final currentStatement = await _statementRepo.findCurrentStatement(
        card.id,
      );
      if (currentStatement != null && !currentStatement.isPaidFully) {
        await scheduleDueDateReminder(currentStatement);
      }
    }
  }
  Future<void> scheduleStatementDateReminder(CreditCard card) async {
    final nextStatementDate = await _cardService.getNextStatementDate(card.id);
    final reminderDate = nextStatementDate.subtract(const Duration(days: 2));
    if (reminderDate.isBefore(DateTime.now())) return;

    final notificationId =
        _statementDateReminderBaseId + card.id.hashCode % 1000;

    await _notificationService.scheduleNotification(
      id: notificationId,
      title: 'Ekstre Kesim Hatırlatması',
      body:
          '${card.bankName} ${card.cardName} kartınızın ekstresi 2 gün sonra kesilecek.',
      scheduledDate: reminderDate,
      payload: 'credit_card_statement_date:${card.id}',
    );
  }
  Future<void> scheduleAllStatementDateReminders() async {
    final cards = await _cardRepo.findActive();

    for (var card in cards) {
      await scheduleStatementDateReminder(card);
    }
  }
  Future<void> sendOverdueNotification(CreditCardStatement statement) async {
    final card = await _cardRepo.findById(statement.cardId);
    if (card == null) return;

    final notificationId =
        _overdueNotificationBaseId + statement.id.hashCode % 1000;
    final daysOverdue = statement.daysOverdue;

    await _notificationService.scheduleNotification(
      id: notificationId,
      title: 'Gecikmiş Ödeme Uyarısı!',
      body:
          '${card.bankName} ${card.cardName} kartınızın ödemesi $daysOverdue gün gecikmiş. '
          'Kalan borç: ₺${statement.remainingDebt.toStringAsFixed(2)}',
      scheduledDate: DateTime.now(),
      payload: 'credit_card_overdue:${statement.id}',
      priority: NotificationPriority.high,
    );
  }
  Future<void> checkAndSendOverdueNotifications() async {
    final overdueStatements = await _statementRepo.findOverdueStatements();

    for (var statement in overdueStatements) {
      await sendOverdueNotification(statement);
    }
  }
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
    if (reminderDate.isBefore(DateTime.now())) return;

    await _notificationService.scheduleNotification(
      id: _dueDateReminderBaseId + 999,
      title: 'Çoklu Kart Ödeme Hatırlatması',
      body:
          '$cardCount kartınızın son ödeme tarihi 3 gün sonra. '
          'Toplam ödenecek: ₺${totalDebt.toStringAsFixed(2)}',
      scheduledDate: reminderDate,
      payload: 'credit_card_grouped_due_date',
    );
  }
  Future<void> scheduleGroupedDueDateNotifications() async {
    final cards = await _cardRepo.findActive();
    final statementsByDueDate = <DateTime, List<CreditCardStatement>>{};
    for (var card in cards) {
      final currentStatement = await _statementRepo.findCurrentStatement(
        card.id,
      );
      if (currentStatement != null && !currentStatement.isPaidFully) {
        final dueDate = DateTime(
          currentStatement.dueDate.year,
          currentStatement.dueDate.month,
          currentStatement.dueDate.day,
        );

        statementsByDueDate
            .putIfAbsent(dueDate, () => [])
            .add(currentStatement);
      }
    }
    for (var entry in statementsByDueDate.entries) {
      if (entry.value.length > 1) {
        await sendGroupedDueDateNotification(entry.value, entry.key);
      } else {
        await scheduleDueDateReminder(entry.value.first);
      }
    }
  }
  Future<bool> areNotificationsEnabled() async {
    return true;
  }
  Future<void> scheduleAllNotifications() async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    await scheduleGroupedDueDateNotifications();
    await scheduleAllStatementDateReminders();
    await checkAndSendOverdueNotifications();
  }
  Future<void> cancelAllNotifications() async {
    for (int i = 0; i < 1000; i++) {
      await _notificationService.cancelNotification(_dueDateReminderBaseId + i);
      await _notificationService.cancelNotification(
        _statementDateReminderBaseId + i,
      );
      await _notificationService.cancelNotification(
        _overdueNotificationBaseId + i,
      );
    }
  }
  Future<void> rescheduleCardNotifications(String cardId) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) return;
    final notificationId1 = _dueDateReminderBaseId + cardId.hashCode % 1000;
    final notificationId2 =
        _statementDateReminderBaseId + cardId.hashCode % 1000;

    await _notificationService.cancelNotification(notificationId1);
    await _notificationService.cancelNotification(notificationId2);
    await scheduleStatementDateReminder(card);

    final currentStatement = await _statementRepo.findCurrentStatement(cardId);
    if (currentStatement != null && !currentStatement.isPaidFully) {
      await scheduleDueDateReminder(currentStatement);
    }
  }
  Future<void> scheduleLimitAlert(
    String cardId,
    double utilization,
    double availableLimit,
  ) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) return;

    final notificationId = _limitAlertBaseId + cardId.hashCode % 1000;

    String title;
    String body;

    if (utilization >= 100) {
      title = 'Limit Doldu!';
      body =
          '${card.bankName} ${card.cardName} kartınızın limiti doldu. '
          'Kullanılabilir limit: ₺${availableLimit.toStringAsFixed(2)}';
    } else if (utilization >= 90) {
      title = 'Limit Uyarısı - %90';
      body =
          '${card.bankName} ${card.cardName} kartınızın limitinin %${utilization.toStringAsFixed(0)}\'i kullanıldı. '
          'Kalan limit: ₺${availableLimit.toStringAsFixed(2)}';
    } else if (utilization >= 80) {
      title = 'Limit Uyarısı - %80';
      body =
          '${card.bankName} ${card.cardName} kartınızın limitinin %${utilization.toStringAsFixed(0)}\'i kullanıldı. '
          'Kalan limit: ₺${availableLimit.toStringAsFixed(2)}';
    } else {
      return;
    }

    await _notificationService.showNotification(
      id: notificationId,
      title: title,
      body: body,
      payload: 'credit_card_limit_alert:$cardId',
      priority: utilization >= 100
          ? NotificationPriority.urgent
          : NotificationPriority.high,
    );
  }
  Future<void> scheduleStatementCutNotification(
    String cardId,
    DateTime cutDate,
    double periodDebt,
    DateTime dueDate,
  ) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) return;

    final notificationId = _statementCutBaseId + cardId.hashCode % 1000;

    await _notificationService.scheduleNotification(
      id: notificationId,
      title: 'Ekstre Kesildi',
      body:
          '${card.bankName} ${card.cardName} kartınızın ekstresi kesildi. '
          'Dönem borcu: ₺${periodDebt.toStringAsFixed(2)}. '
          'Son ödeme tarihi: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
      scheduledDate: cutDate,
      payload: 'credit_card_statement_cut:$cardId',
      priority: NotificationPriority.high,
    );
  }
  Future<void> scheduleInstallmentEndingNotification(
    String transactionId,
    String cardId,
    String description,
    int remainingInstallments,
    double monthlyAmount,
  ) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) return;
    if (remainingInstallments != 1) return;

    final notificationId =
        _installmentEndingBaseId + transactionId.hashCode % 1000;

    await _notificationService.showNotification(
      id: notificationId,
      title: 'Taksit Bitiyor',
      body:
          '${card.bankName} ${card.cardName} kartınızdaki "$description" taksiti bitiyor. '
          'Son taksit: ₺${monthlyAmount.toStringAsFixed(2)}',
      payload: 'credit_card_installment_ending:$transactionId',
      priority: NotificationPriority.normal,
    );
  }
  Future<void> scheduleDeferredInstallmentStartNotification(
    String transactionId,
    String cardId,
    String description,
    DateTime startDate,
    int installmentCount,
    double monthlyAmount,
  ) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) return;

    final notificationId =
        _deferredInstallmentStartBaseId + transactionId.hashCode % 1000;
    await _notificationService.scheduleNotification(
      id: notificationId,
      title: 'Ertelenmiş Taksit Başlıyor',
      body:
          '${card.bankName} ${card.cardName} kartınızdaki "$description" ertelenmiş taksiti başlıyor. '
          '$installmentCount x ₺${monthlyAmount.toStringAsFixed(2)}',
      scheduledDate: startDate,
      payload: 'credit_card_deferred_installment_start:$transactionId',
      priority: NotificationPriority.normal,
    );
  }
  Future<void> schedulePaymentReminderWithDays(
    CreditCardStatement statement,
    int daysBefore,
  ) async {
    final card = await _cardRepo.findById(statement.cardId);
    if (card == null) return;

    final reminderDate =
        statement.dueDate.subtract(Duration(days: daysBefore));
    if (reminderDate.isBefore(DateTime.now())) return;

    final notificationId =
        _dueDateReminderBaseId + statement.id.hashCode % 1000 + daysBefore;

    String title;
    if (daysBefore == 7) {
      title = 'Ödeme Hatırlatması - 7 Gün Kaldı';
    } else if (daysBefore == 3) {
      title = 'Ödeme Hatırlatması - 3 Gün Kaldı';
    } else if (daysBefore == 0) {
      title = 'Son Ödeme Günü!';
    } else {
      title = 'Ödeme Hatırlatması - $daysBefore Gün Kaldı';
    }

    await _notificationService.scheduleNotification(
      id: notificationId,
      title: title,
      body:
          '${card.bankName} ${card.cardName} kartınızın son ödeme tarihi ${daysBefore == 0 ? "bugün" : "$daysBefore gün sonra"}. '
          'Asgari ödeme: ₺${statement.minimumPayment.toStringAsFixed(2)}, '
          'Tam ödeme: ₺${statement.remainingDebt.toStringAsFixed(2)}',
      scheduledDate: reminderDate,
      payload: 'credit_card_payment_reminder:${statement.id}',
      priority: daysBefore == 0
          ? NotificationPriority.urgent
          : NotificationPriority.high,
    );
  }
  Future<void> cancelLimitAlerts(String cardId) async {
    final notificationId = _limitAlertBaseId + cardId.hashCode % 1000;
    await _notificationService.cancelNotification(notificationId);
  }
  Future<void> updatePaymentReminders(String cardId) async {
    final currentStatement = await _statementRepo.findCurrentStatement(cardId);
    if (currentStatement == null || currentStatement.isPaidFully) return;
    for (int days in [0, 3, 7]) {
      final notificationId =
          _dueDateReminderBaseId + currentStatement.id.hashCode % 1000 + days;
      await _notificationService.cancelNotification(notificationId);
    }
    await schedulePaymentReminderWithDays(currentStatement, 7);
    await schedulePaymentReminderWithDays(currentStatement, 3);
    await schedulePaymentReminderWithDays(currentStatement, 0);
  }
}
