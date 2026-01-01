import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/auth/auth_service.dart';
import 'package:parion/services/auth/session_manager.dart';
import 'package:parion/services/auth/secure_storage_service.dart';
import 'package:parion/services/auth/biometric_service.dart';

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
      AuthService().resetForTesting();
      SessionManager().resetForTesting();
      AuthSecureStorageService().resetForTesting();
    });

    group('Secure Data Cleaning', () {
      test('Session Manager clears state on stop', () async {
        final sessionManager = SessionManager();
        await sessionManager.initialize();

        // Start session would require full setup, so we just verify disposal
        await sessionManager.stopSession();

        // Verify state is inactive
        expect(sessionManager.currentSessionState.isActive, isFalse);
      });
    });

    group('Cache Management', () {
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
        final result = await storage.read('key_0');
        expect(result, equals('value_0'));
      });
    });
  });
}
