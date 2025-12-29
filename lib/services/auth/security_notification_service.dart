import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/app_notification.dart';
import '../../models/security/security_event.dart';
import '../notification_service.dart';
import 'secure_storage_service.dart';

/// Güvenlik bildirim servisi
/// 
/// Bu servis güvenlik olayları için bildirim yönetimi yapar:
/// - Başarısız giriş bildirimleri
/// - Yeni cihaz bildirimleri  
/// - Güvenlik ayar değişiklik bildirimleri
/// 
/// Implements Requirements:
/// - 10.2: Başarısız giriş denemeleri olduğunda kullanıcıyı bilgilendirmeli
/// - 10.3: Yeni cihazdan giriş yapıldığında email/SMS bildirimi göndermeli
/// - 10.4: Güvenlik ayarları değiştirildiğinde değişiklik bildirimini göstermeli
class SecurityNotificationService {
  static final SecurityNotificationService _instance = SecurityNotificationService._internal();
  factory SecurityNotificationService() => _instance;
  SecurityNotificationService._internal();

  final NotificationService _notificationService = NotificationService();
  final AuthSecureStorageService _storage = AuthSecureStorageService();
  
  bool _isInitialized = false;
  
  // Bildirim ayarları
  SecurityNotificationSettings _settings = SecurityNotificationSettings.defaultSettings();
  
  // Cihaz tanımlama için
  String? _currentDeviceId;
  Set<String> _knownDevices = {};

  /// Servisi başlatır
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _storage.initialize();
      await _loadSettings();
      await _loadKnownDevices();
      await _generateDeviceId();
      
