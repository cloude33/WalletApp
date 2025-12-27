import 'package:flutter/material.dart';
import 'auth_guard.dart';

/// Example usage of AuthGuard for protecting routes
///
/// This file demonstrates various ways to use the authentication
/// guard to protect routes in the application.

// Example 1: Using guardRoute directly
class ProtectedScreenExample extends StatelessWidget {
  const ProtectedScreenExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: AuthGuard().guardRoute(
        context: context,
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Protected Screen')),
          body: const Center(child: Text('This is protected content')),
        ),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        return snapshot.data ?? const SizedBox.shrink();
      },
    );
  }
}

// Example 2: Using createGuardedRoute for navigation
class NavigationExample extends StatelessWidget {
  const NavigationExample({super.key});

  void _navigateToProtectedScreen(BuildContext context) {
    final route = AuthGuard().createGuardedRoute(
      builder: (context) => const ProtectedScreenExample(),
      settings: const RouteSettings(name: '/protected'),
    );

    Navigator.push(context, route);
  }

  void _navigateToSensitiveScreen(BuildContext context) {
    final route = AuthGuard().createGuardedRoute(
      builder: (context) => const SensitiveScreenExample(),
      requiresSensitive: true,
      settings: const RouteSettings(name: '/sensitive'),
    );

    Navigator.push(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _navigateToProtectedScreen(context),
              child: const Text('Go to Protected Screen'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _navigateToSensitiveScreen(context),
              child: const Text('Go to Sensitive Screen'),
            ),
          ],
        ),
      ),
    );
  }
}

// Example 3: Sensitive operation screen
class SensitiveScreenExample extends StatelessWidget {
  const SensitiveScreenExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensitive Operation')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'This screen requires additional authentication',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Example 4: Using AuthGuardMiddleware in MaterialApp
class AppWithAuthGuardExample extends StatelessWidget {
  const AppWithAuthGuardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final authGuardMiddleware = AuthGuardMiddleware();

    // Add custom protected routes
    authGuardMiddleware.addProtectedRoute('/custom-protected');
    authGuardMiddleware.addSensitiveRoute('/custom-sensitive');

    return MaterialApp(
      title: 'Auth Guard Example',
      navigatorObservers: [authGuardMiddleware],
      home: const NavigationExample(),
      routes: {
        '/protected': (context) => const ProtectedScreenExample(),
        '/sensitive': (context) => const SensitiveScreenExample(),
      },
    );
  }
}

// Example 5: Checking authentication status manually
class AuthStatusExample extends StatefulWidget {
  const AuthStatusExample({super.key});

  @override
  State<AuthStatusExample> createState() => _AuthStatusExampleState();
}

class _AuthStatusExampleState extends State<AuthStatusExample> {
  final AuthGuard _authGuard = AuthGuard();
  bool _isAuthenticated = false;
  bool _requiresSensitiveAuth = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isAuth = await _authGuard.isAuthenticated();
    final needsSensitive = await _authGuard.requiresSensitiveAuth();

    setState(() {
      _isAuthenticated = isAuth;
      _requiresSensitiveAuth = needsSensitive;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auth Status')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Authenticated: $_isAuthenticated',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Requires Sensitive Auth: $_requiresSensitiveAuth',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _checkAuthStatus,
              child: const Text('Refresh Status'),
            ),
          ],
        ),
      ),
    );
  }
}
