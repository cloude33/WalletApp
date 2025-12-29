import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clipboard güvenlik kontrolü yardımcı sınıfı
/// 
/// Bu sınıf, hassas verilerin kopyalanmasını engellemek, clipboard'u temizlemek
/// ve güvenli paylaşım mekanizmaları sağlamak için kullanılır.
/// 
/// Özellikler:
/// - Hassas veri kopyalama engelleme
/// - Otomatik clipboard temizleme
/// - Güvenli paylaşım mekanizmaları
/// - Clipboard izleme ve güvenlik olayları
/// 
/// Gereksinim 9.3: WHEN kopyalama işlemi yapıldığında, THE Security_Layer SHALL hassas verilerin kopyalanmasını engellemeli
class ClipboardSecurity {
  static final ClipboardSecurity _instance = ClipboardSecurity._internal();
  factory ClipboardSecurity() => _instance;
  ClipboardSecurity._internal();

  // Storage keys
  static const String _clipboardSecurityEnabledKey = 'clipboard_security_enabled';
  static const String _autoCleanupEnabledKey = 'clipboard_auto_cleanup_enabled';
  static const String _cleanupIntervalKey = 'clipboard_cleanup_interval';
  static const String _lastClipboardContentKey = 'last_clipboard_content';
  static const String _blockedCopyAttemptsKey = 'blocked_copy_attempts';

  // Default settings
  static const Duration _defaultCleanupInterval = Duration(minutes: 5);
  static const int _maxClipboardHistory = 10;

  // State
  bool _isInitialized = false;
  bool _isSecurityEnabled = true;
  bool _isAutoCleanupEnabled = true;
  Duration _cleanupInterval = _defaultCleanupInterval;
  Timer? _cleanupTimer;
  String? _lastClipboardContent;
  int _blockedAttempts = 0;

