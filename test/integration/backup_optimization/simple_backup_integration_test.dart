import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';

import 'package:parion/services/backup_service.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/models/transaction.dart';
import 'package:parion/models/wallet.dart';
import '../../test_setup.dart';
import '../../test_helpers.dart';

void main() {
  setupCommonTestMocks();

  group('Simple Backup Integration Tests', () {
    late BackupService backupService;
    late DataService dataService;

    /// Helper method to restore from backup bytes
    Future<void> restoreFromBackupBytes(List<int> backupBytes) async {
      final decompressed = GZipDecoder().decodeBytes(backupBytes);
      final jsonString = utf8.decode(decompressed);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      await dataService.restoreFromBackup(backupData);
    }

    setUpAll(() async {
      await TestSetup.initializeTestEnvironment();

      // Initialize services
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

    group('End-to-End Backup and Restore Workflows', () {
      testWidgets(
        'Complete backup and restore workflow with comprehensive data',
        (WidgetTester tester) async {
          try {
            // Create comprehensive test dataset
            final testWallets = _createTestWallets(10);
            final testTransactions = _createTestTransactions(50, testWallets);

            // Save test data
            await dataService.saveWallets(testWallets);
            await dataService.saveTransactions(testTransactions);

            // Verify data is saved
            final savedWallets = await dataService.getWallets();
            final savedTransactions = await dataService.getTransactions();
            expect(savedWallets.length, testWallets.length);
            expect(savedTransactions.length, testTransactions.length);

            print(
              '✅ Test data created: ${testWallets.length} wallets, ${testTransactions.length} transactions',
            );

            // Create backup
            final backupData = await backupService.createBackupRaw();
            expect(backupData, isNotNull);
            expect(backupData.length, greaterThan(0));

            // Verify backup metadata
            final metadata = await backupService.getBackupMetadataFromBytes(
              backupData,
            );
            expect(metadata, isNotNull);
            expect(metadata!.walletCount, testWallets.length);
            expect(metadata.transactionCount, testTransactions.length);

            print('✅ Backup created successfully');
            print('   - Backup size: ${backupData.length} bytes');
            print('   - Wallets in backup: ${metadata.walletCount}');
            print('   - Transactions in backup: ${metadata.transactionCount}');

            // Clear all data
            await dataService.saveWallets([]);
            await dataService.saveTransactions([]);

            // Verify data is cleared
            final clearedWallets = await dataService.getWallets();
            final clearedTransactions = await dataService.getTransactions();
            expect(clearedWallets.length, 0);
            expect(clearedTransactions.length, 0);

            print('✅ Data cleared for restore test');

            // Restore from backup
            await restoreFromBackupBytes(backupData);

            // Verify data is restored
            final restoredWallets = await dataService.getWallets();
            final restoredTransactions = await dataService.getTransactions();

            expect(restoredWallets.length, testWallets.length);
            expect(restoredTransactions.length, testTransactions.length);

            // Verify data integrity
            for (final originalWallet in testWallets) {
              final found = restoredWallets.firstWhere(
                (w) => w.id == originalWallet.id,
              );
              expect(found.name, originalWallet.name);
              expect(found.balance, originalWallet.balance);
              expect(found.type, originalWallet.type);
            }

            for (final originalTransaction in testTransactions) {
              final found = restoredTransactions.firstWhere(
                (t) => t.id == originalTransaction.id,
              );
              expect(found.description, originalTransaction.description);
              expect(found.amount, originalTransaction.amount);
              expect(found.category, originalTransaction.category);
            }

            print('✅ Full backup and restore workflow completed successfully');
          } catch (e) {
            print('❌ Full backup and restore workflow error: $e');
            fail('Full backup and restore workflow failed: $e');
          }
        },
      );

      testWidgets('Backup with special characters and unicode', (
        WidgetTester tester,
      ) async {
        try {
          // Create test data with special characters and unicode
          final specialWallets = [
            Wallet(
              id: 'unicode_1',
              name: 'Türkçe Cüzdan 💰',
              balance: 1234.56,
              type: 'bank',
              color: '#FF5722',
              icon: 'wallet',
            ),
            Wallet(
              id: 'unicode_2',
              name: '中文钱包 🏦',
              balance: 9876.54,
              type: 'cash',
              color: '#2196F3',
              icon: 'cash',
            ),
            Wallet(
              id: 'unicode_3',
              name: 'العربية محفظة 💳',
              balance: 5555.55,
              type: 'credit',
              color: '#4CAF50',
              icon: 'credit',
            ),
          ];

          final specialTransactions = [
            Transaction(
              id: 'unicode_trans_1',
              amount: 123.45,
              description: 'Café ☕ & Résumé 📄',
              date: DateTime.now(),
              type: 'expense',
              walletId: 'unicode_1',
              category: 'Özel Kategori',
            ),
            Transaction(
              id: 'unicode_trans_2',
              amount: 678.90,
              description: '购物 🛒 和 餐厅 🍽️',
              date: DateTime.now(),
              type: 'expense',
              walletId: 'unicode_2',
              category: '购物',
            ),
            Transaction(
              id: 'unicode_trans_3',
              amount: 999.99,
              description: 'مطعم 🍕 و تسوق 🛍️',
              date: DateTime.now(),
              type: 'expense',
              walletId: 'unicode_3',
              category: 'مطاعم',
            ),
          ];

          await dataService.saveWallets(specialWallets);
          await dataService.saveTransactions(specialTransactions);

          // Create backup
          final backupData = await backupService.createBackupRaw();
          expect(backupData, isNotNull);

          // Clear data
          await dataService.saveWallets([]);
          await dataService.saveTransactions([]);

          // Restore backup
          await restoreFromBackupBytes(backupData);

          // Verify unicode characters are preserved
          final restoredWallets = await dataService.getWallets();
          final restoredTransactions = await dataService.getTransactions();

          // Check Turkish characters
          final turkishWallet = restoredWallets.firstWhere(
            (w) => w.id == 'unicode_1',
          );
          expect(turkishWallet.name, 'Türkçe Cüzdan 💰');

          final turkishTransaction = restoredTransactions.firstWhere(
            (t) => t.id == 'unicode_trans_1',
          );
          expect(turkishTransaction.description, 'Café ☕ & Résumé 📄');
          expect(turkishTransaction.category, 'Özel Kategori');

          // Check Chinese characters
          final chineseWallet = restoredWallets.firstWhere(
            (w) => w.id == 'unicode_2',
          );
          expect(chineseWallet.name, '中文钱包 🏦');

          final chineseTransaction = restoredTransactions.firstWhere(
            (t) => t.id == 'unicode_trans_2',
          );
          expect(chineseTransaction.description, '购物 🛒 和 餐厅 🍽️');
          expect(chineseTransaction.category, '购物');

          // Check Arabic characters
          final arabicWallet = restoredWallets.firstWhere(
            (w) => w.id == 'unicode_3',
          );
          expect(arabicWallet.name, 'العربية محفظة 💳');

          final arabicTransaction = restoredTransactions.firstWhere(
            (t) => t.id == 'unicode_trans_3',
          );
          expect(arabicTransaction.description, 'مطعم 🍕 و تسوق 🛍️');
          expect(arabicTransaction.category, 'مطاعم');

          print('✅ Unicode and special characters preserved across platforms');
        } catch (e) {
          print('❌ Unicode preservation test error: $e');
          fail('Unicode preservation test failed: $e');
        }
      });
    });

    group('Cross-Platform Compatibility Tests', () {
      testWidgets('Backup format compatibility across platforms', (
        WidgetTester tester,
      ) async {
        try {
          // Create test data
          final testWallets = _createTestWallets(5);
          final testTransactions = _createTestTransactions(25, testWallets);

          await dataService.saveWallets(testWallets);
          await dataService.saveTransactions(testTransactions);

          // Create backup
          final backupData = await backupService.createBackupRaw();
          expect(backupData, isNotNull);

          // Extract and verify metadata
          final metadata = await backupService.getBackupMetadataFromBytes(
            backupData,
          );
          expect(metadata, isNotNull);
          expect(metadata!.isCrossPlatformCompatible, true);
          expect(metadata.version, isNotNull);

          // Platform information should be present
          expect(metadata.platform, isNotNull);
          expect(metadata.deviceModel, isNotNull);

          print('✅ Cross-platform backup format verified');
          print('   - Platform: ${metadata.platform}');
          print('   - Device: ${metadata.deviceModel}');
          print('   - Version: ${metadata.version}');
          print(
            '   - Cross-platform compatible: ${metadata.isCrossPlatformCompatible}',
          );
        } catch (e) {
          print('❌ Cross-platform compatibility test error: $e');
          fail('Cross-platform compatibility test failed: $e');
        }
      });

      testWidgets('Numeric precision preservation', (
        WidgetTester tester,
      ) async {
        try {
          // Create test data with various numeric precisions
          final precisionTestWallets = [
            Wallet(
              id: 'precision_1',
              name: 'High Precision',
              balance: 123.456789,
              type: 'bank',
              color: 'blue',
              icon: 'wallet',
            ),
            Wallet(
              id: 'precision_2',
              name: 'Very Small',
              balance: 0.01,
              type: 'cash',
              color: 'green',
              icon: 'cash',
            ),
            Wallet(
              id: 'precision_3',
              name: 'Large Number',
              balance: 999999.99,
              type: 'savings',
              color: 'orange',
              icon: 'savings',
            ),
            Wallet(
              id: 'precision_4',
              name: 'Negative',
              balance: -1234.56,
              type: 'credit',
              color: 'red',
              icon: 'credit',
            ),
          ];

          final precisionTestTransactions = [
            Transaction(
              id: 'prec_trans_1',
              amount: 0.001,
              description: 'Micro Transaction',
              date: DateTime.now(),
              type: 'expense',
              walletId: 'precision_1',
              category: 'test',
            ),
            Transaction(
              id: 'prec_trans_2',
              amount: 1234567.89,
              description: 'Large Transaction',
              date: DateTime.now(),
              type: 'income',
              walletId: 'precision_2',
              category: 'test',
            ),
            Transaction(
              id: 'prec_trans_3',
              amount: -999.999,
              description: 'Negative Transaction',
              date: DateTime.now(),
              type: 'expense',
              walletId: 'precision_3',
              category: 'test',
            ),
          ];

          await dataService.saveWallets(precisionTestWallets);
          await dataService.saveTransactions(precisionTestTransactions);

          // Create backup
          final backupData = await backupService.createBackupRaw();
          expect(backupData, isNotNull);

          // Clear and restore
          await dataService.saveWallets([]);
          await dataService.saveTransactions([]);

          await restoreFromBackupBytes(backupData);

          final restoredWallets = await dataService.getWallets();
          final restoredTransactions = await dataService.getTransactions();

          // Verify numeric precision is preserved
          for (final original in precisionTestWallets) {
            final restored = restoredWallets.firstWhere(
              (w) => w.id == original.id,
            );
            expect(restored.balance, closeTo(original.balance, 0.001));
            print(
              '✅ Wallet precision preserved: ${original.id} - ${original.balance} → ${restored.balance}',
            );
          }

          for (final original in precisionTestTransactions) {
            final restored = restoredTransactions.firstWhere(
              (t) => t.id == original.id,
            );
            expect(restored.amount, closeTo(original.amount, 0.001));
            print(
              '✅ Transaction precision preserved: ${original.id} - ${original.amount} → ${restored.amount}',
            );
          }

          print('✅ Numeric precision preservation verified');
        } catch (e) {
          print('❌ Numeric precision test error: $e');
          fail('Numeric precision test failed: $e');
        }
      });
    });

    group('Performance and Scalability Tests', () {
      testWidgets('Large dataset backup performance', (
        WidgetTester tester,
      ) async {
        try {
          // Create large dataset
          final largeWalletList = _createTestWallets(50);
          final largeTransactionList = _createTestTransactions(
            500,
            largeWalletList,
          );

          await dataService.saveWallets(largeWalletList);
          await dataService.saveTransactions(largeTransactionList);

          print(
            '✅ Large dataset created: ${largeWalletList.length} wallets, ${largeTransactionList.length} transactions',
          );

          // Measure backup performance
          final backupStopwatch = Stopwatch()..start();
          final backupData = await backupService.createBackupRaw();
          backupStopwatch.stop();

          expect(backupData, isNotNull);
          expect(backupData.length, greaterThan(0));
          expect(
            backupStopwatch.elapsed.inSeconds,
            lessThan(60),
          ); // Should complete within 60 seconds

          // Verify backup contains expected data
          final metadata = await backupService.getBackupMetadataFromBytes(
            backupData,
          );
          expect(metadata, isNotNull);
          expect(metadata!.walletCount, largeWalletList.length);
          expect(metadata.transactionCount, largeTransactionList.length);

          print(
            '✅ Large dataset backup completed in ${backupStopwatch.elapsedMilliseconds}ms',
          );
          print('   - Backup size: ${backupData.length} bytes');

          // Clear data
          await dataService.saveWallets([]);
          await dataService.saveTransactions([]);

          // Measure restore performance
          final restoreStopwatch = Stopwatch()..start();
          await restoreFromBackupBytes(backupData);
          restoreStopwatch.stop();

          expect(
            restoreStopwatch.elapsed.inSeconds,
            lessThan(60),
          ); // Should restore within 60 seconds

          // Verify data integrity
          final restoredWallets = await dataService.getWallets();
          final restoredTransactions = await dataService.getTransactions();

          expect(restoredWallets.length, largeWalletList.length);
          expect(restoredTransactions.length, largeTransactionList.length);

          print(
            '✅ Large dataset restore completed in ${restoreStopwatch.elapsedMilliseconds}ms',
          );
        } catch (e) {
          print('❌ Large dataset performance test error: $e');
          fail('Large dataset performance test failed: $e');
        }
      });

      testWidgets('Multiple backup operations performance', (
        WidgetTester tester,
      ) async {
        try {
          // Create test data
          final testWallets = _createTestWallets(10);
          final testTransactions = _createTestTransactions(50, testWallets);

          await dataService.saveWallets(testWallets);
          await dataService.saveTransactions(testTransactions);

          // Perform multiple backup operations
          final backupTimes = <Duration>[];

          for (int i = 0; i < 5; i++) {
            final stopwatch = Stopwatch()..start();
            final backupData = await backupService.createBackupRaw();
            stopwatch.stop();

            expect(backupData, isNotNull);
            expect(backupData.length, greaterThan(0));

            backupTimes.add(stopwatch.elapsed);

            // Each backup should complete within reasonable time
            expect(stopwatch.elapsed.inSeconds, lessThan(30));
          }

          // Calculate average time
          final averageTime =
              backupTimes.fold<Duration>(
                Duration.zero,
                (prev, time) => prev + time,
              ) ~/
              backupTimes.length;

          print('✅ Multiple backup operations completed');
          print('   - Average backup time: ${averageTime.inMilliseconds}ms');
          for (int i = 0; i < backupTimes.length; i++) {
            print('   - Backup ${i + 1}: ${backupTimes[i].inMilliseconds}ms');
          }
        } catch (e) {
          print('❌ Multiple backup operations test error: $e');
          fail('Multiple backup operations test failed: $e');
        }
      });
    });

    group('Error Handling and Recovery Tests', () {
      testWidgets('Backup with empty data', (WidgetTester tester) async {
        try {
          // Ensure no data exists
          await dataService.saveWallets([]);
          await dataService.saveTransactions([]);

          // Create backup with empty data
          final backupData = await backupService.createBackupRaw();
          expect(backupData, isNotNull);
          expect(backupData.length, greaterThan(0));

          // Verify backup metadata
          final metadata = await backupService.getBackupMetadataFromBytes(
            backupData,
          );
          expect(metadata, isNotNull);
          expect(metadata!.walletCount, 0);
          expect(metadata.transactionCount, 0);

          print('✅ Empty data backup handled correctly');
        } catch (e) {
          print('❌ Empty data backup test error: $e');
          fail('Empty data backup test failed: $e');
        }
      });

      testWidgets('Backup service configuration persistence', (
        WidgetTester tester,
      ) async {
        try {
          // Test backup service configuration
          await backupService.enableAutoCloudBackup(true);
          expect(backupService.autoCloudBackupEnabled.value, true);

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

          print('✅ Backup service configuration persistence verified');
        } catch (e) {
          print('❌ Configuration persistence test error: $e');
          fail('Configuration persistence test failed: $e');
        }
      });
    });
  });
}

/// Helper function to create test wallets
List<Wallet> _createTestWallets(int count, {int startId = 0}) {
  final wallets = <Wallet>[];
  final types = ['bank', 'cash', 'credit', 'savings'];
  final colors = ['#FF5722', '#2196F3', '#4CAF50', '#FF9800', '#9C27B0'];

  for (int i = 0; i < count; i++) {
    wallets.add(
      Wallet(
        id: 'simple_integration_wallet_${startId + i}',
        name: 'Simple Integration Test Wallet ${startId + i}',
        balance: (i + 1) * 100.0,
        type: types[i % types.length],
        color: colors[i % colors.length],
        icon: 'wallet',
      ),
    );
  }

  return wallets;
}

/// Helper function to create test transactions
List<Transaction> _createTestTransactions(
  int count,
  List<Wallet> wallets, {
  int startId = 0,
}) {
  final transactions = <Transaction>[];
  final categories = [
    'food',
    'transport',
    'entertainment',
    'shopping',
    'bills',
  ];
  final types = ['expense', 'income'];

  for (int i = 0; i < count; i++) {
    transactions.add(
      Transaction(
        id: 'simple_integration_transaction_${startId + i}',
        amount: (i + 1) * 10.0,
        description: 'Simple Integration Test Transaction ${startId + i}',
        date: DateTime.now().subtract(Duration(days: i % 30)),
        type: types[i % types.length],
        walletId: wallets[i % wallets.length].id,
        category: categories[i % categories.length],
      ),
    );
  }

  return transactions;
}
