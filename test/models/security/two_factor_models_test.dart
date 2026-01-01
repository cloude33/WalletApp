import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/security/two_factor_models.dart';

void main() {
  group('TwoFactorConfig', () {
    test('should create default configuration', () {
      final config = TwoFactorConfig.defaultConfig();
      
      expect(config.isEnabled, false);
      expect(config.isSMSEnabled, false);
      expect(config.isEmailEnabled, false);
      expect(config.isTOTPEnabled, false);
      expect(config.backupCodes, isEmpty);
      expect(config.usedBackupCodes, isEmpty);
    });

    test('should serialize to and from JSON', () {
      final originalConfig = TwoFactorConfig(
        isEnabled: true,
        isSMSEnabled: true,
        isEmailEnabled: false,
        isTOTPEnabled: true,
        phoneNumber: '+1234567890',
        emailAddress: null,
        totpSecret: 'JBSWY3DPEHPK3PXP',
        totpIssuer: 'Test App',
        totpAccountName: 'test@example.com',
        backupCodes: ['12345678', '87654321'],
        usedBackupCodes: ['12345678'],
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
      );

      final json = originalConfig.toJson();
      final deserializedConfig = TwoFactorConfig.fromJson(json);

      expect(deserializedConfig.isEnabled, originalConfig.isEnabled);
      expect(deserializedConfig.isSMSEnabled, originalConfig.isSMSEnabled);
      expect(deserializedConfig.isEmailEnabled, originalConfig.isEmailEnabled);
      expect(deserializedConfig.isTOTPEnabled, originalConfig.isTOTPEnabled);
      expect(deserializedConfig.phoneNumber, originalConfig.phoneNumber);
      expect(deserializedConfig.emailAddress, originalConfig.emailAddress);
      expect(deserializedConfig.totpSecret, originalConfig.totpSecret);
      expect(deserializedConfig.totpIssuer, originalConfig.totpIssuer);
      expect(deserializedConfig.totpAccountName, originalConfig.totpAccountName);
      expect(deserializedConfig.backupCodes, originalConfig.backupCodes);
      expect(deserializedConfig.usedBackupCodes, originalConfig.usedBackupCodes);
      expect(deserializedConfig.createdAt, originalConfig.createdAt);
      expect(deserializedConfig.updatedAt, originalConfig.updatedAt);
    });

    test('should create copy with updated fields', () {
      final originalConfig = TwoFactorConfig.defaultConfig();
      
      final updatedConfig = originalConfig.copyWith(
        isEnabled: true,
        isSMSEnabled: true,
        phoneNumber: '+1234567890',
      );

      expect(updatedConfig.isEnabled, true);
      expect(updatedConfig.isSMSEnabled, true);
      expect(updatedConfig.phoneNumber, '+1234567890');
      expect(updatedConfig.isEmailEnabled, originalConfig.isEmailEnabled);
      expect(updatedConfig.isTOTPEnabled, originalConfig.isTOTPEnabled);
    });

    test('should update timestamp when copying', () async {
      final originalConfig = TwoFactorConfig.defaultConfig();
      final originalUpdatedAt = originalConfig.updatedAt;
      
      // Wait a bit to ensure different timestamp
      await Future.delayed(const Duration(milliseconds: 1));
      
      final updatedConfig = originalConfig.copyWith(isEnabled: true);
      
      expect(updatedConfig.updatedAt.isAfter(originalUpdatedAt), true);
    });

    test('should implement equality correctly', () {
      final config1 = TwoFactorConfig(
        isEnabled: true,
        isSMSEnabled: true,
        phoneNumber: '+1234567890',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
      );

      final config2 = TwoFactorConfig(
        isEnabled: true,
        isSMSEnabled: true,
        phoneNumber: '+1234567890',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 3), // Different timestamp
      );

      final config3 = TwoFactorConfig(
        isEnabled: false, // Different value
        isSMSEnabled: true,
        phoneNumber: '+1234567890',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
      );

      expect(config1 == config2, true); // Timestamps don't affect equality
      expect(config1 == config3, false); // Different isEnabled value
    });

    test('should have consistent hashCode', () {
      final config1 = TwoFactorConfig(
        isEnabled: true,
        isSMSEnabled: true,
        phoneNumber: '+1234567890',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
      );

      final config2 = TwoFactorConfig(
        isEnabled: true,
        isSMSEnabled: true,
        phoneNumber: '+1234567890',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 3), // Different timestamp
      );

      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('should have meaningful toString', () {
      final config = TwoFactorConfig(
        isEnabled: true,
        isSMSEnabled: true,
        isEmailEnabled: false,
        isTOTPEnabled: true,
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
      );

      final stringRepresentation = config.toString();
      
      expect(stringRepresentation, contains('TwoFactorConfig'));
      expect(stringRepresentation, contains('isEnabled: true'));
      expect(stringRepresentation, contains('isSMSEnabled: true'));
      expect(stringRepresentation, contains('isEmailEnabled: false'));
      expect(stringRepresentation, contains('isTOTPEnabled: true'));
    });
  });

  group('TwoFactorVerificationResult', () {
    test('should create successful result', () {
      final result = TwoFactorVerificationResult.success(TwoFactorMethod.sms);
      
      expect(result.isSuccess, true);
      expect(result.method, TwoFactorMethod.sms);
      expect(result.errorMessage, isNull);
      expect(result.remainingAttempts, isNull);
      expect(result.lockoutDuration, isNull);
    });

    test('should create failed result', () {
      final result = TwoFactorVerificationResult.failure(
        TwoFactorMethod.totp,
        'Invalid code',
        remainingAttempts: 2,
        lockoutDuration: const Duration(minutes: 5),
      );
      
      expect(result.isSuccess, false);
      expect(result.method, TwoFactorMethod.totp);
      expect(result.errorMessage, 'Invalid code');
      expect(result.remainingAttempts, 2);
      expect(result.lockoutDuration, const Duration(minutes: 5));
    });

    test('should have meaningful toString', () {
      final result = TwoFactorVerificationResult.failure(
        TwoFactorMethod.email,
        'Code expired',
      );
      
      final stringRepresentation = result.toString();
      
      expect(stringRepresentation, contains('TwoFactorVerificationResult'));
      expect(stringRepresentation, contains('isSuccess: false'));
      expect(stringRepresentation, contains('method: TwoFactorMethod.email'));
      expect(stringRepresentation, contains('errorMessage: Code expired'));
    });
  });

  group('TwoFactorMethod', () {
    test('should have correct display names', () {
      expect(TwoFactorMethod.sms.displayName, 'SMS Doğrulama');
      expect(TwoFactorMethod.email.displayName, 'E-posta Doğrulama');
      expect(TwoFactorMethod.totp.displayName, 'Authenticator Uygulaması');
      expect(TwoFactorMethod.backupCode.displayName, 'Yedek Kod');
    });

    test('should have correct icon names', () {
      expect(TwoFactorMethod.sms.iconName, 'sms');
      expect(TwoFactorMethod.email.iconName, 'email');
      expect(TwoFactorMethod.totp.iconName, 'security');
      expect(TwoFactorMethod.backupCode.iconName, 'backup');
    });
  });

  group('TwoFactorSetupResult', () {
    test('should create successful setup result', () {
      final result = TwoFactorSetupResult.success(
        TwoFactorMethod.totp,
        totpSecret: 'JBSWY3DPEHPK3PXP',
        qrCodeUrl: 'otpauth://totp/Test:user@example.com?secret=JBSWY3DPEHPK3PXP',
        backupCodes: ['12345678', '87654321'],
      );
      
      expect(result.isSuccess, true);
      expect(result.method, TwoFactorMethod.totp);
      expect(result.totpSecret, 'JBSWY3DPEHPK3PXP');
      expect(result.qrCodeUrl, contains('otpauth://totp/'));
      expect(result.backupCodes, hasLength(2));
      expect(result.errorMessage, isNull);
    });

    test('should create failed setup result', () {
      final result = TwoFactorSetupResult.failure(
        TwoFactorMethod.sms,
        'Invalid phone number',
      );
      
      expect(result.isSuccess, false);
      expect(result.method, TwoFactorMethod.sms);
      expect(result.errorMessage, 'Invalid phone number');
      expect(result.totpSecret, isNull);
      expect(result.qrCodeUrl, isNull);
      expect(result.backupCodes, isNull);
    });

    test('should have meaningful toString', () {
      final result = TwoFactorSetupResult.failure(
        TwoFactorMethod.email,
        'Invalid email format',
      );
      
      final stringRepresentation = result.toString();
      
      expect(stringRepresentation, contains('TwoFactorSetupResult'));
      expect(stringRepresentation, contains('isSuccess: false'));
      expect(stringRepresentation, contains('method: TwoFactorMethod.email'));
      expect(stringRepresentation, contains('errorMessage: Invalid email format'));
    });
  });

  group('TwoFactorVerificationRequest', () {
    test('should create SMS verification request', () {
      final request = TwoFactorVerificationRequest.sms('123456', '+1234567890');
      
      expect(request.method, TwoFactorMethod.sms);
      expect(request.code, '123456');
      expect(request.phoneNumber, '+1234567890');
      expect(request.emailAddress, isNull);
      expect(request.timestamp, isNotNull);
    });

    test('should create email verification request', () {
      final request = TwoFactorVerificationRequest.email('654321', 'test@example.com');
      
      expect(request.method, TwoFactorMethod.email);
      expect(request.code, '654321');
      expect(request.emailAddress, 'test@example.com');
      expect(request.phoneNumber, isNull);
      expect(request.timestamp, isNotNull);
    });

    test('should create TOTP verification request', () {
      final request = TwoFactorVerificationRequest.totp('789012');
      
      expect(request.method, TwoFactorMethod.totp);
      expect(request.code, '789012');
      expect(request.phoneNumber, isNull);
      expect(request.emailAddress, isNull);
      expect(request.timestamp, isNotNull);
    });

    test('should create backup code verification request', () {
      final request = TwoFactorVerificationRequest.backupCode('12345678');
      
      expect(request.method, TwoFactorMethod.backupCode);
      expect(request.code, '12345678');
      expect(request.phoneNumber, isNull);
      expect(request.emailAddress, isNull);
      expect(request.timestamp, isNotNull);
    });

    test('should mask code in toString', () {
      final request = TwoFactorVerificationRequest.totp('123456');
      final stringRepresentation = request.toString();
      
      expect(stringRepresentation, contains('TwoFactorVerificationRequest'));
      expect(stringRepresentation, contains('method: TwoFactorMethod.totp'));
      expect(stringRepresentation, contains('code: ******'));
      expect(stringRepresentation, isNot(contains('123456')));
    });
  });
}