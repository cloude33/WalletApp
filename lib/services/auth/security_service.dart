import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/security/security_models.dart';
import '../../utils/security/clipboard_security.dart';
import 'secure_storage_service.dart';

/// Güvenlik servisi - Ekran görüntüsü engelleme, arka plan bulanıklaştırma ve root/jailbreak tespiti
/// 
/// Bu servis, uygulamanın güvenlik katmanlarını yönetir ve güvenlik ihlallerine karşı koruma sağlar.
/// 
/// Özellikler:
/// - Ekran görüntüsü engelleme (Android/iOS)
/// - Uygulama arka plan bulanıklaştırma
/// - Root/jailbreak tespiti
/// - Şüpheli aktivite tespiti
/// - Güvenlik olayları kayıt sistemi
/// - Cihaz güvenlik durumu kontrolü
/// 
/// Gereksinimler:
/// - 9.1: Ekran görüntüsü engelleme
/// - 9.2: Arka plan bulanıklaştırma
/// - 9.4: Root/jailbreak tespiti
/// - 9.5: Şüpheli aktivite tespiti ve log kaydetme
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  // Platform channels
  static const MethodChannel _channel = MethodChannel('com.bulut.wallet/security');
  
  // Storage keys
  static const String _securityStatusKey = 'security_status';
  static const String _securityEventsKey = 'security_events';
  static const String _screenshotBlockingKey = 'screenshot_blocking_enabled';
  static const String _backgroundBlurKey = 'background_blur_enabled';
  static const String _rootDetectionKey = 'root_detection_enabled';
  static const String _lastSecurityCheckKey = 'last_security_check';
  
  // Services
  final AuthSecureStorageService _secureStorage = AuthSecureStorageService();
  final ClipboardSecurity _clipboardSecurity = ClipboardSecurity();
  
  // State
  bool _isInitialized = false;
  SecurityStatus? _currentStatus;
  final List<SecurityEvent> _eventBuffer = [];
  Timer? _securityCheckTimer;
  final StreamController<SecurityEvent> _eventStreamController = StreamController<SecurityEvent>.broadcast();
  final StreamController<SecurityStatus> _statusStreamController = StreamController<SecurityStatus>.broadcast();

  /// Güvenlik olayları stream'i
  Stream<SecurityEvent> get securityEventStream => _eventStreamController.stream;
  
  /// Güvenlik durumu stream'i
  Stream<SecurityStatus> get securityStatusStream => _statusStreamController.stream;
  
  /// Mevcut güvenlik durumu
  SecurityStatus? get currentStatus => _currentStatus;

  /// Servisi başlatır
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _secureStorage.initialize();
      await _clipboardSecurity.initialize();
      await _loadSecurityStatus();
      await _startPeriodicSecurityCheck();
      
      _isInitialized = true;
      
      // Başlatma olayını kaydet
      await logSecurityEvent(SecurityEvent(
        type: SecurityEventType.unknown,
        description: 'Güvenlik servisi başlatıldı',
        severity: SecurityEventSeverity.info,
        source: 'SecurityService',
      ));
      
    } catch (e) {
      debugPrint('SecurityService initialization failed: $e');
      rethrow;
    }
  }

  /// Servisi temizler
  Future<void> dispose() async {
    _securityCheckTimer?.cancel();
    await _clipboardSecurity.dispose();
    await _eventStreamController.close();
    await _statusStreamController.close();
    _isInitialized = false;
  }

  /// Ekran görüntüsü engellemeyi etkinleştirir
  /// Gereksinim 9.1: WHEN ekran görüntüsü alınmaya çalışıldığında, THE Security_Layer SHALL hassas içeriği gizlemeli
  Future<void> enableScreenshotBlocking() async {
    await _ensureInitialized();
    
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('enableScreenshotBlocking');
      } else if (Platform.isIOS) {
        await _channel.invokeMethod('enableScreenshotBlocking');
      }
      
      // Durumu kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_screenshotBlockingKey, true);
      
      // Güvenlik durumunu güncelle
      await _updateSecurityStatus();
      
      // Olayı kaydet
      await logSecurityEvent(SecurityEvent(
        type: SecurityEventType.screenshotBlocked,
        description: 'Ekran görüntüsü engelleme etkinleştirildi',
        severity: SecurityEventSeverity.info,
        source: 'SecurityService',
      ));
      
    } catch (e) {
      debugPrint('Failed to enable screenshot blocking: $e');
      
      await logSecurityEvent(SecurityEvent(
        type: SecurityEventType.unknown,
        description: 'Ekran görüntüsü engelleme etkinleştirilemedi: $e',
        severity: SecurityEventSeverity.critical,
        source: 'SecurityService',
        metadata: {'error': e.toString()},
      ));
      
      rethrow;
    }
  }

  /// Ekran görüntüsü engellemeyi devre dışı bırakır
  Future<void> disableScreenshotBlocking() async {
    await _ensureInitialized();
    
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('disableScreenshotBlocking');
      } else if (Platform.isIOS) {
        await _channel.invokeMethod('disableScreenshotBlocking');
      }
      
      // Durumu kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_screenshotBlockingKey, false);
      
      // Güvenlik durumunu güncelle
      await _updateSecurityStatus();
      
      // Olayı kaydet
      await logSecurityEvent(SecurityEvent(
        type: SecurityEventType.unknown,
        description: 'Ekran görüntüsü engelleme devre dışı bırakıldı',
        severity: SecurityEventSeverity.warning,
        source: 'SecurityService',
      ));
      
    } catch (e) {
      debugPrint('Failed to disable screenshot blocking: $e');
      rethrow;
    }
  }

  /// Uygulama arka plan bulanıklaştırmasını etkinleştirir
  /// Gereksinim 9.2: WHEN uygulama task switcher'da gösterildiğinde, THE Security_Layer SHALL içeriği bulanıklaştırmalı
  Future<void> enableAppBackgroundBlur() async {
    await _ensureInitialized();
    
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('enableBackgroundBlur');
      } else if (Platform.isIOS) {
        await _channel.invokeMethod('enableBackgroundBlur');
      }
      
      // Durumu kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_backgroundBlurKey, true);
      
      // Güvenlik durumunu güncelle
      await _updateSecurityStatus();
      
      // Olayı kaydet
      await logSecurityEvent(SecurityEvent(
        type: SecurityEventType.unknown,
        description: 'Arka plan bulanıklaştırma etkinleştirildi',
        severity: SecurityEventSeverity.info,
        source: 'SecurityService',
      ));
      
    } catch (e) {
      debugPrint('Failed to enable background blur: $e');
      
      await logSecurityEvent(SecurityEvent(
        type: SecurityEventType.unknown,
        description: 'Arka plan bulanıklaştırma etkinleştirilemedi: $e',
        severity: SecurityEventSeverity.critical,
        source: 'SecurityService',
        metadata: {'error': e.toString()},
      ));
      
      rethrow;
    }
  }

  /// Uygulama arka plan bulanıklaştırmasını devre dışı bırakır
  Future<void> disableAppBackgroundBlur() async {
    await _ensureInitialized();
    
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('disableBackgroundBlur');
      } else if (Platform.isIOS) {
        await _channel.invokeMethod('disableBackgroundBlur');
      }
      
      // Durumu kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_backgroundBlurKey, false);
      
      // Güvenlik durumunu güncelle
      await _updateSecurityStatus();
      
      // Olayı kaydet
      await logSecurityEvent(SecurityEvent(
        type: SecurityEventType.unknown,
        description: 'Arka plan bulanıklaştırma devre dışı bırakıldı',
        severity: SecurityEventSeverity.warning,
        source: 'SecurityService',
      ));
      
    } catch (e) {
      debugPrint('Failed to disable background blur: $e');
      rethrow;
    }
  }

  /// Cihazın güvenli olup olmadığını kontrol eder
  Future<bool> isDeviceSecure() async {
    await _ensureInitialized();
    
    try {
      // Platform-specific güvenlik kontrolü
      bool isSecure = false;
      
      if (Platform.isAndroid) {
        isSecure = await _channel.invokeMethod('isDeviceSecure') ?? false;
      } else if (Platform.isIOS) {
        isSecure = await _channel.invokeMethod('isDeviceSecure') ?? false;
      }
      
      return isSecure;
    } catch (e) {
      debugPrint('Failed to check device security: $e');
      return false;
    }
  }

  /// Root/jailbreak tespiti yapar
  /// Gereksinim 9.4: WHEN root/jailbreak tespit edildiğinde, THE Security_Layer SHALL uygulamayı güvenli moda almalı
  Future<bool> detectRootJailbreak() async {
    await _ensureInitialized();
    
    try {
      bool isRooted = false;
      
      if (Platform.isAndroid) {
        // Android root tespiti
        isRooted = await _detectAndroidRoot();
      } else if (Platform.isIOS) {
        // iOS jailbreak tespiti
        isRooted = await _detectIOSJailbreak();
      }
      
      if (isRooted) {
        // Root/jailbreak tespit edildi - güvenli moda geç
        await _enterSecureMode();
        
        // Olayı kaydet
        await logSecurityEvent(SecurityEvent.rootDetected(
          details: Platform.isAndroid ? 'Android root tespit edildi' : 'iOS jailbreak tespit edildi',
          metadata: {
            'platform': Platform.operatingSystem,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ));
      }
      
      return isRooted;
    } catch (e) {
      debugPrint('Failed to detect root/jailbreak: $e');
      return false;
    }
  }

  /// Android root tespiti
  Future<bool> _detectAndroidRoot() async {
    try {
      final result = await _channel.invokeMethod('detectRoot');
      return result ?? false;
    } catch (e) {
      debugPrint('Android root detection failed: $e');
      return false;
    }
  }

  /// iOS jailbreak tespiti
  Future<bool> _detectIOSJailbreak() async {
    try {
      final result = await _channel.invokeMethod('detectJailbreak');
      return result ?? false;
    } catch (e) {
      debugPrint('iOS jailbreak detection failed: $e');
      return false;
    }
  }

  /// Güvenli moda geçer
  Future<void> _enterSecureMode() async {
    try {
      // Ekran görüntüsü engellemeyi etkinleştir
      await enableScreenshotBlocking();
      
      // Arka plan bulanıklaştırmayı etkinleştir
      await enableAppBackgroundBlur();
      
      // Güvenlik durumunu güncelle
      await _updateSecurityStatus();
      
      // Olayı kaydet
      await logSecurityEvent(SecurityEvent(
        type: SecurityEventType.unknown,
        description: 'Güvenli mod etkinleştirildi',
        severity: SecurityEventSeverity.critical,
        source: 'SecurityService',
      ));
      
    } catch (e) {
      debugPrint('Failed to enter secure mode: $e');
    }
  }

  /// Güvenlik durumunu alır
  Future<SecurityStatus> getSecurityStatus() async {
    await _ensureInitialized();
    
    if (_currentStatus != null) {
      return _currentStatus!;
    }
    
    return await _updateSecurityStatus();
  }

  /// Güvenlik durumunu günceller
  Future<SecurityStatus> _updateSecurityStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Mevcut ayarları kontrol et
      final isScreenshotBlocked = prefs.getBool(_screenshotBlockingKey) ?? false;
      final isBackgroundBlurEnabled = prefs.getBool(_backgroundBlurKey) ?? false;
      final isRootDetectionEnabled = prefs.getBool(_rootDetectionKey) ?? true;
      
      // Cihaz güvenliğini kontrol et
      final isDeviceSecureResult = await isDeviceSecure();
      final isRootDetected = isRootDetectionEnabled ? await detectRootJailbreak() : false;
      
      // Clipboard güvenlik durumunu kontrol et
      final clipboardStatus = await getClipboardSecurityStatus();
      final isClipboardSecurityEnabled = clipboardStatus.isSecurityEnabled;
      
      // Uyarıları topla
      final warnings = <SecurityWarning>[];
      
      if (isRootDetected) {
        warnings.add(SecurityWarning(
          type: SecurityWarningType.rootDetected,
          severity: SecurityWarningSeverity.critical,
          message: 'Cihazda root/jailbreak tespit edildi',
          description: 'Bu durum uygulamanın güvenliğini tehlikeye atabilir',
        ));
      }
      
      if (!isDeviceSecureResult) {
        warnings.add(SecurityWarning(
          type: SecurityWarningType.weakSecurity,
          severity: SecurityWarningSeverity.high,
          message: 'Cihaz güvenlik ayarları yetersiz',
          description: 'Cihazınızda ekran kilidi veya güvenlik ayarları eksik',
        ));
      }
      
      if (!isScreenshotBlocked) {
        warnings.add(SecurityWarning(
          type: SecurityWarningType.weakSecurity,
          severity: SecurityWarningSeverity.medium,
          message: 'Ekran görüntüsü engelleme devre dışı',
          description: 'Hassas bilgiler ekran görüntüsü ile ele geçirilebilir',
        ));
      }
      
      if (!isClipboardSecurityEnabled) {
        warnings.add(SecurityWarning(
          type: SecurityWarningType.weakSecurity,
          severity: SecurityWarningSeverity.medium,
          message: 'Clipboard güvenliği devre dışı',
          description: 'Hassas bilgiler kopyalanarak ele geçirilebilir',
        ));
      }
      
      if (clipboardStatus.hasSensitiveData) {
        warnings.add(SecurityWarning(
          type: SecurityWarningType.suspiciousActivity,
          severity: SecurityWarningSeverity.high,
          message: 'Clipboard\'da hassas veri tespit edildi',
          description: 'Clipboard\'daki hassas veriler güvenlik riski oluşturabilir',
        ));
      }
      
      // Güvenlik seviyesini belirle
      SecurityLevel level = SecurityLevel.high;
      if (isRootDetected) {
        level = SecurityLevel.critical;
      } else if (!isDeviceSecureResult || warnings.isNotEmpty) {
        level = SecurityLevel.medium;
      }
      
      // Güvenlik durumunu oluştur
      _currentStatus = SecurityStatus(
        isDeviceSecure: isDeviceSecureResult,
        isRootDetected: isRootDetected,
        isScreenshotBlocked: isScreenshotBlocked,
        isBackgroundBlurEnabled: isBackgroundBlurEnabled,
        isClipboardSecurityEnabled: isClipboardSecurityEnabled,
        securityLevel: level,
        warnings: warnings,
      );
      
      // Durumu kaydet
      await _saveSecurityStatus(_currentStatus!);
      
      // Stream'e bildir
      _statusStreamController.add(_currentStatus!);
      
      return _currentStatus!;
    } catch (e) {
      debugPrint('Failed to update security status: $e');
      
      // Hata durumunda varsayılan güvenlik durumu döndür
      _currentStatus = SecurityStatus(
        isDeviceSecure: false,
        isRootDetected: false,
        isScreenshotBlocked: false,
        isBackgroundBlurEnabled: false,
        isClipboardSecurityEnabled: false,
        securityLevel: SecurityLevel.low,
        warnings: [
          SecurityWarning(
            type: SecurityWarningType.unknown,
            severity: SecurityWarningSeverity.critical,
            message: 'Güvenlik durumu kontrol edilemedi',
            description: e.toString(),
          ),
        ],
      );
      
      return _currentStatus!;
    }
  }

  /// Güvenlik olayını kaydeder
  /// Gereksinim 9.5: WHEN şüpheli aktivite tespit edildiğinde, THE Security_Layer SHALL oturumu sonlandırıp log kaydetmeli
  Future<void> logSecurityEvent(SecurityEvent event) async {
    try {
      // Event buffer'a ekle
      _eventBuffer.add(event);
      
      // Stream'e bildir
      _eventStreamController.add(event);
      
      // Kritik olayları hemen kaydet
      if (event.severity == SecurityEventSeverity.critical) {
        await _flushEventBuffer();
      }
      
      // Buffer boyutu kontrolü
      if (_eventBuffer.length >= 50) {
        await _flushEventBuffer();
      }
      
      debugPrint('Security event logged: ${event.type} - ${event.description}');
    } catch (e) {
      debugPrint('Failed to log security event: $e');
    }
  }

  /// Event buffer'ını temizler ve olayları kaydeder
  Future<void> _flushEventBuffer() async {
    if (_eventBuffer.isEmpty) return;
    
    try {
      // Mevcut olayları al
      final existingEvents = await _loadSecurityEvents();
      
      // Yeni olayları ekle
      existingEvents.addAll(_eventBuffer);
      
      // Son 1000 olayı tut
      if (existingEvents.length > 1000) {
        existingEvents.removeRange(0, existingEvents.length - 1000);
      }
      
      // Kaydet
      await _saveSecurityEvents(existingEvents);
      
      // Buffer'ı temizle
      _eventBuffer.clear();
    } catch (e) {
      debugPrint('Failed to flush event buffer: $e');
    }
  }

  /// Güvenlik olaylarını yükler
  Future<List<SecurityEvent>> _loadSecurityEvents() async {
    try {
      final eventsJson = await _secureStorage.read(_securityEventsKey);
      if (eventsJson == null) return [];
      
      final eventsList = eventsJson as List<dynamic>;
      return eventsList
          .map((e) => SecurityEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to load security events: $e');
      return [];
    }
  }

  /// Güvenlik olaylarını kaydeder
  Future<void> _saveSecurityEvents(List<SecurityEvent> events) async {
    try {
      final eventsJson = events.map((e) => e.toJson()).toList();
      await _secureStorage.write(_securityEventsKey, eventsJson);
    } catch (e) {
      debugPrint('Failed to save security events: $e');
    }
  }

  /// Güvenlik durumunu yükler
  Future<void> _loadSecurityStatus() async {
    try {
      final statusJson = await _secureStorage.read(_securityStatusKey);
      if (statusJson != null) {
        _currentStatus = SecurityStatus.fromJson(statusJson as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Failed to load security status: $e');
    }
  }

  /// Güvenlik durumunu kaydeder
  Future<void> _saveSecurityStatus(SecurityStatus status) async {
    try {
      await _secureStorage.write(_securityStatusKey, status.toJson());
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSecurityCheckKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Failed to save security status: $e');
    }
  }

  /// Periyodik güvenlik kontrolünü başlatır
  Future<void> _startPeriodicSecurityCheck() async {
    // Her 5 dakikada bir güvenlik kontrolü yap
    _securityCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        await _updateSecurityStatus();
      } catch (e) {
        debugPrint('Periodic security check failed: $e');
      }
    });
  }

  /// Servisin başlatıldığından emin olur
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Son güvenlik olaylarını alır
  Future<List<SecurityEvent>> getRecentSecurityEvents({int limit = 50}) async {
    await _ensureInitialized();
    
    try {
      final events = await _loadSecurityEvents();
      
      // Son olayları al
      final recentEvents = events.reversed.take(limit).toList();
      return recentEvents;
    } catch (e) {
      debugPrint('Failed to get recent security events: $e');
      return [];
    }
  }

  /// Güvenlik olaylarını temizler
  Future<void> clearSecurityEvents() async {
    await _ensureInitialized();
    
    try {
      await _saveSecurityEvents([]);
      _eventBuffer.clear();
      
      await logSecurityEvent(SecurityEvent(
        type: SecurityEventType.unknown,
        description: 'Güvenlik olayları temizlendi',
        severity: SecurityEventSeverity.info,
        source: 'SecurityService',
      ));
    } catch (e) {
      debugPrint('Failed to clear security events: $e');
    }
  }

  /// Şüpheli aktivite tespit eder ve gerekli aksiyonları alır
  Future<void> detectSuspiciousActivity({
    required String activity,
    required String details,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    await _ensureInitialized();
    
    try {
      // Şüpheli aktivite olayını kaydet
      await logSecurityEvent(SecurityEvent.suspiciousActivity(
        userId: userId,
        activity: activity,
        details: details,
        metadata: metadata,
      ));
      
      // Güvenlik durumunu güncelle
      await _updateSecurityStatus();
      
      // Kritik durumlarda güvenli moda geç
      if (activity.contains('root') || activity.contains('jailbreak') || activity.contains('tamper')) {
        await _enterSecureMode();
      }
      
    } catch (e) {
      debugPrint('Failed to handle suspicious activity: $e');
    }
  }

  /// Clipboard güvenliğini etkinleştirir
  /// Gereksinim 9.3: WHEN kopyalama işlemi yapıldığında, THE Security_Layer SHALL hassas verilerin kopyalanmasını engellemeli
  Future<void> enableClipboardSecurity() async {
    await _ensureInitialized();
    
    try {
      await _clipboardSecurity.enableClipboardSecurity();
      
      // Güvenlik durumunu güncelle
      await _updateSecurityStatus();
      
      // Olayı kaydet
      await logSecurityEvent(SecurityEvent(
        type: SecurityEventType.unknown,
        description: 'Clipboard güvenliği etkinleştirildi',
        severity: SecurityEventSeverity.info,
        source: 'SecurityService',
      ));
      
    } catch (e) {
      debugPrint('Failed to enable clipboard security: $e');
      
      await logSecurityEvent(SecurityEvent(
        type: SecurityEventType.unknown,
        description: 'Clipboard güvenliği etkinleştirilemedi: $e',
        severity: SecurityEventSeverity.critical,
        source: 'SecurityService',
        metadata: {'error': e.toString()},
      ));
      
      rethrow;
    }
  }

  /// Clipboard güvenliğini devre dışı bırakır
  Future<void> disableClipboardSecurity() async {
    await _ensureInitialized();
    
    try {
      await _clipboardSecurity.disableClipboardSecurity();
      
      // Güvenlik durumunu güncelle
      await _updateSecurityStatus();
      
      // Olayı kaydet
      await logSecurityEvent(SecurityEvent(
        type: SecurityEventType.unknown,
        description: 'Clipboard güvenliği devre dışı bırakıldı',
        severity: SecurityEventSeverity.warning,
        source: 'SecurityService',
      ));
      
    } catch (e) {
      debugPrint('Failed to disable clipboard security: $e');
      rethrow;
    }
  }

  /// Clipboard'u güvenli bir şekilde temizler
  Future<void> clearClipboard() async {
    await _ensureInitialized();
    
    try {
      await _clipboardSecurity.clearClipboard();
      
      // Olayı kaydet
      await logSecurityEvent(SecurityEvent(
        type: SecurityEventType.unknown,
        description: 'Clipboard temizlendi',
        severity: SecurityEventSeverity.info,
        source: 'SecurityService',
      ));
      
    } catch (e) {
      debugPrint('Failed to clear clipboard: $e');
      rethrow;
    }
  }

  /// Metni güvenli bir şekilde kopyalar
  Future<bool> secureCopyText(String text, {String? source}) async {
    await _ensureInitialized();
    
    try {
      final success = await _clipboardSecurity.copyText(text, source: source);
      
      if (!success) {
        // Hassas veri kopyalama engellendi
        await logSecurityEvent(SecurityEvent(
          type: SecurityEventType.suspiciousActivity,
          description: 'Hassas veri kopyalama engellendi',
          severity: SecurityEventSeverity.warning,
          source: source ?? 'SecurityService',
          metadata: {
            'textLength': text.length,
            'source': source,
          },
        ));
      }
      
      return success;
    } catch (e) {
      debugPrint('Failed to secure copy text: $e');
      return false;
    }
  }

  /// Güvenli paylaşım yapar
  Future<bool> secureShare(String text, {String? targetApp}) async {
    await _ensureInitialized();
    
    try {
      final success = await _clipboardSecurity.secureShare(text, targetApp: targetApp);
      
      // Olayı kaydet
      await logSecurityEvent(SecurityEvent(
        type: SecurityEventType.unknown,
        description: success ? 'Güvenli paylaşım başarılı' : 'Güvenli paylaşım engellendi',
        severity: success ? SecurityEventSeverity.info : SecurityEventSeverity.warning,
        source: 'SecurityService',
        metadata: {
          'textLength': text.length,
          'targetApp': targetApp,
          'success': success,
        },
      ));
      
      return success;
    } catch (e) {
      debugPrint('Failed to secure share: $e');
      return false;
    }
  }

  /// Clipboard güvenlik durumunu alır
  Future<ClipboardSecurityStatus> getClipboardSecurityStatus() async {
    await _ensureInitialized();
    
    try {
      return await _clipboardSecurity.getSecurityStatus();
    } catch (e) {
      debugPrint('Failed to get clipboard security status: $e');
      
      // Hata durumunda varsayılan durum döndür
      return ClipboardSecurityStatus(
        isSecurityEnabled: false,
        isAutoCleanupEnabled: false,
        cleanupInterval: const Duration(minutes: 5),
        hasContent: false,
        hasSensitiveData: false,
        blockedAttempts: 0,
      );
    }
  }

  /// Clipboard'da hassas veri var mı kontrol eder
  Future<bool> hasClipboardSensitiveData() async {
    await _ensureInitialized();
    
    try {
      return await _clipboardSecurity.hasClipboardSensitiveData();
    } catch (e) {
      debugPrint('Failed to check clipboard sensitive data: $e');
      return false;
    }
  }
}