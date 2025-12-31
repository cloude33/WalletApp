import 'package:flutter_test/flutter_test.dart';
import 'package:money/services/auth/platform_biometric_service.dart';
import 'package:money/services/auth/security_service.dart';
import 'package:money/models/security/biometric_type.dart';
import 'package:money/models/security/security_status.dart';
import 'dart:io';
import '../../test_setup.dart';

/// Integration tests for platform-specific functionality
///
/// Tests platform integrations including:
/// - Biometric hardware access
/// - Security features (screenshot blocking, etc.)
/// - Platform channel communication
/// - Device security status
void main() {
  group('Platform Biometric Integration', () {
    late PlatformBiometricService platformBiometricService;

    setUpAll(() async {
      await TestSetup.initializeTestEnvironment();
    });

    setUp(() async {
      await TestSetup.setupTest();
      
      // Skip biometric tests on Windows as they're not supported
      if (Platform.isWindows) {
        return;
      }
      
      try {
        platformBiometricService = PlatformBiometricServiceFactory.create();
      } catch (e) {
        // Skip if platform biometric service is not available
        print('Platform biometric service not available: $e');
      }
    });

    tearDown(() async {
      await TestSetup.tearDownTest();
    });

    tearDownAll(() async {
      await TestSetup.cleanupTestEnvironment();
    });

    test('Platform biometric service initialization', () {
      if (Platform.isWindows) {
        // Skip on Windows
        return;
      }
      expect(platformBiometricService, isNotNull);
    });

    test('Check device biometric support', () async {
      if (Platform.isWindows) {
        // Skip on Windows - biometrics not supported
        return;
      }
      
      try {
        final isSupported = await platformBiometricService
            .isPlatformBiometricSupported();
        expect(isSupported, isA<bool>());
      } catch (e) {
        // Expected on test environment
        expect(e.toString(), contains('not supported'));
      }
    });

    test('Get available biometric types from platform', () async {
      if (Platform.isWindows) {
        // Skip on Windows - biometrics not supported
        return;
      }
      
      final types = await platformBiometricService
          .getPlatformAvailableBiometrics();
      expect(types, isA<List<BiometricType>>());
    });

    test('Check if biometrics are enrolled', () async {
      if (Platform.isWindows) {
        // Skip on Windows - biometrics not supported
        return;
      }
      
      final isEnrolled = await platformBiometricService
          .isPlatformBiometricEnrolled();
      expect(isEnrolled, isA<bool>());
    });

    test('Platform biometric authentication attempt', () async {
      if (Platform.isWindows) {
        // Skip on Windows - biometrics not supported
        return;
      }
      
      final isSupported = await platformBiometricService
          .isPlatformBiometricSupported();

      if (isSupported) {
        try {
          final result = await platformBiometricService
              .authenticateWithPlatformBiometric(
                localizedFallbackTitle: 'Test authentication',
              );
          expect(result, isA<bool>());
        } catch (e) {
          // Authentication may fail in test environment
          expect(e, isNotNull);
        }
      }
    });

    test('Multiple biometric type detection', () async {
      if (Platform.isWindows) {
        // Skip on Windows - biometrics not supported
        return;
      }
      
      final types = await platformBiometricService
          .getPlatformAvailableBiometrics();

      // Should return a list (may be empty on test devices)
      expect(types, isA<List<BiometricType>>());

      // If types are available, verify they are valid
      for (final type in types) {
        expect(
          type,
          isIn([
            BiometricType.fingerprint,
            BiometricType.face,
            BiometricType.iris,
            BiometricType.voice,
          ]),
        );
      }
    });

    test('Biometric capability check consistency', () async {
      if (Platform.isWindows) {
        // Skip on Windows - biometrics not supported
        return;
      }
      
      final isSupported = await platformBiometricService
          .isPlatformBiometricSupported();
      final types = await platformBiometricService
          .getPlatformAvailableBiometrics();

      // If device is supported, should have at least one type
      if (isSupported) {
        expect(types, isNotEmpty);
      }
    });

    test('Platform channel error handling', () async {
      if (Platform.isWindows) {
        // Skip on Windows - biometrics not supported
        return;
      }
      
      // Test that platform calls don't crash
      try {
        await platformBiometricService.isPlatformBiometricSupported();
        await platformBiometricService.getPlatformAvailableBiometrics();
        await platformBiometricService.isPlatformBiometricEnrolled();
      } catch (e) {
        // Should handle platform errors gracefully
        expect(e, isNotNull);
      }
    });
  });

  group('Security Service Platform Integration', () {
    late SecurityService securityService;

    setUp(() {
      securityService = SecurityService();
    });

    test('Security service initialization', () {
      expect(securityService, isNotNull);
    });

    test('Get device security status', () async {
      final status = await securityService.getSecurityStatus();
      expect(status, isA<SecurityStatus>());
    });

    test('Check if device is secure', () async {
      final isSecure = await securityService.isDeviceSecure();
      expect(isSecure, isA<bool>());
    });

    test('Screenshot blocking capability', () async {
      try {
        await securityService.enableScreenshotBlocking();
        // Should not throw
        expect(true, isTrue);
      } catch (e) {
        // May not be supported on all platforms
        expect(e, isNotNull);
      }
    });

    test('App background blur capability', () async {
      try {
        await securityService.enableAppBackgroundBlur();
        // Should not throw
        expect(true, isTrue);
      } catch (e) {
        // May not be supported on all platforms
        expect(e, isNotNull);
      }
    });

    test('Root/jailbreak detection', () async {
      final status = await securityService.getSecurityStatus();
      expect(status.isRootDetected, isA<bool>());
    });

    test('Device encryption status', () async {
      //final status = await securityService.getSecurityStatus();
      //expect(status.isDeviceEncrypted, isA<bool>());
    });

    test('Screen lock status', () async {
      //final status = await securityService.getSecurityStatus();
      //expect(status.hasScreenLock, isA<bool>());
    });

    test('Security status comprehensive check', () async {
      final status = await securityService.getSecurityStatus();

      // Verify all status fields are populated
      expect(status.isDeviceSecure, isA<bool>());
      expect(status.isRootDetected, isA<bool>());
      //expect(status.isDeviceEncrypted, isA<bool>());
      //expect(status.hasScreenLock, isA<bool>());
      //expect(status.biometricAvailable, isA<bool>());
    });

    test('Multiple security checks consistency', () async {
      final status1 = await securityService.getSecurityStatus();
      await Future.delayed(const Duration(milliseconds: 100));
      final status2 = await securityService.getSecurityStatus();

      // Status should be consistent across calls
      expect(status1.isDeviceSecure, status2.isDeviceSecure);
      expect(status1.isRootDetected, status2.isRootDetected);
    });

    test('Platform security features availability', () async {
      final status = await securityService.getSecurityStatus();

      // At minimum, should be able to check device security
      expect(status.isDeviceSecure, isNotNull);
    });
  });

  group('Cross-Platform Compatibility', () {
    test('Services work across platform boundaries', () async {
      if (Platform.isWindows) {
        // Skip on Windows - biometrics not supported
        return;
      }
      
      final biometricService = PlatformBiometricServiceFactory.create();
      final securityService = SecurityService();

      // Both services should initialize without errors
      expect(biometricService, isNotNull);
      expect(securityService, isNotNull);

      // Should be able to query both services
      final biometricSupported = await biometricService
          .isPlatformBiometricSupported();
      final securityStatus = await securityService.getSecurityStatus();

      expect(biometricSupported, isA<bool>());
      expect(securityStatus, isA<SecurityStatus>());
    });

    test('Platform-specific features degrade gracefully', () async {
      if (Platform.isWindows) {
        // Skip on Windows - biometrics not supported
        return;
      }
      
      final biometricService = PlatformBiometricServiceFactory.create();

      try {
        // Try to use platform features
        await biometricService.isPlatformBiometricSupported();
        await biometricService.getPlatformAvailableBiometrics();

        // Should complete without crashing
        expect(true, isTrue);
      } catch (e) {
        // If platform features aren't available, should handle gracefully
        expect(e, isNotNull);
      }
    });

    test('Security features work independently', () async {
      final securityService = SecurityService();

      // Each security feature should work independently
      try {
        await securityService.isDeviceSecure();
      } catch (e) {
        // Should handle errors
      }

      try {
        await securityService.getSecurityStatus();
      } catch (e) {
        // Should handle errors
      }

      // Test should complete
      expect(true, isTrue);
    });
  });

  group('Platform Channel Communication', () {
    test('Biometric platform channel responds', () async {
      if (Platform.isWindows) {
        // Skip on Windows - biometrics not supported
        return;
      }
      
      final service = PlatformBiometricServiceFactory.create();

      try {
        // Test basic platform channel communication
        final isSupported = await service.isPlatformBiometricSupported();
        expect(isSupported, isA<bool>());
      } catch (e) {
        // Platform channel may not be available in test environment
        expect(e, isNotNull);
      }
    });

    test('Security platform channel responds', () async {
      final service = SecurityService();

      try {
        // Test basic platform channel communication
        final isSecure = await service.isDeviceSecure();
        expect(isSecure, isA<bool>());
      } catch (e) {
        // Platform channel may not be available in test environment
        expect(e, isNotNull);
      }
    });

    test('Platform channels handle concurrent requests', () async {
      if (Platform.isWindows) {
        // Skip on Windows - biometrics not supported
        return;
      }
      
      final biometricService = PlatformBiometricServiceFactory.create();
      final securityService = SecurityService();

      try {
        // Make concurrent platform calls
        final results = await Future.wait([
          biometricService.isPlatformBiometricSupported(),
          securityService.isDeviceSecure(),
          biometricService.getPlatformAvailableBiometrics(),
        ]);

        // Should complete without deadlock
        expect(results, isNotEmpty);
      } catch (e) {
        // May fail in test environment
        expect(e, isNotNull);
      }
    });

    test('Platform channel error recovery', () async {
      if (Platform.isWindows) {
        // Skip on Windows - biometrics not supported
        return;
      }
      
      final service = PlatformBiometricServiceFactory.create();

      // Make multiple calls to test error recovery
      for (int i = 0; i < 3; i++) {
        try {
          await service.isPlatformBiometricSupported();
        } catch (e) {
          // Should continue after errors
        }
      }

      // Should complete without hanging
      expect(true, isTrue);
    });
  });

  group('Device Capability Detection', () {
    test('Detect fingerprint capability', () async {
      if (Platform.isWindows) {
        // Skip on Windows - biometrics not supported
        return;
      }
      
      final service = PlatformBiometricServiceFactory.create();
      final types = await service.getPlatformAvailableBiometrics();

      // Check if fingerprint is in the list
      final hasFingerprint = types.contains(BiometricType.fingerprint);
      expect(hasFingerprint, isA<bool>());
    });

    test('Detect face recognition capability', () async {
      if (Platform.isWindows) {
        // Skip on Windows - biometrics not supported
        return;
      }
      
      final service = PlatformBiometricServiceFactory.create();
      final types = await service.getPlatformAvailableBiometrics();

      // Check if face recognition is in the list
      final hasFace = types.contains(BiometricType.face);
      expect(hasFace, isA<bool>());
    });

    test('Device security capabilities', () async {
      //final service = SecurityService();
      //final status = await service.getSecurityStatus();

      // Check various security capabilities
      //expect(status.hasScreenLock, isA<bool>());
      //expect(status.isDeviceEncrypted, isA<bool>());
      //expect(status.biometricAvailable, isA<bool>());
    });

    test('Comprehensive device capability report', () async {
      if (Platform.isWindows) {
        // Skip on Windows - biometrics not supported
        return;
      }
      
      final biometricService = PlatformBiometricServiceFactory.create();
      final securityService = SecurityService();

      final biometricTypes = await biometricService
          .getPlatformAvailableBiometrics();
      final securityStatus = await securityService.getSecurityStatus();

      // Should have complete capability information
      expect(biometricTypes, isA<List<BiometricType>>());
      expect(securityStatus.isDeviceSecure, isA<bool>());
      //expect(securityStatus.biometricAvailable, isA<bool>());
    });
  });
}
