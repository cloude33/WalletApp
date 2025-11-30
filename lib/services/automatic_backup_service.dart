import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'backup_service.dart';

/// Automatic backup service using WorkManager
class AutomaticBackupService {
  static final AutomaticBackupService _instance =
      AutomaticBackupService._internal();
  factory AutomaticBackupService() => _instance;
  AutomaticBackupService._internal();

  static const String _backupTaskName = 'automatic_backup';
  static const String _backupTaskTag = 'backup';
  final BackupService _backupService = BackupService();

  /// Initialize automatic backup
  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  /// Schedule automatic daily backup
  Future<void> scheduleAutomaticBackup({
    required TimeOfDay time,
  }) async {
    // Cancel existing task
    await Workmanager().cancelByUniqueName(_backupTaskName);

    // Calculate initial delay
    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If scheduled time has passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final initialDelay = scheduledTime.difference(now);

    // Schedule periodic task (daily)
    await Workmanager().registerPeriodicTask(
      _backupTaskName,
      _backupTaskTag,
      frequency: const Duration(days: 1),
      initialDelay: initialDelay,
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
    );
  }

  /// Cancel automatic backup
  Future<void> cancelAutomaticBackup() async {
    await Workmanager().cancelByUniqueName(_backupTaskName);
  }

  /// Perform backup and cleanup old backups
  Future<void> performBackup() async {
    try {
      // Create backup
      final backupFile = await _backupService.createBackup();
      
      if (backupFile != null) {
        debugPrint('Automatic backup created: ${backupFile.path}');
        
        // Cleanup old backups (keep last 7)
        await cleanupOldBackups(keepCount: 7);
      }
    } catch (e) {
      debugPrint('Automatic backup failed: $e');
      // TODO: Send notification about backup failure
    }
  }

  /// Cleanup old backup files
  Future<void> cleanupOldBackups({int keepCount = 7}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (!await backupDir.exists()) {
        return;
      }

      // Get all backup files
      final files = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.zip'))
          .cast<File>()
          .toList();

      // Sort by modification date (newest first)
      files.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

      // Delete old backups
      if (files.length > keepCount) {
        final filesToDelete = files.sublist(keepCount);
        for (var file in filesToDelete) {
          await file.delete();
          debugPrint('Deleted old backup: ${file.path}');
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old backups: $e');
    }
  }

  /// Get list of available backups
  Future<List<BackupInfo>> getAvailableBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (!await backupDir.exists()) {
        return [];
      }

      // Get all backup files
      final files = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.zip'))
          .cast<File>()
          .toList();

      // Create backup info list
      final backups = <BackupInfo>[];
      for (var file in files) {
        final stat = await file.stat();
        final fileName = file.path.split('/').last;
        
        backups.add(BackupInfo(
          fileName: fileName,
          filePath: file.path,
          size: stat.size,
          createdAt: stat.modified,
        ));
      }

      // Sort by date (newest first)
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return backups;
    } catch (e) {
      debugPrint('Error getting available backups: $e');
      return [];
    }
  }

  /// Delete specific backup file
  Future<void> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted backup: $filePath');
      }
    } catch (e) {
      debugPrint('Error deleting backup: $e');
      rethrow;
    }
  }
}

/// Backup information
class BackupInfo {
  final String fileName;
  final String filePath;
  final int size;
  final DateTime createdAt;

  BackupInfo({
    required this.fileName,
    required this.filePath,
    required this.size,
    required this.createdAt,
  });

  String get sizeFormatted {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == AutomaticBackupService._backupTaskTag) {
        final backupService = AutomaticBackupService();
        await backupService.performBackup();
        return Future.value(true);
      }
      return Future.value(false);
    } catch (e) {
      debugPrint('Background backup task error: $e');
      return Future.value(false);
    }
  });
}

/// TimeOfDay class for scheduling
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});
}
