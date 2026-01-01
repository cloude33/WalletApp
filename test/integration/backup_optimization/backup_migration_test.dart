import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:parion/services/backup_service.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/models/backup_metadata.dart';
import 'package:parion/models/transaction.dart';
import 'package:parion/models/wallet.dart';
import '../../test_setup.dart';
import '../../test_helpers.dart';

void main() {
  setupCommonTestMocks();
  group('Backup Migration and Compatibility Tests', () {
    late BackupService backupService;
    late DataService dataService;

    setUpAll(() async {
      await TestSetup.initializeTestEnvironment();

      backupService = BackupService();
      dataService = DataService();

      await dataService.init();
      await backupService.loadSettings();
    });

    tearDownAll(() async {
      await TestSetup.cleanupTestEnvironment();
    });

    setUp(() async {
      await TestSetup.setupTest();

      // Clear preferences for clean test state
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    tearDown(() async {
      await TestSetup.tearDownTest();
    });

    group('Legacy Backup Format Migration', () {
      test('Should handle version 2.0 backup metadata correctly', () async {
        // Create legacy backup metadata (version 2.0)
        final legacyMetadata = BackupMetadata(
          version: '2.0',
          createdAt: DateTime.now(),
          transactionCount: 50,
          walletCount: 5,
          platform: 'android',
          deviceModel: 'Test Device',
        );

        // Test JSON serialization/deserialization
        final json = legacyMetadata.toJson();
        final restored = BackupMetadata.fromJson(json);

        expect(restored.version, legacyMetadata.version);
        expect(restored.transactionCount, legacyMetadata.transactionCount);
        expect(restored.walletCount, legacyMetadata.walletCount);
        expect(restored.platform, legacyMetadata.platform);
        expect(restored.isCrossPlatformCompatible, true);

        print('✅ Legacy backup metadata handled correctly');
        print('   - Version: ${restored.version}');
        print(
          '   - Cross-platform compatible: ${restored.isCrossPlatformCompatible}',
        );
      });

      test(
        'Should handle missing fields in legacy backup gracefully',
        () async {
          // Create incomplete legacy backup data (missing some fields)
          final incompleteMetadata = {
            'version': '1.5', // Old version
            'createdAt': DateTime.now().toIso8601String(),
            'transactionCount': 10,
            // Missing walletCount, platform, deviceModel
          };

          try {
            final metadata = BackupMetadata.fromJson(incompleteMetadata);

            // Should handle missing fields gracefully
            expect(metadata.version, '1.5');
            expect(metadata.transactionCount, 10);
            expect(metadata.walletCount, 0); // Should default to 0
            expect(metadata.platform, isNotNull); // Should have default

            print('✅ Incomplete legacy backup handled gracefully');
          } catch (e) {
            // Should provide meaningful error message
            expect(e.toString(), contains('backup'));
            print('✅ Incomplete legacy backup error handled: $e');
          }
        },
      );

      test('Should preserve user preferences during migration', () async {
        // Set legacy preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('auto_cloud_backup_enabled', true);
        await prefs.setString('last_cloud_backup_date', '01/01/2024 12:00');
        await prefs.setBool('auto_backup_enabled', true);
        await prefs.setInt('auto_backup_hour', 14);
        await prefs.setInt('auto_backup_minute', 30);

        // Load settings in backup service
        await backupService.loadSettings();

        // Verify preferences are preserved
        expect(backupService.autoCloudBackupEnabled.value, true);
        expect(backupService.lastCloudBackupDate.value, '01/01/2024 12:00');

        // Test that scheduled backup settings work
        final isScheduled = await backupService.isAutomaticBackupScheduled();
        expect(isScheduled, true);

        final scheduledTime = await backupService.getScheduledBackupTime();
        expect(scheduledTime, isNotNull);
        expect(scheduledTime!.hour, 14);
        expect(scheduledTime.minute, 30);

        print('✅ User preferences preserved during migration');
        print(
          '   - Auto cloud backup: ${backupService.autoCloudBackupEnabled.value}',
        );
        print(
          '   - Last backup date: ${backupService.lastCloudBackupDate.value}',
        );
        print(
          '   - Scheduled time: ${scheduledTime.hour}:${scheduledTime.minute}',
        );
      });
    });

    group('Backward Compatibility', () {
      test('Should maintain file format compatibility', () async {
        // Create backup with current service
        final backupData = await backupService.createBackupRaw();

        expect(backupData, isNotNull);
        expect(backupData.length, greaterThan(0));

        // Test that metadata can be extracted
        final metadata = await backupService.getBackupMetadataFromBytes(
          backupData,
        );
        expect(metadata, isNotNull);
        expect(metadata!.version, isNotNull);

        // File format should be compatible (readable)
        expect(metadata.transactionCount, isA<int>());
        expect(metadata.walletCount, isA<int>());

        print('✅ File format compatibility maintained');
        print('   - Format readable: ${metadata.version}');
        print('   - Data size: ${backupData.length} bytes');
      });

      test('Should handle cross-platform compatibility correctly', () async {
        // Test different platform scenarios
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

        final webMetadata = BackupMetadata(
          version: '2.0',
          createdAt: DateTime.now(),
          transactionCount: 1,
          walletCount: 1,
          platform: 'web',
        );

        expect(androidMetadata.isCrossPlatformCompatible, true);
        expect(iosMetadata.isCrossPlatformCompatible, true);
        expect(webMetadata.isCrossPlatformCompatible, true);

        print('✅ Cross-platform compatibility verified');
        print(
          '   - Android compatible: ${androidMetadata.isCrossPlatformCompatible}',
        );
        print('   - iOS compatible: ${iosMetadata.isCrossPlatformCompatible}');
        print('   - Web compatible: ${webMetadata.isCrossPlatformCompatible}');
      });
    });

    group('Data Integrity During Migration', () {
      test('Should preserve all data during backup and restore', () async {
        // Create comprehensive test data
        final testWallets = [
          Wallet(
            id: '1',
            name: 'Cash',
            balance: 100.0,
            type: 'cash',
            color: 'green',
            icon: 'cash',
          ),
          Wallet(
            id: '2',
            name: 'Bank',
            balance: 1000.0,
            type: 'bank',
            color: 'blue',
            icon: 'bank',
          ),
          Wallet(
            id: '3',
            name: 'Credit',
            balance: -200.0,
            type: 'credit',
            color: 'red',
            icon: 'credit',
          ),
        ];

        final testTransactions = [
          Transaction(
            id: '1',
            amount: 50.0,
            description: 'Grocery',
            date: DateTime.now(),
            type: 'expense',
            walletId: '1',
            category: 'food',
          ),
          Transaction(
            id: '2',
            amount: 1000.0,
            description: 'Salary',
            date: DateTime.now(),
            type: 'income',
            walletId: '2',
            category: 'salary',
          ),
          Transaction(
            id: '3',
            amount: 200.0,
            description: 'Shopping',
            date: DateTime.now(),
            type: 'expense',
            walletId: '3',
            category: 'shopping',
          ),
        ];

        await dataService.saveWallets(testWallets);
        await dataService.saveTransactions(testTransactions);

        // Create backup
        final backupData = await backupService.createBackupRaw();

        // Verify backup contains expected data
        final metadata = await backupService.getBackupMetadataFromBytes(
          backupData,
        );
        expect(metadata, isNotNull);
        expect(metadata!.walletCount, testWallets.length);
        expect(metadata.transactionCount, testTransactions.length);

        // Clear data
        await dataService.saveWallets([]);
        await dataService.saveTransactions([]);

        // Verify data is cleared
        final clearedWallets = await dataService.getWallets();
        final clearedTransactions = await dataService.getTransactions();
        expect(clearedWallets.length, 0);
        expect(clearedTransactions.length, 0);

        // Restore from backup data (simulate restore process)
        final decompressed = GZipDecoder().decodeBytes(backupData);
        final jsonString = utf8.decode(decompressed);
        final restoredBackupData =
            jsonDecode(jsonString) as Map<String, dynamic>;

        await dataService.restoreFromBackup(restoredBackupData);

        // Verify data is restored
        final restoredWallets = await dataService.getWallets();
        final restoredTransactions = await dataService.getTransactions();

        expect(restoredWallets.length, testWallets.length);
        expect(restoredTransactions.length, testTransactions.length);

        // Check specific wallet data
        for (final originalWallet in testWallets) {
          final found = restoredWallets.firstWhere(
            (w) => w.id == originalWallet.id,
          );
          expect(found.name, originalWallet.name);
          expect(found.balance, originalWallet.balance);
          expect(found.type, originalWallet.type);
        }

        // Check specific transaction data
        for (final originalTransaction in testTransactions) {
          final found = restoredTransactions.firstWhere(
            (t) => t.id == originalTransaction.id,
          );
          expect(found.description, originalTransaction.description);
          expect(found.amount, originalTransaction.amount);
          expect(found.category, originalTransaction.category);
        }

        print('✅ Data integrity preserved during migration');
        print(
          '   - Wallets: ${testWallets.length} → ${restoredWallets.length}',
        );
        print(
          '   - Transactions: ${testTransactions.length} → ${restoredTransactions.length}',
        );
      });

      test(
        'Should handle special characters and unicode in migration',
        () async {
          // Create data with special characters
          final specialWallet = Wallet(
            id: 'special_1',
            name: 'Özel Çüzdan 💰',
            balance: 1234.56,
            type: 'bank',
            color: '#FF5722',
            icon: 'wallet',
          );

          final specialTransaction = Transaction(
            id: 'special_1',
            amount: 123.45,
            description: 'Türkçe açıklama with émojis 🛒💳',
            date: DateTime.now(),
            type: 'expense',
            walletId: 'special_1',
            category: 'Özel Kategori',
          );

          await dataService.saveWallets([specialWallet]);
          await dataService.saveTransactions([specialTransaction]);

          // Create backup
          final backupData = await backupService.createBackupRaw();

          // Clear and restore
          await dataService.saveWallets([]);
          await dataService.saveTransactions([]);

          // Restore from backup
          final decompressed = GZipDecoder().decodeBytes(backupData);
          final jsonString = utf8.decode(decompressed);
          final restoredBackupData =
              jsonDecode(jsonString) as Map<String, dynamic>;

          await dataService.restoreFromBackup(restoredBackupData);

          // Verify special characters are preserved
          final restoredWallets = await dataService.getWallets();
          final restoredTransactions = await dataService.getTransactions();

          final foundWallet = restoredWallets.firstWhere(
            (w) => w.id == 'special_1',
          );
          final foundTransaction = restoredTransactions.firstWhere(
            (t) => t.id == 'special_1',
          );

          expect(foundWallet.name, 'Özel Çüzdan 💰');
          expect(
            foundTransaction.description,
            'Türkçe açıklama with émojis 🛒💳',
          );
          expect(foundTransaction.category, 'Özel Kategori');

          print('✅ Special characters and unicode preserved');
        },
      );
    });

    group('Performance Regression Testing', () {
      test('Should handle moderate datasets efficiently', () async {
        // Create moderate dataset
        final wallets = List.generate(
          20,
          (i) => Wallet(
            id: 'perf_wallet_$i',
            name: 'Performance Wallet $i',
            balance: i * 50.0,
            type: 'bank',
            color: 'blue',
            icon: 'wallet',
          ),
        );

        final transactions = List.generate(
          200,
          (i) => Transaction(
            id: 'perf_transaction_$i',
            amount: i * 5.0,
            description: 'Performance Transaction $i',
            date: DateTime.now().subtract(Duration(days: i % 30)),
            type: i % 2 == 0 ? 'expense' : 'income',
            walletId: 'perf_wallet_${i % 20}',
            category: 'perf_category',
          ),
        );

        await dataService.saveWallets(wallets);
        await dataService.saveTransactions(transactions);

        // Measure backup time
        final stopwatch = Stopwatch()..start();
        final backupData = await backupService.createBackupRaw();
        stopwatch.stop();

        expect(backupData, isNotNull);
        expect(backupData.length, greaterThan(0));

        // Backup should complete within reasonable time (30 seconds)
        expect(stopwatch.elapsed.inSeconds, lessThan(30));

        // Verify backup contains all data
        final metadata = await backupService.getBackupMetadataFromBytes(
          backupData,
        );
        expect(metadata, isNotNull);
        expect(metadata!.walletCount, wallets.length);
        expect(metadata.transactionCount, transactions.length);

        print('✅ Performance test passed');
        print('   - Backup time: ${stopwatch.elapsedMilliseconds}ms');
        print('   - Data size: ${backupData.length} bytes');
        print('   - Wallets: ${metadata.walletCount}');
        print('   - Transactions: ${metadata.transactionCount}');
      });
    });

    group('System Integration Validation', () {
      test('Should integrate with existing backup service correctly', () async {
        // Test that backup service methods work correctly
        expect(backupService.cloudBackupStatus, isNotNull);
        expect(backupService.autoCloudBackupEnabled, isNotNull);
        expect(backupService.lastCloudBackupDate, isNotNull);

        // Test status management
        backupService.cloudBackupStatus.value = CloudBackupStatus.uploading;
        expect(
          backupService.cloudBackupStatus.value,
          CloudBackupStatus.uploading,
        );

        // Test status text
        final statusText = backupService.getCloudBackupStatusText();
        expect(statusText, isNotNull);
        expect(statusText.isNotEmpty, true);

        // Reset status
        backupService.cloudBackupStatus.value = CloudBackupStatus.idle;

        print('✅ Backup service integration validated');
      });

      test('Should maintain data service compatibility', () async {
        // Test that backup service works with data service
        final wallets = await dataService.getWallets();
        final transactions = await dataService.getTransactions();

        // Backup service should be able to create backup from this data
        final backupData = await backupService.createBackupRaw();
        expect(backupData, isNotNull);

        // Verify that backup contains the expected data
        final metadata = await backupService.getBackupMetadataFromBytes(
          backupData,
        );
        expect(metadata, isNotNull);
        expect(metadata!.walletCount, wallets.length);
        expect(metadata.transactionCount, transactions.length);

        print('✅ Data service compatibility maintained');
      });

      test('Should handle configuration persistence correctly', () async {
        // Test backup service configuration
        await backupService.enableAutoCloudBackup(true);
        expect(backupService.autoCloudBackupEnabled.value, true);

        // Test scheduled backup configuration
        final testTime = TimeOfDay(hour: 14, minute: 30);
        await backupService.scheduleAutomaticBackup(testTime);

        final isScheduled = await backupService.isAutomaticBackupScheduled();
        expect(isScheduled, true);

        final scheduledTime = await backupService.getScheduledBackupTime();
        expect(scheduledTime, isNotNull);
        expect(scheduledTime!.hour, testTime.hour);
        expect(scheduledTime.minute, testTime.minute);

        // Cancel and verify
        await backupService.cancelAutomaticBackup();
        final isCancelled = await backupService.isAutomaticBackupScheduled();
        expect(isCancelled, false);

        print('✅ Configuration persistence works correctly');
      });
    });
  });
}
