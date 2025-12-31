import 'package:flutter_test/flutter_test.dart';
import 'package:money/utils/security/encryption_helper.dart';
import '../../property_test_utils.dart';

void main() {
  group('EncryptionHelper Property Tests', () {
    // **Feature: pin-biometric-auth, Property 4: Şifreleme Geri Dönüşüm**
    PropertyTest.forAll<Map<String, String>>(
      description: 'Property 4: Şifreleme Geri Dönüşüm - Encryption round trip should preserve original data',
      generator: () => {
        'plaintext': _generatePinCode(),
        'password': PropertyTest.randomString(minLength: 8, maxLength: 50),
      },
      property: (testData) {
        final plaintext = testData['plaintext']!;
        final password = testData['password']!;
        
        try {
          // Encrypt the plaintext
          final encrypted = EncryptionHelper.encrypt(plaintext, password);
          
          // Decrypt it back
          final decrypted = EncryptionHelper.decrypt(encrypted, password);
          
          // The decrypted text should match the original plaintext
          return decrypted == plaintext;
        } catch (e) {
          // If encryption/decryption fails, the property fails
          return false;
        }
      },
      iterations: 5,
    );

    PropertyTest.forAll<Map<String, String>>(
      description: 'Property: Different passwords should not decrypt successfully',
      generator: () => {
        'plaintext': _generatePinCode(),
        'password1': PropertyTest.randomString(minLength: 8, maxLength: 50),
        'password2': PropertyTest.randomString(minLength: 8, maxLength: 50),
      },
      property: (testData) {
        final plaintext = testData['plaintext']!;
        final password1 = testData['password1']!;
        final password2 = testData['password2']!;
        
        // Skip if passwords are the same
        if (password1 == password2) return true;
        
        try {
          // Encrypt with first password
          final encrypted = EncryptionHelper.encrypt(plaintext, password1);
          
          // Try to decrypt with second password - should fail
          try {
            EncryptionHelper.decrypt(encrypted, password2);
            // If decryption succeeds with wrong password, property fails
            return false;
          } catch (e) {
            // Decryption should fail with wrong password
            return true;
          }
        } catch (e) {
          // If encryption fails, skip this test case
          return true;
        }
      },
      iterations: 5,
    );

    PropertyTest.forAll<String>(
      description: 'Property: Encrypted data should always be valid format',
      generator: () => _generatePinCode(),
      property: (plaintext) {
        final password = PropertyTest.randomString(minLength: 8, maxLength: 50);
        
        try {
          final encrypted = EncryptionHelper.encrypt(plaintext, password);
          return EncryptionHelper.isValidEncryptedData(encrypted);
        } catch (e) {
          return false;
        }
      },
      iterations: 5,
    );

    PropertyTest.forAll<String>(
      description: 'Property: Same input should produce different encrypted outputs (due to random salt/IV)',
      generator: () => _generatePinCode(),
      property: (plaintext) {
        final password = PropertyTest.randomString(minLength: 8, maxLength: 50);
        
        try {
          final encrypted1 = EncryptionHelper.encrypt(plaintext, password);
          final encrypted2 = EncryptionHelper.encrypt(plaintext, password);
          
          // Should be different due to random salt and IV
          final differentOutputs = encrypted1 != encrypted2;
          
          // But both should decrypt to the same plaintext
          final decrypted1 = EncryptionHelper.decrypt(encrypted1, password);
          final decrypted2 = EncryptionHelper.decrypt(encrypted2, password);
          final sameDecryption = decrypted1 == plaintext && decrypted2 == plaintext;
          
          return differentOutputs && sameDecryption;
        } catch (e) {
          return false;
        }
      },
      iterations: 5,
    );
  });
}

/// Generates a random PIN code (4-6 digits)
String _generatePinCode() {
  final length = 4 + PropertyTest.randomInt(min: 0, max: 2); // 4-6 digits
  final digits = List.generate(length, (_) => PropertyTest.randomInt(min: 0, max: 9));
  return digits.join();
}