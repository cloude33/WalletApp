import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../models/backup_optimization/offline_backup_models.dart';
import '../../models/backup_optimization/enhanced_backup_metadata.dart';
import '../../models/backup_optimization/backup_enums.dart';
import '../google_drive_service.dart';
import 'network_monitor.dart';

/// Service for managing offline backup queue and synchronization
class OfflineBackupQueue {
  static const String _queueFileName = 'offline_backup_queue.json';
  static const String _configFileName = 'offline_backup_config.json';

  final GoogleDriveService _driveService;
  final NetworkMonitor _networkMonitor;

  List<OfflineBackupItem> _queue = [];
  OfflineBackupConfig _config = const OfflineBackupConfig();
  Timer? _syncTimer;

  final ValueNotifier<bool> isSyncing = ValueNotifier(false);
  final ValueNotifier<OfflineBackupStats> stats = ValueNotifier(
    const OfflineBackupStats(
      totalItems: 0,
      pendingItems: 0,
      completedItems: 0,
      failedItems: 0,
      totalSizeMB: 0,
    ),
  );

  OfflineBackupQueue({
    GoogleDriveService? driveService,
    NetworkMonitor? networkMonitor,
  }) : _driveService = driveService ?? GoogleDriveService(),
       _networkMonitor = networkMonitor ?? NetworkMonitor();

  /// Initialize the offline backup queue
  Future<void> initialize() async {
    await _loadQueue();
    await _loadConfig();
    _updateStats();
    _startPeriodicSync();
  }

