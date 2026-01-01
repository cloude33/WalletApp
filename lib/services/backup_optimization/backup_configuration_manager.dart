import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/backup_optimization/backup_config.dart';
import '../../models/backup_optimization/backup_enums.dart';

/// Manages backup configuration storage, retrieval, and validation
class BackupConfigurationManager {
  static final BackupConfigurationManager _instance =
      BackupConfigurationManager._internal();
  factory BackupConfigurationManager() => _instance;
  BackupConfigurationManager._internal();

  // Storage keys
  static const String _configKey = 'backup_configuration';
  static const String _userPreferencesKey = 'backup_user_preferences';
  static const String _defaultSettingsKey = 'backup_default_settings';
  static const String _configVersionKey = 'backup_config_version';

  // Current configuration version for migration purposes
  static const int _currentConfigVersion = 1;

  BackupConfig? _cachedConfig;
  Map<String, dynamic>? _cachedPreferences;

  /// Initialize the configuration manager
  Future<void> initialize() async {
    await _loadConfiguration();
    await _loadUserPreferences();
    await _migrateConfigurationIfNeeded();
  }

  /// Store backup configuration
  Future<void> storeConfiguration(BackupConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = jsonEncode(config.toJson());

      await prefs.setString(_configKey, configJson);
      await prefs.setInt(_configVersionKey, _currentConfigVersion);

      _cachedConfig = config;

      debugPrint('✅ Backup configuration stored successfully');
    } catch (e) {
      debugPrint('❌ Error storing backup configuration: $e');
      rethrow;
    }
  }

  /// Retrieve backup configuration
  Future<BackupConfig> retrieveConfiguration() async {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);

      if (configJson != null) {
        final configMap = jsonDecode(configJson) as Map<String, dynamic>;
        _cachedConfig = BackupConfig.fromJson(configMap);
        return _cachedConfig!;
      } else {
        // Return default configuration if none exists
        final defaultConfig = getDefaultConfiguration();
        await storeConfiguration(defaultConfig);
        return defaultConfig;
      }
    } catch (e) {
      debugPrint('❌ Error retrieving backup configuration: $e');
      // Return default configuration on error
      return getDefaultConfiguration();
    }
  }

  /// Store user preferences
  Future<void> storeUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = jsonEncode(preferences);

      await prefs.setString(_userPreferencesKey, preferencesJson);
      _cachedPreferences = Map<String, dynamic>.from(preferences);

      debugPrint('✅ User preferences stored successfully');
    } catch (e) {
      debugPrint('❌ Error storing user preferences: $e');
      rethrow;
    }
  }

  /// Retrieve user preferences
  Future<Map<String, dynamic>> retrieveUserPreferences() async {
    if (_cachedPreferences != null) {
      return Map<String, dynamic>.from(_cachedPreferences!);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString(_userPreferencesKey);

      if (preferencesJson != null) {
        _cachedPreferences = Map<String, dynamic>.from(
          jsonDecode(preferencesJson) as Map<String, dynamic>,
        );
        return Map<String, dynamic>.from(_cachedPreferences!);
      } else {
        // Return default preferences if none exist
        final defaultPreferences = getDefaultUserPreferences();
        await storeUserPreferences(defaultPreferences);
        return defaultPreferences;
      }
    } catch (e) {
      debugPrint('❌ Error retrieving user preferences: $e');
      return getDefaultUserPreferences();
    }
  }

  /// Validate backup configuration
  ValidationResult validateConfiguration(BackupConfig config) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate backup type
    if (!BackupType.values.contains(config.type)) {
      errors.add('Invalid backup type: ${config.type}');
    }

    // Validate included categories
    if (config.includedCategories.isEmpty) {
      errors.add('At least one data category must be included');
    }

    for (final category in config.includedCategories) {
      if (!DataCategory.values.contains(category)) {
        errors.add('Invalid data category: $category');
      }
    }

    // Validate compression level
    if (!CompressionLevel.values.contains(config.compressionLevel)) {
      errors.add('Invalid compression level: ${config.compressionLevel}');
    }

    // Validate retention policy
    final retentionValidation = _validateRetentionPolicy(
      config.retentionPolicy,
    );
    errors.addAll(retentionValidation.errors);
    warnings.addAll(retentionValidation.warnings);

    // Validate schedule config if present
    if (config.scheduleConfig != null) {
      final scheduleValidation = _validateScheduleConfig(
        config.scheduleConfig!,
      );
      errors.addAll(scheduleValidation.errors);
      warnings.addAll(scheduleValidation.warnings);
    }

    // Performance warnings
    if (config.type == BackupType.incremental &&
        config.compressionLevel == CompressionLevel.maximum) {
      warnings.add(
        'Maximum compression with incremental backup may impact performance',
      );
    }

    if (config.includedCategories.length == DataCategory.values.length &&
        config.compressionLevel == CompressionLevel.fast) {
      warnings.add(
        'Fast compression with all categories may result in larger backup sizes',
      );
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate retention policy
  ValidationResult _validateRetentionPolicy(RetentionPolicy policy) {
    final errors = <String>[];
    final warnings = <String>[];

    if (policy.maxBackupCount <= 0) {
      errors.add('Maximum backup count must be greater than 0');
    }

    if (policy.maxAge.inDays <= 0) {
      errors.add('Maximum age must be greater than 0 days');
    }

    // Warnings for potentially problematic settings
    if (policy.maxBackupCount > 50) {
      warnings.add(
        'Large number of backups (${policy.maxBackupCount}) may consume significant storage',
      );
    }

    if (policy.maxAge.inDays > 365) {
      warnings.add(
        'Long retention period (${policy.maxAge.inDays} days) may consume significant storage',
      );
    }

    if (policy.maxBackupCount < 3) {
      warnings.add(
        'Very few backups (${policy.maxBackupCount}) may not provide adequate recovery options',
      );
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate schedule configuration
  ValidationResult _validateScheduleConfig(ScheduleConfig config) {
    final errors = <String>[];
    final warnings = <String>[];

    if (config.interval.inHours <= 0) {
      errors.add('Schedule interval must be greater than 0 hours');
    }

    if (config.minimumBatteryLevel < 0 || config.minimumBatteryLevel > 100) {
      errors.add('Minimum battery level must be between 0 and 100');
    }

    // Warnings for potentially problematic settings
    if (config.interval.inHours < 1) {
      warnings.add(
        'Very frequent backups (< 1 hour) may impact device performance',
      );
    }

    if (config.minimumBatteryLevel > 80) {
      warnings.add(
        'High minimum battery level (${config.minimumBatteryLevel}%) may prevent backups',
      );
    }

    if (!config.wifiOnly) {
      warnings.add('Allowing cellular backups may consume mobile data');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Get default backup configuration
  BackupConfig getDefaultConfiguration() {
    return BackupConfig(
      type: BackupType.full,
      includedCategories: [
        DataCategory.transactions,
        DataCategory.wallets,
        DataCategory.creditCards,
        DataCategory.goals,
        DataCategory.settings,
      ],
      compressionLevel: CompressionLevel.balanced,
      enableValidation: true,
      retentionPolicy: RetentionPolicy.standard(),
      scheduleConfig: ScheduleConfig(
        enabled: false,
        interval: const Duration(hours: 24),
        smartScheduling: true,
        wifiOnly: true,
        minimumBatteryLevel: 20,
      ),
    );
  }

  /// Get default user preferences
  Map<String, dynamic> getDefaultUserPreferences() {
    return {
      'preferredBackupType': BackupType.full.name,
      'autoBackupEnabled': false,
      'notificationsEnabled': true,
      'compressionPreference': CompressionLevel.balanced.name,
      'wifiOnlyPreference': true,
      'batteryThreshold': 20,
      'storageWarningThreshold': 90,
      'lastConfigUpdate': DateTime.now().toIso8601String(),
    };
  }

  /// Update specific preference
  Future<void> updatePreference(String key, dynamic value) async {
    final preferences = await retrieveUserPreferences();
    preferences[key] = value;
    preferences['lastConfigUpdate'] = DateTime.now().toIso8601String();
    await storeUserPreferences(preferences);
  }

  /// Get specific preference with default fallback
  Future<T> getPreference<T>(String key, T defaultValue) async {
    final preferences = await retrieveUserPreferences();
    return preferences[key] as T? ?? defaultValue;
  }

  /// Reset configuration to defaults
  Future<void> resetToDefaults() async {
    final defaultConfig = getDefaultConfiguration();
    final defaultPreferences = getDefaultUserPreferences();

    await storeConfiguration(defaultConfig);
    await storeUserPreferences(defaultPreferences);

    debugPrint('✅ Configuration reset to defaults');
  }

  /// Export configuration as JSON string
  Future<String> exportConfiguration() async {
    final config = await retrieveConfiguration();
    final preferences = await retrieveUserPreferences();

    final exportData = {
      'configuration': config.toJson(),
      'preferences': preferences,
      'version': _currentConfigVersion,
      'exportedAt': DateTime.now().toIso8601String(),
    };

    return jsonEncode(exportData);
  }

  /// Import configuration from JSON string
  Future<bool> importConfiguration(String jsonString) async {
    try {
      final importData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate import data structure
      if (!importData.containsKey('configuration') ||
          !importData.containsKey('preferences')) {
        throw Exception('Invalid configuration format');
      }

      // Import configuration
      final configData = importData['configuration'] as Map<String, dynamic>;
      final config = BackupConfig.fromJson(configData);

      // Validate imported configuration
      final validation = validateConfiguration(config);
      if (!validation.isValid) {
        throw Exception(
          'Invalid configuration: ${validation.errors.join(', ')}',
        );
      }

      // Import preferences
      final preferences = Map<String, dynamic>.from(
        importData['preferences'] as Map<String, dynamic>,
      );

      // Store imported data
      await storeConfiguration(config);
      await storeUserPreferences(preferences);

      debugPrint('✅ Configuration imported successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error importing configuration: $e');
      return false;
    }
  }

  /// Load configuration from storage
  Future<void> _loadConfiguration() async {
    try {
      _cachedConfig = await retrieveConfiguration();
    } catch (e) {
      debugPrint('❌ Error loading configuration: $e');
      _cachedConfig = getDefaultConfiguration();
    }
  }

  /// Load user preferences from storage
  Future<void> _loadUserPreferences() async {
    try {
      _cachedPreferences = await retrieveUserPreferences();
    } catch (e) {
      debugPrint('❌ Error loading user preferences: $e');
      _cachedPreferences = getDefaultUserPreferences();
    }
  }

  /// Migrate configuration if version has changed
  Future<void> _migrateConfigurationIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedVersion = prefs.getInt(_configVersionKey) ?? 0;

      if (storedVersion < _currentConfigVersion) {
        debugPrint(
          '🔄 Migrating configuration from version $storedVersion to $_currentConfigVersion',
        );

        // Perform migration based on version differences
        await _performConfigurationMigration(
          storedVersion,
          _currentConfigVersion,
        );

        // Update version
        await prefs.setInt(_configVersionKey, _currentConfigVersion);

        debugPrint('✅ Configuration migration completed');
      }
    } catch (e) {
      debugPrint('❌ Error during configuration migration: $e');
    }
  }

  /// Perform configuration migration
  Future<void> _performConfigurationMigration(
    int fromVersion,
    int toVersion,
  ) async {
    // Future migration logic would go here
    // For now, we'll just ensure we have valid defaults

    if (fromVersion == 0) {
      // First time setup - ensure defaults are set
      final config = await retrieveConfiguration();
      await retrieveUserPreferences();

      // Validate and fix any issues
      final validation = validateConfiguration(config);
      if (!validation.isValid) {
        await storeConfiguration(getDefaultConfiguration());
      }
    }
  }

  /// Clear all cached data
  void clearCache() {
    _cachedConfig = null;
    _cachedPreferences = null;
  }

  /// Get configuration summary for display
  Future<Map<String, dynamic>> getConfigurationSummary() async {
    final config = await retrieveConfiguration();
    final preferences = await retrieveUserPreferences();

    return {
      'backupType': config.type.name,
      'includedCategories': config.includedCategories.length,
      'compressionLevel': config.compressionLevel.name,
      'validationEnabled': config.enableValidation,
      'scheduleEnabled': config.scheduleConfig?.enabled ?? false,
      'autoBackupEnabled': preferences['autoBackupEnabled'] ?? false,
      'retentionDays': config.retentionPolicy.maxAge.inDays,
      'maxBackups': config.retentionPolicy.maxBackupCount,
    };
  }
}

/// Result of configuration validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  /// Check if there are any warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Get all issues (errors + warnings)
  List<String> get allIssues => [...errors, ...warnings];

  /// Get formatted error message
  String get errorMessage => errors.join('; ');

  /// Get formatted warning message
  String get warningMessage => warnings.join('; ');
}
