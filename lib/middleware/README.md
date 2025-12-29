# Security Middleware

This directory contains middleware components for enforcing security controls across the application.

## SecurityMiddleware

The `SecurityMiddleware` class provides screen-level security controls by integrating with the authentication and sensitive operation services.

### Features

- **Sensitive Screen Detection**: Automatically identifies screens that require additional security
- **Security Level Checking**: Determines the required security level for each screen
- **Authentication Enforcement**: Validates authentication requirements before allowing screen access
- **Widget Wrapping**: Provides convenient methods to wrap screens with security validation
- **Route Creation**: Creates secure routes with automatic authentication checks

### Usage

#### Basic Initialization

```dart
final middleware = SecurityMiddleware();
await middleware.initialize();
```

#### Check if Screen is Sensitive

```dart
final isSensitive = middleware.isSensitiveScreen('add_transaction_screen');
```

#### Get Required Security Level

```dart
final securityLevel = await middleware.getRequiredSecurityLevel(
  'add_transaction_screen',
  context: {'amount': 100.0, 'currency': 'TRY'},
);
```

#### Validate Screen Access

```dart
final result = await middleware.validateScreenAccess(
  'add_transaction_screen',
  context: {'amount': 100.0, 'currency': 'TRY'},
  authMethod: AuthMethod.pin,
  pin: '1234',
);

if (result.isSuccess) {
  // Allow access
} else {
  // Show error: result.errorMessage
}
```

#### Wrap Widget with Security

```dart
Widget build(BuildContext context) {
  return middleware.wrapWithSecurity(
    screenName: 'add_transaction_screen',
    builder: (context) => AddTransactionScreen(),
    context: {'amount': 100.0},
  );
}
```

#### Create Secure Route

```dart
final route = middleware.createSecureRoute(
  screenName: 'add_transaction_screen',
  builder: (context) => AddTransactionScreen(),
  settings: RouteSettings(name: '/transaction'),
);

Navigator.of(context).push(route);
```

### Sensitive Screen Categories

The middleware automatically identifies the following screen categories as sensitive:

#### Money Transfer Screens
- `add_transaction_screen`
- `edit_transaction_screen`
- `make_credit_card_payment_screen`

#### Security Settings Screens
- `security_settings_screen`
- `pin_setup_screen`
- `pin_change_screen`
- `biometric_setup_screen`

#### Account Detail Screens
- `credit_card_detail_screen`
- `debt_detail_screen`
- `wallet_detail_screen`
- `kmh_account_detail_screen`

#### Export and Report Screens
- `export_screen`
- `detailed_report_screen`

### Security Levels

The middleware supports different security levels based on the operation type:

- **Standard**: Basic authentication required
- **Recent Auth**: Authentication within last 5 minutes required
- **Enhanced**: Authentication within last 2 minutes required
- **Multi-Method**: Multiple authentication methods required
- **Two-Factor**: Two-factor authentication required
- **Full Auth**: Complete re-authentication required

### SecurityNavigatorObserver

The `SecurityNavigatorObserver` class automatically monitors navigation and enforces security requirements:

```dart
final observer = SecurityNavigatorObserver();

// Register screens with security configuration
observer.registerScreen(
  'add_transaction_screen',
  ScreenSecurityConfig(
    screenName: 'add_transaction_screen',
    context: {'amount': 100.0},
    onSecurityRequired: () {
      // Handle security requirement
    },
  ),
);

// Use in MaterialApp
MaterialApp(
  navigatorObservers: [observer],
  // ...
);
```

### Integration with Requirements

This middleware implements the following requirements:

- **8.1**: Money transfers require additional authentication
- **8.2**: Security settings changes require PIN and biometric authentication
- **8.4**: Account info viewing requires authentication within last 5 minutes
- **8.5**: Export operations require full authentication

### Testing

Comprehensive tests are available in `test/middleware/security_middleware_test.dart`:

```bash
flutter test test/middleware/security_middleware_test.dart
```

### Implementation Notes

- The middleware integrates with `AuthService` and `SensitiveOperationService`
- Screen names should match the actual screen class names (in snake_case)
- Context can be provided for dynamic security level determination
- All security validations are logged for audit purposes
