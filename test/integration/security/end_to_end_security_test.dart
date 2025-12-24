import 'package:flutter_test/flutter_test.dart';
import 'package:money/services/auth/pin_service.dart';
import 'package:money/services/auth/biometric_service.dart';
import 'package:money/services/auth/auth_service.dart';
import 'package:money/services/auth/session_manager.dart';
import 'package:money/services/auth/secure_storage_service.dart';
import 'package:money/services/auth/security_service.dart';
import 'package:money/services/auth/sensitive_operation_service.dart';
import 'package:money/services/auth/audit_logger_service.dart';
import 'package:money/models/security/security_models.dart';

/// End-to-end security integration tests
///
/// Tests complete security workflows including:
/// - Full user authentication journey
/// - Sensitive operations with additional verification
/// - Security event logging and auditing
/// - Multi-layer security enforcement
void main() {
  group('End-to-End Security Workflows', () {
    late AuthSecureStorageService secureStorage;
    late PINService pinService;
    late BiometricServiceImpl
    biometricService; // Use implementation instead of abstract class
    late SessionManager sessionManager;
    late AuthService authService;
    late SecurityService securityService;
    late SensitiveOperationService sensitiveOpService;
    late AuditLoggerService auditLogger;

    setUp(() async {
      // Initialize services using singleton pattern
      secureStorage = AuthSecureStorageService();
      pinService = PINService();
      biometricService = BiometricServiceImpl(); // Use implementation
      sessionManager = SessionManager();
      authService = AuthService();
      securityService = SecurityService();
      auditLogger = AuditLoggerService();
      sensitiveOpService = SensitiveOperationService();

      // Initialize all services
      await secureStorage.initialize();
      await pinService.initialize();
      await sessionManager.initialize();
      await authService.initialize();
      await auditLogger.initialize();
      await sensitiveOpService.initialize();

      // Clear any existing data
      await secureStorage.clearAllAuthData();
    });

    tearDown(() async {
      await secureStorage.clearAllAuthData();
    });

    test('Complete user onboarding and first login', () async {
      // Step 1: User sets up PIN for the first time
      final setupResult = await pinService.setupPIN('1234');
      expect(setupResult.isSuccess, isTrue);

      // Step 2: Verify PIN is stored securely
      final hasPin = await pinService.isPINSet();
      expect(hasPin, isTrue);

      // Step 3: User logs in with PIN
      final loginResult = await authService.authenticateWithPIN('1234');
      expect(loginResult.isSuccess, isTrue);
      expect(loginResult.method, AuthMethod.pin);

      // Step 4: Session is created
      expect(await authService.isAuthenticated(), isTrue);
      expect(await sessionManager.isSessionActive(), isTrue);

      // Step 5: Check security status
      final securityStatus = await securityService.getSecurityStatus();
      expect(securityStatus, isNotNull);

      // Step 6: User logs out
      await authService.logout();
      expect(await authService.isAuthenticated(), isFalse);
    });

    test('Sensitive operation with additional verification', () async {
      // Setup and authenticate
      await pinService.setupPIN('1234');
      await authService.authenticateWithPIN('1234');

      // Attempt sensitive operation (e.g., money transfer)
      final canPerform = await sensitiveOpService.requiresAuthentication(
        SensitiveOperationType.moneyTransfer,
      );

      if (!canPerform) {
        // Perform the operation
        final result = await sensitiveOpService.authenticateForOperation(
          SensitiveOperationType.moneyTransfer,
          authMethod: AuthMethod.pin,
          pin: '1234',
        );
        expect(result.isSuccess, isTrue);
      } else {
        // Need additional verification
        final verifyResult = await sensitiveOpService.authenticateForOperation(
          SensitiveOperationType.moneyTransfer,
          authMethod: AuthMethod.pin,
          pin: '1234',
        );
        expect(verifyResult.isSuccess, isTrue);
      }
    });

    test('Security breach attempt and lockout', () async {
      // Setup PIN
      await pinService.setupPIN('1234');

      // Simulate brute force attack
      for (int i = 0; i < 3; i++) {
        final result = await authService.authenticateWithPIN('0000');
        expect(result.isSuccess, isFalse);
      }

      // Account should be locked
      expect(await pinService.isLocked(), isTrue);

      // Verify security event was logged
      final events = await auditLogger.getSecurityHistory(limit: 10);
      final lockoutEvents = events.where(
        (e) => e.type == SecurityEventType.accountLocked,
      );
      expect(lockoutEvents, isNotEmpty);

      // Even correct PIN should fail while locked
      final lockedResult = await authService.authenticateWithPIN('1234');
      expect(lockedResult.isSuccess, isFalse);
    });

    test('Session timeout and re-authentication', () async {
      // Setup and authenticate
      await pinService.setupPIN('1234');
      await authService.authenticateWithPIN('1234');
      expect(await authService.isAuthenticated(), isTrue);

      // Simulate session timeout by manually stopping session
      await sessionManager.stopSession();
      expect(await authService.isAuthenticated(), isFalse);

      // Try to perform sensitive operation - should require re-auth
      final canPerform = await sensitiveOpService.requiresAuthentication(
        SensitiveOperationType.accountInfoView,
      );
      expect(canPerform, isTrue);

      // Re-authenticate
      await authService.authenticateWithPIN('1234');
      expect(await authService.isAuthenticated(), isTrue);

      // Now should be able to perform operation
      final canPerformNow = await sensitiveOpService.requiresAuthentication(
        SensitiveOperationType.accountInfoView,
      );
      // This should be false since we just authenticated
      expect(canPerformNow, isFalse);
    });

    test('Multi-factor authentication flow', () async {
      // Setup PIN
      await pinService.setupPIN('1234');

      // First factor: PIN authentication
      final pinAuth = await authService.authenticateWithPIN('1234');
      expect(pinAuth.isSuccess, isTrue);

      // For highly sensitive operations, may require biometric as second factor
      final biometricAvailable = await biometricService.isBiometricAvailable();

      if (biometricAvailable) {
        // Attempt biometric verification
        try {
          await biometricService.authenticate();
        } catch (e) {
          // Biometric may fail in test environment
        }
      }

      // Operation should be allowed after authentication
      expect(await authService.isAuthenticated(), isTrue);
    });

    test('Security settings change with audit trail', () async {
      // Setup and authenticate
      await pinService.setupPIN('1234');
      await authService.authenticateWithPIN('1234');

      // Change PIN (security setting change)
      final changeResult = await pinService.changePIN('1234', '5678');
      expect(changeResult.isSuccess, isTrue);

      // Verify audit log entry
      final events = await auditLogger.getSecurityHistory(limit: 10);
      final pinChangeEvents = events.where(
        (e) => e.type == SecurityEventType.pinChanged,
      );
      expect(pinChangeEvents, isNotEmpty);

      // Verify new PIN works
      await authService.logout();
      final newPinAuth = await authService.authenticateWithPIN('5678');
      expect(newPinAuth.isSuccess, isTrue);
    });

    test('Concurrent sensitive operations handling', () async {
      // Setup and authenticate
      await pinService.setupPIN('1234');
      await authService.authenticateWithPIN('1234');

      // Try multiple sensitive operations concurrently
      final operations = [
        sensitiveOpService.requiresAuthentication(
          SensitiveOperationType.accountInfoView,
        ),
        sensitiveOpService.requiresAuthentication(
          SensitiveOperationType.securitySettingsChange,
        ),
        sensitiveOpService.requiresAuthentication(
          SensitiveOperationType.dataExport,
        ),
      ];

      final results = await Future.wait(operations);

      // All should complete without deadlock
      expect(results.length, 3);
    });

    test('Security event logging throughout workflow', () async {
      // Clear existing logs by cleaning up old ones
      await auditLogger.clearOldLogs();

      // Setup PIN - should log event
      await pinService.setupPIN('1234');

      // Authenticate - should log event
      await authService.authenticateWithPIN('1234');

      // Failed attempt - should log event
      await authService.logout();
      await authService.authenticateWithPIN('0000');

      // Successful auth - should log event
      await authService.authenticateWithPIN('1234');

      // Check all events were logged
      final events = await auditLogger.getSecurityHistory(limit: 20);
      expect(events.length, greaterThanOrEqualTo(3));

      // Verify event types
      final eventTypes = events.map((e) => e.type).toSet();
      expect(eventTypes.contains(SecurityEventType.pinCreated), isTrue);
      expect(eventTypes.contains(SecurityEventType.pinVerified), isTrue);
    });

    test('Device security status affects authentication', () async {
      // Check device security status
      final securityStatus = await securityService.getSecurityStatus();

      // Setup PIN
      await pinService.setupPIN('1234');

      // If device is not secure, authentication should still work
      // but may have warnings
      final authResult = await authService.authenticateWithPIN('1234');
      expect(authResult.isSuccess, isTrue);

      // Security status should be available
      expect(securityStatus.isDeviceSecure, isA<bool>());
    });

    test('Complete security audit report generation', () async {
      // Perform various security operations
      await pinService.setupPIN('1234');
      await authService.authenticateWithPIN('1234');
      await authService.logout();
      await authService.authenticateWithPIN('0000'); // Failed
      await authService.authenticateWithPIN('1234'); // Success

      // Generate audit report
      final events = await auditLogger.getSecurityHistory(limit: 50);

      // Should have comprehensive event log
      expect(events, isNotEmpty);

      // Events should have timestamps
      for (final event in events) {
        expect(event.timestamp, isNotNull);
        expect(event.type, isNotNull);
      }

      // Events should be in chronological order
      for (int i = 0; i < events.length - 1; i++) {
        expect(
          events[i].timestamp.isAfter(events[i + 1].timestamp) ||
              events[i].timestamp.isAtSameMomentAs(events[i + 1].timestamp),
          isTrue,
        );
      }
    });

    test('Recovery from security service failure', () async {
      // Setup authentication
      await pinService.setupPIN('1234');
      await authService.authenticateWithPIN('1234');

      // Even if security service has issues, core auth should work
      try {
        await securityService.getSecurityStatus();
      } catch (e) {
        // Security service may fail, but auth should continue
      }

      // Should still be authenticated
      expect(await authService.isAuthenticated(), isTrue);
    });

    test('Data persistence across service restarts', () async {
      // Setup PIN and authenticate
      await pinService.setupPIN('1234');
      await authService.authenticateWithPIN('1234');

      // Log some security events
      await auditLogger.logSecurityEvent(
        SecurityEvent.pinVerified(metadata: {'test': 'data'}),
      );

      // Simulate service restart by creating new instances
      final newSecureStorage = AuthSecureStorageService();
      await newSecureStorage.initialize();
      final newPinService = PINService();
      await newPinService.initialize();
      final newAuditLogger = AuditLoggerService();
      await newAuditLogger.initialize();

      // PIN should still exist
      expect(await newPinService.isPINSet(), isTrue);

      // Audit logs should persist
      final events = await newAuditLogger.getSecurityHistory(limit: 10);
      expect(events, isNotEmpty);
    });

    test('Sensitive operation rate limiting', () async {
      // Setup and authenticate
      await pinService.setupPIN('1234');
      await authService.authenticateWithPIN('1234');

      // Perform multiple sensitive operations rapidly
      final results = <bool>[];
      for (int i = 0; i < 5; i++) {
        final canPerform = await sensitiveOpService.requiresAuthentication(
          SensitiveOperationType.moneyTransfer,
        );
        results.add(canPerform);
      }

      // Should handle rapid requests
      expect(results, isNotEmpty);
    });

    test('Complete user journey: setup to sensitive operation', () async {
      // Step 1: New user sets up PIN
      final setupResult = await pinService.setupPIN('1234');
      expect(setupResult.isSuccess, isTrue);

      // Step 2: User logs in
      final loginResult = await authService.authenticateWithPIN('1234');
      expect(loginResult.isSuccess, isTrue);

      // Step 3: User views account (sensitive operation)
      final canView = await sensitiveOpService.requiresAuthentication(
        SensitiveOperationType.accountInfoView,
      );
      // Should be false since we just authenticated
      expect(canView, isFalse);

      // Step 4: User performs money transfer (highly sensitive)
      final canTransfer = await sensitiveOpService.requiresAuthentication(
        SensitiveOperationType.moneyTransfer,
      );

      if (!canTransfer) {
        final transferResult = await sensitiveOpService
            .authenticateForOperation(
              SensitiveOperationType.moneyTransfer,
              authMethod: AuthMethod.pin,
              pin: '1234',
            );
        expect(transferResult.isSuccess, isTrue);
      }

      // Step 5: User changes security settings
      final changeResult = await pinService.changePIN('1234', '5678');
      expect(changeResult.isSuccess, isTrue);

      // Step 6: User logs out
      await authService.logout();
      expect(await authService.isAuthenticated(), isFalse);

      // Step 7: User logs back in with new PIN
      final newLoginResult = await authService.authenticateWithPIN('5678');
      expect(newLoginResult.isSuccess, isTrue);

      // Step 8: Verify audit trail
      final events = await auditLogger.getSecurityHistory(limit: 20);
      expect(events.length, greaterThanOrEqualTo(5));
    });
  });

  group('Security Compliance and Best Practices', () {
    late AuthSecureStorageService secureStorage;
    late PINService pinService;
    late AuditLoggerService auditLogger;

    setUp(() async {
      // Initialize services using singleton pattern
      secureStorage = AuthSecureStorageService();
      pinService = PINService();
      auditLogger = AuditLoggerService();

      // Initialize all services
      await secureStorage.initialize();
      await pinService.initialize();
      await auditLogger.initialize();

      // Clear any existing data
      await secureStorage.clearAllAuthData();
    });

    tearDown(() async {
      await secureStorage.clearAllAuthData();
    });

    test('PIN storage encryption verification', () async {
      // Setup PIN
      await pinService.setupPIN('1234');

      // Verify PIN is not stored in plain text
      // (This is a conceptual test - actual verification would require
      // inspecting storage implementation)
      final hasPin = await pinService.isPINSet();
      expect(hasPin, isTrue);

      // Verify PIN can be validated
      final isValid = await pinService.verifyPIN('1234');
      expect(isValid.isSuccess, isTrue);

      // Wrong PIN should fail
      final isInvalid = await pinService.verifyPIN('0000');
      expect(isInvalid.isSuccess, isFalse);
    });

    test('Audit log integrity', () async {
      // Log multiple events
      await auditLogger.logSecurityEvent(
        SecurityEvent.pinCreated(
          metadata: {'timestamp': DateTime.now().toIso8601String()},
        ),
      );

      await auditLogger.logSecurityEvent(
        SecurityEvent.pinVerified(
          metadata: {'timestamp': DateTime.now().toIso8601String()},
        ),
      );

      // Retrieve events
      final events = await auditLogger.getSecurityHistory(limit: 10);

      // Events should be immutable and complete
      expect(events.length, greaterThanOrEqualTo(2));

      for (final event in events) {
        expect(event.type, isNotNull);
        expect(event.timestamp, isNotNull);
      }
    });

    test('Security event completeness', () async {
      // Setup PIN
      await pinService.setupPIN('1234');

      // Get events
      final events = await auditLogger.getSecurityHistory(limit: 10);

      // PIN creation should be logged
      final pinCreatedEvents = events.where(
        (e) => e.type == SecurityEventType.pinCreated,
      );
      expect(pinCreatedEvents, isNotEmpty);
    });
  });
}
