class NotificationIdManager {
  static const int dailySummaryId = 2000;
  static const int weeklySummaryId = 2001;
  static const int billReminderBase = 3000;
  static const int installmentReminderBase = 4000;
  static const int recurringTransactionBase = 5000;
  static const int goalAchievedBase = 6000;
  static const int debtReminderBase = 7000;
  static const int debtOverdueBase = 8000;
  static int getBillReminderId(String transactionId) {
    return billReminderBase + (transactionId.hashCode % 1000).abs();
  }
  static int getInstallmentReminderId(String transactionId) {
    return installmentReminderBase + (transactionId.hashCode % 1000).abs();
  }
  static int getRecurringTransactionId(String recurringId) {
    return recurringTransactionBase + (recurringId.hashCode % 1000).abs();
  }
  static int getGoalAchievedId(String goalId) {
    return goalAchievedBase + (goalId.hashCode % 1000).abs();
  }
  static int getDebtReminderId(String debtId) {
    return debtReminderBase + (debtId.hashCode % 1000).abs();
  }
  static int getDebtOverdueId(String debtId) {
    return debtOverdueBase + (debtId.hashCode % 1000).abs();
  }
  static int getDailySummaryId() {
    return dailySummaryId;
  }
  static int getWeeklySummaryId() {
    return weeklySummaryId;
  }
  static bool isSummary(int id) {
    return id == dailySummaryId || id == weeklySummaryId;
  }
  static bool isBillReminder(int id) {
    return id >= billReminderBase && id < installmentReminderBase;
  }
  static bool isInstallmentReminder(int id) {
    return id >= installmentReminderBase && id < recurringTransactionBase;
  }
  static bool isRecurringTransaction(int id) {
    return id >= recurringTransactionBase && id < goalAchievedBase;
  }
  static bool isGoalAchieved(int id) {
    return id >= goalAchievedBase && id < debtReminderBase;
  }
  static bool isDebtReminder(int id) {
    return id >= debtReminderBase && id < debtOverdueBase;
  }
  static bool isDebtOverdue(int id) {
    return id >= debtOverdueBase;
  }
  static String getNotificationType(int id) {
    if (isSummary(id)) return 'summary';
    if (isBillReminder(id)) return 'bill_reminder';
    if (isInstallmentReminder(id)) return 'installment_reminder';
    if (isRecurringTransaction(id)) return 'recurring_transaction';
    if (isGoalAchieved(id)) return 'goal_achieved';
    if (isDebtReminder(id)) return 'debt_reminder';
    if (isDebtOverdue(id)) return 'debt_overdue';
    return 'unknown';
  }
}
