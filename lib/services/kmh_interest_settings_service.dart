import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kmh_interest_settings.dart';

class KmhInterestSettingsService {
  static const String _storageKey = 'kmh_interest_settings';

  Future<KmhInterestSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    
    if (jsonString == null) {
      return KmhInterestSettings.defaults;
    }

    try {
      final json = jsonDecode(jsonString);
      return KmhInterestSettings.fromJson(json);
    } catch (e) {
      return KmhInterestSettings.defaults;
    }
  }

  Future<void> updateSettings(KmhInterestSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(settings.toJson());
    await prefs.setString(_storageKey, jsonString);
  }
}
