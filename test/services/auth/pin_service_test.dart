import 'package:flutter_test/flutter_test.dart';
import 'package:money/services/auth/pin_service.dart';
import 'package:money/models/security/security_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('PINService', () {
    late PINService pinService;

    setUp(() {
      pinService = PINService();
      pinService.resetForTesting();
    });

    tearDown(() {
      pinService.resetForTesting();
    });

    group('PIN Setup', () {
      test('should successfully setup a valid PIN', () async {
        final result = await pinService.setupPIN('1234');
        
        expect(result.isSuccess, isTrue);
        expect(result.method, equals(AuthMethod.pin));
        expect(await pinService.isPINSet(), isTrue);
      });

      test('should reject PIN shorter than 4 digits', () async {
        final result = await pinService.setupPIN('123');
        
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('en az 4 haneli'));
        expect(await pinService.isPINSet(), isFalse);
      });

      test('should reject PIN longer than 6 digits', () async {
        final result = await pinService.setupPIN('1234567');
        
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('en fazla 6 haneli'));
        expect(await pinService.isPINSet(), isFalse);
      });

      test('should reject non-numeric PIN', () async {
        final result = await pinService.setupPIN('12a4');
        
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('sadece rakamlardan'));
        expect(await pinService.isPINSet(), isFalse);
      });

      test('should reject empty PIN', () async {
        final result = await pinService.setupPIN('');
        
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('boş olamaz'));
        expect(await pinService.isPINSet(), isFalse);
      });

      test('should not allow setting PIN twice', () async {
        await pinService.setupPIN('1234');
        final result = await pinService.setupPIN('5678');
        
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('zaten ayarlanmış'));
      });
    });

    group('PIN Verification', () {
      setUp(() async {
        await pinService.setupPIN('1234');
      });

      test('should successfully verify correct PIN', () async {
        final result = await pinService.verifyPIN('1234');
        
        expect(result.isSuccess, isTrue);
        expect(result.method, equals(AuthMethod.pin));
      });

      test('should reject incorrect PIN', () async {
        final result = await pinService.verifyPIN('5678');
        
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Yanlış PIN'));
        expect(result.remainingAttempts, equals(9));
      });

      test('should increment failed attempts on wrong PIN', () async {
        await pinService.verifyPIN('5678');
        expect(await pinService.getFailedAttempts(), equals(1));
        
        await pinService.verifyPIN('9999');
        expect(await pinService.getFailedAttempts(), equals(2));
      });

      test('should reset failed attempts on successful verification', () async {
        await pinService.verifyPIN('5678');
        await pinService.verifyPIN('9999');
        expect(await pinService.getFailedAttempts(), equals(2));
        
        await pinService.verifyPIN('1234');
        expect(await pinService.getFailedAttempts(), equals(0));
      });

      test('should lock account after 3 failed attempts', () async {
        await pinService.verifyPIN('5678');
        await pinService.verifyPIN('9999');
        final result = await pinService.verifyPIN('0000');
        
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('30 saniye kilitlendi'));
        expect(result.lockoutDuration, isNotNull);
        expect(await pinService.isLocked(), isTrue);
      });

      test('should lock account for 5 minutes after 5 failed attempts', () async {
        // First 3 attempts to trigger first lockout
        await pinService.verifyPIN('5678');
        await pinService.verifyPIN('9999');
        await pinService.verifyPIN('0000');
        
        // Clear lockout manually for testing
        await pinService.clearAllPINData();
        await pinService.setupPIN('1234');
        
        // 5 more attempts
        for (int i = 0; i < 5; i++) {
          await pinService.verifyPIN('wrong');
        }
        
        expect(await pinService.isLocked(), isTrue);
        final remainingTime = await pinService.getRemainingLockoutTime();
        expect(remainingTime, isNotNull);
        expect(remainingTime!.inMinutes, greaterThanOrEqualTo(4));
      });

      test('should reject verification when account is locked', () async {
        // Lock the account
        await pinService.verifyPIN('5678');
        await pinService.verifyPIN('9999');
        await pinService.verifyPIN('0000');
        
        // Try to verify with correct PIN while locked
        final result = await pinService.verifyPIN('1234');
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('kilitli'));
      });
    });

    group('PIN Change', () {
      setUp(() async {
        await pinService.setupPIN('1234');
      });

      test('should successfully change PIN with correct old PIN', () async {
        final result = await pinService.changePIN('1234', '5678');
        
        expect(result.isSuccess, isTrue);
        expect(result.method, equals(AuthMethod.pin));
        
        // Verify new PIN works
        final verifyResult = await pinService.verifyPIN('5678');
        expect(verifyResult.isSuccess, isTrue);
        
        // Verify old PIN doesn't work
        final oldPinResult = await pinService.verifyPIN('1234');
        expect(oldPinResult.isSuccess, isFalse);
      });

      test('should reject change with incorrect old PIN', () async {
        final result = await pinService.changePIN('5678', '9999');
        
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Mevcut PIN yanlış'));
        
        // Verify original PIN still works
        final verifyResult = await pinService.verifyPIN('1234');
        expect(verifyResult.isSuccess, isTrue);
      });

      test('should reject change when new PIN is same as old PIN', () async {
        final result = await pinService.changePIN('1234', '1234');
        
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('aynı olamaz'));
      });

      test('should validate new PIN format', () async {
        final result = await pinService.changePIN('1234', '12');
        
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('en az 4 haneli'));
      });
    });

    group('PIN Reset', () {
      setUp(() async {
        await pinService.setupPIN('1234');
      });

      test('should successfully reset PIN', () async {
        final result = await pinService.resetPIN();
        
        expect(result.isSuccess, isTrue);
        expect(result.method, equals(AuthMethod.pin));
        expect(await pinService.isPINSet(), isFalse);
      });

      test('should clear failed attempts on reset', () async {
        await pinService.verifyPIN('5678');
        expect(await pinService.getFailedAttempts(), equals(1));
        
        await pinService.resetPIN();
        expect(await pinService.getFailedAttempts(), equals(0));
      });
    });

    group('PIN Strength', () {
      test('should return 0 for empty PIN', () {
        final strength = pinService.checkPINStrength('');
        expect(strength, equals(0));
      });

      test('should return low score for weak PIN', () {
        final strength = pinService.checkPINStrength('1111');
        expect(strength, lessThan(50));
      });

      test('should return higher score for stronger PIN', () {
        final strength = pinService.checkPINStrength('123456');
        expect(strength, greaterThan(60));
      });

      test('should penalize sequential digits', () {
        final sequentialStrength = pinService.checkPINStrength('1234');
        final randomStrength = pinService.checkPINStrength('1357');
        expect(randomStrength, greaterThan(sequentialStrength));
      });
    });

    group('Utility Methods', () {
      test('should correctly report PIN status', () async {
        expect(await pinService.isPINSet(), isFalse);
        
        await pinService.setupPIN('1234');
        expect(await pinService.isPINSet(), isTrue);
        
        await pinService.resetPIN();
        expect(await pinService.isPINSet(), isFalse);
      });

      test('should correctly report lock status', () async {
        await pinService.setupPIN('1234');
        expect(await pinService.isLocked(), isFalse);
        
        // Lock the account
        await pinService.verifyPIN('5678');
        await pinService.verifyPIN('9999');
        await pinService.verifyPIN('0000');
        
        expect(await pinService.isLocked(), isTrue);
      });

      test('should clear all PIN data', () async {
        await pinService.setupPIN('1234');
        await pinService.verifyPIN('5678'); // Create failed attempt
        
        final success = await pinService.clearAllPINData();
        
        expect(success, isTrue);
        expect(await pinService.isPINSet(), isFalse);
        expect(await pinService.getFailedAttempts(), equals(0));
        expect(await pinService.isLocked(), isFalse);
      });
    });
  });
}