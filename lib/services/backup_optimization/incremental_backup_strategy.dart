import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/backup_optimization/incremental_data.dart';
import '../../models/backup_optimization/backup_enums.dart';
import 'delta_detector.dart';

/// Strategy for creating and managing incremental backups
class IncrementalBackupStrategy {
  final DeltaDetector _deltaDetector = DeltaDetector();
  final HashCalculator _hashCalculator = HashCalculator();

  static const String _lastBackupDateKey = 'last_incremental_backup_date';
  static const String _lastBackupHashesKey = 'last_backup_hashes';
  static const String _referenceBackupIdKey = 'reference_backup_id';

  /// Detects changes since the last backup
  Future<IncrementalData> detectChanges(DateTime lastBackupDate) async {
    // This method would typically be called with current data
    // For now, we'll return an empty incremental data structure
    return IncrementalData(
      referenceDate: lastBackupDate,
      changes: [],
      entityHashes: {},
      totalChanges: 0,
    );
  }

  /// Detects changes in current data compared to previous backup
  Future<IncrementalData> detectChangesInData(
    Map<String, dynamic> currentData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get last backup information
    final lastBackupDateStr = prefs.getString(_lastBackupDateKey);
    final lastBackupDate = lastBackupDateStr != null 
        ? DateTime.tryParse(lastBackupDateStr) ?? DateTime.now().subtract(const Duration(days: 30))
        : DateTime.now().subtract(const Duration(days: 30));

    // Get previous hashes
    final previousHashesStr = prefs.getString(_lastBackupHashesKey);
    Map<String, String>? previousHashes;
    if (previousHashesStr != null) {
      try {
        final decoded = jsonDecode(previousHashesStr);
        previousHashes = Map<String, String>.from(decoded);
      } catch (e) {
        debugPrint('Error decoding previous hashes: $e');
      }
    }

    // Detect changes using DeltaDetector
    return await _deltaDetector.detectChanges(
      currentData,
      lastBackupDate,
      previousHashes,
    );
  }

  /// Calculates deltas between two data sets
  Future<List<DataChange>> calculateDeltas(
    Map<String, dynamic> currentData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    
    // For incremental backup, we need to compare with stored reference data
    // In a real implementation, this would load the reference data from storage
    // For now, we'll use the delta detector to find changes
    
    final lastBackupDateStr = prefs.getString(_lastBackupDateKey);
    if (lastBackupDateStr == null) {
      // No previous backup, treat everything as new
      return _convertDataToChanges(currentData);
    }

    // Get previous hashes to detect changes
    final previousHashesStr = prefs.getString(_lastBackupHashesKey);
    if (previousHashesStr == null) {
      return _convertDataToChanges(currentData);
    }

    try {
      final previousHashes = Map<String, String>.from(
        jsonDecode(previousHashesStr),
      );
      
      final lastBackupDate = DateTime.parse(lastBackupDateStr);
      final incrementalData = await _deltaDetector.detectChanges(
        currentData,
        lastBackupDate,
        previousHashes,
      );
      
      return incrementalData.changes;
    } catch (e) {
      debugPrint('Error calculating deltas: $e');
      return _convertDataToChanges(currentData);
    }
  }

  /// Converts all data to create changes (for first backup)
  List<DataChange> _convertDataToChanges(Map<String, dynamic> data) {
    final changes = <DataChange>[];
    
    for (final entry in data.entries) {
      final categoryName = entry.key;
      final categoryData = entry.value;
      
      if (categoryData is List) {
        for (int i = 0; i < categoryData.length; i++) {
          if (categoryData[i] is Map<String, dynamic>) {
            final entityId = _extractEntityId(categoryData[i]) ?? i.toString();
            changes.add(DataChange.create(
              entityType: categoryName,
              entityId: entityId,
              newData: categoryData[i],
            ));
          }
        }
      } else if (categoryData is Map<String, dynamic>) {
        changes.add(DataChange.create(
          entityType: categoryName,
          entityId: 'root',
          newData: categoryData,
        ));
      }
    }
    
    return changes;
  }

