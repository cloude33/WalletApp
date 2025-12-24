/// Güvenlik Validator Kullanım Örnekleri
/// 
/// Bu dosya SecurityValidator sınıfının nasıl kullanılacağını gösterir.
library;

import 'package:money/models/security/security_config.dart';
import 'package:money/utils/security/security_validator.dart';

void main() {
  // Örnek 1: PIN güçlülük kontrolü
  print('=== PIN Güçlülük Kontrolü ===');
  
  final weakPIN = SecurityValidator.checkPINStrength('1234');
  print('PIN: 1234');
  print('Güçlülük: ${weakPIN.strength.description}');
  print('Puan: ${weakPIN.score}');
  print('Kabul edilebilir: ${weakPIN.isAcceptable}');
  print('Uyarılar: ${weakPIN.warnings}');
  print('Öneriler: ${weakPIN.suggestions}');
  print('');
  
  final strongPIN = SecurityValidator.checkPINStrength('7391');
  print('PIN: 7391');
  print('Güçlülük: ${strongPIN.strength.description}');
  print('Puan: ${strongPIN.score}');
  print('Kabul edilebilir: ${strongPIN.isAcceptable}');
  print('');
  
  // Örnek 2: Konfigürasyon ile PIN kontrolü
  print('=== Konfigürasyon ile PIN Kontrolü ===');
  
  final config = PINConfiguration(
    minLength: 4,
    maxLength: 6,
    requireComplexPIN: true,
  );
  
  final result = SecurityValidator.checkPINStrength('1234', config: config);
  print('PIN: 1234 (Karmaşık PIN gerekli)');
  print('Kabul edilebilir: ${result.isAcceptable}');
  print('Uyarılar: ${result.warnings}');
  print('');
  
  // Örnek 3: Güvenlik konfigürasyonu validasyonu
  print('=== Güvenlik Konfigürasyonu Validasyonu ===');
  
  final securityConfig = SecurityConfig.defaultConfig();
  final configError = SecurityValidator.validateSecurityConfig(securityConfig);
  
  if (configError == null) {
    print('Güvenlik konfigürasyonu geçerli ✓');
  } else {
    print('Hata: $configError');
  }
  print('');
  
  // Örnek 4: Geçersiz konfigürasyon
  print('=== Geçersiz Konfigürasyon ===');
  
  final invalidConfig = SecurityConfig(
    isPINEnabled: false,
    isBiometricEnabled: false,
    pinConfig: PINConfiguration.defaultConfig(),
    biometricConfig: BiometricConfiguration.defaultConfig(),
    sessionConfig: SessionConfiguration.defaultConfig(),
    twoFactorConfig: TwoFactorConfiguration.defaultConfig(),
  );
  
  final invalidError = SecurityValidator.validateSecurityConfig(invalidConfig);
  print('Hata: $invalidError');
  print('');
  
  // Örnek 5: Hata mesajları
  print('=== Hata Mesajları ===');
  
  print(SecurityValidator.getErrorMessage('pin_too_short', 
    context: {'minLength': 4}));
  
  print(SecurityValidator.getErrorMessage('pin_incorrect', 
    context: {'remainingAttempts': 3}));
  
  print(SecurityValidator.getErrorMessage('pin_locked', 
    context: {'lockoutDuration': Duration(minutes: 5)}));
  
  print(SecurityValidator.getErrorMessage('biometric_not_available'));
  print('');
  
  // Örnek 6: Başarı mesajları
  print('=== Başarı Mesajları ===');
  
  print(SecurityValidator.getSuccessMessage('pin_created'));
  print(SecurityValidator.getSuccessMessage('biometric_enrolled'));
  print(SecurityValidator.getSuccessMessage('auth_success'));
  print('');
  
  // Örnek 7: PIN güçlülük seviyeleri
  print('=== PIN Güçlülük Seviyeleri ===');
  
  for (final strength in PINStrength.values) {
    print('${strength.description}: Puan ${strength.score}, Renk ${strength.colorCode}');
  }
  print('');
  
  // Örnek 8: Farklı PIN türleri
  print('=== Farklı PIN Türleri ===');
  
  final pins = {
    '1111': 'Tüm rakamlar aynı',
    '1234': 'Ardışık rakamlar',
    '1212': 'Tekrarlayan çiftler',
    '0315': 'Tarih benzeri',
    '7391': 'Güçlü PIN',
  };
  
  for (final entry in pins.entries) {
    final result = SecurityValidator.checkPINStrength(entry.key);
    print('${entry.key} (${entry.value}): ${result.strength.description} - Puan: ${result.score}');
  }
}
