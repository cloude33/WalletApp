import 'package:crypto/crypto.dart';

import '../../models/backup_optimization/backup_enums.dart';
import '../../models/backup_optimization/backup_results.dart';
import '../../models/backup_optimization/enhanced_backup_metadata.dart';
import 'integrity_validator.dart';

/// Service for validating backup integrity and detecting corruption
class ValidationService {
  final IntegrityValidator _validator;

  ValidationService({IntegrityValidator? validator})
      : _validator = validator ?? IntegrityValidator();

  /// Validates a complete backup package
  Future<ValidationResult> validateBackup(BackupPackage package) async {
    try {
      // 1. Verify checksum
      final calculatedChecksum = await calculateChecksum(package.data);
      if (calculatedChecksum != package.expectedChecksum) {
        return ValidationResult(
          result: ValidationResultEnum.corrupted,
          errors: ['Checksum mismatch: expected ${package.expectedChecksum}, got $calculatedChecksum'],
          validatedAt: DateTime.now(),
        );
      }

      // 2. Validate structure
      final structureValid = await _validator.validateStructure(package.backupData);
      if (!structureValid) {
        return ValidationResult(
          result: ValidationResultEnum.corrupted,
          errors: ['Invalid backup structure'],
          validatedAt: DateTime.now(),
        );
      }

      // 3. Validate data types
      final dataTypesValid = await _validator.validateDataTypes(package.backupData);
      if (!dataTypesValid) {
        return ValidationResult(
          result: ValidationResultEnum.corrupted,
          errors: ['Invalid data types in backup'],
          validatedAt: DateTime.now(),
        );
      }

      // 4. Find inconsistencies
      final inconsistencies = await _validator.findInconsistencies(package.backupData);
      if (inconsistencies.isNotEmpty) {
        return ValidationResult(
          result: ValidationResultEnum.corrupted,
          errors: inconsistencies.map((e) => e.message).toList(),
          validatedAt: DateTime.now(),
        );
      }

      return ValidationResult(
        result: ValidationResultEnum.valid,
        errors: [],
        validatedAt: DateTime.now(),
      );
    } catch (e) {
      return ValidationResult(
        result: ValidationResultEnum.corrupted,
        errors: ['Validation failed: ${e.toString()}'],
        validatedAt: DateTime.now(),
      );
    }
  }

  /// Calculates SHA-256 checksum for data integrity verification
  Future<String> calculateChecksum(List<int> data) async {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  /// Verifies backup integrity by comparing checksums
  Future<bool> verifyIntegrity(BackupPackage package, String expectedChecksum) async {
    try {
      final calculatedChecksum = await calculateChecksum(package.data);
      return calculatedChecksum == expectedChecksum;
    } catch (e) {
      return false;
    }
  }

  /// Attempts to repair a corrupted backup
  Future<RepairResult> attemptRepair(CorruptedBackup backup) async {
    try {
      // Check if backup has redundant data or can be reconstructed
      if (backup.hasRedundantData) {
        // Try to repair using redundant information
        final repairedData = await _repairFromRedundantData(backup);
        if (repairedData != null) {
          backup.repairedData = repairedData;
          return RepairResult(
            result: RepairResultEnum.repaired,
            message: 'Backup repaired using redundant data',
            repairedAt: DateTime.now(),
          );
        }
      }

      // Check if this is an incremental backup that can be reconstructed
      if (backup.isIncremental && backup.parentBackups.isNotEmpty) {
        final reconstructed = await _reconstructFromIncrementals(backup);
        if (reconstructed != null) {
          backup.repairedData = reconstructed;
          return RepairResult(
            result: RepairResultEnum.repaired,
            message: 'Backup reconstructed from incremental chain',
            repairedAt: DateTime.now(),
          );
        }
      }

      return RepairResult(
        result: RepairResultEnum.unrepairable,
        message: 'No repair method available for this corruption type',
        repairedAt: DateTime.now(),
      );
    } catch (e) {
      return RepairResult(
        result: RepairResultEnum.unrepairable,
        message: 'Repair attempt failed: ${e.toString()}',
        repairedAt: DateTime.now(),
      );
    }
  }

  /// Validates backup metadata for consistency
  Future<ValidationResult> validateMetadata(EnhancedBackupMetadata metadata) async {
    final errors = <String>[];

    // Check required fields
    if (metadata.validationInfo.checksum.isEmpty) {
      errors.add('Missing checksum in metadata');
    }

    if (metadata.originalSize <= 0) {
      errors.add('Invalid original size in metadata');
    }

    if (metadata.compressedSize <= 0) {
      errors.add('Invalid compressed size in metadata');
    }

    // Check compression ratio consistency
    final expectedRatio = metadata.compressedSize / metadata.originalSize;
    if ((metadata.compressionRatio - expectedRatio).abs() > 0.01) {
      errors.add('Compression ratio mismatch in metadata');
    }

    // Check incremental backup consistency
    if (metadata.isIncremental && !metadata.hasParent) {
      errors.add('Incremental backup missing parent reference');
    }

    final resultType = errors.isEmpty 
        ? ValidationResultEnum.valid 
        : ValidationResultEnum.corrupted;

    return ValidationResult(
      result: resultType,
      errors: errors,
      validatedAt: DateTime.now(),
    );
  }

  /// Repairs backup from redundant data
  Future<Map<String, dynamic>?> _repairFromRedundantData(CorruptedBackup backup) async {
    // Implementation would depend on the specific redundancy scheme
    // For now, return null indicating no repair possible
    return null;
  }

  /// Reconstructs backup from incremental chain
  Future<Map<String, dynamic>?> _reconstructFromIncrementals(CorruptedBackup backup) async {
    try {
      // Start with the base backup
      Map<String, dynamic>? baseData;
      
      // Find the full backup in the chain
      for (final parent in backup.parentBackups) {
        if (parent.metadata.type == BackupType.full) {
          baseData = parent.backupData;
          break;
        }
      }

      if (baseData == null) {
        return null;
      }

      // Apply incremental changes in order
      final sortedIncrementals = backup.parentBackups
          .where((b) => b.metadata.type == BackupType.incremental)
          .toList()
        ..sort((a, b) => a.metadata.createdAt.compareTo(b.metadata.createdAt));

      Map<String, dynamic> reconstructed = Map.from(baseData);

      for (final incremental in sortedIncrementals) {
        reconstructed = _applyIncrementalChanges(reconstructed, incremental.backupData);
      }

      return reconstructed;
    } catch (e) {
      return null;
    }
  }

  /// Applies incremental changes to base data
  Map<String, dynamic> _applyIncrementalChanges(
    Map<String, dynamic> baseData,
    Map<String, dynamic> incrementalData,
  ) {
    final result = Map<String, dynamic>.from(baseData);
    
    // Apply changes from incremental data
    incrementalData.forEach((key, value) {
      if (value == null) {
        // Null value indicates deletion
        result.remove(key);
      } else {
        // Update or add the value
        result[key] = value;
      }
    });

    return result;
  }
}

/// Represents a backup package for validation
class BackupPackage {
  final List<int> data;
  final Map<String, dynamic> backupData;
  final String expectedChecksum;
  final EnhancedBackupMetadata metadata;

