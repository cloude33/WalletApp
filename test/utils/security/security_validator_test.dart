import 'package:flutter_test/flutter_test.dart';
import 'package:money/models/security/security_config.dart';
import 'package:money/models/security/biometric_type.dart';
import 'package:money/utils/security/security_validator.dart';

void main() {
  group('SecurityValidator - PIN Strength Tests', () {
    test('should reject PIN with all same digits', () {
      final result = SecurityValidator.checkPINStrength('1111');
      
      expect(result.isAcceptable, isFalse);
      expect(result.strength, PINStrength.veryWeak);
      expect(result.warnings, contains('Tüm rakamlar aynı'));
    });

    test('should detect PIN with sequential digits ascending', () {
      final result = SecurityValidator.checkPINStrength('12345');
      
      expect(result.warnings, contains('Ardışık rakamlar içeriyor'));
    });

    test('should detect PIN with sequential digits descending', () {
      final result = SecurityValidator.checkPINStrength('54321');
      
      expect(result.warnings, contains('Ardışık rakamlar içeriyor'));
    });

    test('should flag common PINs with warnings', () {
      // Test specific common PINs
      final result1234 = SecurityValidator.checkPINStrength('1234');
      expect(result1234.warnings, contains('Yaygın kullanılan bir PIN'));
      
      final result0000 = SecurityValidator.checkPINStrength('0000');
      expect(result0000.warnings.any((w) => 
        w.contains('Yaygın') || w.contains('aynı')
      ), isTrue);
      
      final result1111 = SecurityValidator.checkPINStrength('1111');
      expect(result1111.warnings, contains('Tüm rakamlar aynı'));
      
      final result1212 = SecurityValidator.checkPINStrength('1212');
      expect(result1212.warnings.any((w) => 
        w.contains('Yaygın') || w.contains('Tekrarlayan')
      ), isTrue);
    });

    test('should reject PIN with repeating pairs', () {
      final result = SecurityValidator.checkPINStrength('1212');
      
      expect(result.warnings, contains('Tekrarlayan çiftler içeriyor'));
    });

    test('should detect PIN with date pattern', () {
      final result = SecurityValidator.checkPINStrength('0315'); // March 15
      
      expect(result.warnings, contains('Tarih benzeri bir desen içeriyor'));
    });

    test('should accept strong PIN', () {
      final result = SecurityValidator.checkPINStrength('7391');
      
      expect(result.isAcceptable, isTrue);
      expect(result.strength, isIn([PINStrength.strong, PINStrength.veryStrong]));
      expect(result.warnings, isEmpty);
    });

    test('should reject PIN with non-numeric characters', () {
      final result = SecurityValidator.checkPINStrength('12a4');
      
      expect(result.isAcceptable, isFalse);
      expect(result.warnings, contains('PIN sadece rakamlardan oluşmalı'));
    });

    test('should reject PIN shorter than minimum length', () {
      final config = PINConfiguration(minLength: 4, maxLength: 6);
      final result = SecurityValidator.checkPINStrength('123', config: config);
      
      expect(result.isAcceptable, isFalse);
      expect(result.warnings, contains('PIN en az 4 haneli olmalı'));
    });

    test('should reject PIN longer than maximum length', () {
      final config = PINConfiguration(minLength: 4, maxLength: 6);
      final result = SecurityValidator.checkPINStrength('1234567', config: config);
      
      expect(result.isAcceptable, isFalse);
      expect(result.warnings, contains('PIN en fazla 6 haneli olmalı'));
    });

    test('should give bonus for longer PINs', () {
      final result4 = SecurityValidator.checkPINStrength('7391');
      final result6 = SecurityValidator.checkPINStrength('739182');
      
      // Both might be capped at 100, so check they're both high or result6 >= result4
      expect(result6.score, greaterThanOrEqualTo(result4.score));
    });

    test('should enforce complex PIN requirement', () {
      final config = PINConfiguration(requireComplexPIN: true);
      final result = SecurityValidator.checkPINStrength('1234', config: config);
      
      expect(result.isAcceptable, isFalse);
      expect(result.warnings.any((w) => w.contains('Karmaşık PIN gerekli')), isTrue);
    });

    test('should calculate correct strength levels', () {
      // Very weak
      final veryWeak = SecurityValidator.checkPINStrength('1111');
      expect(veryWeak.strength, PINStrength.veryWeak);
      
      // Strong
      final strong = SecurityValidator.checkPINStrength('7391');
      expect(strong.strength, isIn([PINStrength.strong, PINStrength.veryStrong]));
    });

    test('should provide suggestions for weak PINs', () {
      final result = SecurityValidator.checkPINStrength('1111');
      
      expect(result.suggestions, isNotEmpty);
      expect(result.suggestions, contains('Farklı rakamlar kullanın'));
    });
  });

  group('SecurityValidator - Security Config Tests', () {
    test('should accept valid security config', () {
      final config = SecurityConfig.defaultConfig();
      final error = SecurityValidator.validateSecurityConfig(config);
      
      expect(error, isNull);
    });

    test('should reject config with too few PIN attempts', () {
      final config = SecurityConfig(
        isPINEnabled: true,
        maxPINAttempts: 2,
        pinConfig: PINConfiguration.defaultConfig(),
        biometricConfig: BiometricConfiguration.defaultConfig(),
        sessionConfig: SessionConfiguration.defaultConfig(),
        twoFactorConfig: TwoFactorConfiguration.defaultConfig(),
      );
      
      final error = SecurityValidator.validateSecurityConfig(config);
      
      expect(error, isNotNull);
      expect(error, contains('en az 3 deneme'));
    });

    test('should reject config with biometric enabled but no types', () {
      final config = SecurityConfig(
        isBiometricEnabled: true,
        enabledBiometrics: [],
        pinConfig: PINConfiguration.defaultConfig(),
        biometricConfig: BiometricConfiguration.defaultConfig(),
        sessionConfig: SessionConfiguration.defaultConfig(),
        twoFactorConfig: TwoFactorConfiguration.defaultConfig(),
      );
      
      final error = SecurityValidator.validateSecurityConfig(config);
      
      expect(error, isNotNull);
      expect(error, contains('en az bir biyometrik tür'));
    });

    test('should reject config with no auth methods enabled', () {
      final config = SecurityConfig(
        isPINEnabled: false,
        isBiometricEnabled: false,
        pinConfig: PINConfiguration.defaultConfig(),
        biometricConfig: BiometricConfiguration.defaultConfig(),
        sessionConfig: SessionConfiguration.defaultConfig(),
        twoFactorConfig: TwoFactorConfiguration.defaultConfig(),
      );
      
      final error = SecurityValidator.validateSecurityConfig(config);
      
      expect(error, isNotNull);
      expect(error, contains('En az bir kimlik doğrulama yöntemi'));
    });

    test('should reject config with 2FA enabled but no methods', () {
      final config = SecurityConfig(
        isTwoFactorEnabled: true,
        pinConfig: PINConfiguration.defaultConfig(),
        biometricConfig: BiometricConfiguration.defaultConfig(),
        sessionConfig: SessionConfiguration.defaultConfig(),
        twoFactorConfig: TwoFactorConfiguration(
          enableSMS: false,
          enableEmail: false,
          enableTOTP: false,
        ),
      );
      
      final error = SecurityValidator.validateSecurityConfig(config);
      
      expect(error, isNotNull);
      expect(error, contains('en az bir yöntem'));
    });

    test('should accept config with biometric and types', () {
      final config = SecurityConfig(
        isBiometricEnabled: true,
        enabledBiometrics: [BiometricType.fingerprint],
        pinConfig: PINConfiguration.defaultConfig(),
        biometricConfig: BiometricConfiguration.defaultConfig(),
        sessionConfig: SessionConfiguration.defaultConfig(),
        twoFactorConfig: TwoFactorConfiguration.defaultConfig(),
      );
      
      final error = SecurityValidator.validateSecurityConfig(config);
      
      expect(error, isNull);
    });
  });

  group('SecurityValidator - PIN Config Tests', () {
    test('should accept valid PIN config', () {
      final config = PINConfiguration.defaultConfig();
      final error = SecurityValidator.validatePINConfig(config);
      
      expect(error, isNull);
    });

    test('should reject PIN config with minLength < 4', () {
      final config = PINConfiguration(minLength: 3);
      final error = SecurityValidator.validatePINConfig(config);
      
      expect(error, isNotNull);
      expect(error, contains('Minimum PIN uzunluğu 4'));
    });

    test('should reject PIN config with maxLength > 8', () {
      final config = PINConfiguration(maxLength: 9);
      final error = SecurityValidator.validatePINConfig(config);
      
      expect(error, isNotNull);
      expect(error, contains('Maksimum PIN uzunluğu 8'));
    });

    test('should reject PIN config with minLength > maxLength', () {
      final config = PINConfiguration(minLength: 6, maxLength: 4);
      final error = SecurityValidator.validatePINConfig(config);
      
      expect(error, isNotNull);
      expect(error, contains('Minimum uzunluk maksimum uzunluktan büyük olamaz'));
    });

    test('should reject PIN config with maxAttempts <= 0', () {
      final config = PINConfiguration(maxAttempts: 0);
      final error = SecurityValidator.validatePINConfig(config);
      
      expect(error, isNotNull);
      expect(error, contains('pozitif olmalı'));
    });

    test('should reject PIN config with lockoutDuration < 30 seconds', () {
      final config = PINConfiguration(
        lockoutDuration: Duration(seconds: 20),
      );
      final error = SecurityValidator.validatePINConfig(config);
      
      expect(error, isNotNull);
      expect(error, contains('en az 30 saniye'));
    });
  });

  group('SecurityValidator - Error Messages', () {
    test('should return correct error message for pin_too_short', () {
      final message = SecurityValidator.getErrorMessage(
        'pin_too_short',
        context: {'minLength': 4},
      );
      
      expect(message, contains('en az 4 haneli'));
    });

    test('should return correct error message for pin_incorrect', () {
      final message = SecurityValidator.getErrorMessage(
        'pin_incorrect',
        context: {'remainingAttempts': 3},
      );
      
      expect(message, contains('Yanlış PIN'));
      expect(message, contains('Kalan deneme: 3'));
    });

    test('should return correct error message for pin_locked', () {
      final message = SecurityValidator.getErrorMessage(
        'pin_locked',
        context: {'lockoutDuration': Duration(minutes: 5, seconds: 30)},
      );
      
      expect(message, contains('Hesap kilitli'));
      expect(message, contains('5 dakika 30 saniye'));
    });

    test('should return correct error message for biometric_not_available', () {
      final message = SecurityValidator.getErrorMessage('biometric_not_available');
      
      expect(message, contains('Biyometrik doğrulama'));
      expect(message, contains('kullanılamıyor'));
    });

    test('should return correct error message for session_expired', () {
      final message = SecurityValidator.getErrorMessage('session_expired');
      
      expect(message, contains('Oturumunuz sona erdi'));
    });

    test('should return default message for unknown error', () {
      final message = SecurityValidator.getErrorMessage('unknown_code');
      
      expect(message, contains('Bir hata oluştu'));
    });
  });

  group('SecurityValidator - Success Messages', () {
    test('should return correct success message for pin_created', () {
      final message = SecurityValidator.getSuccessMessage('pin_created');
      
      expect(message, contains('PIN başarıyla oluşturuldu'));
    });

    test('should return correct success message for biometric_enrolled', () {
      final message = SecurityValidator.getSuccessMessage('biometric_enrolled');
      
      expect(message, contains('Biyometrik doğrulama'));
      expect(message, contains('etkinleştirildi'));
    });

    test('should return correct success message for auth_success', () {
      final message = SecurityValidator.getSuccessMessage('auth_success');
      
      expect(message, contains('Giriş başarılı'));
    });

    test('should return default message for unknown success code', () {
      final message = SecurityValidator.getSuccessMessage('unknown_code');
      
      expect(message, contains('İşlem başarılı'));
    });
  });

  group('SecurityValidator - PIN Strength Enum', () {
    test('should have correct descriptions', () {
      expect(PINStrength.veryWeak.description, 'Çok Zayıf');
      expect(PINStrength.weak.description, 'Zayıf');
      expect(PINStrength.medium.description, 'Orta');
      expect(PINStrength.strong.description, 'Güçlü');
      expect(PINStrength.veryStrong.description, 'Çok Güçlü');
    });

    test('should have correct scores', () {
      expect(PINStrength.veryWeak.score, 20);
      expect(PINStrength.weak.score, 40);
      expect(PINStrength.medium.score, 60);
      expect(PINStrength.strong.score, 80);
      expect(PINStrength.veryStrong.score, 100);
    });

    test('should have valid color codes', () {
      expect(PINStrength.veryWeak.colorCode, isNotEmpty);
      expect(PINStrength.weak.colorCode, isNotEmpty);
      expect(PINStrength.medium.colorCode, isNotEmpty);
      expect(PINStrength.strong.colorCode, isNotEmpty);
      expect(PINStrength.veryStrong.colorCode, isNotEmpty);
    });
  });

  group('SecurityValidator - Edge Cases', () {
    test('should handle empty PIN', () {
      final result = SecurityValidator.checkPINStrength('');
      
      expect(result.isAcceptable, isFalse);
    });

    test('should handle very long PIN', () {
      final config = PINConfiguration(minLength: 4, maxLength: 6);
      final result = SecurityValidator.checkPINStrength('12345678901234567890', config: config);
      
      expect(result.isAcceptable, isFalse);
    });

    test('should handle PIN with special characters', () {
      final result = SecurityValidator.checkPINStrength('12!@');
      
      expect(result.isAcceptable, isFalse);
      expect(result.warnings, contains('PIN sadece rakamlardan oluşmalı'));
    });

    test('should handle null context in error messages', () {
      final message = SecurityValidator.getErrorMessage('pin_incorrect');
      
      expect(message, isNotNull);
      expect(message, contains('Yanlış PIN'));
    });

    test('should handle lockout duration with only seconds', () {
      final message = SecurityValidator.getErrorMessage(
        'pin_locked',
        context: {'lockoutDuration': Duration(seconds: 45)},
      );
      
      expect(message, contains('45 saniye'));
    });
  });

  group('SecurityValidator - Biometric Config Tests', () {
    test('should accept valid biometric config', () {
      final config = BiometricConfiguration.defaultConfig();
      final error = SecurityValidator.validateBiometricConfig(config);
      
      expect(error, isNull);
    });

    test('should reject biometric config with maxAttempts <= 0', () {
      final config = BiometricConfiguration(maxAttempts: 0);
      final error = SecurityValidator.validateBiometricConfig(config);
      
      expect(error, isNotNull);
      expect(error, contains('pozitif olmalı'));
    });

    test('should reject biometric config with timeout < 10 seconds', () {
      final config = BiometricConfiguration(timeout: Duration(seconds: 5));
      final error = SecurityValidator.validateBiometricConfig(config);
      
      expect(error, isNotNull);
      expect(error, contains('en az 10 saniye'));
    });
  });

  group('SecurityValidator - Session Config Tests', () {
    test('should accept valid session config', () {
      final config = SessionConfiguration.defaultConfig();
      final error = SecurityValidator.validateSessionConfig(config);
      
      expect(error, isNull);
    });

    test('should reject session config with sessionTimeout < 30 seconds', () {
      final config = SessionConfiguration(
        sessionTimeout: Duration(seconds: 20),
      );
      final error = SecurityValidator.validateSessionConfig(config);
      
      expect(error, isNotNull);
      expect(error, contains('en az 30 saniye'));
    });

    test('should reject session config with negative backgroundLockDelay', () {
      final config = SessionConfiguration(
        backgroundLockDelay: Duration(seconds: -10),
      );
      final error = SecurityValidator.validateSessionConfig(config);
      
      expect(error, isNotNull);
      expect(error, contains('negatif olamaz'));
    });
  });

  group('SecurityValidator - Two Factor Config Tests', () {
    test('should accept valid two factor config', () {
      final config = TwoFactorConfiguration.defaultConfig();
      final error = SecurityValidator.validateTwoFactorConfig(config);
      
      expect(error, isNull);
    });

    test('should reject two factor config with codeValidityDuration < 1 minute', () {
      final config = TwoFactorConfiguration(
        codeValidityDuration: Duration(seconds: 30),
      );
      final error = SecurityValidator.validateTwoFactorConfig(config);
      
      expect(error, isNotNull);
      expect(error, contains('en az 1 dakika'));
    });

    test('should reject two factor config with codeValidityDuration > 30 minutes', () {
      final config = TwoFactorConfiguration(
        codeValidityDuration: Duration(minutes: 35),
      );
      final error = SecurityValidator.validateTwoFactorConfig(config);
      
      expect(error, isNotNull);
      expect(error, contains('30 dakikadan fazla olamaz'));
    });
  });
}
