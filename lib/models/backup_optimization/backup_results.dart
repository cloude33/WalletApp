import 'backup_enums.dart';
import 'enhanced_backup_metadata.dart';

/// Result of a backup operation
class BackupOperationResult {
  final BackupResult result;
  final String? backupId;
  final EnhancedBackupMetadata? metadata;
  final String? errorMessage;
  final Duration duration;
  final int? fileSize;
  final String? filePath;

  const BackupOperationResult({
    required this.result,
    this.backupId,
    this.metadata,
    this.errorMessage,
    required this.duration,
    this.fileSize,
    this.filePath,
  });

  Map<String, dynamic> toJson() => {
    'result': result.name,
    'backupId': backupId,
    'metadata': metadata?.toJson(),
    'errorMessage': errorMessage,
    'duration': duration.inMilliseconds,
    'fileSize': fileSize,
    'filePath': filePath,
  };

  factory BackupOperationResult.fromJson(Map<String, dynamic> json) {
    return BackupOperationResult(
      result: BackupResult.values.firstWhere(
        (e) => e.name == json['result'],
        orElse: () => BackupResult.failed,
      ),
      backupId: json['backupId'],
      metadata: json['metadata'] != null 
          ? EnhancedBackupMetadata.fromJson(json['metadata'])
          : null,
      errorMessage: json['errorMessage'],
      duration: Duration(milliseconds: json['duration'] ?? 0),
      fileSize: json['fileSize'],
      filePath: json['filePath'],
    );
  }

  /// Create a successful result
  factory BackupOperationResult.success({
    required String backupId,
    required EnhancedBackupMetadata metadata,
    required Duration duration,
    int? fileSize,
    String? filePath,
  }) {
    return BackupOperationResult(
      result: BackupResult.success,
      backupId: backupId,
      metadata: metadata,
      duration: duration,
      fileSize: fileSize,
      filePath: filePath,
    );
  }

  /// Create a failed result
  factory BackupOperationResult.failure({
    required String errorMessage,
    required Duration duration,
  }) {
    return BackupOperationResult(
      result: BackupResult.failed,
      errorMessage: errorMessage,
      duration: duration,
    );
  }

  /// Create a cancelled result
  factory BackupOperationResult.cancelled({
    required Duration duration,
  }) {
    return BackupOperationResult(
      result: BackupResult.cancelled,
      duration: duration,
    );
  }

  /// Check if the operation was successful
  bool get isSuccess => result == BackupResult.success;

  /// Check if the operation failed
  bool get isFailed => result == BackupResult.failed;

  /// Check if the operation was cancelled
  bool get isCancelled => result == BackupResult.cancelled;

