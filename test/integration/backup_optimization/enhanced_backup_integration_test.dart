import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:parion/services/backup_service.dart';
import 'package:parion/services/backup_optimization/enhanced_backup_manager.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/models/backup_optimization/backup_config.dart';
import 'package:parion/models/backup_optimization/backup_enums.dart'
    hide BackupResult;
import 'package:parion/models/transaction.dart';
import 'package:parion/models/wallet.dart';
import '../../test_setup.dart';
import '../../test_helpers.dart';



void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupCommonTestMocks();

  group('Enhanced Backup System Integration Tests', () {
    late BackupService originalBackupService;
    late EnhancedBackupManager enhancedBackupManager;
    late DataService dataService;

    setUpAll(() async {
      await TestSetup.initializeTestEnvironment();

      // Initialize services
      originalBackupService = BackupService();
      enhancedBackupManager = EnhancedBackupManager();
      dataService = DataService();

      await dataService.init();
      await originalBackupService.loadSettings();
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

    group('Compatibility with Current Backup Workflows', () {
      test(
        'Enhanced backup manager should extend original backup service',
        () async {
          // Test that enhanced manager is compatible with original service
          expect(enhancedBackupManager, isA<BackupService>());

          // Test that original methods are still available
          expect(enhancedBackupManager.cloudBackupStatus, isNotNull);
          expect(enhancedBackupManager.autoCloudBackupEnabled, isNotNull);
          expect(enhancedBackupManager.lastCloudBackupDate, isNotNull);

          print('✅ Enhanced backup manager extends original service correctly');
        },
      );

      test(
        'Original backup methods should work with enhanced manager',
        () async {
          try {
            // Test original backup creation
            final backupData = await enhancedBackupManager.createBackupRaw();
            expect(backupData, isNotNull);
            expect(backupData.length, greaterThan(0));

            // Test metadata extraction
            final metadata = await enhancedBackupManager
                .getBackupMetadataFromBytes(backupData);
            expect(metadata, isNotNull);
            expect(metadata!.version, isNotNull);

            print('✅ Original backup methods work with enhanced manager');
          } catch (e) {
            print('❌ Original backup method compatibility error: $e');
            fail('Original backup methods should work: $e');
          }
        },
      );

      test(
        'Enhanced backup should be compatible with original restore',
        () async {
          try {
            // Create test data
            final testWallet = Wallet(
              id: 'test_wallet_${DateTime.now().millisecondsSinceEpoch}',
              name: 'Integration Test Wallet',
              balance: 500.0,
              type: 'bank',
              color: 'green',
              icon: 'wallet',
            );

            final testTransaction = Transaction(
              id: 'test_transaction_${DateTime.now().millisecondsSinceEpoch}',
              amount: 100.0,
              description: 'Integration Test Transaction',
              date: DateTime.now(),
              type: 'expense',
              walletId: testWallet.id,
              category: 'test_category',
            );

            // Save test data
            await dataService.saveWallets([testWallet]);
            await dataService.saveTransactions([testTransaction]);

            // Create enhanced backup
            final backupResult = await enhancedBackupManager.createFullBackup();
            expect(backupResult.success, true);
            expect(backupResult.metadata, isNotNull);

            // Clear data
            await dataService.saveWallets([]);
            await dataService.saveTransactions([]);

            // Verify data is cleared
            final clearedWallets = await dataService.getWallets();
            final clearedTransactions = await dataService.getTransactions();
            expect(clearedWallets.length, 0);
            expect(clearedTransactions.length, 0);

            // Test that enhanced backup can be restored using original method
            if (backupResult.localFile != null) {
              await enhancedBackupManager.restoreFromBackup(
                backupResult.localFile!,
              );

              // Verify data is restored
              final restoredWallets = await dataService.getWallets();
              final restoredTransactions = await dataService.getTransactions();

              expect(restoredWallets.length, greaterThan(0));
              expect(restoredTransactions.length, greaterThan(0));

              // Find our test data
              final foundWallet = restoredWallets.firstWhere(
                (w) => w.id == testWallet.id,
                orElse: () => throw Exception('Test wallet not found'),
              );
              final foundTransaction = restoredTransactions.firstWhere(
                (t) => t.id == testTransaction.id,
                orElse: () => throw Exception('Test transaction not found'),
              );

              expect(foundWallet.name, testWallet.name);
              expect(foundTransaction.description, testTransaction.description);
            }

            print('✅ Enhanced backup is compatible with original restore');
          } catch (e) {
            print('❌ Enhanced backup compatibility error: $e');
            fail(
              'Enhanced backup should be compatible with original restore: $e',
            );
          }
        },
      );
    });

    group('Data Migration from Old Backup Format', () {
      test('Should handle version 2.0 backup format', () async {
        try {
          // Create a version 2.0 backup using original service
          final originalBackupData = await originalBackupService
              .createBackupRaw();

          // Extract metadata to verify it's version 2.0
          final metadata = await originalBackupService
              .getBackupMetadataFromBytes(originalBackupData);
          expect(metadata, isNotNull);
          expect(metadata!.version, '2.0');

          // Enhanced manager should be able to handle this format
          final enhancedMetadata = await enhancedBackupManager
              .getBackupMetadataFromBytes(originalBackupData);
          expect(enhancedMetadata, isNotNull);
          expect(enhancedMetadata!.version, '2.0');

          print('✅ Enhanced manager handles version 2.0 backup format');
        } catch (e) {
          print('❌ Version 2.0 backup handling error: $e');
          fail('Should handle version 2.0 backup format: $e');
        }
      });

      test('Should migrate backup preferences correctly', () async {
        try {
          // Set original backup preferences
          await originalBackupService.enableAutoCloudBackup(true);

          // Need to reload settings for the enhanced manager to see the change in shared_preferences
          await enhancedBackupManager.loadSettings();

          // Enhanced manager should inherit these preferences
          expect(enhancedBackupManager.autoCloudBackupEnabled.value, true);

          // Test preference migration
          final preferredStrategy = await enhancedBackupManager
              .getPreferredStrategy();
          expect(preferredStrategy, isA<BackupType>());

          print('✅ Backup preferences migrated correctly');
        } catch (e) {
          print('❌ Preference migration error: $e');
          fail('Should migrate backup preferences correctly: $e');
        }
      });

      test('Should handle cross-platform backup compatibility', () async {
        try {
          // Create backup with enhanced manager
          final backupResult = await enhancedBackupManager.createFullBackup();
          expect(backupResult.success, true);
          expect(backupResult.metadata, isNotNull);

          // Verify cross-platform compatibility
          final metadata = backupResult.metadata!;
          expect(metadata.isCrossPlatformCompatible, true);
          expect(metadata.version, '3.0'); // Enhanced version

          // Verify platform information is preserved
          expect(metadata.platform, isNotNull);
          expect(metadata.deviceModel, isNotNull);

          print('✅ Cross-platform backup compatibility maintained');
        } catch (e) {
          print('❌ Cross-platform compatibility error: $e');
          fail('Should handle cross-platform backup compatibility: $e');
        }
      });
    });

    group('Performance Testing with Large Datasets', () {
      test('Should handle large transaction datasets efficiently', () async {
        try {
          // Create large dataset
          final largeWalletList = <Wallet>[];
          final largeTransactionList = <Transaction>[];

          // Create 100 wallets
          for (int i = 0; i < 100; i++) {
            largeWalletList.add(
              Wallet(
                id: 'wallet_$i',
                name: 'Wallet $i',
                balance: (i * 100.0),
                type: i % 2 == 0 ? 'bank' : 'cash',
                color: '#${(i * 123456).toRadixString(16).padLeft(6, '0')}',
                icon: 'wallet',
              ),
            );
          }

          // Create 1000 transactions
          for (int i = 0; i < 1000; i++) {
            largeTransactionList.add(
              Transaction(
                id: 'transaction_$i',
                amount: (i * 10.0) + 50.0,
                description: 'Large Dataset Transaction $i',
                date: DateTime.now().subtract(Duration(days: i % 365)),
                type: i % 2 == 0 ? 'expense' : 'income',
                walletId: 'wallet_${i % 100}',
                category: 'category_${i % 10}',
              ),
            );
          }

          // Save large dataset
          await dataService.saveWallets(largeWalletList);
          await dataService.saveTransactions(largeTransactionList);

          // Measure backup performance
          final stopwatch = Stopwatch()..start();

          // Test full backup with large dataset
          final fullBackupResult = await enhancedBackupManager
              .createFullBackup();
          expect(fullBackupResult.success, true);

          stopwatch.stop();
          final fullBackupDuration = stopwatch.elapsed;

          // Test incremental backup performance
          stopwatch.reset();
          stopwatch.start();

          final incrementalBackupResult = await enhancedBackupManager
              .createIncrementalBackup();
          expect(incrementalBackupResult.success, true);

          stopwatch.stop();
          final incrementalBackupDuration = stopwatch.elapsed;

          // Performance assertions
          expect(
            fullBackupDuration.inSeconds,
            lessThan(30),
          ); // Should complete within 30 seconds
          expect(
            incrementalBackupDuration.inSeconds,
            lessThan(15),
          ); // Incremental should be faster

          // Verify compression efficiency
          expect(
            fullBackupResult.compressionRatio,
            lessThan(1.0),
          ); // Should be compressed
          expect(incrementalBackupResult.compressionRatio, lessThan(1.0));

          print('✅ Large dataset performance test passed');
          print(
            '   - Full backup duration: ${fullBackupDuration.inMilliseconds}ms',
          );
          print(
            '   - Incremental backup duration: ${incrementalBackupDuration.inMilliseconds}ms',
          );
          print(
            '   - Full backup compression ratio: ${fullBackupResult.compressionRatio.toStringAsFixed(2)}',
          );
          print(
            '   - Incremental backup compression ratio: ${incrementalBackupResult.compressionRatio.toStringAsFixed(2)}',
          );
        } catch (e) {
          print('❌ Large dataset performance error: $e');
          fail('Should handle large datasets efficiently: $e');
        }
      });

      test(
        'Should maintain performance with multiple backup strategies',
        () async {
          try {
            // Test all available strategies
            final strategies = enhancedBackupManager.getAvailableStrategies();
            expect(strategies.length, greaterThan(0));

            final performanceResults = <BackupType, Duration>{};

            for (final strategy in strategies) {
              final stopwatch = Stopwatch()..start();

              BackupResult result;
              switch (strategy) {
                case BackupType.full:
                  result = await enhancedBackupManager.createFullBackup();
                  break;
                case BackupType.incremental:
                  result = await enhancedBackupManager
                      .createIncrementalBackup();
                  break;
                case BackupType.custom:
                  result = await enhancedBackupManager.createCustomBackup(
                    BackupConfig.quick(),
                  );
                  break;
              }

              stopwatch.stop();
              performanceResults[strategy] = stopwatch.elapsed;

              expect(result.success, true);
              expect(
                stopwatch.elapsed.inSeconds,
                lessThan(60),
              ); // All strategies should complete within 60 seconds
            }

            print('✅ Multiple strategy performance test passed');
            for (final entry in performanceResults.entries) {
              print('   - ${entry.key.name}: ${entry.value.inMilliseconds}ms');
            }
          } catch (e) {
            print('❌ Multiple strategy performance error: $e');
            fail('Should maintain performance with multiple strategies: $e');
          }
        },
      );
    });

    group('System Integration Validation', () {
      test('Should integrate with existing Google Drive service', () async {
        try {
          // Test that enhanced manager uses the same Google Drive service
          expect(enhancedBackupManager.cloudBackupStatus, isNotNull);

          // Test cloud backup status integration
          enhancedBackupManager.cloudBackupStatus.value =
              CloudBackupStatus.uploading;
          expect(
            enhancedBackupManager.cloudBackupStatus.value,
            CloudBackupStatus.uploading,
          );

          // Test status text integration
          final statusText = enhancedBackupManager.getCloudBackupStatusText();
          expect(statusText, isNotNull);
          expect(statusText.isNotEmpty, true);

          print('✅ Google Drive service integration validated');
        } catch (e) {
          print('❌ Google Drive integration error: $e');
          fail('Should integrate with existing Google Drive service: $e');
        }
      });

      test('Should maintain data service compatibility', () async {
        try {
          // Test that enhanced manager works with existing data service
          final wallets = await dataService.getWallets();
          final transactions = await dataService.getTransactions();

          // Enhanced manager should be able to gather this data
          final backupResult = await enhancedBackupManager.createFullBackup();
          expect(backupResult.success, true);

          // Verify that backup contains the expected data
          expect(backupResult.metadata, isNotNull);
          expect(backupResult.metadata!.walletCount, wallets.length);
          expect(backupResult.metadata!.transactionCount, transactions.length);

          print('✅ Data service compatibility maintained');
        } catch (e) {
          print('❌ Data service compatibility error: $e');
          fail('Should maintain data service compatibility: $e');
        }
      });

      test('Should handle configuration persistence correctly', () async {
        try {
          // Test configuration management
          final config = BackupConfig(
            type: BackupType.incremental,
            includedCategories: [
              DataCategory.transactions,
              DataCategory.wallets,
            ],
            compressionLevel: CompressionLevel.balanced,
            enableValidation: true,
            retentionPolicy: RetentionPolicy(
              maxBackupCount: 10,
              maxAge: const Duration(days: 30),
              keepMonthlyBackups: true,
              keepYearlyBackups: false,
            ),
          );

          // Update configuration
          await enhancedBackupManager.updateConfiguration(config);

          // Verify configuration is persisted
          final retrievedConfig = enhancedBackupManager.currentConfiguration;
          expect(retrievedConfig.type, config.type);
          expect(retrievedConfig.compressionLevel, config.compressionLevel);
          expect(retrievedConfig.enableValidation, config.enableValidation);

          // Test configuration validation
          final validation = enhancedBackupManager
              .validateCurrentConfiguration();
          expect(validation == ValidationResult.valid, true);

          print('✅ Configuration persistence works correctly');
        } catch (e) {
          print('❌ Configuration persistence error: $e');
          fail('Should handle configuration persistence correctly: $e');
        }
      });
    });
  });
}
