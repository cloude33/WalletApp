import 'dart:async';
import 'package:flutter/material.dart';

/// Tracks and logs performance metrics
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, List<Duration>> _metrics = {};
  final List<PerformanceWarning> _warnings = [];

  /// Measure execution time of an operation
  Future<T> measure<T>(String operation, Future<T> Function() fn) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await fn();
      stopwatch.stop();

      logMetric(operation, stopwatch.elapsed);

      return result;
    } catch (e) {
      stopwatch.stop();
      logMetric(operation, stopwatch.elapsed);
      rethrow;
    }
  }

  /// Measure synchronous operation
  T measureSync<T>(String operation, T Function() fn) {
    final stopwatch = Stopwatch()..start();

    try {
      final result = fn();
      stopwatch.stop();

      logMetric(operation, stopwatch.elapsed);

      return result;
    } catch (e) {
      stopwatch.stop();
      logMetric(operation, stopwatch.elapsed);
      rethrow;
    }
  }

  /// Log a metric
  void logMetric(String name, Duration duration) {
    _metrics.putIfAbsent(name, () => []).add(duration);

    // Check for performance warnings (>500ms)
    if (duration.inMilliseconds > 500) {
      final warning = PerformanceWarning(
        operation: name,
        duration: duration,
        timestamp: DateTime.now(),
        type: WarningType.slowOperation,
      );
      _warnings.add(warning);

      debugPrint('⚠️ Performance Warning: $name took ${duration.inMilliseconds}ms');
    }

    // Keep only last 100 metrics per operation
    if (_metrics[name]!.length > 100) {
      _metrics[name]!.removeAt(0);
    }
  }

  /// Log memory warning
  void logMemoryWarning(int memoryBytes) {
    final memoryMB = memoryBytes / (1024 * 1024);

    if (memoryMB > 200) {
      final warning = PerformanceWarning(
        operation: 'Memory Usage',
        duration: Duration.zero,
        timestamp: DateTime.now(),
        type: WarningType.highMemory,
        details: '${memoryMB.toStringAsFixed(2)} MB',
      );
      _warnings.add(warning);

      debugPrint('⚠️ Memory Warning: ${memoryMB.toStringAsFixed(2)} MB');
    }
  }

  /// Get statistics for all operations
  Map<String, PerformanceStats> getStats() {
    final stats = <String, PerformanceStats>{};

    for (final entry in _metrics.entries) {
      final durations = entry.value;
      if (durations.isEmpty) continue;

      final total = durations.fold<int>(
        0,
        (sum, d) => sum + d.inMilliseconds,
      );
      final average = Duration(milliseconds: total ~/ durations.length);
      final min = durations.reduce((a, b) => a < b ? a : b);
      final max = durations.reduce((a, b) => a > b ? a : b);
      final warningCount = durations.where((d) => d.inMilliseconds > 500).length;

      stats[entry.key] = PerformanceStats(
        operation: entry.key,
        count: durations.length,
        average: average,
        min: min,
        max: max,
        warningCount: warningCount,
      );
    }

    return stats;
  }

  /// Get recent warnings
  List<PerformanceWarning> getWarnings({int limit = 50}) {
    return _warnings.reversed.take(limit).toList();
  }

  /// Clear all metrics
  void clear() {
    _metrics.clear();
    _warnings.clear();
  }

  /// Clear metrics for specific operation
  void clearOperation(String operation) {
    _metrics.remove(operation);
  }
}

/// Performance statistics
class PerformanceStats {
  final String operation;
  final int count;
  final Duration average;
  final Duration min;
  final Duration max;
  final int warningCount;

  PerformanceStats({
    required this.operation,
    required this.count,
    required this.average,
    required this.min,
    required this.max,
    required this.warningCount,
  });

  String get averageMs => '${average.inMilliseconds}ms';
  String get minMs => '${min.inMilliseconds}ms';
  String get maxMs => '${max.inMilliseconds}ms';
  double get warningRate => count > 0 ? (warningCount / count * 100) : 0;
}

/// Performance warning
class PerformanceWarning {
  final String operation;
  final Duration duration;
  final DateTime timestamp;
  final WarningType type;
  final String? details;

  PerformanceWarning({
    required this.operation,
    required this.duration,
    required this.timestamp,
    required this.type,
    this.details,
  });

  String get message {
    switch (type) {
      case WarningType.slowOperation:
        return '$operation took ${duration.inMilliseconds}ms';
      case WarningType.highMemory:
        return 'High memory usage: ${details ?? 'N/A'}';
    }
  }
}

/// Warning types
enum WarningType {
  slowOperation,
  highMemory,
}
