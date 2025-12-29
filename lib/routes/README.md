# Authentication Route Guard

This directory contains the authentication route guard implementation for the Money Management app.

## Overview

The authentication route guard provides secure navigation by enforcing authentication requirements before allowing access to protected routes.

## Components

### AuthGuard

The main authentication guard class that provides route protection functionality.

**Key Methods:**
- `isAuthenticated()` - Checks if the user is currently authenticated
- `requiresSensitiveAuth()` - Checks if sensitive authentication is required
- `guardRoute()` - Guards a route by checking authentication status
- `createGuardedRoute()` - Creates a MaterialPageRoute with authentication guard

**Usage Example:**
```dart
// Create a guarded route
final route = AuthGuard().createGuardedRoute(
  builder: (context) => const ProtectedScreen(),
  requiresSensitive: true,
);

Navigator.push(context, route);
```

### AuthGuardMiddleware

A NavigatorObserver that monitors route changes and enforces authentication requirements.

**Features:**
- Automatically checks authentication for protected routes
- Supports sensitive route authentication
- Configurable protected and sensitive route lists

**Usage Example:**
```dart
MaterialApp(
  navigatorObservers: [AuthGuardMiddleware()],
  // ... other properties
)
```

## Integration with Main App

The authentication guard is integrated into the main app in `lib/main.dart`:

1. **Initialization**: Security authentication services are initialized at app startup
2. **Route Observation**: AuthGuardMiddleware is added to navigatorObservers
3. **Initial Screen**: The app determines the initial screen based on authentication state
4. **Lifecycle Management**: App lifecycle events trigger authentication checks

## Protected Routes

The following routes are protected by default:
- `/home`
- `/settings`
- `/security-settings`
- `/transactions`
- `/wallets`
- `/categories`
- `/goals`
- `/debts`
- `/credit-cards`
- `/bills`
- `/recurring`
- `/statistics`
- `/reports`

## Sensitive Routes

The following routes require additional sensitive authentication:
- `/security-settings`
- `/pin-change`
- `/export`
- `/backup`

## Requirements Implemented

This implementation satisfies the following requirements:

- **Requirement 1.4**: PIN başarıyla doğrulandığında kullanıcı oturumu başlatmalı
- **Requirement 4.4**: Biyometrik doğrulama başarılı olduğunda kullanıcı oturumu başlatmalı
- **Requirement 6.3**: Uygulama tekrar açıldığında kimlik doğrulama gerektirmeli

## Testing

Integration tests are available in `test/integration/auth_integration_test.dart`.

Run tests with:
```bash
flutter test test/integration/auth_integration_test.dart
```

## Future Enhancements

- Add support for custom authentication callbacks
- Implement route-specific authentication timeouts
- Add support for role-based access control
- Implement authentication state persistence across app restarts
