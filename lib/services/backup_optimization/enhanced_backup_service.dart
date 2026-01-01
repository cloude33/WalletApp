import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../backup_service.dart';
import '../../models/backup_optimization/enhanced_backup_metadata.dart';
import '../../models/backup_optimization/backup_enums.dart';

import '../../models/backup_optimization/offline_backup_models.dart';
import 'offline_backup_queue.dart';
import 'local_storage_manager.dart';
import 'network_monitor.dart';

/// Enhanced backup service with offline support and optimization features
class EnhancedBackupService extends BackupService {
  final OfflineBackupQueue _offlineQueue;
  final LocalStorageManager _storageManager;
  final NetworkMonitor _networkMonitor;

  final ValueNotifier<bool> isOfflineMode = ValueNotifier(false);
  final ValueNotifier<int> pendingOfflineBackups = ValueNotifier(0);

  EnhancedBackupService({
    OfflineBackupQueue? offlineQueue,
    LocalStorageManager? storageManager,
    NetworkMonitor? networkMonitor,
  }) : _offlineQueue = offlineQueue ?? OfflineBackupQueue(),
       _storageManager = storageManager ?? LocalStorageManager(),
       _networkMonitor = networkMonitor ?? NetworkMonitor();

  /// Initialize the enhanced backup service
  Future<void> initialize() async {
    await _offlineQueue.initialize();
    await _storageManager.initialize();
    await _monitorNetworkStatus();
    _updatePendingCount();
  }

  /// Create backup with offline support
  Future<String?> createBackupWithOfflineSupport({
    BackupType type = BackupType.full,
    List<DataCategory>? categories,
    int priority = 0,
  }) async {
    try {
      // Check network status
      final hasConnection = await _networkMonitor.hasStableConnection();

      if (hasConnection) {
        // Online backup - use existing cloud backup
        final success = await uploadToCloud();
        if (success) {
          return 'cloud_backup_${DateTime.now().millisecondsSinceEpoch}';
        } else {
          // Fallback to offline if cloud backup fails
          return await _createOfflineBackup(type, categories, priority);
        }
      } else {
        // Offline backup
        return await _createOfflineBackup(type, categories, priority);
      }
    } catch (e) {
      debugPrint('Error creating backup: $e');
      // Fallback to offline backup on any error
      return await _createOfflineBackup(type, categories, priority);
    }
  }

  /// Create offline backup and add to queue
  Future<String?> _createOfflineBackup(
    BackupType type,
    List<DataCategory>? categories,
    int priority,
  ) async {
    try {
      if (kIsWeb) {
        throw UnsupportedError('Offline backup not supported on web');
      }

      // Create local backup file
      final backupFile = await createBackup();

      // Create enhanced metadata
      final metadata = EnhancedBackupMetadata(
        version: '3.0',
        createdAt: DateTime.now(),
        transactionCount: 0, // Will be populated from actual data
        walletCount: 0, // Will be populated from actual data
        platform: await _getPlatformInfo(),
        deviceModel: await _getDeviceModel(),
        type: type,
        compressionInfo: const CompressionInfo(
          algorithm: 'gzip',
          ratio: 0.7,
          originalSize: 0,
          compressedSize: 0,
          compressionTime: Duration.zero,
        ),
        includedDataTypes: categories ?? DataCategory.values,
        performanceMetrics: const PerformanceMetrics(
          totalDuration: Duration.zero,
          compressionTime: Duration.zero,
          uploadTime: Duration.zero,
          validationTime: Duration.zero,
          networkRetries: 0,
          averageUploadSpeed: 0.0,
        ),
        validationInfo: ValidationInfo(
          checksum: '',
          result: ValidationResult.valid,
          validatedAt: DateTime.now(),
          errors: const [],
        ),
        originalSize: 0,
        compressedSize: 0,
        backupDuration: const Duration(seconds: 1),
        compressionAlgorithm: 'gzip',
        compressionRatio: 0.7,
      );

      // Add to offline queue
      final queueId = await _offlineQueue.addToQueue(
        backupFile: backupFile,
        metadata: metadata,
        priority: priority,
      );

      _updatePendingCount();
      isOfflineMode.value = true;

      debugPrint('Created offline backup: $queueId');
      return queueId;
    } catch (e) {
      debugPrint('Error creating offline backup: $e');
      return null;
    }
  }

