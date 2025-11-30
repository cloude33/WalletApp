import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/app_notification.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../models/notification_preferences.dart';
import '../utils/notification_id_manager.dart';
import 'data_service.dart';
import 'notification_service.dart';
import 'notification_scheduler_service.dart';

class EnhancedNotificationService {
  static final EnhancedNotificationService _instance =
      EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();
  final NotificationSchedulerService _schedulerService =
      NotificationSchedulerService();
  
  // Performance optimization: cache for recent notifications
  final Map<String, List<AppNotification>> _notificationCache = {};
  static const Duration _cacheTimeout = Duration(minutes: 5);
  DateTime? _lastCacheUpdate;

  /// Check budget thresholds and create alerts
  Future<List<AppNotification>> checkBudgetThresholds() async {
    final budgets = await _dataService.getBudgets();
    final transactions = await _dataService.getTransactions();
    final notifications = <AppNotification>[];
    final now = DateTime.now();

    for (var budget in budgets.where((b) => b.isActive)) {
      // Calculate spending for this budget
      final budgetTransactions = transactions.where((t) {
        if (t.type != 'expense') return false;
        if (t.category != budget.category) return false;
        
        // Check if transaction is within budget period
        return t.date.isAfter(budget.startDate.subtract(const Duration(seconds: 1))) &&
               t.date.isBefore(budget.endDate.add(const Duration(days: 1)));
      });

      final spent = budgetTransactions.fold<double>(
        0,
        (sum, t) => sum + t.amount,
      );

      final percentage = (spent / budget.amount) * 100;

      // Check for budget exceeded (>100%)
      if (percentage > 100) {
        final excess = spent - budget.amount;
        final notification = AppNotification(
          id: const Uuid().v4(),
          type: NotificationType.budgetExceeded,
          priority: NotificationPriority.high,
          title: 'Bütçe Aşıldı!',
          message:
              '${budget.category} bütçeniz ₺${excess.toStringAsFixed(2)} aşıldı. '
              'Harcama: ₺${spent.toStringAsFixed(2)} / ₺${budget.amount.toStringAsFixed(2)}',
          createdAt: now,
          data: {
            'budgetId': budget.id,
            'category': budget.category,
            'spent': spent,
            'limit': budget.amount,
            'percentage': percentage,
            'excess': excess,
          },
          actions: [
            const NotificationAction(
              id: 'view_details',
              title: 'Detayları Gör',
            ),
          ],
        );
        notifications.add(notification);

        // Show immediate notification
        await _schedulerService.showNotification(
          id: NotificationIdManager.getBudgetAlertId(budget.id),
          title: notification.title,
          body: notification.message,
          priority: NotificationPriority.high,
        );
      }
      // Check for critical alert (100%)
      else if (percentage >= 100 && percentage <= 100.5) {
        final notification = AppNotification(
          id: const Uuid().v4(),
          type: NotificationType.budgetCritical,
          priority: NotificationPriority.high,
          title: 'Bütçe Limitine Ulaşıldı!',
          message:
              '${budget.category} bütçenizin tamamını kullandınız. '
              'Harcama: ₺${spent.toStringAsFixed(2)} / ₺${budget.amount.toStringAsFixed(2)}',
          createdAt: now,
          data: {
            'budgetId': budget.id,
            'category': budget.category,
            'spent': spent,
            'limit': budget.amount,
            'percentage': percentage,
          },
          actions: [
            const NotificationAction(
              id: 'view_details',
              title: 'Detayları Gör',
            ),
          ],
        );
        notifications.add(notification);

        // Show immediate notification
        await _schedulerService.showNotification(
          id: NotificationIdManager.getBudgetAlertId(budget.id),
          title: notification.title,
          body: notification.message,
          priority: NotificationPriority.high,
        );
      }
      // Check for warning (80%)
      else if (percentage >= 80 && percentage < 100) {
        final notification = AppNotification(
          id: const Uuid().v4(),
          type: NotificationType.budgetWarning,
          priority: NotificationPriority.normal,
          title: 'Bütçe Uyarısı',
          message:
              '${budget.category} bütçenizin %${percentage.toInt()}\'ine ulaştınız. '
              'Harcama: ₺${spent.toStringAsFixed(2)} / ₺${budget.amount.toStringAsFixed(2)}',
          createdAt: now,
          data: {
            'budgetId': budget.id,
            'category': budget.category,
            'spent': spent,
            'limit': budget.amount,
            'percentage': percentage,
          },
          actions: [
            const NotificationAction(
              id: 'view_details',
              title: 'Detayları Gör',
            ),
          ],
        );
        notifications.add(notification);

        // Show immediate notification
        await _schedulerService.showNotification(
          id: NotificationIdManager.getBudgetAlertId(budget.id),
          title: notification.title,
          body: notification.message,
          priority: NotificationPriority.normal,
        );
      }
    }

    // Save notifications to history
    for (var notification in notifications) {
      await _notificationService.addNotification(notification);
    }

    return notifications;
  }

