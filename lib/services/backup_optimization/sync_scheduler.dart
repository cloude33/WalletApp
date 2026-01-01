import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/backup_optimization/backup_config.dart';
import 'network_monitor.dart';
import 'resource_monitor.dart';

/// Smart scheduling system for backup operations
class SyncScheduler {
  final NetworkMonitor _networkMonitor;
  final ResourceMonitor _resourceMonitor;
  Timer? _scheduledTimer;
  Timer? _smartCheckTimer;

  SyncScheduler({
    NetworkMonitor? networkMonitor,
    ResourceMonitor? resourceMonitor,
  }) : _networkMonitor = networkMonitor ?? NetworkMonitor(),
        _resourceMonitor = resourceMonitor ?? ResourceMonitor();

  /// Schedule smart backup with intelligent timing
  Future<void> scheduleSmartBackup(SmartScheduleConfig config) async {
    try {
      // Cancel any existing timers
      _cancelTimers();

      // Store configuration
      await _storeScheduleConfig(config);

      // Start smart monitoring timer (checks every 5 minutes)
      _smartCheckTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => _performSmartCheck(config),
      );

      debugPrint('Smart backup scheduling enabled');
    } catch (e) {
      debugPrint('Error scheduling smart backup: $e');
      rethrow;
    }
  }

  /// Check if backup should run now based on smart conditions
  Future<bool> shouldRunBackupNow() async {
    try {
      final config = await _getStoredScheduleConfig();
      if (config == null) return false;

      // Check device idle state
      if (config.enableDeviceIdleDetection) {
        final isIdle = await _resourceMonitor.isDeviceIdle();
        if (!isIdle) {
          debugPrint('Device not idle, skipping backup');
          return false;
        }
      }

      // Check network quality
      if (config.enableNetworkQualityCheck) {
        final networkQuality = await _networkMonitor.getCurrentNetworkQuality();
        if (networkQuality.index < config.minimumNetworkQuality.index) {
          debugPrint('Network quality insufficient: $networkQuality');
          return false;
        }
      }

      // Check battery level
      if (config.enableBatteryLevelCheck) {
        final batteryLevel = await _resourceMonitor.getBatteryLevel();
        if (batteryLevel < config.minimumBatteryPercentage) {
          debugPrint('Battery level too low: ${batteryLevel.toInt()}%');
          return false;
        }
      }

      // Check storage space
      if (config.enableStorageSpaceCheck) {
        final hasSpace = await _resourceMonitor.hasAvailableStorage(
          config.minimumStorageSpaceMB * 1024 * 1024, // Convert MB to bytes
        );
        if (!hasSpace) {
          debugPrint('Insufficient storage space');
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error checking backup conditions: $e');
      return false;
    }
  }

  /// Handle failed backup with exponential backoff retry
  Future<void> handleFailedBackup(BackupFailure failure) async {
    try {
      final retryCount = await _getRetryCount(failure.backupId);
      final maxRetries = 5;

      if (retryCount >= maxRetries) {
        debugPrint('Max retries reached for backup ${failure.backupId}');
        await _clearRetryCount(failure.backupId);
        return;
      }

      // Calculate exponential backoff delay
      final baseDelay = const Duration(minutes: 5);
      final backoffMultiplier = pow(2, retryCount).toInt();
      final delay = Duration(
        milliseconds: baseDelay.inMilliseconds * backoffMultiplier,
      );

      debugPrint(
        'Scheduling retry ${retryCount + 1}/$maxRetries for backup ${failure.backupId} in ${delay.inMinutes} minutes',
      );

      // Schedule retry
      Timer(delay, () async {
        await _incrementRetryCount(failure.backupId);
        // Trigger backup retry callback if provided
        failure.onRetry?.call();
      });
    } catch (e) {
      debugPrint('Error handling failed backup: $e');
    }
  }

  /// Calculate optimal backup time based on usage patterns
  Future<DateTime> calculateOptimalBackupTime() async {
    try {
      final now = DateTime.now();
      
      // Get historical usage patterns (simplified implementation)
      final prefs = await SharedPreferences.getInstance();
      final lastBackupHour = prefs.getInt('last_optimal_backup_hour') ?? 2;
      
      // Default to early morning (2 AM) when device is likely idle
      var optimalHour = lastBackupHour;
      
      // Adjust based on current time to avoid immediate execution
      if (now.hour >= optimalHour) {
        optimalHour = (optimalHour + 24) % 24;
      }
      
      final optimalTime = DateTime(
        now.year,
        now.month,
        now.day + (now.hour >= optimalHour ? 1 : 0),
        optimalHour,
        0,
        0,
      );

      debugPrint('Calculated optimal backup time: $optimalTime');
      return optimalTime;
    } catch (e) {
      debugPrint('Error calculating optimal backup time: $e');
      // Fallback to next day at 2 AM
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day + 1, 2, 0, 0);
    }
  }

  /// Adjust schedule based on device usage patterns
  Future<void> adjustScheduleBasedOnUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Simple usage pattern analysis
      final currentHour = DateTime.now().hour;
      final usageHours = prefs.getStringList('usage_hours') ?? [];
      
      // Track current hour as active
      if (!usageHours.contains(currentHour.toString())) {
        usageHours.add(currentHour.toString());
        
        // Keep only last 7 days of data (168 hours)
        if (usageHours.length > 168) {
          usageHours.removeRange(0, usageHours.length - 168);
        }
        
        await prefs.setStringList('usage_hours', usageHours);
      }
      
      // Find least active hour for optimal backup scheduling
      final hourCounts = <int, int>{};
      for (final hourStr in usageHours) {
        final hour = int.tryParse(hourStr) ?? 0;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }
      
      // Find hour with minimum usage (prefer early morning hours)
      var optimalHour = 2; // Default to 2 AM
      var minUsage = hourCounts[2] ?? 0;
      
      for (int hour = 0; hour < 6; hour++) { // Check early morning hours
        final usage = hourCounts[hour] ?? 0;
        if (usage < minUsage) {
          minUsage = usage;
          optimalHour = hour;
        }
      }
      
      await prefs.setInt('last_optimal_backup_hour', optimalHour);
      debugPrint('Adjusted optimal backup hour to: $optimalHour');
    } catch (e) {
      debugPrint('Error adjusting schedule based on usage: $e');
    }
  }

  /// Stop all scheduled operations
  Future<void> stopScheduling() async {
    _cancelTimers();
    debugPrint('Backup scheduling stopped');
  }

  /// Check if scheduling is currently active
  bool get isSchedulingActive => _smartCheckTimer?.isActive ?? false;

  // Private helper methods

  void _cancelTimers() {
    _scheduledTimer?.cancel();
    _smartCheckTimer?.cancel();
  }

  Future<void> _performSmartCheck(SmartScheduleConfig config) async {
    try {
      final shouldRun = await shouldRunBackupNow();
      if (shouldRun) {
        debugPrint('Smart conditions met, triggering backup');
        // This would trigger the actual backup process
        // Implementation depends on integration with BackupService
      }
    } catch (e) {
      debugPrint('Error in smart check: $e');
    }
  }

  Future<void> _storeScheduleConfig(SmartScheduleConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = config.toJson();
    await prefs.setString('smart_schedule_config', configJson.toString());
  }

  Future<SmartScheduleConfig?> _getStoredScheduleConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configStr = prefs.getString('smart_schedule_config');
      if (configStr != null) {
        // Note: This is a simplified implementation
        // In a real app, you'd properly parse the JSON
        return const SmartScheduleConfig();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting stored schedule config: $e');
      return null;
    }
  }

  Future<int> _getRetryCount(String backupId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('retry_count_$backupId') ?? 0;
  }

  Future<void> _incrementRetryCount(String backupId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = await _getRetryCount(backupId);
    await prefs.setInt('retry_count_$backupId', currentCount + 1);
  }

  Future<void> _clearRetryCount(String backupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('retry_count_$backupId');
  }
}

/// Represents a backup failure for retry handling
class BackupFailure {
  final String backupId;
  final String error;
  final DateTime timestamp;
  final VoidCallback? onRetry;

  const BackupFailure({
    required this.backupId,
    required this.error,
    required this.timestamp,
    this.onRetry,
  });

  @override
  String toString() => 'BackupFailure(id: $backupId, error: $error, time: $timestamp)';
}