import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../../models/backup_optimization/backup_enums.dart';
import 'network_monitor.dart';

/// Network optimization utilities for backup operations
class NetworkOptimizer {
  final NetworkMonitor _networkMonitor;

  // Network optimization parameters
  static const int _maxRetryAttempts = 5;
  static const Duration _baseRetryDelay = Duration(seconds: 2);
  static const int _maxConcurrentUploads = 3;
  static const int _optimalChunkSize = 1024 * 1024; // 1MB
  static const Duration _connectionTimeout = Duration(seconds: 30);

  NetworkOptimizer({NetworkMonitor? networkMonitor})
    : _networkMonitor = networkMonitor ?? NetworkMonitor();

  /// Optimize upload strategy based on network conditions
  Future<UploadStrategy> optimizeUploadStrategy() async {
    try {
      final networkQuality = await _networkMonitor.getCurrentNetworkQuality();
      final isOnWiFi = await _networkMonitor.isOnWiFi();
      final hasStableConnection = await _networkMonitor.hasStableConnection();

      return UploadStrategy(
        chunkSize: _calculateOptimalChunkSize(networkQuality),
        maxConcurrentUploads: _calculateMaxConcurrentUploads(
          networkQuality,
          isOnWiFi,
        ),
        retryStrategy: _createRetryStrategy(
          networkQuality,
          hasStableConnection,
        ),
        compressionLevel: _recommendCompressionLevel(networkQuality, isOnWiFi),
        useProgressiveUpload: !hasStableConnection,
        timeout: _calculateTimeout(networkQuality),
      );
    } catch (e) {
      debugPrint('❌ Upload strategy optimization error: $e');
      return UploadStrategy.defaultStrategy();
    }
  }

  /// Upload data with optimized strategy and retry logic
  Future<UploadResult> uploadWithOptimization(
    List<int> data,
    String destination, {
    UploadProgressCallback? onProgress,
  }) async {
    final strategy = await optimizeUploadStrategy();

    try {
      return await _uploadWithStrategy(data, destination, strategy, onProgress);
    } catch (e) {
      debugPrint('❌ Optimized upload error: $e');
      return UploadResult(
        success: false,
        error: e.toString(),
        bytesTransferred: 0,
        duration: Duration.zero,
      );
    }
  }

  /// Monitor network performance during upload
  Future<NetworkPerformanceMetrics> monitorUploadPerformance(
    Future<UploadResult> uploadFuture,
  ) async {
    final stopwatch = Stopwatch()..start();

    // Monitor network quality changes during upload
    final qualityChanges = <NetworkQualityChange>[];
    Timer? monitoringTimer;

    NetworkQuality? lastQuality;

    try {
      // Start monitoring network quality
      monitoringTimer = Timer.periodic(const Duration(seconds: 5), (
        timer,
      ) async {
        final currentQuality = await _networkMonitor.getCurrentNetworkQuality();

        if (lastQuality != null && currentQuality != lastQuality) {
          qualityChanges.add(
            NetworkQualityChange(
              timestamp: DateTime.now(),
              fromQuality: lastQuality!,
              toQuality: currentQuality,
            ),
          );
        }

        lastQuality = currentQuality;
      });

      // Wait for upload to complete
      final result = await uploadFuture;

      stopwatch.stop();

      return NetworkPerformanceMetrics(
        duration: stopwatch.elapsed,
        bytesTransferred: result.bytesTransferred,
        averageSpeed: _calculateAverageSpeed(
          result.bytesTransferred,
          stopwatch.elapsed,
        ),
        qualityChanges: qualityChanges,
        success: result.success,
        retryCount: result.retryCount ?? 0,
      );
    } finally {
      monitoringTimer?.cancel();
    }
  }

