import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart'
    show SharePlus, ShareResultStatus, ShareParams, XFile;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/backup_metadata.dart';
import 'data_service.dart';
import '../repositories/recurring_transaction_repository.dart';
import '../repositories/kmh_repository.dart';
import 'bill_template_service.dart';
import 'bill_payment_service.dart';
import 'credit_card_service.dart';
import 'unified_auth_service.dart';
import 'google_drive_service.dart';

enum CloudBackupStatus { idle, uploading, downloading, syncing, error }

class BackupService {
  final DataService _dataService = DataService();
  final BillTemplateService _billTemplateService = BillTemplateService();
  final BillPaymentService _billPaymentService = BillPaymentService();
  final UnifiedAuthService _unifiedAuth = UnifiedAuthService();
  final GoogleDriveService _driveService = GoogleDriveService();

  ValueNotifier<CloudBackupStatus> cloudBackupStatus = ValueNotifier(
    CloudBackupStatus.idle,
  );
  ValueNotifier<String?> lastCloudBackupDate = ValueNotifier(null);
  ValueNotifier<bool> autoCloudBackupEnabled = ValueNotifier(false);
  ValueNotifier<String?> lastError = ValueNotifier(null);

  Future<String> _getPlatformInfo() async {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  Future<String> _getDeviceModel() async {
    if (kIsWeb) return 'Web Browser';
    if (Platform.isAndroid) return 'Android Device';
    if (Platform.isIOS) return 'iOS Device';
    return 'unknown';
  }

  Future<Map<String, dynamic>> _gatherBackupData() async {
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

    // Credit card data
    final creditCardService = CreditCardService();
    final creditCards = await creditCardService.getAllCards();
    final creditCardTransactions = <Map<String, dynamic>>[];
    final creditCardPayments = <Map<String, dynamic>>[];

    for (var card in creditCards) {
      final transactions = await creditCardService.getCardTransactions(card.id);
      creditCardTransactions.addAll(
        transactions.map((t) => t.toJson()).toList(),
      );

      final payments = await creditCardService.getCardPayments(card.id);
      creditCardPayments.addAll(payments.map((p) => p.toJson()).toList());
    }

    final goals = await _dataService.getGoals();

    final loans = await _dataService.getLoans();

    // Kullanıcı verileri
    final users = await _dataService.getAllUsers();
    final currentUser = await _dataService.getCurrentUser();

    final userImages = <String, String>{};
    if (!kIsWeb) {
      for (var user in users) {
        if (user.avatar != null &&
            user.avatar!.isNotEmpty &&
            !user.avatar!.startsWith('http') &&
            !user.avatar!.startsWith('assets')) {
          try {
            final file = File(user.avatar!);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              final base64Img = base64Encode(bytes);
              userImages[user.id] = base64Img;
            }
          } catch (e) {
            debugPrint('Avatar yedekleme hatası (${user.id}): $e');
          }
        }
      }
    }

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

    return {
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
      'creditCards': creditCards.map((cc) => cc.toJson()).toList(),
      'creditCardTransactions': creditCardTransactions,
      'creditCardPayments': creditCardPayments,
      'goals': goals.map((g) => g.toJson()).toList(),
      'loans': loans.map((l) => l.toJson()).toList(),
      'users': users.map((u) => u.toJson()).toList(),
      'currentUser': currentUser?.toJson(),
      'userImages': userImages,
    };
  }

  Future<List<int>> createBackupRaw() async {
    final backupData = await _gatherBackupData();
    final jsonString = jsonEncode(backupData);
    final jsonBytes = utf8.encode(jsonString);
    final compressed = GZipEncoder().encode(jsonBytes);
    return compressed!;
  }

  Future<File> createBackup() async {
    if (kIsWeb) {
      throw UnsupportedError('createBackup (File) is not supported on Web');
    }

    final compressed = await createBackupRaw();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'money_backup_$timestamp.mbk';

    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(directory.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final filePath = path.join(backupDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(compressed);

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
    if (kIsWeb) {
      debugPrint(
        'Share is not fully supported on Web via SharePlus for MBK files',
      );
      return false;
    }
    try {
      final backupFile = await createBackup();
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(backupFile.path)],
          subject: 'Parion Backup',
          text:
              'Backup created on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
        ),
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      return false;
    }
  }

  Future<List<File>> getBackupFiles() async {
    if (kIsWeb) return [];

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
    if (kIsWeb) return null;
    try {
      final compressed = await backupFile.readAsBytes();
      return await getBackupMetadataFromBytes(compressed);
    } catch (e) {
      return null;
    }
  }

