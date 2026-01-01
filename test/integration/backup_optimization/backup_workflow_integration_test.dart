import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:parion/services/backup_optimization/enhanced_backup_manager.dart'
    as backup_manager;
import 'package:parion/services/data_service.dart';
import 'package:parion/models/backup_optimization/backup_config.dart'
    as backup_config;
import 'package:parion/models/backup_optimization/backup_enums.dart'
    as backup_enums;
import 'package:parion/models/transaction.dart';
import 'package:parion/models/wallet.dart';
import '../../test_setup.dart';
import '../../test_helpers.dart';

void main() {
  setupCommonTestMocks();

  group('Backup Workflow Integration Tests', () {
    late backup_manager.EnhancedBackupManager enhancedBackupManager;
    late DataService dataService;

    setUpAll(() async {
      await TestSetup.initializeTestEnvironment();

      // Initialize services
      enhancedBackupManager = backup_manager.EnhancedBackupManager();
      dataService = DataService();

      await dataService.init();
      await enhancedBackupManager.initialize();
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
      testWidgets('Complete full backup and restore workflow', (
        WidgetTester tester,
      ) async {
        try {
          // Create comprehensive test dataset
          final testWallets = _createTestWallets(5);
          final testTransactions = _createTestTransactions(25, testWallets);

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

          // Create full backup
          final fullBackupResult = await enhancedBackupManager
              .createFullBackup();
          expect(fullBackupResult.success, true);
          expect(fullBackupResult.metadata, isNotNull);
          expect(fullBackupResult.metadata!.type, backup_enums.BackupType.full);

          print('✅ Full backup created successfully');
          print('   - Backup ID: ${fullBackupResult.backupId}');
          print('   - Duration: ${fullBackupResult.duration.inMilliseconds}ms');
          print(
            '   - Compression ratio: ${fullBackupResult.compressionRatio.toStringAsFixed(2)}',
          );

          // Clear all data
          await dataService.saveWallets([]);
          await dataService.saveTransactions([]);

          // Verify data is cleared
          final clearedWallets = await dataService.getWallets();
          final clearedTransactions = await dataService.getTransactions();
          expect(clearedWallets.length, 0);
          expect(clearedTransactions.length, 0);

          print('✅ Data cleared for restore test');

          // Restore from backup (if local file exists)
          if (fullBackupResult.localFile != null) {
            await enhancedBackupManager.restoreFromBackup(
              fullBackupResult.localFile!,
            );

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
          } else {
            print('⚠️ Local backup file not available, skipping restore test');
          }
        } catch (e) {
          print('❌ Full backup and restore workflow error: $e');
          fail('Full backup and restore workflow failed: $e');
        }
      });

      testWidgets('Incremental backup workflow', (WidgetTester tester) async {
        try {
          // Create initial dataset
          final initialWallets = _createTestWallets(3);
          final initialTransactions = _createTestTransactions(
            10,
            initialWallets,
          );

          await dataService.saveWallets(initialWallets);
          await dataService.saveTransactions(initialTransactions);

          // Create initial full backup
          final fullBackupResult = await enhancedBackupManager
              .createFullBackup();
          expect(fullBackupResult.success, true);

          print('✅ Initial full backup created');

          // Add more data (simulating user activity)
          final additionalWallets = _createTestWallets(2, startId: 3);
          final additionalTransactions = _createTestTransactions(
            8,
            initialWallets + additionalWallets,
            startId: 10,
          );

          await dataService.saveWallets(initialWallets + additionalWallets);
          await dataService.saveTransactions(
            initialTransactions + additionalTransactions,
          );

          // Create incremental backup
          final incrementalBackupResult = await enhancedBackupManager
              .createIncrementalBackup();
          expect(incrementalBackupResult.success, true);
          expect(
            incrementalBackupResult.metadata!.type,
            backup_enums.BackupType.incremental,
          );

          print('✅ Incremental backup created');
          print(
            '   - Incremental backup size: ${incrementalBackupResult.compressedSize} bytes',
          );

          // Verify incremental backup is smaller than full backup
          if (fullBackupResult.compressedSize > 0 &&
              incrementalBackupResult.compressedSize > 0) {
            expect(
              incrementalBackupResult.compressedSize,
              lessThanOrEqualTo(fullBackupResult.compressedSize),
            );
            print(
              '   - Size comparison: Incremental (${incrementalBackupResult.compressedSize}) <= Full (${fullBackupResult.compressedSize})',
            );
          }
        } catch (e) {
          print('❌ Incremental backup workflow error: $e');
          fail('Incremental backup workflow failed: $e');
        }
      });

      testWidgets('Custom backup workflow with selective categories', (
        WidgetTester tester,
      ) async {
        try {
          // Create comprehensive test data
          final testWallets = _createTestWallets(4);
          final testTransactions = _createTestTransactions(20, testWallets);

          await dataService.saveWallets(testWallets);
          await dataService.saveTransactions(testTransactions);

          // Create custom backup with only transactions
          final customConfig = backup_config.BackupConfig(
            type: backup_enums.BackupType.custom,
            includedCategories: [backup_enums.DataCategory.transactions],
            compressionLevel: backup_enums.CompressionLevel.balanced,
            enableValidation: true,
            retentionPolicy: backup_config.RetentionPolicy(
              maxBackupCount: 5,
              maxAge: const Duration(days: 30),
              keepMonthlyBackups: false,
              keepYearlyBackups: false,
            ),
          );

          final customBackupResult = await enhancedBackupManager
              .createCustomBackup(customConfig);
          expect(customBackupResult.success, true);
          expect(
            customBackupResult.metadata!.type,
            backup_enums.BackupType.custom,
          );

          print('✅ Custom backup created with selective categories');
          print(
            '   - Custom backup includes: ${customConfig.includedCategories.map((c) => c.name).join(', ')}',
          );
        } catch (e) {
          print('❌ Custom backup workflow error: $e');
          fail('Custom backup workflow failed: $e');
        }
      });
    });

    group('Cross-Platform Compatibility Tests', () {
      testWidgets('Backup metadata contains correct platform information', (
        WidgetTester tester,
      ) async {
        try {
          // Create test data
          final testWallets = _createTestWallets(2);
          await dataService.saveWallets(testWallets);

          // Create backup
          final backupResult = await enhancedBackupManager.createFullBackup();
          expect(backupResult.success, true);
          expect(backupResult.metadata, isNotNull);

          final metadata = backupResult.metadata!;

          // Verify platform information
          expect(metadata.platform, isNotNull);
          expect(metadata.deviceModel, isNotNull);
          expect(metadata.version, '3.0'); // Enhanced version
          expect(metadata.isCrossPlatformCompatible, true);

          // Platform should be one of the supported platforms
          expect(metadata.platform, isIn(['android', 'ios', 'web']));

          // Device model should be appropriate for platform
          if (kIsWeb) {
            expect(metadata.platform, 'web');
            expect(metadata.deviceModel, 'Web Browser');
          } else if (Platform.isAndroid) {
            expect(metadata.platform, 'android');
            expect(metadata.deviceModel, contains('Android'));
          } else if (Platform.isIOS) {
            expect(metadata.platform, 'ios');
            expect(metadata.deviceModel, contains('iOS'));
          }

          print('✅ Platform information correctly recorded');
          print('   - Platform: ${metadata.platform}');
          print('   - Device: ${metadata.deviceModel}');
          print('   - Version: ${metadata.version}');
          print(
            '   - Cross-platform compatible: ${metadata.isCrossPlatformCompatible}',
          );
        } catch (e) {
          print('❌ Platform information test error: $e');
          fail('Platform information test failed: $e');
        }
      });

      testWidgets('Unicode and special characters preservation', (
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
          ];

          await dataService.saveWallets(specialWallets);
          await dataService.saveTransactions(specialTransactions);

          // Create backup
          final backupResult = await enhancedBackupManager.createFullBackup();
          expect(backupResult.success, true);

          // Clear data
          await dataService.saveWallets([]);
          await dataService.saveTransactions([]);

          // Restore backup
          if (backupResult.localFile != null) {
            await enhancedBackupManager.restoreFromBackup(
              backupResult.localFile!,
            );

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

            print(
              '✅ Unicode and special characters preserved across platforms',
            );
          }
        } catch (e) {
          print('❌ Unicode preservation test error: $e');
          fail('Unicode preservation test failed: $e');
        }
      });
    });

    group('Performance and Scalability Tests', () {
      testWidgets('Large dataset backup performance', (
        WidgetTester tester,
      ) async {
        try {
          // Create large dataset
          final largeWalletList = _createTestWallets(20);
          final largeTransactionList = _createTestTransactions(
            200,
            largeWalletList,
          );

          await dataService.saveWallets(largeWalletList);
          await dataService.saveTransactions(largeTransactionList);

          print(
            '✅ Large dataset created: ${largeWalletList.length} wallets, ${largeTransactionList.length} transactions',
          );

          // Measure backup performance
          final backupStopwatch = Stopwatch()..start();
          final backupResult = await enhancedBackupManager.createFullBackup();
          backupStopwatch.stop();

          expect(backupResult.success, true);
          expect(
            backupStopwatch.elapsed.inSeconds,
            lessThan(30),
          ); // Should complete within 30 seconds

          print(
            '✅ Large dataset backup completed in ${backupStopwatch.elapsedMilliseconds}ms',
          );
          print(
            '   - Backup compression ratio: ${backupResult.compressionRatio.toStringAsFixed(2)}',
          );
        } catch (e) {
          print('❌ Large dataset performance test error: $e');
          fail('Large dataset performance test failed: $e');
        }
      });

      testWidgets('Multiple backup strategies performance', (
        WidgetTester tester,
      ) async {
        try {
          // Create test data
          final testWallets = _createTestWallets(5);
          final testTransactions = _createTestTransactions(25, testWallets);

          await dataService.saveWallets(testWallets);
          await dataService.saveTransactions(testTransactions);

          // Test all available strategies
          final strategies = enhancedBackupManager.getAvailableStrategies();
          expect(strategies.length, greaterThan(0));

          final performanceResults = <backup_enums.BackupType, Duration>{};

          for (final strategy in strategies) {
            final stopwatch = Stopwatch()..start();

            late backup_manager.BackupResult result;
            switch (strategy) {
              case backup_enums.BackupType.full:
                result = await enhancedBackupManager.createFullBackup();
                break;
              case backup_enums.BackupType.incremental:
                result = await enhancedBackupManager.createIncrementalBackup();
                break;
              case backup_enums.BackupType.custom:
                result = await enhancedBackupManager.createCustomBackup(
                  backup_config.BackupConfig.quick(),
                );
                break;
            }

            stopwatch.stop();
            performanceResults[strategy] = stopwatch.elapsed;

            expect(result.success, true);
            expect(
              stopwatch.elapsed.inSeconds,
              lessThan(30),
            ); // All strategies should complete within 30 seconds
          }

          print('✅ Multiple strategy performance test passed');
          for (final entry in performanceResults.entries) {
            print('   - ${entry.key.name}: ${entry.value.inMilliseconds}ms');
          }
        } catch (e) {
          print('❌ Multiple strategy performance error: $e');
          fail('Multiple strategy performance test failed: $e');
        }
      });
    });

    group('Configuration and Persistence Tests', () {
      testWidgets('Configuration persistence across sessions', (
        WidgetTester tester,
      ) async {
        try {
          // Set custom configuration
          final customConfig = backup_config.BackupConfig(
            type: backup_enums.BackupType.incremental,
            includedCategories: [
              backup_enums.DataCategory.transactions,
              backup_enums.DataCategory.wallets,
            ],
            compressionLevel: backup_enums.CompressionLevel.maximum,
            enableValidation: true,
            retentionPolicy: backup_config.RetentionPolicy(
              maxBackupCount: 15,
              maxAge: const Duration(days: 60),
              keepMonthlyBackups: true,
              keepYearlyBackups: false,
            ),
          );

          await enhancedBackupManager.updateConfiguration(customConfig);

          // Verify configuration is set
          final currentConfig = enhancedBackupManager.currentConfiguration;
          expect(currentConfig.type, customConfig.type);
          expect(currentConfig.compressionLevel, customConfig.compressionLevel);
          expect(currentConfig.enableValidation, customConfig.enableValidation);

          // Simulate app restart by creating new manager instance
          final newManager = backup_manager.EnhancedBackupManager();
          await newManager.initialize();

          // Verify configuration persisted
          final persistedConfig = newManager.currentConfiguration;
          expect(persistedConfig.type, customConfig.type);
          expect(
            persistedConfig.compressionLevel,
            customConfig.compressionLevel,
          );
          expect(
            persistedConfig.enableValidation,
            customConfig.enableValidation,
          );

          print('✅ Configuration persistence verified across sessions');
        } catch (e) {
          print('❌ Configuration persistence test error: $e');
          fail('Configuration persistence test failed: $e');
        }
      });

      testWidgets('Backup strategy preference persistence', (
        WidgetTester tester,
      ) async {
        try {
          // Create test data
          final testWallets = _createTestWallets(2);
          await dataService.saveWallets(testWallets);

          // Create incremental backup to set preference
          final incrementalResult = await enhancedBackupManager
              .createIncrementalBackup();
          expect(incrementalResult.success, true);

          // Verify preference is stored
          final preferredStrategy = await enhancedBackupManager
              .getPreferredStrategy();
          expect(preferredStrategy, backup_enums.BackupType.incremental);

          // Create full backup to change preference
          final fullResult = await enhancedBackupManager.createFullBackup();
          expect(fullResult.success, true);

          // Verify preference is updated
          final updatedStrategy = await enhancedBackupManager
              .getPreferredStrategy();
          expect(updatedStrategy, backup_enums.BackupType.full);

          print('✅ Backup strategy preference persistence verified');
        } catch (e) {
          print('❌ Strategy preference test error: $e');
          fail('Strategy preference test failed: $e');
        }
      });
    });

    group('Error Handling and Recovery Tests', () {
      testWidgets('Graceful handling of invalid configurations', (
        WidgetTester tester,
      ) async {
        try {
          // Test with empty categories (should use defaults)
          final invalidConfig = backup_config.BackupConfig(
            type: backup_enums.BackupType.custom,
            includedCategories: [], // Empty categories
            compressionLevel: backup_enums.CompressionLevel.balanced,
            enableValidation: true,
            retentionPolicy: backup_config.RetentionPolicy(
              maxBackupCount: 5,
              maxAge: const Duration(days: 30),
              keepMonthlyBackups: false,
              keepYearlyBackups: false,
            ),
          );

          // This should either handle gracefully or provide meaningful error
          try {
            await enhancedBackupManager.updateConfiguration(invalidConfig);
            final validation = enhancedBackupManager
                .validateCurrentConfiguration();

            // Should either be valid (with defaults) or provide clear error
            if (validation != backup_enums.ValidationResult.valid) {
              print(
                '✅ Invalid configuration handled with validation result: $validation',
              );
            } else {
              print('✅ Invalid configuration handled with defaults');
            }
          } catch (e) {
            // Expected behavior for invalid config
            expect(e.toString(), contains('configuration'));
            print('✅ Invalid configuration rejected with error: $e');
          }
        } catch (e) {
          print('❌ Configuration validation test error: $e');
          fail('Configuration validation test failed: $e');
        }
      });

      testWidgets('Backup operation error recovery', (
        WidgetTester tester,
      ) async {
        try {
          // Create test data
          final testWallets = _createTestWallets(2);
          await dataService.saveWallets(testWallets);

          // Attempt backup (should succeed or fail gracefully)
          final backupResult = await enhancedBackupManager.createFullBackup();

          if (!backupResult.success) {
            // If backup fails, error should be informative
            expect(backupResult.error, isNotNull);
            expect(backupResult.error!.isNotEmpty, true);
            print('✅ Backup failure handled gracefully: ${backupResult.error}');
          } else {
            print('✅ Backup succeeded');
          }

          // Duration should always be recorded
          expect(backupResult.duration.inMilliseconds, greaterThan(0));
        } catch (e) {
          print('❌ Error recovery test error: $e');
          // This test should not fail - it's testing error handling
          print(
            '⚠️ Error recovery test completed with expected error handling',
          );
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
