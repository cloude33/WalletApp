import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../models/backup_optimization/incremental_data.dart';

/// Service for detecting changes in data for incremental backups
class DeltaDetector {
  /// Hash calculator for data integrity
  final HashCalculator _hashCalculator = HashCalculator();

  /// Detects changes in data since the last backup date
  Future<IncrementalData> detectChanges(
    Map<String, dynamic> currentData,
    DateTime lastBackupDate,
    Map<String, String>? previousHashes,
  ) async {
    final changes = <DataChange>[];
    final currentHashes = <String, String>{};

    // Process each data category
    for (final entry in currentData.entries) {
      final categoryName = entry.key;
      final categoryData = entry.value;

      if (categoryData is List) {
        // Handle list data (transactions, wallets, etc.)
        final categoryChanges = await _detectListChanges(
          categoryName,
          categoryData,
          lastBackupDate,
          previousHashes,
          currentHashes,
        );
        changes.addAll(categoryChanges);
      } else if (categoryData is Map<String, dynamic>) {
        // Handle map data (settings, user data, etc.)
        final categoryChanges = await _detectMapChanges(
          categoryName,
          categoryData,
          lastBackupDate,
          previousHashes,
          currentHashes,
        );
        changes.addAll(categoryChanges);
      }
    }

    return IncrementalData(
      referenceDate: lastBackupDate,
      changes: changes,
      entityHashes: currentHashes,
      totalChanges: changes.length,
    );
  }

  /// Detects changes in list-based data
  Future<List<DataChange>> _detectListChanges(
    String entityType,
    List<dynamic> currentList,
    DateTime lastBackupDate,
    Map<String, String>? previousHashes,
    Map<String, String> currentHashes,
  ) async {
    final changes = <DataChange>[];

    for (final item in currentList) {
      if (item is Map<String, dynamic>) {
        final entityId = _extractEntityId(item);
        if (entityId == null) continue;

        final entityKey = '${entityType}_$entityId';
        final currentHash = await _hashCalculator.calculateHash(item);
        currentHashes[entityKey] = currentHash;

        // Check if entity existed in previous backup
        final previousHash = previousHashes?[entityKey];

        if (previousHash == null) {
          // New entity - check if created after last backup
          final createdAt = _extractTimestamp(item);
          if (createdAt == null || createdAt.isAfter(lastBackupDate)) {
            changes.add(DataChange.create(
              entityType: entityType,
              entityId: entityId,
              newData: item,
              timestamp: createdAt ?? DateTime.now(),
            ));
          }
        } else if (previousHash != currentHash) {
          // Entity was modified
          final modifiedAt = _extractTimestamp(item, isModified: true);
          if (modifiedAt == null || modifiedAt.isAfter(lastBackupDate)) {
            changes.add(DataChange.update(
              entityType: entityType,
              entityId: entityId,
              oldData: {}, // We don't have old data in this context
              newData: item,
              timestamp: modifiedAt ?? DateTime.now(),
            ));
          }
        }
      }
    }

    return changes;
  }

  /// Detects changes in map-based data
  Future<List<DataChange>> _detectMapChanges(
    String entityType,
    Map<String, dynamic> currentMap,
    DateTime lastBackupDate,
    Map<String, String>? previousHashes,
    Map<String, String> currentHashes,
  ) async {
    final changes = <DataChange>[];

    for (final entry in currentMap.entries) {
      final entityId = entry.key;
      final entityData = entry.value;

      if (entityData is Map<String, dynamic>) {
        final entityKey = '${entityType}_$entityId';
        final currentHash = await _hashCalculator.calculateHash(entityData);
        currentHashes[entityKey] = currentHash;

        final previousHash = previousHashes?[entityKey];

        if (previousHash == null) {
          // New entity
          final createdAt = _extractTimestamp(entityData);
          if (createdAt == null || createdAt.isAfter(lastBackupDate)) {
            changes.add(DataChange.create(
              entityType: entityType,
              entityId: entityId,
              newData: entityData,
              timestamp: createdAt ?? DateTime.now(),
            ));
          }
        } else if (previousHash != currentHash) {
          // Modified entity
          final modifiedAt = _extractTimestamp(entityData, isModified: true);
          if (modifiedAt == null || modifiedAt.isAfter(lastBackupDate)) {
            changes.add(DataChange.update(
              entityType: entityType,
              entityId: entityId,
              oldData: {},
              newData: entityData,
              timestamp: modifiedAt ?? DateTime.now(),
            ));
          }
        }
      }
    }

    return changes;
  }

  /// Extracts entity ID from data
  String? _extractEntityId(Map<String, dynamic> data) {
    // Try common ID field names
    return data['id']?.toString() ?? 
           data['uuid']?.toString() ?? 
           data['key']?.toString();
  }

  /// Extracts timestamp from data
  DateTime? _extractTimestamp(Map<String, dynamic> data, {bool isModified = false}) {
    try {
      // Try different timestamp field names
      final timestampFields = isModified 
          ? ['updatedAt', 'modifiedAt', 'lastModified', 'createdAt']
          : ['createdAt', 'created', 'timestamp', 'date'];

      for (final field in timestampFields) {
        final value = data[field];
        if (value != null) {
          if (value is DateTime) {
            return value;
          } else if (value is String) {
            return DateTime.tryParse(value);
          } else if (value is int) {
            return DateTime.fromMillisecondsSinceEpoch(value);
          }
        }
      }
    } catch (e) {
      debugPrint('Error extracting timestamp: $e');
    }
    return null;
  }

