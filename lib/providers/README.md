# Security Provider

## Overview

The `SecurityProvider` is a global state management solution for security-related functionality in the application. It provides a reactive interface for UI components to interact with security services and track authentication state.

## Features

- **Global Security State Management**: Centralized management of authentication and security state
- **Authentication State Tracking**: Real-time tracking of user authentication status
- **Security Event Stream**: Broadcast stream for security events across the application
- **Service Coordination**: Coordinates multiple security services (Auth, PIN, Session, Audit, Security)
- **Reactive UI Updates**: Extends `ChangeNotifier` for automatic UI updates

## Usage

### Basic Initialization

```dart
import 'package:money/providers/security_provider.dart';

// Get singleton instance
final securityProvider = SecurityProvider();

// Initialize the provider
await securityProvider.initialize();
```

### Listening to Authentication State

```dart
// Using ChangeNotifier
securityProvider.addListener(() {
  if (securityProvider.isAuthenticated) {
    // User is authenticated
    print('User authenticated: ${securityProvider.authState.sessionId}');
  }
});

// Using Stream
securityProvider.authStateStream.listen((authState) {
  print('Auth state changed: ${authState.isAuthenticated}');
});
```

### Authentication Operations

```dart
// Authenticate with PIN
final result = await securityProvider.authenticateWithPIN('1234');
if (result.isSuccess) {
  // Authentication successful
}

// Authenticate with Biometric
final bioResult = await securityProvider.authenticateWithBiometric();

// Authenticate for sensitive operation
final sensitiveResult = await securityProvider.authenticateForSensitiveOperation(
  method: AuthMethod.pin,
  pin: '1234',
);

// Logout
await securityProvider.logout();
```

### Security Events

```dart
// Listen to security events
securityProvider.securityEventStream.listen((event) {
  print('Security event: ${event.type} - ${event.description}');
});

// Log a security event
await securityProvider.logSecurityEvent(
  SecurityEvent.pinVerified(userId: 'user123'),
);

// Load recent events
await securityProvider.loadRecentEvents(limit: 20);
final recentEvents = securityProvider.recentEvents;
```

### Security Configuration

```dart
// Update security configuration
final newConfig = SecurityConfig(
  isPINEnabled: true,
  isBiometricEnabled: true,
  sessionTimeout: Duration(minutes: 10),
  // ... other settings
);

final success = await securityProvider.updateSecurityConfig(newConfig);
```

### App Lifecycle Management

```dart
// Handle app lifecycle changes
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final securityProvider = SecurityProvider();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    securityProvider.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      securityProvider.onAppBackground();
    } else if (state == AppLifecycleState.resumed) {
      securityProvider.onAppForeground();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(/* ... */);
  }
}
```

### Using with UI Widgets

```dart
class SecurityDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SecurityProvider(),
      builder: (context, child) {
        final provider = SecurityProvider();
        
        return Column(
          children: [
            Text('Authenticated: ${provider.isAuthenticated}'),
            Text('Session: ${provider.sessionData?.sessionId ?? 'None'}'),
            if (provider.isLoading)
              CircularProgressIndicator(),
            if (provider.errorMessage != null)
              Text('Error: ${provider.errorMessage}'),
            ListView.builder(
              itemCount: provider.recentEvents.length,
              itemBuilder: (context, index) {
                final event = provider.recentEvents[index];
                return ListTile(
                  title: Text(event.type.description),
                  subtitle: Text(event.description),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
```

## Architecture

The `SecurityProvider` acts as a facade over multiple security services:

- **AuthService**: Main authentication coordination
- **PINService**: PIN code management
- **SessionManager**: Session lifecycle management
- **AuditLoggerService**: Security event logging
- **SecurityService**: Security features (screenshot blocking, etc.)

## Requirements Implemented

- **Requirement 1.4**: PIN başarıyla doğrulandığında kullanıcı oturumu başlatmalı
- **Requirement 6.2**: 5 dakika boyunca aktivite olmadığında oturumu sonlandırmalı
- **Requirement 7.5**: Güvenlik ayarları değiştirildiğinde değişiklikleri audit loguna kaydetmeli

## Testing

```dart
// Reset provider for testing
provider.resetForTesting();

// Check state
expect(provider.isInitialized, isFalse);
expect(provider.isAuthenticated, isFalse);
expect(provider.recentEvents, isEmpty);
```

## Singleton Pattern

The provider uses a singleton pattern for global state management:

```dart
// Get singleton instance
final provider = SecurityProviderSingleton.instance;

// Set custom instance for testing
SecurityProviderSingleton.setInstance(customProvider);

// Reset singleton
SecurityProviderSingleton.reset();
```

## Notes

- The provider automatically initializes services when needed
- All operations are async and handle errors gracefully
- The provider notifies listeners on state changes
- Security events are automatically logged and broadcast
- Recent events are limited to 50 items for performance
