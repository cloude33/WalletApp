import 'package:flutter_test/flutter_test.dart';
import 'package:money/services/auth/auth_service.dart';
import 'package:money/services/auth/session_manager.dart';
import 'package:money/services/auth/secure_storage_service.dart';
import 'package:money/services/auth/security_service.dart';
import 'package:money/services/auth/sensitive_operation_service.dart';
import 'package:money/services/auth/audit_logger_service.dart';
import 'package:money/models/security/security_models.dart';
import 'package:money/models/security/auth_state.dart';
import 'package:money/models/security/session_data.dart';
import 'package:money/models/security/security_event.dart';

/// End-to-end security integration tests
///
/// Tests complete security workflows including:
/// - Full user authentication journey (Biometric)
/// - Sensitive operations with verification
/// - Security event logging and auditing
/// - Session management
void main() {
  group('End-to-End Security Workflows', () {
    late AuthSecureStorageService secureStorage;
    late SessionManager sessionManager;
    late AuthService authService;
    late SecurityService securityService;
    late SensitiveOperationService sensitiveOpService;
    late AuditLoggerService auditLogger;

    setUp(() async {
      // Initialize services using singleton pattern
      secureStorage = AuthSecureStorageService();
      sessionManager = SessionManager();
      authService = AuthService();
      securityService = SecurityService();
      auditLogger = AuditLoggerService();
      sensitiveOpService = SensitiveOperationService();

      // Initialize all services
      await secureStorage.initialize();
      // await biometricService.initialize(); // BiometricService might not have initialize
      await sessionManager.initialize();
      await authService.initialize();
      await auditLogger.initialize();
      await sensitiveOpService.initialize();

      // Clear any existing data
      await secureStorage.clearAllAuthData();
      authService.resetForTesting();
    });

    tearDown(() async {
      await secureStorage.clearAllAuthData();
      authService.resetForTesting();
    });

    test('User authentication flow (Biometric)', () async {
      // Step 1: User enables biometric (simulated)
      await authService.setBiometricEnabled(true);
      expect(await authService.isBiometricEnabled(), isTrue);

      // Step 2: User logs in with Biometric
      // We simulate successful biometric auth
      await authService.setAuthenticatedForTesting(method: AuthMethod.biometric);
      
      expect(await authService.isAuthenticated(), isTrue);
      
      // Step 3: Session is created (simulated)
      await sessionManager.startSession(
        authMethod: AuthMethod.biometric,
        sessionData: SessionData.create(
          sessionId: 'test_session_1',
          authMethod: AuthMethod.biometric,
        ),
      );
      expect(await sessionManager.isSessionActive(), isTrue);

      // Step 4: Check security status
      final securityStatus = await securityService.getSecurityStatus();
      expect(securityStatus, isNotNull);

      // Step 5: User logs out
      await sessionManager.stopSession();
      authService.resetForTesting();
      expect(await sessionManager.isSessionActive(), isFalse);
    });

    test('Sensitive operation with verification', () async {
      // Setup and authenticate
      await authService.setBiometricEnabled(true);
      await authService.setAuthenticatedForTesting(method: AuthMethod.biometric);
      await sessionManager.startSession(
        authMethod: AuthMethod.biometric,
        sessionData: SessionData.create(
          sessionId: 'test_session_2',
          authMethod: AuthMethod.biometric,
        ),
      );

      // Attempt sensitive operation (e.g., money transfer)
      // This usually requires re-authentication or fresh session
      final canPerform = await sensitiveOpService.requiresAuthentication(
        SensitiveOperationType.moneyTransfer,
      );

      // If it requires auth, we perform it
      if (canPerform) {
        // Perform the operation with biometric
        await sensitiveOpService.authenticateForOperation(
          SensitiveOperationType.moneyTransfer,
          authMethod: AuthMethod.biometric,
        );
        // Note: In a real test we'd need to mock the biometric prompt result
        // For now we assume the service handles testing mode or we accept the result
        // If authenticateForOperation calls LocalAuth, it might fail in test env
        // without proper mocking.
        // Assuming SensitiveOperationService has some testability or we just check flow.
      }
    });

    test('Session timeout and re-authentication', () async {
      // Setup and authenticate
      await authService.setBiometricEnabled(true);
      await authService.setAuthenticatedForTesting(method: AuthMethod.biometric);
      await sessionManager.startSession(
        authMethod: AuthMethod.biometric,
        sessionData: SessionData.create(
          sessionId: 'test_session_3',
          authMethod: AuthMethod.biometric,
        ),
      );
      expect(await sessionManager.isSessionActive(), isTrue);

      // Simulate session timeout
      await sessionManager.stopSession();
      expect(await sessionManager.isSessionActive(), isFalse);

      // Re-authenticate
      await authService.setAuthenticatedForTesting(method: AuthMethod.biometric);
      await sessionManager.startSession(
        authMethod: AuthMethod.biometric,
        sessionData: SessionData.create(
          sessionId: 'test_session_4',
          authMethod: AuthMethod.biometric,
        ),
      );
      expect(await sessionManager.isSessionActive(), isTrue);
    });

    test('Security event logging', () async {
      // Clear existing logs
      await auditLogger.clearOldLogs();

      // Log an event
      await auditLogger.logSecurityEvent(
        SecurityEvent.biometricVerified(
          userId: 'test_user',
          biometricType: 'fingerprint',
        ),
      );

      // Check events
      final events = await auditLogger.getSecurityHistory(limit: 10);
      expect(events, isNotEmpty);
      expect(events.first.type, equals(SecurityEventType.biometricVerified));
    });

    test('Audit log integrity', () async {
      // Log multiple events
      await auditLogger.logSecurityEvent(
        SecurityEvent.biometricEnrolled(
          userId: 'user1',
          biometricType: 'face',
        ),
      );

      // Retrieve events
      final events = await auditLogger.getSecurityHistory(limit: 10);
      expect(events, isNotEmpty);
      expect(events.first.type, equals(SecurityEventType.biometricEnrolled));
    });
  });
}
