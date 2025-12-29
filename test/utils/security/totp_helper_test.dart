import 'package:flutter_test/flutter_test.dart';
import 'package:money/utils/security/totp_helper.dart';

void main() {
  group('TOTPHelper', () {
    group('Secret Generation', () {
      test('should generate valid base32 secret', () {
        final secret = TOTPHelper.generateSecret();
        
        expect(secret, isNotEmpty);
        expect(secret.length, greaterThan(10));
        expect(TOTPHelper.isValidSecret(secret), true);
      });

      test('should generate different secrets each time', () {
        final secret1 = TOTPHelper.generateSecret();
        final secret2 = TOTPHelper.generateSecret();
        
        expect(secret1, isNot(equals(secret2)));
      });

      test('should generate secret with custom length', () {
        final secret = TOTPHelper.generateSecret(length: 32);
        
        expect(secret, isNotEmpty);
        expect(TOTPHelper.isValidSecret(secret), true);
      });
    });

    group('TOTP Generation', () {
      test('should generate 6-digit TOTP code', () {
        const secret = 'JBSWY3DPEHPK3PXP';
        final code = TOTPHelper.generateTOTP(secret);
        
        expect(code, hasLength(6));
        expect(int.tryParse(code), isNotNull);
      });

      test('should generate consistent code for same time', () {
        const secret = 'JBSWY3DPEHPK3PXP';
        final timestamp = DateTime(2023, 1, 1, 12, 0, 0);
        
        final code1 = TOTPHelper.generateTOTP(secret, timestamp: timestamp);
        final code2 = TOTPHelper.generateTOTP(secret, timestamp: timestamp);
        
        expect(code1, equals(code2));
      });

      test('should generate different codes for different times', () {
        const secret = 'JBSWY3DPEHPK3PXP';
        final timestamp1 = DateTime(2023, 1, 1, 12, 0, 0);
        final timestamp2 = DateTime(2023, 1, 1, 12, 1, 0);
        
        final code1 = TOTPHelper.generateTOTP(secret, timestamp: timestamp1);
        final code2 = TOTPHelper.generateTOTP(secret, timestamp: timestamp2);
        
        expect(code1, isNot(equals(code2)));
      });

      test('should generate custom length codes', () {
        const secret = 'JBSWY3DPEHPK3PXP';
        final code = TOTPHelper.generateTOTP(secret, codeLength: 8);
        
        expect(code, hasLength(8));
        expect(int.tryParse(code), isNotNull);
      });
    });

    group('TOTP Verification', () {
      test('should verify valid TOTP code', () {
        const secret = 'JBSWY3DPEHPK3PXP';
        final timestamp = DateTime(2023, 1, 1, 12, 0, 0);
        
        final code = TOTPHelper.generateTOTP(secret, timestamp: timestamp);
        final isValid = TOTPHelper.verifyTOTP(secret, code, timestamp: timestamp);
        
        expect(isValid, true);
      });

      test('should reject invalid TOTP code', () {
        const secret = 'JBSWY3DPEHPK3PXP';
        const invalidCode = '123456';
        
        final isValid = TOTPHelper.verifyTOTP(secret, invalidCode);
        
        expect(isValid, false);
      });

      test('should reject code with wrong length', () {
        const secret = 'JBSWY3DPEHPK3PXP';
        const shortCode = '123';
        
        final isValid = TOTPHelper.verifyTOTP(secret, shortCode);
        
        expect(isValid, false);
      });

      test('should verify code within time window tolerance', () {
        const secret = 'JBSWY3DPEHPK3PXP';
        final baseTime = DateTime(2023, 1, 1, 12, 0, 0);
        
        // Generate code for base time
        final code = TOTPHelper.generateTOTP(secret, timestamp: baseTime);
        
        // Verify code 29 seconds later (within same 30-second window)
        final verifyTime = baseTime.add(const Duration(seconds: 29));
        final isValid = TOTPHelper.verifyTOTP(secret, code, timestamp: verifyTime);
        
        expect(isValid, true);
      });

      test('should verify code with window tolerance', () {
        const secret = 'JBSWY3DPEHPK3PXP';
        final baseTime = DateTime(2023, 1, 1, 12, 0, 0);
        
        // Generate code for base time
        final code = TOTPHelper.generateTOTP(secret, timestamp: baseTime);
        
        // Verify code 31 seconds later (next window, but within tolerance)
        final verifyTime = baseTime.add(const Duration(seconds: 31));
        final isValid = TOTPHelper.verifyTOTP(
          secret, 
          code, 
          timestamp: verifyTime,
          windowTolerance: 1,
        );
        
        expect(isValid, true);
      });
    });

    group('QR Code URL Generation', () {
      test('should generate valid otpauth URL', () {
        const secret = 'JBSWY3DPEHPK3PXP';
        const accountName = 'test@example.com';
        const issuer = 'Test App';
        
        final url = TOTPHelper.generateQRCodeUrl(secret, accountName, issuer);
        
        expect(url, startsWith('otpauth://totp/'));
        expect(url, contains('secret=$secret'));
        expect(url, contains('issuer=Test%20App'));
        expect(url, contains('Test%20App:test%40example.com'));
      });

      test('should include custom parameters in URL', () {
        const secret = 'JBSWY3DPEHPK3PXP';
        const accountName = 'test@example.com';
        const issuer = 'Test App';
        
        final url = TOTPHelper.generateQRCodeUrl(
          secret,
          accountName,
          issuer,
          algorithm: 'SHA256',
          digits: 8,
          period: 60,
        );
        
        expect(url, contains('algorithm=SHA256'));
        expect(url, contains('digits=8'));
        expect(url, contains('period=60'));
      });
    });

    group('Time Utilities', () {
      test('should calculate remaining time in window', () {
        final timestamp = DateTime(2023, 1, 1, 12, 0, 15); // 15 seconds into window
        final remaining = TOTPHelper.getRemainingTime(timestamp: timestamp);
        
        expect(remaining, equals(15)); // 30 - 15 = 15 seconds remaining
      });

      test('should handle edge case at window boundary', () {
        final timestamp = DateTime(2023, 1, 1, 12, 0, 0); // Exactly at window start
        final remaining = TOTPHelper.getRemainingTime(timestamp: timestamp);
        
        expect(remaining, equals(30)); // Full window remaining
      });
    });

    group('Secret Validation', () {
      test('should validate correct base32 secret', () {
        const validSecret = 'JBSWY3DPEHPK3PXP';
        expect(TOTPHelper.isValidSecret(validSecret), true);
      });

      test('should reject empty secret', () {
        expect(TOTPHelper.isValidSecret(''), false);
      });

      test('should reject secret with invalid characters', () {
        const invalidSecret = 'INVALID1SECRET9';
        expect(TOTPHelper.isValidSecret(invalidSecret), false);
      });

      test('should accept secret with padding', () {
        const secretWithPadding = 'JBSWY3DPEHPK3PXP====';
        expect(TOTPHelper.isValidSecret(secretWithPadding), true);
      });

      test('should accept lowercase secret', () {
        const lowercaseSecret = 'jbswy3dpehpk3pxp';
        expect(TOTPHelper.isValidSecret(lowercaseSecret), true);
      });
    });

    group('Backup Codes', () {
      test('should generate backup codes', () {
        final codes = TOTPHelper.generateBackupCodes();
        
        expect(codes, hasLength(10));
        for (final code in codes) {
          expect(code, hasLength(8));
          expect(int.tryParse(code), isNotNull);
        }
      });

      test('should generate unique backup codes', () {
        final codes = TOTPHelper.generateBackupCodes();
        final uniqueCodes = codes.toSet();
        
        expect(uniqueCodes.length, equals(codes.length));
      });

      test('should generate custom number of backup codes', () {
        final codes = TOTPHelper.generateBackupCodes(count: 5);
        
        expect(codes, hasLength(5));
      });

      test('should generate custom length backup codes', () {
        final codes = TOTPHelper.generateBackupCodes(length: 12);
        
        expect(codes, hasLength(10));
        for (final code in codes) {
          expect(code, hasLength(12));
        }
      });

      test('should format backup codes correctly', () {
        const code = '12345678';
        final formatted = TOTPHelper.formatBackupCode(code);
        
        expect(formatted, equals('1234-5678'));
      });

      test('should handle short codes in formatting', () {
        const shortCode = '123';
        final formatted = TOTPHelper.formatBackupCode(shortCode);
        
        expect(formatted, equals('123'));
      });

      test('should format longer codes correctly', () {
        const longCode = '123456789012';
        final formatted = TOTPHelper.formatBackupCode(longCode);
        
        expect(formatted, equals('1234-5678-9012'));
      });
    });

    group('Edge Cases', () {
      test('should handle very long secrets', () {
        final longSecret = TOTPHelper.generateSecret(length: 64);
        expect(TOTPHelper.isValidSecret(longSecret), true);
        
        final code = TOTPHelper.generateTOTP(longSecret);
        expect(code, hasLength(6));
        expect(int.tryParse(code), isNotNull);
      });

      test('should handle minimum length secrets', () {
        final shortSecret = TOTPHelper.generateSecret(length: 10);
        expect(TOTPHelper.isValidSecret(shortSecret), true);
        
        final code = TOTPHelper.generateTOTP(shortSecret);
        expect(code, hasLength(6));
        expect(int.tryParse(code), isNotNull);
      });

      test('should handle custom time steps', () {
        const secret = 'JBSWY3DPEHPK3PXP';
        final timestamp = DateTime(2023, 1, 1, 12, 0, 0);
        
        final code60 = TOTPHelper.generateTOTP(
          secret, 
          timeStep: 60, 
          timestamp: timestamp,
        );
        final code30 = TOTPHelper.generateTOTP(
          secret, 
          timeStep: 30, 
          timestamp: timestamp,
        );
        
        // Different time steps should produce different codes
        expect(code60, isNot(equals(code30)));
      });
    });
  });
}