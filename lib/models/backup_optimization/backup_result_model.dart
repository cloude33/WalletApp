import 'dart:io';
import 'enhanced_backup_metadata.dart';

/// Result of a backup operation
class BackupResult {
  final bool success;
  final String? backupId;
  final EnhancedBackupMetadata? metadata;
  final File? localFile;
  final String? cloudFileId;
  final Duration duration;
  final int originalSize;
  final int compressedSize;
  final String? error;

  const BackupResult({
    required this.success,
    this.backupId,
    this.metadata,
    this.localFile,
    this.cloudFileId,
    required this.duration,
    this.originalSize = 0,
    this.compressedSize = 0,
    this.error,
  });

  /// Get compression ratio
  double get compressionRatio =>
      originalSize > 0 ? compressedSize / originalSize : 0.0;
}
