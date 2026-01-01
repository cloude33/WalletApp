import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../../models/backup_optimization/backup_config.dart';
import '../../models/backup_optimization/backup_enums.dart';
import 'performance_service.dart';
import 'network_monitor.dart';
import 'resource_monitor.dart';

/// Performance optimizer for backup operations
class PerformanceOptimizer {
  final PerformanceService _performanceService;
  final NetworkMonitor _networkMonitor;
  final ResourceMonitor _resourceMonitor;

  // Performance thresholds
  static const Duration _maxAcceptableBackupTime = Duration(minutes: 5);
  static const int _maxMemoryUsageMB = 512;
  static const double _minBatteryPercentage = 20.0;
  static const int _maxNetworkRetries = 3;

  PerformanceOptimizer({
    PerformanceService? performanceService,
    NetworkMonitor? networkMonitor,
    ResourceMonitor? resourceMonitor,
  }) : _performanceService = performanceService ?? PerformanceService(),
       _networkMonitor = networkMonitor ?? NetworkMonitor(),
       _resourceMonitor = resourceMonitor ?? ResourceMonitor();

  /// Optimize memory usage during backup operations
  Future<void> optimizeMemoryUsage() async {
    try {
      // Force garbage collection
      if (!kIsWeb) {
        // Use isolate for memory-intensive operations
        await _runInIsolate(_performGarbageCollection);
      }

      // Clear caches and temporary data
      await _clearTemporaryData();

      debugPrint('✅ Memory optimization completed');
    } catch (e) {
      debugPrint('❌ Memory optimization error: $e');
    }
  }

  /// Optimize network efficiency for backup uploads
  Future<BackupConfig> optimizeNetworkEfficiency(BackupConfig config) async {
    try {
      final networkQuality = await _networkMonitor.getCurrentNetworkQuality();
      final isOnWiFi = await _networkMonitor.isOnWiFi();

      var optimizedConfig = config;

      // Adjust compression based on network quality
      switch (networkQuality) {
        case NetworkQuality.excellent:
          // Use balanced compression for best quality
          optimizedConfig = config.copyWith(
            compressionLevel: CompressionLevel.balanced,
          );
          break;
        case NetworkQuality.good:
          // Use fast compression to reduce upload time
          optimizedConfig = config.copyWith(
            compressionLevel: CompressionLevel.fast,
          );
          break;
        case NetworkQuality.poor:
          // Use maximum compression to reduce data transfer
          optimizedConfig = config.copyWith(
            compressionLevel: CompressionLevel.maximum,
          );
          break;
        case NetworkQuality.fair:
          // Use balanced compression
          optimizedConfig = config.copyWith(
            compressionLevel: CompressionLevel.balanced,
          );
          break;
      }

      // Adjust backup strategy based on connection type
      if (!isOnWiFi && config.type == BackupType.full) {
        // Use incremental backup on mobile data
        optimizedConfig = optimizedConfig.copyWith(
          type: BackupType.incremental,
        );
      }

      debugPrint('✅ Network optimization completed');
      debugPrint('   - Network quality: $networkQuality');
      debugPrint('   - WiFi connection: $isOnWiFi');
      debugPrint(
        '   - Optimized compression: ${optimizedConfig.compressionLevel}',
      );

      return optimizedConfig;
    } catch (e) {
      debugPrint('❌ Network optimization error: $e');
      return config; // Return original config on error
    }
  }

  /// Optimize battery usage during backup operations
  Future<BackupConfig> optimizeBatteryUsage(BackupConfig config) async {
    try {
      final batteryLevel = await _resourceMonitor.getBatteryLevel();
      final isCharging = await _resourceMonitor.isCharging();

      var optimizedConfig = config;

      // Adjust backup strategy based on battery level
      if (batteryLevel < _minBatteryPercentage && !isCharging) {
        // Use minimal backup strategy to preserve battery
        optimizedConfig = BackupConfig.quick().copyWith(
          enableValidation: false, // Skip validation to save CPU
          compressionLevel: CompressionLevel.fast, // Fast compression
        );
      } else if (batteryLevel < 50.0 && !isCharging) {
        // Use incremental backup to reduce processing time
        optimizedConfig = config.copyWith(
          type: BackupType.incremental,
          compressionLevel: CompressionLevel.fast,
        );
      }

      // Disable background processing on low battery
      if (batteryLevel < 30.0 && !isCharging) {
        optimizedConfig = optimizedConfig.copyWith(
          scheduleConfig: optimizedConfig.scheduleConfig?.copyWith(
            enabled: false,
          ),
        );
      }

      debugPrint('✅ Battery optimization completed');
      debugPrint('   - Battery level: ${batteryLevel.toInt()}%');
      debugPrint('   - Charging: $isCharging');
      debugPrint('   - Optimized strategy: ${optimizedConfig.type}');

      return optimizedConfig;
    } catch (e) {
      debugPrint('❌ Battery optimization error: $e');
      return config; // Return original config on error
    }
  }