  const BackupPackage({
    required this.data,
    required this.backupData,
    required this.expectedChecksum,
    required this.metadata,
  });
}

/// Represents a corrupted backup that may be repairable
class CorruptedBackup {
  final BackupPackage originalPackage;
  final List<ValidationError> corruptionErrors;
  final bool hasRedundantData;
  final bool isIncremental;
  final List<BackupPackage> parentBackups;
  Map<String, dynamic>? repairedData;

  CorruptedBackup({
    required this.originalPackage,
    required this.corruptionErrors,
    this.hasRedundantData = false,
    this.isIncremental = false,
    this.parentBackups = const [],
    this.repairedData,
  });
}

/// Result of validation operation
class ValidationResult {
  final ValidationResultEnum result;
  final List<String> errors;
  final DateTime validatedAt;
  final Map<String, dynamic> additionalInfo;

  const ValidationResult({
    required this.result,
    required this.errors,
    required this.validatedAt,
    this.additionalInfo = const {},
  });

  /// Check if validation was successful
  bool get isValid => result == ValidationResultEnum.valid;

  /// Check if backup is corrupted
  bool get isCorrupted => result == ValidationResultEnum.corrupted;

  /// Check if backup is incomplete
  bool get isIncomplete => result == ValidationResultEnum.incomplete;

  Map<String, dynamic> toJson() => {
    'result': result.name,
    'errors': errors,
    'validatedAt': validatedAt.toIso8601String(),
    'additionalInfo': additionalInfo,
  };

  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    return ValidationResult(
      result: ValidationResultEnum.values.firstWhere(
        (e) => e.name == json['result'],
        orElse: () => ValidationResultEnum.corrupted,
      ),
      errors: List<String>.from(json['errors'] ?? []),
      validatedAt: DateTime.parse(json['validatedAt']),
      additionalInfo: Map<String, dynamic>.from(json['additionalInfo'] ?? {}),
    );
  }
}

/// Result of repair operation
class RepairResult {
  final RepairResultEnum result;
  final String message;
  final DateTime repairedAt;
  final Map<String, dynamic> repairDetails;

  const RepairResult({
    required this.result,
    required this.message,
    required this.repairedAt,
    this.repairDetails = const {},
  });

  /// Check if repair was successful
  bool get isRepaired => result == RepairResultEnum.repaired;

  /// Check if backup is unrepairable
  bool get isUnrepairable => result == RepairResultEnum.unrepairable;

  Map<String, dynamic> toJson() => {
    'result': result.name,
    'message': message,
    'repairedAt': repairedAt.toIso8601String(),
    'repairDetails': repairDetails,
  };

  factory RepairResult.fromJson(Map<String, dynamic> json) {
    return RepairResult(
      result: RepairResultEnum.values.firstWhere(
        (e) => e.name == json['result'],
        orElse: () => RepairResultEnum.unrepairable,
      ),
      message: json['message'] ?? '',
      repairedAt: DateTime.parse(json['repairedAt']),
      repairDetails: Map<String, dynamic>.from(json['repairDetails'] ?? {}),
    );
  }
}

/// Validation result types
enum ValidationResultEnum {
  valid,
  corrupted,
  incomplete,
  unsupported,
}

/// Repair result types  
enum RepairResultEnum {
  repaired,
  unrepairable,
  notNeeded,
}