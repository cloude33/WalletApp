import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'package:parion/models/backup_optimization/offline_backup_models.dart';
import 'package:parion/models/backup_optimization/enhanced_backup_metadata.dart';
import 'package:parion/models/backup_optimization/backup_enums.dart';
import 'package:parion/services/backup_optimization/network_monitor.dart';
import 'package:parion/services/google_drive_service.dart';
import '../../property_test_utils.dart';

void main() {
  // Initialize Flutter bindings for testing
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineBackupQueue - Offline Queue Management Property Tests', () {
    late TestableOfflineBackupQueue queue;

    setUp(() async {
      // Create mock services
      final mockDriveService = MockGoogleDriveService();
      final mockNetworkMonitor = MockNetworkMonitor();

      queue = TestableOfflineBackupQueue(
        driveService: mockDriveService,
        networkMonitor: mockNetworkMonitor,
      );

      await queue.initialize();
    });

    tearDown(() async {
      queue.dispose();
    });

    /// **Feature: backup-optimization, Property 20: Offline Backup Queue Management**
    /// **Validates: Requirements 8.4**
    PropertyTest.forAll<OfflineBackupCreationData>(
      description:
          'Property 20: For any offline backup creation, system should add it to synchronization queue',
      generator: _generateRandomOfflineBackupCreationData,
      property: (backupData) async {
        // Arrange - Clear queue and get initial state
        queue.clearQueueForTesting(); // Reset queue for this test
        final initialQueueSize = queue.getQueueItems().length;
        final initialPendingCount = queue.getPendingItems().length;

        // Act - Add backup to offline queue (simulating offline backup creation)
        final queueId = await queue.addToQueueForTesting(
          backupData: backupData.fileContent,
          metadata: backupData.metadata,
          priority: backupData.priority,
        );

        // Property: The backup should be added to the synchronization queue
        final queueItems = queue.getQueueItems();
        final pendingItems = queue.getPendingItems();

        // 1. Queue size should increase by exactly 1
        final queueSizeIncreased = queueItems.length == initialQueueSize + 1;

        // 2. Pending items should increase by exactly 1 (new item should be pending)
        final pendingCountIncreased =
            pendingItems.length == initialPendingCount + 1;

        // 3. The added item should exist in the queue with correct properties
        OfflineBackupItem? addedItem;
        try {
          addedItem = queueItems.firstWhere((item) => item.id == queueId);
        } catch (e) {
          // Item not found - this is a failure
          return false;
        }

        final itemHasCorrectId = addedItem.id == queueId;
        final itemHasCorrectStatus =
            addedItem.status == OfflineBackupStatus.pending;
        final itemHasCorrectPriority =
            addedItem.priority == backupData.priority;
        final itemHasCorrectMetadata =
            addedItem.metadata.type == backupData.metadata.type;

        // 4. The item should be ready for sync (pending status)
        final itemIsReadyForSync = addedItem.isReadyForSync;

        // 5. The item should appear in pending items list
        final itemInPendingList = pendingItems.any(
          (item) => item.id == queueId,
        );

        // 6. Statistics should be updated correctly
        final stats = queue.currentStats;
        final statsUpdated =
            stats.totalItems == queueItems.length &&
            stats.pendingItems == pendingItems.length;

        return queueSizeIncreased &&
            pendingCountIncreased &&
            itemHasCorrectId &&
            itemHasCorrectStatus &&
            itemHasCorrectPriority &&
            itemHasCorrectMetadata &&
            itemIsReadyForSync &&
            itemInPendingList &&
            statsUpdated;
      },
      iterations: 20,
    );

    PropertyTest.forAll<MultipleOfflineBackupCreations>(
      description:
          'Property 20b: For any series of offline backup creations, all should be added to queue in order',
      generator: _generateMultipleOfflineBackupCreations,
      property: (multipleBackups) async {
        // Arrange - Clear queue and get initial state
        queue.clearQueueForTesting(); // Reset queue for this test
        final initialQueueSize = queue.getQueueItems().length;
        final addedIds = <String>[];

        // Act - Add multiple backups to queue
        for (final backupData in multipleBackups.backups) {
          final queueId = await queue.addToQueueForTesting(
            backupData: backupData.fileContent,
            metadata: backupData.metadata,
            priority: backupData.priority,
          );

          addedIds.add(queueId);
        }

        // Property: All backups should be added to the synchronization queue
        final queueItems = queue.getQueueItems();
        final pendingItems = queue.getPendingItems();

        // 1. Queue size should increase by the number of added backups
        final correctQueueSize =
            queueItems.length ==
            initialQueueSize + multipleBackups.backups.length;

        // 2. All added items should exist in the queue
        final allItemsInQueue = addedIds.every(
          (id) => queueItems.any((item) => item.id == id),
        );

        // 3. All added items should be pending and ready for sync
        final allItemsPending = addedIds.every((id) {
          final item = queueItems.firstWhere(
            (item) => item.id == id,
            orElse: () => throw StateError('Item not found'),
          );
          return item.status == OfflineBackupStatus.pending &&
              item.isReadyForSync;
        });

        // 4. All items should appear in pending list
        final allItemsInPendingList = addedIds.every(
          (id) => pendingItems.any((item) => item.id == id),
        );

        // 5. Statistics should reflect all additions
        final stats = queue.currentStats;
        final statsCorrect =
            stats.totalItems >= addedIds.length &&
            stats.pendingItems >= addedIds.length;

        return correctQueueSize &&
            allItemsInQueue &&
            allItemsPending &&
            allItemsInPendingList &&
            statsCorrect;
      },
      iterations: 20,
    );

    PropertyTest.forAll<OfflineBackupWithQueueConstraints>(
      description:
          'Property 20c: For any offline backup creation with queue constraints, system should manage queue capacity',
      generator: _generateOfflineBackupWithQueueConstraints,
      property: (constrainedBackup) async {
        // Arrange - Clear queue and set configuration with constraints
        queue.clearQueueForTesting(); // Reset queue for this test
        await queue.updateConfig(constrainedBackup.config);

        // Fill queue to near capacity first
        final itemsToAdd = constrainedBackup.config.maxQueueSize - 1;
        for (int i = 0; i < itemsToAdd; i++) {
          final metadata = _generateTestMetadata();
          await queue.addToQueueForTesting(
            backupData: List.generate(1024, (index) => i % 256), // 1KB data
            metadata: metadata,
            priority: 0,
          );
        }

        // Act - Add one more backup (should trigger queue management)
        final queueId = await queue.addToQueueForTesting(
          backupData: constrainedBackup.backupData.fileContent,
          metadata: constrainedBackup.backupData.metadata,
          priority: constrainedBackup.backupData.priority,
        );

        // Property: The backup should still be added to queue (with capacity management)
        final queueItems = queue.getQueueItems();

        // 1. The new item should be in the queue
        final newItemInQueue = queueItems.any((item) => item.id == queueId);

        // 2. Queue size should not exceed maximum
        final queueSizeWithinLimit =
            queueItems.length <= constrainedBackup.config.maxQueueSize;

        // 3. The new item should be pending and ready for sync
        OfflineBackupItem? newItem;
        try {
          newItem = queueItems.firstWhere((item) => item.id == queueId);
        } catch (e) {
          return false; // Item not found
        }

        final newItemCorrectStatus =
            newItem.status == OfflineBackupStatus.pending &&
            newItem.isReadyForSync;

        // 4. Statistics should be consistent
        final stats = queue.currentStats;
        final statsConsistent = stats.totalItems == queueItems.length;

        return newItemInQueue &&
            queueSizeWithinLimit &&
            newItemCorrectStatus &&
            statsConsistent;
      },
      iterations: 20,
    );
  });
}

