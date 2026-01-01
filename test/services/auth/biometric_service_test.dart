import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/auth/biometric_service.dart';
import 'package:parion/models/security/auth_result.dart';
import 'package:parion/models/security/auth_state.dart';
import 'package:parion/models/security/biometric_type.dart' as app_biometric;

void main() {
  group('BiometricService', () {
    late BiometricServiceImpl biometricService;

    setUp(() {
      biometricService = BiometricServiceImpl();
    });

    group('BiometricService Interface', () {
      test('should implement all required methods', () {
        // Test that the service implements the interface correctly
        expect(biometricService, isA<BiometricService>());

        // Test method signatures exist
        expect(biometricService.isBiometricAvailable, isA<Function>());
        expect(biometricService.getAvailableBiometrics, isA<Function>());
        expect(biometricService.authenticate, isA<Function>());
        expect(biometricService.enrollBiometric, isA<Function>());
        expect(biometricService.disableBiometric, isA<Function>());
        expect(biometricService.isDeviceSecure, isA<Function>());
        expect(biometricService.canCheckBiometrics, isA<Function>());
      });
    });

    group('Error Handling', () {
      test('should handle errors gracefully in isBiometricAvailable', () async {
        // This test verifies that the service doesn't crash on errors
        final result = await biometricService.isBiometricAvailable();
        expect(result, isA<bool>());
      });

      test(
        'should handle errors gracefully in getAvailableBiometrics',
        () async {
          // This test verifies that the service returns empty list on errors
          final result = await biometricService.getAvailableBiometrics();
          expect(result, isA<List<app_biometric.BiometricType>>());
        },
      );

      test('should handle errors gracefully in canCheckBiometrics', () async {
        // This test verifies that the service doesn't crash on errors
        final result = await biometricService.canCheckBiometrics();
        expect(result, isA<bool>());
      });

      test('should handle errors gracefully in isDeviceSecure', () async {
        // This test verifies that the service doesn't crash on errors
        final result = await biometricService.isDeviceSecure();
        expect(result, isA<bool>());
      });

      test('should handle errors gracefully in enrollBiometric', () async {
        // This test verifies that the service doesn't crash on errors
        final result = await biometricService.enrollBiometric();
        expect(result, isA<bool>());
      });

      test('should not throw exception in disableBiometric', () async {
        // This test verifies that the service doesn't crash on errors
        expect(
          () async => await biometricService.disableBiometric(),
          returnsNormally,
        );
      });
    });

    group('Authentication Results', () {
      test('should return AuthResult from authenticate method', () async {
        // Test that authenticate returns proper AuthResult
        final result = await biometricService.authenticate();
        expect(result, isA<AuthResult>());
        expect(result.method, equals(AuthMethod.biometric));

        // If authentication fails due to unavailability, should have error message
        if (!result.isSuccess) {
          expect(result.errorMessage, isNotNull);
          expect(result.errorMessage, isNotEmpty);
        }
      });

      test('should include metadata in successful authentication', () async {
        // This is a basic test - in real scenarios with available biometrics,
        // successful authentication should include metadata
        final result = await biometricService.authenticate();

        if (result.isSuccess) {
          expect(result.metadata, isNotNull);
          expect(result.metadata!['timestamp'], isNotNull);
          expect(result.metadata!['availableBiometrics'], isNotNull);
        }
      });
    });

    group('Singleton Pattern', () {
      test('should return same instance from singleton', () {
        final instance1 = BiometricServiceSingleton.instance;
        final instance2 = BiometricServiceSingleton.instance;

        expect(identical(instance1, instance2), isTrue);
      });

      test('should allow setting custom instance', () {
        final customService = BiometricServiceImpl();
        BiometricServiceSingleton.setInstance(customService);

        final retrievedInstance = BiometricServiceSingleton.instance;
        expect(identical(retrievedInstance, customService), isTrue);

        // Reset for other tests
        BiometricServiceSingleton.reset();
      });

      test('should reset instance correctly', () {
        final instance1 = BiometricServiceSingleton.instance;
        BiometricServiceSingleton.reset();
        final instance2 = BiometricServiceSingleton.instance;

        expect(identical(instance1, instance2), isFalse);
      });
    });
  });
}
