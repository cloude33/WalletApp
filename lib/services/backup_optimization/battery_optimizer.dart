import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../models/backup_optimization/backup_config.dart';
import '../../models/backup_optimization/backup_enums.dart';
import 'resource_monitor.dart';

/// Battery usage optimization for backup operations
class BatteryOptimizer {
  final ResourceMonitor _resourceMonitor;
  
  // Battery optimization thresholds
  static const double _criticalBatteryLevel = 15.0;
  static const double _lowBatteryLevel = 30.0;
  static const double _moderateBatteryLevel = 50.0;
  static const Duration _batteryCheckInterval = Duration(minutes: 1);
  
  Timer? _batteryMonitoringTimer;
  final List<BatterySnapshot> _batteryHistory = [];
  
  BatteryOptimizer({ResourceMonitor? resourceMonitor})
      : _resourceMonitor = resourceMonitor ?? ResourceMonitor();

  /// Optimize backup configuration based on battery level
  Future<BackupConfig> optimizeForBattery(BackupConfig config) async {
    try {
      final batteryLevel = await _resourceMonitor.getBatteryLevel();
      final isCharging = await _isCharging();
      
      // If charging, use original configuration
      if (isCharging) {
        debugPrint('🔋 Device is charging - using full configuration');
        return config;
      }
      
      // Optimize based on battery level
      if (batteryLevel <= _criticalBatteryLevel) {
        return _createCriticalBatteryConfig(config);
      } else if (batteryLevel <= _lowBatteryLevel) {
        return _createLowBatteryConfig(config);
      } else if (batteryLevel <= _moderateBatteryLevel) {
        return _createModerateBatteryConfig(config);
      } else {
        return config; // Use original configuration for good battery level
      }
    } catch (e) {
      debugPrint('❌ Battery optimization error: $e');
      return config; // Return original config on error
    }
  }

