import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../models/backup_optimization/backup_enums.dart';
import '../../models/backup_optimization/offline_backup_models.dart';

/// Manages local storage for offline backups with priority-based cleanup
class LocalStorageManager {
  static const String _storageInfoFileName = 'storage_info.json';
  static const int _defaultMaxStorageMB = 500;
  static const double _cleanupThreshold = 0.8; // 80% of max storage

  int _maxStorageMB = _defaultMaxStorageMB;
  final Map<DataCategory, int> _categoryPriorities = {
    DataCategory.transactions: 10,
    DataCategory.wallets: 9,
    DataCategory.creditCards: 8,
    DataCategory.bills: 7,
    DataCategory.goals: 6,
    DataCategory.settings: 5,
    DataCategory.recurringTransactions: 4,
    DataCategory.userImages: 3,
  };

  /// Initialize the storage manager
  Future<void> initialize({int? maxStorageMB}) async {
    await _loadStorageInfo();
    if (maxStorageMB != null) {
      _maxStorageMB = maxStorageMB;
    }
  }

  /// Check if there's enough space for a new backup
  Future<bool> hasSpaceForBackup(int backupSizeMB) async {
    final currentUsage = await getCurrentStorageUsageMB();
    return (currentUsage + backupSizeMB) <= _maxStorageMB;
  }

  /// Get current storage usage in MB
  Future<int> getCurrentStorageUsageMB() async {
    if (kIsWeb) return 0;

    try {
      final backupDir = await _getBackupDirectory();
      if (!await backupDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in backupDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }

      return (totalSize / (1024 * 1024)).ceil();
    } catch (e) {
      debugPrint('Error calculating storage usage: $e');
      return 0;
    }
  }

  /// Get available storage space in MB
  Future<int> getAvailableStorageMB() async {
    final currentUsage = await getCurrentStorageUsageMB();
    return _maxStorageMB - currentUsage;
  }

  /// Check if storage is near capacity
  Future<bool> isNearCapacity() async {
    final currentUsage = await getCurrentStorageUsageMB();
    return currentUsage >= (_maxStorageMB * _cleanupThreshold);
  }

  /// Free up storage space by removing low-priority backups
  Future<int> freeUpSpace(
    int requiredMB,
    List<OfflineBackupItem> availableItems,
  ) async {
    if (kIsWeb) return 0;

    int freedMB = 0;
    final sortedItems = _sortItemsByPriority(availableItems);

    for (final item in sortedItems) {
      if (freedMB >= requiredMB) break;

      try {
        final file = File(item.localPath);
        if (await file.exists()) {
          final sizeMB = await _getFileSizeMB(file);
          await file.delete();
          freedMB += sizeMB;

          debugPrint('Deleted low-priority backup: ${item.id} (${sizeMB}MB)');
        }
      } catch (e) {
        debugPrint('Error deleting backup file ${item.id}: $e');
      }
    }

    return freedMB;
  }