  // Sensitive data patterns
  final List<RegExp> _sensitivePatterns = [
    // PIN kodları (4-6 haneli sayılar)
    RegExp(r'^\d{4,6}$'),
    // Kredi kartı numaraları
    RegExp(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b'),
    // IBAN numaraları
    RegExp(r'\b[A-Z]{2}\d{2}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{2}\b'),
    // Telefon numaraları
    RegExp(r'\b(\+90|0)[\s-]?\d{3}[\s-]?\d{3}[\s-]?\d{2}[\s-]?\d{2}\b'),
    // Email adresleri (hassas olabilir)
    RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
    // Şifreler (basit pattern)
    RegExp(r'\b(password|şifre|parola|pin)\s*[:=]\s*\S+', caseSensitive: false),
    // Hesap numaraları
    RegExp(r'\b\d{8,20}\b'),
    // CVV kodları
    RegExp(r'\b\d{3,4}\b'),
  ];

  // Güvenli paylaşım için izin verilen uygulamalar
  final Set<String> _allowedApps = {
    'com.android.mms',
    'com.google.android.apps.messaging',
    'com.whatsapp',
    'com.telegram.messenger',
    'com.microsoft.office.outlook',
    'com.google.android.gm',
  };

  /// Servisi başlatır
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadSettings();
      await _startAutoCleanup();
      
      _isInitialized = true;
      debugPrint('ClipboardSecurity initialized');
    } catch (e) {
      debugPrint('ClipboardSecurity initialization failed: $e');
      rethrow;
    }
  }

  /// Servisi temizler
  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    _isInitialized = false;
  }

  /// Clipboard güvenliğini etkinleştirir
  Future<void> enableClipboardSecurity() async {
    await _ensureInitialized();
    
    _isSecurityEnabled = true;
    await _saveSetting(_clipboardSecurityEnabledKey, true);
    
    debugPrint('Clipboard security enabled');
  }

  /// Clipboard güvenliğini devre dışı bırakır
  Future<void> disableClipboardSecurity() async {
    await _ensureInitialized();
    
    _isSecurityEnabled = false;
    await _saveSetting(_clipboardSecurityEnabledKey, false);
    
    debugPrint('Clipboard security disabled');
  }

  /// Otomatik temizlemeyi etkinleştirir
  Future<void> enableAutoCleanup({Duration? interval}) async {
    await _ensureInitialized();
    
    _isAutoCleanupEnabled = true;
    if (interval != null) {
      _cleanupInterval = interval;
      await _saveSetting(_cleanupIntervalKey, interval.inMinutes);
    }
    
    await _saveSetting(_autoCleanupEnabledKey, true);
    await _startAutoCleanup();
    
    debugPrint('Auto cleanup enabled with interval: $_cleanupInterval');
  }

  /// Otomatik temizlemeyi devre dışı bırakır
  Future<void> disableAutoCleanup() async {
    await _ensureInitialized();
    
    _isAutoCleanupEnabled = false;
    await _saveSetting(_autoCleanupEnabledKey, false);
    
    _cleanupTimer?.cancel();
    
    debugPrint('Auto cleanup disabled');
  }

  /// Metni kopyalamaya çalışır - güvenlik kontrolü yapar
  /// Gereksinim 9.3: Hassas verilerin kopyalanmasını engeller
  Future<bool> copyText(String text, {String? source}) async {
    await _ensureInitialized();
    
    if (!_isSecurityEnabled) {
      // Güvenlik devre dışıysa normal kopyalama yap
      await _performCopy(text);
      return true;
    }

    // Hassas veri kontrolü
    if (_isSensitiveData(text)) {
      _blockedAttempts++;
      await _saveSetting(_blockedCopyAttemptsKey, _blockedAttempts);
      
      debugPrint('Sensitive data copy blocked: ${text.length} characters from $source');
      
      // Güvenlik olayını kaydet (eğer security service mevcutsa)
      await _logSecurityEvent(
        'Hassas veri kopyalama engellendi',
        {
          'source': source ?? 'unknown',
          'textLength': text.length,
          'blockedAttempts': _blockedAttempts,
        },
      );
      
      return false;
    }

    // Güvenli veri - kopyalamaya izin ver
    await _performCopy(text);
    _lastClipboardContent = text;
    await _saveSetting(_lastClipboardContentKey, text);
    
    debugPrint('Text copied safely: ${text.length} characters');
    return true;
  }

  /// Clipboard'u temizler
  Future<void> clearClipboard() async {
    await _ensureInitialized();
    
    try {
      await Clipboard.setData(const ClipboardData(text: ''));
      _lastClipboardContent = null;
      await _saveSetting(_lastClipboardContentKey, '');
      
      debugPrint('Clipboard cleared');
    } catch (e) {
      debugPrint('Failed to clear clipboard: $e');
    }
  }

  /// Güvenli paylaşım yapar
  Future<bool> secureShare(String text, {String? targetApp}) async {
    await _ensureInitialized();
    
    // Hassas veri kontrolü
    if (_isSensitiveData(text)) {
      debugPrint('Secure share blocked: sensitive data detected');
      return false;
    }

    // Hedef uygulama kontrolü
    if (targetApp != null && !_allowedApps.contains(targetApp)) {
      debugPrint('Secure share blocked: app not allowed - $targetApp');
      return false;
    }

    try {
      // Platform-specific güvenli paylaşım
      if (Platform.isAndroid) {
        return await _secureShareAndroid(text, targetApp);
      } else if (Platform.isIOS) {
        return await _secureShareIOS(text, targetApp);
      } else {
        // Test ortamı veya desteklenmeyen platform için basit implementasyon
        debugPrint('Secure share on unsupported platform: $text');
        return true;
      }
    } catch (e) {
      debugPrint('Secure share failed: $e');
      return false;
    }
  }

  /// Clipboard içeriğini kontrol eder
  Future<String?> getClipboardContent() async {
    await _ensureInitialized();
    
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      return clipboardData?.text;
    } catch (e) {
      debugPrint('Failed to get clipboard content: $e');
      return null;
    }
  }

  /// Clipboard'da hassas veri var mı kontrol eder
  Future<bool> hasClipboardSensitiveData() async {
    await _ensureInitialized();
    
    final content = await getClipboardContent();
    if (content == null || content.isEmpty) return false;
    
    return _isSensitiveData(content);
  }

  /// Clipboard güvenlik durumunu alır
  Future<ClipboardSecurityStatus> getSecurityStatus() async {
    await _ensureInitialized();
    
    final hasContent = await getClipboardContent() != null;
    final hasSensitiveData = await hasClipboardSensitiveData();
    
    return ClipboardSecurityStatus(
      isSecurityEnabled: _isSecurityEnabled,
      isAutoCleanupEnabled: _isAutoCleanupEnabled,
      cleanupInterval: _cleanupInterval,
      hasContent: hasContent,
      hasSensitiveData: hasSensitiveData,
      blockedAttempts: _blockedAttempts,
      lastCleanup: _getLastCleanupTime(),
    );
  }

  /// Hassas veri pattern'lerini günceller
  void updateSensitivePatterns(List<RegExp> patterns) {
    _sensitivePatterns.clear();
    _sensitivePatterns.addAll(patterns);
    debugPrint('Updated sensitive patterns: ${patterns.length} patterns');
  }

  /// İzin verilen uygulamaları günceller
  void updateAllowedApps(Set<String> apps) {
    _allowedApps.clear();
    _allowedApps.addAll(apps);
    debugPrint('Updated allowed apps: ${apps.length} apps');
  }

  /// Engellenen kopyalama denemesi sayısını sıfırlar
  Future<void> resetBlockedAttempts() async {
    _blockedAttempts = 0;
    await _saveSetting(_blockedCopyAttemptsKey, 0);
    debugPrint('Blocked attempts reset');
  }

  // Private methods

  /// Servisin başlatıldığından emin olur
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Ayarları yükler
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isSecurityEnabled = prefs.getBool(_clipboardSecurityEnabledKey) ?? true;
      _isAutoCleanupEnabled = prefs.getBool(_autoCleanupEnabledKey) ?? true;
      
      final intervalMinutes = prefs.getInt(_cleanupIntervalKey) ?? _defaultCleanupInterval.inMinutes;
      _cleanupInterval = Duration(minutes: intervalMinutes);
      
      _lastClipboardContent = prefs.getString(_lastClipboardContentKey);
      _blockedAttempts = prefs.getInt(_blockedCopyAttemptsKey) ?? 0;
      
    } catch (e) {
      debugPrint('Failed to load clipboard security settings: $e');
    }
  }

  /// Ayar kaydeder
  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    } catch (e) {
      debugPrint('Failed to save clipboard security setting $key: $e');
    }
  }

  /// Otomatik temizlemeyi başlatır
  Future<void> _startAutoCleanup() async {
    if (!_isAutoCleanupEnabled) return;
    
    _cleanupTimer?.cancel();
    
    _cleanupTimer = Timer.periodic(_cleanupInterval, (timer) async {
      await _performAutoCleanup();
    });
    
    debugPrint('Auto cleanup started with interval: $_cleanupInterval');
  }

  /// Otomatik temizleme işlemini gerçekleştirir
  Future<void> _performAutoCleanup() async {
    try {
      final content = await getClipboardContent();
      
      if (content != null && content.isNotEmpty) {
        // Hassas veri varsa hemen temizle
        if (_isSensitiveData(content)) {
          await clearClipboard();
          debugPrint('Auto cleanup: sensitive data cleared');
          return;
        }
        
        // Normal veri için de temizle (güvenlik için)
        await clearClipboard();
        debugPrint('Auto cleanup: clipboard cleared');
      }
    } catch (e) {
      debugPrint('Auto cleanup failed: $e');
    }
  }

  /// Metni gerçekten kopyalar
  Future<void> _performCopy(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      debugPrint('Failed to copy text: $e');
      rethrow;
    }
  }

  /// Hassas veri kontrolü yapar
  bool _isSensitiveData(String text) {
    if (text.isEmpty) return false;
    
    // Tüm pattern'leri kontrol et
    for (final pattern in _sensitivePatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }
    
    // Uzun sayısal diziler (hesap numaraları olabilir)
    if (RegExp(r'^\d{10,}$').hasMatch(text.replaceAll(RegExp(r'[\s-]'), ''))) {
      return true;
    }
    
    // Çok kısa metinler (PIN olabilir)
    if (text.length >= 4 && text.length <= 8 && RegExp(r'^\d+$').hasMatch(text)) {
      return true;
    }
    
    return false;
  }

  /// Android için güvenli paylaşım
  Future<bool> _secureShareAndroid(String text, String? targetApp) async {
    try {
      // Android Intent kullanarak güvenli paylaşım
      // Bu kısım platform channel ile implement edilebilir
      debugPrint('Android secure share: $text to $targetApp');
      
      // Şimdilik basit implementasyon - gerçek implementasyon platform channel gerektirir
      return true;
    } catch (e) {
      debugPrint('Android secure share failed: $e');
      return false;
    }
  }

  /// iOS için güvenli paylaşım
  Future<bool> _secureShareIOS(String text, String? targetApp) async {
    try {
      // iOS UIActivityViewController kullanarak güvenli paylaşım
      // Bu kısım platform channel ile implement edilebilir
      debugPrint('iOS secure share: $text to $targetApp');
      
      // Şimdilik basit implementasyon - gerçek implementasyon platform channel gerektirir
      return true;
    } catch (e) {
      debugPrint('iOS secure share failed: $e');
      return false;
    }
  }

  /// Güvenlik olayını kaydeder
  Future<void> _logSecurityEvent(String description, Map<String, dynamic> metadata) async {
    try {
      // SecurityService'e olay gönder (eğer mevcutsa)
      debugPrint('Security event: $description - $metadata');
      
      // Bu kısım SecurityService ile entegre edilebilir
      // await SecurityService().logSecurityEvent(SecurityEvent(...));
    } catch (e) {
      debugPrint('Failed to log security event: $e');
    }
  }

  /// Son temizleme zamanını alır
  DateTime? _getLastCleanupTime() {
    // Bu bilgi SharedPreferences'da saklanabilir
    return null;
  }
}

