import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scheduled_notification.dart';

class ScheduledNotificationRepository {
  static final ScheduledNotificationRepository _instance =
      ScheduledNotificationRepository._internal();
  factory ScheduledNotificationRepository() => _instance;
  ScheduledNotificationRepository._internal();

  static const String _key = 'scheduled_notifications';
  Future<List<ScheduledNotification>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key) ?? '[]';
    final List<dynamic> list = jsonDecode(json);
    return list.map((item) => ScheduledNotification.fromJson(item)).toList();
  }
  Future<void> save(ScheduledNotification notification) async {
    final notifications = await getAll();
    notifications.removeWhere((n) => n.id == notification.id);
    notifications.add(notification);
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_key, json);
  }
  Future<void> saveAll(List<ScheduledNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_key, json);
  }
  Future<void> delete(String id) async {
    final notifications = await getAll();
    notifications.removeWhere((n) => n.id == id);

    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_key, json);
  }
  Future<void> deleteByPlatformId(int platformId) async {
    final notifications = await getAll();
    notifications.removeWhere((n) => n.platformId == platformId);

    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_key, json);
  }
  Future<ScheduledNotification?> getById(String id) async {
    final notifications = await getAll();
    try {
      return notifications.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }
  Future<List<ScheduledNotification>> getByType(String type) async {
    final notifications = await getAll();
    return notifications.where((n) => n.type == type).toList();
  }
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, '[]');
  }
  Future<void> cleanupPast() async {
    final notifications = await getAll();
    final now = DateTime.now();

    final active = notifications.where((n) {
      return n.scheduledFor.isAfter(now) || n.isRecurring;
    }).toList();

    await saveAll(active);
  }
}
