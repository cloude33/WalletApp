import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money/services/auth/pin_service.dart';
import 'package:money/models/security/security_models.dart';

/// Brute Force Saldırı Testleri
/// 
/// Bu test dosyası, brute force saldırılarına karşı
/// sistemin direncini test eder.
/// 
/// Gereksinimler:
/// - 2.1: 3 yanlış PIN girişinde hesabı geçici olarak kilitlemeli
/// - 2.2: Hesap kilitlendiğinde 30 saniye bekleme süresi uygulamalı
/// - 2.3: 5 yanlış PIN girişinde hesabı 5 dakika kilitlemeli
/// - 2.4: Kilitleme süresi dolduğunda deneme sayacını sıfırlamalı

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Brute Force Attack Tests', () {
    late PINService pinService;

    setUp(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});

      // Mock flutter_secure_storage
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'read':
              return null;
            case 'write':
              return null;
            case 'delete':
              return null;
            case 'deleteAll':
              return null;
            case 'readAll':
              return <String, String>{};
            case 'containsKey':
              return false;
            default:
              return null;
          }
        },
      );

      pinService = PINService();
      pinService.resetForTesting();
    });

    tearDown(() {
      pinService.resetForTesting();
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      );
    });

    test('BF-001: Sequential brute force attack should trigger lockout', () async {
      // Gereksinim 2.1: 3 yanlış PIN girişinde hesabı geçici olarak kilitlemeli
      await pinService.setupPIN('1234');

      // Attempt sequential PINs
      final attempts = ['0000', '1111', '2222'];
      
      for (int i = 0; i < attempts.length; i++) {
        final result = await pinService.verifyPIN(attempts[i]);
        
        if (i < 2) {
          expect(result.isSuccess, isFalse);
          expect(await pinService.isLocked(), isFalse,
              reason: 'Should not be locked before 3 attempts');
        } else {
          // Third attempt should trigger lockout
          expect(result.isSuccess, isFalse);
          expect(await pinService.isLocked(), isTrue,
              reason: 'Should be locked after 3 failed attempts');
          expect(result.lockoutDuration, isNotNull);
          expect(result.lockoutDuration!.inSeconds, greaterThanOrEqualTo(30),
              reason: 'Lockout should be at least 30 seconds');
        }
      }
    });

    test('BF-002: Dictionary attack with common PINs should be rate-limited', () async {
      // Gereksinim 2.1, 2.2: Deneme sayacı ve kilitleme mekanizması
      await pinService.setupPIN('9876');

      // Common PINs that attackers might try
      final commonPins = [
        '1234', '0000', '1111', '2222', '3333',
        '4444', '5555', '6666', '7777', '8888',
      ];

      int attemptCount = 0;
      bool wasLocked = false;

      for (final pin in commonPins) {
        final result = await pinService.verifyPIN(pin);
        attemptCount++;

        if (await pinService.isLocked()) {
          wasLocked = true;
          break;
        }

        expect(result.isSuccess, isFalse,
            reason: 'Common PIN should not match');
      }

      expect(wasLocked, isTrue,
          reason: 'Account should be locked during dictionary attack');
      expect(attemptCount, lessThanOrEqualTo(3),
          reason: 'Should lock before trying all common PINs');
    });

    test('BF-003: Distributed brute force with delays should still trigger lockout', () async {
      // Gereksinim 2.1: Deneme sayacı yönetimi
      await pinService.setupPIN('1234');

      // Simulate distributed attack with small delays
      for (int i = 0; i < 5; i++) {
        await pinService.verifyPIN('${i}000');
        
        // Small delay between attempts
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Should still be locked despite delays
      expect(await pinService.isLocked(), isTrue,
          reason: 'Delayed attempts should still trigger lockout');
      
      final failedAttempts = await pinService.getFailedAttempts();
      expect(failedAttempts, greaterThanOrEqualTo(3),
          reason: 'Failed attempts should accumulate despite delays');
    });

    test('BF-004: Exhaustive 4-digit PIN brute force should be prevented', () async {
      // Gereksinim 2.1, 2.2: Kilitleme mekanizması
      await pinService.setupPIN('9999'); // Last possible 4-digit PIN

      int attemptCount = 0;
      bool wasLocked = false;

      // Try to brute force all 4-digit PINs
      for (int i = 0; i < 10000; i++) {
        if (await pinService.isLocked()) {
          wasLocked = true;
          break;
        }

        final pin = i.toString().padLeft(4, '0');
        await pinService.verifyPIN(pin);
        attemptCount++;
      }

      expect(wasLocked, isTrue,
          reason: 'Exhaustive brute force should be prevented by lockout');
      expect(attemptCount, lessThan(10),
          reason: 'Should lock well before trying all combinations');
    });

    test('BF-005: Parallel brute force attack should be detected', () async {
      // Gereksinim 2.1: Deneme sayacı yönetimi
      await pinService.setupPIN('1234');

      // Simulate parallel attack attempts
      final futures = <Future<AuthResult>>[];
      
      for (int i = 0; i < 10; i++) {
        futures.add(pinService.verifyPIN('${i}000'));
      }

      final results = await Future.wait(futures);

      // Count failures
      final failures = results.where((r) => !r.isSuccess).length;
      expect(failures, greaterThan(0),
          reason: 'Parallel attempts should fail');

      // Account should be locked
      expect(await pinService.isLocked(), isTrue,
          reason: 'Parallel brute force should trigger lockout');
    });

    test('BF-006: Incremental brute force (0000 to 9999) should be stopped early', () async {
      // Gereksinim 2.1, 2.2: Kilitleme mekanizması
      await pinService.setupPIN('5555'); // Middle-range PIN

      int attemptCount = 0;
      
      for (int i = 0; i <= 9999; i++) {
        if (await pinService.isLocked()) {
          break;
        }

        final pin = i.toString().padLeft(4, '0');
        await pinService.verifyPIN(pin);
        attemptCount++;
      }

      expect(attemptCount, lessThanOrEqualTo(10),
          reason: 'Incremental brute force should be stopped within 10 attempts');
      expect(await pinService.isLocked(), isTrue,
          reason: 'Account should be locked');
    });

    test('BF-007: Reverse brute force (9999 to 0000) should be stopped early', () async {
      // Gereksinim 2.1, 2.2: Kilitleme mekanizması
      await pinService.setupPIN('5555');

      int attemptCount = 0;
      
      for (int i = 9999; i >= 0; i--) {
        if (await pinService.isLocked()) {
          break;
        }

        final pin = i.toString().padLeft(4, '0');
        await pinService.verifyPIN(pin);
        attemptCount++;
      }

      expect(attemptCount, lessThanOrEqualTo(10),
          reason: 'Reverse brute force should be stopped within 10 attempts');
      expect(await pinService.isLocked(), isTrue,
          reason: 'Account should be locked');
    });

    test('BF-008: Pattern-based brute force (1111, 2222, etc.) should trigger lockout', () async {
      // Gereksinim 2.1: Deneme sayacı yönetimi
      await pinService.setupPIN('1234');

      // Try repeated digit patterns
      final patterns = ['1111', '2222', '3333', '4444', '5555'];
      
      int attemptCount = 0;
      for (final pattern in patterns) {
        if (await pinService.isLocked()) {
          break;
        }

        await pinService.verifyPIN(pattern);
        attemptCount++;
      }

      expect(await pinService.isLocked(), isTrue,
          reason: 'Pattern-based attack should trigger lockout');
      expect(attemptCount, lessThanOrEqualTo(3),
          reason: 'Should lock within first 3 attempts');
    });

    test('BF-009: Birthday-based brute force should be rate-limited', () async {
      // Gereksinim 2.1, 2.2: Kilitleme mekanizması
      await pinService.setupPIN('1234');

      // Common birthday patterns (MMDD format)
      final birthdayPatterns = [
        '0101', '0102', '0103', '0201', '0301',
        '1225', '1231', '0704', '1111', '0214',
      ];

      int attemptCount = 0;
      for (final pattern in birthdayPatterns) {
        if (await pinService.isLocked()) {
          break;
        }

        await pinService.verifyPIN(pattern);
        attemptCount++;
      }

      expect(await pinService.isLocked(), isTrue,
          reason: 'Birthday-based attack should trigger lockout');
      expect(attemptCount, lessThanOrEqualTo(3),
          reason: 'Should lock within first 3 attempts');
    });

    test('BF-010: Lockout duration should increase with repeated attacks', () async {
      // Gereksinim 2.2, 2.3: Kilitleme süresi artışı
      await pinService.setupPIN('1234');

      // First attack - trigger first lockout (30 seconds)
      for (int i = 0; i < 3; i++) {
        await pinService.verifyPIN('${i}000');
      }

      expect(await pinService.isLocked(), isTrue);
      final firstLockout = await pinService.getRemainingLockoutTime();
      expect(firstLockout, isNotNull);
      expect(firstLockout!.inSeconds, lessThanOrEqualTo(30),
          reason: 'First lockout should be 30 seconds');

      // Clear lockout for testing
      await pinService.clearAllPINData();
      await pinService.setupPIN('1234');

      // Second attack - trigger longer lockout (5 minutes)
      for (int i = 0; i < 5; i++) {
        await pinService.verifyPIN('${i}000');
      }

      expect(await pinService.isLocked(), isTrue);
      final secondLockout = await pinService.getRemainingLockoutTime();
      expect(secondLockout, isNotNull);
      expect(secondLockout!.inMinutes, greaterThanOrEqualTo(4),
          reason: 'Second lockout should be at least 5 minutes');
    });

    test('BF-011: Maximum attempts should trigger extended lockout', () async {
      // Gereksinim 2.3: 5 yanlış PIN girişinde hesabı 5 dakika kilitlemeli
      await pinService.setupPIN('1234');

      // Attempt maximum number of failures
      for (int i = 0; i < 10; i++) {
        await pinService.verifyPIN('${i}000');
      }

      expect(await pinService.isLocked(), isTrue,
          reason: 'Account should be locked after max attempts');

      final lockoutTime = await pinService.getRemainingLockoutTime();
      expect(lockoutTime, isNotNull);
      expect(lockoutTime!.inMinutes, greaterThanOrEqualTo(5),
          reason: 'Extended lockout should be at least 5 minutes');
    });

    test('BF-012: Lockout should persist across service restarts', () async {
      // Gereksinim 2.2: Kilitleme durumu kalıcı olmalı
      await pinService.setupPIN('1234');

      // Trigger lockout
      for (int i = 0; i < 3; i++) {
        await pinService.verifyPIN('${i}000');
      }

      expect(await pinService.isLocked(), isTrue);

      // Simulate service restart
      pinService.resetForTesting();
      await pinService.initialize();

      // Lockout should still be active
      expect(await pinService.isLocked(), isTrue,
          reason: 'Lockout should persist after restart');
    });

    test('BF-013: Successful authentication should reset attempt counter', () async {
      // Gereksinim 2.4: Başarılı doğrulama deneme sayacını sıfırlamalı
      await pinService.setupPIN('1234');

      // Make some failed attempts
      await pinService.verifyPIN('0000');
      await pinService.verifyPIN('1111');
      
      expect(await pinService.getFailedAttempts(), equals(2));

      // Successful authentication
      final result = await pinService.verifyPIN('1234');
      expect(result.isSuccess, isTrue);

      // Counter should be reset
      expect(await pinService.getFailedAttempts(), equals(0),
          reason: 'Successful authentication should reset counter');
    });

    test('BF-014: Rapid-fire brute force should not bypass rate limiting', () async {
      // Gereksinim 2.1: Deneme sayacı yönetimi
      await pinService.setupPIN('1234');

      // Rapid-fire attempts with no delay
      final startTime = DateTime.now();
      
      for (int i = 0; i < 100; i++) {
        if (await pinService.isLocked()) {
          break;
        }
        await pinService.verifyPIN('${i % 10}000');
      }

      final duration = DateTime.now().difference(startTime);

      expect(await pinService.isLocked(), isTrue,
          reason: 'Rapid-fire attack should trigger lockout');
      expect(duration.inSeconds, lessThan(5),
          reason: 'Lockout should happen quickly');
    });

    test('BF-015: Brute force with valid PIN format variations should fail', () async {
      // Gereksinim 2.1: Deneme sayacı yönetimi
      await pinService.setupPIN('1234');

      // Try variations of valid format
      final variations = [
        '1234 ', // With space
        ' 1234', // Leading space
        '12 34', // Space in middle
        '1234\n', // With newline
        '\t1234', // With tab
      ];

      for (final variation in variations) {
        final result = await pinService.verifyPIN(variation);
        
        // Should either reject format or fail verification
        expect(result.isSuccess, isFalse,
            reason: 'PIN variation should not succeed: "$variation"');
      }
    });
  });
}
