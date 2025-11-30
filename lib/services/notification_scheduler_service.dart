import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

// Notification priority enum
enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

class NotificationSchedulerService {
  static final NotificationSchedulerService _instance =
      NotificationSchedulerService._internal();
  factory NotificationSchedulerService() => _instance;
  NotificationSchedulerService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    // Android 13+ requires runtime permission
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    bool? androidGranted;
    if (androidPlugin != null) {
      androidGranted = await androidPlugin.requestNotificationsPermission();
    }

    // iOS permissions
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    bool? iosGranted;
    if (iosPlugin != null) {
      iosGranted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return androidGranted ?? iosGranted ?? false;
  }

  /// Schedule a notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    List<AndroidNotificationAction>? actions,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'budget_notifications',
      'Budget Notifications',
      channelDescription: 'Notifications for budget alerts and reminders',
      importance: _getImportance(priority),
      priority: Priority.high,
      actions: actions,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Schedule a periodic notification
  Future<void> schedulePeriodicNotification({
    required int id,
    required String title,
    required String body,
    required RepeatInterval interval,
    TimeOfDay? timeOfDay,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'periodic_notifications',
      'Periodic Notifications',
      channelDescription: 'Daily and weekly summaries',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    if (timeOfDay != null) {
      // Schedule at specific time
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );

      // If the time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: _getDateTimeComponents(interval),
      );
    } else {
      // Use default periodic scheduling
      await _notifications.periodicallyShow(
        id,
        title,
        body,
        interval,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    List<AndroidNotificationAction>? actions,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'instant_notifications',
      'Instant Notifications',
      channelDescription: 'Immediate notifications',
      importance: _getImportance(priority),
      priority: Priority.high,
      actions: actions,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Implement navigation based on payload
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Convert priority to importance
  Importance _getImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.urgent:
        return Importance.max;
      default:
        return Importance.defaultImportance;
    }
  }

  /// Get date time components for repeat interval
  DateTimeComponents? _getDateTimeComponents(RepeatInterval interval) {
    switch (interval) {
      case RepeatInterval.daily:
        return DateTimeComponents.time;
      case RepeatInterval.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      default:
        return null;
    }
  }
}

