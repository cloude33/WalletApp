import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/backup_optimization/validation_service.dart';
import 'package:parion/services/backup_optimization/integrity_validator.dart';
import 'package:parion/models/backup_optimization/enhanced_backup_metadata.dart';
import 'package:parion/models/backup_optimization/backup_enums.dart' as enums;

void main() {
  group('ValidationService', () {
    late ValidationService validationService;

    setUp(() {
      validationService = ValidationService();
    });

    test('should calculate checksum correctly', () async {
      // Arrange
      final testData = [1, 2, 3, 4, 5];

      // Act
      final checksum = await validationService.calculateChecksum(testData);

      // Assert
      expect(checksum, isNotEmpty);
      expect(
        checksum.length,
        equals(64),
      ); // SHA-256 produces 64 character hex string
    });

    test('should validate correct backup package', () async {
      // Arrange
      final testData = [1, 2, 3, 4, 5];
      final checksum = await validationService.calculateChecksum(testData);

      final metadata = EnhancedBackupMetadata(
        version: '3.0',
        createdAt: DateTime.now(),
        transactionCount: 1,
        walletCount: 1,
        type: enums.BackupType.full,
        compressionInfo: CompressionInfo(
          algorithm: 'gzip',
          ratio: 0.5,
          originalSize: 100,
          compressedSize: 50,
          compressionTime: Duration(seconds: 1),
        ),
        includedDataTypes: [enums.DataCategory.transactions],
        performanceMetrics: PerformanceMetrics(
          totalDuration: Duration(seconds: 5),
          compressionTime: Duration(seconds: 1),
          uploadTime: Duration(seconds: 2),
          validationTime: Duration(seconds: 1),
          networkRetries: 0,
          averageUploadSpeed: 1.0,
        ),
        validationInfo: ValidationInfo(
          checksum: checksum,
          result: enums.ValidationResult.valid,
          validatedAt: DateTime.now(),
          errors: [],
        ),
        originalSize: 100,
        compressedSize: 50,
        backupDuration: Duration(seconds: 5),
        compressionAlgorithm: 'gzip',
        compressionRatio: 0.5,
      );

      final backupData = {
        'metadata': metadata.toJson(),
        'transactions': [
          {
            'id': 'test-1',
            'amount': 100.0,
            'description': 'Test transaction',
            'date': DateTime.now().toIso8601String(),
          },
        ],
        'wallets': [
          {'id': 'wallet-1', 'name': 'Test Wallet', 'balance': 100.0},
        ],
      };

      final package = BackupPackage(
        data: testData,
        backupData: backupData,
        expectedChecksum: checksum,
        metadata: metadata,
      );

      // Act
      final result = await validationService.validateBackup(package);

      // Assert
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('should detect checksum mismatch', () async {
      // Arrange
      final testData = [1, 2, 3, 4, 5];
      final wrongChecksum = 'wrong_checksum';

      final metadata = EnhancedBackupMetadata(
        version: '3.0',
        createdAt: DateTime.now(),
        transactionCount: 1,
        walletCount: 1,
        type: enums.BackupType.full,
        compressionInfo: CompressionInfo(
          algorithm: 'gzip',
          ratio: 0.5,
          originalSize: 100,
          compressedSize: 50,
          compressionTime: Duration(seconds: 1),
        ),
        includedDataTypes: [enums.DataCategory.transactions],
        performanceMetrics: PerformanceMetrics(
          totalDuration: Duration(seconds: 5),
          compressionTime: Duration(seconds: 1),
          uploadTime: Duration(seconds: 2),
          validationTime: Duration(seconds: 1),
          networkRetries: 0,
          averageUploadSpeed: 1.0,
        ),
        validationInfo: ValidationInfo(
          checksum: wrongChecksum,
          result: enums.ValidationResult.valid,
          validatedAt: DateTime.now(),
          errors: [],
        ),
        originalSize: 100,
        compressedSize: 50,
        backupDuration: Duration(seconds: 5),
        compressionAlgorithm: 'gzip',
        compressionRatio: 0.5,
      );

      final backupData = {
        'metadata': metadata.toJson(),
        'transactions': [
          {
            'id': 'test-1',
            'amount': 100.0,
            'description': 'Test transaction',
            'date': DateTime.now().toIso8601String(),
          },
        ],
        'wallets': [
          {'id': 'wallet-1', 'name': 'Test Wallet', 'balance': 100.0},
        ],
      };

      final package = BackupPackage(
        data: testData,
        backupData: backupData,
        expectedChecksum: wrongChecksum,
        metadata: metadata,
      );

      // Act
      final result = await validationService.validateBackup(package);

      // Assert
      expect(result.isCorrupted, isTrue);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first, contains('Checksum mismatch'));
    });

    test('should validate metadata consistency', () async {
      // Arrange
      final metadata = EnhancedBackupMetadata(
        version: '3.0',
        createdAt: DateTime.now(),
        transactionCount: 1,
        walletCount: 1,
        type: enums.BackupType.full,
        compressionInfo: CompressionInfo(
          algorithm: 'gzip',
          ratio: 0.5,
          originalSize: 100,
          compressedSize: 50,
          compressionTime: Duration(seconds: 1),
        ),
        includedDataTypes: [enums.DataCategory.transactions],
        performanceMetrics: PerformanceMetrics(
          totalDuration: Duration(seconds: 5),
          compressionTime: Duration(seconds: 1),
          uploadTime: Duration(seconds: 2),
          validationTime: Duration(seconds: 1),
          networkRetries: 0,
          averageUploadSpeed: 1.0,
        ),
        validationInfo: ValidationInfo(
          checksum: 'test_checksum',
          result: enums.ValidationResult.valid,
          validatedAt: DateTime.now(),
          errors: [],
        ),
        originalSize: 100,
        compressedSize: 50,
        backupDuration: Duration(seconds: 5),
        compressionAlgorithm: 'gzip',
        compressionRatio: 0.5,
      );

      // Act
      final result = await validationService.validateMetadata(metadata);

      // Assert
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });
  });

  group('IntegrityValidator', () {
    late IntegrityValidator validator;

    setUp(() {
      validator = IntegrityValidator();
    });

    test('should validate correct backup structure', () async {
      // Arrange
      final backupData = {
        'metadata': {
          'version': '3.0',
          'createdAt': DateTime.now().toIso8601String(),
          'transactionCount': 1,
          'walletCount': 1,
        },
        'transactions': [
          {
            'id': 'test-1',
            'amount': 100.0,
            'description': 'Test transaction',
            'date': DateTime.now().toIso8601String(),
          },
        ],
        'wallets': [
          {'id': 'wallet-1', 'name': 'Test Wallet', 'balance': 100.0},
        ],
      };

      // Act
      final isValid = await validator.validateStructure(backupData);

      // Assert
      expect(isValid, isTrue);
    });

    test('should reject backup with missing required fields', () async {
      // Arrange
      final backupData = {
        'metadata': {
          'version': '3.0',
          'createdAt': DateTime.now().toIso8601String(),
        },
        // Missing transactions and wallets
      };

      // Act
      final isValid = await validator.validateStructure(backupData);

      // Assert
      expect(isValid, isFalse);
    });

    test('should validate data types correctly', () async {
      // Arrange
      final backupData = {
        'metadata': {
          'version': '3.0',
          'createdAt': DateTime.now().toIso8601String(),
          'transactionCount': 1,
          'walletCount': 1,
        },
        'transactions': [
          {
            'id': 'test-1',
            'amount': 100.0,
            'description': 'Test transaction',
            'date': DateTime.now().toIso8601String(),
          },
        ],
        'wallets': [
          {'id': 'wallet-1', 'name': 'Test Wallet', 'balance': 100.0},
        ],
      };

      // Act
      final isValid = await validator.validateDataTypes(backupData);

      // Assert
      expect(isValid, isTrue);
    });

    test('should find inconsistencies in backup data', () async {
      // Arrange - metadata says 2 transactions but only 1 exists
      final backupData = {
        'metadata': {
          'version': '3.0',
          'createdAt': DateTime.now().toIso8601String(),
          'transactionCount': 2, // Inconsistent count
          'walletCount': 1,
        },
        'transactions': [
          {
            'id': 'test-1',
            'amount': 100.0,
            'description': 'Test transaction',
            'date': DateTime.now().toIso8601String(),
          },
        ],
        'wallets': [
          {'id': 'wallet-1', 'name': 'Test Wallet', 'balance': 100.0},
        ],
      };

      // Act
      final errors = await validator.findInconsistencies(backupData);

      // Assert
      expect(errors, isNotEmpty);
      expect(
        errors.any((e) => e.message.contains('Transaction count mismatch')),
        isTrue,
      );
    });
  });
}