  /// Compares two data sets and returns detailed changes
  Future<List<DataChange>> calculateDeltas(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) async {
    final changes = <DataChange>[];

    // Get all entity keys from both datasets
    final allKeys = <String>{};
    allKeys.addAll(oldData.keys);
    allKeys.addAll(newData.keys);

    for (final key in allKeys) {
      final oldValue = oldData[key];
      final newValue = newData[key];

      if (oldValue == null && newValue != null) {
        // New entity
        if (newValue is List) {
          for (int i = 0; i < newValue.length; i++) {
            if (newValue[i] is Map<String, dynamic>) {
              final entityId = _extractEntityId(newValue[i]) ?? i.toString();
              changes.add(DataChange.create(
                entityType: key,
                entityId: entityId,
                newData: newValue[i],
              ));
            }
          }
        } else if (newValue is Map<String, dynamic>) {
          changes.add(DataChange.create(
            entityType: key,
            entityId: 'root',
            newData: newValue,
          ));
        }
      } else if (oldValue != null && newValue == null) {
        // Deleted entity
        if (oldValue is List) {
          for (int i = 0; i < oldValue.length; i++) {
            if (oldValue[i] is Map<String, dynamic>) {
              final entityId = _extractEntityId(oldValue[i]) ?? i.toString();
              changes.add(DataChange.delete(
                entityType: key,
                entityId: entityId,
                oldData: oldValue[i],
              ));
            }
          }
        } else if (oldValue is Map<String, dynamic>) {
          changes.add(DataChange.delete(
            entityType: key,
            entityId: 'root',
            oldData: oldValue,
          ));
        }
      } else if (oldValue != null && newValue != null) {
        // Potentially modified entity
        final oldHash = await _hashCalculator.calculateHash(oldValue);
        final newHash = await _hashCalculator.calculateHash(newValue);

        if (oldHash != newHash) {
          if (oldValue is List && newValue is List) {
            final listChanges = await _compareListData(key, oldValue, newValue);
            changes.addAll(listChanges);
          } else if (oldValue is Map<String, dynamic> && 
                     newValue is Map<String, dynamic>) {
            changes.add(DataChange.update(
              entityType: key,
              entityId: 'root',
              oldData: oldValue,
              newData: newValue,
            ));
          }
        }
      }
    }

    return changes;
  }

  /// Compares two lists and returns changes
  Future<List<DataChange>> _compareListData(
    String entityType,
    List<dynamic> oldList,
    List<dynamic> newList,
  ) async {
    final changes = <DataChange>[];
    
    // Create maps for easier comparison
    final oldMap = <String, Map<String, dynamic>>{};
    final newMap = <String, Map<String, dynamic>>{};

    // Build old data map
    for (int i = 0; i < oldList.length; i++) {
      if (oldList[i] is Map<String, dynamic>) {
        final entityId = _extractEntityId(oldList[i]) ?? i.toString();
        oldMap[entityId] = oldList[i];
      }
    }

    // Build new data map
    for (int i = 0; i < newList.length; i++) {
      if (newList[i] is Map<String, dynamic>) {
        final entityId = _extractEntityId(newList[i]) ?? i.toString();
        newMap[entityId] = newList[i];
      }
    }

    // Find all entity IDs
    final allIds = <String>{};
    allIds.addAll(oldMap.keys);
    allIds.addAll(newMap.keys);

    for (final entityId in allIds) {
      final oldEntity = oldMap[entityId];
      final newEntity = newMap[entityId];

      if (oldEntity == null && newEntity != null) {
        // Created
        changes.add(DataChange.create(
          entityType: entityType,
          entityId: entityId,
          newData: newEntity,
        ));
      } else if (oldEntity != null && newEntity == null) {
        // Deleted
        changes.add(DataChange.delete(
          entityType: entityType,
          entityId: entityId,
          oldData: oldEntity,
        ));
      } else if (oldEntity != null && newEntity != null) {
        // Check if modified
        final oldHash = await _hashCalculator.calculateHash(oldEntity);
        final newHash = await _hashCalculator.calculateHash(newEntity);

        if (oldHash != newHash) {
          changes.add(DataChange.update(
            entityType: entityType,
            entityId: entityId,
            oldData: oldEntity,
            newData: newEntity,
          ));
        }
      }
    }

    return changes;
  }
}

/// Utility class for calculating hashes of data
class HashCalculator {
  /// Calculates SHA-256 hash of the given data
  Future<String> calculateHash(dynamic data) async {
    try {
      final jsonString = jsonEncode(data);
      final bytes = utf8.encode(jsonString);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      debugPrint('Error calculating hash: $e');
      return '';
    }
  }

  /// Calculates hash for a map of data
  Future<Map<String, String>> calculateHashMap(
    Map<String, dynamic> dataMap,
  ) async {
    final hashes = <String, String>{};
    
    for (final entry in dataMap.entries) {
      hashes[entry.key] = await calculateHash(entry.value);
    }
    
    return hashes;
  }

  /// Verifies if data matches the expected hash
  Future<bool> verifyHash(dynamic data, String expectedHash) async {
    final actualHash = await calculateHash(data);
    return actualHash == expectedHash;
  }
}