  /// Get formatted duration
  String get formattedDuration {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

/// Information about a backup failure
class BackupFailure {
  final String backupId;
  final DateTime failedAt;
  final String errorMessage;
  final String? stackTrace;
  final int attemptNumber;
  final Duration nextRetryDelay;
  final Map<String, dynamic> context;

  const BackupFailure({
    required this.backupId,
    required this.failedAt,
    required this.errorMessage,
    this.stackTrace,
    required this.attemptNumber,
    required this.nextRetryDelay,
    this.context = const {},
  });

  Map<String, dynamic> toJson() => {
    'backupId': backupId,
    'failedAt': failedAt.toIso8601String(),
    'errorMessage': errorMessage,
    'stackTrace': stackTrace,
    'attemptNumber': attemptNumber,
    'nextRetryDelay': nextRetryDelay.inMilliseconds,
    'context': context,
  };

  factory BackupFailure.fromJson(Map<String, dynamic> json) {
    return BackupFailure(
      backupId: json['backupId'] ?? '',
      failedAt: DateTime.parse(json['failedAt']),
      errorMessage: json['errorMessage'] ?? '',
      stackTrace: json['stackTrace'],
      attemptNumber: json['attemptNumber'] ?? 1,
      nextRetryDelay: Duration(milliseconds: json['nextRetryDelay'] ?? 0),
      context: Map<String, dynamic>.from(json['context'] ?? {}),
    );
  }

  /// Check if this is the first attempt
  bool get isFirstAttempt => attemptNumber == 1;

  /// Get the next retry time
  DateTime get nextRetryAt => failedAt.add(nextRetryDelay);

  /// Check if it's time to retry
  bool get canRetryNow => DateTime.now().isAfter(nextRetryAt);
}

/// Result of a Drive upload operation
class DriveBackupResult {
  final bool success;
  final String? fileId;
  final String? fileName;
  final int? fileSize;
  final Duration uploadDuration;
  final String? errorMessage;
  final int retryCount;

  const DriveBackupResult({
    required this.success,
    this.fileId,
    this.fileName,
    this.fileSize,
    required this.uploadDuration,
    this.errorMessage,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'fileId': fileId,
    'fileName': fileName,
    'fileSize': fileSize,
    'uploadDuration': uploadDuration.inMilliseconds,
    'errorMessage': errorMessage,
    'retryCount': retryCount,
  };

  factory DriveBackupResult.fromJson(Map<String, dynamic> json) {
    return DriveBackupResult(
      success: json['success'] ?? false,
      fileId: json['fileId'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      uploadDuration: Duration(milliseconds: json['uploadDuration'] ?? 0),
      errorMessage: json['errorMessage'],
      retryCount: json['retryCount'] ?? 0,
    );
  }

  /// Create a successful result
  factory DriveBackupResult.success({
    required String fileId,
    required String fileName,
    required int fileSize,
    required Duration uploadDuration,
    int retryCount = 0,
  }) {
    return DriveBackupResult(
      success: true,
      fileId: fileId,
      fileName: fileName,
      fileSize: fileSize,
      uploadDuration: uploadDuration,
      retryCount: retryCount,
    );
  }

  /// Create a failed result
  factory DriveBackupResult.failure({
    required String errorMessage,
    required Duration uploadDuration,
    int retryCount = 0,
  }) {
    return DriveBackupResult(
      success: false,
      errorMessage: errorMessage,
      uploadDuration: uploadDuration,
      retryCount: retryCount,
    );
  }

  /// Get upload speed in MB/s
  double get uploadSpeed {
    if (fileSize == null || uploadDuration.inMilliseconds == 0) return 0.0;
    final seconds = uploadDuration.inMilliseconds / 1000.0;
    final megabytes = fileSize! / (1024 * 1024);
    return megabytes / seconds;
  }
}

/// Validation error information
class ValidationError {
  final String field;
  final String message;
  final String? expectedValue;
  final String? actualValue;
  final String severity; // 'error', 'warning', 'info'

  const ValidationError({
    required this.field,
    required this.message,
    this.expectedValue,
    this.actualValue,
    this.severity = 'error',
  });

  Map<String, dynamic> toJson() => {
    'field': field,
    'message': message,
    'expectedValue': expectedValue,
    'actualValue': actualValue,
    'severity': severity,
  };

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      field: json['field'] ?? '',
      message: json['message'] ?? '',
      expectedValue: json['expectedValue'],
      actualValue: json['actualValue'],
      severity: json['severity'] ?? 'error',
    );
  }

  /// Check if this is an error (vs warning or info)
  bool get isError => severity == 'error';

  /// Check if this is a warning
  bool get isWarning => severity == 'warning';

  /// Check if this is informational
  bool get isInfo => severity == 'info';
}

/// Metrics collected during backup operations
class BackupMetrics {
  final Duration totalDuration;
  final Duration dataGatheringTime;
  final Duration compressionTime;
  final Duration uploadTime;
  final Duration validationTime;
  final int originalDataSize;
  final int compressedDataSize;
  final int networkRetries;
  final double averageUploadSpeed;
  final Map<String, dynamic> additionalMetrics;

  const BackupMetrics({
    required this.totalDuration,
    required this.dataGatheringTime,
    required this.compressionTime,
    required this.uploadTime,
    required this.validationTime,
    required this.originalDataSize,
    required this.compressedDataSize,
    required this.networkRetries,
    required this.averageUploadSpeed,
    this.additionalMetrics = const {},
  });

  Map<String, dynamic> toJson() => {
    'totalDuration': totalDuration.inMilliseconds,
    'dataGatheringTime': dataGatheringTime.inMilliseconds,
    'compressionTime': compressionTime.inMilliseconds,
    'uploadTime': uploadTime.inMilliseconds,
    'validationTime': validationTime.inMilliseconds,
    'originalDataSize': originalDataSize,
    'compressedDataSize': compressedDataSize,
    'networkRetries': networkRetries,
    'averageUploadSpeed': averageUploadSpeed,
    'additionalMetrics': additionalMetrics,
  };

  factory BackupMetrics.fromJson(Map<String, dynamic> json) {
    return BackupMetrics(
      totalDuration: Duration(milliseconds: json['totalDuration'] ?? 0),
      dataGatheringTime: Duration(milliseconds: json['dataGatheringTime'] ?? 0),
      compressionTime: Duration(milliseconds: json['compressionTime'] ?? 0),
      uploadTime: Duration(milliseconds: json['uploadTime'] ?? 0),
      validationTime: Duration(milliseconds: json['validationTime'] ?? 0),
      originalDataSize: json['originalDataSize'] ?? 0,
      compressedDataSize: json['compressedDataSize'] ?? 0,
      networkRetries: json['networkRetries'] ?? 0,
      averageUploadSpeed: (json['averageUploadSpeed'] ?? 0.0).toDouble(),
      additionalMetrics: Map<String, dynamic>.from(json['additionalMetrics'] ?? {}),
    );
  }

  /// Get compression ratio
  double get compressionRatio => 
      originalDataSize > 0 ? compressedDataSize / originalDataSize : 0.0;

  /// Get compression efficiency as percentage
  double get compressionEfficiency => 
      originalDataSize > 0 ? (1 - compressionRatio) * 100 : 0.0;

  /// Get overall backup speed in MB/s
  double get overallSpeed {
    if (originalDataSize == 0 || totalDuration.inMilliseconds == 0) return 0.0;
    final seconds = totalDuration.inMilliseconds / 1000.0;
    final megabytes = originalDataSize / (1024 * 1024);
    return megabytes / seconds;
  }

  /// Get breakdown of time spent in each phase as percentages
  Map<String, double> get timeBreakdown {
    final total = totalDuration.inMilliseconds.toDouble();
    if (total == 0) return {};

    return {
      'dataGathering': (dataGatheringTime.inMilliseconds / total) * 100,
      'compression': (compressionTime.inMilliseconds / total) * 100,
      'upload': (uploadTime.inMilliseconds / total) * 100,
      'validation': (validationTime.inMilliseconds / total) * 100,
    };
  }
}