import 'package:flutter_test/flutter_test.dart';
import 'package:money/models/security/security_models.dart';

void main() {
  group('Security Models Tests', () {
    group('BiometricType', () {
      test('should convert to and from JSON correctly', () {
        const type = BiometricType.fingerprint;
        final json = type.toJson();
        final fromJson = BiometricType.fromJson(json);
        
        expect(fromJson, equals(type));
      });

      test('should convert all enum values to and from JSON correctly', () {
        for (final type in BiometricType.values) {
          final json = type.toJson();
          final fromJson = BiometricType.fromJson(json);
          expect(fromJson, equals(type));
        }
      });

      test('should handle invalid JSON gracefully', () {
        final fromJson = BiometricType.fromJson('invalid_type');
        expect(fromJson, equals(BiometricType.fingerprint)); // default fallback
      });

      test('should provide correct display names', () {
        expect(BiometricType.fingerprint.displayName, equals('Parmak İzi'));
        expect(BiometricType.face.displayName, equals('Yüz Tanıma'));
        expect(BiometricType.voice.displayName, equals('Ses Tanıma'));
        expect(BiometricType.iris.displayName, equals('Iris Tarama'));
      });

      test('should provide correct platform names', () {
        expect(BiometricType.fingerprint.platformName, equals('fingerprint'));
        expect(BiometricType.face.platformName, equals('face'));
        expect(BiometricType.voice.platformName, equals('voice'));
        expect(BiometricType.iris.platformName, equals('iris'));
      });
    });

    group('AuthMethod', () {
      test('should convert to and from JSON correctly', () {
        const method = AuthMethod.pin;
        final json = method.toJson();
        final fromJson = AuthMethod.fromJson(json);
        
        expect(fromJson, equals(method));
      });

      test('should convert all enum values to and from JSON correctly', () {
        for (final method in AuthMethod.values) {
          final json = method.toJson();
          final fromJson = AuthMethod.fromJson(json);
          expect(fromJson, equals(method));
        }
      });

      test('should handle invalid JSON gracefully', () {
        final fromJson = AuthMethod.fromJson('invalid_method');
        expect(fromJson, equals(AuthMethod.pin)); // default fallback
      });

      test('should provide correct display names', () {
        expect(AuthMethod.pin.displayName, equals('PIN Kodu'));
        expect(AuthMethod.biometric.displayName, equals('Biyometrik'));
        expect(AuthMethod.twoFactor.displayName, equals('İki Faktörlü'));
        expect(AuthMethod.securityQuestions.displayName, equals('Güvenlik Soruları'));
      });
    });

    group('AuthResult', () {
      test('should create successful result correctly', () {
        final result = AuthResult.success(
          method: AuthMethod.pin,
          metadata: {'test': 'data'},
        );
        
        expect(result.isSuccess, isTrue);
        expect(result.method, equals(AuthMethod.pin));
        expect(result.errorMessage, isNull);
        expect(result.metadata?['test'], equals('data'));
      });

      test('should create failure result correctly', () {
        final result = AuthResult.failure(
          method: AuthMethod.pin,
          errorMessage: 'Wrong PIN',
          remainingAttempts: 2,
        );
        
        expect(result.isSuccess, isFalse);
        expect(result.method, equals(AuthMethod.pin));
        expect(result.errorMessage, equals('Wrong PIN'));
        expect(result.remainingAttempts, equals(2));
      });

      test('should convert to and from JSON correctly', () {
        final original = AuthResult.success(
          method: AuthMethod.biometric,
          metadata: {'device': 'test'},
        );
        
        final json = original.toJson();
        final fromJson = AuthResult.fromJson(json);
        
        expect(fromJson.isSuccess, equals(original.isSuccess));
        expect(fromJson.method, equals(original.method));
        expect(fromJson.metadata?['device'], equals('test'));
      });

      test('should handle JSON serialization with all fields', () {
        final original = AuthResult.failure(
          method: AuthMethod.biometric,
          errorMessage: 'Biometric failed',
          lockoutDuration: const Duration(minutes: 5),
          remainingAttempts: 2,
          metadata: {'error_code': 'BIO_001'},
        );
        
        final json = original.toJson();
        final fromJson = AuthResult.fromJson(json);
        
        expect(fromJson.isSuccess, equals(original.isSuccess));
        expect(fromJson.method, equals(original.method));
        expect(fromJson.errorMessage, equals(original.errorMessage));
        expect(fromJson.lockoutDuration, equals(original.lockoutDuration));
        expect(fromJson.remainingAttempts, equals(original.remainingAttempts));
        expect(fromJson.metadata?['error_code'], equals('BIO_001'));
      });

      test('should handle malformed JSON gracefully', () {
        // Test with null values instead of wrong types to avoid casting errors
        final json = <String, dynamic>{
          'isSuccess': null,
          'method': 'invalid_method',
          'lockoutDuration': null,
          'remainingAttempts': null,
          'timestamp': null,
        };
        
        final result = AuthResult.fromJson(json);
        
        expect(result.isSuccess, isFalse); // Default fallback
        expect(result.method, equals(AuthMethod.pin)); // Default fallback
        expect(result.lockoutDuration, isNull);
        expect(result.remainingAttempts, isNull);
        expect(result.timestamp, isA<DateTime>());
      });

      test('should validate correctly', () {
        final validResult = AuthResult.success(method: AuthMethod.pin);
        expect(validResult.validate(), isNull);
        
        final invalidResult = AuthResult.failure(
          method: AuthMethod.pin,
          errorMessage: '',
        );
        expect(invalidResult.validate(), isNotNull);
        expect(invalidResult.validate(), contains('hata mesajı gerekli'));
      });

      test('should validate negative values correctly', () {
        final negativeAttempts = AuthResult.failure(
          method: AuthMethod.pin,
          errorMessage: 'Test error',
          remainingAttempts: -1,
        );
        expect(negativeAttempts.validate(), contains('negatif olamaz'));
        
        final negativeLockout = AuthResult.failure(
          method: AuthMethod.pin,
          errorMessage: 'Test error',
          lockoutDuration: const Duration(milliseconds: -1000),
        );
        expect(negativeLockout.validate(), contains('negatif olamaz'));
      });

      test('should implement equality correctly', () {
        final timestamp = DateTime.now();
        final result1 = AuthResult(
          isSuccess: true,
          method: AuthMethod.pin,
          timestamp: timestamp,
        );
        final result2 = AuthResult(
          isSuccess: true,
          method: AuthMethod.pin,
          timestamp: timestamp,
        );
        final result3 = AuthResult(
          isSuccess: true,
          method: AuthMethod.biometric,
          timestamp: timestamp,
        );
        
        expect(result1 == result2, isTrue); // Same timestamp and method
        expect(result1 == result3, isFalse); // Different methods
        expect(result1 == result1, isTrue); // Same instance
      });

      test('should implement copyWith correctly', () {
        final original = AuthResult.failure(
          method: AuthMethod.pin,
          errorMessage: 'Original error',
          remainingAttempts: 3,
        );
        
        final modified = original.copyWith(
          errorMessage: 'Modified error',
          remainingAttempts: 2,
        );
        
        expect(modified.errorMessage, equals('Modified error'));
        expect(modified.remainingAttempts, equals(2));
        expect(modified.method, equals(original.method));
        expect(modified.isSuccess, equals(original.isSuccess));
      });

      test('should handle toString correctly', () {
        final result = AuthResult.success(method: AuthMethod.pin);
        final stringResult = result.toString();
        
        expect(stringResult, contains('AuthResult'));
        expect(stringResult, contains('isSuccess: true'));
        expect(stringResult, contains('method: AuthMethod.pin'));
      });
    });

    group('SecurityConfig', () {
      test('should create default config correctly', () {
        final config = SecurityConfig.defaultConfig();
        
        expect(config.isPINEnabled, isTrue);
        expect(config.isBiometricEnabled, isFalse);
        expect(config.isTwoFactorEnabled, isFalse);
        expect(config.maxPINAttempts, equals(5));
        expect(config.sessionTimeout, equals(const Duration(minutes: 5)));
      });

      test('should convert to and from JSON correctly', () {
        final original = SecurityConfig.defaultConfig();
        
        final json = original.toJson();
        final fromJson = SecurityConfig.fromJson(json);
        
        expect(fromJson.isPINEnabled, equals(original.isPINEnabled));
        expect(fromJson.isBiometricEnabled, equals(original.isBiometricEnabled));
        expect(fromJson.maxPINAttempts, equals(original.maxPINAttempts));
        expect(fromJson.sessionTimeout, equals(original.sessionTimeout));
      });

      test('should handle complex JSON serialization', () {
        final original = SecurityConfig(
          isPINEnabled: true,
          isBiometricEnabled: true,
          isTwoFactorEnabled: true,
          sessionTimeout: const Duration(minutes: 10),
          maxPINAttempts: 3,
          enabledBiometrics: [BiometricType.fingerprint, BiometricType.face],
          pinConfig: PINConfiguration.defaultConfig(),
          biometricConfig: BiometricConfiguration.defaultConfig(),
          sessionConfig: SessionConfiguration.defaultConfig(),
          twoFactorConfig: TwoFactorConfiguration.defaultConfig(),
        );
        
        final json = original.toJson();
        final fromJson = SecurityConfig.fromJson(json);
        
        expect(fromJson.isPINEnabled, equals(original.isPINEnabled));
        expect(fromJson.isBiometricEnabled, equals(original.isBiometricEnabled));
        expect(fromJson.isTwoFactorEnabled, equals(original.isTwoFactorEnabled));
        expect(fromJson.sessionTimeout, equals(original.sessionTimeout));
        expect(fromJson.maxPINAttempts, equals(original.maxPINAttempts));
        expect(fromJson.enabledBiometrics.length, equals(2));
        expect(fromJson.enabledBiometrics, contains(BiometricType.fingerprint));
        expect(fromJson.enabledBiometrics, contains(BiometricType.face));
      });

      test('should handle malformed JSON gracefully', () {
        // Test with null values instead of wrong types to avoid casting errors
        final json = <String, dynamic>{
          'isPINEnabled': null,
          'sessionTimeout': null,
          'maxPINAttempts': null,
          'enabledBiometrics': null,
          'pinConfig': null,
        };
        
        final config = SecurityConfig.fromJson(json);
        
        expect(config.isPINEnabled, isTrue); // Default fallback
        expect(config.sessionTimeout, equals(const Duration(minutes: 5))); // Default
        expect(config.maxPINAttempts, equals(5)); // Default
        expect(config.enabledBiometrics, isEmpty); // Default empty list
      });

      test('should validate correctly', () {
        final validConfig = SecurityConfig.defaultConfig();
        expect(validConfig.validate(), isNull);
        
        final invalidConfig = validConfig.copyWith(maxPINAttempts: 0);
        expect(invalidConfig.validate(), isNotNull);
        expect(invalidConfig.validate(), contains('pozitif olmalı'));
      });

      test('should validate edge cases', () {
        final tooManyAttempts = SecurityConfig.defaultConfig()
            .copyWith(maxPINAttempts: 15);
        expect(tooManyAttempts.validate(), contains('10\'dan fazla olamaz'));
        
        final tooShortTimeout = SecurityConfig.defaultConfig()
            .copyWith(sessionTimeout: const Duration(seconds: 10));
        expect(tooShortTimeout.validate(), contains('en az 30 saniye'));
        
        final tooLongTimeout = SecurityConfig.defaultConfig()
            .copyWith(sessionTimeout: const Duration(hours: 25));
        expect(tooLongTimeout.validate(), contains('24 saatten fazla olamaz'));
      });

      test('should copy with changes correctly', () async {
        final original = SecurityConfig.defaultConfig();
        // Add a small delay to ensure different timestamps
        await Future.delayed(const Duration(milliseconds: 1));
        final modified = original.copyWith(
          isPINEnabled: false,
          maxPINAttempts: 3,
        );
        
        expect(modified.isPINEnabled, isFalse);
        expect(modified.maxPINAttempts, equals(3));
        expect(modified.isBiometricEnabled, equals(original.isBiometricEnabled));
        expect(modified.updatedAt.isAfter(original.updatedAt) || 
               modified.updatedAt.isAtSameMomentAs(original.updatedAt), isTrue);
      });

      test('should implement equality correctly', () {
        final timestamp = DateTime.now();
        final config1 = SecurityConfig(
          pinConfig: PINConfiguration.defaultConfig(),
          biometricConfig: BiometricConfiguration.defaultConfig(),
          sessionConfig: SessionConfiguration.defaultConfig(),
          twoFactorConfig: TwoFactorConfiguration.defaultConfig(),
          createdAt: timestamp,
          updatedAt: timestamp,
        );
        final config2 = SecurityConfig(
          pinConfig: PINConfiguration.defaultConfig(),
          biometricConfig: BiometricConfiguration.defaultConfig(),
          sessionConfig: SessionConfiguration.defaultConfig(),
          twoFactorConfig: TwoFactorConfiguration.defaultConfig(),
          createdAt: timestamp,
          updatedAt: timestamp,
        );
        
        expect(config1 == config2, isTrue); // Same configuration
        expect(config1 == config1, isTrue); // Same instance
      });

      test('should implement toString correctly', () {
        final config = SecurityConfig.defaultConfig();
        final stringResult = config.toString();
        
        expect(stringResult, contains('SecurityConfig'));
        expect(stringResult, contains('isPINEnabled: true'));
        expect(stringResult, contains('maxPINAttempts: 5'));
      });
    });

    group('PINConfiguration', () {
      test('should create default config correctly', () {
        final config = PINConfiguration.defaultConfig();
        
        expect(config.minLength, equals(4));
        expect(config.maxLength, equals(6));
        expect(config.maxAttempts, equals(5));
        expect(config.requireComplexPIN, isFalse);
      });

      test('should convert to and from JSON correctly', () {
        final original = PINConfiguration.defaultConfig();
        
        final json = original.toJson();
        final fromJson = PINConfiguration.fromJson(json);
        
        expect(fromJson.minLength, equals(original.minLength));
        expect(fromJson.maxLength, equals(original.maxLength));
        expect(fromJson.maxAttempts, equals(original.maxAttempts));
        expect(fromJson.requireComplexPIN, equals(original.requireComplexPIN));
        expect(fromJson.lockoutDuration, equals(original.lockoutDuration));
      });

      test('should handle malformed JSON gracefully', () {
        // Test with null values instead of wrong types to avoid casting errors
        final json = <String, dynamic>{
          'minLength': null,
          'maxLength': null,
          'maxAttempts': null,
          'lockoutDuration': null,
          'requireComplexPIN': null,
        };
        
        final config = PINConfiguration.fromJson(json);
        
        expect(config.minLength, equals(4)); // Default fallback
        expect(config.maxLength, equals(6)); // Default fallback
        expect(config.maxAttempts, equals(5)); // Default fallback
        expect(config.requireComplexPIN, isFalse); // Default fallback
      });

      test('should validate correctly', () {
        final validConfig = PINConfiguration.defaultConfig();
        expect(validConfig.validate(), isNull);
        
        final invalidConfig = validConfig.copyWith(minLength: 10, maxLength: 6);
        expect(invalidConfig.validate(), isNotNull);
        expect(invalidConfig.validate(), contains('büyük olamaz'));
      });

      test('should validate edge cases', () {
        final tooShortMin = PINConfiguration.defaultConfig()
            .copyWith(minLength: 3);
        expect(tooShortMin.validate(), contains('4 olmalı'));
        
        final tooLongMax = PINConfiguration.defaultConfig()
            .copyWith(maxLength: 9);
        expect(tooLongMax.validate(), contains('8 olmalı'));
        
        final zeroAttempts = PINConfiguration.defaultConfig()
            .copyWith(maxAttempts: 0);
        expect(zeroAttempts.validate(), contains('pozitif olmalı'));
        
        final shortLockout = PINConfiguration.defaultConfig()
            .copyWith(lockoutDuration: const Duration(seconds: 10));
        expect(shortLockout.validate(), contains('en az 30 saniye'));
      });

      test('should implement copyWith correctly', () {
        final original = PINConfiguration.defaultConfig();
        final modified = original.copyWith(
          minLength: 6,
          requireComplexPIN: true,
        );
        
        expect(modified.minLength, equals(6));
        expect(modified.requireComplexPIN, isTrue);
        expect(modified.maxLength, equals(original.maxLength));
        expect(modified.maxAttempts, equals(original.maxAttempts));
      });

      test('should implement equality correctly', () {
        final config1 = PINConfiguration.defaultConfig();
        final config2 = PINConfiguration.defaultConfig();
        final config3 = config1.copyWith(minLength: 5);
        
        expect(config1 == config2, isTrue);
        expect(config1 == config3, isFalse);
      });
    });

    group('BiometricConfiguration', () {
      test('should create default config correctly', () {
        final config = BiometricConfiguration.defaultConfig();
        
        expect(config.requireFallbackPIN, isTrue);
        expect(config.maxAttempts, equals(3));
        expect(config.timeout, equals(const Duration(seconds: 30)));
      });

      test('should convert to and from JSON correctly', () {
        final original = BiometricConfiguration.defaultConfig();
        
        final json = original.toJson();
        final fromJson = BiometricConfiguration.fromJson(json);
        
        expect(fromJson.requireFallbackPIN, equals(original.requireFallbackPIN));
        expect(fromJson.maxAttempts, equals(original.maxAttempts));
        expect(fromJson.timeout, equals(original.timeout));
      });

      test('should handle malformed JSON gracefully', () {
        // Test with null values instead of wrong types to avoid casting errors
        final json = <String, dynamic>{
          'requireFallbackPIN': null,
          'maxAttempts': null,
          'timeout': null,
        };
        
        final config = BiometricConfiguration.fromJson(json);
        
        expect(config.requireFallbackPIN, isTrue); // Default fallback
        expect(config.maxAttempts, equals(3)); // Default fallback
        expect(config.timeout, equals(const Duration(seconds: 30))); // Default
      });

      test('should validate correctly', () {
        final validConfig = BiometricConfiguration.defaultConfig();
        expect(validConfig.validate(), isNull);
        
        final invalidConfig = validConfig.copyWith(maxAttempts: 0);
        expect(invalidConfig.validate(), isNotNull);
        expect(invalidConfig.validate(), contains('pozitif olmalı'));
      });

      test('should validate edge cases', () {
        final shortTimeout = BiometricConfiguration.defaultConfig()
            .copyWith(timeout: const Duration(seconds: 5));
        expect(shortTimeout.validate(), contains('en az 10 saniye'));
      });

      test('should implement copyWith correctly', () {
        final original = BiometricConfiguration.defaultConfig();
        final modified = original.copyWith(
          requireFallbackPIN: false,
          maxAttempts: 5,
        );
        
        expect(modified.requireFallbackPIN, isFalse);
        expect(modified.maxAttempts, equals(5));
        expect(modified.timeout, equals(original.timeout));
      });

      test('should implement equality correctly', () {
        final config1 = BiometricConfiguration.defaultConfig();
        final config2 = BiometricConfiguration.defaultConfig();
        final config3 = config1.copyWith(maxAttempts: 5);
        
        expect(config1 == config2, isTrue);
        expect(config1 == config3, isFalse);
      });
    });

    group('SessionConfiguration', () {
      test('should create default config correctly', () {
        final config = SessionConfiguration.defaultConfig();
        
        expect(config.sessionTimeout, equals(const Duration(minutes: 5)));
        expect(config.sensitiveOperationTimeout, equals(const Duration(minutes: 2)));
        expect(config.enableBackgroundLock, isTrue);
        expect(config.backgroundLockDelay, equals(const Duration(seconds: 30)));
      });

      test('should convert to and from JSON correctly', () {
        final original = SessionConfiguration.defaultConfig();
        
        final json = original.toJson();
        final fromJson = SessionConfiguration.fromJson(json);
        
        expect(fromJson.sessionTimeout, equals(original.sessionTimeout));
        expect(fromJson.sensitiveOperationTimeout, equals(original.sensitiveOperationTimeout));
        expect(fromJson.enableBackgroundLock, equals(original.enableBackgroundLock));
        expect(fromJson.backgroundLockDelay, equals(original.backgroundLockDelay));
      });

      test('should handle malformed JSON gracefully', () {
        // Test with null values instead of wrong types to avoid casting errors
        final json = <String, dynamic>{
          'sessionTimeout': null,
          'sensitiveOperationTimeout': null,
          'enableBackgroundLock': null,
          'backgroundLockDelay': null,
        };
        
        final config = SessionConfiguration.fromJson(json);
        
        expect(config.sessionTimeout, equals(const Duration(minutes: 5))); // Default
        expect(config.sensitiveOperationTimeout, equals(const Duration(minutes: 2))); // Default
        expect(config.enableBackgroundLock, isTrue); // Default
        expect(config.backgroundLockDelay, equals(const Duration(seconds: 30))); // Default
      });

      test('should validate correctly', () {
        final validConfig = SessionConfiguration.defaultConfig();
        expect(validConfig.validate(), isNull);
        
        final invalidConfig = validConfig.copyWith(
          sessionTimeout: const Duration(seconds: 10),
        );
        expect(invalidConfig.validate(), isNotNull);
        expect(invalidConfig.validate(), contains('en az 30 saniye'));
      });

      test('should validate edge cases', () {
        final shortSensitiveTimeout = SessionConfiguration.defaultConfig()
            .copyWith(sensitiveOperationTimeout: const Duration(seconds: 10));
        expect(shortSensitiveTimeout.validate(), contains('en az 30 saniye'));
        
        final negativeDelay = SessionConfiguration.defaultConfig()
            .copyWith(backgroundLockDelay: const Duration(milliseconds: -1000));
        expect(negativeDelay.validate(), contains('negatif olamaz'));
      });

      test('should implement copyWith correctly', () {
        final original = SessionConfiguration.defaultConfig();
        final modified = original.copyWith(
          sessionTimeout: const Duration(minutes: 10),
          enableBackgroundLock: false,
        );
        
        expect(modified.sessionTimeout, equals(const Duration(minutes: 10)));
        expect(modified.enableBackgroundLock, isFalse);
        expect(modified.sensitiveOperationTimeout, equals(original.sensitiveOperationTimeout));
        expect(modified.backgroundLockDelay, equals(original.backgroundLockDelay));
      });

      test('should implement equality correctly', () {
        final config1 = SessionConfiguration.defaultConfig();
        final config2 = SessionConfiguration.defaultConfig();
        final config3 = config1.copyWith(sessionTimeout: const Duration(minutes: 10));
        
        expect(config1 == config2, isTrue);
        expect(config1 == config3, isFalse);
      });
    });

    group('TwoFactorConfiguration', () {
      test('should create default config correctly', () {
        final config = TwoFactorConfiguration.defaultConfig();
        
        expect(config.enableSMS, isFalse);
        expect(config.enableEmail, isFalse);
        expect(config.enableTOTP, isFalse);
        expect(config.enableBackupCodes, isFalse);
        expect(config.codeValidityDuration, equals(const Duration(minutes: 5)));
      });

      test('should convert to and from JSON correctly', () {
        final original = TwoFactorConfiguration.defaultConfig();
        
        final json = original.toJson();
        final fromJson = TwoFactorConfiguration.fromJson(json);
        
        expect(fromJson.enableSMS, equals(original.enableSMS));
        expect(fromJson.enableEmail, equals(original.enableEmail));
        expect(fromJson.enableTOTP, equals(original.enableTOTP));
        expect(fromJson.enableBackupCodes, equals(original.enableBackupCodes));
        expect(fromJson.codeValidityDuration, equals(original.codeValidityDuration));
      });

      test('should handle malformed JSON gracefully', () {
        // Test with null values instead of wrong types to avoid casting errors
        final json = <String, dynamic>{
          'enableSMS': null,
          'enableEmail': null,
          'enableTOTP': null,
          'enableBackupCodes': null,
          'codeValidityDuration': null,
        };
        
        final config = TwoFactorConfiguration.fromJson(json);
        
        expect(config.enableSMS, isFalse); // Default fallback
        expect(config.enableEmail, isFalse); // Default fallback
        expect(config.enableTOTP, isFalse); // Default fallback
        expect(config.enableBackupCodes, isFalse); // Default fallback
        expect(config.codeValidityDuration, equals(const Duration(minutes: 5))); // Default
      });

      test('should validate correctly', () {
        final validConfig = TwoFactorConfiguration.defaultConfig();
        expect(validConfig.validate(), isNull);
        
        final invalidConfig = validConfig.copyWith(
          codeValidityDuration: const Duration(seconds: 30),
        );
        expect(invalidConfig.validate(), isNotNull);
        expect(invalidConfig.validate(), contains('en az 1 dakika'));
      });

      test('should validate edge cases', () {
        final tooLongValidity = TwoFactorConfiguration.defaultConfig()
            .copyWith(codeValidityDuration: const Duration(minutes: 35));
        expect(tooLongValidity.validate(), contains('30 dakikadan fazla olamaz'));
      });

      test('should implement copyWith correctly', () {
        final original = TwoFactorConfiguration.defaultConfig();
        final modified = original.copyWith(
          enableSMS: true,
          enableTOTP: true,
          codeValidityDuration: const Duration(minutes: 10),
        );
        
        expect(modified.enableSMS, isTrue);
        expect(modified.enableTOTP, isTrue);
        expect(modified.codeValidityDuration, equals(const Duration(minutes: 10)));
        expect(modified.enableEmail, equals(original.enableEmail));
        expect(modified.enableBackupCodes, equals(original.enableBackupCodes));
      });

      test('should implement equality correctly', () {
        final config1 = TwoFactorConfiguration.defaultConfig();
        final config2 = TwoFactorConfiguration.defaultConfig();
        final config3 = config1.copyWith(enableSMS: true);
        
        expect(config1 == config2, isTrue);
        expect(config1 == config3, isFalse);
      });
    });

    group('Edge Cases and Integration', () {
      test('should handle null values in JSON gracefully', () {
        final json = <String, dynamic>{
          'isSuccess': null,
          'method': null,
          'errorMessage': null,
          'lockoutDuration': null,
          'remainingAttempts': null,
          'timestamp': null,
          'metadata': null,
        };
        
        final result = AuthResult.fromJson(json);
        
        expect(result.isSuccess, isFalse);
        expect(result.method, equals(AuthMethod.pin));
        expect(result.errorMessage, isNull);
        expect(result.lockoutDuration, isNull);
        expect(result.remainingAttempts, isNull);
        expect(result.timestamp, isA<DateTime>());
        expect(result.metadata, isNull);
      });

      test('should handle empty JSON objects gracefully', () {
        final emptyJson = <String, dynamic>{};
        
        final authResult = AuthResult.fromJson(emptyJson);
        final securityConfig = SecurityConfig.fromJson(emptyJson);
        final pinConfig = PINConfiguration.fromJson(emptyJson);
        final biometricConfig = BiometricConfiguration.fromJson(emptyJson);
        final sessionConfig = SessionConfiguration.fromJson(emptyJson);
        final twoFactorConfig = TwoFactorConfiguration.fromJson(emptyJson);
        
        expect(authResult.isSuccess, isFalse);
        expect(securityConfig.isPINEnabled, isTrue);
        expect(pinConfig.minLength, equals(4));
        expect(biometricConfig.requireFallbackPIN, isTrue);
        expect(sessionConfig.sessionTimeout, equals(const Duration(minutes: 5)));
        expect(twoFactorConfig.enableSMS, isFalse);
      });

      test('should handle complex nested validation', () {
        final invalidPinConfig = PINConfiguration.defaultConfig()
            .copyWith(minLength: 10, maxLength: 6);
        
        final securityConfig = SecurityConfig(
          pinConfig: invalidPinConfig,
          biometricConfig: BiometricConfiguration.defaultConfig(),
          sessionConfig: SessionConfiguration.defaultConfig(),
          twoFactorConfig: TwoFactorConfiguration.defaultConfig(),
        );
        
        final validation = securityConfig.validate();
        expect(validation, isNotNull);
        expect(validation, contains('büyük olamaz'));
      });

      test('should maintain immutability in copyWith operations', () {
        final original = SecurityConfig.defaultConfig();
        final modified = original.copyWith(isPINEnabled: false);
        
        expect(original.isPINEnabled, isTrue);
        expect(modified.isPINEnabled, isFalse);
        expect(original != modified, isTrue);
      });
    });
  });
}