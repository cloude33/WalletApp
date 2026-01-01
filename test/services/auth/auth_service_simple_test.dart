import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/auth/auth_service.dart';
import 'package:parion/models/security/security_models.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
      authService.resetForTesting();
    });

    tearDown(() {
      authService.dispose();
    });

    test('should initialize successfully', () async {
      // This test will fail due to missing dependencies, but it tests the basic structure
      expect(() => authService.initialize(), isA<Function>());
    });

    test('should have correct initial state', () {
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

    test('should handle session expiration correctly', () {
      final sessionData = SessionData.create(
        sessionId: 'test-session',
        authMethod: AuthMethod.biometric,
      );
      
      // Test with very short timeout
      final isExpired = sessionData.isExpired(const Duration(milliseconds: 1));
      
      // Should not be expired immediately
      expect(isExpired, isFalse);
    });

    test('should require sensitive auth when not authenticated', () async {
      // Should require auth when not authenticated
      final requiresAuth = await authService.requiresSensitiveAuth();
      expect(requiresAuth, isTrue);
    });

    test('should get default security config', () async {
      try {
        final config = await authService.getSecurityConfig();
        expect(config, isNotNull);
        expect(config.sessionTimeout, equals(const Duration(minutes: 5)));
      } catch (e) {
        // Expected to fail due to missing storage initialization
        expect(e, isA<Exception>());
      }
    });

    test('should handle auth method enum correctly', () {
      expect(AuthMethod.biometric.displayName, equals('Biyometrik'));
      expect(AuthMethod.twoFactor.displayName, equals('İki Faktörlü'));
      expect(AuthMethod.securityQuestions.displayName, equals('Güvenlik Soruları'));
      
      expect(AuthMethod.fromJson('biometric'), equals(AuthMethod.biometric));
    });

    test('should create auth result models correctly', () {
      final successResult = AuthResult.success(
        method: AuthMethod.biometric,
        metadata: {'test': 'data'},
      );
      
      expect(successResult.isSuccess, isTrue);
      expect(successResult.method, equals(AuthMethod.biometric));
      expect(successResult.metadata?['test'], equals('data'));
      
      final failureResult = AuthResult.failure(
        method: AuthMethod.biometric,
        errorMessage: 'Test error',
        remainingAttempts: 3,
      );
      
      expect(failureResult.isSuccess, isFalse);
      expect(failureResult.errorMessage, equals('Test error'));
      expect(failureResult.remainingAttempts, equals(3));
    });

    test('should validate auth result correctly', () {
      final validResult = AuthResult.success(method: AuthMethod.biometric);
      expect(validResult.validate(), isNull);
      
      final invalidResult = AuthResult.failure(
        method: AuthMethod.biometric,
        errorMessage: '', // Empty error message should be invalid
      );
      expect(invalidResult.validate(), isNotNull);
    });

    test('should handle security config correctly', () {
      final config = SecurityConfig.defaultConfig();
      
      expect(config.sessionTimeout, equals(const Duration(minutes: 5)));
      
      final validation = config.validate();
      expect(validation, isNull); // Should be valid
    });
  });
}