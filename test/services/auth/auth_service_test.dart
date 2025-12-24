import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:money/services/auth/auth_service.dart';
import 'package:money/services/auth/pin_service.dart';
import 'package:money/services/auth/biometric_service.dart';
import 'package:money/services/auth/secure_storage_service.dart';
import 'package:money/models/security/security_models.dart';

// Generate mocks
@GenerateMocks([PINService, BiometricService, AuthSecureStorageService])
import 'auth_service_test.mocks.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockPINService mockPinService;
    late MockBiometricService mockBiometricService;
    late MockAuthSecureStorageService mockStorage;

    setUp(() {
      mockPinService = MockPINService();
      mockBiometricService = MockBiometricService();
      mockStorage = MockAuthSecureStorageService();
      
      authService = AuthService();
      authService.resetForTesting();
    });

    tearDown(() {
      authService.dispose();
    });

    group('PIN Authentication', () {
      test('should authenticate successfully with correct PIN', () async {
        // Arrange
        const pin = '1234';
        final expectedResult = AuthResult.success(
          method: AuthMethod.pin,
          metadata: {'action': 'verify'},
        );
        
        when(mockStorage.initialize()).thenAnswer((_) async {});
        when(mockPinService.initialize()).thenAnswer((_) async {});
        when(mockPinService.verifyPIN(pin)).thenAnswer((_) async => expectedResult);
        when(mockStorage.getSecurityConfig()).thenAnswer((_) async => SecurityConfig.defaultConfig());
        when(mockStorage.storeAuthState(any)).thenAnswer((_) async => true);
        when(mockStorage.storeSessionData(any)).thenAnswer((_) async => true);

        // Act
        final result = await authService.authenticateWithPIN(pin);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.method, equals(AuthMethod.pin));
        expect(authService.currentAuthState.isAuthenticated, isTrue);
      });

      test('should fail authentication with incorrect PIN', () async {
        // Arrange
        const pin = '0000';
        final expectedResult = AuthResult.failure(
          method: AuthMethod.pin,
          errorMessage: 'Yanlış PIN',
        );
        
        when(mockStorage.initialize()).thenAnswer((_) async {});
        when(mockPinService.initialize()).thenAnswer((_) async {});
        when(mockPinService.verifyPIN(pin)).thenAnswer((_) async => expectedResult);

        // Act
        final result = await authService.authenticateWithPIN(pin);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.method, equals(AuthMethod.pin));
        expect(result.errorMessage, equals('Yanlış PIN'));
        expect(authService.currentAuthState.isAuthenticated, isFalse);
      });
    });

    group('Biometric Authentication', () {
      test('should authenticate successfully with biometric', () async {
        // Arrange
        final expectedResult = AuthResult.success(
          method: AuthMethod.biometric,
          metadata: {'timestamp': DateTime.now().toIso8601String()},
        );
        
        when(mockStorage.initialize()).thenAnswer((_) async {});
        when(mockPinService.initialize()).thenAnswer((_) async {});
        when(mockBiometricService.authenticate()).thenAnswer((_) async => expectedResult);
        when(mockStorage.getSecurityConfig()).thenAnswer((_) async => SecurityConfig.defaultConfig());
        when(mockStorage.storeAuthState(any)).thenAnswer((_) async => true);
        when(mockStorage.storeSessionData(any)).thenAnswer((_) async => true);

        // Act
        final result = await authService.authenticateWithBiometric();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.method, equals(AuthMethod.biometric));
        expect(authService.currentAuthState.isAuthenticated, isTrue);
      });

      test('should fail authentication when biometric fails', () async {
        // Arrange
        final expectedResult = AuthResult.failure(
          method: AuthMethod.biometric,
          errorMessage: 'Biyometrik kimlik doğrulama başarısız',
        );
        
        when(mockStorage.initialize()).thenAnswer((_) async {});
        when(mockPinService.initialize()).thenAnswer((_) async {});
        when(mockBiometricService.authenticate()).thenAnswer((_) async => expectedResult);

        // Act
        final result = await authService.authenticateWithBiometric();

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.method, equals(AuthMethod.biometric));
        expect(authService.currentAuthState.isAuthenticated, isFalse);
      });
    });

    group('Session Management', () {
      test('should start session after successful authentication', () async {
        // Arrange
        const pin = '1234';
        final pinResult = AuthResult.success(
          method: AuthMethod.pin,
          metadata: {'action': 'verify'},
        );
        
        when(mockStorage.initialize()).thenAnswer((_) async {});
        when(mockPinService.initialize()).thenAnswer((_) async {});
        when(mockPinService.verifyPIN(pin)).thenAnswer((_) async => pinResult);
        when(mockStorage.getSecurityConfig()).thenAnswer((_) async => SecurityConfig.defaultConfig());
        when(mockStorage.storeAuthState(any)).thenAnswer((_) async => true);
        when(mockStorage.storeSessionData(any)).thenAnswer((_) async => true);

        // Act
        await authService.authenticateWithPIN(pin);

        // Assert
        expect(authService.currentAuthState.isAuthenticated, isTrue);
        expect(authService.currentAuthState.sessionId, isNotNull);
        expect(authService.currentSession, isNotNull);
        expect(authService.currentSession!.authMethod, equals(AuthMethod.pin));
      });

      test('should logout and clear session', () async {
        // Arrange
        const pin = '1234';
        final pinResult = AuthResult.success(
          method: AuthMethod.pin,
          metadata: {'action': 'verify'},
        );
        
        when(mockStorage.initialize()).thenAnswer((_) async {});
        when(mockPinService.initialize()).thenAnswer((_) async {});
        when(mockPinService.verifyPIN(pin)).thenAnswer((_) async => pinResult);
        when(mockStorage.getSecurityConfig()).thenAnswer((_) async => SecurityConfig.defaultConfig());
        when(mockStorage.storeAuthState(any)).thenAnswer((_) async => true);
        when(mockStorage.storeSessionData(any)).thenAnswer((_) async => true);
        when(mockStorage.clearAuthState()).thenAnswer((_) async => true);
        when(mockStorage.clearSessionData()).thenAnswer((_) async => true);

        // Act
        await authService.authenticateWithPIN(pin);
        expect(authService.currentAuthState.isAuthenticated, isTrue);
        
        await authService.logout();

        // Assert
        expect(authService.currentAuthState.isAuthenticated, isFalse);
        expect(authService.currentAuthState.sessionId, isNull);
        expect(authService.currentSession, isNull);
      });

      test('should check if authentication is required', () async {
        // Arrange
        when(mockStorage.initialize()).thenAnswer((_) async {});
        when(mockPinService.initialize()).thenAnswer((_) async {});

        // Act & Assert - Not authenticated initially
        final isAuthenticatedBefore = await authService.isAuthenticated();
        expect(isAuthenticatedBefore, isFalse);

        // Authenticate
        const pin = '1234';
        final pinResult = AuthResult.success(
          method: AuthMethod.pin,
          metadata: {'action': 'verify'},
        );
        
        when(mockPinService.verifyPIN(pin)).thenAnswer((_) async => pinResult);
        when(mockStorage.getSecurityConfig()).thenAnswer((_) async => SecurityConfig.defaultConfig());
        when(mockStorage.storeAuthState(any)).thenAnswer((_) async => true);
        when(mockStorage.storeSessionData(any)).thenAnswer((_) async => true);

        await authService.authenticateWithPIN(pin);
        
        // Should be authenticated now
        final isAuthenticatedAfter = await authService.isAuthenticated();
        expect(isAuthenticatedAfter, isTrue);
      });
    });

    group('Sensitive Operations', () {
      test('should require sensitive auth when not recently authenticated', () async {
        // Arrange
        when(mockStorage.initialize()).thenAnswer((_) async {});
        when(mockPinService.initialize()).thenAnswer((_) async {});

        // Act
        final requiresAuth = await authService.requiresSensitiveAuth();

        // Assert
        expect(requiresAuth, isTrue);
      });

      test('should authenticate for sensitive operation with PIN', () async {
        // Arrange
        const pin = '1234';
        
        // First authenticate normally
        final pinResult = AuthResult.success(
          method: AuthMethod.pin,
          metadata: {'action': 'verify'},
        );
        
        when(mockStorage.initialize()).thenAnswer((_) async {});
        when(mockPinService.initialize()).thenAnswer((_) async {});
        when(mockPinService.verifyPIN(pin)).thenAnswer((_) async => pinResult);
        when(mockStorage.getSecurityConfig()).thenAnswer((_) async => SecurityConfig.defaultConfig());
        when(mockStorage.storeAuthState(any)).thenAnswer((_) async => true);
        when(mockStorage.storeSessionData(any)).thenAnswer((_) async => true);

        await authService.authenticateWithPIN(pin);

        // Act - Authenticate for sensitive operation
        final result = await authService.authenticateForSensitiveOperation(
          method: AuthMethod.pin,
          pin: pin,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(authService.currentSession!.lastSensitiveAuth, isNotNull);
      });
    });

    group('Security Configuration', () {
      test('should get default security config', () async {
        // Arrange
        when(mockStorage.initialize()).thenAnswer((_) async {});
        when(mockPinService.initialize()).thenAnswer((_) async {});
        when(mockStorage.getSecurityConfig()).thenAnswer((_) async => null);

        // Act
        final config = await authService.getSecurityConfig();

        // Assert
        expect(config, isNotNull);
        expect(config.isPINEnabled, isTrue);
        expect(config.sessionTimeout, equals(const Duration(minutes: 5)));
      });

      test('should update security config', () async {
        // Arrange
        final newConfig = SecurityConfig.defaultConfig().copyWith(
          sessionTimeout: const Duration(minutes: 10),
        );
        
        when(mockStorage.initialize()).thenAnswer((_) async {});
        when(mockPinService.initialize()).thenAnswer((_) async {});
        when(mockStorage.storeSecurityConfig(newConfig)).thenAnswer((_) async => true);

        // Act
        final success = await authService.updateSecurityConfig(newConfig);

        // Assert
        expect(success, isTrue);
        verify(mockStorage.storeSecurityConfig(newConfig)).called(1);
      });
    });
  });
}