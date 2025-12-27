import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/backup_metadata.dart';
import 'data_service.dart';
import '../repositories/recurring_transaction_repository.dart';
import '../repositories/kmh_repository.dart';
import 'bill_template_service.dart';
import 'bill_payment_service.dart';
import 'firestore_service.dart';

// Bulut yedekleme durumları
enum CloudBackupStatus { idle, uploading, downloading, syncing, error }

class BackupService {
  final DataService _dataService = DataService();
  final BillTemplateService _billTemplateService = BillTemplateService();
  final BillPaymentService _billPaymentService = BillPaymentService();
  final FirestoreService _firestoreService = FirestoreService();
  
  ValueNotifier<CloudBackupStatus> cloudBackupStatus = ValueNotifier(CloudBackupStatus.idle);
  ValueNotifier<String?> lastCloudBackupDate = ValueNotifier(null);
  ValueNotifier<bool> autoCloudBackupEnabled = ValueNotifier(false);

  Future<String> _getPlatformInfo() async {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    }
    return 'unknown';
  }

  Future<String> _getDeviceModel() async {
    try {
      if (Platform.isAndroid) {
        return 'Android Device';
      } else if (Platform.isIOS) {
        return 'iOS Device';
      }
    } catch (e) {
      // Device info alınamadığında varsayılan değer döndür
      debugPrint('Device info error: $e');
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
        subject: 'Parion Backup',
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

  // Bulut yedekleme fonksiyonları
  Future<bool> uploadToCloud() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      cloudBackupStatus.value = CloudBackupStatus.uploading;

      // Yedek oluştur
      final backupFile = await createBackup();
      final backupData = await backupFile.readAsBytes();
      final base64Data = base64Encode(backupData);

      // Metadata hazırla
      final metadata = await getBackupMetadata(backupFile);
      
      // Firestore'a yükle
      await _firestoreService.addData(
        collectionName: 'backups',
        data: {
          'data': base64Data,
          'metadata': metadata?.toJson(),
          'deviceInfo': {
            'platform': await _getPlatformInfo(),
            'deviceModel': await _getDeviceModel(),
          },
          'size': backupData.length,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Yerel dosyayı temizle
      await backupFile.delete();

      lastCloudBackupDate.value = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      cloudBackupStatus.value = CloudBackupStatus.idle;

      // SharedPreferences'a kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_cloud_backup_date', lastCloudBackupDate.value!);

      return true;
    } catch (e) {
      debugPrint('Bulut yedekleme hatası: $e');
      cloudBackupStatus.value = CloudBackupStatus.error;
      return false;
    }
  }

  Future<bool> downloadFromCloud() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      cloudBackupStatus.value = CloudBackupStatus.downloading;

      // En son yedeği getir
      final backupsQuery = await _firestoreService.getData(
        collectionName: 'backups',
        queryBuilder: (query) => query.orderBy('uploadedAt', descending: true).limit(1),
      );

      if (backupsQuery == null || backupsQuery.docs.isEmpty) {
        throw Exception('Bulutta yedek bulunamadı');
      }

      final backupDoc = backupsQuery.docs.first;
      final backupData = backupDoc.data() as Map<String, dynamic>;
      final base64Data = backupData['data'] as String;
      final backupBytes = base64Decode(base64Data);

      // Geçici dosya oluştur
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(tempDir.path, 'cloud_backup.mbk'));
      await tempFile.writeAsBytes(backupBytes);

      // Geri yükle
      await restoreFromBackup(tempFile);

      // Geçici dosyayı temizle
      await tempFile.delete();

      cloudBackupStatus.value = CloudBackupStatus.idle;
      return true;
    } catch (e) {
      debugPrint('Bulut geri yükleme hatası: $e');
      cloudBackupStatus.value = CloudBackupStatus.error;
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getCloudBackups() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        return [];
      }

      final backupsQuery = await _firestoreService.getData(
        collectionName: 'backups',
        queryBuilder: (query) => query.orderBy('uploadedAt', descending: true),
      );

      if (backupsQuery == null) return [];

      return backupsQuery.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'uploadedAt': data['uploadedAt'],
          'size': data['size'],
          'metadata': data['metadata'],
          'deviceInfo': data['deviceInfo'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Bulut yedekleri getirme hatası: $e');
      return [];
    }
  }

  Future<bool> deleteCloudBackup(String backupId) async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        return false;
      }

      await _firestoreService.deleteData(
        collectionName: 'backups',
        documentId: backupId,
      );

      return true;
    } catch (e) {
      debugPrint('Bulut yedek silme hatası: $e');
      return false;
    }
  }

  Future<bool> syncWithCloud() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        return false;
      }

      cloudBackupStatus.value = CloudBackupStatus.syncing;

      // Otomatik yedekleme etkinse yedek al
      if (autoCloudBackupEnabled.value) {
        await uploadToCloud();
      }

      cloudBackupStatus.value = CloudBackupStatus.idle;
      return true;
    } catch (e) {
      debugPrint('Bulut senkronizasyon hatası: $e');
      cloudBackupStatus.value = CloudBackupStatus.error;
      return false;
    }
  }

  Future<void> enableAutoCloudBackup(bool enabled) async {
    autoCloudBackupEnabled.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_cloud_backup_enabled', enabled);
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    autoCloudBackupEnabled.value = prefs.getBool('auto_cloud_backup_enabled') ?? false;
    lastCloudBackupDate.value = prefs.getString('last_cloud_backup_date');
  }

  String getCloudBackupStatusText() {
    switch (cloudBackupStatus.value) {
      case CloudBackupStatus.uploading:
        return 'Buluta yükleniyor...';
      case CloudBackupStatus.downloading:
        return 'Buluttan indiriliyor...';
      case CloudBackupStatus.syncing:
        return 'Senkronize ediliyor...';
      case CloudBackupStatus.error:
        return 'Hata oluştu';
      case CloudBackupStatus.idle:
        return 'Hazır';
    }
  }
}
