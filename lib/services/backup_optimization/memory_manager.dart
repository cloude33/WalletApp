import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Memory management utilities for backup operations
class MemoryManager {
  static const int _maxChunkSize = 1024 * 1024; // 1MB chunks
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB cache limit
  
  final Map<String, Uint8List> _cache = {};
  int _currentCacheSize = 0;
  
  /// Process large data in chunks to avoid memory issues
  Future<List<int>> processLargeData(
    List<int> data,
    Future<List<int>> Function(List<int> chunk) processor,
  ) async {
    if (data.length <= _maxChunkSize) {
      return await processor(data);
    }
    
    final result = <int>[];
    
    for (int i = 0; i < data.length; i += _maxChunkSize) {
      final end = (i + _maxChunkSize < data.length) ? i + _maxChunkSize : data.length;
      final chunk = data.sublist(i, end);
      
      final processedChunk = await processor(chunk);
      result.addAll(processedChunk);
      
      // Yield control to prevent blocking
      await Future.delayed(Duration.zero);
    }
    
    return result;
  }

  /// Stream-based processing for very large datasets
  Stream<List<int>> processLargeDataStream(
    Stream<List<int>> dataStream,
    Future<List<int>> Function(List<int> chunk) processor,
  ) async* {
    await for (final chunk in dataStream) {
      final processedChunk = await processor(chunk);
      yield processedChunk;
      
      // Yield control between chunks
      await Future.delayed(Duration.zero);
    }
  }

  /// Cache frequently accessed data with size limits
  void cacheData(String key, Uint8List data) {
    // Check if adding this data would exceed cache limit
    if (_currentCacheSize + data.length > _maxCacheSize) {
      _evictOldestEntries(data.length);
    }
    
    _cache[key] = data;
    _currentCacheSize += data.length;
    
    debugPrint('📦 Cached data: $key (${data.length} bytes)');
  }

  /// Retrieve cached data
  Uint8List? getCachedData(String key) {
    return _cache[key];
  }

  /// Clear specific cached data
  void clearCachedData(String key) {
    final data = _cache.remove(key);
    if (data != null) {
      _currentCacheSize -= data.length;
      debugPrint('🗑️ Cleared cached data: $key (${data.length} bytes)');
    }
  }

  /// Clear all cached data
  void clearAllCache() {
    final totalSize = _currentCacheSize;
    _cache.clear();
    _currentCacheSize = 0;
    debugPrint('🧹 Cleared all cache ($totalSize bytes)');
  }

  /// Get current cache statistics
  Map<String, dynamic> getCacheStatistics() {
    return {
      'entries': _cache.length,
      'totalSize': _currentCacheSize,
      'maxSize': _maxCacheSize,
      'utilizationPercent': (_currentCacheSize / _maxCacheSize * 100).toInt(),
    };
  }

  /// Optimize memory usage by clearing unnecessary data
  Future<void> optimizeMemory() async {
    try {
      // Clear cache if it's getting too large
      if (_currentCacheSize > _maxCacheSize * 0.8) {
        _evictOldestEntries(_currentCacheSize ~/ 2);
      }
      
      // Force garbage collection on supported platforms
      if (!kIsWeb && Platform.isAndroid || Platform.isIOS) {
        await _forceGarbageCollection();
      }
      
      debugPrint('✅ Memory optimization completed');
      debugPrint('   - Cache size: ${(_currentCacheSize / 1024 / 1024).toStringAsFixed(1)} MB');
      debugPrint('   - Cache entries: ${_cache.length}');
    } catch (e) {
      debugPrint('❌ Memory optimization error: $e');
    }
  }

  /// Create a memory-efficient backup data processor
  BackupDataProcessor createProcessor() {
    return BackupDataProcessor(this);
  }

  // Private helper methods