  /// Optimize retry strategy with exponential backoff
  Future<T> retryWithOptimization<T>(
    Future<T> Function() operation, {
    int? maxAttempts,
  }) async {
    final attempts = maxAttempts ?? _maxRetryAttempts;

    for (int attempt = 1; attempt <= attempts; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == attempts) {
          rethrow; // Last attempt, propagate error
        }

        // Calculate exponential backoff delay
        final delay = Duration(
          milliseconds:
              _baseRetryDelay.inMilliseconds * pow(2, attempt - 1).toInt(),
        );

        debugPrint(
          '🔄 Retry attempt $attempt/$attempts after ${delay.inSeconds}s delay',
        );

        // Get current network quality for delay adjustment
        try {
          final currentNetworkQuality = await _networkMonitor
              .getCurrentNetworkQuality();
          if (currentNetworkQuality == NetworkQuality.poor) {
            // Wait longer if poor network
            await Future.delayed(delay * 2);
          } else {
            await Future.delayed(delay);
          }
        } catch (_) {
          // Fallback to normal delay if network quality check fails
          await Future.delayed(delay);
        }
      }
    }

    throw Exception('Operation failed after $attempts attempts');
  }

  /// Optimize data transfer based on connection type
  Future<List<int>> optimizeDataForTransfer(
    List<int> data,
    NetworkQuality networkQuality,
  ) async {
    try {
      switch (networkQuality) {
        case NetworkQuality.excellent:
          // No optimization needed for excellent connection
          return data;

        case NetworkQuality.good:
          // Light compression for good connection
          return await _compressData(data, CompressionLevel.fast);

        case NetworkQuality.poor:
          // Maximum compression for poor connection
          return await _compressData(data, CompressionLevel.maximum);

        case NetworkQuality.fair:
          // Balanced compression for fair connection
          return await _compressData(data, CompressionLevel.balanced);
      }
    } catch (e) {
      debugPrint('❌ Data optimization error: $e');
      return data; // Return original data on error
    }
  }

  /// Calculate optimal batch size for multiple uploads
  int calculateOptimalBatchSize(NetworkQuality networkQuality, int totalItems) {
    switch (networkQuality) {
      case NetworkQuality.excellent:
        return min(totalItems, 50); // Large batches for excellent connection
      case NetworkQuality.good:
        return min(totalItems, 20); // Medium batches for good connection
      case NetworkQuality.poor:
        return min(totalItems, 5); // Small batches for poor connection
      case NetworkQuality.fair:
        return min(totalItems, 10); // Small-medium batches for fair connection
    }
  }

  /// Get network optimization recommendations
  Future<List<NetworkOptimizationRecommendation>>
  getOptimizationRecommendations() async {
    final recommendations = <NetworkOptimizationRecommendation>[];

    try {
      final networkQuality = await _networkMonitor.getCurrentNetworkQuality();
      final isOnWiFi = await _networkMonitor.isOnWiFi();
      final hasStableConnection = await _networkMonitor.hasStableConnection();

      // Connection type recommendations
      if (!isOnWiFi) {
        recommendations.add(
          NetworkOptimizationRecommendation(
            type: NetworkOptimizationType.connectionType,
            title: 'Mobile Data Connection',
            description: 'Using mobile data for backup',
            suggestion:
                'Consider waiting for WiFi connection to reduce data usage',
            priority: NetworkOptimizationPriority.medium,
          ),
        );
      }

      // Network quality recommendations
      if (networkQuality == NetworkQuality.poor) {
        recommendations.add(
          NetworkOptimizationRecommendation(
            type: NetworkOptimizationType.quality,
            title: 'Poor Network Quality',
            description: 'Network connection is slow or unstable',
            suggestion: 'Use maximum compression and smaller chunk sizes',
            priority: NetworkOptimizationPriority.high,
          ),
        );
      }

      // Stability recommendations
      if (!hasStableConnection) {
        recommendations.add(
          NetworkOptimizationRecommendation(
            type: NetworkOptimizationType.stability,
            title: 'Unstable Connection',
            description: 'Network connection is intermittent',
            suggestion: 'Enable progressive upload and increase retry attempts',
            priority: NetworkOptimizationPriority.high,
          ),
        );
      }

      return recommendations;
    } catch (e) {
      debugPrint('❌ Error getting network recommendations: $e');
      return [];
    }
  }

  // Private helper methods

  int _calculateOptimalChunkSize(NetworkQuality networkQuality) {
    switch (networkQuality) {
      case NetworkQuality.excellent:
        return _optimalChunkSize * 4; // 4MB for excellent connection
      case NetworkQuality.good:
        return _optimalChunkSize * 2; // 2MB for good connection
      case NetworkQuality.fair:
        return _optimalChunkSize; // 1MB for fair connection
      case NetworkQuality.poor:
        return _optimalChunkSize ~/ 2; // 512KB for poor connection
    }
  }

  int _calculateMaxConcurrentUploads(
    NetworkQuality networkQuality,
    bool isOnWiFi,
  ) {
    if (!isOnWiFi) {
      return 1; // Single upload on mobile data
    }

    switch (networkQuality) {
      case NetworkQuality.excellent:
        return _maxConcurrentUploads;
      case NetworkQuality.good:
        return 2;
      case NetworkQuality.fair:
        return 1;
      case NetworkQuality.poor:
        return 1;
    }
  }

  RetryStrategy _createRetryStrategy(
    NetworkQuality networkQuality,
    bool hasStableConnection,
  ) {
    int maxAttempts;
    Duration baseDelay;

    if (!hasStableConnection) {
      maxAttempts =
          _maxRetryAttempts * 2; // More retries for unstable connection
      baseDelay = _baseRetryDelay * 2; // Longer delays
    } else {
      maxAttempts = _maxRetryAttempts;
      baseDelay = _baseRetryDelay;
    }

    // Adjust based on network quality
    switch (networkQuality) {
      case NetworkQuality.poor:
        maxAttempts += 2; // Extra retries for poor connection
        baseDelay = baseDelay * 1.5; // Longer delays
        break;
      default:
        break;
    }

    return RetryStrategy(
      maxAttempts: maxAttempts,
      baseDelay: baseDelay,
      useExponentialBackoff: true,
    );
  }

  CompressionLevel _recommendCompressionLevel(
    NetworkQuality networkQuality,
    bool isOnWiFi,
  ) {
    if (!isOnWiFi) {
      return CompressionLevel
          .maximum; // Always use max compression on mobile data
    }

    switch (networkQuality) {
      case NetworkQuality.excellent:
        return CompressionLevel
            .fast; // Fast compression for excellent connection
      case NetworkQuality.good:
        return CompressionLevel
            .balanced; // Balanced compression for good connection
      case NetworkQuality.fair:
        return CompressionLevel
            .balanced; // Balanced compression for fair connection
      case NetworkQuality.poor:
        return CompressionLevel.maximum; // Max compression for poor connection
    }
  }

  Duration _calculateTimeout(NetworkQuality networkQuality) {
    switch (networkQuality) {
      case NetworkQuality.excellent:
        return _connectionTimeout;
      case NetworkQuality.good:
        return _connectionTimeout * 1.5;
      case NetworkQuality.fair:
        return _connectionTimeout * 2;
      case NetworkQuality.poor:
        return _connectionTimeout * 3;
    }
  }

  Future<UploadResult> _uploadWithStrategy(
    List<int> data,
    String destination,
    UploadStrategy strategy,
    UploadProgressCallback? onProgress,
  ) async {
    final stopwatch = Stopwatch()..start();
    int totalBytesTransferred = 0;
    int retryCount = 0;

    try {
      // Split data into chunks
      final chunks = _splitIntoChunks(data, strategy.chunkSize);

      // Upload chunks with concurrency control
      for (int i = 0; i < chunks.length; i += strategy.maxConcurrentUploads) {
        final batchEnd = min(i + strategy.maxConcurrentUploads, chunks.length);
        final batch = chunks.sublist(i, batchEnd);

        // Upload batch concurrently
        final futures = batch.map(
          (chunk) => _uploadChunk(chunk, destination, strategy),
        );
        final results = await Future.wait(futures);

        // Update progress
        for (final result in results) {
          totalBytesTransferred += result.bytesTransferred;
          retryCount += result.retryCount ?? 0;
        }

        onProgress?.call(totalBytesTransferred, data.length);
      }

      stopwatch.stop();

      return UploadResult(
        success: true,
        bytesTransferred: totalBytesTransferred,
        duration: stopwatch.elapsed,
        retryCount: retryCount,
      );
    } catch (e) {
      stopwatch.stop();

      return UploadResult(
        success: false,
        error: e.toString(),
        bytesTransferred: totalBytesTransferred,
        duration: stopwatch.elapsed,
        retryCount: retryCount,
      );
    }
  }

  Future<UploadResult> _uploadChunk(
    List<int> chunk,
    String destination,
    UploadStrategy strategy,
  ) async {
    return await retryWithOptimization(() async {
      // Simulate chunk upload
      await Future.delayed(Duration(milliseconds: 100 + chunk.length ~/ 1000));

      return UploadResult(
        success: true,
        bytesTransferred: chunk.length,
        duration: Duration(milliseconds: 100),
      );
    }, maxAttempts: strategy.retryStrategy.maxAttempts);
  }

  List<List<int>> _splitIntoChunks(List<int> data, int chunkSize) {
    final chunks = <List<int>>[];

    for (int i = 0; i < data.length; i += chunkSize) {
      final end = min(i + chunkSize, data.length);
      chunks.add(data.sublist(i, end));
    }

    return chunks;
  }

  Future<List<int>> _compressData(
    List<int> data,
    CompressionLevel level,
  ) async {
    // Simulate compression based on level
    final compressionRatio = switch (level) {
      CompressionLevel.fast => 0.8,
      CompressionLevel.balanced => 0.6,
      CompressionLevel.maximum => 0.4,
    };

    final compressedSize = (data.length * compressionRatio).toInt();
    return data.take(compressedSize).toList();
  }

  double _calculateAverageSpeed(int bytesTransferred, Duration duration) {
    if (duration.inMilliseconds == 0) return 0.0;
    return (bytesTransferred / 1024 / 1024) /
        (duration.inMilliseconds / 1000); // MB/s
  }
}

