import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Monitors device resources for smart backup scheduling
class ResourceMonitor {
  Timer? _idleDetectionTimer;
  DateTime _lastActivityTime = DateTime.now();
  
  /// Check if device is currently idle (no user activity)
  Future<bool> isDeviceIdle() async {
    try {
      // For web platform, assume device is idle during off-peak hours
      if (kIsWeb) {
        return _isOffPeakHours();
      }
      
      // Simple idle detection based on time since last activity
      final now = DateTime.now();
      final timeSinceLastActivity = now.difference(_lastActivityTime);
      
      // Consider device idle if no activity for 10 minutes
      const idleThreshold = Duration(minutes: 10);
      final isIdle = timeSinceLastActivity >= idleThreshold;
      
      debugPrint('Device idle check: ${isIdle ? 'IDLE' : 'ACTIVE'} '
          '(${timeSinceLastActivity.inMinutes} min since last activity)');
      
      return isIdle;
    } catch (e) {
      debugPrint('Error checking device idle state: $e');
      return false; // Default to not idle on error
    }
  }
  
  /// Get current battery level as percentage (0.0 to 100.0)
  Future<double> getBatteryLevel() async {
    try {
      // For web platform, assume sufficient battery
      if (kIsWeb) {
        return 80.0; // Assume 80% battery for web
      }
      
      // For mobile platforms, we'll use a simplified approach
      // In a real implementation, you'd use platform channels or battery_plus
      debugPrint('Battery level: 75% (simulated)');
      return 75.0; // Simulated battery level
    } catch (e) {
      debugPrint('Error getting battery level: $e');
      return 50.0; // Default to 50% on error
    }
  }
  
  /// Check if device has sufficient available storage
  Future<bool> hasAvailableStorage(int requiredBytes) async {
    try {
      if (kIsWeb) {
        // For web, assume sufficient storage
        return true;
      }
      
      // Get available space (this is a simplified check)
      // In a real implementation, you'd use platform-specific APIs
      final availableBytes = await _getAvailableStorageBytes();
      
      final hasSpace = availableBytes >= requiredBytes;
      debugPrint('Storage check: ${hasSpace ? 'SUFFICIENT' : 'INSUFFICIENT'} '
          '(${(availableBytes / 1024 / 1024).toStringAsFixed(1)} MB available, '
          '${(requiredBytes / 1024 / 1024).toStringAsFixed(1)} MB required)');
      
      return hasSpace;
    } catch (e) {
      debugPrint('Error checking available storage: $e');
      return true; // Default to sufficient storage on error
    }
  }
  
  /// Check if device is charging
  Future<bool> isCharging() async {
    try {
      if (kIsWeb) {
        return false; // Web devices don't have charging state
      }
      
      // Simplified implementation - in reality you'd use battery_plus or platform channels
      debugPrint('Charging state: NOT CHARGING (simulated)');
      return false; // Simulated charging state
    } catch (e) {
      debugPrint('Error checking charging state: $e');
      return false;
    }
  }
  
  /// Get device memory usage information
  Future<MemoryInfo> getMemoryInfo() async {
    try {
      if (kIsWeb) {
        return const MemoryInfo(
          totalMemoryMB: 4096, // Assume 4GB for web
          availableMemoryMB: 2048, // Assume 2GB available
          usedMemoryMB: 2048,
        );
      }
      
      // Platform-specific memory information
      if (Platform.isAndroid) {
        return await _getAndroidMemoryInfo();
      } else if (Platform.isIOS) {
        return await _getIOSMemoryInfo();
      } else {
        return const MemoryInfo(
          totalMemoryMB: 8192, // Default values for other platforms
          availableMemoryMB: 4096,
          usedMemoryMB: 4096,
        );
      }
    } catch (e) {
      debugPrint('Error getting memory info: $e');
      return const MemoryInfo(
        totalMemoryMB: 4096,
        availableMemoryMB: 2048,
        usedMemoryMB: 2048,
      );
    }
  }
  
  /// Check if device has sufficient memory for backup operations
  Future<bool> hasSufficientMemory(int requiredMemoryMB) async {
    try {
      final memoryInfo = await getMemoryInfo();
      final hasMemory = memoryInfo.availableMemoryMB >= requiredMemoryMB;
      
      debugPrint('Memory check: ${hasMemory ? 'SUFFICIENT' : 'INSUFFICIENT'} '
          '(${memoryInfo.availableMemoryMB} MB available, $requiredMemoryMB MB required)');
      
      return hasMemory;
    } catch (e) {
      debugPrint('Error checking memory sufficiency: $e');
      return true; // Default to sufficient memory on error
    }
  }
  
  /// Start monitoring device activity for idle detection
  void startActivityMonitoring() {
    _lastActivityTime = DateTime.now();
    
    // Reset activity timer periodically (simplified implementation)
    _idleDetectionTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateActivityTime(),
    );
    
