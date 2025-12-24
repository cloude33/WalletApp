import 'package:flutter_test/flutter_test.dart';
import 'package:money/services/auth/pin_service.dart';
import 'package:money/models/security/security_models.dart';

void main() {
  group('PINService Validation Logic', () {
    late PINService pinService;

    setUp(() {
      pinService = PINService();
    });

    group('PIN Strength Validation', () {
      test('should return 0 for empty PIN', () {
        final strength = pinService.checkPINStrength('');
        expect(strength, equals(0));
      });

      test('should return low score for weak PIN with repeated digits', () {
        final strength = pinService.checkPINStrength('1111');
        expect(strength, lessThan(50));
      });

      test('should return higher score for PIN with unique digits', () {
        final strength = pinService.checkPINStrength('1357');
        expect(strength, greaterThan(40));
      });

      test('should return higher score for longer PIN', () {
        final shortStrength = pinService.checkPINStrength('1234');
        final longStrength = pinService.checkPINStrength('123456');
        expect(longStrength, greaterThan(shortStrength));
      });

      test('should penalize sequential digits', () {
        final sequentialStrength = pinService.checkPINStrength('1234');
        final randomStrength = pinService.checkPINStrength('1357');
        expect(randomStrength, greaterThan(sequentialStrength));
      });

      test('should penalize descending sequential digits', () {
        final sequentialStrength = pinService.checkPINStrength('4321');
        final randomStrength = pinService.checkPINStrength('1357');
        expect(randomStrength, greaterThan(sequentialStrength));
      });

      test('should handle mixed sequential patterns', () {
        final strength1 = pinService.checkPINStrength('123789');
        final strength2 = pinService.checkPINStrength('987321');
        final strength3 = pinService.checkPINStrength('135792');
        
        // Sequential patterns should have lower strength
        expect(strength3, greaterThan(strength1));
        expect(strength3, greaterThan(strength2));
      });
    });

    group('PIN Format Validation (via setupPIN)', () {
      test('should validate PIN length constraints', () async {
        // Test minimum length
        var result = await pinService.setupPIN('123');
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('en az 4 haneli'));

        // Test maximum length  
        result = await pinService.setupPIN('1234567');
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('en fazla 6 haneli'));

        // Test valid lengths
        result = await pinService.setupPIN('1234');
        expect(result.errorMessage, isNot(contains('haneli')));
        
        result = await pinService.setupPIN('123456');
        expect(result.errorMessage, isNot(contains('haneli')));
      });

      test('should validate PIN contains only digits', () async {
        var result = await pinService.setupPIN('12a4');
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('sadece rakamlardan'));

        result = await pinService.setupPIN('12#4');
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('sadece rakamlardan'));

        result = await pinService.setupPIN('12 4');
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('sadece rakamlardan'));
      });

      test('should reject empty PIN', () async {
        final result = await pinService.setupPIN('');
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('boş olamaz'));
      });

      test('should accept valid numeric PINs', () async {
        // These will fail due to storage issues, but should pass validation
        var result = await pinService.setupPIN('1234');
        expect(result.errorMessage, isNot(contains('haneli')));
        expect(result.errorMessage, isNot(contains('sadece rakamlardan')));
        expect(result.errorMessage, isNot(contains('boş olamaz')));

        result = await pinService.setupPIN('567890');
        expect(result.errorMessage, isNot(contains('haneli')));
        expect(result.errorMessage, isNot(contains('sadece rakamlardan')));
        expect(result.errorMessage, isNot(contains('boş olamaz')));
      });
    });

    group('PIN Change Validation (via changePIN)', () {
      test('should validate new PIN format', () async {
        final result = await pinService.changePIN('1234', '12');
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('en az 4 haneli'));
      });

      test('should reject same old and new PIN', () async {
        final result = await pinService.changePIN('1234', '1234');
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('aynı olamaz'));
      });

      test('should validate old PIN format', () async {
        final result = await pinService.changePIN('12', '5678');
        expect(result.isSuccess, isFalse);
        // Should fail on old PIN validation first
        expect(result.errorMessage, isNot(contains('aynı olamaz')));
      });
    });

    group('Error Handling', () {
      test('should handle initialization gracefully', () async {
        // These tests verify that the service handles initialization errors
        // without crashing and returns appropriate error messages
        
        final result = await pinService.setupPIN('1234');
        expect(result.isSuccess, isFalse);
        expect(result.method, equals(AuthMethod.pin));
        expect(result.errorMessage, isNotNull);
        expect(result.errorMessage, isNotEmpty);
      });

      test('should return consistent error structure', () async {
        final result = await pinService.verifyPIN('1234');
        expect(result.isSuccess, isFalse);
        expect(result.method, equals(AuthMethod.pin));
        expect(result.errorMessage, isNotNull);
        expect(result.timestamp, isNotNull);
      });
    });
  });
}