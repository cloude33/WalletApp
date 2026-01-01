import 'backup_enums.dart';

/// Configuration for backup operations
class BackupConfig {
  final BackupType type;
  final List<DataCategory> includedCategories;
  final CompressionLevel compressionLevel;
  final bool enableValidation;
  final RetentionPolicy retentionPolicy;
  final ScheduleConfig? scheduleConfig;

  const BackupConfig({
    required this.type,
    required this.includedCategories,
    this.compressionLevel = CompressionLevel.balanced,
    this.enableValidation = true,
    required this.retentionPolicy,
    this.scheduleConfig,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'includedCategories': includedCategories.map((e) => e.name).toList(),
    'compressionLevel': compressionLevel.name,
    'enableValidation': enableValidation,
    'retentionPolicy': retentionPolicy.toJson(),
    'scheduleConfig': scheduleConfig?.toJson(),
  };

  factory BackupConfig.fromJson(Map<String, dynamic> json) {
    return BackupConfig(
      type: BackupType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BackupType.full,
      ),
      includedCategories: (json['includedCategories'] as List<dynamic>?)
          ?.map((e) => DataCategory.values.firstWhere(
                (category) => category.name == e,
                orElse: () => DataCategory.transactions,
              ))
          .toList() ?? DataCategory.values,
      compressionLevel: CompressionLevel.values.firstWhere(
        (e) => e.name == json['compressionLevel'],
        orElse: () => CompressionLevel.balanced,
      ),
      enableValidation: json['enableValidation'] ?? true,
      retentionPolicy: RetentionPolicy.fromJson(json['retentionPolicy'] ?? {}),
      scheduleConfig: json['scheduleConfig'] != null 
          ? ScheduleConfig.fromJson(json['scheduleConfig'])
          : null,
    );
  }

  /// Create a quick backup configuration (critical data only)
  factory BackupConfig.quick() {
    return BackupConfig(
      type: BackupType.custom,
      includedCategories: [
        DataCategory.transactions,
        DataCategory.wallets,
        DataCategory.creditCards,
      ],
      compressionLevel: CompressionLevel.fast,
      enableValidation: true,
      retentionPolicy: RetentionPolicy.standard(),
    );
  }

  /// Create a full backup configuration (all data and settings)
  factory BackupConfig.full() {
    return BackupConfig(
      type: BackupType.full,
      includedCategories: DataCategory.values,
      compressionLevel: CompressionLevel.maximum,
      enableValidation: true,
      retentionPolicy: RetentionPolicy.extended(),
    );
  }

  /// Create an incremental backup configuration
  factory BackupConfig.incremental() {
    return BackupConfig(
      type: BackupType.incremental,
      includedCategories: DataCategory.values,
      compressionLevel: CompressionLevel.balanced,
      enableValidation: true,
      retentionPolicy: RetentionPolicy.standard(),
    );
  }

  /// Copy configuration with modifications
  BackupConfig copyWith({
    BackupType? type,
    List<DataCategory>? includedCategories,
    CompressionLevel? compressionLevel,
    bool? enableValidation,
    RetentionPolicy? retentionPolicy,
    ScheduleConfig? scheduleConfig,
  }) {
    return BackupConfig(
      type: type ?? this.type,
      includedCategories: includedCategories ?? this.includedCategories,
      compressionLevel: compressionLevel ?? this.compressionLevel,
      enableValidation: enableValidation ?? this.enableValidation,
      retentionPolicy: retentionPolicy ?? this.retentionPolicy,
      scheduleConfig: scheduleConfig ?? this.scheduleConfig,
    );
  }
}

/// Policy for retaining backup files
class RetentionPolicy {
  final int maxBackupCount;
  final Duration maxAge;
  final bool keepMonthlyBackups;
  final bool keepYearlyBackups;

  const RetentionPolicy({
    required this.maxBackupCount,
    required this.maxAge,
    this.keepMonthlyBackups = false,
    this.keepYearlyBackups = false,
  });

  Map<String, dynamic> toJson() => {
    'maxBackupCount': maxBackupCount,
    'maxAge': maxAge.inDays,
    'keepMonthlyBackups': keepMonthlyBackups,
    'keepYearlyBackups': keepYearlyBackups,
  };

  factory RetentionPolicy.fromJson(Map<String, dynamic> json) {
    return RetentionPolicy(
      maxBackupCount: json['maxBackupCount'] ?? 10,
      maxAge: Duration(days: json['maxAge'] ?? 30),
      keepMonthlyBackups: json['keepMonthlyBackups'] ?? false,
      keepYearlyBackups: json['keepYearlyBackups'] ?? false,
    );
  }

  /// Standard retention policy (10 backups, 30 days)
  factory RetentionPolicy.standard() {
    return const RetentionPolicy(
      maxBackupCount: 10,
      maxAge: Duration(days: 30),
      keepMonthlyBackups: false,
      keepYearlyBackups: false,
    );
  }

