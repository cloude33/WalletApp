
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/app_notification.dart';
import 'data_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final DataService _dataService = DataService();

  Future<AppNotification?> generateWeeklySummary() async {
    final transactions = await _dataService.getTransactions();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final weekTransactions = transactions
        .where((t) => t.date.isAfter(weekAgo) && t.date.isBefore(now))
        .toList();

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
      message:
          'Bu hafta ₺${totalIncome.toStringAsFixed(2)} gelir, '
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

    final monthTransactions = transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();

    if (monthTransactions.isEmpty) return null;

    final totalIncome = monthTransactions
        .where((t) => t.type == 'income')
        .fold<double>(0, (sum, t) => sum + t.amount);

    final totalExpense = monthTransactions
        .where((t) => t.type == 'expense')
        .fold<double>(0, (sum, t) => sum + t.amount);

    final netAmount = totalIncome - totalExpense;

    final notification = AppNotification(
      id: const Uuid().v4(),
      type: NotificationType.monthlySummary,
      title: 'Aylık Özet',
      message:
          'Bu ay ₺${totalIncome.toStringAsFixed(2)} gelir, '
          '₺${totalExpense.toStringAsFixed(2)} gider yaptınız. '
          'Net: ₺${netAmount.toStringAsFixed(2)}',
      createdAt: now,
      data: {
        'income': totalIncome,
        'expense': totalExpense,
        'netAmount': netAmount,
        'transactionCount': monthTransactions.length,
      },
    );

    await addNotification(notification);
    return notification;
  }
  Future<List<AppNotification>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('notifications') ?? '[]';
    final List<dynamic> list = jsonDecode(json);
    return list.map((item) => AppNotification.fromJson(item)).toList();
  }
  Future<List<AppNotification>> getNotificationHistory() async {
    final notifications = await getNotifications();
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    return notifications.where((n) {
      return n.createdAt.isAfter(thirtyDaysAgo);
    }).toList();
  }
  Future<void> addNotification(AppNotification notification) async {
    final notifications = await getNotifications();
    notifications.insert(0, notification);
    if (notifications.length > 50) {
      notifications.removeRange(50, notifications.length);
    }

    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString('notifications', json);
  }
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
  Future<void> markAllAsRead() async {
    final notifications = await getNotifications();
    final updated = notifications.map((n) => n.copyWith(isRead: true)).toList();
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(updated.map((n) => n.toJson()).toList());
    await prefs.setString('notifications', json);
  }
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
  Future<void> deleteNotification(String id) async {
    final notifications = await getNotifications();
    notifications.removeWhere((n) => n.id == id);
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString('notifications', json);
  }
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notifications', '[]');
  }
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
  Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((n) => !n.isRead).length;
  }
  Future<void> scheduleBillReminder({
    required String billId,
    required String billName,
    double? amount,
    required DateTime dueDate,
    required DateTime reminderDate,
  }) async {
    if (reminderDate.isBefore(DateTime.now())) return;

    final notification = AppNotification(
      id: 'bill_$billId',
      type: NotificationType.billReminder,
      priority: NotificationPriority.high,
      title: 'Fatura Hatırlatması',
      message: amount != null
          ? '$billName faturanız: ₺${amount.toStringAsFixed(2)} - Son ödeme: ${_formatDate(dueDate)}'
          : '$billName faturanız - Son ödeme: ${_formatDate(dueDate)}',
      createdAt: reminderDate,
      data: {
        'billId': billId,
        'billName': billName,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
      },
      actions: [
        const NotificationAction(id: 'pay', title: 'Öde'),
        const NotificationAction(id: 'snooze', title: 'Ertele'),
      ],
    );

    await addNotification(notification);
  }
  Future<void> cancelBillReminder(String billId) async {
    final notificationId = 'bill_$billId';
    await deleteNotification(notificationId);
  }
  Future<List<AppNotification>> checkUpcomingBills() async {
    return [];
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}
