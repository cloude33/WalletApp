import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:money/models/kmh_transaction.dart';
import 'package:money/models/kmh_transaction_type.dart';
import 'package:money/models/kmh_alert_settings.dart';
import 'package:money/services/kmh_alert_service.dart';
import 'package:money/services/kmh_service.dart';
import 'package:money/services/data_service.dart';
import 'package:money/services/kmh_box_service.dart';
import 'package:money/services/notification_service.dart';
import 'package:money/repositories/kmh_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';

/// **Feature: kmh-account-management, Property 16: Uyarı Eşiği Özelleştirme**
/// **Validates: Requirements 4.5**
///
/// Property: For any alert threshold change, the new threshold values should be
/// saved and used in subsequent alert checks.
void main() {
  group('KMH Alert Threshold Customization Property Tests', () {
    late KmhAlertService alertService;
    late KmhService kmhService;
    late DataService dataService;
    late KmhRepository kmhRepository;
    late NotificationService notificationService;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('kmh_alert_test_');

      // Initialize Hive with the test directory
      Hive.init(testDir.path);

      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(31)) {
        Hive.registerAdapter(KmhTransactionTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(30)) {
        Hive.registerAdapter(KmhTransactionAdapter());
      }

      // Initialize KMH box service
      await KmhBoxService.init();
    });

    setUp(() async {
      // Initialize SharedPreferences with empty data for each test
      SharedPreferences.setMockInitialValues({});

      // Clear the box before each test
      await KmhBoxService.clearAll();

      // Initialize services
      dataService = DataService();
      await dataService.init();
      kmhRepository = KmhRepository();
      notificationService = NotificationService();
      kmhService = KmhService(
        dataService: dataService,
        repository: kmhRepository,
      );
      alertService = KmhAlertService(
        dataService: dataService,
        notificationService: notificationService,
      );

      // Clear cached settings
      alertService.clearCache();
    });

    tearDownAll(() async {
      // Clean up
      await KmhBoxService.close();
      await Hive.close();
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 16: Alert threshold changes are persisted and retrieved correctly',
      generator: () {
        // Generate random threshold values
        final warningThreshold = PropertyTest.randomPositiveDouble(
          min: 50,
          max: 90,
        );
        final criticalThreshold = PropertyTest.randomPositiveDouble(
          min: warningThreshold + 5, // Critical must be higher than warning
          max: 99,
        );
        final minimumInterestAmount = PropertyTest.randomPositiveDouble(
          min: 0.1,
          max: 100,
        );

        return {
          'limitAlertsEnabled': PropertyTest.randomBool(),
          'warningThreshold': warningThreshold,
          'criticalThreshold': criticalThreshold,
          'interestNotificationsEnabled': PropertyTest.randomBool(),
          'minimumInterestAmount': minimumInterestAmount,
        };
      },
      property: (data) async {
        // Create new settings with random values
        final newSettings = KmhAlertSettings(
          limitAlertsEnabled: data['limitAlertsEnabled'],
          warningThreshold: data['warningThreshold'],
          criticalThreshold: data['criticalThreshold'],
          interestNotificationsEnabled: data['interestNotificationsEnabled'],
          minimumInterestAmount: data['minimumInterestAmount'],
        );

        // Property 1: Update settings should succeed
        await alertService.updateAlertSettings(newSettings);

        // Property 2: Retrieved settings should match the saved settings
        final retrievedSettings = await alertService.getAlertSettings();

        expect(
          retrievedSettings.limitAlertsEnabled,
          equals(newSettings.limitAlertsEnabled),
          reason: 'limitAlertsEnabled should be persisted correctly',
        );
        expect(
          retrievedSettings.warningThreshold,
          closeTo(newSettings.warningThreshold, 0.001),
          reason: 'warningThreshold should be persisted correctly',
        );
        expect(
          retrievedSettings.criticalThreshold,
          closeTo(newSettings.criticalThreshold, 0.001),
          reason: 'criticalThreshold should be persisted correctly',
        );
        expect(
          retrievedSettings.interestNotificationsEnabled,
          equals(newSettings.interestNotificationsEnabled),
          reason: 'interestNotificationsEnabled should be persisted correctly',
        );
        expect(
          retrievedSettings.minimumInterestAmount,
          closeTo(newSettings.minimumInterestAmount, 0.001),
          reason: 'minimumInterestAmount should be persisted correctly',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 16: Custom thresholds are used in alert checks',
      generator: () {
        // Generate custom thresholds
        final warningThreshold = PropertyTest.randomPositiveDouble(
          min: 60,
          max: 80,
        );
        final criticalThreshold = PropertyTest.randomPositiveDouble(
          min: warningThreshold + 5,
          max: 95,
        );

        // Generate a utilization rate between warning and critical
        final utilizationRate = PropertyTest.randomPositiveDouble(
          min: warningThreshold + 1,
          max: criticalThreshold - 1,
        );

        // Calculate credit limit and balance to achieve the utilization rate
        final creditLimit = PropertyTest.randomPositiveDouble(
          min: 10000,
          max: 100000,
        );
        final usedCredit = (utilizationRate / 100) * creditLimit;
        final balance = -usedCredit;

        return {
          'warningThreshold': warningThreshold,
          'criticalThreshold': criticalThreshold,
          'creditLimit': creditLimit,
          'balance': balance,
          'utilizationRate': utilizationRate,
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
        };
      },
      property: (data) async {
        // Set custom thresholds
        final customSettings = KmhAlertSettings(
          limitAlertsEnabled: true,
          warningThreshold: data['warningThreshold'],
          criticalThreshold: data['criticalThreshold'],
          interestNotificationsEnabled: true,
          minimumInterestAmount: 1.0,
        );
        await alertService.updateAlertSettings(customSettings);

        // Create KMH account with specific utilization rate
        final account = await kmhService.createKmhAccount(
          bankName: data['bankName'],
          creditLimit: data['creditLimit'],
          interestRate: data['interestRate'],
          initialBalance: data['balance'],
        );

        final utilizationRate = data['utilizationRate'] as double;

        // Verify the account has the expected utilization rate
        expect(
          account.utilizationRate,
          closeTo(utilizationRate, 1.0),
          reason: 'Account should have the expected utilization rate',
        );

        // Property: Alert check should use custom thresholds
        final alerts = await alertService.checkAccountAlerts(account);

        // Since utilizationRate is between warning and critical,
        // we should get a warning alert (not critical)
        expect(
          alerts.length,
          equals(1),
          reason:
              'Should generate one alert for utilization between warning and critical',
        );

        expect(
          alerts[0].type.toString(),
          contains('Warning'),
          reason:
              'Alert should be a warning (not critical) based on custom thresholds',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 16: Threshold changes affect alert generation immediately',
      generator: () {
        // Generate two distinct threshold sets
        final lowWarningThreshold = PropertyTest.randomPositiveDouble(
          min: 40,
          max: 60,
        );
        final lowCriticalThreshold = PropertyTest.randomPositiveDouble(
          min: lowWarningThreshold + 5,
          max: 70,
        );

        final highWarningThreshold = PropertyTest.randomPositiveDouble(
          min: 85,
          max: 92,
        );
        final highCriticalThreshold = PropertyTest.randomPositiveDouble(
          min: highWarningThreshold + 2,
          max: 98,
        );

        // Create utilization rate between the two warning thresholds
        final utilizationRate = PropertyTest.randomPositiveDouble(
          min: lowWarningThreshold + 2,
          max: highWarningThreshold - 2,
        );

        final creditLimit = PropertyTest.randomPositiveDouble(
          min: 10000,
          max: 100000,
        );
        final usedCredit = (utilizationRate / 100) * creditLimit;
        final balance = -usedCredit;

        return {
          'lowWarningThreshold': lowWarningThreshold,
          'lowCriticalThreshold': lowCriticalThreshold,
          'highWarningThreshold': highWarningThreshold,
          'highCriticalThreshold': highCriticalThreshold,
          'creditLimit': creditLimit,
          'balance': balance,
          'utilizationRate': utilizationRate,
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
        };
      },
      property: (data) async {
        final lowWarningThreshold = data['lowWarningThreshold'] as double;
        final highWarningThreshold = data['highWarningThreshold'] as double;

        // Create account
        final account = await kmhService.createKmhAccount(
          bankName: data['bankName'],
          creditLimit: data['creditLimit'],
          interestRate: data['interestRate'],
          initialBalance: data['balance'],
        );

        // Property 1: With high thresholds, no alert should be generated
        final highSettings = KmhAlertSettings(
          limitAlertsEnabled: true,
          warningThreshold: data['highWarningThreshold'],
          criticalThreshold: data['highCriticalThreshold'],
          interestNotificationsEnabled: true,
          minimumInterestAmount: 1.0,
        );
        await alertService.updateAlertSettings(highSettings);
        alertService.clearCache();

        final alertsWithHighThresholds = await alertService.checkAccountAlerts(
          account,
        );
        expect(
          alertsWithHighThresholds.length,
          equals(0),
          reason:
              'No alerts with high thresholds (utilization: ${account.utilizationRate}%, threshold: $highWarningThreshold%)',
        );

        // Property 2: With low thresholds, alert should be generated
        final lowSettings = KmhAlertSettings(
          limitAlertsEnabled: true,
          warningThreshold: data['lowWarningThreshold'],
          criticalThreshold: data['lowCriticalThreshold'],
          interestNotificationsEnabled: true,
          minimumInterestAmount: 1.0,
        );
        await alertService.updateAlertSettings(lowSettings);
        alertService.clearCache();

        final alertsWithLowThresholds = await alertService.checkAccountAlerts(
          account,
        );
        expect(
          alertsWithLowThresholds.length,
          greaterThan(0),
          reason:
              'Alerts should be generated with low thresholds (utilization: ${account.utilizationRate}%, threshold: $lowWarningThreshold%)',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 16: Multiple threshold updates maintain consistency',
      generator: () {
        // Generate multiple sets of threshold values
        final threshold1Warning = PropertyTest.randomPositiveDouble(
          min: 50,
          max: 70,
        );
        final threshold1Critical = PropertyTest.randomPositiveDouble(
          min: threshold1Warning + 5,
          max: 90,
        );

        final threshold2Warning = PropertyTest.randomPositiveDouble(
          min: 60,
          max: 80,
        );
        final threshold2Critical = PropertyTest.randomPositiveDouble(
          min: threshold2Warning + 5,
          max: 95,
        );

        final threshold3Warning = PropertyTest.randomPositiveDouble(
          min: 70,
          max: 85,
        );
        final threshold3Critical = PropertyTest.randomPositiveDouble(
          min: threshold3Warning + 5,
          max: 99,
        );

        return {
          'threshold1Warning': threshold1Warning,
          'threshold1Critical': threshold1Critical,
          'threshold2Warning': threshold2Warning,
          'threshold2Critical': threshold2Critical,
          'threshold3Warning': threshold3Warning,
          'threshold3Critical': threshold3Critical,
          'enabled1': PropertyTest.randomBool(),
          'enabled2': PropertyTest.randomBool(),
          'enabled3': PropertyTest.randomBool(),
        };
      },
      property: (data) async {
        // Property: Multiple sequential updates should each be persisted correctly

        // Update 1
        final settings1 = KmhAlertSettings(
          limitAlertsEnabled: data['enabled1'],
          warningThreshold: data['threshold1Warning'],
          criticalThreshold: data['threshold1Critical'],
          interestNotificationsEnabled: true,
          minimumInterestAmount: 1.0,
        );
        await alertService.updateAlertSettings(settings1);
        alertService.clearCache();

        final retrieved1 = await alertService.getAlertSettings();
        expect(
          retrieved1.warningThreshold,
          closeTo(data['threshold1Warning'], 0.001),
        );
        expect(
          retrieved1.criticalThreshold,
          closeTo(data['threshold1Critical'], 0.001),
        );
        expect(retrieved1.limitAlertsEnabled, equals(data['enabled1']));

        // Update 2
        final settings2 = KmhAlertSettings(
          limitAlertsEnabled: data['enabled2'],
          warningThreshold: data['threshold2Warning'],
          criticalThreshold: data['threshold2Critical'],
          interestNotificationsEnabled: false,
          minimumInterestAmount: 5.0,
        );
        await alertService.updateAlertSettings(settings2);
        alertService.clearCache();

        final retrieved2 = await alertService.getAlertSettings();
        expect(
          retrieved2.warningThreshold,
          closeTo(data['threshold2Warning'], 0.001),
        );
        expect(
          retrieved2.criticalThreshold,
          closeTo(data['threshold2Critical'], 0.001),
        );
        expect(retrieved2.limitAlertsEnabled, equals(data['enabled2']));

        // Update 3
        final settings3 = KmhAlertSettings(
          limitAlertsEnabled: data['enabled3'],
          warningThreshold: data['threshold3Warning'],
          criticalThreshold: data['threshold3Critical'],
          interestNotificationsEnabled: true,
          minimumInterestAmount: 10.0,
        );
        await alertService.updateAlertSettings(settings3);
        alertService.clearCache();

        final retrieved3 = await alertService.getAlertSettings();
        expect(
          retrieved3.warningThreshold,
          closeTo(data['threshold3Warning'], 0.001),
        );
        expect(
          retrieved3.criticalThreshold,
          closeTo(data['threshold3Critical'], 0.001),
        );
        expect(retrieved3.limitAlertsEnabled, equals(data['enabled3']));

        // Property: Final retrieved settings should match the last update
        expect(
          retrieved3.warningThreshold,
          closeTo(settings3.warningThreshold, 0.001),
          reason: 'Final settings should match last update',
        );
        expect(
          retrieved3.criticalThreshold,
          closeTo(settings3.criticalThreshold, 0.001),
          reason: 'Final settings should match last update',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 16: Disabled alerts prevent notification generation',
      generator: () {
        // Generate high utilization rate that would normally trigger alerts
        final utilizationRate = PropertyTest.randomPositiveDouble(
          min: 85,
          max: 99,
        );
        final creditLimit = PropertyTest.randomPositiveDouble(
          min: 10000,
          max: 100000,
        );
        final usedCredit = (utilizationRate / 100) * creditLimit;
        final balance = -usedCredit;

        return {
          'creditLimit': creditLimit,
          'balance': balance,
          'utilizationRate': utilizationRate,
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
        };
      },
      property: (data) async {
        // Create account with high utilization
        final account = await kmhService.createKmhAccount(
          bankName: data['bankName'],
          creditLimit: data['creditLimit'],
          interestRate: data['interestRate'],
          initialBalance: data['balance'],
        );

        // Property 1: With alerts enabled, should generate alerts
        final settingsEnabled = KmhAlertSettings(
          limitAlertsEnabled: true,
          warningThreshold: 80.0,
          criticalThreshold: 95.0,
          interestNotificationsEnabled: true,
          minimumInterestAmount: 1.0,
        );
        await alertService.updateAlertSettings(settingsEnabled);
        alertService.clearCache();

        final alertsEnabled = await alertService.checkAccountAlerts(account);
        expect(
          alertsEnabled.length,
          greaterThan(0),
          reason: 'Should generate alerts when enabled',
        );

        // Property 2: With alerts disabled, should not generate alerts
        final settingsDisabled = KmhAlertSettings(
          limitAlertsEnabled: false, // Disabled
          warningThreshold: 80.0,
          criticalThreshold: 95.0,
          interestNotificationsEnabled: true,
          minimumInterestAmount: 1.0,
        );
        await alertService.updateAlertSettings(settingsDisabled);
        alertService.clearCache();

        final alertsDisabled = await alertService.checkAccountAlerts(account);
        expect(
          alertsDisabled.length,
          equals(0),
          reason: 'Should not generate alerts when disabled',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 16: Interest notification threshold is respected',
      generator: () {
        // Generate interest amount and threshold
        // Make sure they're clearly separated to avoid edge cases
        final minimumThreshold = PropertyTest.randomPositiveDouble(
          min: 5,
          max: 50,
        );

        // Generate interest amount that's either clearly above or clearly below threshold
        final isAboveThreshold = PropertyTest.randomBool();
        final interestAmount = isAboveThreshold
            ? PropertyTest.randomPositiveDouble(
                min: minimumThreshold + 5,
                max: 100,
              )
            : PropertyTest.randomPositiveDouble(
                min: 0.1,
                max: minimumThreshold - 1,
              );

        final creditLimit = PropertyTest.randomPositiveDouble(
          min: 10000,
          max: 100000,
        );
        final balance = PropertyTest.randomDouble(
          min: -creditLimit,
          max: -1000,
        );

        return {
          'interestAmount': interestAmount,
          'minimumThreshold': minimumThreshold,
          'creditLimit': creditLimit,
          'balance': balance,
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'isAboveThreshold': isAboveThreshold,
        };
      },
      property: (data) async {
        // Create account
        final account = await kmhService.createKmhAccount(
          bankName: data['bankName'],
          creditLimit: data['creditLimit'],
          interestRate: data['interestRate'],
          initialBalance: data['balance'],
        );

        final interestAmount = data['interestAmount'] as double;
        final minimumThreshold = data['minimumThreshold'] as double;
        final isAboveThreshold = data['isAboveThreshold'] as bool;

        // Verify test setup
        if (isAboveThreshold) {
          expect(
            interestAmount,
            greaterThanOrEqualTo(minimumThreshold),
            reason: 'Test setup: interest should be >= threshold',
          );
        } else {
          expect(
            interestAmount,
            lessThan(minimumThreshold),
            reason: 'Test setup: interest should be < threshold',
          );
        }

        // Set custom minimum interest threshold
        final settings = KmhAlertSettings(
          limitAlertsEnabled: true,
          warningThreshold: 80.0,
          criticalThreshold: 95.0,
          interestNotificationsEnabled: true,
          minimumInterestAmount: minimumThreshold,
        );
        await alertService.updateAlertSettings(settings);
        alertService.clearCache();

        // Clear any existing notifications
        final existingNotifications = await notificationService
            .getNotifications();
        for (final notif in existingNotifications) {
          await notificationService.deleteNotification(notif.id);
        }

        // Try to send interest notification
        await alertService.sendInterestNotification(account, interestAmount);

        // Get notifications
        final notifications = await notificationService.getNotifications();

        // Property: Notification should only be sent if interest >= threshold
        if (interestAmount >= minimumThreshold) {
          expect(
            notifications.length,
            greaterThan(0),
            reason:
                'Should send notification when interest ($interestAmount) >= threshold ($minimumThreshold)',
          );
        } else {
          expect(
            notifications.length,
            equals(0),
            reason:
                'Should not send notification when interest ($interestAmount) < threshold ($minimumThreshold)',
          );
        }

        return true;
      },
      iterations: 100,
    );
  });
}
