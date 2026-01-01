import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:parion/services/backup_optimization/backup_configuration_manager.dart';
import 'package:parion/models/backup_optimization/backup_config.dart';
import 'package:parion/models/backup_optimization/backup_enums.dart';
import '../../property_test_utils.dart';
import '../../test_helpers.dart';

void main() {
  setupCommonTestMocks();
  group('Backup Strategy Preference Persistence Property Tests', () {
    late BackupConfigurationManager configManager;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      configManager = BackupConfigurationManager();
      await configManager.initialize();
    });

    tearDown(() {
      configManager.clearCache();
    });

    /// **Feature: backup-optimization, Property 12: Backup Strategy Preference Persistence**
    /// **Validates: Requirements 4.4**
    PropertyTest.forAll<BackupConfig>(
      description:
          'Property 12: For any backup strategy change, the system should persist the user\'s preference for future operations',
      generator: _generateRandomBackupConfig,
      property: (config) async {
        // Store the configuration
        await configManager.storeConfiguration(config);

        // Clear cache to force retrieval from storage
        configManager.clearCache();

        // Retrieve the configuration
        final retrievedConfig = await configManager.retrieveConfiguration();

        // Verify that the backup type (strategy) is persisted correctly
        final strategyPersisted = retrievedConfig.type == config.type;

        // Verify that other strategy-related preferences are also persisted
        final categoriesPersisted = _listsEqual(
          retrievedConfig.includedCategories,
          config.includedCategories,
        );

        final compressionPersisted =
            retrievedConfig.compressionLevel == config.compressionLevel;
        final validationPersisted =
            retrievedConfig.enableValidation == config.enableValidation;

        // Verify retention policy persistence
        final retentionPersisted = _retentionPolicyEqual(
          retrievedConfig.retentionPolicy,
          config.retentionPolicy,
        );

        // Verify schedule config persistence (if present)
        bool scheduleConfigPersisted = true;
        if (config.scheduleConfig != null) {
          if (retrievedConfig.scheduleConfig == null) {
            scheduleConfigPersisted = false;
          } else {
            scheduleConfigPersisted = _scheduleConfigEqual(
              retrievedConfig.scheduleConfig!,
              config.scheduleConfig!,
            );
          }
        } else {
          scheduleConfigPersisted = retrievedConfig.scheduleConfig == null;
        }

        return strategyPersisted &&
            categoriesPersisted &&
            compressionPersisted &&
            validationPersisted &&
            retentionPersisted &&
            scheduleConfigPersisted;
      },
      iterations: 20,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 12a: User preference updates should be persisted independently',
      generator: _generateRandomUserPreferences,
      property: (preferences) async {
        // Store the preferences
        await configManager.storeUserPreferences(preferences);

        // Clear cache to force retrieval from storage
        configManager.clearCache();

        // Retrieve the preferences
        final retrievedPreferences = await configManager
            .retrieveUserPreferences();

        // Verify all preferences are persisted correctly
        bool allPreferencesPersisted = true;
        for (final entry in preferences.entries) {
          if (retrievedPreferences[entry.key] != entry.value) {
            allPreferencesPersisted = false;
            break;
          }
        }

        return allPreferencesPersisted;
      },
      iterations: 20,
    );

    PropertyTest.forAll<BackupConfig>(
      description:
          'Property 12b: Strategy changes should update lastConfigUpdate timestamp',
      generator: _generateRandomBackupConfig,
      property: (config) async {
        // Get initial preferences
        final initialPreferences = await configManager
            .retrieveUserPreferences();
        final initialTimestamp = initialPreferences['lastConfigUpdate'];

        // Wait a small amount to ensure timestamp difference
        await Future.delayed(const Duration(milliseconds: 10));

        // Store new configuration (simulating strategy change)
        await configManager.storeConfiguration(config);

        // Update preference to simulate strategy change
        await configManager.updatePreference(
          'preferredBackupType',
          config.type.name,
        );

        // Get updated preferences
        final updatedPreferences = await configManager
            .retrieveUserPreferences();
        final updatedTimestamp = updatedPreferences['lastConfigUpdate'];

        // Verify timestamp was updated
        return updatedTimestamp != initialTimestamp;
      },
      iterations: 20,
    );
  });
}

