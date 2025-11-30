/// Manages notification IDs to ensure uniqueness and avoid conflicts
class NotificationIdManager {
  // Base IDs for different notification types
  static const int budgetAlertBase = 1000;
  static const int dailySummaryId = 2000;
  static const int weeklySummaryId = 2001;
  static const int billReminderBase = 3000;
  static const int installmentReminderBase = 4000;
  static const int recurringTransactionBase = 5000;
  static const int goalAchievedBase = 6000;
  static const int debtReminderBase = 7000;
  static const int debtOverdueBase = 8000;

  /// Get notification ID for budget alert
  /// Uses budget ID hash to ensure uniqueness
  static int getBudgetAlertId(String budgetId) {
    return budgetAlertBase + (budgetId.hashCode % 1000).abs();
  }

  /// Get notification ID for bill reminder
  /// Uses transaction ID hash to ensure uniqueness
  static int getBillReminderId(String transactionId) {
    return billReminderBase + (transactionId.hashCode % 1000).abs();
  }

  /// Get notification ID for installment reminder
  /// Uses transaction ID hash to ensure uniqueness
  static int getInstallmentReminderId(String transactionId) {
    return installmentReminderBase + (transactionId.hashCode % 1000).abs();
  }

  /// Get notification ID for recurring transaction
  /// Uses recurring transaction ID hash to ensure uniqueness
  static int getRecurringTransactionId(String recurringId) {
    return recurringTransactionBase + (recurringId.hashCode % 1000).abs();
  }

  /// Get notification ID for goal achieved
  /// Uses goal ID hash to ensure uniqueness
  static int getGoalAchievedId(String goalId) {
    return goalAchievedBase + (goalId.hashCode % 1000).abs();
  }

  /// Get notification ID for debt reminder
  /// Uses debt ID hash to ensure uniqueness
  static int getDebtReminderId(String debtId) {
    return debtReminderBase + (debtId.hashCode % 1000).abs();
  }

  /// Get notification ID for overdue debt
  /// Uses debt ID hash to ensure uniqueness
  static int getDebtOverdueId(String debtId) {
    return debtOverdueBase + (debtId.hashCode % 1000).abs();
  }

  /// Get daily summary notification ID
  static int getDailySummaryId() {
    return dailySummaryId;
  }

  /// Get weekly summary notification ID
  static int getWeeklySummaryId() {
    return weeklySummaryId;
  }

  /// Check if an ID is a budget alert
  static bool isBudgetAlert(int id) {
    return id >= budgetAlertBase && id < dailySummaryId;
  }

  /// Check if an ID is a summary notification
  static bool isSummary(int id) {
    return id == dailySummaryId || id == weeklySummaryId;
  }

  /// Check if an ID is a bill reminder
  static bool isBillReminder(int id) {
    return id >= billReminderBase && id < installmentReminderBase;
  }

  /// Check if an ID is an installment reminder
  static bool isInstallmentReminder(int id) {
    return id >= installmentReminderBase && id < recurringTransactionBase;
  }

  /// Check if an ID is a recurring transaction notification
  static bool isRecurringTransaction(int id) {
    return id >= recurringTransactionBase && id < goalAchievedBase;
  }

  /// Check if an ID is a goal achieved notification
  static bool isGoalAchieved(int id) {
    return id >= goalAchievedBase && id < debtReminderBase;
  }

  /// Check if an ID is a debt reminder
  static bool isDebtReminder(int id) {
    return id >= debtReminderBase && id < debtOverdueBase;
  }

  /// Check if an ID is a debt overdue notification
  static bool isDebtOverdue(int id) {
    return id >= debtOverdueBase;
  }

  /// Get notification type from ID
  static String getNotificationType(int id) {
    if (isBudgetAlert(id)) return 'budget_alert';
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
