/// Güvenlik validasyon yardımcıları
/// 
/// Bu sınıf güvenlik konfigürasyon validasyonu ve hata mesajı yönetimi sağlar.
library;

import '../../../models/security/security_config.dart';

/// Güvenlik validasyon sınıfı
class SecurityValidator {
  /// Güvenlik konfigürasyonunu validate eder
  static String? validateSecurityConfig(SecurityConfig config) {
    return config.validate();
  }

  /// Biyometrik konfigürasyonu validate eder
  static String? validateBiometricConfig(BiometricConfiguration config) {
    return config.validate();
  }

  /// Oturum konfigürasyonu validate eder
  static String? validateSessionConfig(SessionConfiguration config) {
    return config.validate();
  }

  /// İki faktörlü doğrulama konfigürasyonu validate eder
  static String? validateTwoFactorConfig(TwoFactorConfiguration config) {
    return config.validate();
  }

  /// Güvenlik seviyesi hesaplama
  static int calculateSecurityLevel(SecurityConfig config) {
    int level = 0;
    
    if (config.isBiometricEnabled) level += 50;
    if (config.isTwoFactorEnabled) level += 30;
    if (config.sessionTimeout.inMinutes <= 5) level += 20;
    
    return level.clamp(0, 100);
  }

  /// Güvenlik önerileri
  static List<String> getSecurityRecommendations(SecurityConfig config) {
    List<String> recommendations = [];
    
    if (!config.isBiometricEnabled) {
      recommendations.add('Biyometrik doğrulamayı etkinleştirin');
    }
    
    if (!config.isTwoFactorEnabled) {
      recommendations.add('İki faktörlü doğrulamayı etkinleştirin');
    }
    
    if (config.sessionTimeout.inMinutes > 10) {
      recommendations.add('Oturum zaman aşımını kısaltın');
    }
    
    return recommendations;
  }

  /// Hata mesajı döndürür
  static String getErrorMessage(String code) {
    switch (code) {
      case 'biometric_failed':
        return 'Biyometrik doğrulama başarısız';
      case 'biometric_not_available':
        return 'Biyometrik sensör bulunamadı';
      default:
        return 'Bir hata oluştu';
    }
  }

  /// Başarı mesajı döndürür
  static String getSuccessMessage(String code) {
    switch (code) {
      case 'config_updated':
        return 'Ayarlar güncellendi';
      default:
        return 'İşlem başarılı';
    }
  }
}