  /// Monitor budgets continuously (call this after transactions are added/updated)
  Future<void> monitorBudgets() async {
    await checkBudgetThresholds();
  }

  /// Get spending for a specific budget
  Future<double> getBudgetSpending(Budget budget) async {
    final transactions = await _dataService.getTransactions();
    
    final budgetTransactions = transactions.where((t) {
      if (t.type != 'expense') return false;
      if (t.category != budget.category) return false;
      
      return t.date.isAfter(budget.startDate.subtract(const Duration(seconds: 1))) &&
             t.date.isBefore(budget.endDate.add(const Duration(days: 1)));
    });

    return budgetTransactions.fold<double>(0, (sum, t) => sum + t.amount);
  }

  /// Get budget utilization percentage
  Future<double> getBudgetUtilization(Budget budget) async {
    final spent = await getBudgetSpending(budget);
    return budget.amount > 0 ? (spent / budget.amount) * 100 : 0;
  }

  /// Check if budget alert should be sent
  Future<bool> shouldSendBudgetAlert(Budget budget, double percentage) async {
    // Check if we already sent an alert for this threshold
    final notifications = await _notificationService.getNotifications();
    
    // Look for recent notifications for this budget
    final recentAlerts = notifications.where((n) {
      if (n.data == null) return false;
      if (n.data!['budgetId'] != budget.id) return false;
      
      // Check if notification is from today
      final isToday = n.createdAt.year == DateTime.now().year &&
                      n.createdAt.month == DateTime.now().month &&
                      n.createdAt.day == DateTime.now().day;
      
      return isToday;
    }).toList();

    // If we already sent an alert today for this budget, don't send another
    if (recentAlerts.isNotEmpty) {
      // Check if the percentage has crossed a new threshold
      final lastPercentage = recentAlerts.first.data!['percentage'] as double;
      
      // Only send if we crossed a major threshold (80% -> 100% -> exceeded)
      if (percentage >= 100 && lastPercentage < 100) return true;
      if (percentage >= 80 && lastPercentage < 80) return true;
      
      return false;
    }

    return true;
  }

  // ==================== SUMMARY GENERATION ====================