/// Upload strategy configuration
class UploadStrategy {
  final int chunkSize;
  final int maxConcurrentUploads;
  final RetryStrategy retryStrategy;
  final CompressionLevel compressionLevel;
  final bool useProgressiveUpload;
  final Duration timeout;

  const UploadStrategy({
    required this.chunkSize,
    required this.maxConcurrentUploads,
    required this.retryStrategy,
    required this.compressionLevel,
    required this.useProgressiveUpload,
    required this.timeout,
  });

  factory UploadStrategy.defaultStrategy() {
    return UploadStrategy(
      chunkSize: 1024 * 1024, // 1MB
      maxConcurrentUploads: 2,
      retryStrategy: RetryStrategy.defaultStrategy(),
      compressionLevel: CompressionLevel.balanced,
      useProgressiveUpload: false,
      timeout: const Duration(seconds: 30),
    );
  }
}

/// Retry strategy configuration
class RetryStrategy {
  final int maxAttempts;
  final Duration baseDelay;
  final bool useExponentialBackoff;

  const RetryStrategy({
    required this.maxAttempts,
    required this.baseDelay,
    required this.useExponentialBackoff,
  });

  factory RetryStrategy.defaultStrategy() {
    return const RetryStrategy(
      maxAttempts: 3,
      baseDelay: Duration(seconds: 2),
      useExponentialBackoff: true,
    );
  }
}

