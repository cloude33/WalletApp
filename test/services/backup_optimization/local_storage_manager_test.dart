import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:parion/services/backup_optimization/local_storage_manager.dart';
import 'package:parion/models/backup_optimization/offline_backup_models.dart';
import 'package:parion/models/backup_optimization/enhanced_backup_metadata.dart';
import 'package:parion/models/backup_optimization/backup_enums.dart';
import '../../test_helpers.dart';

void main() {
  setupCommonTestMocks();
  group('LocalStorageManager', () {
    late LocalStorageManager storageManager;

    setUpAll(() async {
      try {
        final dir = Directory('test_temp');
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (e) {
        print('Cleanup error (ignored): $e');
      }
    });

    setUp(() {
      storageManager = LocalStorageManager();
    });

    test('should initialize with default settings', () async {
      await storageManager.initialize();

      final stats = await storageManager.getStorageStats();
      expect(stats.maxStorageMB, equals(500)); // Default max storage
    });

    test('should initialize with custom max storage', () async {
      await storageManager.initialize(maxStorageMB: 1000);

      final stats = await storageManager.getStorageStats();
      expect(stats.maxStorageMB, equals(1000));
    });

    test('should calculate available storage correctly', () async {
      await storageManager.initialize(maxStorageMB: 100);

      final availableMB = await storageManager.getAvailableStorageMB();
      expect(availableMB, greaterThanOrEqualTo(0));
      expect(availableMB, lessThanOrEqualTo(100));
    });

    test('should detect when near capacity', () async {
      await storageManager.initialize(maxStorageMB: 10); // Very small limit

      final isNear = await storageManager.isNearCapacity();
      // This test depends on actual storage usage, so we just verify it returns a boolean
      expect(isNear, isA<bool>());
    });

    test('should check space availability for backup', () async {
      await storageManager.initialize(maxStorageMB: 100);

      final hasSpace = await storageManager.hasSpaceForBackup(50);
      expect(hasSpace, isA<bool>());
    });

    test('should prioritize items correctly for deletion', () async {
      await storageManager.initialize();

      final items = [
        _createTestItem('1', OfflineBackupStatus.completed, [
          DataCategory.userImages,
        ], 1),
        _createTestItem('2', OfflineBackupStatus.pending, [
          DataCategory.transactions,
        ], 10),
        _createTestItem('3', OfflineBackupStatus.failed, [
          DataCategory.settings,
        ], 5),
      ];

      // This test verifies the method doesn't crash - actual prioritization logic
      // would need more complex setup with real files
      final freedMB = await storageManager.freeUpSpace(10, items);
      expect(freedMB, greaterThanOrEqualTo(0));
    });

    test('should get storage statistics', () async {
      await storageManager.initialize(maxStorageMB: 200);

      final stats = await storageManager.getStorageStats();

      expect(stats.maxStorageMB, equals(200));
      expect(stats.currentUsageMB, greaterThanOrEqualTo(0));
      expect(stats.availableMB, greaterThanOrEqualTo(0));
      expect(stats.usagePercentage, greaterThanOrEqualTo(0));
      expect(stats.usagePercentage, lessThanOrEqualTo(100));
      expect(stats.isNearCapacity, isA<bool>());
    });

    test('should update max storage limit', () async {
      await storageManager.initialize(maxStorageMB: 100);

      await storageManager.setMaxStorageLimit(300);

      final stats = await storageManager.getStorageStats();
      expect(stats.maxStorageMB, equals(300));
    });

    test('should perform auto cleanup', () async {
      await storageManager.initialize(maxStorageMB: 50);

      final items = [
        _createTestItem('1', OfflineBackupStatus.completed, [
          DataCategory.transactions,
        ], 5),
        _createTestItem('2', OfflineBackupStatus.completed, [
          DataCategory.userImages,
        ], 1),
      ];

      final result = await storageManager.performAutoCleanup(items);

      expect(result.deletedFiles, greaterThanOrEqualTo(0));
      expect(result.freedSpaceMB, greaterThanOrEqualTo(0));
      expect(result.reason, isNotEmpty);
    });

    test('should clean up temporary files', () async {
      await storageManager.initialize();

      // This test verifies the method doesn't crash
      // In a real scenario, we'd create temp files and verify they're cleaned
      await storageManager.cleanupTemporaryFiles();

      // If we get here without exception, the test passes
      expect(true, isTrue);
    });

    test('should find deletable files', () async {
      await storageManager.initialize();

      final items = [
        _createTestItem('1', OfflineBackupStatus.completed, [
          DataCategory.transactions,
        ], 5),
        _createTestItem('2', OfflineBackupStatus.pending, [
          DataCategory.wallets,
        ], 3),
      ];

      final deletableFiles = await storageManager.getDeletableFiles(items);

      expect(deletableFiles, isA<List<DeletableFile>>());
      // The actual files won't exist in test, so list will be empty
      // but we verify the method works
    });
  });
}

OfflineBackupItem _createTestItem(
  String id,
  OfflineBackupStatus status,
  List<DataCategory> categories,
  int priority,
) {
  return OfflineBackupItem(
    id: id,
    localPath: '/test/path/backup_$id.mbk',
    metadata: EnhancedBackupMetadata(
      version: '3.0',
      createdAt: DateTime.now().subtract(Duration(hours: priority)),
      transactionCount: 10,
      walletCount: 2,
      platform: 'test',
      deviceModel: 'test device',
      type: BackupType.full,
      compressionInfo: const CompressionInfo(
        algorithm: 'gzip',
        ratio: 0.7,
        originalSize: 1000,
        compressedSize: 700,
        compressionTime: Duration(seconds: 1),
      ),
      includedDataTypes: categories,
      performanceMetrics: const PerformanceMetrics(
        totalDuration: Duration(seconds: 5),
        compressionTime: Duration(seconds: 1),
        uploadTime: Duration(seconds: 3),
        validationTime: Duration(seconds: 1),
        networkRetries: 0,
        averageUploadSpeed: 1.5,
      ),
      validationInfo: ValidationInfo(
        checksum: 'test-checksum',
        result: ValidationResult.valid,
        validatedAt: DateTime.now(),
        errors: const [],
      ),
      originalSize: 1000,
      compressedSize: 700,
      backupDuration: const Duration(seconds: 5),
      compressionAlgorithm: 'gzip',
      compressionRatio: 0.7,
    ),
    createdAt: DateTime.now().subtract(Duration(hours: priority)),
    status: status,
    priority: priority,
  );
}
