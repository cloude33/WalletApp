import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/backup_optimization/validation_service.dart';
import 'package:parion/models/backup_optimization/enhanced_backup_metadata.dart';
import 'package:parion/models/backup_optimization/backup_enums.dart' as enums;
import '../../property_test_utils.dart';

void main() {
  group('ValidationService - Checksum Validation Property Tests', () {
    late ValidationService validationService;

    setUp(() {
      validationService = ValidationService();
    });

    /// **Feature: backup-optimization, Property 15: Backup Integrity Verification**
    /// **Validates: Requirements 6.2**
    PropertyTest.forAll<BackupPackage>(
      description:
          'Property 15: For any backup restoration, checksum verification should match stored value',
      generator: _generateRandomBackupPackage,
      property: (backupPackage) async {
        // Act - verify integrity using the expected checksum
        final integrityResult = await validationService.verifyIntegrity(
          backupPackage,
          backupPackage.expectedChecksum,
        );

        // Property: When the expected checksum matches the calculated checksum,
        // integrity verification should return true
        return integrityResult == true;
      },
      iterations: 20,
    );

    PropertyTest.forAll<BackupPackageWithCorruption>(
      description:
          'Property 15b: For any corrupted backup data, checksum verification should detect corruption',
      generator: _generateCorruptedBackupPackage,
      property: (corruptedPackage) async {
        // Act - verify integrity with original checksum against corrupted data
        final integrityResult = await validationService.verifyIntegrity(
          corruptedPackage.corruptedPackage,
          corruptedPackage.originalChecksum,
        );

        // Property: When data is corrupted, checksum verification should return false
        return integrityResult == false;
      },
      iterations: 20,
    );

    PropertyTest.forAll<List<int>>(
      description:
          'Property 15c: For any data, checksum calculation should be deterministic',
      generator: _generateRandomByteData,
      property: (data) async {
        // Act - calculate checksum twice for the same data
        final checksum1 = await validationService.calculateChecksum(data);
        final checksum2 = await validationService.calculateChecksum(data);

        // Property: Checksum calculation should be deterministic
        return checksum1 == checksum2 && checksum1.isNotEmpty;
      },
      iterations: 20,
    );

    PropertyTest.forAll<TwoDataSets>(
      description:
          'Property 15d: For any two different data sets, checksums should be different',
      generator: _generateTwoDifferentDataSets,
      property: (dataSets) async {
        // Act - calculate checksums for both data sets
        final checksum1 = await validationService.calculateChecksum(
          dataSets.data1,
        );
        final checksum2 = await validationService.calculateChecksum(
          dataSets.data2,
        );

        // Property: Different data should produce different checksums
        return checksum1 != checksum2;
      },
      iterations: 20,
    );
  });
}

/// Generates a random backup package with valid checksum
BackupPackage _generateRandomBackupPackage() {
  // Generate random backup data
  final backupData = _generateRandomBackupData();

  // Convert to bytes for checksum calculation
  final jsonString = jsonEncode(backupData);
  final data = utf8.encode(jsonString);

  // Calculate correct checksum synchronously using crypto library directly
  final checksum = _calculateChecksumSync(data);

  // Generate metadata
  final metadata = _generateRandomMetadata(checksum);

  return BackupPackage(
    data: data,
    backupData: backupData,
    expectedChecksum: checksum,
    metadata: metadata,
  );
}

/// Generates a backup package with corrupted data but original checksum
BackupPackageWithCorruption _generateCorruptedBackupPackage() {
  final random = Random();

  // Generate original backup data
  final originalBackupData = _generateRandomBackupData();
  final originalJsonString = jsonEncode(originalBackupData);
  final originalData = utf8.encode(originalJsonString);

  // Calculate original checksum synchronously
  final originalChecksum = _calculateChecksumSync(originalData);

  // Corrupt the data by modifying some bytes
  final corruptedData = List<int>.from(originalData);
  final corruptionIndex = random.nextInt(corruptedData.length);
  corruptedData[corruptionIndex] = (corruptedData[corruptionIndex] + 1) % 256;

  // Generate metadata with original checksum
  final metadata = _generateRandomMetadata(originalChecksum);

  final corruptedPackage = BackupPackage(
    data: corruptedData,
    backupData: originalBackupData, // Keep original backup data structure
    expectedChecksum: originalChecksum,
    metadata: metadata,
  );

  return BackupPackageWithCorruption(
    corruptedPackage: corruptedPackage,
    originalChecksum: originalChecksum,
  );
}

/// Generates random byte data for checksum testing
List<int> _generateRandomByteData() {
  final random = Random();
  final length = 10 + random.nextInt(1000); // 10 to 1010 bytes
  return List.generate(length, (_) => random.nextInt(256));
}

/// Generates two different data sets for checksum uniqueness testing
TwoDataSets _generateTwoDifferentDataSets() {
  final random = Random();

  // Generate first data set
  final length1 = 10 + random.nextInt(500);
  final data1 = List.generate(length1, (_) => random.nextInt(256));

  // Generate second data set (ensure it's different)
  List<int> data2;
  do {
    final length2 = 10 + random.nextInt(500);
    data2 = List.generate(length2, (_) => random.nextInt(256));
  } while (_listsEqual(data1, data2));

  return TwoDataSets(data1: data1, data2: data2);
}