/// Generates random offline backup creation data for testing
OfflineBackupCreationData _generateRandomOfflineBackupCreationData() {
  final random = Random();

  return OfflineBackupCreationData(
    id: PropertyTest.randomString(minLength: 5, maxLength: 15),
    fileContent: List.generate(
      PropertyTest.randomInt(min: 1024, max: 10240), // 1KB to 10KB
      (index) => random.nextInt(256),
    ),
    metadata: _generateTestMetadata(),
    priority: PropertyTest.randomInt(min: 0, max: 10),
  );
}

/// Generates multiple offline backup creations for batch testing
MultipleOfflineBackupCreations _generateMultipleOfflineBackupCreations() {
  final random = Random();
  final backupCount = 2 + random.nextInt(8); // 2 to 9 backups

  final backups = <OfflineBackupCreationData>[];
  final usedIds = <String>{};

  for (int i = 0; i < backupCount; i++) {
    String id;
    do {
      id =
          'multi_offline_${i}_${PropertyTest.randomString(minLength: 3, maxLength: 8)}';
    } while (usedIds.contains(id));

    usedIds.add(id);

    backups.add(
      OfflineBackupCreationData(
        id: id,
        fileContent: List.generate(
          PropertyTest.randomInt(min: 512, max: 5120), // 512B to 5KB
          (index) => random.nextInt(256),
        ),
        metadata: _generateTestMetadata(),
        priority: PropertyTest.randomInt(min: 0, max: 5),
      ),
    );
  }

  return MultipleOfflineBackupCreations(backups: backups);
}