  /// Add a backup to the offline queue
  Future<String> addToQueue({
    required File backupFile,
    required EnhancedBackupMetadata metadata,
    int priority = 0,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    // Check queue capacity
    if (_queue.length >= _config.maxQueueSize) {
      await _cleanupOldestItems(1);
    }

    // Check storage capacity
    final fileSizeMB = await _getFileSizeMB(backupFile);
    if (_getTotalStorageMB() + fileSizeMB > _config.maxLocalStorageMB) {
      await _freeUpStorage(fileSizeMB);
    }

    // Move file to queue directory
    final queueDir = await _getQueueDirectory();
    final queueFileName = 'backup_$id.mbk';
    final queueFilePath = path.join(queueDir.path, queueFileName);
    final queueFile = await backupFile.copy(queueFilePath);

    // Create queue item
    final item = OfflineBackupItem(
      id: id,
      localPath: queueFile.path,
      metadata: metadata,
      createdAt: DateTime.now(),
      status: OfflineBackupStatus.pending,
      priority: priority,
    );

    _queue.add(item);
    await _saveQueue();
    _updateStats();

    // Try immediate sync if online
    if (await _networkMonitor.hasStableConnection()) {
      _triggerSync();
    }

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

  /// Remove an item from the queue
  Future<bool> removeFromQueue(String id) async {
    final index = _queue.indexWhere((item) => item.id == id);
    if (index == -1) return false;

    final item = _queue[index];

    // Delete local file
    try {
      final file = File(item.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting queue file: $e');
    }

    _queue.removeAt(index);
    await _saveQueue();
    _updateStats();

    return true;
  }

  /// Start automatic synchronization when connection is available
  Future<void> startAutoSync() async {
    if (isSyncing.value) return;

    isSyncing.value = true;

    try {
      final pendingItems = getPendingItems();

      for (final item in pendingItems) {
        // Check connection before each item
        if (!await _networkMonitor.hasStableConnection()) {
          debugPrint('Connection lost during sync, stopping');
          break;
        }

        await _syncItem(item);
      }

      // Cleanup completed items if configured
      if (_config.autoCleanupOnSync) {
        await _cleanupCompletedItems();
      }
    } finally {
      isSyncing.value = false;
      _updateStats();
    }
  }

  /// Sync a specific item to cloud
  Future<bool> _syncItem(OfflineBackupItem item) async {
    try {
      // Update status to syncing
      await _updateItemStatus(item.id, OfflineBackupStatus.syncing);

      // Check if file exists
      final file = File(item.localPath);
      if (!await file.exists()) {
        throw Exception('Local backup file not found');
      }

      // Upload to Google Drive
      final fileName = 'offline_backup_${item.id}.mbk';
      final result = await _driveService.uploadBackup(
        file,
        fileName,
        description: 'Offline Backup - ${item.metadata.type.displayName}',
      );

      if (result == null) {
        throw Exception('Upload failed - no result returned');
      }

      // Mark as completed
      await _updateItemStatus(item.id, OfflineBackupStatus.completed);

      debugPrint('Successfully synced offline backup: ${item.id}');
      return true;
    } catch (e) {
      debugPrint('Error syncing item ${item.id}: $e');

      // Update retry count and status
      final updatedItem = item.copyWith(
        status: OfflineBackupStatus.failed,
        retryCount: item.retryCount + 1,
        lastRetryAt: DateTime.now(),
        errorMessage: e.toString(),
      );

      await _updateItem(updatedItem);
      return false;
    }
  }

  /// Update configuration
  Future<void> updateConfig(OfflineBackupConfig config) async {
    _config = config;
    await _saveConfig();
  }

  /// Get current configuration
  OfflineBackupConfig get config => _config;

  /// Get current statistics
  OfflineBackupStats get currentStats => stats.value;

  /// Clean up old completed items
  Future<void> _cleanupCompletedItems() async {
    final completedItems = _queue
        .where((item) => item.status == OfflineBackupStatus.completed)
        .toList();

    for (final item in completedItems) {
      await removeFromQueue(item.id);
    }
  }

  /// Clean up oldest items to make space
  Future<void> _cleanupOldestItems(int count) async {
    final sortedItems = List<OfflineBackupItem>.from(_queue);
    sortedItems.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (int i = 0; i < count && i < sortedItems.length; i++) {
      await removeFromQueue(sortedItems[i].id);
    }
  }

  /// Free up storage space
  Future<void> _freeUpStorage(int requiredMB) async {
    int freedMB = 0;
    final sortedItems = List<OfflineBackupItem>.from(_queue);

    // Sort by priority (lower first) and age (older first)
    sortedItems.sort((a, b) {
      final priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) return priorityCompare;
      return a.createdAt.compareTo(b.createdAt);
    });

    for (final item in sortedItems) {
      if (freedMB >= requiredMB) break;

      final file = File(item.localPath);
      if (await file.exists()) {
        final sizeMB = await _getFileSizeMB(file);
        await removeFromQueue(item.id);
        freedMB += sizeMB;
      }
    }
  }

  /// Update item status
  Future<void> _updateItemStatus(String id, OfflineBackupStatus status) async {
    final index = _queue.indexWhere((item) => item.id == id);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(status: status);
      await _saveQueue();
    }
  }

  /// Update entire item
  Future<void> _updateItem(OfflineBackupItem updatedItem) async {
    final index = _queue.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _queue[index] = updatedItem;
      await _saveQueue();
    }
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkAndSync();
    });
  }

  /// Check connection and trigger sync if available
  Future<void> _checkAndSync() async {
    if (isSyncing.value) return;

    if (await _networkMonitor.hasStableConnection()) {
      final pendingCount = _queue.where((item) => item.isReadyForSync).length;
      if (pendingCount > 0) {
        debugPrint(
          'Connection available, starting auto sync for $pendingCount items',
        );
        _triggerSync();
      }
    }
  }

  /// Trigger sync without waiting
  void _triggerSync() {
    Future.microtask(() => startAutoSync());
  }

  /// Update statistics
  void _updateStats() {
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

    DateTime? oldestDate;
    DateTime? newestDate;

    if (_queue.isNotEmpty) {
      oldestDate = _queue
          .map((item) => item.createdAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      newestDate = _queue
          .map((item) => item.createdAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }

    stats.value = OfflineBackupStats(
      totalItems: totalItems,
      pendingItems: pendingItems,
      completedItems: completedItems,
      failedItems: failedItems,
      totalSizeMB: _getTotalStorageMB(),
      oldestItemDate: oldestDate,
      newestItemDate: newestDate,
    );
  }

  /// Get total storage used by queue in MB
  int _getTotalStorageMB() {
    // This is an approximation - in real implementation we'd calculate actual file sizes
    return _queue.length * 5; // Assume average 5MB per backup
  }

  /// Get file size in MB
  Future<int> _getFileSizeMB(File file) async {
    try {
      final stat = await file.stat();
      return (stat.size / (1024 * 1024)).ceil();
    } catch (e) {
      return 5; // Default assumption
    }
  }

  /// Get queue directory
  Future<Directory> _getQueueDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Offline backup queue not supported on web');
    }

    final appDir = await getApplicationDocumentsDirectory();
    final queueDir = Directory(path.join(appDir.path, 'offline_backup_queue'));

    if (!await queueDir.exists()) {
      await queueDir.create(recursive: true);
    }

    return queueDir;
  }

  /// Load queue from storage
  Future<void> _loadQueue() async {
    try {
      if (kIsWeb) return;

      final queueDir = await _getQueueDirectory();
      final queueFile = File(path.join(queueDir.path, _queueFileName));

      if (await queueFile.exists()) {
        final jsonString = await queueFile.readAsString();
        final jsonData = jsonDecode(jsonString) as List<dynamic>;

        _queue = jsonData
            .map(
              (item) =>
                  OfflineBackupItem.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        // Verify local files still exist
        _queue = await _verifyLocalFiles(_queue);
      }
    } catch (e) {
      debugPrint('Error loading offline backup queue: $e');
      _queue = [];
    }
  }

  /// Save queue to storage
  Future<void> _saveQueue() async {
    try {
      if (kIsWeb) return;

      final queueDir = await _getQueueDirectory();
      final queueFile = File(path.join(queueDir.path, _queueFileName));

      final jsonData = _queue.map((item) => item.toJson()).toList();
      final jsonString = jsonEncode(jsonData);

      await queueFile.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Error saving offline backup queue: $e');
    }
  }

  /// Load configuration from storage
  Future<void> _loadConfig() async {
    try {
      if (kIsWeb) return;

      final queueDir = await _getQueueDirectory();
      final configFile = File(path.join(queueDir.path, _configFileName));

      if (await configFile.exists()) {
        final jsonString = await configFile.readAsString();
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        _config = OfflineBackupConfig.fromJson(jsonData);
      }
    } catch (e) {
      debugPrint('Error loading offline backup config: $e');
      _config = const OfflineBackupConfig();
    }
  }

  /// Save configuration to storage
  Future<void> _saveConfig() async {
    try {
      if (kIsWeb) return;

      final queueDir = await _getQueueDirectory();
      final configFile = File(path.join(queueDir.path, _configFileName));

      final jsonString = jsonEncode(_config.toJson());
      await configFile.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Error saving offline backup config: $e');
    }
  }

  /// Verify that local files still exist and remove missing ones
  Future<List<OfflineBackupItem>> _verifyLocalFiles(
    List<OfflineBackupItem> items,
  ) async {
    final validItems = <OfflineBackupItem>[];

    for (final item in items) {
      final file = File(item.localPath);
      if (await file.exists()) {
        validItems.add(item);
      } else {
        debugPrint('Removing missing file from queue: ${item.localPath}');
      }
    }

    return validItems;
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    isSyncing.dispose();
    stats.dispose();
  }
}
