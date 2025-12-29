import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'backup_service.dart';

class AutoBackupService {
  static final AutoBackupService _instance = AutoBackupService._internal();
  factory AutoBackupService() => _instance;
  AutoBackupService._internal();

  final BackupService _backupService = BackupService();
  final ValueNotifier<bool> isAutoBackupEnabledNotifier = ValueNotifier<bool>(false);
  Timer? _dailyBackupTimer;
  
  static const String _lastAutoBackupKey = 'last_auto_backup_date';
  static const String _autoBackupEnabledKey = 'auto_backup_enabled';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    isAutoBackupEnabledNotifier.value = prefs.getBool(_autoBackupEnabledKey) ?? false;
    await _scheduleAutoBackup();
  }

  Future<void> _scheduleAutoBackup() async {
    _dailyBackupTimer?.cancel();
    
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_autoBackupEnabledKey) ?? false;
    
    if (!isEnabled) {
      debugPrint('Otomatik yedekleme devre dışı');
      return;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      debugPrint('Otomatik yedekleme: Kullanıcı oturum açmamış, planlanmadı');
      return;
    }

    final now = DateTime.now();
    var nextBackup = DateTime(now.year, now.month, now.day, 2, 0);
    
    if (nextBackup.isBefore(now)) {
      nextBackup = nextBackup.add(const Duration(days: 1));
    }

    final duration = nextBackup.difference(now);
    
    _dailyBackupTimer = Timer(duration, () {
      _performAutoBackup();
      _scheduleAutoBackup();
    });

    debugPrint('Otomatik yedekleme planlandı: ${nextBackup.toString()}');
  }

  Future<void> _performAutoBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBackup = prefs.getString(_lastAutoBackupKey);
      final now = DateTime.now();
      
      if (lastBackup != null) {
        final lastBackupDate = DateTime.parse(lastBackup);
        if (now.difference(lastBackupDate).inHours < 24) {
          debugPrint('Otomatik yedekleme: 24 saat henüz geçmedi');
          return;
        }
      }

      if (FirebaseAuth.instance.currentUser == null) {
        debugPrint('Otomatik yedekleme: Kullanıcı oturum açmamış');
        return;
      }

      debugPrint('Otomatik yedekleme başlatılıyor...');
      final success = await _backupService.uploadToCloud();
      
      if (success) {
        await prefs.setString(_lastAutoBackupKey, now.toIso8601String());
        debugPrint('Otomatik yedekleme başarılı');
      } else {
        debugPrint('Otomatik yedekleme başarısız');
      }
    } catch (e) {
      debugPrint('Otomatik yedekleme hatası: $e');
    }
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupEnabledKey, enabled);
    isAutoBackupEnabledNotifier.value = enabled;
    
    if (enabled) {
      await _scheduleAutoBackup();
    } else {
      _dailyBackupTimer?.cancel();
      _dailyBackupTimer = null;
    }
  }

  // Backward compatibility for tests and other calls
  Future<void> enableAutoBackup(bool enabled) => setEnabled(enabled);

  Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupEnabledKey) ?? false;
  }

  Future<DateTime?> getLastAutoBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackup = prefs.getString(_lastAutoBackupKey);
    return lastBackup != null ? DateTime.parse(lastBackup) : null;
  }

  void dispose() {
    _dailyBackupTimer?.cancel();
  }

  Future<void> checkAndPerformBackupIfNeeded() async {
    final isEnabled = await isAutoBackupEnabled();
    if (!isEnabled || FirebaseAuth.instance.currentUser == null) {
      return;
    }

    final lastBackup = await getLastAutoBackupDate();
    if (lastBackup == null) {
      await _performAutoBackup();
      return;
    }

    final now = DateTime.now();
    final hoursSinceLastBackup = now.difference(lastBackup).inHours;
    
    if (hoursSinceLastBackup >= 24) {
      await _performAutoBackup();
    }
  }
}