import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_preferences.dart';

class NotificationPreferencesService {
  static final NotificationPreferencesService _instance =
      NotificationPreferencesService._internal();
  factory NotificationPreferencesService() => _instance;
  NotificationPreferencesService._internal();

  static const String _prefsKey = 'notification_preferences';
  NotificationPreferences? _cachedPreferences;
  Future<NotificationPreferences> getPreferences() async {
    if (_cachedPreferences != null) return _cachedPreferences!;

    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);

    if (json == null) {
      _cachedPreferences = NotificationPreferences.defaults;
      await savePreferences(_cachedPreferences!);
      return _cachedPreferences!;
    }

    _cachedPreferences = NotificationPreferences.fromJson(jsonDecode(json));
    return _cachedPreferences!;
  }
  Future<void> savePreferences(NotificationPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(preferences.toJson()));
    _cachedPreferences = preferences;
  }
  Future<void> updatePreference({
    bool? dailySummaryEnabled,
    bool? weeklySummaryEnabled,
    bool? billRemindersEnabled,
    int? billReminderDays,
    bool? installmentRemindersEnabled,
    int? installmentReminderDays,
  }) async {
    final current = await getPreferences();
    final updated = current.copyWith(
      dailySummaryEnabled: dailySummaryEnabled,
      weeklySummaryEnabled: weeklySummaryEnabled,
      billRemindersEnabled: billRemindersEnabled,
      billReminderDays: billReminderDays,
      installmentRemindersEnabled: installmentRemindersEnabled,
      installmentReminderDays: installmentReminderDays,
    );
    await savePreferences(updated);
  }
  Future<void> resetToDefaults() async {
    await savePreferences(NotificationPreferences.defaults);
  }
  void clearCache() {
    _cachedPreferences = null;
  }
}