  /// Generate daily summary notification
  Future<AppNotification?> generateDailySummary() async {
    final transactions = await _dataService.getTransactions();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Get today's transactions
    final todayTransactions = transactions.where((t) {
      return t.date.isAfter(today.subtract(const Duration(seconds: 1))) &&
             t.date.isBefore(tomorrow);
    }).toList();

    // If no transactions today, don't send summary
    if (todayTransactions.isEmpty) return null;

    // Calculate totals
    final totalIncome = todayTransactions
        .where((t) => t.type == 'income')
        .fold<double>(0, (sum, t) => sum + t.amount);

    final totalExpense = todayTransactions
        .where((t) => t.type == 'expense')
        .fold<double>(0, (sum, t) => sum + t.amount);

    final netBalance = totalIncome - totalExpense;

    // Get top 3 spending categories
    final categorySpending = <String, double>{};
    for (var t in todayTransactions.where((t) => t.type == 'expense')) {
      categorySpending[t.category] =
          (categorySpending[t.category] ?? 0) + t.amount;
    }

    final topCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = topCategories.take(3).toList();

    // Build message
    final formatter = NumberFormat('#,##0.00', 'tr_TR');
    var message = 'Gelir: ₺${formatter.format(totalIncome)}, '
        'Gider: ₺${formatter.format(totalExpense)}, '
        'Net: ₺${formatter.format(netBalance)}';

    if (top3.isNotEmpty) {
      message += '\n\nEn çok harcama:';
      for (var i = 0; i < top3.length; i++) {
        message += '\n${i + 1}. ${top3[i].key}: ₺${formatter.format(top3[i].value)}';
      }
    }

    final notification = AppNotification(
      id: const Uuid().v4(),
      type: NotificationType.dailySummary,
      priority: NotificationPriority.normal,
      title: 'Günlük Özet - ${DateFormat('d MMMM', 'tr_TR').format(now)}',
      message: message,
      createdAt: now,
      data: {
        'date': today.toIso8601String(),
        'income': totalIncome,
        'expense': totalExpense,
        'net': netBalance,
        'transactionCount': todayTransactions.length,
        'topCategories': top3.map((e) => {
          'category': e.key,
          'amount': e.value,
        }).toList(),
      },
    );

    // Save to history
    await _notificationService.addNotification(notification);

    return notification;
  }