  /// Check if backup should be delayed due to low battery
  Future<bool> shouldDelayBackup() async {
    try {
      final batteryLevel = await _resourceMonitor.getBatteryLevel();
      final isCharging = await _isCharging();
      
      // Don't delay if charging
      if (isCharging) {
        return false;
      }
      
      // Delay backup if battery is critically low
      if (batteryLevel <= _criticalBatteryLevel) {
        debugPrint('🔋 Delaying backup due to critical battery level: ${batteryLevel.toInt()}%');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Battery check error: $e');
      return false; // Don't delay on error
    }
  }

  /// Start monitoring battery usage during backup
  void startBatteryMonitoring() {
    _batteryMonitoringTimer?.cancel();
    
    _batteryMonitoringTimer = Timer.periodic(_batteryCheckInterval, (timer) async {
      await _takeBatterySnapshot();
    });
    
    debugPrint('🔋 Started battery monitoring');
  }

  /// Stop monitoring battery usage
  void stopBatteryMonitoring() {
    _batteryMonitoringTimer?.cancel();
    _batteryMonitoringTimer = null;
    debugPrint('🔋 Stopped battery monitoring');
  }

  /// Get battery usage statistics
  BatteryUsageStatistics getBatteryStatistics() {
    if (_batteryHistory.isEmpty) {
      return BatteryUsageStatistics.empty();
    }
    
    final first = _batteryHistory.first;
    final last = _batteryHistory.last;
    final batteryDrain = first.batteryLevel - last.batteryLevel;
    final duration = last.timestamp.difference(first.timestamp);
    
    return BatteryUsageStatistics(
      initialBatteryLevel: first.batteryLevel,
      finalBatteryLevel: last.batteryLevel,
      batteryDrain: batteryDrain,
      monitoringDuration: duration,
      drainRate: duration.inMinutes > 0 ? batteryDrain / duration.inMinutes : 0.0,
      snapshotCount: _batteryHistory.length,
    );
  }

  /// Get battery optimization recommendations
  Future<List<BatteryOptimizationRecommendation>> getOptimizationRecommendations() async {
    final recommendations = <BatteryOptimizationRecommendation>[];
    
    try {
      final batteryLevel = await _resourceMonitor.getBatteryLevel();
      final isCharging = await _isCharging();
      
      // Critical battery recommendations
      if (batteryLevel <= _criticalBatteryLevel && !isCharging) {
        recommendations.add(BatteryOptimizationRecommendation(
          type: BatteryOptimizationType.critical,
          title: 'Critical Battery Level',
          description: 'Battery level is critically low (${batteryLevel.toInt()}%)',
          suggestion: 'Charge device before performing backup operations',
          priority: BatteryOptimizationPriority.critical,
        ));
      }
      
      // Low battery recommendations
      else if (batteryLevel <= _lowBatteryLevel && !isCharging) {
        recommendations.add(BatteryOptimizationRecommendation(
          type: BatteryOptimizationType.lowBattery,
          title: 'Low Battery Level',
          description: 'Battery level is low (${batteryLevel.toInt()}%)',
          suggestion: 'Use quick backup mode or wait until charging',
          priority: BatteryOptimizationPriority.high,
        ));
      }
      
      // Charging recommendations
      if (!isCharging && batteryLevel < _moderateBatteryLevel) {
        recommendations.add(BatteryOptimizationRecommendation(
          type: BatteryOptimizationType.charging,
          title: 'Device Not Charging',
          description: 'Device is running on battery power',
          suggestion: 'Connect charger for optimal backup performance',
          priority: BatteryOptimizationPriority.medium,
        ));
      }
      
      // Battery drain recommendations
      final statistics = getBatteryStatistics();
      if (statistics.drainRate > 5.0) { // More than 5% per minute
        recommendations.add(BatteryOptimizationRecommendation(
          type: BatteryOptimizationType.highDrain,
          title: 'High Battery Drain',
          description: 'Battery is draining faster than normal',
          suggestion: 'Reduce backup frequency or use power-saving mode',
          priority: BatteryOptimizationPriority.medium,
        ));
      }
      
      return recommendations;
    } catch (e) {
      debugPrint('❌ Error getting battery recommendations: $e');
      return [];
    }
  }

  /// Estimate backup time impact on battery
  Future<BatteryImpactEstimate> estimateBatteryImpact(
    BackupConfig config,
    int estimatedDataSizeMB,
  ) async {
    try {
      final batteryLevel = await _resourceMonitor.getBatteryLevel();
      final isCharging = await _isCharging();
      
      // Base battery consumption estimates (percentage per MB)
      double batteryConsumptionRate;
      
      switch (config.type) {
        case BackupType.full:
          batteryConsumptionRate = 0.1; // 0.1% per MB for full backup
          break;
        case BackupType.incremental:
          batteryConsumptionRate = 0.05; // 0.05% per MB for incremental
          break;
        case BackupType.custom:
          batteryConsumptionRate = 0.07; // 0.07% per MB for custom
          break;
      }
      
      // Adjust for compression level (more compression = more CPU = more battery)
      switch (config.compressionLevel) {
        case CompressionLevel.fast:
          batteryConsumptionRate *= 0.8;
          break;
        case CompressionLevel.balanced:
          batteryConsumptionRate *= 1.0;
          break;
        case CompressionLevel.maximum:
          batteryConsumptionRate *= 1.5;
          break;
      }
      
      // Adjust for validation (validation uses extra CPU)
      if (config.enableValidation) {
        batteryConsumptionRate *= 1.2;
      }
      
      final estimatedBatteryUsage = estimatedDataSizeMB * batteryConsumptionRate;
      final remainingBatteryAfter = batteryLevel - estimatedBatteryUsage;
      
      return BatteryImpactEstimate(
        currentBatteryLevel: batteryLevel,
        estimatedUsage: estimatedBatteryUsage,
        remainingBatteryAfter: remainingBatteryAfter,
        isCharging: isCharging,
        isSafe: remainingBatteryAfter > _criticalBatteryLevel || isCharging,
        recommendation: _getBatteryRecommendation(remainingBatteryAfter, isCharging),
      );
    } catch (e) {
      debugPrint('❌ Battery impact estimation error: $e');
      return BatteryImpactEstimate.unknown();
    }
  }

  /// Clear battery monitoring history
  void clearBatteryHistory() {
    _batteryHistory.clear();
    debugPrint('🧹 Cleared battery monitoring history');
  }

  // Private helper methods

  Future<bool> _isCharging() async {
    try {
      // This would check actual charging status
      // For now, return false as a safe default
      return false;
    } catch (e) {
      debugPrint('❌ Error checking charging status: $e');
      return false;
    }
  }

  BackupConfig _createCriticalBatteryConfig(BackupConfig config) {
    debugPrint('🔋 Creating critical battery configuration');
    
    return BackupConfig(
      type: BackupType.custom,
      includedCategories: [
        DataCategory.transactions, // Only most essential data
      ],
      compressionLevel: CompressionLevel.fast, // Fastest compression to save CPU
      enableValidation: false, // Skip validation to save CPU
      retentionPolicy: config.retentionPolicy,
      scheduleConfig: null, // Disable scheduling
    );
  }

  BackupConfig _createLowBatteryConfig(BackupConfig config) {
    debugPrint('🔋 Creating low battery configuration');
    
    return config.copyWith(
      type: BackupType.incremental, // Use incremental to reduce processing
      compressionLevel: CompressionLevel.fast, // Fast compression
      enableValidation: false, // Skip validation
      scheduleConfig: config.scheduleConfig?.copyWith(
        enabled: false, // Disable scheduling
      ),
    );
  }

  BackupConfig _createModerateBatteryConfig(BackupConfig config) {
    debugPrint('🔋 Creating moderate battery configuration');
    
    return config.copyWith(
      compressionLevel: CompressionLevel.fast, // Use fast compression
      scheduleConfig: config.scheduleConfig?.copyWith(
        minimumBatteryLevel: _moderateBatteryLevel.toInt(), // Increase battery threshold
      ),
    );
  }

  Future<void> _takeBatterySnapshot() async {
    try {
      final batteryLevel = await _resourceMonitor.getBatteryLevel();
      final isCharging = await _isCharging();
      
      final snapshot = BatterySnapshot(
        timestamp: DateTime.now(),
        batteryLevel: batteryLevel,
        isCharging: isCharging,
      );
      
      _batteryHistory.add(snapshot);
      
      // Keep only last 100 snapshots
      if (_batteryHistory.length > 100) {
        _batteryHistory.removeAt(0);
      }
      
      // Log warnings for critical battery levels
      if (batteryLevel <= _criticalBatteryLevel && !isCharging) {
        debugPrint('⚠️ Critical battery level: ${batteryLevel.toInt()}%');
      }
    } catch (e) {
      debugPrint('❌ Battery snapshot error: $e');
    }
  }

  String _getBatteryRecommendation(double remainingBattery, bool isCharging) {
    if (isCharging) {
      return 'Device is charging - backup can proceed safely';
    }
    
    if (remainingBattery <= _criticalBatteryLevel) {
      return 'Charge device before backup to avoid shutdown';
    } else if (remainingBattery <= _lowBatteryLevel) {
      return 'Consider charging device or using quick backup mode';
    } else if (remainingBattery <= _moderateBatteryLevel) {
      return 'Monitor battery level during backup';
    } else {
      return 'Battery level is sufficient for backup';
    }
  }
}

/// Battery usage snapshot
class BatterySnapshot {
  final DateTime timestamp;
  final double batteryLevel;
  final bool isCharging;
  
