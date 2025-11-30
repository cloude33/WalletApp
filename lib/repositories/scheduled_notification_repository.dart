import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scheduled_notification.dart';

class ScheduledNotificationRepository {
  static final ScheduledNotificationRepository _instance =
      ScheduledNotificationRepository._internal();
  factory ScheduledNotificationRepository() => _instance;
  ScheduledNotificationRepository._internal();

  static const String _key = 'scheduled_notifications';

  /// Get all scheduled notifications
  Future<List<ScheduledNotification>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key) ?? '[]';
    final List<dynamic> list = jsonDecode(json);
    return list.map((item) => ScheduledNotification.fromJson(item)).toList();
  }

  /// Save scheduled notification
  Future<void> save(ScheduledNotification notification) async {
    final notifications = await getAll();
    
    // Remove existing notification with same ID if exists
    notifications.removeWhere((n) => n.id == notification.id);
    
    // Add new notification
    notifications.add(notification);
    
    // Save to storage
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_key, json);
  }

  /// Save multiple scheduled notifications
  Future<void> saveAll(List<ScheduledNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_key, json);
  }

  /// Delete scheduled notification
  Future<void> delete(String id) async {
    final notifications = await getAll();
    notifications.removeWhere((n) => n.id == id);
    
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_key, json);
  }

  /// Delete by platform ID
  Future<void> deleteByPlatformId(int platformId) async {
    final notifications = await getAll();
    notifications.removeWhere((n) => n.platformId == platformId);
    
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_key, json);
  }

  /// Get scheduled notification by ID
  Future<ScheduledNotification?> getById(String id) async {
    final notifications = await getAll();
    try {
      return notifications.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get scheduled notifications by type
  Future<List<ScheduledNotification>> getByType(String type) async {
    final notifications = await getAll();
    return notifications.where((n) => n.type == type).toList();
  }

  /// Clear all scheduled notifications
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, '[]');
  }

  /// Clean up past scheduled notifications
  Future<void> cleanupPast() async {
    final notifications = await getAll();
    final now = DateTime.now();
    
    final active = notifications.where((n) {
      return n.scheduledFor.isAfter(now) || n.isRecurring;
    }).toList();
    
    await saveAll(active);
  }
}
