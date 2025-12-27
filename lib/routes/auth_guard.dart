import 'package:flutter/material.dart';
import '../services/auth/auth_service.dart';

/// Route guard for authentication
/// 
/// This class provides route protection by checking authentication status
/// before allowing navigation to protected routes.
/// 
/// Implements Requirements:
/// - 1.4: PIN başarıyla doğrulandığında kullanıcı oturumu başlatmalı
/// - 4.4: Biyometrik doğrulama başarılı olduğunda kullanıcı oturumu başlatmalı
/// - 6.3: Uygulama tekrar açıldığında kimlik doğrulama gerektirmeli
class AuthGuard {
  static final AuthGuard _instance = AuthGuard._internal();
  factory AuthGuard() => _instance;
  AuthGuard._internal();

  final AuthService _authService = AuthService();

  /// Checks if the user is authenticated
  /// 
  /// Returns true if authenticated, false otherwise
  Future<bool> isAuthenticated() async {
    return await _authService.isAuthenticated();
  }

  /// Checks if sensitive authentication is required
  /// 
  /// Returns true if sensitive auth is required, false otherwise
  Future<bool> requiresSensitiveAuth() async {
    return await _authService.requiresSensitiveAuth();
  }

  /// Guards a route by checking authentication status
  /// 
  /// [context] - Build context for navigation
  /// [builder] - Widget builder for the protected route
  /// [requiresSensitive] - Whether sensitive authentication is required
  /// 
  /// Returns the protected widget or navigates to login screen
  Future<Widget> guardRoute({
    required BuildContext context,
    required WidgetBuilder builder,
    bool requiresSensitive = false,
  }) async {
    final isAuth = await isAuthenticated();
    
    if (!context.mounted) return const SizedBox.shrink();

    if (!isAuth) {
      // Not authenticated - navigate to login
      return _buildAuthScreen(context, builder, 'Giriş Yapın');
    }
    
    if (requiresSensitive) {
      final needsSensitiveAuth = await requiresSensitiveAuth();
      if (!context.mounted) return const SizedBox.shrink();
      
      if (needsSensitiveAuth) {
        // Sensitive auth required - navigate to login
        return _buildAuthScreen(context, builder, 'Hassas İşlem Doğrulaması');
      }
    }
    
    // Authenticated - allow access
    if (!context.mounted) {
      return const SizedBox.shrink();
    }
    return builder(context);
  }

  Widget _buildAuthScreen(BuildContext context, WidgetBuilder builder, String title) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Devam etmek için doğrulama gerekli'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final authService = AuthService();
                final result = await authService.authenticateWithBiometric();
                if (result.isSuccess && context.mounted) {
                   Navigator.of(context).pushReplacement(
                     MaterialPageRoute(builder: builder),
                   );
                }
              },
              child: const Text('Doğrula'),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a route with authentication guard
  /// 
  /// [builder] - Widget builder for the protected route
  /// [requiresSensitive] - Whether sensitive authentication is required
  /// 
  /// Returns a MaterialPageRoute with authentication guard
  Route<dynamic> createGuardedRoute({
    required WidgetBuilder builder,
    bool requiresSensitive = false,
    RouteSettings? settings,
  }) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => FutureBuilder<Widget>(
        future: guardRoute(
          context: context,
          builder: builder,
          requiresSensitive: requiresSensitive,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Hata: ${snapshot.error}'),
              ),
            );
          }
          
          return snapshot.data ?? const SizedBox.shrink();
        },
      ),
    );
  }
}

/// Route guard middleware for checking authentication before navigation
/// 
/// This class can be used as a navigation observer to intercept
/// route changes and enforce authentication requirements.
class AuthGuardMiddleware extends NavigatorObserver {
  final AuthService _authService = AuthService();
  
  /// List of routes that require authentication
  final Set<String> _protectedRoutes = {
    '/home',
    '/settings',
    '/security-settings',
    '/transactions',
    '/wallets',
    '/categories',
    '/goals',
    '/debts',
    '/credit-cards',
    '/bills',
    '/recurring',
    '/statistics',
    '/reports',
  };
  
  /// List of routes that require sensitive authentication
  final Set<String> _sensitiveRoutes = {
    '/security-settings',
    '/export',
    '/backup',
  };

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _checkRouteAuth(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _checkRouteAuth(newRoute);
    }
  }

  /// Checks if the route requires authentication
  Future<void> _checkRouteAuth(Route<dynamic> route) async {
    final routeName = route.settings.name;
    
    if (routeName == null) return;
    
    // Check if route is protected
    if (_protectedRoutes.contains(routeName)) {
      final isAuth = await _authService.isAuthenticated();
      
      if (!isAuth) {
        // Not authenticated - should navigate to login
        // This is handled by the route guard in the route builder
        debugPrint('Route $routeName requires authentication');
      }
    }
    
    // Check if route requires sensitive auth
    if (_sensitiveRoutes.contains(routeName)) {
      final needsSensitiveAuth = await _authService.requiresSensitiveAuth();
      
      if (needsSensitiveAuth) {
        debugPrint('Route $routeName requires sensitive authentication');
      }
    }
  }

  /// Adds a protected route
  void addProtectedRoute(String routeName) {
    _protectedRoutes.add(routeName);
  }

  /// Adds a sensitive route
  void addSensitiveRoute(String routeName) {
    _sensitiveRoutes.add(routeName);
  }

  /// Removes a protected route
  void removeProtectedRoute(String routeName) {
    _protectedRoutes.remove(routeName);
  }

  /// Removes a sensitive route
  void removeSensitiveRoute(String routeName) {
    _sensitiveRoutes.remove(routeName);
  }
}