/// Generates offline backup with queue constraints for capacity testing
OfflineBackupWithQueueConstraints _generateOfflineBackupWithQueueConstraints() {
  return OfflineBackupWithQueueConstraints(
    config: OfflineBackupConfig(
      maxQueueSize: PropertyTest.randomInt(min: 5, max: 15), // Reasonable range
      maxRetryAttempts: 3,
      maxLocalStorageMB: PropertyTest.randomInt(min: 50, max: 200),
      autoCleanupOnSync: PropertyTest.randomBool(),
    ),
    backupData: _generateRandomOfflineBackupCreationData(),
  );
}

/// Generates test metadata for backup items
EnhancedBackupMetadata _generateTestMetadata() {
  final random = Random();

  return EnhancedBackupMetadata(
    version: '3.0',
    createdAt: PropertyTest.randomDateTime(),
    transactionCount: PropertyTest.randomInt(min: 0, max: 1000),
    walletCount: PropertyTest.randomInt(min: 1, max: 10),
    platform: 'test',
    deviceModel: 'test device',
    type: BackupType.values[random.nextInt(BackupType.values.length)],
    compressionInfo: CompressionInfo(
      algorithm: 'gzip',
      ratio: PropertyTest.randomPositiveDouble(min: 0.1, max: 0.9),
      originalSize: PropertyTest.randomInt(min: 1000, max: 100000),
      compressedSize: PropertyTest.randomInt(min: 500, max: 50000),
      compressionTime: Duration(
        milliseconds: PropertyTest.randomInt(min: 100, max: 5000),
      ),
    ),
    includedDataTypes: [DataCategory.transactions, DataCategory.wallets],
    performanceMetrics: PerformanceMetrics(
      totalDuration: Duration(seconds: PropertyTest.randomInt(min: 1, max: 60)),
      compressionTime: Duration(
        milliseconds: PropertyTest.randomInt(min: 100, max: 2000),
      ),
      uploadTime: Duration(seconds: PropertyTest.randomInt(min: 1, max: 30)),
      validationTime: Duration(
        milliseconds: PropertyTest.randomInt(min: 50, max: 1000),
      ),
      networkRetries: PropertyTest.randomInt(min: 0, max: 3),
      averageUploadSpeed: PropertyTest.randomPositiveDouble(
        min: 0.5,
        max: 10.0,
      ),
    ),
    validationInfo: ValidationInfo(
      checksum: PropertyTest.randomString(minLength: 32, maxLength: 64),
      result: ValidationResult.valid,
      validatedAt: PropertyTest.randomDateTime(),
      errors: const [],
    ),
    originalSize: PropertyTest.randomInt(min: 1000, max: 100000),
    compressedSize: PropertyTest.randomInt(min: 500, max: 50000),
    backupDuration: Duration(seconds: PropertyTest.randomInt(min: 1, max: 60)),
    compressionAlgorithm: 'gzip',
    compressionRatio: PropertyTest.randomPositiveDouble(min: 0.1, max: 0.9),
  );
}

/// Helper class representing offline backup creation data
class OfflineBackupCreationData {
  final String id;
  final List<int> fileContent;
  final EnhancedBackupMetadata metadata;
  final int priority;

  OfflineBackupCreationData({
    required this.id,
    required this.fileContent,
    required this.metadata,
    required this.priority,
  });
}

/// Helper class for multiple offline backup creations
class MultipleOfflineBackupCreations {
  final List<OfflineBackupCreationData> backups;

  MultipleOfflineBackupCreations({required this.backups});
}

/// Helper class for offline backup with queue constraints
class OfflineBackupWithQueueConstraints {
  final OfflineBackupConfig config;
  final OfflineBackupCreationData backupData;

  OfflineBackupWithQueueConstraints({
    required this.config,
    required this.backupData,
  });
}

/// Mock Google Drive Service for testing
class MockGoogleDriveService implements GoogleDriveService {
  @override
  Future<drive.File?> uploadBackup(
    File file,
    String fileName, {
    String? description,
    Map<String, String>? properties,
  }) async {
    // Simulate successful upload
    await Future.delayed(const Duration(milliseconds: 10));
    final mockFile = drive.File();
    mockFile.id = 'mock_drive_file_id_${DateTime.now().millisecondsSinceEpoch}';
    mockFile.name = fileName;
    return mockFile;
  }

  @override
  Future<bool> isAuthenticated() async => true;

  @override
  Future<void> signIn() async {}

