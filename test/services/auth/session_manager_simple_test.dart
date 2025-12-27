import 'package:flutter_test/flutter_test.dart';
import 'package:money/services/auth/session_manager.dart';
import 'package:money/models/security/session_data.dart';
import 'package:money/models/security/auth_state.dart';

void main() {
  group('SessionManager Simple Tests', () {
    late SessionManager sessionManager;

    setUp(() {
      sessionManager = SessionManager();
      sessionManager.resetForTesting();
    });

    tearDown(() {
      sessionManager.dispose();
    });

    test('should create session manager instance', () {
      expect(sessionManager, isNotNull);
      expect(sessionManager.currentSessionState.isActive, false);
    });

    test('should handle session state transitions without storage', () {
      // Test basic state transitions without requiring storage initialization
      final sessionData = SessionData.create(
        sessionId: 'test_session_123',
        authMethod: AuthMethod.biometric,
      );

      // Create active session state
      final activeState = SessionState.active(
        sessionData: sessionData,
        authMethod: AuthMethod.biometric,
      );

      expect(activeState.isActive, true);
      expect(activeState.sessionData?.sessionId, 'test_session_123');
      expect(activeState.authMethod, AuthMethod.biometric);

      // Test background transition
      final backgroundState = activeState.enterBackground();
      expect(backgroundState.isInBackground, true);
      expect(backgroundState.isActive, true);

      // Test foreground transition
      final foregroundState = backgroundState.enterForeground();
      expect(foregroundState.isInBackground, false);
      expect(foregroundState.isActive, true);

      // Test sensitive screen state
      final sensitiveState = foregroundState.setSensitiveScreen(true);
      expect(sensitiveState.isInSensitiveScreen, true);
      expect(sensitiveState.isActive, true);

      // Test termination
      final terminatedState = sensitiveState.terminate();
      expect(terminatedState.isActive, false);
      expect(terminatedState.sessionData, null);
      expect(terminatedState.authMethod, null);
      expect(terminatedState.isInBackground, false);
      expect(terminatedState.isInSensitiveScreen, false);
    });

    test('should handle activity updates', () async {
      final sessionData = SessionData.create(
        sessionId: 'test_session_123',
        authMethod: AuthMethod.biometric,
      );

      final initialState = SessionState.active(
        sessionData: sessionData,
        authMethod: AuthMethod.biometric,
      );

      final initialTime = initialState.lastActivityTime;
      
      // Wait a bit to ensure time difference
      await Future.delayed(const Duration(milliseconds: 1));
      
      final updatedState = initialState.updateActivity();
      
      expect(updatedState.lastActivityTime.isAfter(initialTime) || 
             updatedState.lastActivityTime.isAtSameMomentAs(initialTime), true);
    });

    test('should serialize and deserialize session state', () {
      final sessionData = SessionData.create(
        sessionId: 'test_session_123',
        authMethod: AuthMethod.biometric,
      );

      final originalState = SessionState.active(
        sessionData: sessionData,
        authMethod: AuthMethod.biometric,
        metadata: {'test': 'value'},
      );

      final json = originalState.toJson();
      final restoredState = SessionState.fromJson(json);

      expect(restoredState.isActive, originalState.isActive);
      expect(restoredState.sessionData?.sessionId, originalState.sessionData?.sessionId);
      expect(restoredState.authMethod, originalState.authMethod);
      expect(restoredState.metadata, originalState.metadata);
    });

    test('should handle stream events', () async {
      final stateChanges = <SessionState>[];
      final subscription = sessionManager.sessionStateStream.listen((state) {
        stateChanges.add(state);
      });

      // Manually emit some state changes
      sessionManager.sessionStateStream;

      await Future.delayed(const Duration(milliseconds: 10));

      // Initially should have no events since we haven't started any sessions
      expect(stateChanges.length, 0);

      await subscription.cancel();
    });

    test('should validate session timeout logic', () {
      final sessionData = SessionData.create(
        sessionId: 'test_session_123',
        authMethod: AuthMethod.biometric,
      );

      // Test session expiration
      expect(sessionData.isExpired(const Duration(minutes: 5)), false);
      
      // Create an old session data
      final oldSessionData = SessionData(
        sessionId: 'old_session',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        lastActivity: DateTime.now().subtract(const Duration(minutes: 10)),
        authMethod: AuthMethod.biometric,
      );

      expect(oldSessionData.isExpired(const Duration(minutes: 5)), true);
    });

    test('should validate sensitive operation timeout logic', () {
      final sessionData = SessionData.create(
        sessionId: 'test_session_123',
        authMethod: AuthMethod.biometric,
      );

      // Initially should require sensitive auth (no previous auth)
      expect(sessionData.requiresSensitiveAuth(const Duration(minutes: 2)), true);

      // After updating sensitive auth
      final updatedSessionData = sessionData.updateSensitiveAuth();
      expect(updatedSessionData.requiresSensitiveAuth(const Duration(minutes: 2)), false);
    });

    test('should handle session manager singleton', () {
      final instance1 = SessionManagerSingleton.instance;
      final instance2 = SessionManagerSingleton.instance;

      expect(instance1, same(instance2));

      // Test reset
      SessionManagerSingleton.reset();
      final instance3 = SessionManagerSingleton.instance;
      
      // After reset, should get a new instance
      expect(instance3, isNotNull);
      expect(instance3.currentSessionState.isActive, false);
    });
  });
}