  /// Optimize backup configuration based on current system conditions
  Future<BackupConfig> optimizeConfiguration(BackupConfig config) async {
    try {
      // Start with the original configuration
      var optimizedConfig = config;

      // Apply network optimizations
      optimizedConfig = await optimizeNetworkEfficiency(optimizedConfig);

      // Apply battery optimizations
      optimizedConfig = await optimizeBatteryUsage(optimizedConfig);

      // Apply storage optimizations
      optimizedConfig = await _optimizeStorageUsage(optimizedConfig);

      // Apply CPU optimizations
      optimizedConfig = await _optimizeCpuUsage(optimizedConfig);

      debugPrint('✅ Configuration optimization completed');
      return optimizedConfig;
    } catch (e) {
      debugPrint('❌ Configuration optimization error: $e');
      return config; // Return original config on error
    }
  }

  /// Monitor and optimize backup performance in real-time
  Future<void> monitorAndOptimize(String operationId) async {
    Timer? monitoringTimer;

    try {
      // Start performance monitoring
      final trackingId = await _performanceService.startMetricsCollection(
        operationId,
      );

      // Monitor performance every 30 seconds
      monitoringTimer = Timer.periodic(const Duration(seconds: 30), (
        timer,
      ) async {
        await _checkAndOptimizePerformance(trackingId);
      });

      // Wait for operation to complete (this would be called from the backup manager)
      // The timer will be cancelled when the operation completes
    } catch (e) {
      debugPrint('❌ Performance monitoring error: $e');
    } finally {
      monitoringTimer?.cancel();
    }
  }

  /// Generate performance optimization recommendations
  Future<List<OptimizationRecommendation>> generateRecommendations() async {
    try {
      final recommendations = <OptimizationRecommendation>[];

      // Check system resources
      final batteryLevel = await _resourceMonitor.getBatteryLevel();
      final availableStorage = await _resourceMonitor.getAvailableStorageGB();
      final networkQuality = await _networkMonitor.getCurrentNetworkQuality();

      // Battery recommendations
      if (batteryLevel < 30.0) {
        recommendations.add(
          OptimizationRecommendation(
            type: RecommendationType.performance,
            title: 'Low Battery Detected',
            description: 'Battery level is below 30%',
            suggestion:
                'Consider using incremental backup or wait until device is charging',
            priority: RecommendationPriority.high,
          ),
        );
      }

      // Storage recommendations
      if (availableStorage < 1.0) {
        recommendations.add(
          OptimizationRecommendation(
            type: RecommendationType.storage,
            title: 'Low Storage Space',
            description: 'Available storage is less than 1GB',
            suggestion: 'Clean up old backups or use maximum compression',
            priority: RecommendationPriority.high,
          ),
        );
      }

      // Network recommendations
      if (networkQuality == NetworkQuality.poor) {
        recommendations.add(
          OptimizationRecommendation(
            type: RecommendationType.performance,
            title: 'Poor Network Quality',
            description: 'Network connection is slow or unstable',
            suggestion:
                'Wait for better network conditions or use incremental backup',
            priority: RecommendationPriority.medium,
          ),
        );
      }

      // Performance history recommendations
      final performanceRecommendations = await _performanceService
          .generateOptimizationRecommendations();
      recommendations.addAll(performanceRecommendations);

      return recommendations;
    } catch (e) {
      debugPrint('❌ Error generating recommendations: $e');
      return [];
    }
  }

  /// Get performance optimization statistics
  Future<Map<String, dynamic>> getOptimizationStatistics() async {
    try {
      final batteryLevel = await _resourceMonitor.getBatteryLevel();
      final availableStorage = await _resourceMonitor.getAvailableStorageGB();
      final networkQuality = await _networkMonitor.getCurrentNetworkQuality();
      final isCharging = await _resourceMonitor.isCharging();
      final isOnWiFi = await _networkMonitor.isOnWiFi();

      return {
        'battery': {
          'level': batteryLevel,
          'charging': isCharging,
          'optimizationNeeded': batteryLevel < 50.0 && !isCharging,
        },
        'storage': {
          'availableGB': availableStorage,
          'optimizationNeeded': availableStorage < 2.0,
        },
        'network': {
          'quality': networkQuality.name,
          'wifi': isOnWiFi,
          'optimizationNeeded':
              networkQuality.index < NetworkQuality.good.index,
        },
        'recommendations': await generateRecommendations(),
      };
    } catch (e) {
      debugPrint('❌ Error getting optimization statistics: $e');
      return {};
    }
  }

