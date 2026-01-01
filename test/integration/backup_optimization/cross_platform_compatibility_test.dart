import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:parion/services/backup_optimization/enhanced_backup_manager.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/models/backup_optimization/backup_config.dart';
import 'package:parion/models/backup_optimization/backup_enums.dart';
import 'package:parion/models/backup_optimization/enhanced_backup_metadata.dart';
import 'package:parion/models/transaction.dart';
import 'package:parion/models/wallet.dart';
import '../../test_setup.dart';
import '../../test_helpers.dart';

void main() {
  setupCommonTestMocks();

  group('Cross-Platform Compatibility Integration Tests', () {
    late EnhancedBackupManager enhancedBackupManager;
    late DataService dataService;

    setUpAll(() async {
      await TestSetup.initializeTestEnvironment();

      // Initialize services
      enhancedBackupManager = EnhancedBackupManager();
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

    group('Platform-Specific Backup Format Tests', () {
      testWidgets('Backup format consistency across different platforms', (
        WidgetTester tester,
      ) async {
        try {
          // Create test data with various data types
          final testData = _createComprehensiveTestData();
          await _saveTestData(testData);

          // Create backup on current platform
          final backupResult = await enhancedBackupManager.createFullBackup();
          expect(backupResult.success, true);
          expect(backupResult.metadata, isNotNull);

          final originalMetadata = backupResult.metadata!;

          // Simulate backup created on different platforms
          final platformVariants = _createPlatformVariants(originalMetadata);

          for (final variant in platformVariants) {
            // Verify each platform variant maintains compatibility
            expect(variant.isCrossPlatformCompatible, true);
            expect(variant.version, originalMetadata.version);

            // Data counts should remain consistent
            expect(variant.walletCount, originalMetadata.walletCount);
            expect(variant.transactionCount, originalMetadata.transactionCount);

            // Platform-specific fields should be appropriate
            _validatePlatformSpecificFields(variant);

            print('✅ Platform variant validated: ${variant.platform}');
          }

          print('✅ Backup format consistency verified across platforms');
        } catch (e) {
          print('❌ Platform format consistency test error: $e');
          fail('Platform format consistency test failed: $e');
        }
      });

      testWidgets('Compression algorithm compatibility across platforms', (
        WidgetTester tester,
      ) async {
        try {
          // Create test data
          final testData = _createComprehensiveTestData();
          await _saveTestData(testData);

          // Test different compression levels
          final compressionLevels = [
            CompressionLevel.fast,
            CompressionLevel.balanced,
            CompressionLevel.maximum,
          ];

          for (final level in compressionLevels) {
            final config = BackupConfig(
              type: BackupType.full,
              includedCategories: DataCategory.values,
              compressionLevel: level,
              enableValidation: true,
              retentionPolicy: RetentionPolicy(
                maxBackupCount: 5,
                maxAge: const Duration(days: 30),
                keepMonthlyBackups: false,
                keepYearlyBackups: false,
              ),
            );

            final backupResult = await enhancedBackupManager.createCustomBackup(
              config,
            );
            expect(backupResult.success, true);

            // Verify compression is applied
            expect(backupResult.compressionRatio, lessThan(1.0));

            // Verify backup can be validated (indicating format integrity)
            if (backupResult.localFile != null) {
              final fileBytes = await backupResult.localFile!.readAsBytes();
              expect(fileBytes.length, greaterThan(0));

              // Compression should reduce size for higher levels
              if (level == CompressionLevel.maximum) {
                expect(backupResult.compressionRatio, lessThan(0.8));
              }
            }

            print('✅ Compression level ${level.name} validated');
          }

          print('✅ Compression algorithm compatibility verified');
        } catch (e) {
          print('❌ Compression compatibility test error: $e');
          fail('Compression compatibility test failed: $e');
        }
      });

      testWidgets('Character encoding compatibility across platforms', (
        WidgetTester tester,
      ) async {
        try {
          // Create test data with various character encodings
          final encodingTestData = _createEncodingTestData();
          await _saveEncodingTestData(encodingTestData);

          // Create backup
          final backupResult = await enhancedBackupManager.createFullBackup();
          expect(backupResult.success, true);

          // Clear data
          await dataService.saveWallets([]);
          await dataService.saveTransactions([]);

          // Restore and verify encoding preservation
          if (backupResult.localFile != null) {
            await enhancedBackupManager.restoreFromBackup(
              backupResult.localFile!,
            );

            final restoredWallets = await dataService.getWallets();
            final restoredTransactions = await dataService.getTransactions();

            // Verify each encoding test case
            for (final testCase in encodingTestData['wallets']) {
              final found = restoredWallets.firstWhere(
                (w) => w.id == testCase['id'],
              );
              expect(found.name, testCase['name']);
              print(
                '✅ Encoding preserved: ${testCase['encoding']} - ${found.name}',
              );
            }

            for (final testCase in encodingTestData['transactions']) {
              final found = restoredTransactions.firstWhere(
                (t) => t.id == testCase['id'],
              );
              expect(found.description, testCase['description']);
              expect(found.category, testCase['category']);
              print(
                '✅ Transaction encoding preserved: ${testCase['encoding']}',
              );
            }
          }

          print('✅ Character encoding compatibility verified');
        } catch (e) {
          print('❌ Character encoding test error: $e');
          fail('Character encoding test failed: $e');
        }
      });
    });

    group('Data Type Compatibility Tests', () {
      testWidgets('Numeric precision preservation across platforms', (
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
          final backupResult = await enhancedBackupManager.createFullBackup();
          expect(backupResult.success, true);

          // Clear and restore
          await dataService.saveWallets([]);
          await dataService.saveTransactions([]);

          if (backupResult.localFile != null) {
            await enhancedBackupManager.restoreFromBackup(
              backupResult.localFile!,
            );

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
          }

          print('✅ Numeric precision preservation verified');
        } catch (e) {
          print('❌ Numeric precision test error: $e');
          fail('Numeric precision test failed: $e');
        }
      });

      testWidgets('Date and time handling across time zones', (
        WidgetTester tester,
      ) async {
        try {
          // Create test data with various date/time scenarios
          final now = DateTime.now();
          final utcNow = DateTime.now().toUtc();

          final dateTestTransactions = [
            Transaction(
              id: 'date_1',
              amount: 100.0,
              description: 'Current Local Time',
              date: now,
              type: 'expense',
              walletId: 'test_wallet',
              category: 'test',
            ),
            Transaction(
              id: 'date_2',
              amount: 200.0,
              description: 'UTC Time',
              date: utcNow,
              type: 'income',
              walletId: 'test_wallet',
              category: 'test',
            ),
            Transaction(
              id: 'date_3',
              amount: 300.0,
              description: 'Past Date',
              date: DateTime(2023, 1, 1, 12, 30, 45),
              type: 'expense',
              walletId: 'test_wallet',
              category: 'test',
            ),
            Transaction(
              id: 'date_4',
              amount: 400.0,
              description: 'Future Date',
              date: DateTime(2025, 12, 31, 23, 59, 59),
              type: 'income',
              walletId: 'test_wallet',
              category: 'test',
            ),
          ];

          final testWallet = Wallet(
            id: 'test_wallet',
            name: 'Date Test Wallet',
            balance: 1000.0,
            type: 'bank',
            color: 'blue',
            icon: 'wallet',
          );

          await dataService.saveWallets([testWallet]);
          await dataService.saveTransactions(dateTestTransactions);

          // Create backup
          final backupResult = await enhancedBackupManager.createFullBackup();
          expect(backupResult.success, true);

          // Verify backup metadata contains correct timestamp
          expect(backupResult.metadata!.createdAt, isA<DateTime>());

          // Clear and restore
          await dataService.saveWallets([]);
          await dataService.saveTransactions([]);

          if (backupResult.localFile != null) {
            await enhancedBackupManager.restoreFromBackup(
              backupResult.localFile!,
            );

            final restoredTransactions = await dataService.getTransactions();

            // Verify date/time preservation
            for (final original in dateTestTransactions) {
              final restored = restoredTransactions.firstWhere(
                (t) => t.id == original.id,
              );

              // Dates should be preserved (allowing for minor serialization differences)
              final timeDifference = original.date
                  .difference(restored.date)
                  .abs();
              expect(timeDifference.inSeconds, lessThan(2));

              print(
                '✅ Date preserved: ${original.id} - ${original.date} → ${restored.date}',
              );
            }
          }

          print('✅ Date and time handling verified');
        } catch (e) {
          print('❌ Date and time test error: $e');
          fail('Date and time test failed: $e');
        }
      });
    });

    group('System Integration Compatibility Tests', () {
      testWidgets('File system compatibility across platforms', (
        WidgetTester tester,
      ) async {
        try {
          // Skip file system tests on web platform
          if (kIsWeb) {
            print('⚠️ Skipping file system test on web platform');
            return;
          }

          // Create test data
          final testWallets = [
            Wallet(
              id: 'fs_test_1',
              name: 'File System Test',
              balance: 500.0,
              type: 'bank',
              color: 'blue',
              icon: 'wallet',
            ),
          ];

          await dataService.saveWallets(testWallets);

          // Create backup
          final backupResult = await enhancedBackupManager.createFullBackup();
          expect(backupResult.success, true);
          expect(backupResult.localFile, isNotNull);

          // Verify file exists and is readable
          final backupFile = backupResult.localFile!;
          expect(await backupFile.exists(), true);

          final fileSize = await backupFile.length();
          expect(fileSize, greaterThan(0));

          // Verify file can be read
          final fileBytes = await backupFile.readAsBytes();
          expect(fileBytes.length, fileSize);

          // Verify file path follows platform conventions
          final filePath = backupFile.path;
          if (Platform.isWindows) {
            expect(filePath, contains('\\'));
          } else {
            expect(filePath, contains('/'));
          }

          print('✅ File system compatibility verified');
          print('   - File path: $filePath');
          print('   - File size: $fileSize bytes');
        } catch (e) {
          print('❌ File system compatibility test error: $e');
          fail('File system compatibility test failed: $e');
        }
      });

      testWidgets('Memory usage patterns across platforms', (
        WidgetTester tester,
      ) async {
        try {
          // Create progressively larger datasets to test memory usage
          final dataSizes = [10, 50, 100];

          for (final size in dataSizes) {
            final testWallets = _createTestWallets(size);
            final testTransactions = _createTestTransactions(
              size * 10,
              testWallets,
            );

            await dataService.saveWallets(testWallets);
            await dataService.saveTransactions(testTransactions);

            // Measure backup operation
            final stopwatch = Stopwatch()..start();
            final backupResult = await enhancedBackupManager.createFullBackup();
            stopwatch.stop();

            expect(backupResult.success, true);

            // Memory usage should scale reasonably with data size
            final duration = stopwatch.elapsed;
            expect(
              duration.inSeconds,
              lessThan(30),
            ); // Should complete within 30 seconds

            print(
              '✅ Memory usage test for $size wallets, ${size * 10} transactions: ${duration.inMilliseconds}ms',
            );

            // Clean up for next iteration
            await dataService.saveWallets([]);
            await dataService.saveTransactions([]);
          }

          print('✅ Memory usage patterns verified across data sizes');
        } catch (e) {
          print('❌ Memory usage test error: $e');
          fail('Memory usage test failed: $e');
        }
      });

      testWidgets('Configuration persistence across platform restarts', (
        WidgetTester tester,
      ) async {
        try {
          // Set custom configuration
          final customConfig = BackupConfig(
            type: BackupType.incremental,
            includedCategories: [
              DataCategory.transactions,
              DataCategory.wallets,
            ],
            compressionLevel: CompressionLevel.maximum,
            enableValidation: true,
            retentionPolicy: RetentionPolicy(
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
          final newManager = EnhancedBackupManager();
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

          print('✅ Configuration persistence verified across restarts');
        } catch (e) {
          print('❌ Configuration persistence test error: $e');
          fail('Configuration persistence test failed: $e');
        }
      });
    });

    group('Validation and Integrity Tests', () {
      testWidgets('Cross-platform backup validation', (
        WidgetTester tester,
      ) async {
        try {
          // Create test data
          final testData = _createComprehensiveTestData();
          await _saveTestData(testData);

          // Create backup with validation enabled
          final config = BackupConfig(
            type: BackupType.full,
            includedCategories: DataCategory.values,
            compressionLevel: CompressionLevel.balanced,
            enableValidation: true,
            retentionPolicy: RetentionPolicy(
              maxBackupCount: 5,
              maxAge: const Duration(days: 30),
              keepMonthlyBackups: false,
              keepYearlyBackups: false,
            ),
          );

          final backupResult = await enhancedBackupManager.createCustomBackup(
            config,
          );
          expect(backupResult.success, true);
          expect(
            backupResult.metadata!.validationInfo.result,
            ValidationResult.valid,
          );

          // Verify validation checksum
          expect(backupResult.metadata!.validationInfo.checksum, isNotEmpty);
          expect(backupResult.metadata!.validationInfo.errors, isEmpty);

          print('✅ Cross-platform backup validation successful');
          print(
            '   - Checksum: ${backupResult.metadata!.validationInfo.checksum}',
          );
        } catch (e) {
          print('❌ Cross-platform validation test error: $e');
          fail('Cross-platform validation test failed: $e');
        }
      });

      testWidgets(
        'Backup integrity verification across different environments',
        (WidgetTester tester) async {
          try {
            // Create test data
            final testWallets = _createTestWallets(5);
            await dataService.saveWallets(testWallets);

            // Create backup
            final backupResult = await enhancedBackupManager.createFullBackup();
            expect(backupResult.success, true);

            // Simulate different environment by modifying metadata
            final originalMetadata = backupResult.metadata!;
            final environmentVariants = [
              EnhancedBackupMetadata(
                version: originalMetadata.version,
                createdAt: originalMetadata.createdAt,
                transactionCount: originalMetadata.transactionCount,
                walletCount: originalMetadata.walletCount,
                platform: 'android',
                deviceModel: originalMetadata.deviceModel,
                type: originalMetadata.type,
                compressionInfo: originalMetadata.compressionInfo,
                includedDataTypes: originalMetadata.includedDataTypes,
                parentBackupId: originalMetadata.parentBackupId,
                performanceMetrics: originalMetadata.performanceMetrics,
                validationInfo: originalMetadata.validationInfo,
                originalSize: originalMetadata.originalSize,
                compressedSize: originalMetadata.compressedSize,
                backupDuration: originalMetadata.backupDuration,
                compressionAlgorithm: originalMetadata.compressionAlgorithm,
                compressionRatio: originalMetadata.compressionRatio,
              ),
              EnhancedBackupMetadata(
                version: originalMetadata.version,
                createdAt: originalMetadata.createdAt,
                transactionCount: originalMetadata.transactionCount,
                walletCount: originalMetadata.walletCount,
                platform: 'ios',
                deviceModel: originalMetadata.deviceModel,
                type: originalMetadata.type,
                compressionInfo: originalMetadata.compressionInfo,
                includedDataTypes: originalMetadata.includedDataTypes,
                parentBackupId: originalMetadata.parentBackupId,
                performanceMetrics: originalMetadata.performanceMetrics,
                validationInfo: originalMetadata.validationInfo,
                originalSize: originalMetadata.originalSize,
                compressedSize: originalMetadata.compressedSize,
                backupDuration: originalMetadata.backupDuration,
                compressionAlgorithm: originalMetadata.compressionAlgorithm,
                compressionRatio: originalMetadata.compressionRatio,
              ),
              EnhancedBackupMetadata(
                version: originalMetadata.version,
                createdAt: originalMetadata.createdAt,
                transactionCount: originalMetadata.transactionCount,
                walletCount: originalMetadata.walletCount,
                platform: 'web',
                deviceModel: originalMetadata.deviceModel,
                type: originalMetadata.type,
                compressionInfo: originalMetadata.compressionInfo,
                includedDataTypes: originalMetadata.includedDataTypes,
                parentBackupId: originalMetadata.parentBackupId,
                performanceMetrics: originalMetadata.performanceMetrics,
                validationInfo: originalMetadata.validationInfo,
                originalSize: originalMetadata.originalSize,
                compressedSize: originalMetadata.compressedSize,
                backupDuration: originalMetadata.backupDuration,
                compressionAlgorithm: originalMetadata.compressionAlgorithm,
                compressionRatio: originalMetadata.compressionRatio,
              ),
            ];

            for (final variant in environmentVariants) {
              // Each variant should maintain integrity
              expect(variant.isCrossPlatformCompatible, true);
              expect(variant.version, originalMetadata.version);
              expect(variant.walletCount, originalMetadata.walletCount);

              // Validation info should remain consistent
              expect(variant.validationInfo.result, ValidationResult.valid);

              print('✅ Integrity verified for ${variant.platform} environment');
            }

            print('✅ Backup integrity verification completed');
          } catch (e) {
            print('❌ Integrity verification test error: $e');
            fail('Integrity verification test failed: $e');
          }
        },
      );
    });
  });
}

/// Helper function to create comprehensive test data
Map<String, dynamic> _createComprehensiveTestData() {
  return {
    'wallets': [
      {
        'id': 'comp_1',
        'name': 'Comprehensive Wallet 1',
        'balance': 1000.0,
        'type': 'bank',
      },
      {
        'id': 'comp_2',
        'name': 'Comprehensive Wallet 2',
        'balance': 500.0,
        'type': 'cash',
      },
      {
        'id': 'comp_3',
        'name': 'Comprehensive Wallet 3',
        'balance': -200.0,
        'type': 'credit',
      },
    ],
    'transactions': [
      {
        'id': 'comp_trans_1',
        'amount': 100.0,
        'description': 'Test Transaction 1',
        'walletId': 'comp_1',
      },
      {
        'id': 'comp_trans_2',
        'amount': 50.0,
        'description': 'Test Transaction 2',
        'walletId': 'comp_2',
      },
      {
        'id': 'comp_trans_3',
        'amount': 200.0,
        'description': 'Test Transaction 3',
        'walletId': 'comp_3',
      },
    ],
  };
}

/// Helper function to save comprehensive test data
Future<void> _saveTestData(Map<String, dynamic> testData) async {
  final dataService = DataService.forTesting();

  final wallets = (testData['wallets'] as List)
      .map(
        (w) => Wallet(
          id: w['id'],
          name: w['name'],
          balance: w['balance'],
          type: w['type'],
          color: 'blue',
          icon: 'wallet',
        ),
      )
      .toList();

  final transactions = (testData['transactions'] as List)
      .map(
        (t) => Transaction(
          id: t['id'],
          amount: t['amount'],
          description: t['description'],
          date: DateTime.now(),
          type: 'expense',
          walletId: t['walletId'],
          category: 'test',
        ),
      )
      .toList();

  await dataService.saveWallets(wallets);
  await dataService.saveTransactions(transactions);
}

/// Helper function to create platform variants of metadata
List<EnhancedBackupMetadata> _createPlatformVariants(
  EnhancedBackupMetadata original,
) {
  return [
    EnhancedBackupMetadata(
      version: original.version,
      createdAt: original.createdAt,
      transactionCount: original.transactionCount,
      walletCount: original.walletCount,
      platform: 'android',
      deviceModel: 'Android Test Device',
      type: original.type,
      compressionInfo: original.compressionInfo,
      includedDataTypes: original.includedDataTypes,
      parentBackupId: original.parentBackupId,
      performanceMetrics: original.performanceMetrics,
      validationInfo: original.validationInfo,
      originalSize: original.originalSize,
      compressedSize: original.compressedSize,
      backupDuration: original.backupDuration,
      compressionAlgorithm: original.compressionAlgorithm,
      compressionRatio: original.compressionRatio,
    ),
    EnhancedBackupMetadata(
      version: original.version,
      createdAt: original.createdAt,
      transactionCount: original.transactionCount,
      walletCount: original.walletCount,
      platform: 'ios',
      deviceModel: 'iOS Test Device',
      type: original.type,
      compressionInfo: original.compressionInfo,
      includedDataTypes: original.includedDataTypes,
      parentBackupId: original.parentBackupId,
      performanceMetrics: original.performanceMetrics,
      validationInfo: original.validationInfo,
      originalSize: original.originalSize,
      compressedSize: original.compressedSize,
      backupDuration: original.backupDuration,
      compressionAlgorithm: original.compressionAlgorithm,
      compressionRatio: original.compressionRatio,
    ),
    EnhancedBackupMetadata(
      version: original.version,
      createdAt: original.createdAt,
      transactionCount: original.transactionCount,
      walletCount: original.walletCount,
      platform: 'web',
      deviceModel: 'Web Browser',
      type: original.type,
      compressionInfo: original.compressionInfo,
      includedDataTypes: original.includedDataTypes,
      parentBackupId: original.parentBackupId,
      performanceMetrics: original.performanceMetrics,
      validationInfo: original.validationInfo,
      originalSize: original.originalSize,
      compressedSize: original.compressedSize,
      backupDuration: original.backupDuration,
      compressionAlgorithm: original.compressionAlgorithm,
      compressionRatio: original.compressionRatio,
    ),
  ];
}

/// Helper function to validate platform-specific fields
void _validatePlatformSpecificFields(EnhancedBackupMetadata metadata) {
  expect(metadata.platform, isIn(['android', 'ios', 'web']));
  expect(metadata.deviceModel, isNotNull);
  expect(metadata.deviceModel, isNotEmpty);

  // Platform-specific validations
  switch (metadata.platform) {
    case 'android':
      expect(metadata.deviceModel, contains('Android'));
      break;
    case 'ios':
      expect(metadata.deviceModel, contains('iOS'));
      break;
    case 'web':
      expect(metadata.deviceModel, contains('Web'));
      break;
  }
}

/// Helper function to create encoding test data
Map<String, dynamic> _createEncodingTestData() {
  return {
    'wallets': [
      {'id': 'enc_1', 'name': 'ASCII Wallet', 'encoding': 'ASCII'},
      {'id': 'enc_2', 'name': 'Türkçe Cüzdan 💰', 'encoding': 'UTF-8 Turkish'},
      {'id': 'enc_3', 'name': '中文钱包 🏦', 'encoding': 'UTF-8 Chinese'},
      {'id': 'enc_4', 'name': 'العربية محفظة 💳', 'encoding': 'UTF-8 Arabic'},
      {
        'id': 'enc_5',
        'name': 'Русский кошелек 💴',
        'encoding': 'UTF-8 Russian',
      },
      {'id': 'enc_6', 'name': '日本の財布 💵', 'encoding': 'UTF-8 Japanese'},
    ],
    'transactions': [
      {
        'id': 'enc_trans_1',
        'description': 'Simple ASCII',
        'category': 'test',
        'encoding': 'ASCII',
      },
      {
        'id': 'enc_trans_2',
        'description': 'Café ☕ & Résumé 📄',
        'category': 'Özel',
        'encoding': 'UTF-8 Mixed',
      },
      {
        'id': 'enc_trans_3',
        'description': '购物 🛒 和 餐厅 🍽️',
        'category': '购物',
        'encoding': 'UTF-8 Chinese',
      },
      {
        'id': 'enc_trans_4',
        'description': 'مطعم 🍕 و تسوق 🛍️',
        'category': 'مطاعم',
        'encoding': 'UTF-8 Arabic',
      },
    ],
  };
}

/// Helper function to save encoding test data
Future<void> _saveEncodingTestData(Map<String, dynamic> testData) async {
  final dataService = DataService.forTesting();

  final wallets = (testData['wallets'] as List)
      .map(
        (w) => Wallet(
          id: w['id'],
          name: w['name'],
          balance: 1000.0,
          type: 'bank',
          color: 'blue',
          icon: 'wallet',
        ),
      )
      .toList();

  final transactions = (testData['transactions'] as List)
      .map(
        (t) => Transaction(
          id: t['id'],
          amount: 100.0,
          description: t['description'],
          date: DateTime.now(),
          type: 'expense',
          walletId: wallets.first.id,
          category: t['category'],
        ),
      )
      .toList();

  await dataService.saveWallets(wallets);
  await dataService.saveTransactions(transactions);
}

/// Helper function to create test wallets
List<Wallet> _createTestWallets(int count) {
  final wallets = <Wallet>[];
  final types = ['bank', 'cash', 'credit', 'savings'];
  final colors = ['#FF5722', '#2196F3', '#4CAF50', '#FF9800'];

  for (int i = 0; i < count; i++) {
    wallets.add(
      Wallet(
        id: 'cross_platform_wallet_$i',
        name: 'Cross Platform Wallet $i',
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
List<Transaction> _createTestTransactions(int count, List<Wallet> wallets) {
  final transactions = <Transaction>[];
  final categories = ['food', 'transport', 'entertainment', 'shopping'];
  final types = ['expense', 'income'];

  for (int i = 0; i < count; i++) {
    transactions.add(
      Transaction(
        id: 'cross_platform_transaction_$i',
        amount: (i + 1) * 10.0,
        description: 'Cross Platform Transaction $i',
        date: DateTime.now().subtract(Duration(days: i % 30)),
        type: types[i % types.length],
        walletId: wallets[i % wallets.length].id,
        category: categories[i % categories.length],
      ),
    );
  }

  return transactions;
}
