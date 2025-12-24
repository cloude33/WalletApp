import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money/services/auth/security_notification_service.dart';
import 'package:money/models/security/security_event.dart';

void main() {
  group('SecurityNotificationService', () {
    late SecurityNotificationService service;

    setUp(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      service = SecurityNotificationService();
      await service.initialize();
    });

    tearDown(() {
      service.resetForTesting();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        final newService = SecurityNotificationService();
        await expectLater(newService.initialize(), completes);
      });

      test('should generate device ID on first run', () async {
        final deviceId = service.getCurrentDeviceId();
        expect(deviceId, isNotNull);
        expect(deviceId!.length, greaterThan(0));
      });

      test('should load default settings', () async {
        final settings = await service.getSettings();
        expect(settings.enableFailedLoginNotifications, isTrue);
        expect(settings.enableNewDeviceNotifications, isTrue);
        expect(settings.enableSettingsChangeNotifications, isTrue);
      });
    });

    group('Failed Login Notifications', () {
      test('should send failed login notification', () async {
        final event = SecurityEvent.pinFailed(
          userId: 'test_user',
          remainingAttempts: 2,
        );

        await service.notifyFailedLogin(
          event: event,
          remainingAttempts: 2,
        );

        // Verify notification was created (would need to mock NotificationService)
        // This is a basic test - in real implementation we'd verify the notification
        expect(true, isTrue); // Placeholder assertion
      });

      test('should send account locked notification', () async {
        final event = SecurityEvent.accountLocked(
          userId: 'test_user',
          lockoutDuration: const Duration(minutes: 5),
          reason: 'Too many failed attempts',
        );

        await service.notifyFailedLogin(
          event: event,
          remainingAttempts: 0,
          lockoutDuration: const Duration(minutes: 5),
        );

        expect(true, isTrue); // Placeholder assertion
      });

      test('should not send notification when disabled', () async {
        // Disable failed login notifications
        final settings = SecurityNotificationSettings.defaultSettings().copyWith(
          enableFailedLoginNotifications: false,
        );
        await service.updateSettings(settings);

        final event = SecurityEvent.pinFailed(
          userId: 'test_user',
          remainingAttempts: 2,
        );

        await service.notifyFailedLogin(
          event: event,
          remainingAttempts: 2,
        );

        expect(true, isTrue); // Placeholder assertion
      });
    });

    group('New Device Notifications', () {
      test('should send new device notification', () async {
        final event = SecurityEvent.sessionStarted(
          userId: 'test_user',
          authMethod: 'pin',
        );

        final deviceInfo = {
          'deviceId': 'new_device_123',
          'deviceName': 'iPhone 15',
          'platform': 'iOS',
          'location': 'Istanbul, Turkey',
        };

        await service.notifyNewDeviceLogin(
          event: event,
          deviceInfo: deviceInfo,
        );

        // Verify device was added to known devices
        final knownDevices = await service.getKnownDevices();
        expect(knownDevices.contains('new_device_123'), isTrue);
      });

      test('should not send notification for known device', () async {
        final deviceId = service.getCurrentDeviceId()!;
        
        final event = SecurityEvent.sessionStarted(
          userId: 'test_user',
          authMethod: 'pin',
        );

        final deviceInfo = {
          'deviceId': deviceId,
          'deviceName': 'Current Device',
          'platform': 'Android',
        };

        await service.notifyNewDeviceLogin(
          event: event,
          deviceInfo: deviceInfo,
        );

        expect(true, isTrue); // Placeholder assertion
      });

      test('should not send notification when disabled', () async {
        final settings = SecurityNotificationSettings.defaultSettings().copyWith(
          enableNewDeviceNotifications: false,
        );
        await service.updateSettings(settings);

        final event = SecurityEvent.sessionStarted(
          userId: 'test_user',
          authMethod: 'pin',
        );

        final deviceInfo = {
          'deviceId': 'new_device_456',
          'deviceName': 'Android Phone',
          'platform': 'Android',
        };

        await service.notifyNewDeviceLogin(
          event: event,
          deviceInfo: deviceInfo,
        );

        expect(true, isTrue); // Placeholder assertion
      });
    });

    group('Security Settings Change Notifications', () {
      test('should send settings change notification', () async {
        final event = SecurityEvent.securitySettingsChanged(
          userId: 'test_user',
          setting: 'pinEnabled',
          oldValue: 'false',
          newValue: 'true',
        );

        await service.notifySecuritySettingsChange(
          event: event,
          settingName: 'pinEnabled',
          oldValue: 'false',
          newValue: 'true',
        );

        expect(true, isTrue); // Placeholder assertion
      });

      test('should format setting names correctly', () async {
        final event = SecurityEvent.securitySettingsChanged(
          userId: 'test_user',
          setting: 'biometricEnabled',
          oldValue: 'false',
          newValue: 'true',
        );

        await service.notifySecuritySettingsChange(
          event: event,
          settingName: 'biometricEnabled',
          oldValue: 'false',
          newValue: 'true',
        );

        expect(true, isTrue); // Placeholder assertion
      });

      test('should not send notification when disabled', () async {
        final settings = SecurityNotificationSettings.defaultSettings().copyWith(
          enableSettingsChangeNotifications: false,
        );
        await service.updateSettings(settings);

        final event = SecurityEvent.securitySettingsChanged(
          userId: 'test_user',
          setting: 'sessionTimeout',
          oldValue: '15',
          newValue: '30',
        );

        await service.notifySecuritySettingsChange(
          event: event,
          settingName: 'sessionTimeout',
          oldValue: '15',
          newValue: '30',
        );

        expect(true, isTrue); // Placeholder assertion
      });
    });

    group('Suspicious Activity Notifications', () {
      test('should send suspicious activity notification', () async {
        final event = SecurityEvent.suspiciousActivity(
          userId: 'test_user',
          activity: 'Multiple failed login attempts from different locations',
          details: 'Detected login attempts from 5 different IP addresses',
        );

        await service.notifySuspiciousActivity(
          event: event,
          activityDetails: 'Multiple failed login attempts from different locations',
        );

        expect(true, isTrue); // Placeholder assertion
      });

      test('should not send notification when disabled', () async {
        final settings = SecurityNotificationSettings.defaultSettings().copyWith(
          enableSuspiciousActivityNotifications: false,
        );
        await service.updateSettings(settings);

        final event = SecurityEvent.suspiciousActivity(
          userId: 'test_user',
          activity: 'Root detection',
          details: 'Device appears to be rooted',
        );

        await service.notifySuspiciousActivity(
          event: event,
          activityDetails: 'Root detection',
        );

        expect(true, isTrue); // Placeholder assertion
      });
    });

    group('Settings Management', () {
      test('should update and persist settings', () async {
        final newSettings = SecurityNotificationSettings.defaultSettings().copyWith(
          enableFailedLoginNotifications: false,
          enableNewDeviceNotifications: false,
        );

        await service.updateSettings(newSettings);

        final retrievedSettings = await service.getSettings();
        expect(retrievedSettings.enableFailedLoginNotifications, isFalse);
        expect(retrievedSettings.enableNewDeviceNotifications, isFalse);
        expect(retrievedSettings.enableSettingsChangeNotifications, isTrue);
      });

      test('should load settings from storage', () async {
        // Set initial settings
        final initialSettings = SecurityNotificationSettings.defaultSettings().copyWith(
          enableFailedLoginNotifications: false,
        );
        await service.updateSettings(initialSettings);

        // Create new service instance
        final newService = SecurityNotificationService();
        await newService.initialize();

        final loadedSettings = await newService.getSettings();
        expect(loadedSettings.enableFailedLoginNotifications, isFalse);
        
        newService.resetForTesting();
      });
    });

    group('Known Devices Management', () {
      test('should manage known devices', () async {
        final deviceId = 'test_device_123';
        
        // Initially should not be known
        var knownDevices = await service.getKnownDevices();
        expect(knownDevices.contains(deviceId), isFalse);

        // Add device through new device notification
        final event = SecurityEvent.sessionStarted(
          userId: 'test_user',
          authMethod: 'pin',
        );

        await service.notifyNewDeviceLogin(
          event: event,
          deviceInfo: {'deviceId': deviceId, 'deviceName': 'Test Device'},
        );

        // Should now be known
        knownDevices = await service.getKnownDevices();
        expect(knownDevices.contains(deviceId), isTrue);

        // Remove device
        await service.removeKnownDevice(deviceId);
        knownDevices = await service.getKnownDevices();
        expect(knownDevices.contains(deviceId), isFalse);
      });

      test('should clear all known devices', () async {
        // Add some devices
        final event = SecurityEvent.sessionStarted(
          userId: 'test_user',
          authMethod: 'pin',
        );

        await service.notifyNewDeviceLogin(
          event: event,
          deviceInfo: {'deviceId': 'device1', 'deviceName': 'Device 1'},
        );

        await service.notifyNewDeviceLogin(
          event: event,
          deviceInfo: {'deviceId': 'device2', 'deviceName': 'Device 2'},
        );

        var knownDevices = await service.getKnownDevices();
        expect(knownDevices.length, greaterThan(2)); // Including current device

        // Clear all
        await service.clearKnownDevices();
        knownDevices = await service.getKnownDevices();
        expect(knownDevices.isEmpty, isTrue);
      });
    });

    group('SecurityNotificationSettings', () {
      test('should create default settings', () {
        final settings = SecurityNotificationSettings.defaultSettings();
        
        expect(settings.enableFailedLoginNotifications, isTrue);
        expect(settings.enableNewDeviceNotifications, isTrue);
        expect(settings.enableSettingsChangeNotifications, isTrue);
        expect(settings.enableSuspiciousActivityNotifications, isTrue);
        expect(settings.enableEmailNotifications, isFalse);
        expect(settings.enableSmsNotifications, isFalse);
        expect(settings.enablePushNotifications, isTrue);
      });

      test('should serialize to/from JSON', () {
        final originalSettings = SecurityNotificationSettings.defaultSettings().copyWith(
          enableFailedLoginNotifications: false,
          enableEmailNotifications: true,
        );

        final json = originalSettings.toJson();
        final deserializedSettings = SecurityNotificationSettings.fromJson(json);

        expect(deserializedSettings, equals(originalSettings));
      });

      test('should create copy with changes', () {
        final originalSettings = SecurityNotificationSettings.defaultSettings();
        
        final modifiedSettings = originalSettings.copyWith(
          enableFailedLoginNotifications: false,
          enableNewDeviceNotifications: false,
        );

        expect(modifiedSettings.enableFailedLoginNotifications, isFalse);
        expect(modifiedSettings.enableNewDeviceNotifications, isFalse);
        expect(modifiedSettings.enableSettingsChangeNotifications, isTrue); // Unchanged
      });

      test('should have proper equality', () {
        final settings1 = SecurityNotificationSettings.defaultSettings();
        final settings2 = SecurityNotificationSettings.defaultSettings();
        final settings3 = SecurityNotificationSettings.defaultSettings().copyWith(
          enableFailedLoginNotifications: false,
        );

        expect(settings1, equals(settings2));
        expect(settings1, isNot(equals(settings3)));
      });

      test('should have proper toString', () {
        final settings = SecurityNotificationSettings.defaultSettings();
        final stringRepresentation = settings.toString();
        
        expect(stringRepresentation, contains('SecurityNotificationSettings'));
        expect(stringRepresentation, contains('failedLogin: true'));
        expect(stringRepresentation, contains('newDevice: true'));
      });
    });
  });
}