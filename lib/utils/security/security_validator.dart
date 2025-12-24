/// Güvenlik validasyon yardımcıları
/// 
/// Bu sınıf PIN güçlülük kontrolü, güvenlik konfigürasyon validasyonu
/// ve hata mesajı yönetimi sağlar.
library;

import '../../../models/security/security_config.dart';

/// PIN güçlülük seviyeleri
enum PINStrength {
  /// Çok zayıf (örn: 1111, 1234)
  veryWeak,
  
  /// Zayıf (örn: 1122, 2345)
  weak,
  
  /// Orta (örn: 1357, 2468)
  medium,
  
  /// Güçlü (örn: 3719, 8264)
  strong,
  
  /// Çok güçlü (örn: 7391, 5928)
  veryStrong;

  /// Güçlülük seviyesinin açıklaması
  String get description {
    switch (this) {
      case PINStrength.veryWeak:
        return 'Çok Zayıf';
      case PINStrength.weak:
        return 'Zayıf';
      case PINStrength.medium:
        return 'Orta';
      case PINStrength.strong:
        return 'Güçlü';
      case PINStrength.veryStrong:
        return 'Çok Güçlü';
    }
  }

  /// Güçlülük seviyesinin renk kodu
  String get colorCode {
    switch (this) {
      case PINStrength.veryWeak:
        return '#FF0000'; // Kırmızı
      case PINStrength.weak:
        return '#FF6600'; // Turuncu
      case PINStrength.medium:
        return '#FFCC00'; // Sarı
      case PINStrength.strong:
        return '#66CC00'; // Açık yeşil
      case PINStrength.veryStrong:
        return '#00CC00'; // Yeşil
    }
  }

  /// Güçlülük seviyesinin puanı (0-100)
  int get score {
    switch (this) {
      case PINStrength.veryWeak:
        return 20;
      case PINStrength.weak:
        return 40;
      case PINStrength.medium:
        return 60;
      case PINStrength.strong:
        return 80;
      case PINStrength.veryStrong:
        return 100;
    }
  }
}

/// PIN güçlülük analiz sonucu
class PINStrengthResult {
  /// Güçlülük seviyesi
  final PINStrength strength;
  
  /// Güçlülük puanı (0-100)
  final int score;
  
  /// Uyarı mesajları
  final List<String> warnings;
  
  /// Öneriler
  final List<String> suggestions;
  
  /// PIN kabul edilebilir mi?
  final bool isAcceptable;

  const PINStrengthResult({
    required this.strength,
    required this.score,
    required this.warnings,
    required this.suggestions,
    required this.isAcceptable,
  });

  /// Başarılı sonuç oluşturur
  factory PINStrengthResult.success({
    required PINStrength strength,
    required int score,
  }) {
    return PINStrengthResult(
      strength: strength,
      score: score,
      warnings: [],
      suggestions: [],
      isAcceptable: true,
    );
  }

  /// Başarısız sonuç oluşturur
  factory PINStrengthResult.failure({
    required PINStrength strength,
    required int score,
    required List<String> warnings,
    required List<String> suggestions,
  }) {
    return PINStrengthResult(
      strength: strength,
      score: score,
      warnings: warnings,
      suggestions: suggestions,
      isAcceptable: false,
    );
  }
}

/// Güvenlik validasyon yardımcıları
class SecurityValidator {
  SecurityValidator._();

  /// PIN güçlülüğünü kontrol eder
  /// 
  /// [pin] kontrol edilecek PIN kodu
  /// [config] PIN konfigürasyonu (opsiyonel)
  /// 
  /// Returns PIN güçlülük analiz sonucu
  static PINStrengthResult checkPINStrength(
    String pin, {
    PINConfiguration? config,
  }) {
    final warnings = <String>[];
    final suggestions = <String>[];
    int score = 100;

    // Uzunluk kontrolü
    if (config != null) {
      if (pin.length < config.minLength) {
        warnings.add('PIN en az ${config.minLength} haneli olmalı');
        return PINStrengthResult.failure(
          strength: PINStrength.veryWeak,
          score: 0,
          warnings: warnings,
          suggestions: ['Daha uzun bir PIN seçin'],
        );
      }
      
      if (pin.length > config.maxLength) {
        warnings.add('PIN en fazla ${config.maxLength} haneli olmalı');
        return PINStrengthResult.failure(
          strength: PINStrength.veryWeak,
          score: 0,
          warnings: warnings,
          suggestions: ['Daha kısa bir PIN seçin'],
        );
      }
    }

    // Sadece rakam kontrolü
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      warnings.add('PIN sadece rakamlardan oluşmalı');
      return PINStrengthResult.failure(
        strength: PINStrength.veryWeak,
        score: 0,
        warnings: warnings,
        suggestions: ['Sadece rakam kullanın'],
      );
    }

