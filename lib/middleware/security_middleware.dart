import 'package:flutter/material.dart';
import '../services/auth/auth_service.dart';
import '../services/auth/sensitive_operation_service.dart';
import '../models/security/security_models.dart';
import '../models/security/sensitive_operation_models.dart';

/// Security middleware for screen-level security controls
/// 
/// This middleware provides:
/// - Sensitive screen identification
/// - Security level checking
/// - Additional authentication requirements
/// - Integration with auth guard and sensitive operation service
/// 
/// Implements Requirements:
/// - 8.1: Para transferi yapıldığında ek kimlik doğrulama gerektirmeli
/// - 8.2: Güvenlik ayarları değiştirildiğinde PIN ve biyometrik doğrulama gerektirmeli
/// - 8.4: Hesap bilgileri görüntülendiğinde son 5 dakika içinde doğrulama gerektirmeli
/// - 8.5: Export işlemi yapıldığında tam kimlik doğrulama gerektirmeli
class SecurityMiddleware {
  static final SecurityMiddleware _instance = SecurityMiddleware._internal();
  factory SecurityMiddleware() => _instance;
  SecurityMiddleware._internal();

  final AuthService _authService = AuthService();
  final SensitiveOperationService _sensitiveOperationService = SensitiveOperationService();
  
  bool _isInitialized = false;

  /// Initializes the security middleware
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _authService.initialize();
      await _sensitiveOperationService.initialize();
      
