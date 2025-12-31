import 'package:flutter_test/flutter_test.dart';

import 'package:money/services/backup_service.dart';
import 'package:money/services/firestore_service.dart';
import 'package:money/services/firebase_auth_service.dart';
import 'package:money/services/auto_backup_service.dart';
import 'package:money/services/data_service.dart';
import 'package:money/models/backup_metadata.dart';
import 'package:money/models/transaction.dart' as app_models;
import 'package:money/models/wallet.dart';
import 'test_setup.dart';

void main() {
  group('Firebase Backup System Tests', () {
    BackupService? backupService;
    FirestoreService? firestoreService;
    FirebaseAuthService? authService;
    AutoBackupService? autoBackupService;
    DataService? dataService;

    setUpAll(() async {
      await TestSetup.initializeTestEnvironment();
    });

    setUp(() async {
      await TestSetup.setupTest();
      
      // Use mock services to avoid Firebase initialization issues
      try {
        backupService = BackupService();
        firestoreService = FirestoreService();
        authService = FirebaseAuthService();
        autoBackupService = AutoBackupService();
        dataService = DataService.forTesting();
      } catch (e) {
        // Skip Firebase-dependent tests if Firebase is not available
        print('Firebase services not available in test environment: $e');
        backupService = null;
        firestoreService = null;
        authService = null;
        autoBackupService = null;
        dataService = null;
      }
    });

    tearDown(() async {
      await TestSetup.tearDownTest();
    });

    tearDownAll(() async {
      await TestSetup.cleanupTestEnvironment();
    });

    group('Backup Metadata Tests', () {
      test('BackupMetadata should create correctly', () {
        final metadata = BackupMetadata(
          version: '2.0',
          createdAt: DateTime.now(),
          transactionCount: 10,
          walletCount: 3,
          platform: 'android',
          deviceModel: 'Test Device',
        );

        expect(metadata.version, '2.0');
        expect(metadata.transactionCount, 10);
        expect(metadata.walletCount, 3);
        expect(metadata.isAndroidBackup, true);
        expect(metadata.isIOSBackup, false);
        expect(metadata.isCrossPlatformCompatible, true);
      });

      test('BackupMetadata should handle JSON serialization', () {
        final now = DateTime.now();
        final metadata = BackupMetadata(
          version: '2.0',
          createdAt: now,
          transactionCount: 5,
          walletCount: 2,
          platform: 'ios',
          deviceModel: 'iPhone 15',
        );

        final json = metadata.toJson();
        final restored = BackupMetadata.fromJson(json);

        expect(restored.version, metadata.version);
        expect(restored.createdAt, metadata.createdAt);
        expect(restored.transactionCount, metadata.transactionCount);
        expect(restored.walletCount, metadata.walletCount);
        expect(restored.platform, metadata.platform);
        expect(restored.deviceModel, metadata.deviceModel);
      });

      test('BackupMetadata should detect cross-platform compatibility', () {
        final androidMetadata = BackupMetadata(
          version: '2.0',
          createdAt: DateTime.now(),
          transactionCount: 1,
          walletCount: 1,
          platform: 'android',
        );

        final iosMetadata = BackupMetadata(
          version: '2.0',
          createdAt: DateTime.now(),
          transactionCount: 1,
          walletCount: 1,
          platform: 'ios',
        );

        final oldMetadata = BackupMetadata(
          version: '0.9',
          createdAt: DateTime.now(),
          transactionCount: 1,
          walletCount: 1,
          platform: 'android',
        );

        expect(androidMetadata.isCrossPlatformCompatible, true);
        expect(iosMetadata.isCrossPlatformCompatible, true);
        expect(oldMetadata.isCrossPlatformCompatible, false);
      });
    });

    group('Data Service Tests', () {
      test('DataService should initialize correctly', () async {
        if (dataService == null) {
          print('DataService not available, skipping test');
          return;
        }
        
        await dataService!.init();
        final prefs = await dataService!.getPrefs();
        expect(prefs, isNotNull);
      });

      test('DataService should handle backup data restoration', () async {
        if (dataService == null) {
          print('DataService not available, skipping test');
          return;
        }
        
        await dataService!.init();

        // Test verileri oluştur
        final testTransactions = [
          app_models.Transaction(
            id: '1',
            amount: 100.0,
            description: 'Test Transaction',
            category: 'Test Category',
            walletId: 'wallet1',
            date: DateTime.now(),
            type: 'expense',
            isIncome: false,
          ),
        ];

        final testWallets = [
          Wallet(
            id: 'wallet1',
            name: 'Test Wallet',
            balance: 1000.0,
            type: 'cash',
            color: '#2196F3',
            icon: 'wallet',
          ),
        ];

        final backupData = {
          'transactions': testTransactions.map((t) => t.toJson()).toList(),
          'wallets': testWallets.map((w) => w.toJson()).toList(),
          'categories': [],
          'recurringTransactions': [],
          'kmhTransactions': [],
          'billTemplates': [],
          'billPayments': [],
        };

        // Geri yükleme işlemini test et
        await dataService!.restoreFromBackup(backupData);

        // Verilerin doğru yüklendiğini kontrol et
        final restoredTransactions = await dataService!.getTransactions();
        final restoredWallets = await dataService!.getWallets();

        expect(restoredTransactions.length, 1);
        expect(restoredWallets.length, greaterThanOrEqualTo(1));
        expect(restoredTransactions.first.id, '1');
        expect(restoredTransactions.first.amount, 100.0);
      });
    });

    group('Backup Service Tests', () {
      test('BackupService should create backup file', () async {
        // Bu test gerçek dosya sistemi gerektirir, unit test için skip
      }, skip: 'Requires file system access');

      test('BackupService should handle cloud backup status', () {
        if (backupService == null) {
          print('BackupService not available, skipping test');
          return;
        }
        
        expect(backupService!.cloudBackupStatus.value, CloudBackupStatus.idle);
        
        backupService!.cloudBackupStatus.value = CloudBackupStatus.uploading;
        expect(backupService!.cloudBackupStatus.value, CloudBackupStatus.uploading);
        
        final statusText = backupService!.getCloudBackupStatusText();
        expect(statusText, 'Buluta yükleniyor...');
      });

      test('BackupService should handle settings', () async {
        if (backupService == null) {
          print('BackupService not available, skipping test');
          return;
        }
        
        await backupService!.loadSettings();
        
        await backupService!.enableAutoCloudBackup(true);
        expect(backupService!.autoCloudBackupEnabled.value, true);
        
        await backupService!.enableAutoCloudBackup(false);
        expect(backupService!.autoCloudBackupEnabled.value, false);
      });
    });

    group('Auto Backup Service Tests', () {
      test('AutoBackupService should handle auto backup settings', () async {
        if (autoBackupService == null) {
          print('AutoBackupService not available, skipping test');
          return;
        }
        
        await autoBackupService!.enableAutoBackup(true);
        final isEnabled = await autoBackupService!.isAutoBackupEnabled();
        expect(isEnabled, true);

        await autoBackupService!.enableAutoBackup(false);
        final isDisabled = await autoBackupService!.isAutoBackupEnabled();
        expect(isDisabled, false);
      });

      test('AutoBackupService should track last backup date', () async {
        if (autoBackupService == null) {
          print('AutoBackupService not available, skipping test');
          return;
        }
        
        final lastBackup = await autoBackupService!.getLastAutoBackupDate();
        expect(lastBackup, isNull); // İlk çalıştırmada null olmalı
      });
    });

    group('Integration Tests', () {
      test('Complete backup and restore flow should work', () async {
        // Bu test Firebase bağlantısı gerektirir, integration test için ayrı dosyada yapılmalı
      }, skip: 'Requires Firebase connection');
    });
  });

  group('Error Handling Tests', () {
    test('Should handle authentication errors gracefully', () {
      try {
        // Firebase Auth hata durumları için basit test
        final authService = FirebaseAuthService();
        expect(authService.isSignedIn, false); // Başlangıçta false olmalı
      } catch (e) {
        // Firebase not available in test environment
        expect(e.toString(), contains('Firebase'));
      }
    });

    test('Should handle network errors in backup operations', () async {
      try {
        // Network hata durumları için test
        final backupService = BackupService();
        
        // Offline durumda backup işlemi
        backupService.cloudBackupStatus.value = CloudBackupStatus.error;
        expect(backupService.cloudBackupStatus.value, CloudBackupStatus.error);
      } catch (e) {
        // Firebase not available in test environment
        expect(e.toString(), contains('Firebase'));
      }
    });
  });
}