    // Aynı rakamların tekrarı kontrolü (örn: 1111, 2222)
    if (RegExp(r'^(\d)\1+$').hasMatch(pin)) {
      warnings.add('Tüm rakamlar aynı');
      score -= 40;
      suggestions.add('Farklı rakamlar kullanın');
    }

    // Ardışık rakamlar kontrolü (örn: 1234, 4321)
    if (pin.length >= 3 && _hasSequentialDigits(pin)) {
      warnings.add('Ardışık rakamlar içeriyor');
      score -= 30;
      suggestions.add('Ardışık olmayan rakamlar seçin');
    }

    // Yaygın PIN kontrolü
    if (_isCommonPIN(pin)) {
      warnings.add('Yaygın kullanılan bir PIN');
      score -= 30;
      suggestions.add('Daha özgün bir PIN seçin');
    }

    // Tekrarlayan çiftler kontrolü (örn: 1212, 3434)
    if (_hasRepeatingPairs(pin)) {
      warnings.add('Tekrarlayan çiftler içeriyor');
      score -= 20;
      suggestions.add('Daha karmaşık bir desen kullanın');
    }

    // Tarih benzeri desenler kontrolü (örn: 0101, 1225)
    if (_hasDatePattern(pin)) {
      warnings.add('Tarih benzeri bir desen içeriyor');
      score -= 15;
      suggestions.add('Tarih veya özel günlerle ilgili olmayan bir PIN seçin');
    }

    // Uzunluk bonusu
    if (pin.length > 4) {
      score += (pin.length - 4) * 5;
    }

    // Benzersiz rakam sayısı bonusu
    final uniqueDigits = pin.split('').toSet().length;
    if (uniqueDigits >= pin.length * 0.75) {
      score += 10;
    }

    // Skoru sınırla
    score = score.clamp(0, 100);

    // Güçlülük seviyesini belirle
    final strength = _determineStrength(score);

    // Karmaşık PIN gereksinimi kontrolü
    if (config?.requireComplexPIN == true && score < 60) {
      warnings.add('Karmaşık PIN gerekli (minimum puan: 60)');
      return PINStrengthResult.failure(
        strength: strength,
        score: score,
        warnings: warnings,
        suggestions: suggestions.isEmpty 
            ? ['Daha karmaşık bir PIN seçin']
            : suggestions,
      );
    }

    // Sonuç
    final isAcceptable = score >= 40;
    