  /// Creates an incremental backup package
  Future<BackupPackage> createIncrementalPackage(
    IncrementalData incrementalData,
  ) async {
    final packageId = _generatePackageId();
    final prefs = await SharedPreferences.getInstance();
    final parentPackageId = prefs.getString(_referenceBackupIdKey);

    // Prepare package data
    final packageData = {
      'incrementalData': incrementalData.toJson(),
      'referenceDate': incrementalData.referenceDate.toIso8601String(),
      'changeCount': incrementalData.totalChanges,
    };

    // Calculate sizes
    final jsonString = jsonEncode(packageData);
    final originalSize = utf8.encode(jsonString).length;
    
    // For now, assume no compression (would be handled by CompressionService)
    final compressedSize = originalSize;

    // Calculate checksum
    final checksum = await _hashCalculator.calculateHash(packageData);

    final package = BackupPackage(
      id: packageId,
      type: BackupType.incremental,
      createdAt: DateTime.now(),
      data: packageData,
      checksum: checksum,
      originalSize: originalSize,
      compressedSize: compressedSize,
      parentPackageId: parentPackageId,
    );

    // Store current backup information for next incremental backup
    await _storeBackupReference(
      packageId,
      incrementalData.entityHashes,
    );

    return package;
  }

  /// Reconstructs full data from a series of incremental packages
  Future<Map<String, dynamic>> reconstructFullData(
    List<BackupPackage> packages,
  ) async {
    if (packages.isEmpty) {
      return {};
    }

    // Sort packages by creation date
    packages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Find the base (full) backup
    BackupPackage? basePackage;
    final incrementalPackages = <BackupPackage>[];

    for (final package in packages) {
      if (package.type == BackupType.full) {
        basePackage = package;
        incrementalPackages.clear(); // Reset incremental packages after full backup
      } else if (package.type == BackupType.incremental) {
        incrementalPackages.add(package);
      }
    }

    if (basePackage == null) {
      throw Exception('No base (full) backup found for reconstruction');
    }

    // Start with base data
    Map<String, dynamic> reconstructedData = Map<String, dynamic>.from(
      basePackage.data['backupData'] ?? {},
    );

    // Apply incremental changes in order
    for (final incrementalPackage in incrementalPackages) {
      reconstructedData = await _applyIncrementalChanges(
        reconstructedData,
        incrementalPackage,
      );
    }

    return reconstructedData;
  }

  /// Applies incremental changes to existing data
  Future<Map<String, dynamic>> _applyIncrementalChanges(
    Map<String, dynamic> baseData,
    BackupPackage incrementalPackage,
  ) async {
    var result = Map<String, dynamic>.from(baseData);
    
    try {
      final incrementalData = incrementalPackage.data['incrementalData'];
      if (incrementalData == null) return result;

      final changes = (incrementalData['changes'] as List<dynamic>?)
          ?.map((c) => DataChange.fromJson(c as Map<String, dynamic>))
          .toList() ?? [];

      for (final change in changes) {
        result = _applyChange(result, change);
      }
    } catch (e) {
      debugPrint('Error applying incremental changes: $e');
    }

    return result;
  }

  /// Applies a single change to the data
  Map<String, dynamic> _applyChange(
    Map<String, dynamic> data,
    DataChange change,
  ) {
    final result = Map<String, dynamic>.from(data);
    
    try {
      switch (change.type) {
        case ChangeType.create:
          _applyCreateChange(result, change);
          break;
        case ChangeType.update:
          _applyUpdateChange(result, change);
          break;
        case ChangeType.delete:
          _applyDeleteChange(result, change);
          break;
      }
    } catch (e) {
      debugPrint('Error applying change ${change.type} for ${change.entityType}:${change.entityId}: $e');
    }

    return result;
  }

  /// Applies a create change
  void _applyCreateChange(Map<String, dynamic> data, DataChange change) {
    if (change.newData == null) return;

    final categoryData = data[change.entityType];
    
    if (categoryData is List) {
      // Add to list
      final newList = List<dynamic>.from(categoryData);
      newList.add(change.newData);
      data[change.entityType] = newList;
    } else if (categoryData is Map<String, dynamic>) {
      // Add to map
      final newMap = Map<String, dynamic>.from(categoryData);
      newMap[change.entityId] = change.newData;
      data[change.entityType] = newMap;
    } else {
      // Create new category
      if (change.entityId == 'root') {
        data[change.entityType] = change.newData;
      } else {
        data[change.entityType] = [change.newData];
      }
    }
  }

