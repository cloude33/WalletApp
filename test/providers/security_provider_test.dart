import 'package:flutter_test/flutter_test.dart';
import 'package:parion/providers/security_provider.dart';
import 'package:parion/models/security/auth_state.dart';
import 'package:parion/models/security/security_event.dart';
import 'package:parion/models/security/security_models.dart';

void main() {
  // Initialize Flutter bindings for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecurityProvider', () {
    late SecurityProvider provider;

    setUp(() {
      // Create a fresh instance for each test
      provider = SecurityProvider();
      provider.resetForTesting();
    });

    tearDown(() {
      // Don't dispose singleton, just reset it
      provider.resetForTesting();
    });

    test('should initialize successfully', () async {
      await provider.initialize();
      
      expect(provider.isInitialized, isTrue);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.authState.isAuthenticated, isFalse);
    });

    test('should have unauthenticated state initially', () {
      expect(provider.isAuthenticated, isFalse);
      expect(provider.authState, equals(AuthState.unauthenticated()));
      expect(provider.sessionData, isNull);
    });

    test('should provide security event stream', () {
      expect(provider.securityEventStream, isNotNull);
    });

    test('should provide auth state stream', () {
      expect(provider.authStateStream, isNotNull);
    });

    test('should track loading state', () async {
      expect(provider.isLoading, isFalse);
      
      // Loading state is managed internally during operations
      // We can verify it exists and is accessible
      expect(() => provider.isLoading, returnsNormally);
    });

    test('should track error messages', () {
      expect(provider.errorMessage, isNull);
      
      // Error messages are set during failed operations
      // We can verify the getter exists and is accessible
      expect(() => provider.errorMessage, returnsNormally);
    });

    test('should provide recent events list', () {
      expect(provider.recentEvents, isEmpty);
      expect(provider.recentEvents, isA<List<SecurityEvent>>());
    });

    test('should provide security config getter', () {
      expect(() => provider.securityConfig, returnsNormally);
    });

    test('should handle authentication check when not initialized', () async {
      final isAuthenticated = await provider.checkAuthentication();
      
      // Should initialize automatically and return false for unauthenticated state
      expect(isAuthenticated, isFalse);
      expect(provider.isInitialized, isTrue);
    });

    test('should handle sensitive auth check when not initialized', () async {
      final requiresAuth = await provider.requiresSensitiveAuth();
      
      // Should initialize automatically and return true (requires auth)
      expect(requiresAuth, isTrue);
      expect(provider.isInitialized, isTrue);
    });

    test('should broadcast security events when logged', () async {
      await provider.initialize();
      
      final events = <SecurityEvent>[];
      final subscription = provider.securityEventStream.listen(events.add);
      
      final testEvent = SecurityEvent.biometricEnrolled(
        userId: 'test_user',
        biometricType: 'face',
        metadata: {'test': true},
      );
      
      await provider.logSecurityEvent(testEvent);
      
      // Wait for stream to process
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(events, isNotEmpty);
      expect(events.first.type, equals(SecurityEventType.biometricEnrolled));
      
      await subscription.cancel();
    });

    test('should add logged events to recent events list', () async {
      await provider.initialize();
      
      final testEvent = SecurityEvent.biometricVerified(
        userId: 'test_user',
        biometricType: 'face',
      );
      
      await provider.logSecurityEvent(testEvent);
      
      expect(provider.recentEvents, isNotEmpty);
      expect(provider.recentEvents.first.type, equals(SecurityEventType.biometricVerified));
    });

    test('should limit recent events to 50', () async {
      await provider.initialize();
      
      // Add more than 50 events
      for (int i = 0; i < 60; i++) {
        await provider.logSecurityEvent(
          SecurityEvent.biometricVerified(userId: 'user_$i', biometricType: 'face'),
        );
      }
      
      expect(provider.recentEvents.length, equals(50));
    });

    test('should handle app background lifecycle', () async {
      await provider.initialize();
      
      // Should not throw
      await provider.onAppBackground();
      expect(() => provider.onAppBackground(), returnsNormally);
    });

    test('should handle app foreground lifecycle', () async {
      await provider.initialize();
      
      // Should not throw
      await provider.onAppForeground();
      expect(() => provider.onAppForeground(), returnsNormally);
    });

    test('should reset state for testing', () async {
      await provider.initialize();
      
      // Add some state
      await provider.logSecurityEvent(
        SecurityEvent.biometricEnrolled(userId: 'test', biometricType: 'fingerprint'),
      );
      
      // Reset
      provider.resetForTesting();
      
      expect(provider.isInitialized, isFalse);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.recentEvents, isEmpty);
      expect(provider.sessionData, isNull);
      expect(provider.errorMessage, isNull);
    });

    test('should provide singleton instance', () {
      final instance1 = SecurityProviderSingleton.instance;
      final instance2 = SecurityProviderSingleton.instance;
      
      expect(instance1, equals(instance2));
    });

    test('should allow setting custom instance for testing', () {
      final customProvider = SecurityProvider();
      SecurityProviderSingleton.setInstance(customProvider);
      
      expect(SecurityProviderSingleton.instance, equals(customProvider));
      
      // Cleanup
      SecurityProviderSingleton.reset();
    });
  });

  group('SecurityProvider - Integration', () {
    late SecurityProvider provider;

    setUp(() {
      provider = SecurityProvider();
      provider.resetForTesting();
    });

    tearDown(() {
      provider.resetForTesting();
    });

    test('should handle initialization and provide access to services', () async {
      await provider.initialize();
      
      expect(provider.isInitialized, isTrue);
      expect(provider.authState, isNotNull);
      expect(provider.recentEvents, isNotNull);
    });

    test('should notify listeners on state changes', () async {
      await provider.initialize();
      
      int notificationCount = 0;
      provider.addListener(() {
        notificationCount++;
      });
      
      // Trigger a state change by logging an event
      await provider.logSecurityEvent(
        SecurityEvent.biometricEnrolled(
          userId: 'test',
          biometricType: 'face',
        ),
      );
      
      expect(notificationCount, greaterThan(0));
    });

    test('should handle logout gracefully', () async {
      await provider.initialize();
      
      // Should not throw even when not authenticated
      await provider.logout();
      
      expect(provider.isAuthenticated, isFalse);
    });
  });
}
