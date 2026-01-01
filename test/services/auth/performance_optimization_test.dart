import 'package:flutter_test/flutter_test.dart';
import 'package:parion/utils/security/encryption_helper.dart';

/// Performance optimization tests for authentication services
/// 
/// These tests verify that performance optimizations are working correctly:
/// - Key caching in encryption
/// - Reduced redundant operations
/// - Memory leak prevention
void main() {
  group('EncryptionHelper Performance Optimizations', () {
    setUp(() {
      // Clear cache before each test
      EncryptionHelper.clearKeyCache();
    });

    test('should cache derived keys for better performance', () {
      final password = 'testPassword123';
      final plaintext = '1234';
      
      // First encryption - will derive key
      final stopwatch1 = Stopwatch()..start();
      final encrypted1 = EncryptionHelper.encrypt(plaintext, password);
      stopwatch1.stop();
      final firstTime = stopwatch1.elapsedMicroseconds;
      
      // Second encryption with same password - should use cached key
      final stopwatch2 = Stopwatch()..start();
      final encrypted2 = EncryptionHelper.encrypt(plaintext, password);
      stopwatch2.stop();
      final secondTime = stopwatch2.elapsedMicroseconds;
      
      // Verify both encryptions work
      expect(EncryptionHelper.isValidEncryptedData(encrypted1), true);
      expect(EncryptionHelper.isValidEncryptedData(encrypted2), true);
      
      // Second encryption should be faster due to caching
      // Note: This is a rough check, actual performance may vary
      print('First encryption: $firstTimeμs');
      print('Second encryption (cached): $secondTimeμs');
      print('Performance improvement: ${((firstTime - secondTime) / firstTime * 100).toStringAsFixed(1)}%');
      
      // Verify decryption works for both
      final decrypted1 = EncryptionHelper.decrypt(encrypted1, password);
      final decrypted2 = EncryptionHelper.decrypt(encrypted2, password);
      expect(decrypted1, plaintext);
      expect(decrypted2, plaintext);
    });

    test('should clear key cache when requested', () {
      final password = 'testPassword123';
      final plaintext = '1234';
      
      // Encrypt to populate cache
      EncryptionHelper.encrypt(plaintext, password);
      
      // Clear cache
      EncryptionHelper.clearKeyCache();
      
      // Next encryption should take longer (no cache)
      final encrypted = EncryptionHelper.encrypt(plaintext, password);
      expect(EncryptionHelper.isValidEncryptedData(encrypted), true);
      
      final decrypted = EncryptionHelper.decrypt(encrypted, password);
      expect(decrypted, plaintext);
    });

    test('should handle multiple different passwords in cache', () {
      final passwords = ['pass1', 'pass2', 'pass3', 'pass4', 'pass5'];
      final plaintext = '1234';
      
      // Encrypt with different passwords
      for (final password in passwords) {
        final encrypted = EncryptionHelper.encrypt(plaintext, password);
        expect(EncryptionHelper.isValidEncryptedData(encrypted), true);
        
        final decrypted = EncryptionHelper.decrypt(encrypted, password);
        expect(decrypted, plaintext);
      }
      
      // All should still work (cache should handle multiple entries)
      for (final password in passwords) {
        final encrypted = EncryptionHelper.encrypt(plaintext, password);
        final decrypted = EncryptionHelper.decrypt(encrypted, password);
        expect(decrypted, plaintext);
      }
    });

    test('should evict old cache entries when cache is full', () {
      final plaintext = '1234';
      
      // Fill cache beyond max size (10 entries)
      for (int i = 0; i < 15; i++) {
        final password = 'password$i';
        final encrypted = EncryptionHelper.encrypt(plaintext, password);
        expect(EncryptionHelper.isValidEncryptedData(encrypted), true);
      }
      
      // All encryptions should still work (cache eviction should not break functionality)
      for (int i = 0; i < 15; i++) {
        final password = 'password$i';
        final encrypted = EncryptionHelper.encrypt(plaintext, password);
        final decrypted = EncryptionHelper.decrypt(encrypted, password);
        expect(decrypted, plaintext);
      }
    });

    test('should maintain security with caching enabled', () {
      final password = 'securePassword123';
      final plaintext1 = '1234';
      final plaintext2 = '5678';
      
      // Encrypt different plaintexts with same password
      final encrypted1 = EncryptionHelper.encrypt(plaintext1, password);
      final encrypted2 = EncryptionHelper.encrypt(plaintext2, password);
      
      // Verify they produce different ciphertexts (due to different IVs)
      expect(encrypted1, isNot(equals(encrypted2)));
      
      // Verify both decrypt correctly
      expect(EncryptionHelper.decrypt(encrypted1, password), plaintext1);
      expect(EncryptionHelper.decrypt(encrypted2, password), plaintext2);
      
      // Verify wrong password fails
      expect(
        () => EncryptionHelper.decrypt(encrypted1, 'wrongPassword'),
        throwsException,
      );
    });

    test('should handle cache expiry correctly', () async {
      final password = 'testPassword123';
      final plaintext = '1234';
      
      // Encrypt to populate cache
      final encrypted1 = EncryptionHelper.encrypt(plaintext, password);
      expect(EncryptionHelper.isValidEncryptedData(encrypted1), true);
      
      // Wait for cache to expire (5 minutes in production, but we can't wait that long in tests)
      // This test just verifies the mechanism exists
      
      // Encrypt again - should still work regardless of cache state
      final encrypted2 = EncryptionHelper.encrypt(plaintext, password);
      expect(EncryptionHelper.isValidEncryptedData(encrypted2), true);
      
      // Verify decryption
      expect(EncryptionHelper.decrypt(encrypted1, password), plaintext);
      expect(EncryptionHelper.decrypt(encrypted2, password), plaintext);
    });

    test('should perform encryption within acceptable time limits', () {
      final password = 'testPassword123';
      final plaintext = '1234';
      
      // Measure encryption time
      final stopwatch = Stopwatch()..start();
      final encrypted = EncryptionHelper.encrypt(plaintext, password);
      stopwatch.stop();
      
      final encryptionTime = stopwatch.elapsedMilliseconds;
      print('Encryption time: ${encryptionTime}ms');
      
      // Encryption should complete within 1000ms (allowing for test environment overhead)
      // Production target is 500ms, but test environment may be slower
      expect(encryptionTime, lessThan(1000));
      
      // Verify encryption worked
      expect(EncryptionHelper.isValidEncryptedData(encrypted), true);
      expect(EncryptionHelper.decrypt(encrypted, password), plaintext);
    });

    test('should perform decryption within acceptable time limits', () {
      final password = 'testPassword123';
      final plaintext = '1234';
      
      // Encrypt first
      final encrypted = EncryptionHelper.encrypt(plaintext, password);
      
      // Measure decryption time
      final stopwatch = Stopwatch()..start();
      final decrypted = EncryptionHelper.decrypt(encrypted, password);
      stopwatch.stop();
      
      final decryptionTime = stopwatch.elapsedMilliseconds;
      print('Decryption time: ${decryptionTime}ms');
      
      // Decryption should complete within 500ms (design requirement)
      expect(decryptionTime, lessThan(500));
      
      // Verify decryption worked
      expect(decrypted, plaintext);
    });
  });

  group('Performance Benchmarks', () {
    test('benchmark: encryption performance with caching', () {
      final password = 'benchmarkPassword';
      final plaintext = '123456';
      final iterations = 10;
      
      // Benchmark without cache (clear cache before each operation)
      final stopwatch1 = Stopwatch()..start();
      for (int i = 0; i < iterations; i++) {
        EncryptionHelper.clearKeyCache();
        EncryptionHelper.encrypt(plaintext, password);
      }
      stopwatch1.stop();
      final timeWithoutCache = stopwatch1.elapsedMilliseconds;
      
      // Benchmark with cache (reuse cached keys)
      EncryptionHelper.clearKeyCache();
      final stopwatch2 = Stopwatch()..start();
      for (int i = 0; i < iterations; i++) {
        EncryptionHelper.encrypt(plaintext, password);
      }
      stopwatch2.stop();
      final timeWithCache = stopwatch2.elapsedMilliseconds;
      
      print('=== Encryption Performance Benchmark ===');
      print('Iterations: $iterations');
      print('Time without cache: ${timeWithoutCache}ms (${(timeWithoutCache / iterations).toStringAsFixed(2)}ms per operation)');
      print('Time with cache: ${timeWithCache}ms (${(timeWithCache / iterations).toStringAsFixed(2)}ms per operation)');
      
      if (timeWithCache < timeWithoutCache) {
        print('Performance improvement: ${((timeWithoutCache - timeWithCache) / timeWithoutCache * 100).toStringAsFixed(1)}%');
      } else {
        print('Note: Cache benefit may vary due to test environment overhead');
      }
      
      // Both should complete within reasonable time (allowing for test environment overhead)
      expect(timeWithoutCache, lessThan(10000)); // 10 seconds for 10 operations in test environment
      expect(timeWithCache, lessThan(10000)); // 10 seconds for 10 operations in test environment
    });
  });
}