  /// Clean up temporary files
  Future<void> cleanupTemporaryFiles() async {
    if (kIsWeb) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final backupTempDir = Directory(path.join(tempDir.path, 'backup_temp'));

      if (await backupTempDir.exists()) {
        await for (final entity in backupTempDir.list()) {
          if (entity is File) {
            final stat = await entity.stat();
            final age = DateTime.now().difference(stat.modified);

            // Delete files older than 24 hours
            if (age.inHours > 24) {
              await entity.delete();
              debugPrint('Deleted old temp file: ${entity.path}');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up temporary files: $e');
    }
  }

  /// Get storage statistics
  Future<LocalStorageStats> getStorageStats() async {
    final currentUsageMB = await getCurrentStorageUsageMB();
    final availableMB = await getAvailableStorageMB();
    final isNearLimit = await isNearCapacity();

    return LocalStorageStats(
      maxStorageMB: _maxStorageMB,
      currentUsageMB: currentUsageMB,
      availableMB: availableMB,
      usagePercentage: (currentUsageMB / _maxStorageMB) * 100,
      isNearCapacity: isNearLimit,
    );
  }

  /// Set maximum storage limit
  Future<void> setMaxStorageLimit(int maxMB) async {
    _maxStorageMB = maxMB;
    await _saveStorageInfo();
  }

  /// Get files that can be safely deleted (completed backups, old temp files)
  Future<List<DeletableFile>> getDeletableFiles(
    List<OfflineBackupItem> queueItems,
  ) async {
    if (kIsWeb) return [];

    final deletableFiles = <DeletableFile>[];

    try {
      // Find completed backup files
      final completedItems = queueItems
          .where((item) => item.status == OfflineBackupStatus.completed)
          .toList();

      for (final item in completedItems) {
        final file = File(item.localPath);
        if (await file.exists()) {
          final sizeMB = await _getFileSizeMB(file);
          deletableFiles.add(
            DeletableFile(
              path: item.localPath,
              sizeMB: sizeMB,
              type: DeletableFileType.completedBackup,
              lastModified: item.createdAt,
              priority: _calculateItemPriority(item),
            ),
          );
        }
      }

      // Find old temporary files
      final tempDir = await getTemporaryDirectory();
      final backupTempDir = Directory(path.join(tempDir.path, 'backup_temp'));

      if (await backupTempDir.exists()) {
        await for (final entity in backupTempDir.list()) {
          if (entity is File) {
            final stat = await entity.stat();
            final age = DateTime.now().difference(stat.modified);

            if (age.inHours > 1) {
              // Files older than 1 hour
              final sizeMB = await _getFileSizeMB(entity);
              deletableFiles.add(
                DeletableFile(
                  path: entity.path,
                  sizeMB: sizeMB,
                  type: DeletableFileType.temporaryFile,
                  lastModified: stat.modified,
                  priority: age
                      .inHours, // Older files have higher priority for deletion
                ),
              );
            }
          }
        }
      }

      // Sort by deletion priority (higher priority = delete first)
      deletableFiles.sort((a, b) => b.priority.compareTo(a.priority));
    } catch (e) {
      debugPrint('Error finding deletable files: $e');
    }

    return deletableFiles;
  }

  /// Delete specific files
  Future<int> deleteFiles(List<String> filePaths) async {
    int deletedSizeMB = 0;

    for (final filePath in filePaths) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          final sizeMB = await _getFileSizeMB(file);
          await file.delete();
          deletedSizeMB += sizeMB;
          debugPrint('Deleted file: $filePath (${sizeMB}MB)');
        }
      } catch (e) {
        debugPrint('Error deleting file $filePath: $e');
      }
    }

    return deletedSizeMB;
  }

  /// Perform automatic cleanup based on storage pressure
  Future<CleanupResult> performAutoCleanup(
    List<OfflineBackupItem> queueItems,
  ) async {
    final stats = await getStorageStats();

    if (!stats.isNearCapacity) {
      return CleanupResult(
        deletedFiles: 0,
        freedSpaceMB: 0,
        reason:
            'No cleanup needed - storage usage is ${stats.usagePercentage.toStringAsFixed(1)}%',
      );
    }

    int deletedFiles = 0;
    int freedSpaceMB = 0;
    final reasons = <String>[];

    // Step 1: Clean up temporary files
    await cleanupTemporaryFiles();
    reasons.add('Cleaned temporary files');

    // Step 2: Delete completed backups if still over threshold
    final currentUsage = await getCurrentStorageUsageMB();
    if (currentUsage >= (_maxStorageMB * _cleanupThreshold)) {
      final deletableFiles = await getDeletableFiles(queueItems);
      final completedBackups = deletableFiles
          .where((f) => f.type == DeletableFileType.completedBackup)
          .toList();

      // Delete up to 50% of completed backups
      final toDelete = completedBackups
          .take((completedBackups.length * 0.5).ceil())
          .toList();

      for (final file in toDelete) {
        try {
          await File(file.path).delete();
          deletedFiles++;
          freedSpaceMB += file.sizeMB;
        } catch (e) {
          debugPrint('Error deleting completed backup: $e');
        }
      }

      if (toDelete.isNotEmpty) {
        reasons.add('Deleted ${toDelete.length} completed backups');
      }
    }

    return CleanupResult(
      deletedFiles: deletedFiles,
      freedSpaceMB: freedSpaceMB,
      reason: reasons.join(', '),
    );
  }

