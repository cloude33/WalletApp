import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';

import 'package:parion/services/backup_service.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/services/kmh_box_service.dart';
import 'package:parion/models/transaction.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/models/backup_metadata.dart';
import '../../test_setup.dart';
import '../../test_helpers.dart';

void main() {
  setupCommonTestMocks();
  group('Backup Integration Tests - Task 12.2', () {
    late BackupService backupService;
    late DataService dataService;

    setUpAll(() async {
      await TestSetup.initializeTestEnvironment();
    });

    tearDownAll(() async {
      await TestSetup.cleanupTestEnvironment();
    });

    setUp(() async {
      // Clear SharedPreferences completely before each test
      SharedPreferences.setMockInitialValues({});

      await TestSetup.setupTest();

      // Initialize services
      backupService = BackupService();
      dataService = DataService(); // Use singleton

      await dataService.init();
      await dataService.clearAllData(); // Ensure clean state for the singleton
      await backupService.loadSettings();

      // Initialize KMH box service for backup tests
      try {
        await KmhBoxService.init();
      } catch (e) {
        // KMH service might fail in test environment, that's okay
        print('KMH service initialization skipped in test: $e');
      }
    });

    tearDown(() async {
      await dataService.clearAllData();
      await TestSetup.tearDownTest();
    });

    test('End-to-end backup and restore workflow', () async {
      try {
        // Create test dataset
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
        expect(metadata.version, isNotNull);
        expect(metadata.createdAt, isNotNull);

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

        // Restore from backup using proper method
        final decompressed = GZipDecoder().decodeBytes(backupData);
        final jsonString = utf8.decode(decompressed);
        final backupDataMap = jsonDecode(jsonString) as Map<String, dynamic>;
        await dataService.restoreFromBackup(backupDataMap);

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

        print(
          '✅ End-to-end backup and restore workflow completed successfully',
        );
      } catch (e, stackTrace) {
        print('❌ End-to-end backup workflow error: $e');
        print('Stack trace: $stackTrace');
        fail('End-to-end backup workflow failed: $e');
      }
    });

    test('Cross-platform compatibility test', () async {
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

        // Verify backup structure
        final decompressed = GZipDecoder().decodeBytes(backupData);
        final jsonString = utf8.decode(decompressed);
        final backupStructure = jsonDecode(jsonString) as Map<String, dynamic>;

        // Check required backup structure elements
        expect(backupStructure.containsKey('metadata'), true);
        expect(backupStructure.containsKey('transactions'), true);
        expect(backupStructure.containsKey('wallets'), true);
        expect(backupStructure.containsKey('users'), true);

        print('✅ Cross-platform backup format verified');
        print('   - Platform: ${metadata.platform}');
        print('   - Device: ${metadata.deviceModel}');
        print('   - Version: ${metadata.version}');
        print(
          '   - Cross-platform compatible: ${metadata.isCrossPlatformCompatible}',
        );
      } catch (e, stackTrace) {
        print('❌ Cross-platform compatibility test error: $e');
        print('Stack trace: $stackTrace');
        fail('Cross-platform compatibility test failed: $e');
      }
    });

    test('Unicode and special characters preservation', () async {
      try {
        // Ensure clean state
        await dataService.saveWallets([]);
        await dataService.saveTransactions([]);

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
        final decompressed = GZipDecoder().decodeBytes(backupData);
        final jsonString = utf8.decode(decompressed);
        final backupDataMap = jsonDecode(jsonString) as Map<String, dynamic>;
        await dataService.restoreFromBackup(backupDataMap);

        // Verify unicode characters are preserved
        final restoredWallets = await dataService.getWallets();
        final restoredTransactions = await dataService.getTransactions();

        expect(restoredWallets.length, specialWallets.length);
        expect(restoredTransactions.length, specialTransactions.length);

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
      } catch (e, stackTrace) {
        print('❌ Unicode preservation test error: $e');
        print('Stack trace: $stackTrace');
        fail('Unicode preservation test failed: $e');
      }
    });

    test('Large dataset performance test', () async {
      try {
        // Ensure clean state
        await dataService.saveWallets([]);
        await dataService.saveTransactions([]);

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
        final decompressed = GZipDecoder().decodeBytes(backupData);
        final jsonString = utf8.decode(decompressed);
        final backupDataMap = jsonDecode(jsonString) as Map<String, dynamic>;
        await dataService.restoreFromBackup(backupDataMap);
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
      } catch (e, stackTrace) {
        print('❌ Large dataset performance test error: $e');
        print('Stack trace: $stackTrace');
        fail('Large dataset performance test failed: $e');
      }
    });

    test('Empty data backup test', () async {
      try {
        // Ensure clean state - clear multiple times to be sure
        await dataService.saveWallets([]);
        await dataService.saveTransactions([]);
        await dataService.saveWallets([]);
        await dataService.saveTransactions([]);

        // Verify no data exists
        final initialWallets = await dataService.getWallets();
        final initialTransactions = await dataService.getTransactions();
        expect(
          initialWallets.length,
          0,
          reason: 'Should start with no wallets',
        );
        expect(
          initialTransactions.length,
          0,
          reason: 'Should start with no transactions',
        );

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
      } catch (e, stackTrace) {
        print('❌ Empty data backup test error: $e');
        print('Stack trace: $stackTrace');
        fail('Empty data backup test failed: $e');
      }
    });

    test('Backup service configuration test', () async {
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
      } catch (e, stackTrace) {
        print('❌ Configuration persistence test error: $e');
        print('Stack trace: $stackTrace');
        fail('Configuration persistence test failed: $e');
      }
    });

    test('Backup format validation and requirements coverage', () async {
      try {
        // Ensure clean state
        await dataService.saveWallets([]);
        await dataService.saveTransactions([]);

        // Create comprehensive test data covering all requirements
        final testWallets = _createTestWallets(20);
        final testTransactions = _createTestTransactions(100, testWallets);

        await dataService.saveWallets(testWallets);
        await dataService.saveTransactions(testTransactions);

        // Create backup
        final backupData = await backupService.createBackupRaw();
        expect(backupData, isNotNull);

        // Validate backup format and structure
        final decompressed = GZipDecoder().decodeBytes(backupData);
        final jsonString = utf8.decode(decompressed);
        final backupStructure = jsonDecode(jsonString) as Map<String, dynamic>;

        // Requirement validation: All backup optimization system requirements

        // 1. Backup format compatibility (Requirements 1.1-1.4)
        expect(
          backupStructure.containsKey('metadata'),
          true,
          reason: 'Backup must contain metadata',
        );
        expect(
          backupStructure.containsKey('transactions'),
          true,
          reason: 'Backup must contain transactions',
        );
        expect(
          backupStructure.containsKey('wallets'),
          true,
          reason: 'Backup must contain wallets',
        );

        // 2. Compression validation (Requirements 2.1-2.4)
        final originalSize = jsonString.length;
        final compressedSize = backupData.length;
        final compressionRatio = (originalSize - compressedSize) / originalSize;
        expect(
          compressionRatio,
          greaterThan(0),
          reason: 'Backup should be compressed',
        );

        // 3. Cross-platform compatibility (Requirements 3.1-3.4)
        final metadata = BackupMetadata.fromJson(backupStructure['metadata']);
        expect(
          metadata.isCrossPlatformCompatible,
          true,
          reason: 'Backup must be cross-platform compatible',
        );
        expect(
          metadata.platform,
          isNotNull,
          reason: 'Platform information must be present',
        );
        expect(
          metadata.version,
          isNotNull,
          reason: 'Version information must be present',
        );

        // 4. Data integrity validation (Requirements 6.1-6.4)
        expect(
          metadata.walletCount,
          testWallets.length,
          reason: 'Wallet count must match',
        );
        expect(
          metadata.transactionCount,
          testTransactions.length,
          reason: 'Transaction count must match',
        );
        expect(
          metadata.createdAt,
          isNotNull,
          reason: 'Creation timestamp must be present',
        );

        // 5. Performance requirements (Requirements 7.1-7.4)
        final backupStopwatch = Stopwatch()..start();
        await backupService.createBackupRaw();
        backupStopwatch.stop();
        expect(
          backupStopwatch.elapsed.inSeconds,
          lessThan(30),
          reason: 'Backup should complete within 30 seconds',
        );

        print('✅ All backup optimization requirements validated');
        print(
          '   - Compression ratio: ${(compressionRatio * 100).toStringAsFixed(1)}%',
        );
        print('   - Original size: $originalSize bytes');
        print('   - Compressed size: $compressedSize bytes');
        print('   - Performance: ${backupStopwatch.elapsedMilliseconds}ms');
      } catch (e, stackTrace) {
        print('❌ Requirements validation test error: $e');
        print('Stack trace: $stackTrace');
        fail('Requirements validation test failed: $e');
      }
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
        id: 'integration_wallet_${startId + i}',
        name: 'Integration Test Wallet ${startId + i}',
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
        id: 'integration_transaction_${startId + i}',
        amount: (i + 1) * 10.0,
        description: 'Integration Test Transaction ${startId + i}',
        date: DateTime.now().subtract(Duration(days: i % 30)),
        type: types[i % types.length],
        walletId: wallets[i % wallets.length].id,
        category: categories[i % categories.length],
      ),
    );
  }

  return transactions;
}