    if (isAcceptable && warnings.isEmpty) {
      return PINStrengthResult.success(
        strength: strength,
        score: score,
      );
    } else {
      return PINStrengthResult(
        strength: strength,
        score: score,
        warnings: warnings,
        suggestions: suggestions,
        isAcceptable: isAcceptable,
      );
    }
  }

  /// Ardışık rakamları kontrol eder
  static bool _hasSequentialDigits(String pin) {
    for (int i = 0; i < pin.length - 2; i++) {
      final current = int.parse(pin[i]);
      final next = int.parse(pin[i + 1]);
      final afterNext = int.parse(pin[i + 2]);
      
      // Artan sıra (örn: 123, 234)
      if (next == current + 1 && afterNext == next + 1) {
        return true;
      }
      
      // Azalan sıra (örn: 321, 432)
      if (next == current - 1 && afterNext == next - 1) {
        return true;
      }
    }
    return false;
  }

  /// Yaygın PIN'leri kontrol eder
  static bool _isCommonPIN(String pin) {
    const commonPINs = [
      '1234', '0000', '1111', '2222', '3333', '4444',
      '5555', '6666', '7777', '8888', '9999',
      '1212', '1004', '2000', '4321', '6969',
      '0123', '1122', '2233', '3344', '4455',
      '5566', '6677', '7788', '8899', '9900',
    ];
    return commonPINs.contains(pin);
  }

  /// Tekrarlayan çiftleri kontrol eder
  static bool _hasRepeatingPairs(String pin) {
    if (pin.length < 4) return false;
    
    for (int i = 0; i < pin.length - 3; i += 2) {
      final pair1 = pin.substring(i, i + 2);
      final pair2 = pin.substring(i + 2, i + 4);
      if (pair1 == pair2) {
        return true;
      }
    }
    return false;
  }

  /// Tarih benzeri desenleri kontrol eder
  static bool _hasDatePattern(String pin) {
    if (pin.length != 4) return false;
    
    final month = int.tryParse(pin.substring(0, 2));
    final day = int.tryParse(pin.substring(2, 4));
    
    // Ay kontrolü (01-12) ve gün kontrolü (01-31)
    if (month != null && month >= 1 && month <= 12 &&
        day != null && day >= 1 && day <= 31) {
      return true;
    }
    
    // Ters kontrol: gün-ay formatı
    final day2 = int.tryParse(pin.substring(0, 2));
    final month2 = int.tryParse(pin.substring(2, 4));
    
    if (day2 != null && day2 >= 1 && day2 <= 31 &&
        month2 != null && month2 >= 1 && month2 <= 12) {
      return true;
    }
    
    return false;
  }

  /// Puana göre güçlülük seviyesini belirler
  static PINStrength _determineStrength(int score) {
    if (score >= 80) return PINStrength.veryStrong;
    if (score >= 60) return PINStrength.strong;
    if (score >= 40) return PINStrength.medium;
    if (score >= 20) return PINStrength.weak;
    return PINStrength.veryWeak;
  }

  /// Güvenlik konfigürasyonunu validate eder
  /// 
  /// [config] validate edilecek güvenlik konfigürasyonu
  /// 
  /// Returns hata mesajı (null ise geçerli)
  static String? validateSecurityConfig(SecurityConfig config) {
    // SecurityConfig'in kendi validate metodunu kullan
    final configValidation = config.validate();
    if (configValidation != null) {
      return configValidation;
    }

    // Ek validasyonlar
    if (config.isPINEnabled && config.maxPINAttempts < 3) {
      return 'PIN etkinken en az 3 deneme hakkı olmalı';
    }

    if (config.isBiometricEnabled && config.enabledBiometrics.isEmpty) {
      return 'Biyometrik etkinken en az bir biyometrik tür seçilmeli';
    }

    if (!config.isPINEnabled && !config.isBiometricEnabled) {
      return 'En az bir kimlik doğrulama yöntemi etkin olmalı';
    }

    if (config.isTwoFactorEnabled && 
        !config.twoFactorConfig.enableSMS && 
        !config.twoFactorConfig.enableEmail && 
        !config.twoFactorConfig.enableTOTP) {
      return 'İki faktörlü doğrulama etkinken en az bir yöntem seçilmeli';
    }

    return null;
  }

  /// PIN konfigürasyonunu validate eder
  /// 
  /// [config] validate edilecek PIN konfigürasyonu
  /// 
  /// Returns hata mesajı (null ise geçerli)
  static String? validatePINConfig(PINConfiguration config) {
    return config.validate();
  }

  /// Biyometrik konfigürasyonunu validate eder
  /// 
  /// [config] validate edilecek biyometrik konfigürasyonu
  /// 
  /// Returns hata mesajı (null ise geçerli)
  static String? validateBiometricConfig(BiometricConfiguration config) {
    return config.validate();
  }

  /// Oturum konfigürasyonunu validate eder
  /// 
  /// [config] validate edilecek oturum konfigürasyonu
  /// 
  /// Returns hata mesajı (null ise geçerli)
  static String? validateSessionConfig(SessionConfiguration config) {
    return config.validate();
  }

  /// İki faktörlü doğrulama konfigürasyonunu validate eder
  /// 
  /// [config] validate edilecek iki faktörlü doğrulama konfigürasyonu
  /// 
  /// Returns hata mesajı (null ise geçerli)
  static String? validateTwoFactorConfig(TwoFactorConfiguration config) {
    return config.validate();
  }

  /// Kullanıcı dostu hata mesajı oluşturur
  /// 
  /// [errorCode] hata kodu
  /// [context] ek bağlam bilgisi
  /// 
  /// Returns kullanıcı dostu hata mesajı
  static String getErrorMessage(String errorCode, {Map<String, dynamic>? context}) {
    switch (errorCode) {
      // PIN hataları
      case 'pin_too_short':
        final minLength = context?['minLength'] ?? 4;
        return 'PIN en az $minLength haneli olmalı';
      
      case 'pin_too_long':
        final maxLength = context?['maxLength'] ?? 6;
        return 'PIN en fazla $maxLength haneli olmalı';
      
      case 'pin_invalid_format':
        return 'PIN sadece rakamlardan oluşmalı';
      
      case 'pin_too_weak':
        return 'PIN çok zayıf. Daha güçlü bir PIN seçin';
      
      case 'pin_incorrect':
        final remaining = context?['remainingAttempts'];
        if (remaining != null) {
          return 'Yanlış PIN. Kalan deneme: $remaining';
        }
        return 'Yanlış PIN';
      
      case 'pin_locked':
        final duration = context?['lockoutDuration'] as Duration?;
        if (duration != null) {
          final minutes = duration.inMinutes;
          final seconds = duration.inSeconds % 60;
          if (minutes > 0) {
            return 'Hesap kilitli. $minutes dakika $seconds saniye sonra tekrar deneyin';
          }
          return 'Hesap kilitli. $seconds saniye sonra tekrar deneyin';
        }
        return 'Hesap kilitli';
      
      // Biyometrik hataları
      case 'biometric_not_available':
        return 'Biyometrik doğrulama bu cihazda kullanılamıyor';
      
      case 'biometric_not_enrolled':
        return 'Biyometrik veri kayıtlı değil. Lütfen cihaz ayarlarından kayıt yapın';
      
      case 'biometric_failed':
        return 'Biyometrik doğrulama başarısız';
      
      case 'biometric_locked':
        return 'Biyometrik doğrulama kilitli. PIN ile giriş yapın';
      
      case 'biometric_timeout':
        return 'Biyometrik doğrulama zaman aşımına uğradı';
      
      // Oturum hataları
      case 'session_expired':
        return 'Oturumunuz sona erdi. Lütfen tekrar giriş yapın';
      
      case 'session_invalid':
        return 'Geçersiz oturum. Lütfen tekrar giriş yapın';
      
      // Güvenlik hataları
      case 'security_threat_detected':
        return 'Güvenlik tehdidi tespit edildi. Uygulama güvenli moda alındı';
      
      case 'device_not_secure':
        return 'Cihazınız güvenli değil. Root/jailbreak tespit edildi';
      
      case 'screenshot_blocked':
        return 'Güvenlik nedeniyle ekran görüntüsü alınamaz';
      
      // Konfigürasyon hataları
      case 'config_invalid':
        return 'Güvenlik konfigürasyonu geçersiz';
      
      case 'config_missing':
        return 'Güvenlik konfigürasyonu bulunamadı';
      
      // Genel hataları
      case 'unknown_error':
        return 'Bilinmeyen bir hata oluştu';
      
      case 'network_error':
        return 'Ağ bağlantısı hatası';
      
      case 'storage_error':
        return 'Veri depolama hatası';
      
      default:
        return 'Bir hata oluştu: $errorCode';
    }
  }

  /// Başarı mesajı oluşturur
  /// 
  /// [successCode] başarı kodu
  /// [context] ek bağlam bilgisi
  /// 
  /// Returns kullanıcı dostu başarı mesajı
  static String getSuccessMessage(String successCode, {Map<String, dynamic>? context}) {
    switch (successCode) {
      case 'pin_created':
        return 'PIN başarıyla oluşturuldu';
      
      case 'pin_changed':
        return 'PIN başarıyla değiştirildi';
      
      case 'pin_reset':
        return 'PIN başarıyla sıfırlandı';
      
      case 'biometric_enrolled':
        return 'Biyometrik doğrulama başarıyla etkinleştirildi';
      
      case 'biometric_disabled':
        return 'Biyometrik doğrulama devre dışı bırakıldı';
      
      case 'auth_success':
        return 'Giriş başarılı';
      
      case 'config_saved':
        return 'Güvenlik ayarları kaydedildi';
      
      case 'two_factor_enabled':
        return 'İki faktörlü doğrulama etkinleştirildi';
      
      case 'two_factor_disabled':
        return 'İki faktörlü doğrulama devre dışı bırakıldı';
      
      default:
        return 'İşlem başarılı';
    }
  }
}
