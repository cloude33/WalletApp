/// Enums for backup optimization system

/// Types of backup operations
enum BackupType {
  full,
  incremental,
  custom,
}

/// Data categories that can be included in backups
enum DataCategory {
  transactions,
  wallets,
  creditCards,
  bills,
  goals,
  settings,
  userImages,
  recurringTransactions,
}

/// Types of changes detected in incremental backups
enum ChangeType {
  create,
  update,
  delete,
}

/// Compression algorithms available for backup data
enum CompressionAlgorithm {
  gzip,
  lz4,
  zstd,
  brotli,
}

/// Compression levels for different use cases
enum CompressionLevel {
  fast,
  balanced,
  maximum,
}

/// Data types for optimal compression algorithm selection
enum DataType {
  json,
  image,
  text,
  binary,
}

/// Network quality levels for smart scheduling
enum NetworkQuality {
  poor,
  fair,
  good,
  excellent,
}

/// Backup operation results
enum BackupResult {
  success,
  failed,
  cancelled,
  partialSuccess,
}

/// Validation result types
enum ValidationResult {
  valid,
  corrupted,
  incomplete,
  unsupported,
}

/// Repair operation results
enum RepairResult {
  repaired,
  unrepairable,
  notNeeded,
}

extension BackupTypeExtension on BackupType {
  String get displayName {
    switch (this) {
      case BackupType.full:
        return 'Tam Yedekleme';
      case BackupType.incremental:
        return 'Artımlı Yedekleme';
      case BackupType.custom:
        return 'Özel Yedekleme';
    }
  }
}

extension DataCategoryExtension on DataCategory {
  String get displayName {
    switch (this) {
      case DataCategory.transactions:
        return 'İşlemler';
      case DataCategory.wallets:
        return 'Cüzdanlar';
      case DataCategory.creditCards:
        return 'Kredi Kartları';
      case DataCategory.bills:
        return 'Faturalar';
      case DataCategory.goals:
        return 'Hedefler';
      case DataCategory.settings:
        return 'Ayarlar';
      case DataCategory.userImages:
        return 'Kullanıcı Resimleri';
      case DataCategory.recurringTransactions:
        return 'Tekrarlayan İşlemler';
    }
  }
}

extension CompressionAlgorithmExtension on CompressionAlgorithm {
  String get displayName {
    switch (this) {
      case CompressionAlgorithm.gzip:
        return 'GZIP';
      case CompressionAlgorithm.lz4:
        return 'LZ4';
      case CompressionAlgorithm.zstd:
        return 'ZSTD';
      case CompressionAlgorithm.brotli:
        return 'Brotli';
    }
  }
}