  /// Applies an update change
  void _applyUpdateChange(Map<String, dynamic> data, DataChange change) {
    if (change.newData == null) return;

    final categoryData = data[change.entityType];
    
    if (categoryData is List) {
      // Find and update in list
      final list = List<dynamic>.from(categoryData);
      for (int i = 0; i < list.length; i++) {
        if (list[i] is Map<String, dynamic>) {
          final entityId = _extractEntityId(list[i]) ?? i.toString();
          if (entityId == change.entityId) {
            list[i] = change.newData;
            break;
          }
        }
      }
      data[change.entityType] = list;
    } else if (categoryData is Map<String, dynamic>) {
      // Update in map
      final map = Map<String, dynamic>.from(categoryData);
      map[change.entityId] = change.newData;
      data[change.entityType] = map;
    }
  }

  /// Applies a delete change
  void _applyDeleteChange(Map<String, dynamic> data, DataChange change) {
    final categoryData = data[change.entityType];
    
    if (categoryData is List) {
      // Remove from list
      final list = List<dynamic>.from(categoryData);
      list.removeWhere((item) {
        if (item is Map<String, dynamic>) {
          final entityId = _extractEntityId(item);
          return entityId == change.entityId;
        }
        return false;
      });
      data[change.entityType] = list;
    } else if (categoryData is Map<String, dynamic>) {
      // Remove from map
      final map = Map<String, dynamic>.from(categoryData);
      map.remove(change.entityId);
      data[change.entityType] = map;
    }
  }

  /// Stores backup reference information for next incremental backup
  Future<void> _storeBackupReference(
    String backupId,
    Map<String, String> entityHashes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_referenceBackupIdKey, backupId);
    await prefs.setString(_lastBackupDateKey, DateTime.now().toIso8601String());
    await prefs.setString(_lastBackupHashesKey, jsonEncode(entityHashes));
  }

  /// Gets the last backup reference information
  Future<Map<String, dynamic>?> getLastBackupReference() async {
    final prefs = await SharedPreferences.getInstance();
    
    final backupId = prefs.getString(_referenceBackupIdKey);
    final dateStr = prefs.getString(_lastBackupDateKey);
    final hashesStr = prefs.getString(_lastBackupHashesKey);
    
    if (backupId == null || dateStr == null) {
      return null;
    }
    
    Map<String, String>? hashes;
    if (hashesStr != null) {
      try {
        hashes = Map<String, String>.from(jsonDecode(hashesStr));
      } catch (e) {
        debugPrint('Error decoding stored hashes: $e');
      }
    }
    
    return {
      'backupId': backupId,
      'date': DateTime.parse(dateStr),
      'hashes': hashes ?? <String, String>{},
    };
  }

  /// Clears backup reference (useful when creating a new full backup)
  Future<void> clearBackupReference() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_referenceBackupIdKey);
    await prefs.remove(_lastBackupDateKey);
    await prefs.remove(_lastBackupHashesKey);
  }

  /// Checks if incremental backup is possible
  Future<bool> canCreateIncrementalBackup() async {
    final reference = await getLastBackupReference();
    return reference != null;
  }

  /// Gets incremental backup statistics
  Future<Map<String, dynamic>> getIncrementalStats(
    IncrementalData incrementalData,
  ) async {
    final stats = incrementalData.changeStatistics;
    final totalSize = incrementalData.approximateTotalSize;
    
    return {
      'totalChanges': incrementalData.totalChanges,
      'creates': stats['creates'] ?? 0,
      'updates': stats['updates'] ?? 0,
      'deletes': stats['deletes'] ?? 0,
      'approximateSize': totalSize,
      'hasChanges': incrementalData.hasChanges,
    };
  }

  /// Extracts entity ID from data
  String? _extractEntityId(Map<String, dynamic> data) {
    return data['id']?.toString() ?? 
           data['uuid']?.toString() ?? 
           data['key']?.toString();
  }

  /// Generates a unique package ID
  String _generatePackageId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'inc_${timestamp}_$random';
  }
}