      _isInitialized = true;
      debugPrint('Security Notification Service initialized successfully');
    } catch (e) {
      throw Exception('Failed to initialize Security Notification service: ${e.toString()}');
    }
  }

  /// Başarısız giriş bildirimi gönderir
  /// 
  /// [event] - Güvenlik olayı
  /// [remainingAttempts] - Kalan deneme sayısı
  /// [lockoutDuration] - Kilitleme süresi (varsa)
  /// 
  /// Implements Requirement 10.2: Başarısız giriş denemeleri olduğunda kullanıcıyı bilgilendirmeli
  Future<void> notifyFailedLogin({
    required SecurityEvent event,
    int? remainingAttempts,
    Duration? lockoutDuration,
  }) async {
    try {
      await _ensureInitialized();
      
      if (!_settings.enableFailedLoginNotifications) {
        debugPrint('Failed login notifications disabled');
        return;
      }

      String title;
      String message;
      NotificationPriority priority;

      if (lockoutDuration != null) {
        // Hesap kilitlendi
        title = 'Hesap Kilitlendi';
        message = 'Çok fazla başarısız giriş denemesi nedeniyle hesabınız '
                 '${_formatDuration(lockoutDuration)} süreyle kilitlendi.';
        priority = NotificationPriority.urgent;
      } else if (remainingAttempts != null && remainingAttempts <= 2) {
        // Kritik seviye
        title = 'Güvenlik Uyarısı';
        message = 'Başarısız giriş denemesi! Kalan deneme hakkınız: $remainingAttempts';
        priority = NotificationPriority.high;
      } else {
        // Normal uyarı
        title = 'Başarısız Giriş Denemesi';
        message = 'Hesabınızda başarısız bir giriş denemesi tespit edildi.';
        priority = NotificationPriority.normal;
      }

      final notification = AppNotification(
        id: 'security_failed_login_${DateTime.now().millisecondsSinceEpoch}',
        type: lockoutDuration != null 
            ? NotificationType.securityAccountLocked 
            : NotificationType.securityFailedLogin,
        priority: priority,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        data: {
          'eventType': 'failed_login',
          'eventId': event.eventId,
          'remainingAttempts': remainingAttempts,
          'lockoutDuration': lockoutDuration?.inMilliseconds,
          'timestamp': event.timestamp.toIso8601String(),
          'deviceId': _currentDeviceId,
        },
        actions: lockoutDuration == null ? [
          const NotificationAction(
            id: 'view_security',
            title: 'Güvenlik Ayarları',
          ),
        ] : null,
      );

      await _notificationService.addNotification(notification);
      
      // Kritik durumlarda ek güvenlik önlemleri
      if (priority == NotificationPriority.urgent) {
        await _handleCriticalSecurityEvent(event);
      }
      
      debugPrint('Failed login notification sent: $title');
    } catch (e) {
      debugPrint('Failed to send failed login notification: $e');
    }
  }

  /// Yeni cihaz giriş bildirimi gönderir
  /// 
  /// [event] - Güvenlik olayı
  /// [deviceInfo] - Cihaz bilgileri
  /// 
  /// Implements Requirement 10.3: Yeni cihazdan giriş yapıldığında email/SMS bildirimi göndermeli
  Future<void> notifyNewDeviceLogin({
    required SecurityEvent event,
    required Map<String, dynamic> deviceInfo,
  }) async {
    try {
      await _ensureInitialized();
      
      if (!_settings.enableNewDeviceNotifications) {
        debugPrint('New device notifications disabled');
        return;
      }

      final deviceId = deviceInfo['deviceId'] as String?;
      if (deviceId == null) {
        debugPrint('Device ID not provided for new device notification');
        return;
      }

      // Bilinen cihaz mı kontrol et
      if (_knownDevices.contains(deviceId)) {
        debugPrint('Device already known, skipping new device notification');
        return;
      }

      // Yeni cihazı kaydet
      await _addKnownDevice(deviceId);

      final deviceName = deviceInfo['deviceName'] as String? ?? 'Bilinmeyen Cihaz';
      final platform = deviceInfo['platform'] as String? ?? 'Bilinmeyen Platform';
      final location = deviceInfo['location'] as String?;

      String message = 'Hesabınıza yeni bir cihazdan giriş yapıldı:\n'
                      'Cihaz: $deviceName\n'
                      'Platform: $platform';
      
      if (location != null) {
        message += '\nKonum: $location';
      }

      final notification = AppNotification(
        id: 'security_new_device_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.securityNewDevice,
        priority: NotificationPriority.high,
        title: 'Yeni Cihazdan Giriş',
        message: message,
        createdAt: DateTime.now(),
        data: {
          'eventType': 'new_device_login',
          'eventId': event.eventId,
          'deviceId': deviceId,
          'deviceName': deviceName,
          'platform': platform,
          'location': location,
          'timestamp': event.timestamp.toIso8601String(),
        },
        actions: [
          const NotificationAction(
            id: 'approve_device',
            title: 'Bu Benim',
          ),
          const NotificationAction(
            id: 'secure_account',
            title: 'Hesabı Güvenli Hale Getir',
          ),
        ],
      );

      await _notificationService.addNotification(notification);
      
      // Email/SMS bildirimi simülasyonu (gerçek implementasyon için harici servis gerekir)
      await _sendExternalNotification(
        type: 'new_device_login',
        title: 'Yeni Cihazdan Giriş',
        message: message,
        deviceInfo: deviceInfo,
      );
      
      debugPrint('New device login notification sent for device: $deviceName');
    } catch (e) {
      debugPrint('Failed to send new device login notification: $e');
    }
  }

  /// Güvenlik ayarları değişiklik bildirimi gönderir
  /// 
  /// [event] - Güvenlik olayı
  /// [settingName] - Değişen ayar adı
  /// [oldValue] - Eski değer
  /// [newValue] - Yeni değer
  /// 
  /// Implements Requirement 10.4: Güvenlik ayarları değiştirildiğinde değişiklik bildirimini göstermeli
  Future<void> notifySecuritySettingsChange({
    required SecurityEvent event,
    required String settingName,
    required String oldValue,
    required String newValue,
  }) async {
    try {
      await _ensureInitialized();
      
      if (!_settings.enableSettingsChangeNotifications) {
        debugPrint('Settings change notifications disabled');
        return;
      }

      final settingDisplayName = _getSettingDisplayName(settingName);
      final oldDisplayValue = _getSettingDisplayValue(settingName, oldValue);
      final newDisplayValue = _getSettingDisplayValue(settingName, newValue);

      final message = 'Güvenlik ayarınız değiştirildi:\n'
                     '$settingDisplayName: $oldDisplayValue → $newDisplayValue';

      final notification = AppNotification(
        id: 'security_settings_${settingName}_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.securitySettingsChange,
        priority: NotificationPriority.normal,
        title: 'Güvenlik Ayarları Değişti',
        message: message,
        createdAt: DateTime.now(),
        data: {
          'eventType': 'settings_change',
          'eventId': event.eventId,
          'settingName': settingName,
          'oldValue': oldValue,
          'newValue': newValue,
          'timestamp': event.timestamp.toIso8601String(),
          'deviceId': _currentDeviceId,
        },
        actions: [
          const NotificationAction(
            id: 'view_settings',
            title: 'Ayarları Görüntüle',
          ),
        ],
      );

      await _notificationService.addNotification(notification);
      
      debugPrint('Security settings change notification sent: $settingDisplayName');
    } catch (e) {
      debugPrint('Failed to send security settings change notification: $e');
    }
  }

  /// Şüpheli aktivite bildirimi gönderir
  /// 
  /// [event] - Güvenlik olayı
  /// [activityDetails] - Aktivite detayları
  Future<void> notifySuspiciousActivity({
    required SecurityEvent event,
    required String activityDetails,
  }) async {
    try {
      await _ensureInitialized();
      
      if (!_settings.enableSuspiciousActivityNotifications) {
        debugPrint('Suspicious activity notifications disabled');
        return;
      }

      final notification = AppNotification(
        id: 'security_suspicious_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.securitySuspiciousActivity,
        priority: NotificationPriority.urgent,
        title: 'Şüpheli Aktivite Tespit Edildi',
        message: 'Hesabınızda şüpheli bir aktivite tespit edildi:\n$activityDetails',
        createdAt: DateTime.now(),
        data: {
          'eventType': 'suspicious_activity',
          'eventId': event.eventId,
          'activityDetails': activityDetails,
          'timestamp': event.timestamp.toIso8601String(),
          'deviceId': _currentDeviceId,
        },
        actions: [
          const NotificationAction(
            id: 'secure_account',
            title: 'Hesabı Güvenli Hale Getir',
          ),
          const NotificationAction(
            id: 'contact_support',
            title: 'Destek İle İletişim',
          ),
        ],
      );

      await _notificationService.addNotification(notification);
      
      // Kritik güvenlik olayı olarak işle
      await _handleCriticalSecurityEvent(event);
      
      debugPrint('Suspicious activity notification sent');
    } catch (e) {
      debugPrint('Failed to send suspicious activity notification: $e');
    }
  }

  /// Bildirim ayarlarını alır
  Future<SecurityNotificationSettings> getSettings() async {
    await _ensureInitialized();
    return _settings;
  }

  /// Bildirim ayarlarını günceller
  /// 
  /// [settings] - Yeni bildirim ayarları
  Future<void> updateSettings(SecurityNotificationSettings settings) async {
    try {
      await _ensureInitialized();
      
      _settings = settings;
      await _saveSettings();
      
      debugPrint('Security notification settings updated');
    } catch (e) {
      debugPrint('Failed to update security notification settings: $e');
    }
  }

  /// Bilinen cihazları alır
  Future<Set<String>> getKnownDevices() async {
    await _ensureInitialized();
    return Set.from(_knownDevices);
  }

  /// Cihazı bilinen cihazlar listesinden kaldırır
  /// 
  /// [deviceId] - Kaldırılacak cihaz ID'si
  Future<void> removeKnownDevice(String deviceId) async {
    try {
      await _ensureInitialized();
      
      _knownDevices.remove(deviceId);
      await _saveKnownDevices();
      
      debugPrint('Device removed from known devices: $deviceId');
    } catch (e) {
      debugPrint('Failed to remove known device: $e');
    }
  }

  /// Tüm bilinen cihazları temizler
  Future<void> clearKnownDevices() async {
    try {
      await _ensureInitialized();
      
      _knownDevices.clear();
      await _saveKnownDevices();
      
      debugPrint('All known devices cleared');
    } catch (e) {
      debugPrint('Failed to clear known devices: $e');
    }
  }

  /// Mevcut cihaz ID'sini alır
  String? getCurrentDeviceId() {
    return _currentDeviceId;
  }

  /// Test amaçlı servisi sıfırlar
  @visibleForTesting
  void resetForTesting() {
    _isInitialized = false;
    _settings = SecurityNotificationSettings.defaultSettings();
    _currentDeviceId = null;
    _knownDevices.clear();
  }

  // Private helper methods

  /// Servisin başlatıldığından emin olur
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Bildirim ayarlarını yükler
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('security_notification_settings');
      
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _settings = SecurityNotificationSettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('Failed to load security notification settings: $e');
      _settings = SecurityNotificationSettings.defaultSettings();
    }
  }

  /// Bildirim ayarlarını kaydeder
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(_settings.toJson());
      await prefs.setString('security_notification_settings', settingsJson);
    } catch (e) {
      debugPrint('Failed to save security notification settings: $e');
    }
  }

  /// Bilinen cihazları yükler
  Future<void> _loadKnownDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final devicesJson = prefs.getStringList('known_devices') ?? [];
      _knownDevices = devicesJson.toSet();
    } catch (e) {
      debugPrint('Failed to load known devices: $e');
      _knownDevices = {};
    }
  }

  /// Bilinen cihazları kaydeder
  Future<void> _saveKnownDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('known_devices', _knownDevices.toList());
    } catch (e) {
      debugPrint('Failed to save known devices: $e');
    }
  }

  /// Cihaz ID'si oluşturur
  Future<void> _generateDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentDeviceId = prefs.getString('device_id');
      
      if (_currentDeviceId == null) {
        _currentDeviceId = const Uuid().v4();
        await prefs.setString('device_id', _currentDeviceId!);
      }
      
      // Mevcut cihazı bilinen cihazlar listesine ekle
      await _addKnownDevice(_currentDeviceId!);
    } catch (e) {
      debugPrint('Failed to generate device ID: $e');
      _currentDeviceId = const Uuid().v4();
    }
  }

  /// Cihazı bilinen cihazlar listesine ekler
  Future<void> _addKnownDevice(String deviceId) async {
    if (!_knownDevices.contains(deviceId)) {
      _knownDevices.add(deviceId);
      await _saveKnownDevices();
    }
  }

  /// Kritik güvenlik olayını işler
  Future<void> _handleCriticalSecurityEvent(SecurityEvent event) async {
    try {
      // Kritik olayları özel bir yerde sakla
      final prefs = await SharedPreferences.getInstance();
      final criticalEvents = prefs.getStringList('critical_security_events') ?? [];
      
      criticalEvents.add(jsonEncode({
        'eventId': event.eventId,
        'timestamp': event.timestamp.toIso8601String(),
        'type': event.type.name,
        'description': event.description,
      }));
      
      // Son 100 kritik olayı sakla
      if (criticalEvents.length > 100) {
        criticalEvents.removeRange(0, criticalEvents.length - 100);
      }
      
      await prefs.setStringList('critical_security_events', criticalEvents);
      
      debugPrint('Critical security event logged: ${event.eventId}');
    } catch (e) {
      debugPrint('Failed to handle critical security event: $e');
    }
  }

  /// Harici bildirim gönderir (Email/SMS simülasyonu)
  Future<void> _sendExternalNotification({
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      // Gerçek implementasyonda burada email/SMS servisi çağrılır
      // Şimdilik sadece log yazdırıyoruz
      debugPrint('External notification sent:');
      debugPrint('Type: $type');
      debugPrint('Title: $title');
      debugPrint('Message: $message');
      
      if (deviceInfo != null) {
        debugPrint('Device Info: $deviceInfo');
      }
      
      // Simülasyon için kısa gecikme
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('Failed to send external notification: $e');
    }
  }

  /// Süreyi formatlar
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} gün';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} saat';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} dakika';
    } else {
      return '${duration.inSeconds} saniye';
    }
  }

  /// Ayar adını görüntülenebilir forma çevirir
  String _getSettingDisplayName(String settingName) {
    switch (settingName) {
      case 'pinEnabled':
        return 'PIN Kodu';
      case 'biometricEnabled':
        return 'Biyometrik Doğrulama';
      case 'twoFactorEnabled':
        return 'İki Faktörlü Doğrulama';
      case 'sessionTimeout':
        return 'Oturum Zaman Aşımı';
      case 'maxPinAttempts':
        return 'Maksimum PIN Denemesi';
      case 'lockoutDuration':
        return 'Kilitleme Süresi';
      default:
        return settingName;
    }
  }

  /// Ayar değerini görüntülenebilir forma çevirir
  String _getSettingDisplayValue(String settingName, String value) {
    switch (settingName) {
      case 'pinEnabled':
      case 'biometricEnabled':
      case 'twoFactorEnabled':
        return value == 'true' ? 'Etkin' : 'Devre Dışı';
      case 'sessionTimeout':
      case 'lockoutDuration':
        final minutes = int.tryParse(value);
        if (minutes != null) {
          if (minutes >= 60) {
            return '${minutes ~/ 60} saat ${minutes % 60} dakika';
          } else {
            return '$minutes dakika';
          }
        }
        return value;
      default:
        return value;
    }
  }
}