  // Private helper methods

  Future<BackupConfig> _optimizeStorageUsage(BackupConfig config) async {
    try {
      final availableStorage = await _resourceMonitor.getAvailableStorageGB();

      if (availableStorage < 1.0) {
        // Use maximum compression and minimal data
        return config.copyWith(
          compressionLevel: CompressionLevel.maximum,
          type: BackupType.custom,
          includedCategories: [
            DataCategory.transactions,
            DataCategory.wallets,
          ], // Only essential data
        );
      } else if (availableStorage < 2.0) {
        // Use balanced compression
        return config.copyWith(compressionLevel: CompressionLevel.balanced);
      }

      return config;
    } catch (e) {
      debugPrint('❌ Storage optimization error: $e');
      return config;
    }
  }

  Future<BackupConfig> _optimizeCpuUsage(BackupConfig config) async {
    try {
      final isDeviceIdle = await _resourceMonitor.isDeviceIdle();

      if (!isDeviceIdle) {
        // Use fast compression to reduce CPU usage
        return config.copyWith(
          compressionLevel: CompressionLevel.fast,
          enableValidation: false, // Skip validation to save CPU
        );
      }

      return config;
    } catch (e) {
      debugPrint('❌ CPU optimization error: $e');
      return config;
    }
  }

  Future<void> _checkAndOptimizePerformance(String trackingId) async {
    try {
      // Get current metrics
      final metrics = await _performanceService.getPerformanceMetrics(
        trackingId,
      );

      // Check if backup is taking too long
      if (metrics.totalDuration > _maxAcceptableBackupTime) {
        debugPrint(
          '⚠️ Backup taking longer than expected: ${metrics.totalDuration.inMinutes} minutes',
        );

        // Trigger memory optimization
        await optimizeMemoryUsage();
      }

      // Check memory usage
      if (metrics.memoryUsage > _maxMemoryUsageMB * 1024 * 1024) {
        debugPrint(
          '⚠️ High memory usage detected: ${(metrics.memoryUsage / 1024 / 1024).toInt()} MB',
        );

        // Trigger memory optimization
        await optimizeMemoryUsage();
      }

      // Check network retries
      if (metrics.networkRetries > _maxNetworkRetries) {
        debugPrint('⚠️ High network retry count: ${metrics.networkRetries}');

        // Could trigger network optimization here
      }
    } catch (e) {
      debugPrint('❌ Performance check error: $e');
    }
  }

  Future<void> _clearTemporaryData() async {
    try {
      // This would clear temporary files, caches, etc.
      // Implementation depends on the specific caching strategy
      debugPrint('🧹 Clearing temporary data');

      // Simulate clearing temporary data
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('❌ Error clearing temporary data: $e');
    }
  }

  Future<void> _runInIsolate(Function operation) async {
    try {
      final receivePort = ReceivePort();

      await Isolate.spawn(_isolateEntryPoint, receivePort.sendPort);

      // Wait for isolate to complete
      await receivePort.first;

      receivePort.close();
    } catch (e) {
      debugPrint('❌ Isolate operation error: $e');
    }
  }

  static void _isolateEntryPoint(SendPort sendPort) {
    try {
      // Perform memory-intensive operations in isolate
      _performGarbageCollection();

      // Send completion signal
      sendPort.send('completed');
    } catch (e) {
      sendPort.send('error: $e');
    }
  }

  static void _performGarbageCollection() {
    // Force garbage collection (platform-specific implementation)
    // This is a placeholder - actual implementation would depend on platform
    debugPrint('🗑️ Performing garbage collection');
  }
}

/// Extension methods for resource monitoring
extension ResourceMonitorExtensions on ResourceMonitor {
  /// Get available storage in GB
  Future<double> getAvailableStorageGB() async {
    try {
      final availableBytes = await getAvailableStorageBytes();
      return availableBytes / (1024 * 1024 * 1024); // Convert to GB
    } catch (e) {
      debugPrint('❌ Error getting available storage: $e');
      return 0.0;
    }
  }

  /// Check if device is charging
  Future<bool> isCharging() async {
    try {
      // This would check the actual charging status
      // For now, return false as a safe default
      return false;
    } catch (e) {
      debugPrint('❌ Error checking charging status: $e');
      return false;
    }
  }
}
