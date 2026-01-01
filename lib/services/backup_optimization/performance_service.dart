import 'dart:async';
import 'dart:math';

/// Service for monitoring and analyzing backup performance
class PerformanceService {
  final MetricsTracker _metricsTracker;
  final ReportAnalyzer _reportAnalyzer;
  final List<BackupMetrics> _metricsHistory = [];

  PerformanceService({
    MetricsTracker? metricsTracker,
    ReportAnalyzer? reportAnalyzer,
  }) : _metricsTracker = metricsTracker ?? MetricsTracker(),
       _reportAnalyzer = reportAnalyzer ?? ReportAnalyzer();

  /// Start tracking metrics for a backup operation
  Future<String> startMetricsCollection(String operationId) async {
    return await _metricsTracker.startTracking(operationId);
  }

  /// Stop tracking and collect final metrics
  Future<BackupMetrics> stopMetricsCollection(String trackingId) async {
    final metrics = await _metricsTracker.stopTracking(trackingId);
    _metricsHistory.add(metrics);
    return metrics;
  }

  /// Get performance metrics for completed backup operations
  Future<BackupMetrics> getPerformanceMetrics(String operationId) async {
    // Find metrics in history
    final metrics = _metricsHistory
        .where((m) => m.operationId == operationId)
        .lastOrNull;
    if (metrics != null) {
      return metrics;
    }

    // If not found, return empty metrics
    return BackupMetrics.empty(operationId);
  }

  /// Analyze performance trends from historical data
  Future<PerformanceTrendAnalysis> analyzePerformanceTrends() async {
    return await _reportAnalyzer.analyzeTrends(_metricsHistory);
  }

  /// Generate optimization recommendations based on performance data
  Future<List<OptimizationRecommendation>>
  generateOptimizationRecommendations() async {
    final trends = await analyzePerformanceTrends();
    return await _reportAnalyzer.generateRecommendations(
      trends,
      _metricsHistory,
    );
  }

  /// Check if backup duration is longer than normal
  Future<bool> isBackupDurationAbnormal(Duration duration) async {
    if (_metricsHistory.isEmpty) return false;

    final averageDuration = _calculateAverageDuration();
    final threshold = averageDuration * 1.5; // 50% longer than average

    return duration > threshold;
  }

  /// Check if system resources are being overused
  Future<bool> isResourceUsageExcessive(BackupMetrics metrics) async {
    // Check memory usage (if available)
    if (metrics.memoryUsage > 500 * 1024 * 1024) {
      // 500MB threshold
      return true;
    }

    // Check CPU usage duration
    if (metrics.cpuIntensiveDuration > const Duration(minutes: 10)) {
      return true;
    }

    // Check network usage
    if (metrics.networkBytesTransferred > 1024 * 1024 * 1024) {
      // 1GB threshold
      return true;
    }

    return false;
  }

  /// Get all historical metrics
  List<BackupMetrics> get metricsHistory => _metricsHistory;

  /// Clear old metrics (keep only last 100 entries)
  void cleanupOldMetrics() {
    if (_metricsHistory.length > 100) {
      _metricsHistory.removeRange(0, _metricsHistory.length - 100);
    }
  }

  Duration _calculateAverageDuration() {
    if (_metricsHistory.isEmpty) return Duration.zero;

    final totalMilliseconds = _metricsHistory
        .map((m) => m.totalDuration.inMilliseconds)
        .reduce((a, b) => a + b);

    return Duration(milliseconds: totalMilliseconds ~/ _metricsHistory.length);
  }
}

/// Tracks real-time performance metrics during backup operations
class MetricsTracker {
  final Map<String, _TrackingSession> _activeSessions = {};

  /// Start tracking metrics for an operation
  Future<String> startTracking(String operationId) async {
    final trackingId =
        '${operationId}_${DateTime.now().millisecondsSinceEpoch}';
    _activeSessions[trackingId] = _TrackingSession(
      operationId: operationId,
      startTime: DateTime.now(),
    );
    return trackingId;
  }

  /// Stop tracking and return collected metrics
  Future<BackupMetrics> stopTracking(String trackingId) async {
    final session = _activeSessions.remove(trackingId);
    if (session == null) {
      throw ArgumentError(
        'No active tracking session found for ID: $trackingId',
      );
    }

    final endTime = DateTime.now();
    final totalDuration = endTime.difference(session.startTime);

    return BackupMetrics(
      operationId: session.operationId,
      startTime: session.startTime,
      endTime: endTime,
      totalDuration: totalDuration,
      compressionTime: session.compressionTime,
      uploadTime: session.uploadTime,
      validationTime: session.validationTime,
      networkRetries: session.networkRetries,
      averageUploadSpeed: session.averageUploadSpeed,
      memoryUsage: session.peakMemoryUsage,
      cpuIntensiveDuration: session.cpuIntensiveDuration,
      networkBytesTransferred: session.networkBytesTransferred,
      successRate: session.successRate,
    );
  }

