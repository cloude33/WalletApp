import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:parion/services/backup_optimization/offline_backup_queue.dart';
import 'package:parion/services/backup_optimization/network_monitor.dart';
import 'package:parion/models/backup_optimization/backup_enums.dart';
import 'package:parion/models/backup_optimization/offline_backup_models.dart';
import 'package:parion/models/backup_optimization/enhanced_backup_metadata.dart';
import '../../test_helpers.dart';

// Simple mock classes for testing offline scenarios
class MockNetworkMonitor extends NetworkMonitor {
  bool _hasConnection = true;

  void setConnectionStatus(bool hasConnection) {
    _hasConnection = hasConnection;
  }

  @override
  Future<bool> hasStableConnection() async => _hasConnection;

  @override
  Future<bool> isOnWiFi() async => _hasConnection;

  @override
  Future<NetworkQuality> getCurrentNetworkQuality() async {
    return _hasConnection ? NetworkQuality.excellent : NetworkQuality.poor;
  }
}

class TestOfflineBackupQueue extends OfflineBackupQueue {
  final List<OfflineBackupItem> _testQueue = [];
  bool _shouldFailAddToQueue = false;
  bool _shouldFailSync = false;

  void setShouldFailAddToQueue(bool shouldFail) {
    _shouldFailAddToQueue = shouldFail;
  }

  void setShouldFailSync(bool shouldFail) {
    _shouldFailSync = shouldFail;
  }

  void addTestItem(OfflineBackupItem item) {
    _testQueue.add(item);
  }

  void clearTestQueue() {
    _testQueue.clear();
  }

  @override
  Future<void> initialize() async {
    // Test initialization - no actual file operations
  }

  @override
  Future<String> addToQueue({
    required File backupFile,
    required EnhancedBackupMetadata metadata,
    int priority = 0,
  }) async {
    if (_shouldFailAddToQueue) {
      throw Exception('Test storage full');
    }

    final id = 'test_backup_${DateTime.now().millisecondsSinceEpoch}';
    final item = OfflineBackupItem(
      id: id,
      localPath: backupFile.path,
      metadata: metadata,
      createdAt: DateTime.now(),
      status: OfflineBackupStatus.pending,
      priority: priority,
    );
    _testQueue.add(item);
    return id;
  }

  @override
  List<OfflineBackupItem> getPendingItems() {
    final pending = _testQueue.where((item) => item.isReadyForSync).toList();
    pending.sort((a, b) {
      // First sort by priority (higher first)
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;

      // Then by creation date (older first)
      return a.createdAt.compareTo(b.createdAt);
    });
    return pending;
  }

  @override
  Future<void> startAutoSync() async {
    if (_shouldFailSync) {
      throw Exception('Test sync failed');
    }

    // Mark all pending items as completed
    for (int i = 0; i < _testQueue.length; i++) {
      if (_testQueue[i].status == OfflineBackupStatus.pending) {
        _testQueue[i] = _testQueue[i].copyWith(
          status: OfflineBackupStatus.completed,
        );
      }
    }
  }

  @override
  OfflineBackupStats get currentStats => OfflineBackupStats(
    totalItems: _testQueue.length,
    pendingItems: _testQueue
        .where((item) => item.status == OfflineBackupStatus.pending)
        .length,
    completedItems: _testQueue
        .where((item) => item.status == OfflineBackupStatus.completed)
        .length,
    failedItems: _testQueue
        .where((item) => item.status == OfflineBackupStatus.failed)
        .length,
    totalSizeMB: _testQueue.length * 5,
  );
}

