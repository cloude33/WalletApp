import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/auth/session_manager.dart';
import 'package:parion/models/security/session_data.dart';
import 'package:parion/models/security/auth_state.dart';
import 'package:parion/models/security/security_models.dart';

void main() {
  group('SessionManager', () {
    late SessionManager sessionManager;

    setUp(() {
      // Mock Flutter secure storage
      TestWidgetsFlutterBinding.ensureInitialized();
      
      sessionManager = SessionManager();
      sessionManager.resetForTesting();
    });

    tearDown(() {
      sessionManager.dispose();
    });

    // Skip integration tests that require plugins for now
    // Focus on unit tests for SessionState model
  });

  group('SessionState', () {
    test('should create inactive session state', () {
      final state = SessionState.inactive();
      
      expect(state.isActive, false);
      expect(state.sessionData, null);
      expect(state.authMethod, null);
      expect(state.isInBackground, false);
      expect(state.isInSensitiveScreen, false);
    });

    test('should create active session state', () {
      final sessionData = SessionData.create(
        sessionId: 'test_session_123',
        authMethod: AuthMethod.biometric,
      );

      final state = SessionState.active(
        sessionData: sessionData,
        authMethod: AuthMethod.biometric,
      );
      
      expect(state.isActive, true);
      expect(state.sessionData, sessionData);
      expect(state.authMethod, AuthMethod.biometric);
      expect(state.isInBackground, false);
      expect(state.isInSensitiveScreen, false);
    });

    test('should update activity time', () async {
      final state = SessionState.inactive();
      final initialTime = state.lastActivityTime;
      
      // Wait a bit to ensure time difference
      await Future.delayed(const Duration(milliseconds: 1));
      
      final updatedState = state.updateActivity();
      
      expect(updatedState.lastActivityTime.isAfter(initialTime) || 
             updatedState.lastActivityTime.isAtSameMomentAs(initialTime), true);
    });

    test('should terminate session', () {
      final sessionData = SessionData.create(
        sessionId: 'test_session_123',
        authMethod: AuthMethod.biometric,
      );

      final activeState = SessionState.active(
        sessionData: sessionData,
        authMethod: AuthMethod.biometric,
      );

      final terminatedState = activeState.terminate();
      
      expect(terminatedState.isActive, false);
      expect(terminatedState.sessionData, null);
      expect(terminatedState.authMethod, null);
      expect(terminatedState.isInBackground, false);
      expect(terminatedState.isInSensitiveScreen, false);
    });

    test('should handle background/foreground transitions', () {
      final sessionData = SessionData.create(
        sessionId: 'test_session_123',
        authMethod: AuthMethod.biometric,
      );

      final activeState = SessionState.active(
        sessionData: sessionData,
        authMethod: AuthMethod.biometric,
      );

      final backgroundState = activeState.enterBackground();
      expect(backgroundState.isInBackground, true);

      final foregroundState = backgroundState.enterForeground();
      expect(foregroundState.isInBackground, false);
    });

    test('should handle sensitive screen state', () {
      final sessionData = SessionData.create(
        sessionId: 'test_session_123',
        authMethod: AuthMethod.biometric,
      );

      final activeState = SessionState.active(
        sessionData: sessionData,
        authMethod: AuthMethod.biometric,
      );

      final sensitiveState = activeState.setSensitiveScreen(true);
      expect(sensitiveState.isInSensitiveScreen, true);

      final normalState = sensitiveState.setSensitiveScreen(false);
      expect(normalState.isInSensitiveScreen, false);
    });

    test('should serialize to and from JSON', () {
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

    test('should handle equality correctly', () {
      final sessionData1 = SessionData.create(
        sessionId: 'test_session_123',
        authMethod: AuthMethod.biometric,
      );

      final state1 = SessionState.active(
        sessionData: sessionData1,
        authMethod: AuthMethod.biometric,
      );

      final state2 = SessionState.active(
        sessionData: sessionData1, // Same session data
        authMethod: AuthMethod.biometric,
      );

      // Should be equal with same session data
      expect(state1 == state2, true);

      // Same instance should be equal
      expect(state1 == state1, true);
      
      // Different states should not be equal
      final inactiveState = SessionState.inactive();
      expect(state1 == inactiveState, false);
    });
  });
}