/// Generate a random backup configuration for testing
BackupConfig _generateRandomBackupConfig() {
  final backupTypes = BackupType.values;
  final compressionLevels = CompressionLevel.values;
  final allCategories = DataCategory.values;

  // Generate random subset of categories (at least 1)
  final categoryCount =
      1 + PropertyTest.randomInt(max: allCategories.length - 1);
  final shuffledCategories = List<DataCategory>.from(allCategories)..shuffle();
  final selectedCategories = shuffledCategories.take(categoryCount).toList();

  // Generate random retention policy
  final retentionPolicy = RetentionPolicy(
    maxBackupCount: PropertyTest.randomInt(min: 1, max: 50),
    maxAge: Duration(days: PropertyTest.randomInt(min: 1, max: 365)),
    keepMonthlyBackups: PropertyTest.randomBool(),
    keepYearlyBackups: PropertyTest.randomBool(),
  );

  // Randomly include schedule config
  ScheduleConfig? scheduleConfig;
  if (PropertyTest.randomBool()) {
    scheduleConfig = ScheduleConfig(
      enabled: PropertyTest.randomBool(),
      interval: Duration(
        hours: PropertyTest.randomInt(min: 1, max: 168),
      ), // 1 hour to 1 week
      smartScheduling: PropertyTest.randomBool(),
      wifiOnly: PropertyTest.randomBool(),
      minimumBatteryLevel: PropertyTest.randomInt(min: 0, max: 100),
    );
  }

  return BackupConfig(
    type: backupTypes[PropertyTest.randomInt(max: backupTypes.length - 1)],
    includedCategories: selectedCategories,
    compressionLevel:
        compressionLevels[PropertyTest.randomInt(
          max: compressionLevels.length - 1,
        )],
    enableValidation: PropertyTest.randomBool(),
    retentionPolicy: retentionPolicy,
    scheduleConfig: scheduleConfig,
  );
}

/// Generate random user preferences for testing
Map<String, dynamic> _generateRandomUserPreferences() {
  final backupTypes = BackupType.values;
  final compressionLevels = CompressionLevel.values;

  return {
    'preferredBackupType':
        backupTypes[PropertyTest.randomInt(max: backupTypes.length - 1)].name,
    'autoBackupEnabled': PropertyTest.randomBool(),
    'notificationsEnabled': PropertyTest.randomBool(),
    'compressionPreference':
        compressionLevels[PropertyTest.randomInt(
              max: compressionLevels.length - 1,
            )]
            .name,
    'wifiOnlyPreference': PropertyTest.randomBool(),
    'batteryThreshold': PropertyTest.randomInt(min: 0, max: 100),
    'storageWarningThreshold': PropertyTest.randomInt(min: 50, max: 100),
    'lastConfigUpdate': DateTime.now().toIso8601String(),
  };
}

/// Helper function to compare two lists for equality
bool _listsEqual<T>(List<T> list1, List<T> list2) {
  if (list1.length != list2.length) return false;

  for (int i = 0; i < list1.length; i++) {
    if (list1[i] != list2[i]) return false;
  }

  return true;
}

/// Helper function to compare two retention policies for equality
bool _retentionPolicyEqual(RetentionPolicy policy1, RetentionPolicy policy2) {
  return policy1.maxBackupCount == policy2.maxBackupCount &&
      policy1.maxAge == policy2.maxAge &&
      policy1.keepMonthlyBackups == policy2.keepMonthlyBackups &&
      policy1.keepYearlyBackups == policy2.keepYearlyBackups;
}

/// Helper function to compare two schedule configs for equality
bool _scheduleConfigEqual(ScheduleConfig config1, ScheduleConfig config2) {
  return config1.enabled == config2.enabled &&
      config1.interval == config2.interval &&
      config1.smartScheduling == config2.smartScheduling &&
      config1.wifiOnly == config2.wifiOnly &&
      config1.minimumBatteryLevel == config2.minimumBatteryLevel;
}
