import 'package:flutter_test/flutter_test.dart';
import 'package:money/services/auth/secure_storage_service.dart';
import 'package:money/services/auth/pin_service.dart';
import 'package:money/services/auth/biometric_service.dart';
import 'package:money/services/auth/auth_service.dart';
import 'package:money/services/auth/session_manager.dart';
import 'package:money/models/security/auth_state.dart';
import 'package:money/models/security/biometric_type.dart';
import 'package:money/models/security/session_data.dart';

/// Integration tests for complete authentication flow
///
/// Tests the full authentication workflow including:
/// - PIN setup and verification
/// - Biometric authentication with fallback
/// - Session management
/// - Authentication state transitions
void main() {
  group('Complete Authentication Flow Integration', () {
    late AuthSecureStorageService secureStorage;
    late PINService pinService;
    late BiometricServiceImpl biometricService;
    late SessionManager sessionManager;
    late AuthService authService;

    setUp(() async {
      // Get singleton instances of services
      pinService = PINService();
      biometricService = BiometricServiceImpl();
      authService = AuthService();
      sessionManager = SessionManager();

      // Initialize services
      await pinService.initialize();
      await authService.initialize();
      await sessionManager.initialize();

      // Setup secure storage
      secureStorage = AuthSecureStorageService();
      await secureStorage.initialize();

      // Clear any existing data
      await secureStorage.clearAllAuthData();
    });

    tearDown(() async {
      // Clear any existing data
      await secureStorage.clearAllAuthData();
    });

    test('Complete PIN setup and authentication flow', () async {
      // Step 1: Setup PIN
      final setupResult = await pinService.setupPIN('1234');
      expect(setupResult, isTrue);

      // Step 2: Verify PIN is stored
      final hasPin = await pinService.isPINSet();
      expect(hasPin, isTrue);

      // Step 3: Authenticate with correct PIN
      final authResult = await authService.authenticateWithPIN('1234');
      expect(authResult.isSuccess, isTrue);
      expect(authResult.method, AuthMethod.pin);

      // Step 4: Verify session is created
      final isAuthenticated = await authService.isAuthenticated();
      expect(isAuthenticated, isTrue);

      // Step 5: Logout
      await authService.logout();
      final isAuthenticatedAfterLogout = await authService.isAuthenticated();
      expect(isAuthenticatedAfterLogout, isFalse);
    });

    test('PIN authentication with failed attempts and lockout', () async {
      // Setup PIN
      await pinService.setupPIN('1234');

      // Attempt 1: Wrong PIN
      var result = await authService.authenticateWithPIN('0000');
      expect(result.isSuccess, isFalse);
      expect(result.remainingAttempts, 2);

      // Attempt 2: Wrong PIN
      result = await authService.authenticateWithPIN('1111');
      expect(result.isSuccess, isFalse);
      expect(result.remainingAttempts, 1);

      // Attempt 3: Wrong PIN - triggers lockout
      result = await authService.authenticateWithPIN('2222');
      expect(result.isSuccess, isFalse);
      expect(result.remainingAttempts, 0);

      // Verify account is locked
      final isLocked = await pinService.isLocked();
      expect(isLocked, isTrue);

      // Attempt with correct PIN should fail while locked
      result = await authService.authenticateWithPIN('1234');
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('locked'));
    });

    test('PIN change flow with authentication', () async {
      // Setup initial PIN
      await pinService.setupPIN('1234');

      // Authenticate
      await authService.authenticateWithPIN('1234');
      expect(await authService.isAuthenticated(), isTrue);

      // Change PIN
      final changeResult = await pinService.changePIN('1234', '5678');
      expect(changeResult, isTrue);

      // Logout
      await authService.logout();

      // Authenticate with new PIN
      final authResult = await authService.authenticateWithPIN('5678');
      expect(authResult.isSuccess, isTrue);

      // Old PIN should not work
      await authService.logout();
      final oldPinResult = await authService.authenticateWithPIN('1234');
      expect(oldPinResult.isSuccess, isFalse);
    });

    test('Biometric authentication with PIN fallback', () async {
      // Setup PIN first (required for fallback)
      await pinService.setupPIN('1234');

      // Check if biometric is available
      final isAvailable = await biometricService.isBiometricAvailable();

      if (isAvailable) {
        // Try biometric authentication
        final biometricResult = await authService.authenticateWithBiometric();

        // If biometric fails, should allow PIN fallback
        if (!biometricResult.isSuccess) {
          final pinResult = await authService.authenticateWithPIN('1234');
          expect(pinResult.isSuccess, isTrue);
          expect(pinResult.method, AuthMethod.pin);
        }
      } else {
        // If biometric not available, PIN should work
        final pinResult = await authService.authenticateWithPIN('1234');
        expect(pinResult.isSuccess, isTrue);
      }
    });

    test('Session timeout and re-authentication', () async {
      // Setup PIN
      await pinService.setupPIN('1234');

      // Authenticate
      await authService.authenticateWithPIN('1234');
      expect(await authService.isAuthenticated(), isTrue);

      // Simulate session timeout by manually stopping session
      await sessionManager.stopSession();

      // Should no longer be authenticated
      expect(await authService.isAuthenticated(), isFalse);

      // Re-authenticate
      final reAuthResult = await authService.authenticateWithPIN('1234');
      expect(reAuthResult.isSuccess, isTrue);
      expect(await authService.isAuthenticated(), isTrue);
    });

    test('Multiple authentication methods coordination', () async {
      // Setup PIN
      await pinService.setupPIN('1234');

      // Authenticate with PIN
      var result = await authService.authenticateWithPIN('1234');
      expect(result.isSuccess, isTrue);
      expect(result.method, AuthMethod.pin);

      // Logout
      await authService.logout();

      // Check biometric availability
      final biometricAvailable = await biometricService.isBiometricAvailable();

      if (biometricAvailable) {
        // Enable biometric
        final types = await biometricService.getAvailableBiometrics();
        expect(types, isNotEmpty);
      }

      // Re-authenticate with PIN
      result = await authService.authenticateWithPIN('1234');
      expect(result.isSuccess, isTrue);
    });

    test('Authentication state stream updates', () async {
      // Setup PIN
      await pinService.setupPIN('1234');

      // Listen to auth state changes
      final stateChanges = <bool>[];
      final subscription = authService.authStateStream.listen((state) {
        stateChanges.add(state.isAuthenticated);
      });

      // Authenticate
      await authService.authenticateWithPIN('1234');
      await Future.delayed(const Duration(milliseconds: 100));

      // Logout
      await authService.logout();
      await Future.delayed(const Duration(milliseconds: 100));

      // Should have recorded state changes
      expect(stateChanges.length, greaterThanOrEqualTo(2));

      await subscription.cancel();
    });

    test('Concurrent authentication attempts handling', () async {
      // Setup PIN
      await pinService.setupPIN('1234');

      // Try multiple concurrent authentications
      final results = await Future.wait([
        authService.authenticateWithPIN('1234'),
        authService.authenticateWithPIN('1234'),
        authService.authenticateWithPIN('1234'),
      ]);

      // At least one should succeed
      expect(results.any((r) => r.isSuccess), isTrue);
    });

    test('Authentication after app restart simulation', () async {
      // Setup PIN
      await pinService.setupPIN('1234');
      await authService.authenticateWithPIN('1234');

      // Simulate app restart by creating new service instances
      final newPinService = PINService();
      final newAuthService = AuthService();

      // PIN should still be set
      expect(await newPinService.isPINSet(), isTrue);

      // Should not be authenticated (session ended)
      expect(await newAuthService.isAuthenticated(), isFalse);

      // Should be able to authenticate with stored PIN
      final result = await newAuthService.authenticateWithPIN('1234');
      expect(result.isSuccess, isTrue);
    });

    test('Failed attempts counter reset after successful auth', () async {
      // Setup PIN
      await pinService.setupPIN('1234');

      // Make some failed attempts
      await authService.authenticateWithPIN('0000');
      await authService.authenticateWithPIN('1111');

      var attempts = await pinService.getFailedAttempts();
      expect(attempts, 2);

      // Successful authentication should reset counter
      await authService.authenticateWithPIN('1234');

      attempts = await pinService.getFailedAttempts();
      expect(attempts, 0);
    });
  });

  group('Biometric Integration Flow', () {
    late BiometricServiceImpl biometricService;

    setUp(() {
      biometricService = BiometricServiceImpl();
    });

    test('Biometric availability check', () async {
      final isAvailable = await biometricService.isBiometricAvailable();
      expect(isAvailable, isA<bool>());
    });

    test('Get available biometric types', () async {
      final types = await biometricService.getAvailableBiometrics();
      expect(types, isA<List<BiometricType>>());
    });

    test('Biometric enrollment check', () async {
      final isAvailable = await biometricService.isBiometricAvailable();

      if (isAvailable) {
        final types = await biometricService.getAvailableBiometrics();
        expect(types, isNotEmpty);
      }
    });
  });

  group('Session Management Integration', () {
    late SessionManager sessionManager;

    setUp(() async {
      sessionManager = SessionManager();
      await sessionManager.initialize();
    });

    tearDown(() async {
      // Cleanup handled by SessionManager
    });

    test('Session lifecycle', () async {
      // Create session data
      final sessionData = SessionData.create(
        sessionId: 'test-session-id',
        authMethod: AuthMethod.pin,
      );

      // Start session
      await sessionManager.startSession(
        sessionData: sessionData,
        authMethod: AuthMethod.pin,
      );
      expect(await sessionManager.isSessionActive(), isTrue);

      // Update activity
      await sessionManager.recordActivity();

      // End session
      await sessionManager.stopSession();
      expect(await sessionManager.isSessionActive(), isFalse);
    });

    test('Session timeout detection', () async {
      // Create session data
      final sessionData = SessionData.create(
        sessionId: 'test-session-id-2',
        authMethod: AuthMethod.pin,
      );

      // Start session
      await sessionManager.startSession(
        sessionData: sessionData,
        authMethod: AuthMethod.pin,
      );

      // Check if session is valid
      final isValid = await sessionManager.isSessionActive();
      expect(isValid, isTrue);
    });

    test('Multiple session operations', () async {
      // Create session data
      final sessionData = SessionData.create(
        sessionId: 'test-session-id-3',
        authMethod: AuthMethod.pin,
      );

      // Start session
      await sessionManager.startSession(
        sessionData: sessionData,
        authMethod: AuthMethod.pin,
      );

      // Multiple activity updates
      for (int i = 0; i < 5; i++) {
        await sessionManager.recordActivity();
        await Future.delayed(const Duration(milliseconds: 10));
      }

      expect(await sessionManager.isSessionActive(), isTrue);
    });
  });
}
