import 'backup_enums.dart';

/// Represents a change detected in data for incremental backup
class DataChange {
  final String entityType;
  final String entityId;
  final ChangeType type;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final DateTime timestamp;

  const DataChange({
    required this.entityType,
    required this.entityId,
    required this.type,
    this.oldData,
    this.newData,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'entityType': entityType,
    'entityId': entityId,
    'type': type.name,
    'oldData': oldData,
    'newData': newData,
    'timestamp': timestamp.toIso8601String(),
  };

  factory DataChange.fromJson(Map<String, dynamic> json) {
    return DataChange(
      entityType: json['entityType'] ?? '',
      entityId: json['entityId'] ?? '',
      type: ChangeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChangeType.update,
      ),
      oldData: json['oldData'] as Map<String, dynamic>?,
      newData: json['newData'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  /// Create a change for a new entity
  factory DataChange.create({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> newData,
    DateTime? timestamp,
  }) {
    return DataChange(
      entityType: entityType,
      entityId: entityId,
      type: ChangeType.create,
      newData: newData,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Create a change for an updated entity
  factory DataChange.update({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> oldData,
    required Map<String, dynamic> newData,
    DateTime? timestamp,
  }) {
    return DataChange(
      entityType: entityType,
      entityId: entityId,
      type: ChangeType.update,
      oldData: oldData,
      newData: newData,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Create a change for a deleted entity
  factory DataChange.delete({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> oldData,
    DateTime? timestamp,
  }) {
    return DataChange(
      entityType: entityType,
      entityId: entityId,
      type: ChangeType.delete,
      oldData: oldData,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Check if this change represents a creation
  bool get isCreate => type == ChangeType.create;

  /// Check if this change represents an update
  bool get isUpdate => type == ChangeType.update;

  /// Check if this change represents a deletion
  bool get isDelete => type == ChangeType.delete;

  /// Get the size of the change in bytes (approximate)
  int get approximateSize {
    int size = 0;
    if (oldData != null) {
      size += oldData.toString().length;
    }
    if (newData != null) {
      size += newData.toString().length;
    }
    return size;
  }
}

/// Container for incremental backup data
class IncrementalData {
  final DateTime referenceDate;
  final List<DataChange> changes;
  final Map<String, String> entityHashes;
  final int totalChanges;

  const IncrementalData({
    required this.referenceDate,
    required this.changes,
    required this.entityHashes,
    required this.totalChanges,
  });

  Map<String, dynamic> toJson() => {
    'referenceDate': referenceDate.toIso8601String(),
    'changes': changes.map((c) => c.toJson()).toList(),
    'entityHashes': entityHashes,
    'totalChanges': totalChanges,
  };

  factory IncrementalData.fromJson(Map<String, dynamic> json) {
    return IncrementalData(
      referenceDate: DateTime.parse(json['referenceDate']),
      changes: (json['changes'] as List<dynamic>?)
          ?.map((c) => DataChange.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
      entityHashes: Map<String, String>.from(json['entityHashes'] ?? {}),
      totalChanges: json['totalChanges'] ?? 0,
    );
  }

  /// Check if there are any changes
  bool get hasChanges => changes.isNotEmpty;

  /// Get changes by type
  List<DataChange> getChangesByType(ChangeType type) {
    return changes.where((c) => c.type == type).toList();
  }

  /// Get changes by entity type
  List<DataChange> getChangesByEntityType(String entityType) {
    return changes.where((c) => c.entityType == entityType).toList();
  }

  /// Get the total size of all changes (approximate)
  int get approximateTotalSize {
    return changes.fold(0, (sum, change) => sum + change.approximateSize);
  }

  /// Get statistics about the changes
  Map<String, int> get changeStatistics {
    final stats = <String, int>{
      'creates': 0,
      'updates': 0,
      'deletes': 0,
    };

    for (final change in changes) {
      switch (change.type) {
        case ChangeType.create:
          stats['creates'] = (stats['creates'] ?? 0) + 1;
          break;
        case ChangeType.update:
          stats['updates'] = (stats['updates'] ?? 0) + 1;
          break;
        case ChangeType.delete:
          stats['deletes'] = (stats['deletes'] ?? 0) + 1;
          break;
      }
    }

    return stats;
  }
}

/// Package containing backup data
class BackupPackage {
  final String id;
  final BackupType type;
  final DateTime createdAt;
  final Map<String, dynamic> data;
  final String checksum;
  final int originalSize;
  final int compressedSize;
  final String? parentPackageId;

  const BackupPackage({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.data,
    required this.checksum,
    required this.originalSize,
    required this.compressedSize,
    this.parentPackageId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'createdAt': createdAt.toIso8601String(),
    'data': data,
    'checksum': checksum,
    'originalSize': originalSize,
    'compressedSize': compressedSize,
    'parentPackageId': parentPackageId,
  };

  factory BackupPackage.fromJson(Map<String, dynamic> json) {
    return BackupPackage(
      id: json['id'] ?? '',
      type: BackupType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BackupType.full,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      data: json['data'] as Map<String, dynamic>? ?? {},
      checksum: json['checksum'] ?? '',
      originalSize: json['originalSize'] ?? 0,
      compressedSize: json['compressedSize'] ?? 0,
      parentPackageId: json['parentPackageId'],
    );
  }

  /// Check if this is an incremental package
  bool get isIncremental => type == BackupType.incremental;

  /// Check if this package has a parent
  bool get hasParent => parentPackageId != null;

  /// Get compression ratio
  double get compressionRatio => 
      originalSize > 0 ? compressedSize / originalSize : 0.0;

  /// Get compression efficiency as percentage
  double get compressionEfficiency => 
      originalSize > 0 ? (1 - compressionRatio) * 100 : 0.0;
}

/// Information about a corrupted backup
class CorruptedBackup {
  final String backupId;
  final String filePath;
  final List<String> errors;
  final DateTime detectedAt;
  final String expectedChecksum;
  final String actualChecksum;

  const CorruptedBackup({
    required this.backupId,
    required this.filePath,
    required this.errors,
    required this.detectedAt,
    required this.expectedChecksum,
    required this.actualChecksum,
  });

  Map<String, dynamic> toJson() => {
    'backupId': backupId,
    'filePath': filePath,
    'errors': errors,
    'detectedAt': detectedAt.toIso8601String(),
    'expectedChecksum': expectedChecksum,
    'actualChecksum': actualChecksum,
  };

  factory CorruptedBackup.fromJson(Map<String, dynamic> json) {
    return CorruptedBackup(
      backupId: json['backupId'] ?? '',
      filePath: json['filePath'] ?? '',
      errors: List<String>.from(json['errors'] ?? []),
      detectedAt: DateTime.parse(json['detectedAt']),
      expectedChecksum: json['expectedChecksum'] ?? '',
      actualChecksum: json['actualChecksum'] ?? '',
    );
  }

  /// Check if checksums match
  bool get checksumsMatch => expectedChecksum == actualChecksum;

  /// Get a summary of the corruption
  String get corruptionSummary {
    if (errors.isEmpty) return 'Checksum mismatch';
    return errors.join(', ');
  }
}