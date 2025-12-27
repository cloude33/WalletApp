import 'package:flutter_test/flutter_test.dart';
import 'package:money/services/auth/two_factor_service.dart';
import 'package:money/models/security/two_factor_models.dart';
import 'package:money/utils/security/totp_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('TwoFactorService', () {
    late TwoFactorService twoFactorService;

    setUp(() {
      twoFactorService = TwoFactorService();
      twoFactorService.resetForTesting();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        await twoFactorService.initialize();
        expect(await twoFactorService.isTwoFactorEnabled(), false);
      });

      test('should return default configuration when not configured', () async {
        await twoFactorService.initialize();
        final config = await twoFactorService.getConfiguration();
        
        expect(config.isEnabled, false);
        expect(config.isSMSEnabled, false);
        expect(config.isEmailEnabled, false);
        expect(config.isTOTPEnabled, false);
      });
    });

    group('SMS Verification', () {
      test('should enable SMS verification with valid phone number', () async {
        await twoFactorService.initialize();
        
        final result = await twoFactorService.enableSMSVerification('+1234567890');
        
        expect(result.isSuccess, true);
        expect(result.method, TwoFactorMethod.sms);
        expect(result.backupCodes, isNotNull);
        expect(result.backupCodes!.length, 10);
        
        final config = await twoFactorService.getConfiguration();
        expect(config.isEnabled, true);
        expect(config.isSMSEnabled, true);
        expect(config.phoneNumber, '+1234567890');
      });

      test('should fail to enable SMS verification with invalid phone number', () async {
        await twoFactorService.initialize();
        
        final result = await twoFactorService.enableSMSVerification('invalid');
        
        expect(result.isSuccess, false);
        expect(result.method, TwoFactorMethod.sms);
        expect(result.errorMessage, contains('Geçersiz telefon numarası'));
      });

      test('should send SMS code when SMS is enabled', () async {
        await twoFactorService.initialize();
        await twoFactorService.enableSMSVerification('+1234567890');
        
        final success = await twoFactorService.sendSMSCode();
        expect(success, true);
      });

      test('should fail to send SMS code when SMS is not enabled', () async {
        await twoFactorService.initialize();
        
        final success = await twoFactorService.sendSMSCode();
        expect(success, false);
      });
    });

    group('Email Verification', () {
      test('should enable email verification with valid email', () async {
        await twoFactorService.initialize();
        
        final result = await twoFactorService.enableEmailVerification('test@example.com');
        
        expect(result.isSuccess, true);
        expect(result.method, TwoFactorMethod.email);
        expect(result.backupCodes, isNotNull);
        
        final config = await twoFactorService.getConfiguration();
        expect(config.isEnabled, true);
        expect(config.isEmailEnabled, true);
        expect(config.emailAddress, 'test@example.com');
      });

      test('should fail to enable email verification with invalid email', () async {
        await twoFactorService.initialize();
        
        final result = await twoFactorService.enableEmailVerification('invalid-email');
        
        expect(result.isSuccess, false);
        expect(result.method, TwoFactorMethod.email);
        expect(result.errorMessage, contains('Geçersiz e-posta adresi'));
      });

      test('should send email code when email is enabled', () async {
        await twoFactorService.initialize();
        await twoFactorService.enableEmailVerification('test@example.com');
        
        final success = await twoFactorService.sendEmailCode();
        expect(success, true);
      });
    });

    group('TOTP Verification', () {
      test('should enable TOTP verification with valid account name', () async {
        await twoFactorService.initialize();
        
        final result = await twoFactorService.enableTOTPVerification('test@example.com');
        
        expect(result.isSuccess, true);
        expect(result.method, TwoFactorMethod.totp);
        expect(result.totpSecret, isNotNull);
        expect(result.qrCodeUrl, isNotNull);
        expect(result.qrCodeUrl, contains('otpauth://totp/'));
        expect(result.backupCodes, isNotNull);
        
        final config = await twoFactorService.getConfiguration();
        expect(config.isEnabled, true);
        expect(config.isTOTPEnabled, true);
        expect(config.totpSecret, isNotNull);
        expect(config.totpAccountName, 'test@example.com');
      });

      test('should fail to enable TOTP verification with empty account name', () async {
        await twoFactorService.initialize();
        
        final result = await twoFactorService.enableTOTPVerification('');
        
        expect(result.isSuccess, false);
        expect(result.method, TwoFactorMethod.totp);
        expect(result.errorMessage, contains('Hesap adı boş olamaz'));
      });

      test('should verify valid TOTP code', () async {
        await twoFactorService.initialize();
        
        // Enable TOTP
        final setupResult = await twoFactorService.enableTOTPVerification('test@example.com');
        expect(setupResult.isSuccess, true);
        
        // Generate valid TOTP code
        final totpCode = TOTPHelper.generateTOTP(setupResult.totpSecret!);
        
        // Verify the code
        final request = TwoFactorVerificationRequest.totp(totpCode);
        final result = await twoFactorService.verifyCode(request);
        
        expect(result.isSuccess, true);
        expect(result.method, TwoFactorMethod.totp);
      });

      test('should reject invalid TOTP code', () async {
        await twoFactorService.initialize();
        
        // Enable TOTP
        final setupResult = await twoFactorService.enableTOTPVerification('test@example.com');
        expect(setupResult.isSuccess, true);
        
        // Try invalid code
        final request = TwoFactorVerificationRequest.totp('123456');
        final result = await twoFactorService.verifyCode(request);
        
        expect(result.isSuccess, false);
        expect(result.method, TwoFactorMethod.totp);
        expect(result.errorMessage, contains('Geçersiz authenticator kodu'));
      });
    });

    group('Backup Codes', () {
      test('should generate backup codes when enabling first method', () async {
        await twoFactorService.initialize();
        
        final result = await twoFactorService.enableSMSVerification('+1234567890');
        
        expect(result.backupCodes, isNotNull);
        expect(result.backupCodes!.length, 10);
        
        // Verify codes are stored
        final unusedCodes = await twoFactorService.getUnusedBackupCodes();
        expect(unusedCodes.length, 10);
      });

      test('should verify valid backup code', () async {
        await twoFactorService.initialize();
        
        // Enable SMS to get backup codes
        final setupResult = await twoFactorService.enableSMSVerification('+1234567890');
        final backupCode = setupResult.backupCodes!.first;
        
        // Verify backup code
        final request = TwoFactorVerificationRequest.backupCode(backupCode);
        final result = await twoFactorService.verifyCode(request);
        
        expect(result.isSuccess, true);
        expect(result.method, TwoFactorMethod.backupCode);
        
        // Code should be marked as used
        final unusedCodes = await twoFactorService.getUnusedBackupCodes();
        expect(unusedCodes.length, 9);
        expect(unusedCodes.contains(backupCode), false);
      });

      test('should reject used backup code', () async {
        await twoFactorService.initialize();
        
        // Enable SMS to get backup codes
        final setupResult = await twoFactorService.enableSMSVerification('+1234567890');
        final backupCode = setupResult.backupCodes!.first;
        
        // Use the backup code once
        final request1 = TwoFactorVerificationRequest.backupCode(backupCode);
        final result1 = await twoFactorService.verifyCode(request1);
        expect(result1.isSuccess, true);
        
        // Try to use the same code again
        final request2 = TwoFactorVerificationRequest.backupCode(backupCode);
        final result2 = await twoFactorService.verifyCode(request2);
        
        expect(result2.isSuccess, false);
        expect(result2.errorMessage, contains('daha önce kullanılmış'));
      });

      test('should generate new backup codes', () async {
        await twoFactorService.initialize();
        await twoFactorService.enableSMSVerification('+1234567890');
        
        final originalCodes = await twoFactorService.getUnusedBackupCodes();
        expect(originalCodes.length, 10);
        
        final newCodes = await twoFactorService.generateNewBackupCodes();
        expect(newCodes.length, 10);
        
        // New codes should be different
        expect(newCodes, isNot(equals(originalCodes)));
        
        // All codes should be unused
        final unusedCodes = await twoFactorService.getUnusedBackupCodes();
        expect(unusedCodes.length, 10);
      });
    });

    group('Available Methods', () {
      test('should return empty list when no methods are enabled', () async {
        await twoFactorService.initialize();
        
        final methods = await twoFactorService.getAvailableMethods();
        expect(methods, isEmpty);
      });

      test('should return enabled methods', () async {
        await twoFactorService.initialize();
        
        await twoFactorService.enableSMSVerification('+1234567890');
        await twoFactorService.enableEmailVerification('test@example.com');
        
        final methods = await twoFactorService.getAvailableMethods();
        
        expect(methods.contains(TwoFactorMethod.sms), true);
        expect(methods.contains(TwoFactorMethod.email), true);
        expect(methods.contains(TwoFactorMethod.backupCode), true);
        expect(methods.contains(TwoFactorMethod.totp), false);
      });
    });

    group('Disable Methods', () {
      test('should disable specific method', () async {
        await twoFactorService.initialize();
        
        await twoFactorService.enableSMSVerification('+1234567890');
        await twoFactorService.enableEmailVerification('test@example.com');
        
        // Verify both methods are enabled
        final config1 = await twoFactorService.getConfiguration();
        expect(config1.isSMSEnabled, true);
        expect(config1.isEmailEnabled, true);
        expect(config1.isEnabled, true);
        
        // Disable SMS
        final success = await twoFactorService.disableMethod(TwoFactorMethod.sms);
        expect(success, true);
        
        // Verify SMS is disabled but email is still enabled
        final config2 = await twoFactorService.getConfiguration();
        expect(config2.isSMSEnabled, false);
        expect(config2.isEmailEnabled, true);
        expect(config2.isEnabled, true); // Still enabled because email is active
      });

      test('should disable 2FA completely when last method is disabled', () async {
        await twoFactorService.initialize();
        
        await twoFactorService.enableSMSVerification('+1234567890');
        
        // Disable the only method
        final success = await twoFactorService.disableMethod(TwoFactorMethod.sms);
        expect(success, true);
        
        // 2FA should be completely disabled
        final config = await twoFactorService.getConfiguration();
        expect(config.isEnabled, false);
        expect(config.isSMSEnabled, false);
      });

      test('should disable all methods', () async {
        await twoFactorService.initialize();
        
        await twoFactorService.enableSMSVerification('+1234567890');
        await twoFactorService.enableEmailVerification('test@example.com');
        await twoFactorService.enableTOTPVerification('test@example.com');
        
        final success = await twoFactorService.disableAllMethods();
        expect(success, true);
        
        final config = await twoFactorService.getConfiguration();
        expect(config.isEnabled, false);
        expect(config.isSMSEnabled, false);
        expect(config.isEmailEnabled, false);
        expect(config.isTOTPEnabled, false);
        
        final methods = await twoFactorService.getAvailableMethods();
        expect(methods, isEmpty);
      });
    });

    group('Sensitive Operations', () {
      test('should require 2FA for sensitive operations when enabled', () async {
        await twoFactorService.initialize();
        
        // Initially not required
        expect(await twoFactorService.isRequiredForSensitiveOperations(), false);
        
        // Enable 2FA
        await twoFactorService.enableSMSVerification('+1234567890');
        
        // Now required
        expect(await twoFactorService.isRequiredForSensitiveOperations(), true);
      });
    });
  });
}