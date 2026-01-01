import 'backup_optimization_models.dart';

/// Abstract base class for backup strategies
abstract class BackupStrategy {
  /// The type of backup this strategy handles
  BackupType get type;

  /// Create a backup using this strategy
  Future<BackupPackage> createBackup(
    Map<String, dynamic> data,
    BackupConfig config,
  );

  /// Restore data from a backup package
  Future<Map<String, dynamic>> restoreBackup(
    BackupPackage package,
    {List<BackupPackage>? additionalPackages}
  );

  /// Validate that this strategy can handle the given backup type
  bool canHandle(BackupType backupType) => backupType == type;

  /// Get the estimated size of a backup for the given data
  Future<int> estimateBackupSize(
    Map<String, dynamic> data,
    BackupConfig config,
  );

  /// Check if the strategy requires additional packages for restoration
  bool get requiresAdditionalPackages => false;
}

/// Strategy for full backups
class FullBackupStrategy extends BackupStrategy {
  @override
  BackupType get type => BackupType.full;

  @override
  Future<BackupPackage> createBackup(
    Map<String, dynamic> data,
    BackupConfig config,
  ) async {
    // Filter data based on included categories
    final filteredData = _filterDataByCategories(data, config.includedCategories);
    
    // Generate unique ID for this backup
    final backupId = _generateBackupId();
    
    // Calculate original size
    final originalSize = _calculateDataSize(filteredData);
    
    // For now, simulate compression (will be implemented in compression service)
    final compressedSize = (originalSize * 0.7).round(); // Simulate 30% compression
    
    // Generate checksum (will be implemented in validation service)
    final checksum = _generateChecksum(filteredData);
    
    return BackupPackage(
      id: backupId,
      type: BackupType.full,
      createdAt: DateTime.now(),
      data: filteredData,
      checksum: checksum,
      originalSize: originalSize,
      compressedSize: compressedSize,
    );
  }

  @override
  Future<Map<String, dynamic>> restoreBackup(
    BackupPackage package,
    {List<BackupPackage>? additionalPackages}
  ) async {
    if (package.type != BackupType.full) {
      throw ArgumentError('FullBackupStrategy can only restore full backups');
    }
    
    // For full backups, simply return the data
    return Map<String, dynamic>.from(package.data);
  }

  @override
  Future<int> estimateBackupSize(
    Map<String, dynamic> data,
    BackupConfig config,
  ) async {
    final filteredData = _filterDataByCategories(data, config.includedCategories);
    final originalSize = _calculateDataSize(filteredData);
    
    // Estimate compression based on compression level
    double compressionRatio;
    switch (config.compressionLevel) {
      case CompressionLevel.fast:
        compressionRatio = 0.8; // 20% compression
        break;
      case CompressionLevel.balanced:
        compressionRatio = 0.7; // 30% compression
        break;
      case CompressionLevel.maximum:
        compressionRatio = 0.5; // 50% compression
        break;
    }
    
    return (originalSize * compressionRatio).round();
  }

  Map<String, dynamic> _filterDataByCategories(
    Map<String, dynamic> data,
    List<DataCategory> categories,
  ) {
    final filtered = <String, dynamic>{};
    
    for (final category in categories) {
      final key = _getCategoryKey(category);
      if (data.containsKey(key)) {
        filtered[key] = data[key];
      }
    }
    
    // Always include metadata
    if (data.containsKey('metadata')) {
      filtered['metadata'] = data['metadata'];
    }
    
    return filtered;
  }

  String _getCategoryKey(DataCategory category) {
    switch (category) {
      case DataCategory.transactions:
        return 'transactions';
      case DataCategory.wallets:
        return 'wallets';
      case DataCategory.creditCards:
        return 'creditCards';
      case DataCategory.bills:
        return 'billTemplates';
      case DataCategory.goals:
        return 'goals';
      case DataCategory.settings:
        return 'settings';
      case DataCategory.userImages:
        return 'userImages';
      case DataCategory.recurringTransactions:
        return 'recurringTransactions';
    }
  }

  int _calculateDataSize(Map<String, dynamic> data) {
    // Approximate size calculation
    return data.toString().length;
  }

  String _generateBackupId() {
    return 'backup_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateChecksum(Map<String, dynamic> data) {
    // Simple checksum for now (will be replaced with proper implementation)
    return data.toString().hashCode.toString();
  }
}

/// Strategy for incremental backups
class IncrementalBackupStrategy extends BackupStrategy {
  @override
  BackupType get type => BackupType.incremental;

  @override
  bool get requiresAdditionalPackages => true;

  @override
  Future<BackupPackage> createBackup(
    Map<String, dynamic> data,
    BackupConfig config,
  ) async {
    // This will be implemented with delta detection
    // For now, create a placeholder implementation
    
    final backupId = _generateBackupId();
    final originalSize = _calculateDataSize(data);
    final compressedSize = (originalSize * 0.5).round(); // Incremental should be smaller
    final checksum = _generateChecksum(data);
    
    return BackupPackage(
      id: backupId,
      type: BackupType.incremental,
      createdAt: DateTime.now(),
      data: data,
      checksum: checksum,
      originalSize: originalSize,
      compressedSize: compressedSize,
      parentPackageId: null, // Will be set when we have reference backup
    );
  }