  /// Generate weekly summary notification
  Future<AppNotification?> generateWeeklySummary() async {
    final transactions = await _dataService.getTransactions();
    final budgets = await _dataService.getBudgets();
    final now = DateTime.now();
    
    // Get this week's transactions (last 7 days)
    final weekAgo = now.subtract(const Duration(days: 7));
    final thisWeekTransactions = transactions.where((t) {
      return t.date.isAfter(weekAgo) && t.date.isBefore(now);
    }).toList();

    // Get previous week's transactions for comparison
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    final lastWeekTransactions = transactions.where((t) {
      return t.date.isAfter(twoWeeksAgo) && t.date.isBefore(weekAgo);
    }).toList();

    // Calculate this week's totals
    final thisWeekIncome = thisWeekTransactions
        .where((t) => t.type == 'income')
        .fold<double>(0, (sum, t) => sum + t.amount);

    final thisWeekExpense = thisWeekTransactions
        .where((t) => t.type == 'expense')
        .fold<double>(0, (sum, t) => sum + t.amount);

    final thisWeekNet = thisWeekIncome - thisWeekExpense;

    // Calculate last week's totals for comparison
    final lastWeekIncome = lastWeekTransactions
        .where((t) => t.type == 'income')
        .fold<double>(0, (sum, t) => sum + t.amount);

    final lastWeekExpense = lastWeekTransactions
        .where((t) => t.type == 'expense')
        .fold<double>(0, (sum, t) => sum + t.amount);

    // Calculate changes
    final incomeChange = lastWeekIncome > 0
        ? ((thisWeekIncome - lastWeekIncome) / lastWeekIncome) * 100
        : 0.0;
    final expenseChange = lastWeekExpense > 0
        ? ((thisWeekExpense - lastWeekExpense) / lastWeekExpense) * 100
        : 0.0;

    // Get top 5 spending categories
    final categorySpending = <String, double>{};
    for (var t in thisWeekTransactions.where((t) => t.type == 'expense')) {
      categorySpending[t.category] =
          (categorySpending[t.category] ?? 0) + t.amount;
    }

    final topCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = topCategories.take(5).toList();

    // Get budget utilization
    final budgetUtilization = <String, double>{};
    for (var budget in budgets.where((b) => b.isActive)) {
      final utilization = await getBudgetUtilization(budget);
      budgetUtilization[budget.category] = utilization;
    }

    // Build message
    final formatter = NumberFormat('#,##0.00', 'tr_TR');
    var message = 'Bu hafta:\n'
        'Gelir: ₺${formatter.format(thisWeekIncome)} '
        '(${incomeChange >= 0 ? '+' : ''}${incomeChange.toStringAsFixed(1)}%)\n'
        'Gider: ₺${formatter.format(thisWeekExpense)} '
        '(${expenseChange >= 0 ? '+' : ''}${expenseChange.toStringAsFixed(1)}%)\n'
        'Net: ₺${formatter.format(thisWeekNet)}';

    if (top5.isNotEmpty) {
      message += '\n\nEn çok harcama:';
      for (var i = 0; i < top5.length; i++) {
        message += '\n${i + 1}. ${top5[i].key}: ₺${formatter.format(top5[i].value)}';
      }
    }

    if (budgetUtilization.isNotEmpty) {
      message += '\n\nBütçe kullanımı:';
      for (var entry in budgetUtilization.entries) {
        message += '\n${entry.key}: %${entry.value.toStringAsFixed(0)}';
      }
    }

    final notification = AppNotification(
      id: const Uuid().v4(),
      type: NotificationType.weeklySummary,
      priority: NotificationPriority.normal,
      title: 'Haftalık Özet',
      message: message,
      createdAt: now,
      data: {
        'weekStart': weekAgo.toIso8601String(),
        'weekEnd': now.toIso8601String(),
        'income': thisWeekIncome,
        'expense': thisWeekExpense,
        'net': thisWeekNet,
        'incomeChange': incomeChange,
        'expenseChange': expenseChange,
        'transactionCount': thisWeekTransactions.length,
        'topCategories': top5.map((e) => {
          'category': e.key,
          'amount': e.value,
        }).toList(),
        'budgetUtilization': budgetUtilization,
      },
    );

    // Save to history
    await _notificationService.addNotification(notification);

    return notification;
  }
}


  // ==================== REMINDER SCHEDULING ====================

  /// Schedule bill reminders for recurring transactions
  Future<void> scheduleBillReminders({int reminderDays = 3}) async {
    final recurringTransactions = await _dataService.getRecurringTransactions();
    
    // Filter for bill-type transactions (Faturalar category)
    final bills = recurringTransactions.where((rt) {
      return rt.isActive && 
             rt.category.toLowerCase().contains('fatura');
    }).toList();

    for (var bill in bills) {
      final nextOccurrence = bill.getNextOccurrence();
      if (nextOccurrence == null) continue;

      final now = DateTime.now();
      final daysUntilDue = nextOccurrence.difference(now).inDays;

      // Schedule reminder if within reminder window
      if (daysUntilDue <= reminderDays && daysUntilDue >= 0) {
        final priority = daysUntilDue == 0
            ? NotificationPriority.high
            : NotificationPriority.normal;

        final notificationType = daysUntilDue == 0
            ? NotificationType.paymentDue
            : NotificationType.billReminder;

        final formatter = NumberFormat('#,##0.00', 'tr_TR');
        final dateFormatter = DateFormat('d MMMM', 'tr_TR');

        final title = daysUntilDue == 0
            ? 'Fatura Ödeme Günü!'
            : 'Fatura Hatırlatıcısı';

        final message = daysUntilDue == 0
            ? '${bill.description} faturanız bugün ödenmeli. '
                'Tutar: ₺${formatter.format(bill.amount)}'
            : '${bill.description} faturanız $daysUntilDue gün sonra ödenecek. '
                'Tutar: ₺${formatter.format(bill.amount)}, '
                'Tarih: ${dateFormatter.format(nextOccurrence)}';

        // Schedule notification for the reminder day
        final reminderDate = nextOccurrence.subtract(Duration(days: daysUntilDue));
        
        await _schedulerService.scheduleNotification(
          id: NotificationIdManager.getBillReminderId(bill.id),
          title: title,
          body: message,
          scheduledDate: reminderDate,
          priority: priority,
          payload: 'bill_reminder:${bill.id}',
          actions: [
            const AndroidNotificationAction(
              'mark_paid',
              'Ödendi Olarak İşaretle',
            ),
            const AndroidNotificationAction(
              'snooze',
              'Ertele',
            ),
          ],
        );

        // Also save to notification history
        final notification = AppNotification(
          id: const Uuid().v4(),
          type: notificationType,
          priority: priority,
          title: title,
          message: message,
          createdAt: now,
          data: {
            'recurringTransactionId': bill.id,
            'amount': bill.amount,
            'dueDate': nextOccurrence.toIso8601String(),
            'daysUntilDue': daysUntilDue,
            'description': bill.description,
          },
          actions: [
            const NotificationAction(
              id: 'mark_paid',
              title: 'Ödendi Olarak İşaretle',
            ),
            const NotificationAction(
              id: 'snooze',
              title: 'Ertele',
            ),
          ],
        );

        await _notificationService.addNotification(notification);
      }
    }
  }

  /// Schedule installment reminders
  Future<void> scheduleInstallmentReminders({int reminderDays = 5}) async {
    final transactions = await _dataService.getTransactions();
    
    // Filter for installment transactions
    final installments = transactions.where((t) {
      return t.installments != null && 
             t.installments! > 1 &&
             t.currentInstallment != null;
    }).toList();

    // Group by parent transaction
    final installmentGroups = <String, List<Transaction>>{};
    for (var installment in installments) {
      final parentId = installment.parentTransactionId ?? installment.id;
      installmentGroups.putIfAbsent(parentId, () => []).add(installment);
    }

    final now = DateTime.now();
    final upcomingInstallments = <Transaction>[];

    // Find upcoming installments
    for (var group in installmentGroups.values) {
      // Sort by date
      group.sort((a, b) => a.date.compareTo(b.date));
      
      // Find next unpaid installment
      for (var installment in group) {
        if (installment.date.isAfter(now)) {
          final daysUntilDue = installment.date.difference(now).inDays;
          
          if (daysUntilDue <= reminderDays && daysUntilDue >= 0) {
            upcomingInstallments.add(installment);
          }
          break; // Only take the next installment from each group
        }
      }
    }

    // Check if we should send consolidated notification
    if (upcomingInstallments.length > 1) {
      await _sendConsolidatedInstallmentReminder(upcomingInstallments);
    } else {
      // Send individual reminders
      for (var installment in upcomingInstallments) {
        await _sendInstallmentReminder(installment, reminderDays);
      }
    }
  }

  /// Send individual installment reminder
  Future<void> _sendInstallmentReminder(
    Transaction installment,
    int reminderDays,
  ) async {
    final now = DateTime.now();
    final daysUntilDue = installment.date.difference(now).inDays;

    final priority = daysUntilDue == 0
        ? NotificationPriority.high
        : NotificationPriority.normal;

    final notificationType = daysUntilDue == 0
        ? NotificationType.paymentDue
        : NotificationType.installmentReminder;

    final formatter = NumberFormat('#,##0.00', 'tr_TR');
    final dateFormatter = DateFormat('d MMMM', 'tr_TR');

    final title = daysUntilDue == 0
        ? 'Taksit Ödeme Günü!'
        : 'Taksit Hatırlatıcısı';

    final message = daysUntilDue == 0
        ? '${installment.description} - ${installment.currentInstallment}/${installment.installments} taksit bugün ödenecek. '
            'Tutar: ₺${formatter.format(installment.amount)}'
        : '${installment.description} - ${installment.currentInstallment}/${installment.installments} taksit $daysUntilDue gün sonra ödenecek. '
            'Tutar: ₺${formatter.format(installment.amount)}, '
            'Tarih: ${dateFormatter.format(installment.date)}';

    // Schedule notification
    await _schedulerService.scheduleNotification(
      id: NotificationIdManager.getInstallmentReminderId(installment.id),
      title: title,
      body: message,
      scheduledDate: installment.date.subtract(Duration(days: daysUntilDue)),
      priority: priority,
      payload: 'installment_reminder:${installment.id}',
      actions: [
        const AndroidNotificationAction(
          'view_details',
          'Detayları Gör',
        ),
        const AndroidNotificationAction(
          'snooze',
          'Ertele',
        ),
      ],
    );

    // Save to notification history
    final notification = AppNotification(
      id: const Uuid().v4(),
      type: notificationType,
      priority: priority,
      title: title,
      message: message,
      createdAt: now,
      data: {
        'transactionId': installment.id,
        'amount': installment.amount,
        'dueDate': installment.date.toIso8601String(),
        'daysUntilDue': daysUntilDue,
        'description': installment.description,
        'currentInstallment': installment.currentInstallment,
        'totalInstallments': installment.installments,
      },
      actions: [
        const NotificationAction(
          id: 'view_details',
          title: 'Detayları Gör',
        ),
        const NotificationAction(
          id: 'snooze',
          title: 'Ertele',
        ),
      ],
    );

    await _notificationService.addNotification(notification);
  }

  /// Send consolidated installment reminder for multiple installments
  Future<void> _sendConsolidatedInstallmentReminder(
    List<Transaction> installments,
  ) async {
    final now = DateTime.now();
    final formatter = NumberFormat('#,##0.00', 'tr_TR');
    final dateFormatter = DateFormat('d MMM', 'tr_TR');

    var message = 'Yaklaşan ${installments.length} taksit ödemesi:\n\n';
    double totalAmount = 0;

    for (var i = 0; i < installments.length; i++) {
      final installment = installments[i];
      final daysUntilDue = installment.date.difference(now).inDays;
      
      message += '${i + 1}. ${installment.description} '
          '(${installment.currentInstallment}/${installment.installments})\n'
          '   ₺${formatter.format(installment.amount)} - '
          '${dateFormatter.format(installment.date)} '
          '($daysUntilDue gün)\n';
      
      totalAmount += installment.amount;
    }

    message += '\nToplam: ₺${formatter.format(totalAmount)}';

    // Schedule notification
    await _schedulerService.showNotification(
      id: NotificationIdManager.getInstallmentReminderId('consolidated'),
      title: 'Yaklaşan Taksit Ödemeleri',
      body: message,
      priority: NotificationPriority.normal,
      payload: 'installment_reminder:consolidated',
    );

    // Save to notification history
    final notification = AppNotification(
      id: const Uuid().v4(),
      type: NotificationType.installmentReminder,
      priority: NotificationPriority.normal,
      title: 'Yaklaşan Taksit Ödemeleri',
      message: message,
      createdAt: now,
      data: {
        'installmentCount': installments.length,
        'totalAmount': totalAmount,
        'installments': installments.map((i) => {
          'id': i.id,
          'description': i.description,
          'amount': i.amount,
          'dueDate': i.date.toIso8601String(),
          'currentInstallment': i.currentInstallment,
          'totalInstallments': i.installments,
        }).toList(),
      },
    );

    await _notificationService.addNotification(notification);
  }

  /// Cancel a specific reminder
  Future<void> cancelReminder(String reminderId) async {
    // Determine the type and cancel the notification
    final platformId = NotificationIdManager.getBillReminderId(reminderId);
    await _schedulerService.cancelNotification(platformId);
  }

  // ==================== NOTIFICATION ACTIONS ====================

  /// Handle notification action
  Future<void> handleNotificationAction(
    String action,
    Map<String, dynamic> data,
  ) async {
    switch (action) {
      case 'view_details':
        await _handleViewDetails(data);
        break;
      case 'mark_paid':
        await _handleMarkAsPaid(data);
        break;
      case 'snooze':
        await _handleSnooze(data);
        break;
      default:
        break;
    }
  }

  /// Handle view details action
  Future<void> _handleViewDetails(Map<String, dynamic> data) async {
    // This will be handled by navigation in the UI
    // Just mark the notification as read
    if (data.containsKey('notificationId')) {
      await _notificationService.markAsRead(data['notificationId']);
    }
  }

  /// Handle mark as paid action
  Future<void> markAsPaid(String recurringTransactionId) async {
    final recurringTransactions = await _dataService.getRecurringTransactions();
    final recurring = recurringTransactions.firstWhere(
      (rt) => rt.id == recurringTransactionId,
      orElse: () => throw Exception('Recurring transaction not found'),
    );

    // Create a transaction for this payment
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: recurring.type,
      amount: recurring.amount,
      description: recurring.description,
      category: recurring.category,
      walletId: recurring.walletId,
      date: DateTime.now(),
      memo: recurring.memo,
      images: recurring.images,
    );

    await _dataService.addTransaction(transaction);

    // Update wallet balance
    final wallets = await _dataService.getWallets();
    final walletIndex = wallets.indexWhere((w) => w.id == recurring.walletId);
    if (walletIndex != -1) {
      final wallet = wallets[walletIndex];
      final newBalance = recurring.type == 'income'
          ? wallet.balance + recurring.amount
          : wallet.balance - recurring.amount;

      wallets[walletIndex] = wallet.copyWith(balance: newBalance);
      await _dataService.saveWallets(wallets);
    }

    // Cancel the reminder
    await cancelReminder(recurringTransactionId);
  }

  /// Handle mark as paid action from notification data
  Future<void> _handleMarkAsPaid(Map<String, dynamic> data) async {
    if (data.containsKey('recurringTransactionId')) {
      await markAsPaid(data['recurringTransactionId']);
    }
  }

  /// Handle snooze action
  Future<void> snoozeNotification(String notificationId, {Duration? duration}) async {
    final snoozeDuration = duration ?? const Duration(hours: 1);
    final snoozeUntil = DateTime.now().add(snoozeDuration);

    // Reschedule the notification
    // This is a simplified implementation
    // In a real app, you'd need to store the snooze info and reschedule properly
    
    // Mark as dismissed for now
    await _notificationService.markAsDismissed(notificationId);
  }

  /// Handle snooze action from notification data
  Future<void> _handleSnooze(Map<String, dynamic> data) async {
    if (data.containsKey('notificationId')) {
      await snoozeNotification(data['notificationId']);
    }
  }

  // ==================== PERFORMANCE OPTIMIZATION ====================

  /// Process multiple notifications in batch
  Future<void> processBatchNotifications(
    List<AppNotification> notifications,
  ) async {
    final startTime = DateTime.now();
    
    try {
      // Process in batches of 10 to avoid overwhelming the system
      const batchSize = 10;
      for (var i = 0; i < notifications.length; i += batchSize) {
        final end = (i + batchSize < notifications.length)
            ? i + batchSize
            : notifications.length;
        final batch = notifications.sublist(i, end);
        
        // Process batch
        await Future.wait(
          batch.map((n) => _notificationService.addNotification(n)),
        );
        
        // Check timeout (100ms per batch)
        final elapsed = DateTime.now().difference(startTime);
        if (elapsed.inMilliseconds > 100 * ((i ~/ batchSize) + 1)) {
          debugPrint('Warning: Notification batch processing slow: ${elapsed.inMilliseconds}ms');
        }
      }
      
      // Invalidate cache after batch processing
      _invalidateCache();
    } catch (e) {
      debugPrint('Error in batch notification processing: $e');
    }
  }

  /// Get cached notifications or fetch fresh
  Future<List<AppNotification>> getCachedNotifications({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    
    // Check if cache is valid
    if (!forceRefresh &&
        _lastCacheUpdate != null &&
        now.difference(_lastCacheUpdate!).compareTo(_cacheTimeout) < 0 &&
        _notificationCache.containsKey('all')) {
      return _notificationCache['all']!;
    }
    
    // Fetch fresh data
    final notifications = await _notificationService.getNotifications();
    
    // Update cache
    _notificationCache['all'] = notifications;
    _lastCacheUpdate = now;
    
    return notifications;
  }

  /// Invalidate notification cache
  void _invalidateCache() {
    _notificationCache.clear();
    _lastCacheUpdate = null;
  }

  /// Monitor performance of notification operations
  Future<T> _measurePerformance<T>(
    String operation,
    Future<T> Function() fn,
  ) async {
    final startTime = DateTime.now();
    
    try {
      final result = await fn();
      final duration = DateTime.now().difference(startTime);
      
      if (duration.inMilliseconds > 100) {
        debugPrint('Performance warning: $operation took ${duration.inMilliseconds}ms');
      }
      
      return result;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('Error in $operation after ${duration.inMilliseconds}ms: $e');
      rethrow;
    }
  }
}
