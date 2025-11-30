import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/app_notification.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import 'data_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final DataService _dataService = DataService();

  // Check budgets and create warnings
  Future<List<AppNotification>> checkBudgets() async {
    final budgets = await _dataService.getBudgets();
    final transactions = await _dataService.getTransactions();
    final notifications = <AppNotification>[];
    final now = DateTime.now();

    for (var budget in budgets) {
      final budgetTransactions = transactions.where((t) {
        if (t.type != 'expense') return false;
        if (budget.category != null && t.category != budget.category) return false;
        return t.date.year == now.year && t.date.month == now.month;
      });

      final spent = budgetTransactions.fold<double>(0, (sum, t) => sum + t.amount);
      final percentage = (spent / budget.amount) * 100;

      if (percentage >= 100 && !_hasRecentNotification(budget.id, NotificationType.budgetExceeded)) {
        notifications.add(AppNotification(
          id: const Uuid().v4(),
          type: NotificationType.budgetExceeded,
          title: 'Bütçe Aşıldı!',
          message: '${budget.category ?? "Toplam"} bütçeniz aşıldı. '
              '₺${spent.toStringAsFixed(2)} / ₺${budget.amount.toStringAsFixed(2)}',
          createdAt: now,
          data: {'budgetId': budget.id, 'spent': spent, 'limit': budget.amount},
        ));
      } else if (percentage >= 80 && percentage < 100 && 
                 !_hasRecentNotification(budget.id, NotificationType.budgetWarning)) {
        notifications.add(AppNotification(
          id: const Uuid().v4(),
          type: NotificationType.budgetWarning,
          title: 'Bütçe Uyarısı',
          message: '${budget.category ?? "Toplam"} bütçenizin %${percentage.toInt()}\'ine ulaştınız. '
              '₺${spent.toStringAsFixed(2)} / ₺${budget.amount.toStringAsFixed(2)}',
          createdAt: now,
          data: {'budgetId': budget.id, 'spent': spent, 'limit': budget.amount},
        ));
      }
    }

    for (var notification in notifications) {
      await addNotification(notification);
    }

    return notifications;
  }

  Future<AppNotification?> generateWeeklySummary() async {
    final transactions = await _dataService.getTransactions();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final weekTransactions = transactions.where((t) => 
      t.date.isAfter(weekAgo) && t.date.isBefore(now)
    ).toList();

    if (weekTransactions.isEmpty) return null;

    final totalIncome = weekTransactions
        .where((t) => t.type == 'income')
        .fold<double>(0, (sum, t) => sum + t.amount);
    
    final totalExpense = weekTransactions
        .where((t) => t.type == 'expense')
        .fold<double>(0, (sum, t) => sum + t.amount);

    final notification = AppNotification(
      id: const Uuid().v4(),
      type: NotificationType.weeklySummary,
      title: 'Haftalık Özet',
      message: 'Bu hafta ₺${totalIncome.toStringAsFixed(2)} gelir, '
          '₺${totalExpense.toStringAsFixed(2)} gider yaptınız. '
          'Net: ₺${(totalIncome - totalExpense).toStringAsFixed(2)}',
      createdAt: now,
      data: {
        'income': totalIncome,
        'expense': totalExpense,
        'transactionCount': weekTransactions.length,
      },
    );

    await addNotification(notification);
    return notification;
  }

  Future<AppNotification?> generateMonthlySummary() async {
    final transactions = await _dataService.getTransactions();
    final now = DateTime.now();

    final monthTransactions = transactions.where((t) => 
      t.date.year == now.year && t.date.month == now.month
    ).toList();

    if (monthTransactions.isEmpty) return null;

    final totalIncome = monthTransactions
        .where((t) => t.type == 'income')
        .fold<double>(0, (sum, t) => sum + t.amount);
    
    final totalExpense = monthTransactions
        .where((t) => t.type == 'expense')
        .fold<double>(0, (sum, t) => sum + t.amount);

    final savingsRate = totalIncome > 0 
        ? ((totalIncome - totalExpense) / totalIncome * 100)
        : 0;

    final notification = AppNotification(
      id: const Uuid().v4(),
      type: NotificationType.monthlySummary,
      title: 'Aylık Özet',
      message: 'Bu ay ₺${totalIncome.toStringAsFixed(2)} gelir, '
          '₺${totalExpense.toStringAsFixed(2)} gider yaptınız. '
          'Tasarruf oranı: %${savingsRate.toStringAsFixed(1)}',
      createdAt: now,
      data: {
        'income': totalIncome,
        'expense': totalExpense,
        'savingsRate': savingsRate,
        'transactionCount': monthTransactions.length,
      },
    );

    await addNotification(notification);
    return notification;
  }

  /// Get all notifications
  Future<List<AppNotification>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('notifications') ?? '[]';
    final List<dynamic> list = jsonDecode(json);
    return list.map((item) => AppNotification.fromJson(item)).toList();
  }

  /// Get notifications from last 30 days
  Future<List<AppNotification>> getNotificationHistory() async {
    final notifications = await getNotifications();
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    return notifications.where((n) {
      return n.createdAt.isAfter(thirtyDaysAgo);
    }).toList();
  }

  /// Add notification
  Future<void> addNotification(AppNotification notification) async {
    final notifications = await getNotifications();
    notifications.insert(0, notification);
    
    // Keep only last 50 notifications
    if (notifications.length > 50) {
      notifications.removeRange(50, notifications.length);
    }
    
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString('notifications', json);
  }

  /// Mark notification as read
  Future<void> markAsRead(String id) async {
    final notifications = await getNotifications();
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(notifications.map((n) => n.toJson()).toList());
      await prefs.setString('notifications', json);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final notifications = await getNotifications();
    final updated = notifications.map((n) => n.copyWith(isRead: true)).toList();
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(updated.map((n) => n.toJson()).toList());
    await prefs.setString('notifications', json);
  }

  /// Mark notification as dismissed
  Future<void> markAsDismissed(String id) async {
    final notifications = await getNotifications();
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isDismissed: true);
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(notifications.map((n) => n.toJson()).toList());
      await prefs.setString('notifications', json);
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String id) async {
    final notifications = await getNotifications();
    notifications.removeWhere((n) => n.id == id);
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString('notifications', json);
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notifications', '[]');
  }

  /// Clean up old notifications (older than 30 days)
  Future<void> cleanupOldNotifications() async {
    final notifications = await getNotifications();
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    final filtered = notifications.where((n) {
      return n.createdAt.isAfter(thirtyDaysAgo);
    }).toList();
    
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(filtered.map((n) => n.toJson()).toList());
    await prefs.setString('notifications', json);
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  /// Check if recent notification exists
  bool _hasRecentNotification(String budgetId, NotificationType type) {
    return false;
  }
}
