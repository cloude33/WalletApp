import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import '../models/backup_metadata.dart';
import 'data_service.dart';

/// Service for creating and restoring backups
class BackupService {
  final DataService _dataService = DataService();

  /// Create a complete backup of all data
  Future<File> createBackup() async {
    // Gather all data
    final transactions = await _dataService.getTransactions();
    final budgets = await _dataService.getBudgets();
    final wallets = await _dataService.getWallets();
    final recurringTransactions = await _dataService.getRecurringTransactions();
    final categories = await _dataService.getCategories();

    // Create metadata
    final metadata = BackupMetadata(
      version: '1.0',
      createdAt: DateTime.now(),
      transactionCount: transactions.length,
      budgetCount: budgets.length,
      walletCount: wallets.length,
    );

    // Create backup data structure
    final backupData = {
      'metadata': metadata.toJson(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'budgets': budgets.map((b) => b.toJson()).toList(),
      'wallets': wallets.map((w) => w.toJson()).toList(),
      'recurringTransactions':
          recurringTransactions.map((rt) => rt.toJson()).toList(),
      'categories': categories,
    };

    // Convert to JSON
    final jsonString = jsonEncode(backupData);
    final jsonBytes = utf8.encode(jsonString);

    // Compress using gzip
    final compressed = GZipEncoder().encode(jsonBytes);

    // Create filename with timestamp
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'money_backup_$timestamp.mbk';

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(directory.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final filePath = path.join(backupDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(compressed!);

    return file;
  }

  /// Restore data from backup file
  Future<void> restoreFromBackup(File backupFile) async {
    try {
      // Read and decompress file
      final compressed = await backupFile.readAsBytes();
      final decompressed = GZipDecoder().decodeBytes(compressed);
      final jsonString = utf8.decode(decompressed);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate backup structure
      if (!backupData.containsKey('metadata') ||
          !backupData.containsKey('transactions')) {
        throw Exception('Invalid backup file format');
      }

      // Parse metadata
      final metadata = BackupMetadata.fromJson(backupData['metadata']);

      // Restore data (this will replace existing data)
      await _dataService.restoreFromBackup(backupData);

      // Log successful restore
      print('Backup restored successfully: ${metadata.transactionCount} transactions');
    } catch (e) {
      print('Error restoring backup: $e');
      rethrow;
    }
  }

  /// Share backup file
  Future<bool> shareBackup() async {
    try {
      final backupFile = await createBackup();
      final result = await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: 'Money App Backup',
        text: 'Backup created on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      print('Error sharing backup: $e');
      return false;
    }
  }

  /// Get list of available backup files
  Future<List<File>> getBackupFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(directory.path, 'backups'));

    if (!await backupDir.exists()) {
      return [];
    }

    final files = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.mbk'))
        .toList();

    // Sort by modification time (newest first)
    files.sort((a, b) {
      final aStat = a.statSync();
      final bStat = b.statSync();
      return bStat.modified.compareTo(aStat.modified);
    });

    return files;
  }

  /// Cleanup old backups (keep only last 7)
  Future<void> cleanupOldBackups() async {
    final backups = await getBackupFiles();

    // Keep only the 7 most recent backups
    if (backups.length > 7) {
      final toDelete = backups.sublist(7);
      for (final file in toDelete) {
        await file.delete();
        print('Deleted old backup: ${path.basename(file.path)}');
      }
    }
  }

  /// Get backup metadata without restoring
  Future<BackupMetadata?> getBackupMetadata(File backupFile) async {
    try {
      final compressed = await backupFile.readAsBytes();
      final decompressed = GZipDecoder().decodeBytes(compressed);
      final jsonString = utf8.decode(decompressed);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      if (backupData.containsKey('metadata')) {
        return BackupMetadata.fromJson(backupData['metadata']);
      }
      return null;
    } catch (e) {
      print('Error reading backup metadata: $e');
      return null;
    }
  }

  /// Schedule automatic backup (placeholder for WorkManager integration)
  Future<void> scheduleAutomaticBackup(TimeOfDay time) async {
    // This would integrate with WorkManager for Android
    // and Background Fetch for iOS
    // For now, just log the intent
    print('Automatic backup scheduled for ${time.hour}:${time.minute}');
  }
}

/// Time of day for scheduling
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});
}
