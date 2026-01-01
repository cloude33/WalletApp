import 'package:flutter_test/flutter_test.dart';

import 'package:parion/models/backup_optimization/backup_optimization_models.dart';

void main() {
  group('Backup Strategies Unit Tests', () {
    late FullBackupStrategy fullStrategy;
    late CustomBackupStrategy customStrategy;
    late Map<String, dynamic> sampleData;

    setUp(() {
      fullStrategy = FullBackupStrategy();
      customStrategy = CustomBackupStrategy();

      // Create comprehensive sample data for testing
      sampleData = {
        'transactions': [
          {'id': '1', 'amount': 100.0, 'description': 'Test transaction 1'},
          {'id': '2', 'amount': 200.0, 'description': 'Test transaction 2'},
          {'id': '3', 'amount': 300.0, 'description': 'Test transaction 3'},
        ],
        'wallets': [
          {'id': '1', 'name': 'Main Wallet', 'balance': 1000.0},
          {'id': '2', 'name': 'Savings Wallet', 'balance': 5000.0},
        ],
        'creditCards': [
          {'id': '1', 'name': 'Credit Card 1', 'limit': 10000.0},
          {'id': '2', 'name': 'Credit Card 2', 'limit': 5000.0},
        ],
        'billTemplates': [
          {'id': '1', 'name': 'Electricity Bill', 'amount': 150.0},
        ],
        'goals': [
          {'id': '1', 'name': 'Vacation Fund', 'target': 2000.0},
        ],
        'settings': {'currency': 'TRY', 'theme': 'dark', 'notifications': true},
        'userImages': [
          {'id': '1', 'path': '/path/to/avatar.jpg'},
        ],
        'recurringTransactions': [
          {'id': '1', 'description': 'Monthly Salary', 'amount': 5000.0},
        ],
        'metadata': {
          'version': '1.0',
          'created': DateTime.now().toIso8601String(),
        },
      };
    });

    group('Quick Backup Strategy Tests (Requirement 4.1)', () {
      test('should create quick backup with only critical data', () async {
        // Arrange
        final quickConfig = BackupConfig.quick();

        // Act
        final result = await customStrategy.createBackup(
          sampleData,
          quickConfig,
        );

        // Assert
        expect(result.type, equals(BackupType.custom));
        expect(result.data, isNotNull);
        expect(result.checksum, isNotEmpty);
        expect(result.originalSize, greaterThan(0));
        expect(result.compressedSize, greaterThan(0));

        // Verify only critical data categories are included in config
        final expectedCriticalCategories = [
          DataCategory.transactions,
          DataCategory.wallets,
          DataCategory.creditCards,
        ];

        expect(
          quickConfig.includedCategories,
          equals(expectedCriticalCategories),
        );

        // Verify compression level is fast for quick backup
        expect(quickConfig.compressionLevel, equals(CompressionLevel.fast));

        // Verify backup is compressed
        expect(result.compressedSize, lessThan(result.originalSize));
      });

      test(
        'should exclude non-critical data from quick backup config',
        () async {
          // Arrange
          final quickConfig = BackupConfig.quick();

          // Act & Assert
          // Verify non-critical categories are NOT included in quick config
          final nonCriticalCategories = [
            DataCategory.bills,
            DataCategory.goals,
            DataCategory.settings,
            DataCategory.userImages,
            DataCategory.recurringTransactions,
          ];

          for (final category in nonCriticalCategories) {
            expect(quickConfig.includedCategories, isNot(contains(category)));
          }
        },
      );

      test('should estimate smaller size for quick backup', () async {
        // Arrange
        final quickConfig = BackupConfig.quick();
        final fullConfig = BackupConfig.full();

        // Act
        final quickSize = await customStrategy.estimateBackupSize(
          sampleData,
          quickConfig,
        );
        final fullSize = await fullStrategy.estimateBackupSize(
          sampleData,
          fullConfig,
        );

        // Assert
        expect(quickSize, greaterThan(0));
        expect(fullSize, greaterThan(0));

        // Quick backup should be smaller due to fewer categories
        expect(quickSize, lessThan(fullSize));
      });
    });

    group('Full Backup Strategy Tests (Requirement 4.2)', () {
      test('should create full backup with all data and settings', () async {
        // Arrange
        final fullConfig = BackupConfig.full();

        // Act
        final result = await fullStrategy.createBackup(sampleData, fullConfig);

        // Assert
        expect(result.type, equals(BackupType.full));
        expect(result.data, isNotNull);
        expect(result.checksum, isNotEmpty);
        expect(result.originalSize, greaterThan(0));
        expect(result.compressedSize, greaterThan(0));

        // Verify all data categories are included in config
        expect(fullConfig.includedCategories, equals(DataCategory.values));

        // Verify maximum compression is used for full backup
        expect(fullConfig.compressionLevel, equals(CompressionLevel.maximum));

        // Verify backup contains comprehensive data
        expect(result.originalSize, greaterThan(0));
        expect(result.compressedSize, greaterThan(0));
      });

      test(
        'should include all data categories in full backup config',
        () async {
          // Arrange
          final fullConfig = BackupConfig.full();

          // Act & Assert
          // Verify every data category is included
          for (final category in DataCategory.values) {
            expect(fullConfig.includedCategories, contains(category));
          }
        },
      );

      test('should include settings in full backup config', () async {
        // Arrange
        final fullConfig = BackupConfig.full();

        // Act & Assert
        expect(fullConfig.includedCategories, contains(DataCategory.settings));
      });

      test('should include user images in full backup config', () async {
        // Arrange
        final fullConfig = BackupConfig.full();

        // Act & Assert
        expect(
          fullConfig.includedCategories,
          contains(DataCategory.userImages),
        );
      });

      test('should use maximum compression for full backup', () async {
        // Arrange
        final fullConfig = BackupConfig.full();

        // Act
        final result = await customStrategy.createBackup(
          sampleData,
          fullConfig,
        );

        // Assert
        expect(fullConfig.compressionLevel, equals(CompressionLevel.maximum));

        // Verify compression ratio is applied
        expect(result.compressedSize, lessThan(result.originalSize));
      });

      test('should restore full backup data correctly', () async {
        // Arrange
        final fullConfig = BackupConfig.full();
        final originalPackage = await fullStrategy.createBackup(
          sampleData,
          fullConfig,
        );

        // Act
        final restoredData = await fullStrategy.restoreBackup(originalPackage);

        // Assert
        expect(restoredData, isNotNull);
        expect(restoredData, isA<Map<String, dynamic>>());

        // Verify key data is present
        expect(restoredData.containsKey('transactions'), isTrue);
        expect(restoredData.containsKey('wallets'), isTrue);
        expect(restoredData.containsKey('settings'), isTrue);
      });
    });

    group('Strategy Comparison Tests', () {
      test(
        'should show size difference between quick and full backup',
        () async {
          // Arrange
          final quickConfig = BackupConfig.quick();
          final fullConfig = BackupConfig.full();

          // Act
          final quickSize = await customStrategy.estimateBackupSize(
            sampleData,
            quickConfig,
          );
          final fullSize = await fullStrategy.estimateBackupSize(
            sampleData,
            fullConfig,
          );

          // Assert
          expect(quickSize, greaterThan(0));
          expect(fullSize, greaterThan(0));

          // Full backup should be larger than quick backup
          expect(fullSize, greaterThan(quickSize));
        },
      );

      test('should validate backup configurations', () async {
        // Arrange
        final quickConfig = BackupConfig.quick();
        final fullConfig = BackupConfig.full();

        // Act & Assert
        expect(quickConfig.type, equals(BackupType.custom));
        expect(fullConfig.type, equals(BackupType.full));

        expect(quickConfig.enableValidation, isTrue);
        expect(fullConfig.enableValidation, isTrue);

        expect(
          quickConfig.includedCategories.length,
          lessThan(fullConfig.includedCategories.length),
        );
      });

      test('should handle strategy factory correctly', () async {
        // Act
        final fullStrategy = BackupStrategyFactory.getStrategy(BackupType.full);
        final customStrategy = BackupStrategyFactory.getStrategy(
          BackupType.custom,
        );

        // Assert
        expect(fullStrategy, isA<FullBackupStrategy>());
        expect(customStrategy, isA<CustomBackupStrategy>());
        expect(fullStrategy.type, equals(BackupType.full));
        expect(customStrategy.type, equals(BackupType.custom));
      });

      test('should verify strategy availability', () async {
        // Act & Assert
        expect(BackupStrategyFactory.hasStrategy(BackupType.full), isTrue);
        expect(BackupStrategyFactory.hasStrategy(BackupType.custom), isTrue);
        expect(
          BackupStrategyFactory.hasStrategy(BackupType.incremental),
          isTrue,
        );

        final allStrategies = BackupStrategyFactory.getAllStrategies();
        expect(allStrategies.length, equals(3));
      });
    });

    group('Error Handling Tests', () {
      test('should handle empty backup configuration gracefully', () async {
        // Arrange
        final emptyConfig = BackupConfig(
          type: BackupType.custom,
          includedCategories: [], // Empty categories
          compressionLevel: CompressionLevel.fast,
          enableValidation: true,
          retentionPolicy: RetentionPolicy.minimal(),
        );

        // Act
        final result = await customStrategy.createBackup(
          sampleData,
          emptyConfig,
        );

        // Assert
        // Should still succeed but with minimal data (metadata only)
        expect(result.type, equals(BackupType.custom));
        expect(result.originalSize, greaterThanOrEqualTo(0));
      });

      test('should validate backup package has required fields', () async {
        // Arrange
        final fullConfig = BackupConfig.full();

        // Act
        final result = await fullStrategy.createBackup(sampleData, fullConfig);

        // Assert
        expect(result.id, isNotEmpty);
        expect(result.type, equals(BackupType.full));
        expect(result.createdAt, isNotNull);
        expect(result.data, isNotNull);
        expect(result.checksum, isNotEmpty);
        expect(result.originalSize, greaterThanOrEqualTo(0));
        expect(result.compressedSize, greaterThanOrEqualTo(0));
      });

      test('should throw error for wrong backup type in restore', () async {
        // Arrange
        final fullConfig = BackupConfig.full();
        final package = await fullStrategy.createBackup(sampleData, fullConfig);

        // Modify package type to test error handling
        final wrongTypePackage = BackupPackage(
          id: package.id,
          type: BackupType.incremental, // Wrong type
          createdAt: package.createdAt,
          data: package.data,
          checksum: package.checksum,
          originalSize: package.originalSize,
          compressedSize: package.compressedSize,
        );

        // Act & Assert
        expect(
          () => fullStrategy.restoreBackup(wrongTypePackage),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle strategy factory errors', () async {
        // Act & Assert
        expect(
          () => BackupStrategyFactory.getStrategy(BackupType.values.first),
          returnsNormally,
        );
      });
    });
  });
}