  Future<BackupMetadata?> getBackupMetadataFromBytes(List<int> bytes) async {
    try {
      final decompressed = GZipDecoder().decodeBytes(bytes);
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

  // Bulut yedekleme fonksiyonları - DRIVE Implementation
  Future<bool> uploadToCloud() async {
    lastError.value = null;
    try {
      debugPrint('🔄 Google Drive yedekleme başlatılıyor...');

      // Auth Check
      if (!await _driveService.isAuthenticated()) {
        await _driveService.signIn();
      }

      cloudBackupStatus.value = CloudBackupStatus.uploading;

      // 1. Dosyayı Oluştur (Create Local File)
      debugPrint('📦 Yedek verisi ve dosyası hazırlanıyor...');
      File? backupFile;
      if (kIsWeb) {
        throw UnsupportedError(
          'Web upload not fully implemented for direct file IO in this method yet.',
        );
      } else {
        backupFile = await createBackup();
      }

      // 2. Drive'a Yükle
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'money_backup_$timestamp.mbk';

      debugPrint('☁️ Google Drive\'a yükleniyor...');

      final result = await _driveService.uploadBackup(
        backupFile,
        fileName,
        description: 'Parion Backup Version 2.0 via Google Drive',
      );

      if (result == null) {
        throw Exception('Google Drive upload failed');
      }

      debugPrint('✅ Google Drive yükleme başarılı: ${result.id}');

      final now = DateTime.now();
      lastCloudBackupDate.value = DateFormat('dd/MM/yyyy HH:mm').format(now);
      cloudBackupStatus.value = CloudBackupStatus.idle;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_cloud_backup_date',
        lastCloudBackupDate.value!,
      );

      return true;
    } catch (e, stackTrace) {
      lastError.value = 'Hata: ${e.toString()}';
      debugPrint('❌ Bulut yedekleme hatası: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      cloudBackupStatus.value = CloudBackupStatus.error;
      return false;
    }
  }

  Future<bool> downloadFromCloud([String? backupId]) async {
    try {
      debugPrint('🔄 Google Drive geri yükleme başlatılıyor...');
      cloudBackupStatus.value = CloudBackupStatus.downloading;

      // Auth Check
      if (!await _driveService.isAuthenticated()) {
        await _driveService.signIn();
      }

      String? fileId = backupId;
      String? fileName;

      // Eğer ID verilmediyse en son yedeği bul
      if (fileId == null) {
        final backups = await _driveService.listBackups();
        if (backups.isEmpty) {
          debugPrint('❌ Hiç yedek bulunamadı.');
          cloudBackupStatus.value = CloudBackupStatus.error;
          return false;
        }
        fileId = backups.first.id;
        fileName = backups.first.name;
      }

      if (fileId == null) return false;

      debugPrint('📥 İndiriliyor: $fileId');

      final tempDir = await getTemporaryDirectory();
      final tempPath = path.join(
        tempDir.path,
        fileName ?? 'restored_backup.mbk',
      );

      final downloadedFile = await _driveService.downloadBackup(
        fileId,
        tempPath,
      );

      if (downloadedFile == null) {
        throw Exception('Dosya indirilemedi');
      }

      await restoreFromBackup(downloadedFile);

      await downloadedFile.delete(); // Cleanup

      cloudBackupStatus.value = CloudBackupStatus.idle;
      debugPrint('✅ Geri yükleme başarılı');
      return true;
    } catch (e) {
      debugPrint('❌ Bulut geri yükleme hatası: $e');
      cloudBackupStatus.value = CloudBackupStatus.error;
      return false;
    }
  }

  // Listeleme (Firestore yerine Drive'dan)
  Future<List<Map<String, dynamic>>> getCloudBackups() async {
    try {
      if (!await _driveService.isAuthenticated()) {
        return [];
      }

      final files = await _driveService.listBackups();

      return files
          .map(
            (f) => {
              'id': f.id,
              'uploadedAt':
                  f.createdTime?.toIso8601String() ??
                  DateTime.now().toIso8601String(),
              'size': int.tryParse(f.size ?? '0') ?? 0,
              'metadata': {
                'deviceModel': 'Drive Backup',
                'platform': 'Unknown',
              },
              'fileName': f.name,
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Yedek listeleme hatası: $e');
      return [];
    }
  }

  Future<bool> deleteCloudBackup(String backupId) async {
    try {
      await _driveService.deleteBackup(backupId);
      return true;
    } catch (e) {
      debugPrint('Bulut yedek silme hatası: $e');
      return false;
    }
  }

  Future<bool> syncWithCloud() async {
    try {
      // Unified auth kontrolü for Backup is less strict than FireStore,
      // but we still want to ensure we have auth.
      // For Drive Sync, we just upload if enabled.

      if (autoCloudBackupEnabled.value) {
        return await uploadToCloud();
      }
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
    autoCloudBackupEnabled.value =
        prefs.getBool('auto_cloud_backup_enabled') ?? false;
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
