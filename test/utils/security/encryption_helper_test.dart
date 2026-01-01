import 'package:flutter_test/flutter_test.dart';
import 'package:parion/utils/security/encryption_helper.dart';

void main() {
  group('EncryptionHelper', () {
    test('should encrypt and decrypt successfully', () {
      const plaintext = '1234';
      const password = 'test_password';
      
      final encrypted = EncryptionHelper.encrypt(plaintext, password);
      final decrypted = EncryptionHelper.decrypt(encrypted, password);
      
      expect(decrypted, equals(plaintext));
    });

    test('should fail with wrong password', () {
      const plaintext = '1234';
      const password = 'test_password';
      const wrongPassword = 'wrong_password';
      
      final encrypted = EncryptionHelper.encrypt(plaintext, password);
      
      expect(
        () => EncryptionHelper.decrypt(encrypted, wrongPassword),
        throwsException,
      );
    });

    test('should validate encrypted data format', () {
      const plaintext = '1234';
      const password = 'test_password';
      
      final encrypted = EncryptionHelper.encrypt(plaintext, password);
      
      expect(EncryptionHelper.isValidEncryptedData(encrypted), isTrue);
      expect(EncryptionHelper.isValidEncryptedData('invalid'), isFalse);
      expect(EncryptionHelper.isValidEncryptedData(''), isFalse);
    });

    test('should hash and verify password', () {
      const password = 'test_password';
      
      final hash = EncryptionHelper.hashPassword(password);
      
      expect(EncryptionHelper.verifyPassword(password, hash), isTrue);
      expect(EncryptionHelper.verifyPassword('wrong', hash), isFalse);
    });

    test('should throw on empty inputs', () {
      expect(
        () => EncryptionHelper.encrypt('', 'password'),
        throwsArgumentError,
      );
      
      expect(
        () => EncryptionHelper.encrypt('data', ''),
        throwsArgumentError,
      );
      
      expect(
        () => EncryptionHelper.decrypt('', 'password'),
        throwsArgumentError,
      );
      
      expect(
        () => EncryptionHelper.decrypt('data', ''),
        throwsArgumentError,
      );
    });

    test('should generate different encrypted outputs for same input', () {
      const plaintext = '1234';
      const password = 'test_password';
      
      final encrypted1 = EncryptionHelper.encrypt(plaintext, password);
      final encrypted2 = EncryptionHelper.encrypt(plaintext, password);
      
      // Should be different due to random salt and IV
      expect(encrypted1, isNot(equals(encrypted2)));
      
      // But both should decrypt to the same plaintext
      expect(EncryptionHelper.decrypt(encrypted1, password), equals(plaintext));
      expect(EncryptionHelper.decrypt(encrypted2, password), equals(plaintext));
    });
  });
}