/// Upload result
class UploadResult {
  final bool success;
  final String? error;
  final int bytesTransferred;
  final Duration duration;
  final int? retryCount;

  const UploadResult({
    required this.success,
    this.error,
    required this.bytesTransferred,
    required this.duration,
    this.retryCount,
  });
}

/// Network performance metrics
class NetworkPerformanceMetrics {
  final Duration duration;
  final int bytesTransferred;
  final double averageSpeed; // MB/s
  final List<NetworkQualityChange> qualityChanges;
  final bool success;
  final int retryCount;

  const NetworkPerformanceMetrics({
    required this.duration,
    required this.bytesTransferred,
    required this.averageSpeed,
    required this.qualityChanges,
    required this.success,
    required this.retryCount,
  });

  Map<String, dynamic> toJson() => {
    'durationSeconds': duration.inSeconds,
    'bytesTransferred': bytesTransferred,
    'averageSpeedMBps': averageSpeed,
    'qualityChanges': qualityChanges.length,
    'success': success,
    'retryCount': retryCount,
  };
}

/// Network quality change event
class NetworkQualityChange {
  final DateTime timestamp;
  final NetworkQuality fromQuality;
  final NetworkQuality toQuality;

  const NetworkQualityChange({
    required this.timestamp,
    required this.fromQuality,
    required this.toQuality,
  });
}

/// Network optimization recommendation
class NetworkOptimizationRecommendation {
  final NetworkOptimizationType type;
  final String title;
  final String description;
  final String suggestion;
  final NetworkOptimizationPriority priority;

  const NetworkOptimizationRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.suggestion,
    required this.priority,
  });
}

/// Types of network optimization
enum NetworkOptimizationType {
  connectionType,
  quality,
  stability,
  bandwidth,
  latency,
}

/// Priority levels for network optimization
enum NetworkOptimizationPriority { low, medium, high, critical }

/// Upload progress callback
typedef UploadProgressCallback =
    void Function(int bytesTransferred, int totalBytes);
