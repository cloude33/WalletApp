import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/routes/auth_guard.dart';
import 'package:money/services/auth/auth_service.dart';
import 'package:money/services/auth/pin_service.dart';

void main() {
  group('AuthGuard', () {
    late AuthGuard authGuard;
    late AuthService authService;
    late PINService pinService;

    setUp(() async {
      authGuard = AuthGuard();
      authService = AuthService();
      pinService = PINService();
      
      // Reset services for testing
      authService.resetForTesting();
      pinService.resetForTesting();
      
      // Initialize services
      await authService.initialize();
      await pinService.initialize();
    });

    tearDown(() {
      authService.resetForTesting();
      pinService.resetForTesting();
    });

    test('isAuthenticated returns false when not authenticated', () async {
      final result = await authGuard.isAuthenticated();
      expect(result, false);
    });

    test('isAuthenticated returns true after successful authentication', () async {
      // Setup PIN
      await pinService.setupPIN('1234');
      
      // Authenticate
      await authService.authenticateWithPIN('1234');
      
      // Check authentication
      final result = await authGuard.isAuthenticated();
      expect(result, true);
    });

    test('requiresSensitiveAuth returns true when not authenticated', () async {
      final result = await authGuard.requiresSensitiveAuth();
      expect(result, true);
    });

    test('requiresSensitiveAuth returns false immediately after authentication', () async {
      // Setup PIN
      await pinService.setupPIN('1234');
      
      // Authenticate
      await authService.authenticateWithPIN('1234');
      
      // Check sensitive auth requirement
      final result = await authGuard.requiresSensitiveAuth();
      expect(result, false);
    });

    testWidgets('guardRoute returns login screen when not authenticated', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return FutureBuilder<Widget>(
                future: authGuard.guardRoute(
                  context: context,
                  builder: (context) => const Scaffold(
                    body: Text('Protected Content'),
                  ),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  return snapshot.data ?? const SizedBox.shrink();
                },
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show PIN login screen
      expect(find.text('Protected Content'), findsNothing);
    });

    testWidgets('guardRoute returns protected content when authenticated', (tester) async {
      // Setup PIN and authenticate
      await pinService.setupPIN('1234');
      await authService.authenticateWithPIN('1234');

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return FutureBuilder<Widget>(
                future: authGuard.guardRoute(
                  context: context,
                  builder: (context) => const Scaffold(
                    body: Text('Protected Content'),
                  ),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  return snapshot.data ?? const SizedBox.shrink();
                },
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show protected content
      expect(find.text('Protected Content'), findsOneWidget);
    });
  });

  group('AuthGuardMiddleware', () {
    late AuthGuardMiddleware middleware;

    setUp(() {
      middleware = AuthGuardMiddleware();
    });

    test('addProtectedRoute adds route to protected routes', () {
      middleware.addProtectedRoute('/test-route');
      // No direct way to verify, but should not throw
    });

    test('addSensitiveRoute adds route to sensitive routes', () {
      middleware.addSensitiveRoute('/test-sensitive');
      // No direct way to verify, but should not throw
    });

    test('removeProtectedRoute removes route from protected routes', () {
      middleware.addProtectedRoute('/test-route');
      middleware.removeProtectedRoute('/test-route');
      // No direct way to verify, but should not throw
    });

    test('removeSensitiveRoute removes route from sensitive routes', () {
      middleware.addSensitiveRoute('/test-sensitive');
      middleware.removeSensitiveRoute('/test-sensitive');
      // No direct way to verify, but should not throw
    });
  });
}