/// Güvenlik bildirim ayarları
class SecurityNotificationSettings {
  /// Başarısız giriş bildirimleri etkin mi
  final bool enableFailedLoginNotifications;
  
  /// Yeni cihaz bildirimleri etkin mi
  final bool enableNewDeviceNotifications;
  
  /// Ayar değişiklik bildirimleri etkin mi
  final bool enableSettingsChangeNotifications;
  
  /// Şüpheli aktivite bildirimleri etkin mi
  final bool enableSuspiciousActivityNotifications;
  
  /// Email bildirimleri etkin mi
  final bool enableEmailNotifications;
  
  /// SMS bildirimleri etkin mi
  final bool enableSmsNotifications;
  
  /// Push bildirimleri etkin mi
  final bool enablePushNotifications;

  const SecurityNotificationSettings({
    this.enableFailedLoginNotifications = true,
    this.enableNewDeviceNotifications = true,
    this.enableSettingsChangeNotifications = true,
    this.enableSuspiciousActivityNotifications = true,
    this.enableEmailNotifications = false, // Harici servis gerektirir
    this.enableSmsNotifications = false,   // Harici servis gerektirir
    this.enablePushNotifications = true,
  });

  /// Varsayılan ayarlar
  factory SecurityNotificationSettings.defaultSettings() {
    return const SecurityNotificationSettings();
  }

