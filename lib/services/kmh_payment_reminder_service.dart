import 'package:uuid/uuid.dart';
import '../models/payment_plan.dart';
import '../models/app_notification.dart';
import '../models/scheduled_notification.dart';
import '../repositories/payment_plan_repository.dart';
import '../repositories/scheduled_notification_repository.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
class KmhPaymentReminderService {
  final PaymentPlanRepository _planRepository;
  final ScheduledNotificationRepository _notificationRepository;
  final DataService _dataService;
  final NotificationService _notificationService;
  final Uuid _uuid = const Uuid();

  KmhPaymentReminderService({
    PaymentPlanRepository? planRepository,
    ScheduledNotificationRepository? notificationRepository,
    DataService? dataService,
    NotificationService? notificationService,
  })  : _planRepository = planRepository ?? PaymentPlanRepository(),
        _notificationRepository = notificationRepository ?? ScheduledNotificationRepository(),
        _dataService = dataService ?? DataService(),
        _notificationService = notificationService ?? NotificationService();
  Future<String> schedulePaymentReminder(
    PaymentPlan plan, {
    int reminderDaysBefore = 3,
  }) async {
    final wallets = await _dataService.getWallets();
    final wallet = wallets.firstWhere(
      (w) => w.id == plan.walletId,
      orElse: () => throw Exception('Wallet not found'),
    );
    final now = DateTime.now();
    final nextPaymentDate = DateTime(
      now.month == 12 ? now.year + 1 : now.year,
      now.month == 12 ? 1 : now.month + 1,
      1,
    );
    final reminderDate = nextPaymentDate.subtract(
      Duration(days: reminderDaysBefore),
    );
    if (reminderDate.isBefore(DateTime.now())) {
      return '';
    }
    final notificationId = _uuid.v4();
    final platformId = DateTime.now().millisecondsSinceEpoch % 2147483647;

    final scheduledNotification = ScheduledNotification(
      id: notificationId,
      platformId: platformId,
      type: 'kmhPaymentReminder',
      scheduledFor: reminderDate,
      data: {
        'walletId': wallet.id,
        'walletName': wallet.name,
        'planId': plan.id,
        'paymentAmount': plan.monthlyPayment,
        'paymentDate': nextPaymentDate.toIso8601String(),
        'currentDebt': wallet.usedCredit,
      },
      isRecurring: true,
      repeatInterval: 'monthly',
    );
    await _notificationRepository.save(scheduledNotification);

    return notificationId;
  }
  Future<void> cancelPaymentReminder(String planId) async {
    final notifications = await _notificationRepository.getAll();
    final planNotifications = notifications.where((n) {
      return n.type == 'kmhPaymentReminder' && 
             n.data['planId'] == planId;
    }).toList();

    for (final notification in planNotifications) {
      await _notificationRepository.delete(notification.id);
    }
  }
  Future<void> sendPaymentReminder(PaymentPlan plan) async {
    final wallets = await _dataService.getWallets();
    final wallet = wallets.firstWhere(
      (w) => w.id == plan.walletId,
      orElse: () => throw Exception('Wallet not found'),
    );
    final now = DateTime.now();
    final nextPaymentDate = DateTime(
      now.month == 12 ? now.year + 1 : now.year,
      now.month == 12 ? 1 : now.month + 1,
      1,
    );
    final notification = AppNotification(
      id: _uuid.v4(),
      type: NotificationType.kmhInterestAccrued,
      priority: NotificationPriority.high,
      title: 'KMH Ödeme Hatırlatması',
      message: '${wallet.name}: Ödeme planınıza göre '
          '₺${plan.monthlyPayment.toStringAsFixed(2)} ödeme yapmanız önerilir. '
          'Hedef tarih: ${_formatDate(nextPaymentDate)}',
      createdAt: DateTime.now(),
      data: {
        'walletId': wallet.id,
        'walletName': wallet.name,
        'planId': plan.id,
        'paymentAmount': plan.monthlyPayment,
        'paymentDate': nextPaymentDate.toIso8601String(),
        'currentDebt': wallet.usedCredit,
        'remainingMonths': plan.durationMonths,
      },
      actions: [
        const NotificationAction(id: 'view_plan', title: 'Planı Görüntüle'),
        const NotificationAction(id: 'make_payment', title: 'Ödeme Yap'),
        const NotificationAction(id: 'snooze', title: 'Ertele'),
      ],
    );

    await _notificationService.addNotification(notification);
  }
  Future<int> checkUpcomingPayments({int daysAhead = 3}) async {
    final plans = await _planRepository.getAllPlans();
    final activePlans = plans.where((p) => p.isActive).toList();

    int remindersSent = 0;
    final now = DateTime.now();
    final checkUntil = now.add(Duration(days: daysAhead));

    for (final plan in activePlans) {
      final nextPaymentDate = DateTime(
        now.month == 12 ? now.year + 1 : now.year,
        now.month == 12 ? 1 : now.month + 1,
        1,
      );
      if (nextPaymentDate.isAfter(now) && 
          nextPaymentDate.isBefore(checkUntil)) {
        try {
          await sendPaymentReminder(plan);
          remindersSent++;
        } catch (e) {
          print('Failed to send payment reminder for plan ${plan.id}: $e');
        }
      }
    }

    return remindersSent;
  }
  Future<void> rescheduleAllReminders() async {
    final notifications = await _notificationRepository.getAll();
    final kmhReminders = notifications.where((n) => 
      n.type == 'kmhPaymentReminder'
    ).toList();

    for (final notification in kmhReminders) {
      await _notificationRepository.delete(notification.id);
    }
    final plans = await _planRepository.getAllPlans();
    final activePlans = plans.where((p) => p.isActive).toList();

    for (final plan in activePlans) {
      try {
        await schedulePaymentReminder(plan);
      } catch (e) {
        print('Failed to schedule reminder for plan ${plan.id}: $e');
      }
    }
  }
  Future<void> updatePaymentReminder(PaymentPlan plan) async {
    await cancelPaymentReminder(plan.id);
    
    if (plan.isActive) {
      await schedulePaymentReminder(plan);
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}
