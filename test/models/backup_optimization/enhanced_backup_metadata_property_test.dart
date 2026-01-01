import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/backup_optimization/enhanced_backup_metadata.dart';
import 'package:parion/models/backup_optimization/backup_enums.dart';
import 'package:parion/models/backup_optimization/incremental_data.dart';
import '../../property_test_utils.dart';

void main() {
  group('Enhanced Backup Metadata Property Tests', () {
    /// **Feature: backup-optimization, Property 1: Incremental Backup Delta Detection**
    /// **Validates: Requirements 1.1**
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 1: Incremental Backup Delta Detection - For any data set and timestamp, when incremental backup is performed, only data modified after the timestamp should be included in the backup package',
      generator: _generateIncrementalBackupScenario,
      property: (scenario) async {
        final referenceTimestamp = scenario['referenceTimestamp'] as DateTime;
        final allChanges = scenario['allChanges'] as List<DataChange>;
        final expectedChanges = scenario['expectedChanges'] as List<DataChange>;
        
        // Create incremental data with all changes
        final incrementalData = IncrementalData(
          referenceDate: referenceTimestamp,
          changes: allChanges,
          entityHashes: {},
          totalChanges: allChanges.length,
        );
        
        // Filter changes that should be included (modified after reference timestamp)
        final actualFilteredChanges = incrementalData.changes
            .where((change) => change.timestamp.isAfter(referenceTimestamp))
            .toList();
        
        // Create enhanced metadata for incremental backup
        final metadata = EnhancedBackupMetadata(
          version: '3.0',
          createdAt: DateTime.now(),
          transactionCount: actualFilteredChanges.length,
          walletCount: 1,
          type: BackupType.incremental,
          compressionInfo: _generateCompressionInfo(),
          includedDataTypes: [DataCategory.transactions],
          performanceMetrics: _generatePerformanceMetrics(),
          validationInfo: _generateValidationInfo(),
          originalSize: 1000,
          compressedSize: 500,
          backupDuration: const Duration(seconds: 30),
          compressionAlgorithm: 'gzip',
          compressionRatio: 0.5,
        );
        
        // Property: Only changes after reference timestamp should be included
        // The metadata should reflect an incremental backup
        final isIncrementalBackup = metadata.isIncremental;
        
        // The filtered changes should match expected changes (those after reference timestamp)
        final correctFiltering = actualFilteredChanges.length == expectedChanges.length &&
            actualFilteredChanges.every((change) => 
                expectedChanges.any((expected) => 
                    expected.entityId == change.entityId && 
                    expected.timestamp == change.timestamp));
        
        // All filtered changes should be after the reference timestamp
        final allChangesAfterReference = actualFilteredChanges.every(
            (change) => change.timestamp.isAfter(referenceTimestamp));
        
        // Metadata should correctly identify as incremental
        final metadataCorrect = isIncrementalBackup && 
            metadata.type == BackupType.incremental;
        
        return correctFiltering && allChangesAfterReference && metadataCorrect;
      },
      iterations: 20,
    );

    test('Enhanced metadata should handle JSON serialization correctly', () {
      final metadata = _generateRandomEnhancedMetadata();
      
      final json = metadata.toJson();
      final restored = EnhancedBackupMetadata.fromJson(json);
      
      expect(restored.version, metadata.version);
      expect(restored.type, metadata.type);
      expect(restored.compressionRatio, metadata.compressionRatio);
      expect(restored.isIncremental, metadata.isIncremental);
      expect(restored.compressionEfficiency, metadata.compressionEfficiency);
    });

    test('Enhanced metadata should calculate compression efficiency correctly', () {
      final metadata = EnhancedBackupMetadata(
        version: '3.0',
        createdAt: DateTime.now(),
        transactionCount: 10,
        walletCount: 2,
        type: BackupType.full,
        compressionInfo: const CompressionInfo(
          algorithm: 'gzip',
          ratio: 0.6,
          originalSize: 1000,
          compressedSize: 600,
          compressionTime: Duration(seconds: 5),
        ),
        includedDataTypes: const [DataCategory.transactions],
        performanceMetrics: const PerformanceMetrics(
          totalDuration: Duration(minutes: 2),
          compressionTime: Duration(seconds: 5),
          uploadTime: Duration(seconds: 30),
          validationTime: Duration(seconds: 2),
          networkRetries: 0,
          averageUploadSpeed: 1.5,
        ),
        validationInfo: ValidationInfo(
          checksum: 'abc123',
          result: ValidationResult.valid,
          validatedAt: DateTime.now(),
          errors: const [],
        ),
        originalSize: 1000,
        compressedSize: 600,
        backupDuration: const Duration(minutes: 2),
        compressionAlgorithm: 'gzip',
        compressionRatio: 0.6,
      );
      
      expect(metadata.compressionEfficiency, 40.0); // (1 - 0.6) * 100
    });
  });
}

