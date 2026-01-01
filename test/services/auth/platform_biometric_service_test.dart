import 'package:flutter_test/flutter_test.dart';

import 'package:parion/services/auth/platform_biometric_service.dart';

void main() {
  group('PlatformBiometricService Tests', () {
    tearDown(() {
      PlatformBiometricServiceSingleton.reset();
    });

    group('PlatformBiometricServiceFactory', () {
      test('should create AndroidBiometricService on Android platform', () {
        expect(() => PlatformBiometricServiceFactory.createForTesting(isAndroid: true), 
               returnsNormally);
      });

      test('should create IOSBiometricService on iOS platform', () {
        expect(() => PlatformBiometricServiceFactory.createForTesting(isAndroid: false), 
               returnsNormally);
      });
    });

    group('AndroidBiometricService', () {
      test('getPlatformInfo should return correct Android platform info', () {
        // Arrange
        final androidService = AndroidBiometricService();
        
        // Act
        final info = androidService.getPlatformInfo();
        
        // Assert
        expect(info.platformName, equals('Android'));
        expect(info.platformVersion, equals('API 23+'));
        expect(info.supportedBiometricTypes, contains('fingerprint'));
        expect(info.supportedBiometricTypes, contains('face'));
        expect(info.supportedBiometricTypes, contains('iris'));
        expect(info.hasSecureHardware, isTrue);
        expect(info.hasStrongBiometric, isTrue);
      });

      test('openPlatformBiometricSettings should return false when method channel fails', () async {
        // Arrange
        final androidService = AndroidBiometricService();
        
        // Act
        final result = await androidService.openPlatformBiometricSettings();
        
        // Assert
        // Method channel will fail in test environment, so expect false
        expect(result, isFalse);
      });
    });

    group('IOSBiometricService', () {
      test('getPlatformInfo should return correct iOS platform info', () {
        // Arrange
        final iosService = IOSBiometricService();
        
        // Act
        final info = iosService.getPlatformInfo();
        
        // Assert
        expect(info.platformName, equals('iOS'));
        expect(info.platformVersion, equals('11.0+'));
        expect(info.supportedBiometricTypes, contains('touchid'));
        expect(info.supportedBiometricTypes, contains('faceid'));
        expect(info.hasSecureHardware, isTrue);
        expect(info.hasStrongBiometric, isTrue);
      });

      test('openPlatformBiometricSettings should return false when method channel fails', () async {
        // Arrange
        final iosService = IOSBiometricService();
        
        // Act
        final result = await iosService.openPlatformBiometricSettings();
        
        // Assert
        // Method channel will fail in test environment, so expect false
        expect(result, isFalse);
      });
    });

    group('PlatformBiometricInfo', () {
      test('should serialize to JSON correctly', () {
        // Arrange
        const info = PlatformBiometricInfo(
          platformName: 'Test Platform',
          platformVersion: '1.0',
          supportedBiometricTypes: ['fingerprint', 'face'],
          hasSecureHardware: true,
          hasStrongBiometric: false,
        );
        
        // Act
        final json = info.toJson();
        
        // Assert
        expect(json['platformName'], equals('Test Platform'));
        expect(json['platformVersion'], equals('1.0'));
        expect(json['supportedBiometricTypes'], equals(['fingerprint', 'face']));
        expect(json['hasSecureHardware'], isTrue);
        expect(json['hasStrongBiometric'], isFalse);
      });
    });

    group('Integration Tests', () {
      test('should work with singleton pattern', () {
        // Test setting custom instance
        final mockService = AndroidBiometricService();
        PlatformBiometricServiceSingleton.setInstance(mockService);
        expect(PlatformBiometricServiceSingleton.instance, equals(mockService));
        
        // Test reset
        PlatformBiometricServiceSingleton.reset();
        
        // Test that factory throws on unsupported platform (Windows in test environment)
        expect(() => PlatformBiometricServiceFactory.create(), 
               throwsA(isA<UnsupportedError>()));
      });
    });
  });
}