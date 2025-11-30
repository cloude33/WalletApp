import 'dart:async';
import 'dart:collection';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Manages offline operations and synchronization
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  final Queue<OfflineOperation> _queue = Queue();
  bool isOnline = true;
  final _syncController = StreamController<SyncStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Initialize offline sync service
  Future<void> initialize() async {
    // Check initial connectivity
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    isOnline = !result.contains(ConnectivityResult.none);

    // Listen to connectivity changes
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = isOnline;
      isOnline = !results.contains(ConnectivityResult.none);

      if (!wasOnline && isOnline) {
        // Just came online, sync queued operations
        syncAll();
      }

      _syncController.add(SyncStatus(
        isOnline: isOnline,
        queueSize: _queue.length,
      ));
    });
  }

  /// Queue an operation for later sync
  Future<void> queueOperation(OfflineOperation operation) async {
    _queue.add(operation);
    
    _syncController.add(SyncStatus(
      isOnline: isOnline,
      queueSize: _queue.length,
    ));

    // If online, try to sync immediately
    if (isOnline) {
      await syncAll();
    }
  }

  /// Sync all queued operations
  Future<void> syncAll() async {
    if (!isOnline || _queue.isEmpty) return;

    _syncController.add(SyncStatus(
      isOnline: isOnline,
      queueSize: _queue.length,
      isSyncing: true,
    ));

    final operations = List<OfflineOperation>.from(_queue);
    final failedOperations = <OfflineOperation>[];

    for (final operation in operations) {
      try {
        await _executeOperation(operation);
        _queue.remove(operation);
      } catch (e) {
        debugPrint('Failed to sync operation ${operation.id}: $e');
        
        // Increment retry count
        final updatedOp = operation.copyWith(
          retryCount: operation.retryCount + 1,
        );

        // Remove old and add updated
        _queue.remove(operation);
        
        // Only retry up to 3 times
        if (updatedOp.retryCount < 3) {
          failedOperations.add(updatedOp);
        }
      }
    }

    // Re-add failed operations to queue
    for (final op in failedOperations) {
      _queue.add(op);
    }

    _syncController.add(SyncStatus(
      isOnline: isOnline,
      queueSize: _queue.length,
      isSyncing: false,
    ));
  }

  /// Execute a single operation
  Future<void> _executeOperation(OfflineOperation operation) async {
    // This would call the appropriate service method based on operation type
    // For now, just simulate execution
    await Future.delayed(const Duration(milliseconds: 100));
    
    // In real implementation:
    // switch (operation.type) {
    //   case OperationType.create:
    //     await _dataService.create(operation.entityType, operation.data);
    //   case OperationType.update:
    //     await _dataService.update(operation.entityType, operation.data);
    //   case OperationType.delete:
    //     await _dataService.delete(operation.entityType, operation.data['id']);
    // }
  }

  /// Handle sync conflicts (local changes vs server changes)
  Future<void> handleConflict(Conflict conflict) async {
    // Strategy: Local changes win (as per requirements)
    debugPrint('Conflict detected: ${conflict.description}');
    debugPrint('Prioritizing local changes');
    
    // Log conflict for review
    // In production, you might want to store conflicts for user review
  }

  /// Get sync status stream
  Stream<SyncStatus> get syncStream => _syncController.stream;

  /// Get current queue size
  int get queueSize => _queue.length;

  /// Clear all queued operations
  void clearQueue() {
    _queue.clear();
    _syncController.add(SyncStatus(
      isOnline: isOnline,
      queueSize: 0,
    ));
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncController.close();
  }
}

/// Offline operation model
class OfflineOperation {
  final String id;
  final OperationType type;
  final String entityType;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  OfflineOperation({
    required this.id,
    required this.type,
    required this.entityType,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  OfflineOperation copyWith({
    String? id,
    OperationType? type,
    String? entityType,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? retryCount,
  }) {
    return OfflineOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      entityType: entityType ?? this.entityType,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// Operation types
enum OperationType {
  create,
  update,
  delete,
}

/// Sync status
class SyncStatus {
  final bool isOnline;
  final int queueSize;
  final bool isSyncing;

  SyncStatus({
    required this.isOnline,
    required this.queueSize,
    this.isSyncing = false,
  });
}

/// Conflict model
class Conflict {
  final String entityType;
  final String entityId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final String description;

  Conflict({
    required this.entityType,
    required this.entityId,
    required this.localData,
    required this.serverData,
    required this.description,
  });
}
