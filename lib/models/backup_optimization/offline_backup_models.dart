import 'backup_enums.dart';
import 'enhanced_backup_metadata.dart';

/// Represents a backup item in the offline queue
class OfflineBackupItem {
  final String id;
  final String localPath;
  final EnhancedBackupMetadata metadata;
  final DateTime createdAt;
  final OfflineBackupStatus status;
  final int retryCount;
  final DateTime? lastRetryAt;
  final String? errorMessage;
  final int priority; // Higher number = higher priority

  const OfflineBackupItem({
    required this.id,
    required this.localPath,
    required this.metadata,
    required this.createdAt,
    required this.status,
    this.retryCount = 0,
    this.lastRetryAt,
    this.errorMessage,
    this.priority = 0,
  });

  OfflineBackupItem copyWith({
    String? id,
    String? localPath,
    EnhancedBackupMetadata? metadata,
    DateTime? createdAt,
    OfflineBackupStatus? status,
    int? retryCount,
    DateTime? lastRetryAt,
    String? errorMessage,
    int? priority,
  }) {
    return OfflineBackupItem(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
      errorMessage: errorMessage ?? this.errorMessage,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'localPath': localPath,
    'metadata': metadata.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'retryCount': retryCount,
    'lastRetryAt': lastRetryAt?.toIso8601String(),
    'errorMessage': errorMessage,
    'priority': priority,
  };

  factory OfflineBackupItem.fromJson(Map<String, dynamic> json) {
    return OfflineBackupItem(
      id: json['id'],
      localPath: json['localPath'],
      metadata: EnhancedBackupMetadata.fromJson(json['metadata']),
      createdAt: DateTime.parse(json['createdAt']),
      status: OfflineBackupStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OfflineBackupStatus.pending,
      ),
      retryCount: json['retryCount'] ?? 0,
      lastRetryAt: json['lastRetryAt'] != null 
          ? DateTime.parse(json['lastRetryAt']) 
          : null,
      errorMessage: json['errorMessage'],
      priority: json['priority'] ?? 0,
    );
  }

  /// Check if this item can be retried
  bool get canRetry => 
      status == OfflineBackupStatus.failed && 
      retryCount < 3;

  /// Check if this item is ready for sync
  bool get isReadyForSync => 
      status == OfflineBackupStatus.pending || 
      (status == OfflineBackupStatus.failed && canRetry);
}

/// Status of offline backup items
enum OfflineBackupStatus {
  pending,
  syncing,
  completed,
  failed,
}

/// Configuration for offline backup behavior
class OfflineBackupConfig {
  final int maxQueueSize;
  final int maxRetryAttempts;
  final Duration retryDelay;
  final int maxLocalStorageMB;
  final bool autoCleanupOnSync;
  final List<DataCategory> priorityCategories;

  const OfflineBackupConfig({
    this.maxQueueSize = 50,
    this.maxRetryAttempts = 3,
    this.retryDelay = const Duration(minutes: 5),
    this.maxLocalStorageMB = 500,
    this.autoCleanupOnSync = true,
    this.priorityCategories = const [
      DataCategory.transactions,
      DataCategory.wallets,
    ],
  });

  Map<String, dynamic> toJson() => {
    'maxQueueSize': maxQueueSize,
    'maxRetryAttempts': maxRetryAttempts,
    'retryDelay': retryDelay.inMilliseconds,
    'maxLocalStorageMB': maxLocalStorageMB,
    'autoCleanupOnSync': autoCleanupOnSync,
    'priorityCategories': priorityCategories.map((e) => e.name).toList(),
  };

  factory OfflineBackupConfig.fromJson(Map<String, dynamic> json) {
    return OfflineBackupConfig(
      maxQueueSize: json['maxQueueSize'] ?? 50,
      maxRetryAttempts: json['maxRetryAttempts'] ?? 3,
      retryDelay: Duration(milliseconds: json['retryDelay'] ?? 300000),
      maxLocalStorageMB: json['maxLocalStorageMB'] ?? 500,
      autoCleanupOnSync: json['autoCleanupOnSync'] ?? true,
      priorityCategories: (json['priorityCategories'] as List<dynamic>?)
          ?.map((e) => DataCategory.values.firstWhere(
                (category) => category.name == e,
                orElse: () => DataCategory.transactions,
              ))
          .toList() ?? [DataCategory.transactions, DataCategory.wallets],
    );
  }
}

/// Statistics about offline backup queue
class OfflineBackupStats {
  final int totalItems;
  final int pendingItems;
  final int completedItems;
  final int failedItems;
  final int totalSizeMB;
  final DateTime? oldestItemDate;
  final DateTime? newestItemDate;

  const OfflineBackupStats({
    required this.totalItems,
    required this.pendingItems,
    required this.completedItems,
    required this.failedItems,
    required this.totalSizeMB,
    this.oldestItemDate,
    this.newestItemDate,
  });

  /// Check if queue is near capacity
  bool isNearCapacity(int maxSize) => totalItems >= (maxSize * 0.8);

  /// Check if storage is near limit
  bool isStorageNearLimit(int maxSizeMB) => totalSizeMB >= (maxSizeMB * 0.8);
}

extension OfflineBackupStatusExtension on OfflineBackupStatus {
  String get displayName {
    switch (this) {
      case OfflineBackupStatus.pending:
        return 'Bekliyor';
      case OfflineBackupStatus.syncing:
        return 'Senkronize Ediliyor';
      case OfflineBackupStatus.completed:
        return 'Tamamlandı';
      case OfflineBackupStatus.failed:
        return 'Başarısız';
    }
  }

  bool get isActive => this == OfflineBackupStatus.syncing;
  bool get isCompleted => this == OfflineBackupStatus.completed;
  bool get isFailed => this == OfflineBackupStatus.failed;
}