/// Generates random backup data structure
Map<String, dynamic> _generateRandomBackupData() {
  final random = Random();

  final transactionCount = random.nextInt(100);
  final walletCount = random.nextInt(10) + 1;

  return {
    'metadata': {
      'version': '3.0',
      'createdAt': PropertyTest.randomDateTime().toIso8601String(),
      'transactionCount': transactionCount,
      'walletCount': walletCount,
    },
    'transactions': List.generate(
      transactionCount,
      (i) => {
        'id': 'tx-${PropertyTest.randomString(minLength: 5, maxLength: 10)}',
        'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 10000.0),
        'description': PropertyTest.randomString(minLength: 5, maxLength: 50),
        'date': PropertyTest.randomDateTime().toIso8601String(),
        'category': PropertyTest.randomString(minLength: 3, maxLength: 20),
      },
    ),
    'wallets': List.generate(
      walletCount,
      (i) => {
        'id': 'wallet-${PropertyTest.randomString(minLength: 3, maxLength: 8)}',
        'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
        'balance': PropertyTest.randomPositiveDouble(min: 0.0, max: 100000.0),
        'currency': PropertyTest.randomString(minLength: 3, maxLength: 3),
      },
    ),
    'creditCards': List.generate(
      random.nextInt(5),
      (i) => {
        'id': 'cc-${PropertyTest.randomString(minLength: 3, maxLength: 8)}',
        'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
        'limit': PropertyTest.randomPositiveDouble(min: 1000.0, max: 50000.0),
        'balance': PropertyTest.randomPositiveDouble(min: 0.0, max: 25000.0),
      },
    ),
  };
}

/// Generates random enhanced backup metadata
EnhancedBackupMetadata _generateRandomMetadata(String checksum) {
  final random = Random();

  return EnhancedBackupMetadata(
    version: '3.0',
    createdAt: PropertyTest.randomDateTime(),
    transactionCount: PropertyTest.randomInt(min: 0, max: 100),
    walletCount: PropertyTest.randomInt(min: 1, max: 10),
    type:
        enums.BackupType.values[random.nextInt(enums.BackupType.values.length)],
    compressionInfo: CompressionInfo(
      algorithm: ['gzip', 'lz4', 'zstd'][random.nextInt(3)],
      ratio: PropertyTest.randomPositiveDouble(min: 0.1, max: 0.9),
      originalSize: PropertyTest.randomInt(min: 1000, max: 100000),
      compressedSize: PropertyTest.randomInt(min: 500, max: 50000),
      compressionTime: Duration(
        milliseconds: PropertyTest.randomInt(min: 100, max: 5000),
      ),
    ),
    includedDataTypes: [
      enums.DataCategory.transactions,
      enums.DataCategory.wallets,
    ],
    performanceMetrics: PerformanceMetrics(
      totalDuration: Duration(
        seconds: PropertyTest.randomInt(min: 1, max: 300),
      ),
      compressionTime: Duration(
        milliseconds: PropertyTest.randomInt(min: 100, max: 5000),
      ),
      uploadTime: Duration(seconds: PropertyTest.randomInt(min: 1, max: 120)),
      validationTime: Duration(
        milliseconds: PropertyTest.randomInt(min: 50, max: 2000),
      ),
      networkRetries: PropertyTest.randomInt(min: 0, max: 5),
      averageUploadSpeed: PropertyTest.randomPositiveDouble(
        min: 0.1,
        max: 10.0,
      ),
    ),
    validationInfo: ValidationInfo(
      checksum: checksum,
      result: enums.ValidationResult.valid,
      validatedAt: PropertyTest.randomDateTime(),
      errors: [],
    ),
    originalSize: PropertyTest.randomInt(min: 1000, max: 100000),
    compressedSize: PropertyTest.randomInt(min: 500, max: 50000),
    backupDuration: Duration(seconds: PropertyTest.randomInt(min: 1, max: 300)),
    compressionAlgorithm: ['gzip', 'lz4', 'zstd'][random.nextInt(3)],
    compressionRatio: PropertyTest.randomPositiveDouble(min: 0.1, max: 0.9),
  );
}

/// Helper function to check if two lists are equal
bool _listsEqual(List<int> list1, List<int> list2) {
  if (list1.length != list2.length) return false;
  for (int i = 0; i < list1.length; i++) {
    if (list1[i] != list2[i]) return false;
  }
  return true;
}

/// Helper class for corrupted backup package testing
class BackupPackageWithCorruption {
  final BackupPackage corruptedPackage;
  final String originalChecksum;

  BackupPackageWithCorruption({
    required this.corruptedPackage,
    required this.originalChecksum,
  });
}

/// Helper class for two different data sets testing
class TwoDataSets {
  final List<int> data1;
  final List<int> data2;

  TwoDataSets({required this.data1, required this.data2});
}

/// Synchronous checksum calculation for test data generation
String _calculateChecksumSync(List<int> data) {
  final digest = sha256.convert(data);
  return digest.toString();
}
