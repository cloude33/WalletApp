import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/backup_metadata.dart';
import 'data_service.dart';
import '../repositories/recurring_transaction_repository.dart';
import '../repositories/kmh_repository.dart';
import 'bill_template_service.dart';
import 'bill_payment_service.dart';
class BackupService {
  final DataService _dataService = DataService();
  final BillTemplateService _billTemplateService = BillTemplateService();
  final BillPaymentService _billPaymentService = BillPaymentService();
  
  Future<String> _getPlatformInfo() async {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    }
    return 'unknown';
  }
  
  Future<String> _getDeviceModel() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name} (${iosInfo.model})';
      }
    } catch (e) {
      // Ignore errors
    }
    return 'unknown';
  }
  Future<File> createBackup() async {
    final transactions = await _dataService.getTransactions();
    final wallets = await _dataService.getWallets();
    final recurringRepo = RecurringTransactionRepository();
    await recurringRepo.init();
    final recurringTransactions = recurringRepo.getAll();

    final categories = await _dataService.getCategories();
    final kmhRepo = KmhRepository();
    final kmhTransactions = await kmhRepo.findAll();
    
    // Bill templates and payments
    final billTemplates = await _billTemplateService.getTemplates();
    final billPayments = await _billPaymentService.getPayments();
    
    final platform = await _getPlatformInfo();
    final deviceModel = await _getDeviceModel();
    
    final metadata = BackupMetadata(
      version: '2.0',
      createdAt: DateTime.now(),
      transactionCount: transactions.length,
      walletCount: wallets.length,
      platform: platform,
      deviceModel: deviceModel,
    );
    final backupData = {
      'metadata': metadata.toJson(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'wallets': wallets.map((w) => w.toJson()).toList(),
      'recurringTransactions': recurringTransactions
          .map((rt) => rt.toJson())
          .toList(),
      'categories': categories,
      'kmhTransactions': kmhTransactions.map((kt) => kt.toJson()).toList(),
      'billTemplates': billTemplates.map((bt) => bt.toJson()).toList(),
      'billPayments': billPayments.map((bp) => bp.toJson()).toList(),
    };
    final jsonString = jsonEncode(backupData);
    final jsonBytes = utf8.encode(jsonString);
    final compressed = GZipEncoder().encode(jsonBytes);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'money_backup_$timestamp.mbk';
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
  Future<void> restoreFromBackup(File backupFile) async {
    try {
      final compressed = await backupFile.readAsBytes();
      final decompressed = GZipDecoder().decodeBytes(compressed);
      final jsonString = utf8.decode(decompressed);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      if (!backupData.containsKey('metadata') ||
          !backupData.containsKey('transactions')) {
        throw Exception('Invalid backup file format');
      }
      
      // Platform kontrolü ve uyarı
      final metadata = BackupMetadata.fromJson(backupData['metadata']);
      final currentPlatform = await _getPlatformInfo();
      
      print('Restoring backup from ${metadata.platform} to $currentPlatform');
      print('Device: ${metadata.deviceModel}');
      print('Backup created: ${metadata.createdAt}');
      print('Cross-platform compatible: ${metadata.isCrossPlatformCompatible}');
      
      if (!metadata.isCrossPlatformCompatible) {
        throw Exception('Backup version ${metadata.version} is not compatible');
      }
      
      await _dataService.restoreFromBackup(backupData);
    } catch (e) {
      rethrow;
    }
  }
  Future<bool> shareBackup() async {
    try {
      final backupFile = await createBackup();
      final result = await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: 'Money App Backup',
        text:
            'Backup created on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      return false;
    }
  }
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
    files.sort((a, b) {
      final aStat = a.statSync();
      final bStat = b.statSync();
      return bStat.modified.compareTo(aStat.modified);
    });

    return files;
  }
  Future<void> cleanupOldBackups() async {
    final backups = await getBackupFiles();
    if (backups.length > 7) {
      final toDelete = backups.sublist(7);
      for (final file in toDelete) {
        await file.delete();
      }
    }
  }
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
      return null;
    }
  }
  Future<void> scheduleAutomaticBackup(TimeOfDay time) async {
    // TODO: Implement automatic backup scheduling
  }
}