      _isInitialized = true;
      debugPrint('Security Middleware initialized successfully');
    } catch (e) {
      throw Exception('Failed to initialize Security Middleware: ${e.toString()}');
    }
  }

  /// Checks if a screen requires security validation
  /// 
  /// [screenName] - Name of the screen to check
  /// [context] - Additional context about the screen
  /// 
  /// Returns true if the screen is sensitive and requires validation
  Future<bool> requiresSecurityCheck(
    String screenName, {
    Map<String, dynamic>? context,
  }) async {
    await _ensureInitialized();
    
    // Check if screen is marked as sensitive
    final isSensitive = _sensitiveOperationService.isSensitiveScreen(
      screenName,
      context: context,
    );
    
    if (!isSensitive) {
      return false;
    }
    
    // Determine operation type from screen
    final operationType = _sensitiveOperationService.getOperationTypeFromScreen(
      screenName,
      context: context,
    );
    
    if (operationType == null) {
      return false;
    }
    
    // Check if authentication is required for this operation
    return await _sensitiveOperationService.requiresAuthentication(
      operationType,
      context: context,
    );
  }

  /// Gets the required security level for a screen
  /// 
  /// [screenName] - Name of the screen
  /// [context] - Additional context about the screen
  /// 
  /// Returns the required security level, or null if not a sensitive screen
  Future<OperationSecurityLevel?> getRequiredSecurityLevel(
    String screenName, {
    Map<String, dynamic>? context,
  }) async {
    await _ensureInitialized();
    
    final operationType = _sensitiveOperationService.getOperationTypeFromScreen(
      screenName,
      context: context,
    );
    
    if (operationType == null) {
      return null;
    }
    
    return await _sensitiveOperationService.getRequiredSecurityLevel(
      operationType,
      context: context,
    );
  }

  /// Validates security requirements before allowing screen access
  /// 
  /// [screenName] - Name of the screen to validate
  /// [context] - Additional context about the screen
  /// [authMethod] - Preferred authentication method
  /// [pin] - PIN code if using PIN authentication
  /// [twoFactorCode] - Two-factor code if required
  /// 
  /// Returns validation result
  Future<SecurityValidationResult> validateScreenAccess(
    String screenName, {
    Map<String, dynamic>? context,
    AuthMethod authMethod = AuthMethod.biometric,
    String? twoFactorCode,
  }) async {
    await _ensureInitialized();
    
    try {
      // Check if screen requires security validation
      final requiresCheck = await requiresSecurityCheck(screenName, context: context);
      
      if (!requiresCheck) {
        // Screen doesn't require additional security
        return SecurityValidationResult.success(
          screenName: screenName,
          securityLevel: OperationSecurityLevel.standard,
        );
      }
      
      // Get operation type
      final operationType = _sensitiveOperationService.getOperationTypeFromScreen(
        screenName,
        context: context,
      );
      
      if (operationType == null) {
        return SecurityValidationResult.failure(
          screenName: screenName,
          errorMessage: 'İşlem türü belirlenemedi',
        );
      }
      
      // Perform authentication for the operation
      final operationResult = await _sensitiveOperationService.authenticateForOperation(
        operationType,
        context: context,
        authMethod: authMethod,
        twoFactorCode: twoFactorCode,
      );
      
      if (operationResult.isSuccess) {
        return SecurityValidationResult.success(
          screenName: screenName,
          securityLevel: operationResult.securityLevel,
          authMethod: operationResult.authMethod,
          metadata: operationResult.metadata,
        );
      } else {
        return SecurityValidationResult.failure(
          screenName: screenName,
          securityLevel: operationResult.securityLevel,
          errorMessage: operationResult.errorMessage,
          remainingAttempts: operationResult.remainingAttempts,
          lockoutDuration: operationResult.lockoutDuration,
        );
      }
    } catch (e) {
      debugPrint('Screen access validation error: $e');
      return SecurityValidationResult.failure(
        screenName: screenName,
        errorMessage: 'Güvenlik doğrulaması sırasında hata oluştu: ${e.toString()}',
      );
    }
  }

  /// Wraps a screen widget with security validation
  /// 
  /// [screenName] - Name of the screen
  /// [builder] - Widget builder for the screen
  /// [context] - Additional context about the screen
  /// [onAuthRequired] - Callback when authentication is required
  /// 
  /// Returns a widget that enforces security requirements
  Widget wrapWithSecurity({
    required String screenName,
    required WidgetBuilder builder,
    Map<String, dynamic>? context,
    VoidCallback? onAuthRequired,
  }) {
    return FutureBuilder<bool>(
      future: requiresSecurityCheck(screenName, context: context),
      builder: (buildContext, snapshot) {
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
              child: Text('Güvenlik kontrolü hatası: ${snapshot.error}'),
            ),
          );
        }
        
        final requiresCheck = snapshot.data ?? false;
        
        if (requiresCheck) {
          // Authentication required - show auth screen
          onAuthRequired?.call();
          
          return Scaffold(
            appBar: AppBar(title: const Text('Doğrulama Gerekli')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bu işlemi gerçekleştirmek için doğrulama gerekli'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      // Trigger authentication
                      final result = await validateScreenAccess(screenName, context: context);
                      if (result.isSuccess && buildContext.mounted) {
                         Navigator.of(buildContext).pushReplacement(
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
        
        // No additional security required - show the screen
        return builder(buildContext);
      },
    );
  }

  /// Creates a route with security middleware
  /// 
  /// [screenName] - Name of the screen
  /// [builder] - Widget builder for the screen
  /// [context] - Additional context about the screen
  /// [settings] - Route settings
  /// 
  /// Returns a MaterialPageRoute with security middleware
  Route<dynamic> createSecureRoute({
    required String screenName,
    required WidgetBuilder builder,
    Map<String, dynamic>? context,
    RouteSettings? settings,
  }) {
    return MaterialPageRoute(
      settings: settings,
      builder: (buildContext) => wrapWithSecurity(
        screenName: screenName,
        builder: builder,
        context: context,
      ),
    );
  }

  /// Checks if a screen is marked as sensitive
  /// 
  /// [screenName] - Name of the screen to check
  /// [context] - Additional context about the screen
  /// 
  /// Returns true if the screen is sensitive
  bool isSensitiveScreen(String screenName, {Map<String, dynamic>? context}) {
    return _sensitiveOperationService.isSensitiveScreen(screenName, context: context);
  }

  /// Gets the operation type for a screen
  /// 
  /// [screenName] - Name of the screen
  /// [context] - Additional context about the screen
  /// 
  /// Returns the operation type, or null if not a sensitive screen
  SensitiveOperationType? getOperationTypeForScreen(
    String screenName, {
    Map<String, dynamic>? context,
  }) {
    return _sensitiveOperationService.getOperationTypeFromScreen(
      screenName,
      context: context,
    );
  }

  /// Resets the middleware for testing
  @visibleForTesting
  void resetForTesting() {
    _isInitialized = false;
  }

  // Private helper methods

  /// Ensures the middleware is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}

/// Result of security validation
class SecurityValidationResult {
  /// Whether validation was successful
  final bool isSuccess;
  
  /// Name of the screen being validated
  final String screenName;
  
  /// Required security level
  final OperationSecurityLevel? securityLevel;
  
  /// Authentication method used
  final AuthMethod? authMethod;
  
  /// Error message if validation failed
  final String? errorMessage;
  
  /// Remaining authentication attempts
  final int? remainingAttempts;
  
  /// Lockout duration if account is locked
  final Duration? lockoutDuration;
  
  /// Additional metadata
  final Map<String, dynamic>? metadata;

  const SecurityValidationResult({
    required this.isSuccess,
    required this.screenName,
    this.securityLevel,
    this.authMethod,
    this.errorMessage,
    this.remainingAttempts,
    this.lockoutDuration,
    this.metadata,
  });

  /// Creates a successful validation result
  factory SecurityValidationResult.success({
    required String screenName,
    required OperationSecurityLevel securityLevel,
    AuthMethod? authMethod,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityValidationResult(
      isSuccess: true,
      screenName: screenName,
      securityLevel: securityLevel,
      authMethod: authMethod,
      metadata: metadata,
    );
  }

  /// Creates a failed validation result
  factory SecurityValidationResult.failure({
    required String screenName,
    OperationSecurityLevel? securityLevel,
    String? errorMessage,
    int? remainingAttempts,
    Duration? lockoutDuration,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityValidationResult(
      isSuccess: false,
      screenName: screenName,
      securityLevel: securityLevel,
      errorMessage: errorMessage,
      remainingAttempts: remainingAttempts,
      lockoutDuration: lockoutDuration,
      metadata: metadata,
    );
  }

  @override
  String toString() {
    return 'SecurityValidationResult(isSuccess: $isSuccess, screenName: $screenName, '
           'securityLevel: $securityLevel, errorMessage: $errorMessage)';
  }
}

/// Navigator observer for automatic security checking
/// 
/// This observer automatically checks security requirements when
/// navigating to screens and enforces authentication if needed.
class SecurityNavigatorObserver extends NavigatorObserver {
  final SecurityMiddleware _middleware = SecurityMiddleware();
  
  /// Map of screen names to their security configurations
  final Map<String, ScreenSecurityConfig> _screenConfigs = {};

  /// Registers a screen with security configuration
  void registerScreen(String screenName, ScreenSecurityConfig config) {
    _screenConfigs[screenName] = config;
  }

  /// Unregisters a screen
  void unregisterScreen(String screenName) {
    _screenConfigs.remove(screenName);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _checkRouteSecurity(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _checkRouteSecurity(newRoute);
    }
  }

  /// Checks security requirements for a route
  Future<void> _checkRouteSecurity(Route<dynamic> route) async {
    final routeName = route.settings.name;
    
    if (routeName == null) return;
    
    // Check if we have a security config for this screen
    final config = _screenConfigs[routeName];
    
    if (config == null) {
      // Try to determine if it's a sensitive screen
      final isSensitive = _middleware.isSensitiveScreen(routeName);
      
      if (isSensitive) {
        debugPrint('Route $routeName is sensitive but not configured');
      }
      return;
    }
    
    // Check if security validation is required
    final requiresCheck = await _middleware.requiresSecurityCheck(
      routeName,
      context: config.context,
    );
    
    if (requiresCheck) {
      debugPrint('Route $routeName requires security validation');
      config.onSecurityRequired?.call();
    }
  }
}

/// Screen security configuration
class ScreenSecurityConfig {
  /// Screen name
  final String screenName;
  
  /// Additional context for security checks
  final Map<String, dynamic>? context;
  
  /// Callback when security validation is required
  final VoidCallback? onSecurityRequired;
  
  /// Whether to enforce security automatically
  final bool enforceAutomatically;

  const ScreenSecurityConfig({
    required this.screenName,
    this.context,
    this.onSecurityRequired,
    this.enforceAutomatically = true,
  });
}