    debugPrint('Activity monitoring started');
  }
  
  /// Stop monitoring device activity
  void stopActivityMonitoring() {
    _idleDetectionTimer?.cancel();
    _idleDetectionTimer = null;
    debugPrint('Activity monitoring stopped');
  }
  
  /// Record user activity (call this when user interacts with the app)
  void recordActivity() {
    _lastActivityTime = DateTime.now();
  }
  
  /// Get device performance score (0.0 to 1.0, higher is better)
  Future<double> getDevicePerformanceScore() async {
    try {
      final batteryLevel = await getBatteryLevel();
      final memoryInfo = await getMemoryInfo();
      final hasStorage = await hasAvailableStorage(100 * 1024 * 1024); // 100MB
      
      // Calculate performance score based on multiple factors
      double score = 0.0;
      
      // Battery contribution (30%)
      score += (batteryLevel / 100.0) * 0.3;
      
      // Memory contribution (40%)
      final memoryRatio = memoryInfo.availableMemoryMB / memoryInfo.totalMemoryMB;
      score += memoryRatio * 0.4;
      
      // Storage contribution (30%)
      score += (hasStorage ? 1.0 : 0.0) * 0.3;
      
      debugPrint('Device performance score: ${(score * 100).toStringAsFixed(1)}%');
      return score;
    } catch (e) {
      debugPrint('Error calculating performance score: $e');
      return 0.5; // Default to medium performance
    }
  }
  
  // Private helper methods
  
  bool _isOffPeakHours() {
    final now = DateTime.now();
    final hour = now.hour;
    
    // Consider off-peak hours as 11 PM to 6 AM
    return hour >= 23 || hour <= 6;
  }
  
  void _updateActivityTime() {
    // In a real implementation, this would check for actual user activity
    // For now, we assume activity during peak hours
    if (!_isOffPeakHours()) {
      _lastActivityTime = DateTime.now();
    }
  }
  
  /// Get available storage in bytes (public method)
  Future<int> getAvailableStorageBytes() async {
    return await _getAvailableStorageBytes();
  }
  
  Future<int> _getAvailableStorageBytes() async {
    try {
      // Simplified storage check - in reality you'd use platform channels
      // to get actual available storage from the OS
      
      if (Platform.isAndroid || Platform.isIOS) {
        // Return a reasonable estimate (1GB available)
        return 1024 * 1024 * 1024;
      }
      
      return 2048 * 1024 * 1024; // 2GB for other platforms
    } catch (e) {
      debugPrint('Error getting available storage: $e');
      return 512 * 1024 * 1024; // 512MB fallback
    }
  }
  
  Future<MemoryInfo> _getAndroidMemoryInfo() async {
    try {
      // Simplified implementation without device_info_plus
      // In a real app, you'd use platform channels to get actual memory info
      final totalMemoryMB = 4096; // Default estimate
      final availableMemoryMB = totalMemoryMB ~/ 2; // Assume 50% available
      
      return MemoryInfo(
        totalMemoryMB: totalMemoryMB,
        availableMemoryMB: availableMemoryMB,
        usedMemoryMB: totalMemoryMB - availableMemoryMB,
      );
    } catch (e) {
      debugPrint('Error getting Android memory info: $e');
      return const MemoryInfo(
        totalMemoryMB: 4096,
        availableMemoryMB: 2048,
        usedMemoryMB: 2048,
      );
    }
  }
  
  Future<MemoryInfo> _getIOSMemoryInfo() async {
    try {
      // Simplified implementation without device_info_plus
      // In a real app, you'd use platform channels to get actual memory info
      final totalMemoryMB = 6144; // Default estimate for iOS devices
      final availableMemoryMB = totalMemoryMB ~/ 3; // Assume 33% available
      
      return MemoryInfo(
        totalMemoryMB: totalMemoryMB,
        availableMemoryMB: availableMemoryMB,
        usedMemoryMB: totalMemoryMB - availableMemoryMB,
      );
    } catch (e) {
      debugPrint('Error getting iOS memory info: $e');
      return const MemoryInfo(
        totalMemoryMB: 6144,
        availableMemoryMB: 2048,
        usedMemoryMB: 4096,
      );
    }
  }
}

/// Information about device memory usage
class MemoryInfo {
  final int totalMemoryMB;
  final int availableMemoryMB;
  final int usedMemoryMB;
  
  const MemoryInfo({
    required this.totalMemoryMB,
    required this.availableMemoryMB,
    required this.usedMemoryMB,
  });
  
  /// Get memory usage percentage (0.0 to 100.0)
  double get usagePercentage => (usedMemoryMB / totalMemoryMB) * 100.0;
  
  /// Get available memory percentage (0.0 to 100.0)
  double get availablePercentage => (availableMemoryMB / totalMemoryMB) * 100.0;
  
  @override
  String toString() => 'MemoryInfo(total: ${totalMemoryMB}MB, '
      'available: ${availableMemoryMB}MB, used: ${usedMemoryMB}MB, '
      'usage: ${usagePercentage.toStringAsFixed(1)}%)';
}