import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart' show SharePlus, ShareResultStatus, ShareParams, XFile;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/backup_metadata.dart';
import 'data_service.dart';
import '../repositories/recurring_transaction_repository.dart';
import '../repositories/kmh_repository.dart';
import 'bill_template_service.dart';
import 'bill_payment_service.dart';
import 'firestore_service.dart';
import 'unified_auth_service.dart';

// Bulut yedekleme durumları
enum CloudBackupStatus { idle, uploading, downloading, syncing, error }

class BackupService {
  final DataService _dataService = DataService();
  final BillTemplateService _billTemplateService = BillTemplateService();
  final BillPaymentService _billPaymentService = BillPaymentService();
  final FirestoreService _firestoreService = FirestoreService();
  final UnifiedAuthService _unifiedAuth = UnifiedAuthService();

  ValueNotifier<CloudBackupStatus> cloudBackupStatus = ValueNotifier(
    CloudBackupStatus.idle,
  );
  ValueNotifier<String?> lastCloudBackupDate = ValueNotifier(null);
  ValueNotifier<bool> autoCloudBackupEnabled = ValueNotifier(false);

  Future<String> _getPlatformInfo() async {
    if (kIsWeb) {
      return 'web';
    }
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    }
    return 'unknown';
  }

  Future<String> _getDeviceModel() async {
    try {
      if (kIsWeb) {
        return 'Web Browser';
      }
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
      'recurringTransactions':
          recurringTransactions.map((rt) => rt.toJson()).toList(),
      'categories': categories,
      'kmhTransactions': kmhTransactions.map((kt) => kt.toJson()).toList(),
      'billTemplates': billTemplates.map((bt) => bt.toJson()).toList(),
      'billPayments': billPayments.map((bp) => bp.toJson()).toList(),
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
      debugPrint('Share is not fully supported on Web via SharePlus for MBK files');
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

  ValueNotifier<String?> lastError = ValueNotifier(null);

  // Bulut yedekleme fonksiyonları
  Future<bool> uploadToCloud() async {
    lastError.value = null;
    try {
      debugPrint('🔄 Bulut yedekleme başlatılıyor...');

      // Unified auth kontrolü
      if (!_unifiedAuth.currentState.canUseBackup ||
          _unifiedAuth.currentState.requiresLocalAuth) {
        lastError.value = 'Kullanıcı Firebase\'e giriş yapmamış veya yetkisiz';
        debugPrint('❌ Bulut yedekleme hatası: ${lastError.value}');
        debugPrint('   Auth durumu: ${_unifiedAuth.currentState.status}');
        debugPrint(
          '   Firebase kullanıcı: ${_unifiedAuth.currentFirebaseUser?.email}',
        );
        cloudBackupStatus.value = CloudBackupStatus.error;
        return false;
      }

      debugPrint(
        '✅ Firebase Auth OK: ${_unifiedAuth.currentFirebaseUser!.email}',
      );
      cloudBackupStatus.value = CloudBackupStatus.uploading;

      // Yedek oluştur
      debugPrint('📦 Yedek verisi hazırlanıyor...');
      final backupData = await createBackupRaw();

      debugPrint('📊 Yedek dosyası boyutu: ${backupData.length} bytes');

      debugPrint('🔄 Base64 encoding yapılıyor...');
      final base64Data = base64Encode(backupData);
      debugPrint('📊 Base64 boyutu: ${base64Data.length} characters');

      // Firestore 1MB limiti kontrolü
      if (base64Data.length > 1048000) {
        lastError.value =
            'Yedek dosyası çok büyük (${(base64Data.length / 1024 / 1024).toStringAsFixed(2)} MB). Firestore limiti 1 MB.';
        debugPrint('❌ Bulut yedekleme hatası: ${lastError.value}');
        cloudBackupStatus.value = CloudBackupStatus.error;
        return false;
      }

      // Metadata hazırla
      debugPrint('📋 Metadata hazırlanıyor...');
      final backupMap = await _gatherBackupData();
      final metadataJson = backupMap['metadata'];
      debugPrint('📋 Metadata: $metadataJson');

      // Firestore'a yükle
      debugPrint('☁️ Firestore\'a yükleniyor...');
      final docRef = await _firestoreService.addData(
        collectionName: 'backups',
        data: {
          'data': base64Data,
          'metadata': metadataJson,
          'deviceInfo': {
            'platform': await _getPlatformInfo(),
            'deviceModel': await _getDeviceModel(),
          },
          'size': backupData.length,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      if (docRef == null) {
        lastError.value = 'Veritabanına yazma işlemi başarısız oldu.';
        debugPrint('❌ Firestore\'a yedek yüklenemedi');
        throw Exception('Firestore\'a yedek yüklenemedi');
      }

      debugPrint('✅ Firestore\'a yükleme başarılı: ${docRef.id}');

      debugPrint('✅ Firestore\'a yükleme başarılı: ${docRef.id}');

      final now = DateTime.now();
      lastCloudBackupDate.value = DateFormat('dd/MM/yyyy HH:mm').format(now);
      cloudBackupStatus.value = CloudBackupStatus.idle;

      // SharedPreferences'a kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_cloud_backup_date',
        lastCloudBackupDate.value!,
      );

      debugPrint('🎉 Bulut yedekleme başarılı: ${backupData.length} bytes');
      return true;
    } catch (e, stackTrace) {
      lastError.value = 'Hata: ${e.toString()}';
      debugPrint('❌ Bulut yedekleme hatası: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      cloudBackupStatus.value = CloudBackupStatus.error;
      return false;
    }
  }

  Future<bool> downloadFromCloud() async {
    try {
      // Unified auth kontrolü
      if (!_unifiedAuth.currentState.canUseBackup ||
          _unifiedAuth.currentState.requiresLocalAuth) {
        debugPrint(
          '❌ Bulut geri yükleme hatası: Kullanıcı Firebase\'e giriş yapmamış',
        );
        debugPrint('   Auth durumu: ${_unifiedAuth.currentState.status}');
        cloudBackupStatus.value = CloudBackupStatus.error;
        return false;
      }

      cloudBackupStatus.value = CloudBackupStatus.downloading;
      debugPrint('🔄 Buluttan geri yükleme başlatılıyor...');

      // En son yedeği getir
      final backupsQuery = await _firestoreService.getData(
        collectionName: 'backups',
        includeDefaultOrder: false,
        queryBuilder: (query) =>
            query.orderBy('uploadedAt', descending: true).limit(1),
      );

      if (backupsQuery == null || backupsQuery.docs.isEmpty) {
        debugPrint('Bulut geri yükleme hatası: Bulutta yedek bulunamadı');
        cloudBackupStatus.value = CloudBackupStatus.error;
        return false;
      }

      final backupDoc = backupsQuery.docs.first;
      final backupData = backupDoc.data() as Map<String, dynamic>;

      if (!backupData.containsKey('data')) {
        debugPrint('Bulut geri yükleme hatası: Yedek verisi bulunamadı');
        cloudBackupStatus.value = CloudBackupStatus.error;
        return false;
      }

      final base64Data = backupData['data'] as String;
      final backupBytes = base64Decode(base64Data);

      // Metadata kontrol et
      final metadata = await getBackupMetadataFromBytes(backupBytes);
      if (metadata != null) {
        debugPrint('Geri yüklenen yedek bilgisi:');
        debugPrint('  - Platform: ${metadata.platform}');
        debugPrint('  - Versiyon: ${metadata.version}');
        debugPrint('  - İşlem sayısı: ${metadata.transactionCount}');
        debugPrint('  - Cüzdan sayısı: ${metadata.walletCount}');
        debugPrint('  - Tarih: ${metadata.createdAt}');

        if (!metadata.isCrossPlatformCompatible) {
          debugPrint(
            'Bulut geri yükleme uyarısı: Yedek versionu uyumlu olmayabilir',
          );
        }
      }

      // Geri yükle - Mobile için geçici dosya gerebilir ama _dataService.restoreFromBackup Map alıyorsa direkt kullanalım mı?
      // restoreFromBackup File bekliyor. Web'de bunu Map alan bir versiyona çevirmeliyiz ya da File yerine bytes almalı.

      if (kIsWeb) {
        final decompressed = GZipDecoder().decodeBytes(backupBytes);
        final jsonString = utf8.decode(decompressed);
        final backupMap = jsonDecode(jsonString) as Map<String, dynamic>;
        await _dataService.restoreFromBackup(backupMap);
      } else {
        // Geçici dosya oluştur (Mobile)
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
          path.join(
            tempDir.path,
            'cloud_backup_${DateTime.now().millisecondsSinceEpoch}.mbk',
          ),
        );
        await tempFile.writeAsBytes(backupBytes);
        await restoreFromBackup(tempFile);
        await tempFile.delete();
      }

      cloudBackupStatus.value = CloudBackupStatus.idle;
      debugPrint('Buluttan geri yükleme başarılı');
      return true;
    } catch (e) {
      debugPrint('Bulut geri yükleme hatası: $e');
      cloudBackupStatus.value = CloudBackupStatus.error;
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getCloudBackups() async {
    try {
      // Unified auth kontrolü
      if (!_unifiedAuth.currentState.canUseBackup ||
          _unifiedAuth.currentState.requiresLocalAuth) {
        debugPrint(
          '❌ Bulut yedekleri getirme hatası: Kullanıcı Firebase\'e giriş yapmamış',
        );
        return [];
      }

      final backupsQuery = await _firestoreService.getData(
        collectionName: 'backups',
        includeDefaultOrder: false,
        queryBuilder: (query) => query.orderBy('uploadedAt', descending: true),
      );

      if (backupsQuery == null) {
        debugPrint('Bulut yedekleri getirme hatası: Sorgu başarısız');
        return [];
      }

      final backups = backupsQuery.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'uploadedAt': data['uploadedAt'],
          'size': data['size'] ?? 0,
          'metadata': data['metadata'],
          'deviceInfo': data['deviceInfo'],
        };
      }).toList();

      debugPrint('Bulut yedekleri başarıyla getirildi: ${backups.length} adet');
      return backups;
    } catch (e) {
      debugPrint('Bulut yedekleri getirme hatası: $e');
      return [];
    }
  }

  Future<bool> deleteCloudBackup(String backupId) async {
    try {
      // Unified auth kontrolü
      if (!_unifiedAuth.currentState.canUseBackup ||
          _unifiedAuth.currentState.requiresLocalAuth) {
        debugPrint(
          '❌ Bulut yedek silme hatası: Kullanıcı Firebase\'e giriş yapmamış',
        );
        return false;
      }

      await _firestoreService.deleteData(
        collectionName: 'backups',
        documentId: backupId,
      );

      debugPrint('Bulut yedeği başarıyla silindi: $backupId');
      return true;
    } catch (e) {
      debugPrint('Bulut yedek silme hatası: $e');
      return false;
    }
  }

  Future<bool> syncWithCloud() async {
    try {
      // Unified auth kontrolü
      if (!_unifiedAuth.currentState.canUseBackup ||
          _unifiedAuth.currentState.requiresLocalAuth) {
        debugPrint(
          '❌ Bulut senkronizasyon hatası: Kullanıcı Firebase\'e giriş yapmamış',
        );
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
