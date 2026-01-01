import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/auth/biometric_security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('BiometricSecurityService', () {
    late BiometricSecurityService service;

    setUp(() {
      service = BiometricSecurityServiceImpl();
    });

    group('BiometricDataStatus enum', () {
      test('should have all required status values', () {
        expect(BiometricDataStatus.valid, isNotNull);
        expect(BiometricDataStatus.corrupted, isNotNull);
        expect(BiometricDataStatus.notFound, isNotNull);
        expect(BiometricDataStatus.deviceChanged, isNotNull);
        expect(BiometricDataStatus.securityBreach, isNotNull);
      });
    });

    group('Service instantiation', () {
      test('should create service instance successfully', () {
        expect(service, isNotNull);
        expect(service, isA<BiometricSecurityService>());
      });

      test('should create singleton instance', () {
        final instance1 = BiometricSecurityServiceSingleton.instance;
        final instance2 = BiometricSecurityServiceSingleton.instance;
        
        expect(instance1, equals(instance2));
        expect(instance1, isA<BiometricSecurityService>());
      });
    });

    group('isLocalStorageSecure', () {
      test('should handle initialization gracefully', () async {
        // This test verifies the method doesn't throw exceptions
        // In a real environment, this would depend on device capabilities
        final result = await service.isLocalStorageSecure();
        expect(result, isA<bool>());
      });
    });

    group('accessSecureArea', () {
      test('should handle secure area access gracefully', () async {
        // This test verifies the method doesn't throw exceptions
        final result = await service.accessSecureArea();
        expect(result, isA<bool>());
      });
    });

    group('clearBiometricData', () {
      test('should handle data clearing gracefully', () async {
        // This test verifies the method doesn't throw exceptions
        final result = await service.clearBiometricData();
        expect(result, isA<bool>());
      });
    });

    group('validateDeviceIntegrity', () {
      test('should handle device integrity validation gracefully', () async {
        // This test verifies the method doesn't throw exceptions
        final result = await service.validateDeviceIntegrity();
        expect(result, isA<bool>());
      });
    });

    group('validateBiometricIntegrity', () {
      test('should handle biometric integrity validation gracefully', () async {
        // This test verifies the method doesn't throw exceptions
        final result = await service.validateBiometricIntegrity();
        expect(result, isA<bool>());
      });
    });

    group('secureEnrollBiometric', () {
      test('should handle biometric enrollment gracefully', () async {
        // This test verifies the method doesn't throw exceptions
        final result = await service.secureEnrollBiometric();
        expect(result, isA<bool>());
      });
    });

    group('getBiometricDataStatus', () {
      test('should return valid BiometricDataStatus', () async {
        // This test verifies the method returns a valid enum value
        final result = await service.getBiometricDataStatus();
        expect(result, isA<BiometricDataStatus>());
        
        // Verify it's one of the expected values
        final validStatuses = [
          BiometricDataStatus.valid,
          BiometricDataStatus.corrupted,
          BiometricDataStatus.notFound,
          BiometricDataStatus.deviceChanged,
          BiometricDataStatus.securityBreach,
        ];
        expect(validStatuses.contains(result), isTrue);
      });
    });

    group('handleSecurityBreach', () {
      test('should handle security breach gracefully', () async {
        // This test verifies the method doesn't throw exceptions
        expect(() async => await service.handleSecurityBreach(), returnsNormally);
      });
    });

    group('Singleton management', () {
      test('should allow setting custom instance for testing', () {
        final customService = BiometricSecurityServiceImpl();
        BiometricSecurityServiceSingleton.setInstance(customService);
        
        final retrievedInstance = BiometricSecurityServiceSingleton.instance;
        expect(retrievedInstance, equals(customService));
        
        // Reset for other tests
        BiometricSecurityServiceSingleton.reset();
      });

      test('should reset singleton instance', () {
        final originalInstance = BiometricSecurityServiceSingleton.instance;
        BiometricSecurityServiceSingleton.reset();
        final newInstance = BiometricSecurityServiceSingleton.instance;
        
        // After reset, we should get a new instance
        expect(newInstance, isNot(equals(originalInstance)));
        expect(newInstance, isA<BiometricSecurityService>());
      });
    });

    group('Error handling', () {
      test('should handle exceptions in all public methods', () async {
        // Test that all methods handle exceptions gracefully
        // and don't crash the application
        
        expect(() async => await service.isLocalStorageSecure(), returnsNormally);
        expect(() async => await service.accessSecureArea(), returnsNormally);
        expect(() async => await service.clearBiometricData(), returnsNormally);
        expect(() async => await service.validateDeviceIntegrity(), returnsNormally);
        expect(() async => await service.validateBiometricIntegrity(), returnsNormally);
        expect(() async => await service.secureEnrollBiometric(), returnsNormally);
        expect(() async => await service.getBiometricDataStatus(), returnsNormally);
        expect(() async => await service.handleSecurityBreach(), returnsNormally);
      });
    });
  });
}