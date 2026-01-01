import 'package:flutter_test/flutter_test.dart';

import 'package:parion/services/backup_optimization/offline_backup_queue.dart';
import 'package:parion/models/backup_optimization/offline_backup_models.dart';
import 'package:parion/models/backup_optimization/enhanced_backup_metadata.dart';
import 'package:parion/models/backup_optimization/backup_enums.dart';
import '../../test_helpers.dart';

void main() {
  setupCommonTestMocks();
  group('OfflineBackupQueue', () {
    late OfflineBackupQueue queue;

    setUp(() {
      queue = OfflineBackupQueue();
    });

    tearDown(() {
      queue.dispose();
    });

    test('should initialize with empty queue', () async {
      await queue.initialize();

      expect(queue.getQueueItems(), isEmpty);
      expect(queue.getPendingItems(), isEmpty);
    });

    test('should handle configuration updates', () async {
      await queue.initialize();

      const newConfig = OfflineBackupConfig(
        maxQueueSize: 100,
        maxRetryAttempts: 5,
        maxLocalStorageMB: 1000,
      );

      await queue.updateConfig(newConfig);

      expect(queue.config.maxQueueSize, equals(100));
      expect(queue.config.maxRetryAttempts, equals(5));
      expect(queue.config.maxLocalStorageMB, equals(1000));
    });

    test('should get current statistics', () async {
      await queue.initialize();

      final stats = queue.currentStats;

      expect(stats.totalItems, equals(0));
      expect(stats.pendingItems, equals(0));
      expect(stats.completedItems, equals(0));
      expect(stats.failedItems, equals(0));
    });

    test('should handle offline backup configuration', () {
      const config = OfflineBackupConfig(
        maxQueueSize: 50,
        maxRetryAttempts: 3,
        retryDelay: Duration(minutes: 5),
        maxLocalStorageMB: 500,
        autoCleanupOnSync: true,
        priorityCategories: [DataCategory.transactions, DataCategory.wallets],
      );

      expect(config.maxQueueSize, equals(50));
      expect(config.maxRetryAttempts, equals(3));
      expect(config.retryDelay, equals(const Duration(minutes: 5)));
      expect(config.maxLocalStorageMB, equals(500));
      expect(config.autoCleanupOnSync, isTrue);
      expect(config.priorityCategories, contains(DataCategory.transactions));
      expect(config.priorityCategories, contains(DataCategory.wallets));
    });

    test('should create offline backup item correctly', () {
      final metadata = _createTestMetadata();

      final item = OfflineBackupItem(
        id: 'test-id',
        localPath: '/test/path/backup.mbk',
        metadata: metadata,
        createdAt: DateTime.now(),
        status: OfflineBackupStatus.pending,
        priority: 5,
      );

      expect(item.id, equals('test-id'));
      expect(item.localPath, equals('/test/path/backup.mbk'));
      expect(item.status, equals(OfflineBackupStatus.pending));
      expect(item.priority, equals(5));
      expect(item.canRetry, isFalse); // Not failed, so can't retry
      expect(item.isReadyForSync, isTrue); // Pending, so ready for sync
    });

    test('should handle item status changes', () {
      final metadata = _createTestMetadata();

      final item = OfflineBackupItem(
        id: 'test-id',
        localPath: '/test/path/backup.mbk',
        metadata: metadata,
        createdAt: DateTime.now(),
        status: OfflineBackupStatus.failed,
        retryCount: 2,
      );

      expect(item.canRetry, isTrue); // Failed with retry count < 3
      expect(item.isReadyForSync, isTrue); // Failed but can retry

      final itemWithMaxRetries = item.copyWith(retryCount: 3);
      expect(itemWithMaxRetries.canRetry, isFalse); // Max retries reached
    });
  });
}

EnhancedBackupMetadata _createTestMetadata() {
  return EnhancedBackupMetadata(
    version: '3.0',
    createdAt: DateTime.now(),
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
    includedDataTypes: const [DataCategory.transactions, DataCategory.wallets],
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
  );
}