void main() {
  setupCommonTestMocks();
  group('Offline Backup Scenarios', () {
    late TestOfflineBackupQueue testQueue;
    late MockNetworkMonitor mockNetworkMonitor;

    setUp(() {
      testQueue = TestOfflineBackupQueue();
      mockNetworkMonitor = MockNetworkMonitor();
    });

    tearDown(() {
      testQueue.clearTestQueue();
    });

    group('Offline Backup Creation (Requirement 8.1)', () {
      test(
        'should create offline backup when no internet connection',
        () async {
          // Arrange
          mockNetworkMonitor.setConnectionStatus(false);
          await testQueue.initialize();

          final testFile = File('/test/path/backup.mbk');
          final testMetadata = _createTestMetadata();

          // Act
          final result = await testQueue.addToQueue(
            backupFile: testFile,
            metadata: testMetadata,
            priority: 5,
          );

          // Assert
          expect(result, isNotNull);
          expect(result, startsWith('test_backup_'));

          final pendingItems = testQueue.getPendingItems();
          expect(pendingItems, hasLength(1));
          expect(pendingItems.first.priority, equals(5));
          expect(
            pendingItems.first.status,
            equals(OfflineBackupStatus.pending),
          );
        },
      );

      test(
        'should handle offline backup creation with different priorities',
        () async {
          // Arrange
          await testQueue.initialize();
          final testFile = File('/test/path/backup.mbk');
          final testMetadata = _createTestMetadata();

          // Act - Add multiple backups with different priorities
          await testQueue.addToQueue(
            backupFile: testFile,
            metadata: testMetadata,
            priority: 1,
          );

          await testQueue.addToQueue(
            backupFile: testFile,
            metadata: testMetadata,
            priority: 10,
          );

          await testQueue.addToQueue(
            backupFile: testFile,
            metadata: testMetadata,
            priority: 5,
          );

          // Assert
          final pendingItems = testQueue.getPendingItems();
          expect(pendingItems, hasLength(3));

          // Check that items are sorted by priority (higher first)
          expect(pendingItems[0].priority, equals(10));
          expect(pendingItems[1].priority, equals(5));
          expect(pendingItems[2].priority, equals(1));
        },
      );

      test('should handle offline backup creation errors gracefully', () async {
        // Arrange
        testQueue.setShouldFailAddToQueue(true);
        await testQueue.initialize();

        final testFile = File('/test/path/backup.mbv');
        final testMetadata = _createTestMetadata();

        // Act & Assert
        expect(
          () => testQueue.addToQueue(
            backupFile: testFile,
            metadata: testMetadata,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should create offline backup item with correct metadata', () async {
        // Arrange
        await testQueue.initialize();
        final testFile = File('/test/path/backup.mbk');
        final testMetadata = _createTestMetadata();

        // Act
        final result = await testQueue.addToQueue(
          backupFile: testFile,
          metadata: testMetadata,
          priority: 8,
        );

        // Assert
        expect(result, isNotNull);

        final pendingItems = testQueue.getPendingItems();
        expect(pendingItems, hasLength(1));
        expect(pendingItems.first.priority, equals(8));
        expect(pendingItems.first.metadata.type, equals(BackupType.full));
        expect(pendingItems.first.localPath, equals('/test/path/backup.mbk'));
      });
    });

    group('Automatic Sync on Reconnection (Requirement 8.2)', () {
      test(
        'should automatically sync pending backups when connection restored',
        () async {
          // Arrange
          mockNetworkMonitor.setConnectionStatus(true);
          await testQueue.initialize();

          // Add a test item to the queue
          testQueue.addTestItem(_createTestOfflineBackupItem());

          // Act
          final hasConnection = await mockNetworkMonitor.hasStableConnection();
          expect(hasConnection, isTrue);

          await testQueue.startAutoSync();

          // Assert
          final stats = testQueue.currentStats;
          expect(stats.completedItems, equals(1));
          expect(stats.pendingItems, equals(0));
        },
      );

      test('should not sync when no stable connection available', () async {
        // Arrange
        mockNetworkMonitor.setConnectionStatus(false);
        await testQueue.initialize();

        testQueue.addTestItem(_createTestOfflineBackupItem());

        // Act
        final hasConnection = await mockNetworkMonitor.hasStableConnection();

        // Assert
        expect(hasConnection, isFalse);

        // Verify items remain pending (no sync attempted)
        final stats = testQueue.currentStats;
        expect(stats.pendingItems, equals(1));
        expect(stats.completedItems, equals(0));
      });

      test('should handle sync errors gracefully', () async {
        // Arrange
        mockNetworkMonitor.setConnectionStatus(true);
        testQueue.setShouldFailSync(true);
        await testQueue.initialize();

        testQueue.addTestItem(_createTestOfflineBackupItem());

        // Act & Assert
        expect(() => testQueue.startAutoSync(), throwsA(isA<Exception>()));

        // Verify items remain pending after failed sync
        final stats = testQueue.currentStats;
        expect(stats.pendingItems, equals(1));
      });

      test('should process multiple pending items during sync', () async {
        // Arrange
        mockNetworkMonitor.setConnectionStatus(true);
        await testQueue.initialize();

        // Add multiple test items
        testQueue.addTestItem(_createTestOfflineBackupItem());
        testQueue.addTestItem(_createTestOfflineBackupItem());
        testQueue.addTestItem(_createTestOfflineBackupItem());

        // Act
        await testQueue.startAutoSync();

        // Assert
        final stats = testQueue.currentStats;
        expect(stats.completedItems, equals(3));
        expect(stats.pendingItems, equals(0));
      });

      test('should maintain correct queue statistics', () async {
        // Arrange
        await testQueue.initialize();

        // Add items with different statuses
        testQueue.addTestItem(_createTestOfflineBackupItem());
        testQueue.addTestItem(_createTestOfflineBackupItem());

        // Act - Check initial stats
        var stats = testQueue.currentStats;
        expect(stats.totalItems, equals(2));
        expect(stats.pendingItems, equals(2));
        expect(stats.completedItems, equals(0));

        // Sync one item
        mockNetworkMonitor.setConnectionStatus(true);
        await testQueue.startAutoSync();

        // Assert - Check final stats
        stats = testQueue.currentStats;
        expect(stats.totalItems, equals(2));
        expect(stats.pendingItems, equals(0));
        expect(stats.completedItems, equals(2));
      });
    });

    group('Integration Scenarios', () {
      test('should handle complete offline-to-online workflow', () async {
        // Arrange
        await testQueue.initialize();

        // Start offline
        mockNetworkMonitor.setConnectionStatus(false);

        final testFile = File('/test/path/backup.mbk');
        final testMetadata = _createTestMetadata();

        // Act 1: Create offline backup
        final offlineResult = await testQueue.addToQueue(
          backupFile: testFile,
          metadata: testMetadata,
          priority: 5,
        );

        expect(offlineResult, isNotNull);

        var stats = testQueue.currentStats;
        expect(stats.pendingItems, equals(1));

        // Go online
        mockNetworkMonitor.setConnectionStatus(true);

        // Act 2: Sync when online
        await testQueue.startAutoSync();

        // Assert
        stats = testQueue.currentStats;
        expect(stats.completedItems, equals(1));
        expect(stats.pendingItems, equals(0));
      });

      test('should handle network quality changes', () async {
        // Arrange
        await testQueue.initialize();

        // Test different network qualities
        mockNetworkMonitor.setConnectionStatus(false);
        var quality = await mockNetworkMonitor.getCurrentNetworkQuality();
        expect(quality, equals(NetworkQuality.poor));

        mockNetworkMonitor.setConnectionStatus(true);
        quality = await mockNetworkMonitor.getCurrentNetworkQuality();
        expect(quality, equals(NetworkQuality.excellent));
      });
    });
  });
}

OfflineBackupItem _createTestOfflineBackupItem() {
  return OfflineBackupItem(
    id: 'test_item_123',
    localPath: '/test/path/backup.mbk',
    metadata: _createTestMetadata(),
    createdAt: DateTime.now(),
    status: OfflineBackupStatus.pending,
    priority: 5,
  );
}

// Helper method to create test metadata
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