  /// Sync all pending offline backups
  Future<bool> syncOfflineBackups() async {
    try {
      if (!await _networkMonitor.hasStableConnection()) {
        debugPrint('No stable connection for sync');
        return false;
      }

      await _offlineQueue.startAutoSync();
      _updatePendingCount();

      // Update offline mode status
      final pendingItems = _offlineQueue.getPendingItems();
      isOfflineMode.value = pendingItems.isNotEmpty;

      return true;
    } catch (e) {
      debugPrint('Error syncing offline backups: $e');
      return false;
    }
  }

  /// Get offline backup statistics
  OfflineBackupStats getOfflineStats() => _offlineQueue.currentStats;

  /// Get local storage statistics
  Future<LocalStorageStats> getStorageStats() =>
      _storageManager.getStorageStats();

  /// Get pending offline backup items
  List<OfflineBackupItem> getPendingOfflineBackups() =>
      _offlineQueue.getPendingItems();

  /// Remove offline backup from queue
  Future<bool> removeOfflineBackup(String id) async {
    final result = await _offlineQueue.removeFromQueue(id);
    if (result) {
      _updatePendingCount();
    }
    return result;
  }

  /// Perform storage cleanup
  Future<CleanupResult> performStorageCleanup() async {
    final queueItems = _offlineQueue.getQueueItems();
    return await _storageManager.performAutoCleanup(queueItems);
  }

  /// Configure offline backup settings
  Future<void> configureOfflineBackup(OfflineBackupConfig config) async {
    await _offlineQueue.updateConfig(config);
  }

  /// Get current offline backup configuration
  OfflineBackupConfig getOfflineConfig() => _offlineQueue.config;

  /// Check if device has enough storage for backup
  Future<bool> hasStorageForBackup(int estimatedSizeMB) async {
    return await _storageManager.hasSpaceForBackup(estimatedSizeMB);
  }

  /// Monitor network status and trigger sync when available
  Future<void> _monitorNetworkStatus() async {
    // Start monitoring network changes
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      final hasConnection = await _networkMonitor.hasStableConnection();

      if (hasConnection && isOfflineMode.value) {
        final pendingCount = _offlineQueue.getPendingItems().length;
        if (pendingCount > 0) {
          debugPrint(
            'Network available, attempting to sync $pendingCount offline backups',
          );
          await syncOfflineBackups();
        }
      }
    });
  }

  /// Update pending backup count
  void _updatePendingCount() {
    final pendingItems = _offlineQueue.getPendingItems();
    pendingOfflineBackups.value = pendingItems.length;

    // Update offline mode status
    isOfflineMode.value = pendingItems.isNotEmpty;
  }

  /// Override the original uploadToCloud to handle offline fallback
  @override
  Future<bool> uploadToCloud() async {
    try {
      // Check network first
      if (!await _networkMonitor.hasStableConnection()) {
        debugPrint('No network connection, creating offline backup instead');
        final offlineId = await _createOfflineBackup(
          BackupType.full,
          DataCategory.values,
          5, // High priority for manual backups
        );
        return offlineId != null;
      }

      // Try normal cloud upload
      final result = await super.uploadToCloud();

      if (!result) {
        // If cloud upload fails, create offline backup
        debugPrint('Cloud upload failed, creating offline backup as fallback');
        final offlineId = await _createOfflineBackup(
          BackupType.full,
          DataCategory.values,
          5,
        );
        return offlineId != null;
      }

      return result;
    } catch (e) {
      debugPrint('Error in enhanced uploadToCloud: $e');
      // Create offline backup as last resort
      final offlineId = await _createOfflineBackup(
        BackupType.full,
        DataCategory.values,
        5,
      );
      return offlineId != null;
    }
  }

  /// Get platform info (helper method)
  Future<String> _getPlatformInfo() async {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// Get device model (helper method)
  Future<String> _getDeviceModel() async {
    if (kIsWeb) return 'Web Browser';
    if (Platform.isAndroid) return 'Android Device';
    if (Platform.isIOS) return 'iOS Device';
    return 'unknown';
  }

  /// Dispose resources
  void dispose() {
    _offlineQueue.dispose();
    isOfflineMode.dispose();
    pendingOfflineBackups.dispose();
  }
}