  /// Record compression time for active session
  void recordCompressionTime(String trackingId, Duration duration) {
    final session = _activeSessions[trackingId];
    if (session != null) {
      session.compressionTime = duration;
    }
  }

  /// Record upload time for active session
  void recordUploadTime(String trackingId, Duration duration) {
    final session = _activeSessions[trackingId];
    if (session != null) {
      session.uploadTime = duration;
    }
  }

  /// Record validation time for active session
  void recordValidationTime(String trackingId, Duration duration) {
    final session = _activeSessions[trackingId];
    if (session != null) {
      session.validationTime = duration;
    }
  }

  /// Record network retry
  void recordNetworkRetry(String trackingId) {
    final session = _activeSessions[trackingId];
    if (session != null) {
      session.networkRetries++;
    }
  }

  /// Record upload speed
  void recordUploadSpeed(String trackingId, double speedMBps) {
    final session = _activeSessions[trackingId];
    if (session != null) {
      session.averageUploadSpeed = speedMBps;
    }
  }

  /// Record memory usage
  void recordMemoryUsage(String trackingId, int bytes) {
    final session = _activeSessions[trackingId];
    if (session != null) {
      session.peakMemoryUsage = max(session.peakMemoryUsage, bytes);
    }
  }

  /// Record network bytes transferred
  void recordNetworkTransfer(String trackingId, int bytes) {
    final session = _activeSessions[trackingId];
    if (session != null) {
      session.networkBytesTransferred += bytes;
    }
  }
}

/// Analyzes performance reports and generates insights
class ReportAnalyzer {
  /// Analyze performance trends from historical metrics
  Future<PerformanceTrendAnalysis> analyzeTrends(
    List<BackupMetrics> metrics,
  ) async {
    if (metrics.isEmpty) {
      return PerformanceTrendAnalysis.empty();
    }

    final recentMetrics = metrics.length > 10
        ? metrics.sublist(metrics.length - 10)
        : metrics;

    final averageDuration = _calculateAverageDuration(recentMetrics);
    final averageSize = _calculateAverageSize(recentMetrics);
    final successRate = _calculateSuccessRate(recentMetrics);
    final trend = _calculateTrend(recentMetrics);

    return PerformanceTrendAnalysis(
      averageDuration: averageDuration,
      averageSize: averageSize,
      successRate: successRate,
      trend: trend,
      sampleSize: recentMetrics.length,
      analysisDate: DateTime.now(),
    );
  }

  /// Generate optimization recommendations based on analysis
  Future<List<OptimizationRecommendation>> generateRecommendations(
    PerformanceTrendAnalysis trends,
    List<BackupMetrics> metrics,
  ) async {
    final recommendations = <OptimizationRecommendation>[];

    // Check for slow backup duration
    if (trends.averageDuration > const Duration(minutes: 5)) {
      recommendations.add(
        OptimizationRecommendation(
          type: RecommendationType.performance,
          title: 'Slow Backup Performance',
          description: 'Backup operations are taking longer than expected',
          suggestion:
              'Consider enabling incremental backups or reducing backup frequency',
          priority: RecommendationPriority.medium,
        ),
      );
    }

    // Check for low success rate
    if (trends.successRate < 0.9) {
      recommendations.add(
        OptimizationRecommendation(
          type: RecommendationType.reliability,
          title: 'Low Backup Success Rate',
          description: 'Some backup operations are failing',
          suggestion: 'Check network connectivity and storage availability',
          priority: RecommendationPriority.high,
        ),
      );
    }

    // Check for degrading performance trend
    if (trends.trend == PerformanceTrend.degrading) {
      recommendations.add(
        OptimizationRecommendation(
          type: RecommendationType.maintenance,
          title: 'Performance Degradation Detected',
          description: 'Backup performance is getting worse over time',
          suggestion: 'Clean up old backups and optimize storage',
          priority: RecommendationPriority.medium,
        ),
      );
    }

    return recommendations;
  }

  Duration _calculateAverageDuration(List<BackupMetrics> metrics) {
    if (metrics.isEmpty) return Duration.zero;

    final totalMs = metrics
        .map((m) => m.totalDuration.inMilliseconds)
        .reduce((a, b) => a + b);

    return Duration(milliseconds: totalMs ~/ metrics.length);
  }

  double _calculateAverageSize(List<BackupMetrics> metrics) {
    if (metrics.isEmpty) return 0.0;

    final totalBytes = metrics
        .map((m) => m.networkBytesTransferred)
        .reduce((a, b) => a + b);

    return totalBytes / metrics.length;
  }