  const BatterySnapshot({
    required this.timestamp,
    required this.batteryLevel,
    required this.isCharging,
  });
}

/// Battery usage statistics
class BatteryUsageStatistics {
  final double initialBatteryLevel;
  final double finalBatteryLevel;
  final double batteryDrain;
  final Duration monitoringDuration;
  final double drainRate; // Percentage per minute
  final int snapshotCount;
  
  const BatteryUsageStatistics({
    required this.initialBatteryLevel,
    required this.finalBatteryLevel,
    required this.batteryDrain,
    required this.monitoringDuration,
    required this.drainRate,
    required this.snapshotCount,
  });
  
  factory BatteryUsageStatistics.empty() {
    return const BatteryUsageStatistics(
      initialBatteryLevel: 0.0,
      finalBatteryLevel: 0.0,
      batteryDrain: 0.0,
      monitoringDuration: Duration.zero,
      drainRate: 0.0,
      snapshotCount: 0,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'initialBatteryLevel': initialBatteryLevel,
    'finalBatteryLevel': finalBatteryLevel,
    'batteryDrain': batteryDrain,
    'monitoringDurationMinutes': monitoringDuration.inMinutes,
    'drainRatePerMinute': drainRate,
    'snapshotCount': snapshotCount,
  };
}

/// Battery impact estimate
class BatteryImpactEstimate {
  final double currentBatteryLevel;
  final double estimatedUsage;
  final double remainingBatteryAfter;
  final bool isCharging;
  final bool isSafe;
  final String recommendation;
  
  const BatteryImpactEstimate({
    required this.currentBatteryLevel,
    required this.estimatedUsage,
    required this.remainingBatteryAfter,
    required this.isCharging,
    required this.isSafe,
    required this.recommendation,
  });
  
  factory BatteryImpactEstimate.unknown() {
    return const BatteryImpactEstimate(
      currentBatteryLevel: 0.0,
      estimatedUsage: 0.0,
      remainingBatteryAfter: 0.0,
      isCharging: false,
      isSafe: false,
      recommendation: 'Unable to estimate battery impact',
    );
  }
  
  Map<String, dynamic> toJson() => {
    'currentBatteryLevel': currentBatteryLevel,
    'estimatedUsage': estimatedUsage,
    'remainingBatteryAfter': remainingBatteryAfter,
    'isCharging': isCharging,
    'isSafe': isSafe,
    'recommendation': recommendation,
  };
}

/// Battery optimization recommendation
class BatteryOptimizationRecommendation {
  final BatteryOptimizationType type;
  final String title;
  final String description;
  final String suggestion;
  final BatteryOptimizationPriority priority;
  
  const BatteryOptimizationRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.suggestion,
    required this.priority,
  });
}

/// Types of battery optimization
enum BatteryOptimizationType {
  critical,
  lowBattery,
  charging,
  highDrain,
  powerSaving,
}

/// Priority levels for battery optimization
enum BatteryOptimizationPriority {
  low,
  medium,
  high,
  critical,
}