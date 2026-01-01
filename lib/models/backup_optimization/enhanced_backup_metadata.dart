import '../backup_metadata.dart';
import 'backup_enums.dart';

/// Enhanced backup metadata with optimization features
class EnhancedBackupMetadata extends BackupMetadata {
  final BackupType type;
  final CompressionInfo compressionInfo;
  final List<DataCategory> includedDataTypes;
  final String? parentBackupId; // For incremental backups
  final PerformanceMetrics performanceMetrics;
  final ValidationInfo validationInfo;
  
  // New fields for optimization
  final int originalSize;
  final int compressedSize;
  final Duration backupDuration;
  final String compressionAlgorithm;
  final double compressionRatio;

  const EnhancedBackupMetadata({
    required super.version,
    required super.createdAt,
    required super.transactionCount,
    required super.walletCount,
    super.appVersion,
    super.platform,
    super.deviceModel,
    required this.type,
    required this.compressionInfo,
    required this.includedDataTypes,
    this.parentBackupId,
    required this.performanceMetrics,
    required this.validationInfo,
    required this.originalSize,
    required this.compressedSize,
    required this.backupDuration,
    required this.compressionAlgorithm,
    required this.compressionRatio,
  });

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'type': type.name,
      'compressionInfo': compressionInfo.toJson(),
      'includedDataTypes': includedDataTypes.map((e) => e.name).toList(),
      'parentBackupId': parentBackupId,
      'performanceMetrics': performanceMetrics.toJson(),
      'validationInfo': validationInfo.toJson(),
      'originalSize': originalSize,
      'compressedSize': compressedSize,
      'backupDuration': backupDuration.inMilliseconds,
      'compressionAlgorithm': compressionAlgorithm,
      'compressionRatio': compressionRatio,
    };
  }

  factory EnhancedBackupMetadata.fromJson(Map<String, dynamic> json) {
    return EnhancedBackupMetadata(
      version: json['version'] ?? '3.0',
      createdAt: DateTime.parse(json['createdAt']),
      transactionCount: json['transactionCount'] ?? 0,
      walletCount: json['walletCount'] ?? 0,
      appVersion: json['appVersion'] ?? '1.0.0',
      platform: json['platform'] ?? 'unknown',
      deviceModel: json['deviceModel'] ?? 'unknown',
      type: BackupType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BackupType.full,
      ),
      compressionInfo: CompressionInfo.fromJson(json['compressionInfo'] ?? {}),
      includedDataTypes: (json['includedDataTypes'] as List<dynamic>?)
          ?.map((e) => DataCategory.values.firstWhere(
                (category) => category.name == e,
                orElse: () => DataCategory.transactions,
              ))
          .toList() ?? [],
      parentBackupId: json['parentBackupId'],
      performanceMetrics: PerformanceMetrics.fromJson(json['performanceMetrics'] ?? {}),
      validationInfo: ValidationInfo.fromJson(json['validationInfo'] ?? {}),
      originalSize: json['originalSize'] ?? 0,
      compressedSize: json['compressedSize'] ?? 0,
      backupDuration: Duration(milliseconds: json['backupDuration'] ?? 0),
      compressionAlgorithm: json['compressionAlgorithm'] ?? 'gzip',
      compressionRatio: (json['compressionRatio'] ?? 0.0).toDouble(),
    );
  }

  /// Check if this is an incremental backup
  bool get isIncremental => type == BackupType.incremental;

  /// Check if this backup has a parent (for incremental chains)
  bool get hasParent => parentBackupId != null;

  /// Get compression efficiency as percentage
  double get compressionEfficiency => 
      originalSize > 0 ? (1 - (compressedSize / originalSize)) * 100 : 0.0;
}

/// Information about compression applied to backup
class CompressionInfo {
  final String algorithm;
  final double ratio;
  final int originalSize;
  final int compressedSize;
  final Duration compressionTime;

  const CompressionInfo({
    required this.algorithm,
    required this.ratio,
    required this.originalSize,
    required this.compressedSize,
    required this.compressionTime,
  });

  Map<String, dynamic> toJson() => {
    'algorithm': algorithm,
    'ratio': ratio,
    'originalSize': originalSize,
    'compressedSize': compressedSize,
    'compressionTime': compressionTime.inMilliseconds,
  };

  factory CompressionInfo.fromJson(Map<String, dynamic> json) {
    return CompressionInfo(
      algorithm: json['algorithm'] ?? 'gzip',
      ratio: (json['ratio'] ?? 0.0).toDouble(),
      originalSize: json['originalSize'] ?? 0,
      compressedSize: json['compressedSize'] ?? 0,
      compressionTime: Duration(milliseconds: json['compressionTime'] ?? 0),
    );
  }
}

/// Performance metrics collected during backup operations
class PerformanceMetrics {
  final Duration totalDuration;
  final Duration compressionTime;
  final Duration uploadTime;
  final Duration validationTime;
  final int networkRetries;
  final double averageUploadSpeed; // MB/s

  const PerformanceMetrics({
    required this.totalDuration,
    required this.compressionTime,
    required this.uploadTime,
    required this.validationTime,
    required this.networkRetries,
    required this.averageUploadSpeed,
  });

  Map<String, dynamic> toJson() => {
    'totalDuration': totalDuration.inMilliseconds,
    'compressionTime': compressionTime.inMilliseconds,
    'uploadTime': uploadTime.inMilliseconds,
    'validationTime': validationTime.inMilliseconds,
    'networkRetries': networkRetries,
    'averageUploadSpeed': averageUploadSpeed,
  };

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      totalDuration: Duration(milliseconds: json['totalDuration'] ?? 0),
      compressionTime: Duration(milliseconds: json['compressionTime'] ?? 0),
      uploadTime: Duration(milliseconds: json['uploadTime'] ?? 0),
      validationTime: Duration(milliseconds: json['validationTime'] ?? 0),
      networkRetries: json['networkRetries'] ?? 0,
      averageUploadSpeed: (json['averageUploadSpeed'] ?? 0.0).toDouble(),
    );
  }
}

/// Information about backup validation
class ValidationInfo {
  final String checksum;
  final ValidationResult result;
  final DateTime validatedAt;
  final List<String> errors;

  const ValidationInfo({
    required this.checksum,
    required this.result,
    required this.validatedAt,
    required this.errors,
  });

  Map<String, dynamic> toJson() => {
    'checksum': checksum,
    'result': result.name,
    'validatedAt': validatedAt.toIso8601String(),
    'errors': errors,
  };

  factory ValidationInfo.fromJson(Map<String, dynamic> json) {
    return ValidationInfo(
      checksum: json['checksum'] ?? '',
      result: ValidationResult.values.firstWhere(
        (e) => e.name == json['result'],
        orElse: () => ValidationResult.valid,
      ),
      validatedAt: DateTime.parse(json['validatedAt'] ?? DateTime.now().toIso8601String()),
      errors: List<String>.from(json['errors'] ?? []),
    );
  }

  /// Check if validation was successful
  bool get isValid => result == ValidationResult.valid;
}