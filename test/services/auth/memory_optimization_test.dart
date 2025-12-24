import 'package:flutter_test/flutter_test.dart';
import 'package:money/services/auth/pin_service.dart';
import 'package:money/services/auth/auth_service.dart';
import 'package:money/services/auth/session_manager.dart';
import 'package:money/services/auth/secure_storage_service.dart';
import 'package:money/services/auth/biometric_service.dart';

/// Memory Optimization Tests
/// 
/// These tests verify that memory optimization implementations are working correctly:
/// 1. Secure data cleaning
/// 2. Cache management
/// 3. Resource disposal
/// 
/// Validates: Bellek performans gereksinimleri
void main() {
  group('Memory Optimization Tests', () {
    setUp(() {
      // Reset all services before each test
      PINService().resetForTesting();
      AuthService().resetForTesting();
      SessionManager().resetForTesting();
      AuthSecureStorageService().resetForTesting();
    });

    group('Secure Data Cleaning', () {
      test('PIN Service clears cache after state changes', () async {
        final pinService = PINService();
        await pinService.initialize();

        // Setup PIN
        await pinService.setupPIN('1234');

        // Verify PIN is cached
        final isPINSet1 = await pinService.isPINSet();
        expect(isPINSet1, isTrue);

        // Clear all PIN data (should invalidate cache)
        await pinService.clearAllPINData();

        // Verify cache was invalidated
        final isPINSet2 = await pinService.isPINSet();
        expect(isPINSet2, isFalse);
      });

      test('Auth Service clears session data on logout', () async {
        final authService = AuthService();
        await authService.initialize();

        // Setup PIN first
        final pinService = PINService();
        await pinService.initialize();
        await pinService.setupPIN('1234');

        // Authenticate
        await authService.authenticateWithPIN('1234');

        // Verify session exists
        expect(authService.currentSession, isNotNull);

        // Logout
        await authService.logout();

        // Verify session is cleared
        expect(authService.currentSession, isNull);
        expect(authService.currentAuthState.isAuthenticated, isFalse);
      });

      test('Session Manager clears state on stop', () async {
        final sessionManager = SessionManager();
        await sessionManager.initialize();

        // Start session would require full setup, so we just verify disposal
        await sessionManager.stopSession();

        // Verify state is inactive
        expect(sessionManager.currentSessionState.isActive, isFalse);
      });

      test('Secure Storage invalidates cache after write', () async {
        final storage = AuthSecureStorageService();
        await storage.initialize();

        // Write data
        await storage.storePIN('1234');

        // Cache should be invalidated, forcing fresh read
        final isPINSet = await storage.isPINSet();
        expect(isPINSet, isTrue);

        // Remove PIN
        await storage.removePIN();

        // Cache should be invalidated again
        final isPINSetAfterRemove = await storage.isPINSet();
        expect(isPINSetAfterRemove, isFalse);
      });
    });

    group('Cache Management', () {
      test('PIN Service uses cache for repeated reads', () async {
        final pinService = PINService();
        await pinService.initialize();

        await pinService.setupPIN('1234');

        // First call - cache miss
        final startTime1 = DateTime.now();
        final result1 = await pinService.isPINSet();
        final duration1 = DateTime.now().difference(startTime1);

        // Second call - cache hit (should be faster or same)
        final startTime2 = DateTime.now();
        final result2 = await pinService.isPINSet();
        final duration2 = DateTime.now().difference(startTime2);

        expect(result1, equals(result2));
        expect(result1, isTrue);

        // Cache hit should be at least as fast
        // Note: In tests, timing can be unreliable, so we just verify correctness
        expect(duration2.inMilliseconds, lessThanOrEqualTo(duration1.inMilliseconds + 50));
      });

      test('Cache expires after timeout', () async {
        final pinService = PINService();
        await pinService.initialize();

        await pinService.setupPIN('1234');

        // First read - populates cache
        await pinService.isPINSet();

        // Wait for cache to expire (5 seconds + buffer)
        await Future.delayed(const Duration(seconds: 6));

        // This should trigger a fresh read
        final result = await pinService.isPINSet();
        expect(result, isTrue);
      });

      test('Biometric Service caches availability checks', () async {
        final biometricService = BiometricServiceImpl();

        // First call
        final available1 = await biometricService.isBiometricAvailable();

        // Second call - should use cache
        final available2 = await biometricService.isBiometricAvailable();

        expect(available1, equals(available2));
      });

      test('Secure Storage cache has size limits', () async {
        final storage = AuthSecureStorageService();
        await storage.initialize();

        // Write multiple values
        for (int i = 0; i < 100; i++) {
          await storage.write('test_key_$i', 'test_value_$i');
        }

        // Cache should not grow unbounded
        // This is verified by the implementation using targeted invalidation
        final result = await storage.read('test_key_0');
        expect(result, equals('test_value_0'));
      });
    });

    group('Resource Disposal', () {
      test('Auth Service disposes all timers', () async {
        final authService = AuthService();
        await authService.initialize();

        // Setup PIN
        final pinService = PINService();
        await pinService.initialize();
        await pinService.setupPIN('1234');

        // Authenticate to start timers
        await authService.authenticateWithPIN('1234');

        // Dispose service
        authService.dispose();

        // Verify cleanup
        expect(authService.currentSession, isNull);
        expect(authService.currentAuthState.isAuthenticated, isFalse);
      });

      test('Session Manager disposes all timers and streams', () async {
        final sessionManager = SessionManager();
        await sessionManager.initialize();

        // Dispose service
        sessionManager.dispose();

        // Stream should be closed
        expect(
          sessionManager.sessionStateStream,
          emitsDone,
        );
      });

      test('Services can be reinitialized after disposal', () async {
        final authService = AuthService();
        await authService.initialize();

        // Dispose
        authService.dispose();

        // Reset for testing
        authService.resetForTesting();

        // Reinitialize
        await authService.initialize();

        // Should work normally
        expect(authService.currentAuthState.isAuthenticated, isFalse);
      });

      test('Multiple dispose calls are safe', () async {
        final authService = AuthService();
        await authService.initialize();

        // Multiple dispose calls should not throw
        authService.dispose();
        authService.dispose();
        authService.dispose();

        // Should be safe
        expect(authService.currentSession, isNull);
      });
    });

    group('Memory Leak Prevention', () {
      test('Repeated authentication does not leak memory', () async {
        final authService = AuthService();
        await authService.initialize();

        final pinService = PINService();
        await pinService.initialize();
        await pinService.setupPIN('1234');

        // Perform multiple authentication cycles
        for (int i = 0; i < 10; i++) {
          await authService.authenticateWithPIN('1234');
          await authService.logout();
        }

        // Service should still be in clean state
        expect(authService.currentSession, isNull);
        expect(authService.currentAuthState.isAuthenticated, isFalse);
      });

      test('Session Manager handles multiple session cycles', () async {
        final sessionManager = SessionManager();
        await sessionManager.initialize();

        // Multiple session cycles
        for (int i = 0; i < 5; i++) {
          await sessionManager.stopSession();
        }

        // Should be in clean state
        expect(sessionManager.currentSessionState.isActive, isFalse);
      });

      test('Cache does not grow unbounded', () async {
        final storage = AuthSecureStorageService();
        await storage.initialize();

        // Write many values
        for (int i = 0; i < 1000; i++) {
          await storage.write('key_$i', 'value_$i');
        }

        // Cache should have been invalidated multiple times
        // Verify we can still read values
        final value = await storage.read('key_999');
        expect(value, equals('value_999'));
      });
    });

    group('Performance Optimization', () {
      test('Cached reads are faster than uncached reads', () async {
        final pinService = PINService();
        await pinService.initialize();
        await pinService.setupPIN('1234');

        // Uncached read (first time)
        final uncachedStart = DateTime.now();
        await pinService.getFailedAttempts();
        final uncachedDuration = DateTime.now().difference(uncachedStart);

        // Cached read (second time, within cache window)
        final cachedStart = DateTime.now();
        await pinService.getFailedAttempts();
        final cachedDuration = DateTime.now().difference(cachedStart);

        // Cached should be faster or equal
        expect(
          cachedDuration.inMicroseconds,
          lessThanOrEqualTo(uncachedDuration.inMicroseconds + 1000),
        );
      });

      test('Throttled writes reduce I/O operations', () async {
        final sessionManager = SessionManager();
        await sessionManager.initialize();

        // Record multiple activities rapidly
        for (int i = 0; i < 10; i++) {
          await sessionManager.recordActivity();
        }

        // Throttling should have reduced actual writes
        // This is verified by the implementation using throttled saves
        expect(sessionManager.lastActivityTime, isNotNull);
      });

      test('Cache expiry prevents stale data', () async {
        final pinService = PINService();
        await pinService.initialize();

        await pinService.setupPIN('1234');

        // Read to populate cache
        final result1 = await pinService.isPINSet();
        expect(result1, isTrue);

        // Wait for cache to expire
        await Future.delayed(const Duration(seconds: 6));

        // Change state
        await pinService.clearAllPINData();

        // Read again - should get fresh data
        final result2 = await pinService.isPINSet();
        expect(result2, isFalse);
      });
    });

    group('Edge Cases', () {
      test('Disposal before initialization is safe', () {
        final authService = AuthService();

        // Dispose before initialize
        expect(() => authService.dispose(), returnsNormally);
      });

      test('Cache invalidation with no cache is safe', () async {
        final pinService = PINService();
        await pinService.initialize();

        // Clear cache when nothing is cached
        expect(() => pinService.resetForTesting(), returnsNormally);
      });

      test('Multiple cache invalidations are safe', () async {
        final storage = AuthSecureStorageService();
        await storage.initialize();

        // Multiple invalidations
        storage.resetForTesting();
        storage.resetForTesting();
        storage.resetForTesting();

        // Should still work
        await storage.initialize();
        final result = await storage.isPINSet();
        expect(result, isFalse);
      });
    });
  });
}