  @override
  Future<Map<String, dynamic>> restoreBackup(
    BackupPackage package,
    {List<BackupPackage>? additionalPackages}
  ) async {
    if (package.type != BackupType.incremental) {
      throw ArgumentError('IncrementalBackupStrategy can only restore incremental backups');
    }
    
    if (additionalPackages == null || additionalPackages.isEmpty) {
      throw ArgumentError('Incremental backup restoration requires additional packages');
    }
    
    // This will be implemented with proper delta reconstruction
    // For now, return the package data
    return Map<String, dynamic>.from(package.data);
  }

  @override
  Future<int> estimateBackupSize(
    Map<String, dynamic> data,
    BackupConfig config,
  ) async {
    // Incremental backups are typically much smaller
    final originalSize = _calculateDataSize(data);
    return (originalSize * 0.1).round(); // Estimate 10% of full size
  }

  int _calculateDataSize(Map<String, dynamic> data) {
    return data.toString().length;
  }

  String _generateBackupId() {
    return 'incremental_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateChecksum(Map<String, dynamic> data) {
    return data.toString().hashCode.toString();
  }
}

/// Strategy for custom backups
class CustomBackupStrategy extends BackupStrategy {
  @override
  BackupType get type => BackupType.custom;

  @override
  Future<BackupPackage> createBackup(
    Map<String, dynamic> data,
    BackupConfig config,
  ) async {
    // Similar to full backup but with custom filtering
    final filteredData = _filterDataByCategories(data, config.includedCategories);
    
    final backupId = _generateBackupId();
    final originalSize = _calculateDataSize(filteredData);
    final compressedSize = (originalSize * 0.7).round();
    final checksum = _generateChecksum(filteredData);
    
    return BackupPackage(
      id: backupId,
      type: BackupType.custom,
      createdAt: DateTime.now(),
      data: filteredData,
      checksum: checksum,
      originalSize: originalSize,
      compressedSize: compressedSize,
    );
  }

  @override
  Future<Map<String, dynamic>> restoreBackup(
    BackupPackage package,
    {List<BackupPackage>? additionalPackages}
  ) async {
    if (package.type != BackupType.custom) {
      throw ArgumentError('CustomBackupStrategy can only restore custom backups');
    }
    
    return Map<String, dynamic>.from(package.data);
  }

  @override
  Future<int> estimateBackupSize(
    Map<String, dynamic> data,
    BackupConfig config,
  ) async {
    final filteredData = _filterDataByCategories(data, config.includedCategories);
    final originalSize = _calculateDataSize(filteredData);
    
    // Estimate based on compression level
    double compressionRatio;
    switch (config.compressionLevel) {
      case CompressionLevel.fast:
        compressionRatio = 0.8;
        break;
      case CompressionLevel.balanced:
        compressionRatio = 0.7;
        break;
      case CompressionLevel.maximum:
        compressionRatio = 0.5;
        break;
    }
    
    return (originalSize * compressionRatio).round();
  }

  Map<String, dynamic> _filterDataByCategories(
    Map<String, dynamic> data,
    List<DataCategory> categories,
  ) {
    final filtered = <String, dynamic>{};
    
    for (final category in categories) {
      final key = _getCategoryKey(category);
      if (data.containsKey(key)) {
        filtered[key] = data[key];
      }
    }
    
    // Always include metadata
    if (data.containsKey('metadata')) {
      filtered['metadata'] = data['metadata'];
    }
    
    return filtered;
  }

  String _getCategoryKey(DataCategory category) {
    switch (category) {
      case DataCategory.transactions:
        return 'transactions';
      case DataCategory.wallets:
        return 'wallets';
      case DataCategory.creditCards:
        return 'creditCards';
      case DataCategory.bills:
        return 'billTemplates';
      case DataCategory.goals:
        return 'goals';
      case DataCategory.settings:
        return 'settings';
      case DataCategory.userImages:
        return 'userImages';
      case DataCategory.recurringTransactions:
        return 'recurringTransactions';
    }
  }

  int _calculateDataSize(Map<String, dynamic> data) {
    return data.toString().length;
  }

  String _generateBackupId() {
    return 'custom_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateChecksum(Map<String, dynamic> data) {
    return data.toString().hashCode.toString();
  }
}

/// Factory for creating backup strategies
class BackupStrategyFactory {
  static final Map<BackupType, BackupStrategy> _strategies = {
    BackupType.full: FullBackupStrategy(),
    BackupType.incremental: IncrementalBackupStrategy(),
    BackupType.custom: CustomBackupStrategy(),
  };

  /// Get a strategy for the given backup type
  static BackupStrategy getStrategy(BackupType type) {
    final strategy = _strategies[type];
    if (strategy == null) {
      throw ArgumentError('No strategy found for backup type: $type');
    }
    return strategy;
  }

  /// Get all available strategies
  static Map<BackupType, BackupStrategy> getAllStrategies() {
    return Map.unmodifiable(_strategies);
  }

  /// Check if a strategy exists for the given type
  static bool hasStrategy(BackupType type) {
    return _strategies.containsKey(type);
  }
}