import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/security/security_models.dart';
import 'auth_test_helper.dart';
import 'test_setup.dart';

void main() {
  setUpAll(() async {
    await TestSetup.initializeTestEnvironment();
  });

  tearDownAll(() async {
    await TestSetup.cleanupTestEnvironment();
  });

  setUp(() async {
    await TestSetup.setupTest();
  });

  tearDown(() async {
    AuthTestHelper.cleanupAuthService();
    await TestSetup.tearDownTest();
  });

  group('AuthService Basic Tests', () {
    test('should create AuthService instance', () async {
      final authService = await AuthTestHelper.initializeAuthService();
      expect(authService, isNotNull);
    });

    test('should have correct initial state', () async {
      final authService = await AuthTestHelper.initializeAuthService();
      expect(authService.currentAuthState.isAuthenticated, isFalse);
      expect(authService.currentAuthState.sessionId, isNull);
      expect(authService.currentSession, isNull);
    });

    test('should create auth state models correctly', () {
      // Test AuthState model
      final authState = AuthState.authenticated(
        sessionId: 'test-session',
        authMethod: AuthMethod.biometric,
      );
      
      expect(authState.isAuthenticated, isTrue);
      expect(authState.sessionId, equals('test-session'));
      expect(authState.authMethod, equals(AuthMethod.biometric));
    });

    test('should create session data models correctly', () {
      // Test SessionData model
      final sessionData = SessionData.create(
        sessionId: 'test-session',
        authMethod: AuthMethod.biometric,
      );
      
      expect(sessionData.sessionId, equals('test-session'));
      expect(sessionData.authMethod, equals(AuthMethod.biometric));
      expect(sessionData.isActive, isTrue);
    });

    test('should handle auth method enum correctly', () {
      expect(AuthMethod.values, contains(AuthMethod.biometric));
      expect(AuthMethod.values, contains(AuthMethod.twoFactor));
      expect(AuthMethod.values, contains(AuthMethod.securityQuestions));
    });
  });
}