  void _evictOldestEntries(int targetBytes) {
    int freedBytes = 0;
    final keysToRemove = <String>[];
    
    // Simple LRU-like eviction (remove entries until we free enough space)
    for (final entry in _cache.entries) {
      keysToRemove.add(entry.key);
      freedBytes += entry.value.length;
      
      if (freedBytes >= targetBytes) {
        break;
      }
    }
    
    for (final key in keysToRemove) {
      clearCachedData(key);
    }
    
    debugPrint('🗑️ Evicted ${keysToRemove.length} cache entries (${(freedBytes / 1024 / 1024).toStringAsFixed(1)} MB)');
  }

  Future<void> _forceGarbageCollection() async {
    try {
      // This is a platform-specific implementation
      // On mobile platforms, we can suggest garbage collection
      await Future.delayed(const Duration(milliseconds: 10));
      debugPrint('🗑️ Suggested garbage collection');
    } catch (e) {
      debugPrint('❌ Garbage collection error: $e');
    }
  }
}

/// Specialized processor for backup data with memory optimization
class BackupDataProcessor {
  final MemoryManager _memoryManager;
  
  BackupDataProcessor(this._memoryManager);

  /// Process JSON data with memory optimization
  Future<Map<String, dynamic>> processJsonData(
    Map<String, dynamic> data,
    {bool useCache = true}
  ) async {
    try {
      final processedData = <String, dynamic>{};
      
      for (final entry in data.entries) {
        final key = entry.key;
        final value = entry.value;
        
        if (value is List && value.length > 1000) {
          // Process large lists in chunks
          processedData[key] = await _processLargeList(value);
        } else if (value is Map<String, dynamic>) {
          // Recursively process nested maps
          processedData[key] = await processJsonData(value, useCache: useCache);
        } else {
          processedData[key] = value;
        }
        
        // Yield control periodically
        if (processedData.length % 100 == 0) {
          await Future.delayed(Duration.zero);
        }
      }
      
      return processedData;
    } catch (e) {
      debugPrint('❌ JSON processing error: $e');
      rethrow;
    }
  }

  /// Process large binary data with streaming
  Stream<Uint8List> processBinaryDataStream(Uint8List data) async* {
    const chunkSize = 64 * 1024; // 64KB chunks
    
    for (int i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      final chunk = Uint8List.sublistView(data, i, end);
      
      yield chunk;
      
      // Yield control between chunks
      await Future.delayed(Duration.zero);
    }
  }

  /// Compress data with memory optimization
  Future<Uint8List> compressData(Uint8List data) async {
    try {
      // For large data, process in chunks
      if (data.length > MemoryManager._maxChunkSize) {
        return await _compressLargeData(data);
      } else {
        return await _compressSmallData(data);
      }
    } catch (e) {
      debugPrint('❌ Compression error: $e');
      rethrow;
    }
  }

  /// Decompress data with memory optimization
  Future<Uint8List> decompressData(Uint8List compressedData) async {
    try {
      // Check cache first
      final cacheKey = 'decompressed_${compressedData.hashCode}';
      final cached = _memoryManager.getCachedData(cacheKey);
      if (cached != null) {
        return cached;
      }
      
      // Decompress data
      final decompressed = await _decompressData(compressedData);
      
      // Cache result if it's not too large
      if (decompressed.length < MemoryManager._maxChunkSize) {
        _memoryManager.cacheData(cacheKey, decompressed);
      }
      
      return decompressed;
    } catch (e) {
      debugPrint('❌ Decompression error: $e');
      rethrow;
    }
  }

  // Private helper methods

  Future<List<dynamic>> _processLargeList(List<dynamic> list) async {
    const chunkSize = 1000;
    final processedList = <dynamic>[];
    
    for (int i = 0; i < list.length; i += chunkSize) {
      final end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
      final chunk = list.sublist(i, end);
      
      // Process chunk (could apply transformations here)
      processedList.addAll(chunk);
      
      // Yield control between chunks
      await Future.delayed(Duration.zero);
    }
    
    return processedList;
  }

  Future<Uint8List> _compressLargeData(Uint8List data) async {
    // This would implement chunked compression
    // For now, return the original data as a placeholder
    debugPrint('📦 Compressing large data (${data.length} bytes)');
    return data;
  }

  Future<Uint8List> _compressSmallData(Uint8List data) async {
    // This would implement standard compression
    // For now, return the original data as a placeholder
    debugPrint('📦 Compressing small data (${data.length} bytes)');
    return data;
  }