  double _calculateSuccessRate(List<BackupMetrics> metrics) {
    if (metrics.isEmpty) return 1.0;

    final successCount = metrics.where((m) => m.successRate > 0.9).length;
    return successCount / metrics.length;
  }

  PerformanceTrend _calculateTrend(List<BackupMetrics> metrics) {
    if (metrics.length < 3) return PerformanceTrend.stable;

    final recent = metrics.sublist(metrics.length - 3);
    final durations = recent
        .map((m) => m.totalDuration.inMilliseconds)
        .toList();

    // Simple trend analysis: compare first and last
    final firstDuration = durations.first;
    final lastDuration = durations.last;

    if (lastDuration > firstDuration * 1.2) {
      return PerformanceTrend.degrading;
    } else if (lastDuration < firstDuration * 0.8) {
      return PerformanceTrend.improving;
    } else {
      return PerformanceTrend.stable;
    }
  }
}

/// Internal tracking session for active operations
class _TrackingSession {
  final String operationId;
  final DateTime startTime;
  Duration compressionTime = Duration.zero;
  Duration uploadTime = Duration.zero;
  Duration validationTime = Duration.zero;
  int networkRetries = 0;
  double averageUploadSpeed = 0.0;
  int peakMemoryUsage = 0;
  Duration cpuIntensiveDuration = Duration.zero;
  int networkBytesTransferred = 0;
  double successRate = 1.0;

  _TrackingSession({required this.operationId, required this.startTime});
}

/// Comprehensive backup metrics
class BackupMetrics {
  final String operationId;
  final DateTime startTime;
  final DateTime endTime;
  final Duration totalDuration;
  final Duration compressionTime;
  final Duration uploadTime;
  final Duration validationTime;
  final int networkRetries;
  final double averageUploadSpeed;
  final int memoryUsage;
  final Duration cpuIntensiveDuration;
  final int networkBytesTransferred;
  final double successRate;

  const BackupMetrics({
    required this.operationId,
    required this.startTime,
    required this.endTime,
    required this.totalDuration,
    required this.compressionTime,
    required this.uploadTime,
    required this.validationTime,
    required this.networkRetries,
    required this.averageUploadSpeed,
    required this.memoryUsage,
    required this.cpuIntensiveDuration,
    required this.networkBytesTransferred,
    required this.successRate,
  });

  factory BackupMetrics.empty(String operationId) {
    final now = DateTime.now();
    return BackupMetrics(
      operationId: operationId,
      startTime: now,
      endTime: now,
      totalDuration: Duration.zero,
      compressionTime: Duration.zero,
      uploadTime: Duration.zero,
      validationTime: Duration.zero,
      networkRetries: 0,
      averageUploadSpeed: 0.0,
      memoryUsage: 0,
      cpuIntensiveDuration: Duration.zero,
      networkBytesTransferred: 0,
      successRate: 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'operationId': operationId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'totalDuration': totalDuration.inMilliseconds,
    'compressionTime': compressionTime.inMilliseconds,
    'uploadTime': uploadTime.inMilliseconds,
    'validationTime': validationTime.inMilliseconds,
    'networkRetries': networkRetries,
    'averageUploadSpeed': averageUploadSpeed,
    'memoryUsage': memoryUsage,
    'cpuIntensiveDuration': cpuIntensiveDuration.inMilliseconds,
    'networkBytesTransferred': networkBytesTransferred,
    'successRate': successRate,
  };
}

/// Performance trend analysis results
class PerformanceTrendAnalysis {
  final Duration averageDuration;
  final double averageSize;
  final double successRate;
  final PerformanceTrend trend;
  final int sampleSize;
  final DateTime analysisDate;

  const PerformanceTrendAnalysis({
    required this.averageDuration,
    required this.averageSize,
    required this.successRate,
    required this.trend,
    required this.sampleSize,
    required this.analysisDate,
  });

  factory PerformanceTrendAnalysis.empty() {
    return PerformanceTrendAnalysis(
      averageDuration: Duration.zero,
      averageSize: 0.0,
      successRate: 1.0,
      trend: PerformanceTrend.stable,
      sampleSize: 0,
      analysisDate: DateTime.now(),
    );
  }
}

/// Optimization recommendation
class OptimizationRecommendation {
  final RecommendationType type;
  final String title;
  final String description;
  final String suggestion;
  final RecommendationPriority priority;

  const OptimizationRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.suggestion,
    required this.priority,
  });
}

/// Performance trend direction
enum PerformanceTrend { improving, stable, degrading }

/// Type of optimization recommendation
enum RecommendationType { performance, reliability, maintenance, storage }

/// Priority level for recommendations
enum RecommendationPriority { low, medium, high, critical }
