import 'backup_enums.dart';

/// Compressed data container
class CompressedData {
  final List<int> data;
  final CompressionAlgorithm algorithm;
  final int originalSize;
  final int compressedSize;
  final Duration compressionTime;
  final Map<String, dynamic> metadata;

  const CompressedData({
    required this.data,
    required this.algorithm,
    required this.originalSize,
    required this.compressedSize,
    required this.compressionTime,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'data': data,
    'algorithm': algorithm.name,
    'originalSize': originalSize,
    'compressedSize': compressedSize,
    'compressionTime': compressionTime.inMilliseconds,
    'metadata': metadata,
  };

  factory CompressedData.fromJson(Map<String, dynamic> json) {
    return CompressedData(
      data: List<int>.from(json['data'] ?? []),
      algorithm: CompressionAlgorithm.values.firstWhere(
        (e) => e.name == json['algorithm'],
        orElse: () => CompressionAlgorithm.gzip,
      ),
      originalSize: json['originalSize'] ?? 0,
      compressedSize: json['compressedSize'] ?? 0,
      compressionTime: Duration(milliseconds: json['compressionTime'] ?? 0),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Get compression ratio (0.0 to 1.0)
  double get compressionRatio => 
      originalSize > 0 ? compressedSize / originalSize : 0.0;

  /// Get compression efficiency as percentage
  double get compressionEfficiency => 
      originalSize > 0 ? (1 - compressionRatio) * 100 : 0.0;

  /// Get compression speed in MB/s
  double get compressionSpeed {
    if (compressionTime.inMilliseconds == 0) return 0.0;
    final seconds = compressionTime.inMilliseconds / 1000.0;
    final megabytes = originalSize / (1024 * 1024);
    return megabytes / seconds;
  }
}

/// Statistics about compression performance
class CompressionStats {
  final CompressionAlgorithm algorithm;
  final double ratio;
  final Duration time;
  final int originalSize;
  final int compressedSize;
  final double speed; // MB/s

  const CompressionStats({
    required this.algorithm,
    required this.ratio,
    required this.time,
    required this.originalSize,
    required this.compressedSize,
    required this.speed,
  });

  Map<String, dynamic> toJson() => {
    'algorithm': algorithm.name,
    'ratio': ratio,
    'time': time.inMilliseconds,
    'originalSize': originalSize,
    'compressedSize': compressedSize,
    'speed': speed,
  };

  factory CompressionStats.fromJson(Map<String, dynamic> json) {
    return CompressionStats(
      algorithm: CompressionAlgorithm.values.firstWhere(
        (e) => e.name == json['algorithm'],
        orElse: () => CompressionAlgorithm.gzip,
      ),
      ratio: (json['ratio'] ?? 0.0).toDouble(),
      time: Duration(milliseconds: json['time'] ?? 0),
      originalSize: json['originalSize'] ?? 0,
      compressedSize: json['compressedSize'] ?? 0,
      speed: (json['speed'] ?? 0.0).toDouble(),
    );
  }

  /// Get efficiency as percentage
  double get efficiency => (1 - ratio) * 100;

  /// Check if compression was beneficial
  bool get isBeneficial => ratio < 1.0;
}

/// Configuration for upload operations
class UploadConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final int chunkSize; // bytes
  final bool enableResume;

  const UploadConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(minutes: 5),
    this.chunkSize = 1024 * 1024, // 1MB
    this.enableResume = true,
  });

  Map<String, dynamic> toJson() => {
    'maxRetries': maxRetries,
    'initialDelay': initialDelay.inMilliseconds,
    'backoffMultiplier': backoffMultiplier,
    'maxDelay': maxDelay.inMilliseconds,
    'chunkSize': chunkSize,
    'enableResume': enableResume,
  };

  factory UploadConfig.fromJson(Map<String, dynamic> json) {
    return UploadConfig(
      maxRetries: json['maxRetries'] ?? 3,
      initialDelay: Duration(milliseconds: json['initialDelay'] ?? 1000),
      backoffMultiplier: (json['backoffMultiplier'] ?? 2.0).toDouble(),
      maxDelay: Duration(milliseconds: json['maxDelay'] ?? 300000),
      chunkSize: json['chunkSize'] ?? 1024 * 1024,
      enableResume: json['enableResume'] ?? true,
    );
  }

  /// Create a fast upload configuration
  factory UploadConfig.fast() {
    return const UploadConfig(
      maxRetries: 2,
      initialDelay: Duration(milliseconds: 500),
      backoffMultiplier: 1.5,
      maxDelay: Duration(minutes: 2),
      chunkSize: 2 * 1024 * 1024, // 2MB
      enableResume: false,
    );
  }

  /// Create a reliable upload configuration
  factory UploadConfig.reliable() {
    return const UploadConfig(
      maxRetries: 5,
      initialDelay: Duration(seconds: 2),
      backoffMultiplier: 2.5,
      maxDelay: Duration(minutes: 10),
      chunkSize: 512 * 1024, // 512KB
      enableResume: true,
    );
  }
}

/// Information about storage quota
class QuotaInfo {
  final int totalSpace;
  final int usedSpace;
  final int availableSpace;
  final double usagePercentage;
  final bool isNearLimit;

  const QuotaInfo({
    required this.totalSpace,
    required this.usedSpace,
    required this.availableSpace,
    required this.usagePercentage,
    required this.isNearLimit,
  });

  Map<String, dynamic> toJson() => {
    'totalSpace': totalSpace,
    'usedSpace': usedSpace,
    'availableSpace': availableSpace,
    'usagePercentage': usagePercentage,
    'isNearLimit': isNearLimit,
  };

  factory QuotaInfo.fromJson(Map<String, dynamic> json) {
    return QuotaInfo(
      totalSpace: json['totalSpace'] ?? 0,
      usedSpace: json['usedSpace'] ?? 0,
      availableSpace: json['availableSpace'] ?? 0,
      usagePercentage: (json['usagePercentage'] ?? 0.0).toDouble(),
      isNearLimit: json['isNearLimit'] ?? false,
    );
  }

  /// Check if there's enough space for a backup of given size
  bool hasSpaceFor(int backupSize) {
    return availableSpace >= backupSize;
  }

  /// Get formatted storage sizes
  String get formattedTotalSpace => _formatBytes(totalSpace);
  String get formattedUsedSpace => _formatBytes(usedSpace);
  String get formattedAvailableSpace => _formatBytes(availableSpace);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Information about a backup file in Drive
class DriveBackupInfo {
  final String id;
  final String name;
  final int size;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final String? description;
  final Map<String, dynamic> metadata;

  const DriveBackupInfo({
    required this.id,
    required this.name,
    required this.size,
    required this.createdAt,
    this.modifiedAt,
    this.description,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'size': size,
    'createdAt': createdAt.toIso8601String(),
    'modifiedAt': modifiedAt?.toIso8601String(),
    'description': description,
    'metadata': metadata,
  };

  factory DriveBackupInfo.fromJson(Map<String, dynamic> json) {
    return DriveBackupInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      size: json['size'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      modifiedAt: json['modifiedAt'] != null 
          ? DateTime.parse(json['modifiedAt'])
          : null,
      description: json['description'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Get formatted file size
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get age of the backup
  Duration get age => DateTime.now().difference(createdAt);

  /// Check if backup is recent (less than 24 hours old)
  bool get isRecent => age.inHours < 24;
}