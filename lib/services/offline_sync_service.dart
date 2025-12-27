import 'dart:async';
import 'dart:collection';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  final Queue<OfflineOperation> _queue = Queue();
  bool isOnline = true;
  final _syncController = StreamController<SyncStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Future<void> initialize() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    isOnline = !result.contains(ConnectivityResult.none);
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((
      results,
    ) {
      final wasOnline = isOnline;
      isOnline = !results.contains(ConnectivityResult.none);

      if (!wasOnline && isOnline) {
        syncAll();
      }

      _syncController.add(
        SyncStatus(isOnline: isOnline, queueSize: _queue.length),
      );
    });
  }
  Future<void> queueOperation(OfflineOperation operation) async {
    _queue.add(operation);

    _syncController.add(
      SyncStatus(isOnline: isOnline, queueSize: _queue.length),
    );
    if (isOnline) {
      await syncAll();
    }
  }
  Future<void> syncAll() async {
    if (!isOnline || _queue.isEmpty) return;

    _syncController.add(
      SyncStatus(isOnline: isOnline, queueSize: _queue.length, isSyncing: true),
    );

    final operations = List<OfflineOperation>.from(_queue);
    final failedOperations = <OfflineOperation>[];

    for (final operation in operations) {
      try {
        await _executeOperation(operation);
        _queue.remove(operation);
      } catch (e) {
        debugPrint('Failed to sync operation ${operation.id}: $e');
        final updatedOp = operation.copyWith(
          retryCount: operation.retryCount + 1,
        );
        _queue.remove(operation);
        if (updatedOp.retryCount < 3) {
          failedOperations.add(updatedOp);
        }
      }
    }
    for (final op in failedOperations) {
      _queue.add(op);
    }

    _syncController.add(
      SyncStatus(
        isOnline: isOnline,
        queueSize: _queue.length,
        isSyncing: false,
      ),
    );
  }
  Future<void> _executeOperation(OfflineOperation operation) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
  Future<void> handleConflict(Conflict conflict) async {
    debugPrint('Conflict detected: ${conflict.description}');
    debugPrint('Prioritizing local changes');
  }
  Stream<SyncStatus> get syncStream => _syncController.stream;
  int get queueSize => _queue.length;
  void clearQueue() {
    _queue.clear();
    _syncController.add(SyncStatus(isOnline: isOnline, queueSize: 0));
  }
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncController.close();
  }
}
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
enum OperationType { create, update, delete }
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