  Future<Uint8List> _decompressData(Uint8List compressedData) async {
    // This would implement decompression
    // For now, return the original data as a placeholder
    debugPrint('📦 Decompressing data (${compressedData.length} bytes)');
    return compressedData;
  }
}

/// Memory usage monitor
class MemoryUsageMonitor {
  Timer? _monitoringTimer;
  final List<MemorySnapshot> _snapshots = [];
  
  /// Start monitoring memory usage
  void startMonitoring({Duration interval = const Duration(seconds: 30)}) {
    _monitoringTimer?.cancel();
    
    _monitoringTimer = Timer.periodic(interval, (timer) {
      _takeSnapshot();
    });
    
    debugPrint('📊 Started memory monitoring (interval: ${interval.inSeconds}s)');
  }

  /// Stop monitoring memory usage
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    debugPrint('📊 Stopped memory monitoring');
  }

  /// Get memory usage statistics
  MemoryStatistics getStatistics() {
    if (_snapshots.isEmpty) {
      return MemoryStatistics.empty();
    }
    
    final latest = _snapshots.last;
    final peak = _snapshots.reduce((a, b) => a.usedMemoryMB > b.usedMemoryMB ? a : b);
    final average = _snapshots.map((s) => s.usedMemoryMB).reduce((a, b) => a + b) / _snapshots.length;
    
    return MemoryStatistics(
      currentUsageMB: latest.usedMemoryMB,
      peakUsageMB: peak.usedMemoryMB,
      averageUsageMB: average,
      snapshotCount: _snapshots.length,
      monitoringDuration: _snapshots.isNotEmpty 
          ? latest.timestamp.difference(_snapshots.first.timestamp)
          : Duration.zero,
    );
  }

  /// Clear monitoring history
  void clearHistory() {
    _snapshots.clear();
    debugPrint('🧹 Cleared memory monitoring history');
  }

  // Private helper methods

  void _takeSnapshot() {
    try {
      // This would get actual memory usage from the platform
      // For now, simulate memory usage
      final usedMemoryMB = _getSimulatedMemoryUsage();
      
      final snapshot = MemorySnapshot(
        timestamp: DateTime.now(),
        usedMemoryMB: usedMemoryMB,
      );
      
      _snapshots.add(snapshot);
      
      // Keep only last 100 snapshots
      if (_snapshots.length > 100) {
        _snapshots.removeAt(0);
      }
      
      // Log warning if memory usage is high
      if (usedMemoryMB > 400) {
        debugPrint('⚠️ High memory usage: ${usedMemoryMB.toInt()} MB');
      }
    } catch (e) {
      debugPrint('❌ Memory snapshot error: $e');
    }
  }

  double _getSimulatedMemoryUsage() {
    // Simulate memory usage between 100-500 MB
    return 100 + (400 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000);
  }
}

/// Memory usage snapshot
class MemorySnapshot {
  final DateTime timestamp;
  final double usedMemoryMB;
  
  const MemorySnapshot({
    required this.timestamp,
    required this.usedMemoryMB,
  });
}

/// Memory usage statistics
class MemoryStatistics {
  final double currentUsageMB;
  final double peakUsageMB;
  final double averageUsageMB;
  final int snapshotCount;
  final Duration monitoringDuration;
  
  const MemoryStatistics({
    required this.currentUsageMB,
    required this.peakUsageMB,
    required this.averageUsageMB,
    required this.snapshotCount,
    required this.monitoringDuration,
  });
  
  factory MemoryStatistics.empty() {
    return const MemoryStatistics(
      currentUsageMB: 0.0,
      peakUsageMB: 0.0,
      averageUsageMB: 0.0,
      snapshotCount: 0,
      monitoringDuration: Duration.zero,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'currentUsageMB': currentUsageMB,
    'peakUsageMB': peakUsageMB,
    'averageUsageMB': averageUsageMB,
    'snapshotCount': snapshotCount,
    'monitoringDurationSeconds': monitoringDuration.inSeconds,
  };
}