  /// Extended retention policy (20 backups, 90 days, with monthly/yearly)
  factory RetentionPolicy.extended() {
    return const RetentionPolicy(
      maxBackupCount: 20,
      maxAge: Duration(days: 90),
      keepMonthlyBackups: true,
      keepYearlyBackups: true,
    );
  }

  /// Minimal retention policy (5 backups, 7 days)
  factory RetentionPolicy.minimal() {
    return const RetentionPolicy(
      maxBackupCount: 5,
      maxAge: Duration(days: 7),
      keepMonthlyBackups: false,
      keepYearlyBackups: false,
    );
  }
}

/// Configuration for scheduled backups
class ScheduleConfig {
  final bool enabled;
  final Duration interval;
  final bool smartScheduling;
  final bool wifiOnly;
  final int minimumBatteryLevel;

  const ScheduleConfig({
    required this.enabled,
    required this.interval,
    this.smartScheduling = true,
    this.wifiOnly = true,
    this.minimumBatteryLevel = 20,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'interval': interval.inHours,
    'smartScheduling': smartScheduling,
    'wifiOnly': wifiOnly,
    'minimumBatteryLevel': minimumBatteryLevel,
  };

  factory ScheduleConfig.fromJson(Map<String, dynamic> json) {
    return ScheduleConfig(
      enabled: json['enabled'] ?? false,
      interval: Duration(hours: json['interval'] ?? 24),
      smartScheduling: json['smartScheduling'] ?? true,
      wifiOnly: json['wifiOnly'] ?? true,
      minimumBatteryLevel: json['minimumBatteryLevel'] ?? 20,
    );
  }

  /// Daily backup schedule
  factory ScheduleConfig.daily() {
    return const ScheduleConfig(
      enabled: true,
      interval: Duration(hours: 24),
      smartScheduling: true,
      wifiOnly: true,
      minimumBatteryLevel: 20,
    );
  }

  /// Weekly backup schedule
  factory ScheduleConfig.weekly() {
    return const ScheduleConfig(
      enabled: true,
      interval: Duration(days: 7),
      smartScheduling: true,
      wifiOnly: true,
      minimumBatteryLevel: 30,
    );
  }

  /// Copy configuration with modifications
  ScheduleConfig copyWith({
    bool? enabled,
    Duration? interval,
    bool? smartScheduling,
    bool? wifiOnly,
    int? minimumBatteryLevel,
  }) {
    return ScheduleConfig(
      enabled: enabled ?? this.enabled,
      interval: interval ?? this.interval,
      smartScheduling: smartScheduling ?? this.smartScheduling,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      minimumBatteryLevel: minimumBatteryLevel ?? this.minimumBatteryLevel,
    );
  }
}

/// Smart scheduling configuration
class SmartScheduleConfig {
  final bool enableDeviceIdleDetection;
  final bool enableNetworkQualityCheck;
  final bool enableBatteryLevelCheck;
  final bool enableStorageSpaceCheck;
  final NetworkQuality minimumNetworkQuality;
  final int minimumBatteryPercentage;
  final int minimumStorageSpaceMB;

  const SmartScheduleConfig({
    this.enableDeviceIdleDetection = true,
    this.enableNetworkQualityCheck = true,
    this.enableBatteryLevelCheck = true,
    this.enableStorageSpaceCheck = true,
    this.minimumNetworkQuality = NetworkQuality.fair,
    this.minimumBatteryPercentage = 20,
    this.minimumStorageSpaceMB = 100,
  });

  Map<String, dynamic> toJson() => {
    'enableDeviceIdleDetection': enableDeviceIdleDetection,
    'enableNetworkQualityCheck': enableNetworkQualityCheck,
    'enableBatteryLevelCheck': enableBatteryLevelCheck,
    'enableStorageSpaceCheck': enableStorageSpaceCheck,
    'minimumNetworkQuality': minimumNetworkQuality.name,
    'minimumBatteryPercentage': minimumBatteryPercentage,
    'minimumStorageSpaceMB': minimumStorageSpaceMB,
  };

  factory SmartScheduleConfig.fromJson(Map<String, dynamic> json) {
    return SmartScheduleConfig(
      enableDeviceIdleDetection: json['enableDeviceIdleDetection'] ?? true,
      enableNetworkQualityCheck: json['enableNetworkQualityCheck'] ?? true,
      enableBatteryLevelCheck: json['enableBatteryLevelCheck'] ?? true,
      enableStorageSpaceCheck: json['enableStorageSpaceCheck'] ?? true,
      minimumNetworkQuality: NetworkQuality.values.firstWhere(
        (e) => e.name == json['minimumNetworkQuality'],
        orElse: () => NetworkQuality.fair,
      ),
      minimumBatteryPercentage: json['minimumBatteryPercentage'] ?? 20,
      minimumStorageSpaceMB: json['minimumStorageSpaceMB'] ?? 100,
    );
  }
}