/// Clipboard güvenlik durumu
class ClipboardSecurityStatus {
  /// Güvenlik etkin mi?
  final bool isSecurityEnabled;
  
  /// Otomatik temizleme etkin mi?
  final bool isAutoCleanupEnabled;
  
  /// Temizleme aralığı
  final Duration cleanupInterval;
  
  /// Clipboard'da içerik var mı?
  final bool hasContent;
  
  /// Hassas veri var mı?
  final bool hasSensitiveData;
  
  /// Engellenen deneme sayısı
  final int blockedAttempts;
  
  /// Son temizleme zamanı
  final DateTime? lastCleanup;

  ClipboardSecurityStatus({
    required this.isSecurityEnabled,
    required this.isAutoCleanupEnabled,
    required this.cleanupInterval,
    required this.hasContent,
    required this.hasSensitiveData,
    required this.blockedAttempts,
    this.lastCleanup,
  });

  /// JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'isSecurityEnabled': isSecurityEnabled,
      'isAutoCleanupEnabled': isAutoCleanupEnabled,
      'cleanupIntervalMinutes': cleanupInterval.inMinutes,
      'hasContent': hasContent,
      'hasSensitiveData': hasSensitiveData,
      'blockedAttempts': blockedAttempts,
      'lastCleanup': lastCleanup?.toIso8601String(),
    };
  }

  /// JSON'dan oluşturur
  factory ClipboardSecurityStatus.fromJson(Map<String, dynamic> json) {
    return ClipboardSecurityStatus(
      isSecurityEnabled: json['isSecurityEnabled'] as bool? ?? true,
      isAutoCleanupEnabled: json['isAutoCleanupEnabled'] as bool? ?? true,
      cleanupInterval: Duration(minutes: json['cleanupIntervalMinutes'] as int? ?? 5),
      hasContent: json['hasContent'] as bool? ?? false,
      hasSensitiveData: json['hasSensitiveData'] as bool? ?? false,
      blockedAttempts: json['blockedAttempts'] as int? ?? 0,
      lastCleanup: json['lastCleanup'] != null
          ? DateTime.parse(json['lastCleanup'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'ClipboardSecurityStatus(isSecurityEnabled: $isSecurityEnabled, '
           'hasContent: $hasContent, hasSensitiveData: $hasSensitiveData, '
           'blockedAttempts: $blockedAttempts)';
  }
}