import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  Locale _locale = const Locale('tr'); // Varsayılan dil Türkçe

  Locale get locale => _locale;

  static final LanguageService _instance = LanguageService._internal();
  
  factory LanguageService() {
    return _instance;
  }

  LanguageService._internal() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code');
    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale loc) async {
    if (_locale == loc) return;
    
    _locale = loc;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', loc.languageCode);
    notifyListeners();
  }
}
