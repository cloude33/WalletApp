import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/security/security_event.dart';
import 'security_notification_service.dart';
import 'auth_service.dart';
import 'pin_service.dart';

/// Güvenlik bildirim entegrasyonu örneği
/// 
/// Bu sınıf güvenlik bildirim servisinin diğer güvenlik servisleri ile
/// nasıl entegre edilebileceğini gösterir.
/// 
/// Gerçek implementasyonda bu entegrasyon AuthService veya
/// SecurityService içinde yapılabilir.
class SecurityNotificationIntegrationExample {
  final SecurityNotificationService _notificationService;
  final AuthService _authService;
  final PINService _pinService;
  
  SecurityNotificationIntegrationExample({
    SecurityNotificationService? notificationService,
    AuthService? authService,
    PINService? pinService,
  }) : _notificationService = notificationService ?? SecurityNotificationService(),
       _authService = authService ?? AuthService(),
       _pinService = pinService ?? PINService();

  /// Servisleri başlatır ve event listener'ları kurar
  Future<void> initialize() async {
    try {
      await _notificationService.initialize();
      await _authService.initialize();
      await _pinService.initialize();
      
      // Auth service event'lerini dinle
      _authService.authStateStream.listen(_handleAuthStateChange);
      
      debugPrint('Security notification integration initialized');
    } catch (e) {
      debugPrint('Failed to initialize security notification integration: $e');
      rethrow;
    }
  }

  /// PIN doğrulama başarısızlığını işler
  /// 
  /// Bu metod PIN servisinden çağrılabilir
  Future<void> handlePINFailure({
    required String userId,
    required int remainingAttempts,
    Duration? lockoutDuration,
  }) async {
    try {
      final event = SecurityEvent.pinFailed(
        userId: userId,
        remainingAttempts: remainingAttempts,
      );

      await _notificationService.notifyFailedLogin(
        event: event,
        remainingAttempts: remainingAttempts,
        lockoutDuration: lockoutDuration,
      );
      
      debugPrint('PIN failure notification sent for user: $userId');
    } catch (e) {
      debugPrint('Failed to handle PIN failure notification: $e');
    }
  }

  /// Yeni cihaz girişini işler
  /// 
  /// Bu metod auth service'den çağrılabilir
  Future<void> handleNewDeviceLogin({
    required String userId,
    required String deviceId,
    required String deviceName,
    required String platform,
    String? location,
  }) async {
    try {
      final event = SecurityEvent.sessionStarted(
        userId: userId,
        authMethod: 'pin',
        metadata: {
          'deviceId': deviceId,
          'deviceName': deviceName,
          'platform': platform,
          'location': location,
        },
      );

      final deviceInfo = {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'platform': platform,
        if (location != null) 'location': location,
      };

      await _notificationService.notifyNewDeviceLogin(
        event: event,
        deviceInfo: deviceInfo,
      );
      
      debugPrint('New device login notification sent for user: $userId');
    } catch (e) {
      debugPrint('Failed to handle new device login notification: $e');
    }
  }

  /// Güvenlik ayarları değişikliğini işler
  /// 
  /// Bu metod security settings screen'den çağrılabilir
  Future<void> handleSecuritySettingsChange({
    required String userId,
    required String settingName,
    required String oldValue,
    required String newValue,
  }) async {
    try {
      final event = SecurityEvent.securitySettingsChanged(
        userId: userId,
        setting: settingName,
        oldValue: oldValue,
        newValue: newValue,
      );

      await _notificationService.notifySecuritySettingsChange(
        event: event,
        settingName: settingName,
        oldValue: oldValue,
        newValue: newValue,
      );
      
      debugPrint('Security settings change notification sent for user: $userId');
    } catch (e) {
      debugPrint('Failed to handle security settings change notification: $e');
    }
  }

  /// Şüpheli aktiviteyi işler
  /// 
  /// Bu metod security service'den çağrılabilir
  Future<void> handleSuspiciousActivity({
    required String userId,
    required String activity,
    required String details,
  }) async {
    try {
      final event = SecurityEvent.suspiciousActivity(
        userId: userId,
        activity: activity,
        details: details,
      );

      await _notificationService.notifySuspiciousActivity(
        event: event,
        activityDetails: details,
      );
      
      debugPrint('Suspicious activity notification sent for user: $userId');
    } catch (e) {
      debugPrint('Failed to handle suspicious activity notification: $e');
    }
  }

  /// Auth state değişikliklerini işler
  void _handleAuthStateChange(dynamic authState) {
    // Bu metod auth state değişikliklerini dinler
    // Gerekirse ek bildirimler gönderebilir
    debugPrint('Auth state changed: $authState');
  }

  /// Bildirim ayarlarını alır
  Future<SecurityNotificationSettings> getNotificationSettings() async {
    return await _notificationService.getSettings();
  }

  /// Bildirim ayarlarını günceller
  Future<void> updateNotificationSettings(SecurityNotificationSettings settings) async {
    await _notificationService.updateSettings(settings);
  }

  /// Bilinen cihazları alır
  Future<Set<String>> getKnownDevices() async {
    return await _notificationService.getKnownDevices();
  }

  /// Cihazı bilinen cihazlar listesinden kaldırır
  Future<void> removeKnownDevice(String deviceId) async {
    await _notificationService.removeKnownDevice(deviceId);
  }

  /// Tüm bilinen cihazları temizler
  Future<void> clearKnownDevices() async {
    await _notificationService.clearKnownDevices();
  }
}

/// Güvenlik bildirim entegrasyonu için singleton
class SecurityNotificationIntegration {
  static SecurityNotificationIntegrationExample? _instance;
  
  /// Singleton instance'ı döndürür
  static SecurityNotificationIntegrationExample get instance {
    _instance ??= SecurityNotificationIntegrationExample();
    return _instance!;
  }
  
  /// Test için instance'ı set eder
  static void setInstance(SecurityNotificationIntegrationExample integration) {
    _instance = integration;
  }
  
  /// Instance'ı temizler
  static void reset() {
    _instance = null;
  }
}