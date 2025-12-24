import 'package:flutter_test/flutter_test.dart';
import 'package:money/utils/kmh_validator.dart';
import '../property_test_utils.dart';

/// Property-based tests for KMH account number masking
/// 
/// Feature: kmh-account-management, Property 34: Hesap Numarası Maskeleme
/// Validates: Requirements 9.4
/// 
/// Property: For any account number, when displayed, only the last 4 digits
/// should be visible, the rest should be masked with asterisks.
void main() {
  group('KMH Account Number Masking Property Tests', () {
    // Property 34: Account Number Masking
    // For any account number, when displayed, only the last 4 digits should be visible
    test('property: account numbers with 4+ digits show only last 4 digits', () {
      for (int i = 0; i < 100; i++) {
        // Generate random account number with at least 4 digits
        final length = 4 + PropertyTest.randomInt(min: 0, max: 16);
        final accountNumber = _generateAccountNumber(length);
        
        // Apply masking
        final masked = KmhValidator.maskAccountNumber(accountNumber);
        
        // Verify property: only last 4 digits are visible
        expect(masked, isNotNull);
        expect(masked!.length, equals(accountNumber.length));
        
        // Last 4 characters should match original
        final lastFour = accountNumber.substring(accountNumber.length - 4);
        expect(masked.substring(masked.length - 4), equals(lastFour));
        
        // All characters before last 4 should be asterisks
        final maskedPart = masked.substring(0, masked.length - 4);
        expect(maskedPart, equals('*' * (accountNumber.length - 4)));
      }
    });

    test('property: account numbers shorter than 4 digits remain unchanged', () {
      for (int i = 0; i < 100; i++) {
        // Generate random account number with less than 4 digits
        final length = PropertyTest.randomInt(min: 0, max: 3);
        final accountNumber = length > 0 ? _generateAccountNumber(length) : '';
        
        // Apply masking
        final masked = KmhValidator.maskAccountNumber(accountNumber);
        
        // Verify property: short account numbers are not masked
        expect(masked, equals(accountNumber));
      }
    });

    test('property: null account numbers return null', () {
      // Apply masking to null
      final masked = KmhValidator.maskAccountNumber(null);
      
      // Verify property: null input returns null
      expect(masked, isNull);
    });

    test('property: masking is idempotent for short numbers', () {
      for (int i = 0; i < 100; i++) {
        // Generate random short account number (< 4 digits)
        final length = PropertyTest.randomInt(min: 0, max: 3);
        final accountNumber = length > 0 ? _generateAccountNumber(length) : '';
        
        // Apply masking twice
        final masked1 = KmhValidator.maskAccountNumber(accountNumber);
        final masked2 = KmhValidator.maskAccountNumber(masked1);
        
        // Verify property: masking twice gives same result as masking once
        expect(masked2, equals(masked1));
      }
    });

    test('property: masked numbers preserve original length', () {
      for (int i = 0; i < 100; i++) {
        // Generate random account number with at least 4 digits
        final length = 4 + PropertyTest.randomInt(min: 0, max: 16);
        final accountNumber = _generateAccountNumber(length);
        
        // Apply masking
        final masked = KmhValidator.maskAccountNumber(accountNumber);
        
        // Verify property: length is preserved
        expect(masked!.length, equals(accountNumber.length));
      }
    });

    test('property: exactly 4 asterisks for 8-digit account numbers', () {
      for (int i = 0; i < 100; i++) {
        // Generate 8-digit account number (common format)
        final accountNumber = _generateAccountNumber(8);
        
        // Apply masking
        final masked = KmhValidator.maskAccountNumber(accountNumber);
        
        // Verify property: first 4 chars are asterisks, last 4 are digits
        expect(masked!.substring(0, 4), equals('****'));
        expect(masked.substring(4), equals(accountNumber.substring(4)));
      }
    });

    test('property: masking works with numeric-only account numbers', () {
      for (int i = 0; i < 100; i++) {
        // Generate numeric-only account number
        final length = 4 + PropertyTest.randomInt(min: 0, max: 16);
        final accountNumber = _generateNumericAccountNumber(length);
        
        // Apply masking
        final masked = KmhValidator.maskAccountNumber(accountNumber);
        
        // Verify property: masking works correctly
        expect(masked, isNotNull);
        expect(masked!.length, equals(accountNumber.length));
        expect(masked.substring(masked.length - 4), equals(accountNumber.substring(accountNumber.length - 4)));
      }
    });

    test('property: masking works with alphanumeric account numbers', () {
      for (int i = 0; i < 100; i++) {
        // Generate alphanumeric account number
        final length = 4 + PropertyTest.randomInt(min: 0, max: 16);
        final accountNumber = _generateAlphanumericAccountNumber(length);
        
        // Apply masking
        final masked = KmhValidator.maskAccountNumber(accountNumber);
        
        // Verify property: masking works correctly
        expect(masked, isNotNull);
        expect(masked!.length, equals(accountNumber.length));
        expect(masked.substring(masked.length - 4), equals(accountNumber.substring(accountNumber.length - 4)));
      }
    });

    test('property: no information leakage - masked part contains no original digits', () {
      for (int i = 0; i < 100; i++) {
        // Generate random account number with at least 4 digits
        final length = 4 + PropertyTest.randomInt(min: 0, max: 16);
        final accountNumber = _generateAccountNumber(length);
        
        // Apply masking
        final masked = KmhValidator.maskAccountNumber(accountNumber);
        
        // Verify property: masked part contains only asterisks
        final maskedPart = masked!.substring(0, masked.length - 4);
        expect(maskedPart.contains(RegExp(r'[^*]')), isFalse,
            reason: 'Masked part should only contain asterisks');
      }
    });
  });
}

/// Generate a random account number with specified length
String _generateAccountNumber(int length) {
  final random = PropertyTest.randomInt(min: 0, max: 999999999);
  return random.toString().padLeft(length, '0').substring(0, length);
}

/// Generate a numeric-only account number
String _generateNumericAccountNumber(int length) {
  final buffer = StringBuffer();
  for (int i = 0; i < length; i++) {
    buffer.write(PropertyTest.randomInt(min: 0, max: 9));
  }
  return buffer.toString();
}

/// Generate an alphanumeric account number
String _generateAlphanumericAccountNumber(int length) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final buffer = StringBuffer();
  for (int i = 0; i < length; i++) {
    final index = PropertyTest.randomInt(min: 0, max: chars.length - 1);
    buffer.write(chars[index]);
  }
  return buffer.toString();
}