  /// Sort items by priority (lowest priority first for deletion)
  List<OfflineBackupItem> _sortItemsByPriority(List<OfflineBackupItem> items) {
    final sortedItems = List<OfflineBackupItem>.from(items);

    sortedItems.sort((a, b) {
      // First by status (completed items can be deleted first)
      if (a.status != b.status) {
        if (a.status == OfflineBackupStatus.completed) return -1;
        if (b.status == OfflineBackupStatus.completed) return 1;
      }

      // Then by data category priority
      final aPriority = _calculateItemPriority(a);
      final bPriority = _calculateItemPriority(b);
      final priorityCompare = aPriority.compareTo(bPriority);
      if (priorityCompare != 0) return priorityCompare;

      // Finally by age (older first)
      return a.createdAt.compareTo(b.createdAt);
    });

    return sortedItems;
  }

  /// Calculate priority score for an item (lower = delete first)
  int _calculateItemPriority(OfflineBackupItem item) {
    int priority = item.priority;

    // Add category-based priority
    for (final category in item.metadata.includedDataTypes) {
      priority += _categoryPriorities[category] ?? 1;
    }

    // Boost priority for failed items (they can be deleted more easily)
    if (item.status == OfflineBackupStatus.failed) {
      priority -= 5;
    }

    return priority;
  }

  /// Get file size in MB
  Future<int> _getFileSizeMB(FileSystemEntity file) async {
    try {
      final stat = await file.stat();
      return (stat.size / (1024 * 1024)).ceil();
    } catch (e) {
      return 1; // Default assumption
    }
  }

  /// Get backup directory
  Future<Directory> _getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(path.join(appDir.path, 'offline_backup_queue'));
  }

  /// Load storage configuration
  Future<void> _loadStorageInfo() async {
    try {
      if (kIsWeb) return;

      final backupDir = await _getBackupDirectory();
      final infoFile = File(path.join(backupDir.path, _storageInfoFileName));

      if (await infoFile.exists()) {
        final jsonString = await infoFile.readAsString();
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        _maxStorageMB = jsonData['maxStorageMB'] ?? _defaultMaxStorageMB;
      }
    } catch (e) {
      debugPrint('Error loading storage info: $e');
    }
  }

  /// Save storage configuration
  Future<void> _saveStorageInfo() async {
    try {
      if (kIsWeb) return;

      final backupDir = await _getBackupDirectory();
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final infoFile = File(path.join(backupDir.path, _storageInfoFileName));
      final jsonData = {'maxStorageMB': _maxStorageMB};

      await infoFile.writeAsString(jsonEncode(jsonData));
    } catch (e) {
      debugPrint('Error saving storage info: $e');
    }
  }
}

/// Statistics about local storage usage
class LocalStorageStats {
  final int maxStorageMB;
  final int currentUsageMB;
  final int availableMB;
  final double usagePercentage;
  final bool isNearCapacity;

  const LocalStorageStats({
    required this.maxStorageMB,
    required this.currentUsageMB,
    required this.availableMB,
    required this.usagePercentage,
    required this.isNearCapacity,
  });

  Map<String, dynamic> toJson() => {
    'maxStorageMB': maxStorageMB,
    'currentUsageMB': currentUsageMB,
    'availableMB': availableMB,
    'usagePercentage': usagePercentage,
    'isNearCapacity': isNearCapacity,
  };
}

/// Represents a file that can be safely deleted
class DeletableFile {
  final String path;
  final int sizeMB;
  final DeletableFileType type;
  final DateTime lastModified;
  final int priority; // Higher = delete first

  const DeletableFile({
    required this.path,
    required this.sizeMB,
    required this.type,
    required this.lastModified,
    required this.priority,
  });
}

/// Types of deletable files
enum DeletableFileType { completedBackup, temporaryFile, failedBackup }

/// Result of cleanup operation
class CleanupResult {
  final int deletedFiles;
  final int freedSpaceMB;
  final String reason;

  const CleanupResult({
    required this.deletedFiles,
    required this.freedSpaceMB,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
    'deletedFiles': deletedFiles,
    'freedSpaceMB': freedSpaceMB,
    'reason': reason,
  };
}

extension DeletableFileTypeExtension on DeletableFileType {
  String get displayName {
    switch (this) {
      case DeletableFileType.completedBackup:
        return 'Tamamlanmış Yedek';
      case DeletableFileType.temporaryFile:
        return 'Geçici Dosya';
      case DeletableFileType.failedBackup:
        return 'Başarısız Yedek';
    }
  }
}
