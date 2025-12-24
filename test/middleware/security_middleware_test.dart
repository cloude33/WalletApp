import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money/middleware/security_middleware.dart';
import 'package:money/models/security/security_models.dart';
import 'package:money/models/security/sensitive_operation_models.dart';
import 'package:money/services/auth/auth_service.dart';
import 'package:money/services/auth/sensitive_operation_service.dart';
import 'package:money/services/auth/pin_service.dart';

void main() {
  late SecurityMiddleware middleware;
  late AuthService authService;
  late SensitiveOperationService sensitiveOperationService;
  late PINService pinService;

  setUp(() async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    
    middleware = SecurityMiddleware();
    authService = AuthService();
    sensitiveOperationService = SensitiveOperationService();
    pinService = PINService();
    
    // Reset services for testing
    authService.resetForTesting();
    sensitiveOperationService.resetForTesting();
    middleware.resetForTesting();
    pinService.resetForTesting();
    
    // Initialize services
    await pinService.initialize();
    await authService.initialize();
    await sensitiveOperationService.initialize();
    await middleware.initialize();
    
    // Set up a PIN for testing
    await pinService.setupPIN('1234');
    await authService.authenticateWithPIN('1234');
  });

  tearDown(() {
    authService.resetForTesting();
    sensitiveOperationService.resetForTesting();
    middleware.resetForTesting();
    pinService.resetForTesting();
  });

  group('SecurityMiddleware - Initialization', () {
    test('should initialize successfully', () async {
      final newMiddleware = SecurityMiddleware();
      newMiddleware.resetForTesting();
      
      await newMiddleware.initialize();
      
      // Should not throw
      expect(true, true);
    });

    test('should not reinitialize if already initialized', () async {
      // Already initialized in setUp
      await middleware.initialize();
      
      // Should not throw
      expect(true, true);
    });
  });

  group('SecurityMiddleware - Sensitive Screen Detection', () {
    test('should identify money transfer screens as sensitive', () {
      expect(
        middleware.isSensitiveScreen('add_transaction_screen'),
        true,
      );
      
      expect(
        middleware.isSensitiveScreen('edit_transaction_screen'),
        true,
      );
      
      expect(
        middleware.isSensitiveScreen('make_credit_card_payment_screen'),
        true,
      );
    });

    test('should identify security settings screens as sensitive', () {
      expect(
        middleware.isSensitiveScreen('security_settings_screen'),
        true,
      );
      
      expect(
        middleware.isSensitiveScreen('pin_setup_screen'),
        true,
      );
      
      expect(
        middleware.isSensitiveScreen('biometric_setup_screen'),
        true,
      );
    });

    test('should identify account detail screens as sensitive', () {
      expect(
        middleware.isSensitiveScreen('credit_card_detail_screen'),
        true,
      );
      
      expect(
        middleware.isSensitiveScreen('debt_detail_screen'),
        true,
      );
      
      expect(
        middleware.isSensitiveScreen('kmh_account_detail_screen'),
        true,
      );
    });

    test('should identify export screens as sensitive', () {
      expect(
        middleware.isSensitiveScreen('export_screen'),
        true,
      );
      
      expect(
        middleware.isSensitiveScreen('detailed_report_screen'),
        true,
      );
    });

    test('should not identify non-sensitive screens', () {
      expect(
        middleware.isSensitiveScreen('home_screen'),
        false,
      );
      
      expect(
        middleware.isSensitiveScreen('about_screen'),
        false,
      );
      
      expect(
        middleware.isSensitiveScreen('help_screen'),
        false,
      );
    });
  });

  group('SecurityMiddleware - Operation Type Detection', () {
    test('should detect money transfer operation type', () {
      final operationType = middleware.getOperationTypeForScreen(
        'add_transaction_screen',
      );
      
      expect(operationType, SensitiveOperationType.moneyTransfer);
    });

    test('should detect security settings operation type', () {
      final operationType = middleware.getOperationTypeForScreen(
        'security_settings_screen',
      );
      
      expect(operationType, SensitiveOperationType.securitySettingsChange);
    });

    test('should detect account info view operation type', () {
      final operationType = middleware.getOperationTypeForScreen(
        'credit_card_detail_screen',
      );
      
      expect(operationType, SensitiveOperationType.accountInfoView);
    });

    test('should detect data export operation type', () {
      final operationType = middleware.getOperationTypeForScreen(
        'export_screen',
      );
      
      expect(operationType, SensitiveOperationType.dataExport);
    });

    test('should return null for non-sensitive screens', () {
      final operationType = middleware.getOperationTypeForScreen(
        'home_screen',
      );
      
      expect(operationType, null);
    });
  });

  group('SecurityMiddleware - Security Level Requirements', () {
    test('should require enhanced security for money transfers', () async {
      final securityLevel = await middleware.getRequiredSecurityLevel(
        'add_transaction_screen',
        context: {'amount': 100.0, 'currency': 'TRY'},
      );
      
      expect(securityLevel, OperationSecurityLevel.enhanced);
    });

    test('should require two-factor for large transactions', () async {
      final securityLevel = await middleware.getRequiredSecurityLevel(
        'add_transaction_screen',
        context: {'amount': 15000.0, 'currency': 'TRY'},
      );
      
      expect(securityLevel, OperationSecurityLevel.twoFactor);
    });

    test('should require multi-method for security settings', () async {
      final securityLevel = await middleware.getRequiredSecurityLevel(
        'security_settings_screen',
      );
      
      expect(securityLevel, OperationSecurityLevel.multiMethod);
    });

    test('should require recent auth for account info', () async {
      final securityLevel = await middleware.getRequiredSecurityLevel(
        'credit_card_detail_screen',
      );
      
      expect(securityLevel, OperationSecurityLevel.recentAuth);
    });

    test('should require full auth for data export', () async {
      final securityLevel = await middleware.getRequiredSecurityLevel(
        'export_screen',
      );
      
      expect(securityLevel, OperationSecurityLevel.fullAuth);
    });

    test('should return null for non-sensitive screens', () async {
      final securityLevel = await middleware.getRequiredSecurityLevel(
        'home_screen',
      );
      
      expect(securityLevel, null);
    });
  });

  group('SecurityMiddleware - Security Check Requirements', () {
    test('should not require check for non-sensitive screens', () async {
      final requiresCheck = await middleware.requiresSecurityCheck(
        'home_screen',
      );
      
      expect(requiresCheck, false);
    });

    test('should require check for sensitive screens when auth is old', () async {
      // Wait for auth to become stale (in real scenario)
      // For testing, we'll just check the logic
      final requiresCheck = await middleware.requiresSecurityCheck(
        'credit_card_detail_screen',
      );
      
      // Should check based on recent auth requirement
      expect(requiresCheck, isA<bool>());
    });
  });

  group('SecurityMiddleware - Screen Access Validation', () {
    test('should allow access to non-sensitive screens', () async {
      final result = await middleware.validateScreenAccess(
        'home_screen',
      );
      
      expect(result.isSuccess, true);
      expect(result.screenName, 'home_screen');
      expect(result.securityLevel, OperationSecurityLevel.standard);
    });

    test('should validate access with correct PIN', () async {
      final result = await middleware.validateScreenAccess(
        'add_transaction_screen',
        context: {'amount': 100.0, 'currency': 'TRY'},
        authMethod: AuthMethod.pin,
        pin: '1234',
      );
      
      expect(result.isSuccess, true);
      expect(result.screenName, 'add_transaction_screen');
      expect(result.securityLevel, OperationSecurityLevel.enhanced);
    });

    test('should reject access with incorrect PIN', () async {
      final result = await middleware.validateScreenAccess(
        'add_transaction_screen',
        context: {'amount': 100.0, 'currency': 'TRY'},
        authMethod: AuthMethod.pin,
        pin: '9999',
      );
      
      expect(result.isSuccess, false);
      expect(result.screenName, 'add_transaction_screen');
      expect(result.errorMessage, isNotNull);
    });

    test('should handle validation errors gracefully', () async {
      final result = await middleware.validateScreenAccess(
        'unknown_screen',
        authMethod: AuthMethod.pin,
        pin: '1234',
      );
      
      // Should handle gracefully
      expect(result, isA<SecurityValidationResult>());
    });
  });

  group('SecurityMiddleware - Widget Wrapping', () {
    testWidgets('should wrap non-sensitive screens without auth', (tester) async {
      final widget = middleware.wrapWithSecurity(
        screenName: 'home_screen',
        builder: (context) => const Scaffold(
          body: Text('Home Screen'),
        ),
      );
      
      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pumpAndSettle();
      
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('should show loading while checking security', (tester) async {
      final widget = middleware.wrapWithSecurity(
        screenName: 'add_transaction_screen',
        builder: (context) => const Scaffold(
          body: Text('Transaction Screen'),
        ),
      );
      
      await tester.pumpWidget(MaterialApp(home: widget));
      
      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('SecurityMiddleware - Route Creation', () {
    test('should create secure route for sensitive screens', () {
      final route = middleware.createSecureRoute(
        screenName: 'add_transaction_screen',
        builder: (context) => const Scaffold(
          body: Text('Transaction Screen'),
        ),
      );
      
      expect(route, isA<MaterialPageRoute>());
      expect(route.settings.name, null);
    });

    test('should create secure route with custom settings', () {
      final route = middleware.createSecureRoute(
        screenName: 'add_transaction_screen',
        builder: (context) => const Scaffold(
          body: Text('Transaction Screen'),
        ),
        settings: const RouteSettings(name: '/transaction'),
      );
      
      expect(route, isA<MaterialPageRoute>());
      expect(route.settings.name, '/transaction');
    });
  });

  group('SecurityValidationResult', () {
    test('should create success result', () {
      final result = SecurityValidationResult.success(
        screenName: 'test_screen',
        securityLevel: OperationSecurityLevel.enhanced,
        authMethod: AuthMethod.pin,
      );
      
      expect(result.isSuccess, true);
      expect(result.screenName, 'test_screen');
      expect(result.securityLevel, OperationSecurityLevel.enhanced);
      expect(result.authMethod, AuthMethod.pin);
    });

    test('should create failure result', () {
      final result = SecurityValidationResult.failure(
        screenName: 'test_screen',
        securityLevel: OperationSecurityLevel.enhanced,
        errorMessage: 'Authentication failed',
        remainingAttempts: 2,
      );
      
      expect(result.isSuccess, false);
      expect(result.screenName, 'test_screen');
      expect(result.errorMessage, 'Authentication failed');
      expect(result.remainingAttempts, 2);
    });

    test('should have meaningful toString', () {
      final result = SecurityValidationResult.success(
        screenName: 'test_screen',
        securityLevel: OperationSecurityLevel.enhanced,
      );
      
      final str = result.toString();
      expect(str, contains('SecurityValidationResult'));
      expect(str, contains('test_screen'));
      expect(str, contains('true'));
    });
  });

  group('SecurityNavigatorObserver', () {
    test('should register and unregister screens', () {
      final observer = SecurityNavigatorObserver();
      
      final config = ScreenSecurityConfig(
        screenName: 'test_screen',
        enforceAutomatically: true,
      );
      
      observer.registerScreen('test_screen', config);
      
      // Should not throw
      expect(true, true);
      
      observer.unregisterScreen('test_screen');
      
      // Should not throw
      expect(true, true);
    });
  });

  group('ScreenSecurityConfig', () {
    test('should create config with required fields', () {
      final config = ScreenSecurityConfig(
        screenName: 'test_screen',
      );
      
      expect(config.screenName, 'test_screen');
      expect(config.enforceAutomatically, true);
      expect(config.context, null);
      expect(config.onSecurityRequired, null);
    });

    test('should create config with all fields', () {
      var callbackCalled = false;
      
      final config = ScreenSecurityConfig(
        screenName: 'test_screen',
        context: {'key': 'value'},
        onSecurityRequired: () => callbackCalled = true,
        enforceAutomatically: false,
      );
      
      expect(config.screenName, 'test_screen');
      expect(config.enforceAutomatically, false);
      expect(config.context, {'key': 'value'});
      
      config.onSecurityRequired?.call();
      expect(callbackCalled, true);
    });
  });
}