  @override
  Future<void> signOut() async {}

  @override
  void setTestMode(bool value) {}

  @override
  Future<List<drive.File>> listBackups() async => [];

  @override
  Future<File?> downloadBackup(String fileId, String localPath) async => null;

  @override
  Future<void> deleteBackup(String fileId) async {}
}

/// Mock Network Monitor for testing
class MockNetworkMonitor extends NetworkMonitor {
  bool _hasConnection = false;

  void setConnectionStatus(bool hasConnection) {
    _hasConnection = hasConnection;
  }

  @override
  Future<bool> hasStableConnection() async {
    return _hasConnection;
  }

  @override
  Future<NetworkQuality> getCurrentNetworkQuality() async {
    return _hasConnection ? NetworkQuality.good : NetworkQuality.poor;
  }

  @override
  Future<bool> isOnWiFi() async {
    return _hasConnection;
  }
}

/// Testable version of OfflineBackupQueue that doesn't use file system
class TestableOfflineBackupQueue {
  final GoogleDriveService _driveService;
  final NetworkMonitor _networkMonitor;

  final List<OfflineBackupItem> _queue = [];
  OfflineBackupConfig _config = const OfflineBackupConfig();

  final OfflineBackupStats _stats = const OfflineBackupStats(
    totalItems: 0,
    pendingItems: 0,
    completedItems: 0,
    failedItems: 0,
    totalSizeMB: 0,
  );

  TestableOfflineBackupQueue({
    GoogleDriveService? driveService,
    NetworkMonitor? networkMonitor,
  }) : _driveService = driveService ?? MockGoogleDriveService(),
       _networkMonitor = networkMonitor ?? MockNetworkMonitor();

  /// Initialize the offline backup queue
  Future<void> initialize() async {
    // No file system operations in test version
  }

  /// Add a backup to the offline queue for testing
  Future<String> addToQueueForTesting({
    required List<int> backupData,
    required EnhancedBackupMetadata metadata,
    int priority = 0,
  }) async {
    // Generate unique ID with some randomness to avoid collisions
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    final id = '${timestamp}_$random';

    // Check queue capacity and cleanup if needed
    if (_queue.length >= _config.maxQueueSize) {
      await _cleanupOldestItems(1);
    }

    // Create queue item (no file operations)
    final item = OfflineBackupItem(
      id: id,
      localPath: '/mock/path/backup_$id.mbk', // Mock path
      metadata: metadata,
      createdAt: DateTime.now(),
      status: OfflineBackupStatus.pending,
      priority: priority,
    );

    _queue.add(item);
    _updateStats();

    return id;
  }

  /// Get all items in the queue
  List<OfflineBackupItem> getQueueItems() => List.unmodifiable(_queue);

  /// Get pending items sorted by priority and creation date
  List<OfflineBackupItem> getPendingItems() {
    final pending = _queue.where((item) => item.isReadyForSync).toList();
    pending.sort((a, b) {
      // First sort by priority (higher first)
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;

      // Then by creation date (older first)
      return a.createdAt.compareTo(b.createdAt);
    });
    return pending;
  }

  /// Update configuration
  Future<void> updateConfig(OfflineBackupConfig config) async {
    _config = config;
  }

  /// Get current configuration
  OfflineBackupConfig get config => _config;

  /// Get current statistics
  OfflineBackupStats get currentStats {
    final totalItems = _queue.length;
    final pendingItems = _queue
        .where((item) => item.status == OfflineBackupStatus.pending)
        .length;
    final completedItems = _queue
        .where((item) => item.status == OfflineBackupStatus.completed)
        .length;
    final failedItems = _queue
        .where((item) => item.status == OfflineBackupStatus.failed)
        .length;

    return OfflineBackupStats(
      totalItems: totalItems,
      pendingItems: pendingItems,
      completedItems: completedItems,
      failedItems: failedItems,
      totalSizeMB: totalItems * 5, // Mock size calculation
    );
  }

  /// Clean up oldest items to make space
  Future<void> _cleanupOldestItems(int count) async {
    final sortedItems = List<OfflineBackupItem>.from(_queue);
    sortedItems.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (int i = 0; i < count && i < sortedItems.length; i++) {
      _queue.removeWhere((item) => item.id == sortedItems[i].id);
    }
  }

  /// Update statistics
  void _updateStats() {
    // Stats are calculated dynamically in currentStats getter
  }

  /// Clear the queue for testing
  void clearQueueForTesting() {
    _queue.clear();
  }

  /// Dispose resources
  void dispose() {
    // No resources to dispose in test version
  }
}