  /// JSON'dan oluşturur
  factory SecurityNotificationSettings.fromJson(Map<String, dynamic> json) {
    return SecurityNotificationSettings(
      enableFailedLoginNotifications: json['enableFailedLoginNotifications'] ?? true,
      enableNewDeviceNotifications: json['enableNewDeviceNotifications'] ?? true,
      enableSettingsChangeNotifications: json['enableSettingsChangeNotifications'] ?? true,
      enableSuspiciousActivityNotifications: json['enableSuspiciousActivityNotifications'] ?? true,
      enableEmailNotifications: json['enableEmailNotifications'] ?? false,
      enableSmsNotifications: json['enableSmsNotifications'] ?? false,
      enablePushNotifications: json['enablePushNotifications'] ?? true,
    );
  }

  /// JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'enableFailedLoginNotifications': enableFailedLoginNotifications,
      'enableNewDeviceNotifications': enableNewDeviceNotifications,
      'enableSettingsChangeNotifications': enableSettingsChangeNotifications,
      'enableSuspiciousActivityNotifications': enableSuspiciousActivityNotifications,
      'enableEmailNotifications': enableEmailNotifications,
      'enableSmsNotifications': enableSmsNotifications,
      'enablePushNotifications': enablePushNotifications,
    };
  }

  /// Kopya oluşturur
  SecurityNotificationSettings copyWith({
    bool? enableFailedLoginNotifications,
    bool? enableNewDeviceNotifications,
    bool? enableSettingsChangeNotifications,
    bool? enableSuspiciousActivityNotifications,
    bool? enableEmailNotifications,
    bool? enableSmsNotifications,
    bool? enablePushNotifications,
  }) {
    return SecurityNotificationSettings(
      enableFailedLoginNotifications: enableFailedLoginNotifications ?? this.enableFailedLoginNotifications,
      enableNewDeviceNotifications: enableNewDeviceNotifications ?? this.enableNewDeviceNotifications,
      enableSettingsChangeNotifications: enableSettingsChangeNotifications ?? this.enableSettingsChangeNotifications,
      enableSuspiciousActivityNotifications: enableSuspiciousActivityNotifications ?? this.enableSuspiciousActivityNotifications,
      enableEmailNotifications: enableEmailNotifications ?? this.enableEmailNotifications,
      enableSmsNotifications: enableSmsNotifications ?? this.enableSmsNotifications,
      enablePushNotifications: enablePushNotifications ?? this.enablePushNotifications,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SecurityNotificationSettings &&
        other.enableFailedLoginNotifications == enableFailedLoginNotifications &&
        other.enableNewDeviceNotifications == enableNewDeviceNotifications &&
        other.enableSettingsChangeNotifications == enableSettingsChangeNotifications &&
        other.enableSuspiciousActivityNotifications == enableSuspiciousActivityNotifications &&
        other.enableEmailNotifications == enableEmailNotifications &&
        other.enableSmsNotifications == enableSmsNotifications &&
        other.enablePushNotifications == enablePushNotifications;
  }

  @override
  int get hashCode {
    return Object.hash(
      enableFailedLoginNotifications,
      enableNewDeviceNotifications,
      enableSettingsChangeNotifications,
      enableSuspiciousActivityNotifications,
      enableEmailNotifications,
      enableSmsNotifications,
      enablePushNotifications,
    );
  }

  @override
  String toString() {
    return 'SecurityNotificationSettings('
           'failedLogin: $enableFailedLoginNotifications, '
           'newDevice: $enableNewDeviceNotifications, '
           'settingsChange: $enableSettingsChangeNotifications, '
           'suspicious: $enableSuspiciousActivityNotifications)';
  }
}