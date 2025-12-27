import 'package:flutter_test/flutter_test.dart';
import 'package:money/models/security/security_config.dart';
import 'package:money/models/security/biometric_type.dart';
import 'package:money/utils/security/security_validator.dart';

void main() {
  // PIN Strength Tests removed
  // PIN Config Tests removed
  // PIN Strength Enum Tests removed

  group('SecurityValidator - Security Config Tests', () {
    test('should accept valid security config', () {
      final config = SecurityConfig.defaultConfig();
      final error = SecurityValidator.validateSecurityConfig(config);
      
      expect(error, isNull);
    });

    test('should reject config with biometric enabled but no types', () {
      final config = SecurityConfig(
        isBiometricEnabled: true,
        enabledBiometrics: [],
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
        isBiometricEnabled: false,
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
        biometricConfig: BiometricConfiguration.defaultConfig(),
        sessionConfig: SessionConfiguration.defaultConfig(),
        twoFactorConfig: TwoFactorConfiguration.defaultConfig(),
      );
      
      final error = SecurityValidator.validateSecurityConfig(config);
      
      expect(error, isNull);
    });
  });

  group('SecurityValidator - Error Messages', () {
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
  
  // PIN Strength Enum Tests removed

  group('SecurityValidator - Edge Cases', () {
    test('should handle biometric config with negative attempts', () {
      final config = BiometricConfiguration(maxAttempts: -1);
      final error = SecurityValidator.validateBiometricConfig(config);
      expect(error, isNotNull);
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