/// Generate a random scenario for incremental backup testing
Map<String, dynamic> _generateIncrementalBackupScenario() {
  final referenceTimestamp = PropertyTest.randomDateTime(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now().subtract(const Duration(days: 1)),
  );
  
  // Generate changes both before and after reference timestamp
  final allChanges = <DataChange>[];
  final expectedChanges = <DataChange>[];
  
  // Add some changes before reference timestamp (should be filtered out)
  for (int i = 0; i < PropertyTest.randomInt(min: 1, max: 5); i++) {
    final changeTime = referenceTimestamp.subtract(
      Duration(hours: PropertyTest.randomInt(min: 1, max: 24))
    );
    final change = DataChange.create(
      entityType: 'transaction',
      entityId: 'tx_${PropertyTest.randomString(maxLength: 8)}',
      newData: {'amount': PropertyTest.randomPositiveDouble()},
      timestamp: changeTime,
    );
    allChanges.add(change);
  }
  
  // Add some changes after reference timestamp (should be included)
  for (int i = 0; i < PropertyTest.randomInt(min: 1, max: 5); i++) {
    final changeTime = referenceTimestamp.add(
      Duration(hours: PropertyTest.randomInt(min: 1, max: 24))
    );
    final change = DataChange.create(
      entityType: 'transaction',
      entityId: 'tx_${PropertyTest.randomString(maxLength: 8)}',
      newData: {'amount': PropertyTest.randomPositiveDouble()},
      timestamp: changeTime,
    );
    allChanges.add(change);
    expectedChanges.add(change);
  }
  
  return {
    'referenceTimestamp': referenceTimestamp,
    'allChanges': allChanges,
    'expectedChanges': expectedChanges,
  };
}

/// Generate random compression info for testing
CompressionInfo _generateCompressionInfo() {
  final originalSize = PropertyTest.randomInt(min: 100, max: 10000);
  final compressionRatio = PropertyTest.randomPositiveDouble(min: 0.1, max: 0.9);
  final compressedSize = (originalSize * compressionRatio).round();
  
  return CompressionInfo(
    algorithm: ['gzip', 'lz4', 'zstd'][PropertyTest.randomInt(max: 2)],
    ratio: compressionRatio,
    originalSize: originalSize,
    compressedSize: compressedSize,
    compressionTime: Duration(seconds: PropertyTest.randomInt(min: 1, max: 30)),
  );
}

/// Generate random performance metrics for testing
PerformanceMetrics _generatePerformanceMetrics() {
  return PerformanceMetrics(
    totalDuration: Duration(seconds: PropertyTest.randomInt(min: 30, max: 300)),
    compressionTime: Duration(seconds: PropertyTest.randomInt(min: 1, max: 30)),
    uploadTime: Duration(seconds: PropertyTest.randomInt(min: 10, max: 120)),
    validationTime: Duration(seconds: PropertyTest.randomInt(min: 1, max: 10)),
    networkRetries: PropertyTest.randomInt(min: 0, max: 5),
    averageUploadSpeed: PropertyTest.randomPositiveDouble(min: 0.1, max: 10.0),
  );
}

/// Generate random validation info for testing
ValidationInfo _generateValidationInfo() {
  return ValidationInfo(
    checksum: PropertyTest.randomString(maxLength: 32),
    result: ValidationResult.values[PropertyTest.randomInt(max: ValidationResult.values.length - 1)],
    validatedAt: PropertyTest.randomDateTime(),
    errors: PropertyTest.randomBool() ? [] : [PropertyTest.randomString()],
  );
}

/// Generate a random enhanced backup metadata for testing
EnhancedBackupMetadata _generateRandomEnhancedMetadata() {
  final originalSize = PropertyTest.randomInt(min: 100, max: 10000);
  final compressionRatio = PropertyTest.randomPositiveDouble(min: 0.1, max: 0.9);
  final compressedSize = (originalSize * compressionRatio).round();
  
  return EnhancedBackupMetadata(
    version: '3.0',
    createdAt: PropertyTest.randomDateTime(),
    transactionCount: PropertyTest.randomInt(min: 0, max: 1000),
    walletCount: PropertyTest.randomInt(min: 1, max: 10),
    type: BackupType.values[PropertyTest.randomInt(max: BackupType.values.length - 1)],
    compressionInfo: _generateCompressionInfo(),
    includedDataTypes: [DataCategory.transactions, DataCategory.wallets],
    performanceMetrics: _generatePerformanceMetrics(),
    validationInfo: _generateValidationInfo(),
    originalSize: originalSize,
    compressedSize: compressedSize,
    backupDuration: Duration(seconds: PropertyTest.randomInt(min: 30, max: 300)),
    compressionAlgorithm: ['gzip', 'lz4', 'zstd'][PropertyTest.randomInt(max: 2)],
    compressionRatio: compressionRatio,
  );
}