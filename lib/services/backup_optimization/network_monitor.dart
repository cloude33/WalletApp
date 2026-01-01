import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../models/backup_optimization/backup_enums.dart';

/// Monitors network conditions for smart backup scheduling
class NetworkMonitor {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  /// Get current network quality assessment
  Future<NetworkQuality> getCurrentNetworkQuality() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      
      // Check basic connectivity
      if (connectivityResults.contains(ConnectivityResult.none) || connectivityResults.isEmpty) {
        return NetworkQuality.poor;
      }
      
      // For web platform, assume good quality if connected
      if (kIsWeb) {
        return connectivityResults.contains(ConnectivityResult.wifi) 
            ? NetworkQuality.excellent 
            : NetworkQuality.good;
      }
      
      // Perform network speed test for mobile platforms
      final speedTestResult = await _performSpeedTest();
      
      // Classify based on connection type and speed (prioritize best connection)
      if (connectivityResults.contains(ConnectivityResult.ethernet)) {
        return NetworkQuality.excellent;
      } else if (connectivityResults.contains(ConnectivityResult.wifi)) {
        return _classifyWifiQuality(speedTestResult);
      } else if (connectivityResults.contains(ConnectivityResult.mobile)) {
        return _classifyMobileQuality(speedTestResult);
      } else if (connectivityResults.contains(ConnectivityResult.vpn)) {
        return _classifyVpnQuality(speedTestResult);
      } else if (connectivityResults.contains(ConnectivityResult.bluetooth)) {
        return NetworkQuality.poor;
      } else {
        return NetworkQuality.fair;
      }
    } catch (e) {
      debugPrint('Error assessing network quality: $e');
      return NetworkQuality.fair; // Default to fair on error
    }
  }
  
  /// Check if device is connected to WiFi
  Future<bool> isOnWiFi() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      return connectivityResults.contains(ConnectivityResult.wifi);
    } catch (e) {
      debugPrint('Error checking WiFi status: $e');
      return false;
    }
  }
  
  /// Check if network connection is stable
  Future<bool> hasStableConnection() async {
    try {
      // Perform multiple connectivity checks over time
      const checkCount = 3;
      const checkInterval = Duration(seconds: 2);
      
      int successfulChecks = 0;
      
      for (int i = 0; i < checkCount; i++) {
        final isConnected = await _isConnected();
        if (isConnected) {
          successfulChecks++;
        }
        
        if (i < checkCount - 1) {
          await Future.delayed(checkInterval);
        }
      }
      
      // Consider stable if at least 2 out of 3 checks succeed
      final isStable = successfulChecks >= 2;
      debugPrint('Network stability check: $successfulChecks/$checkCount successful');
      
      return isStable;
    } catch (e) {
      debugPrint('Error checking network stability: $e');
      return false;
    }
  }
  
  /// Start monitoring network changes
  void startMonitoring(Function(List<ConnectivityResult>) onConnectivityChanged) {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      onConnectivityChanged,
      onError: (error) {
        debugPrint('Network monitoring error: $error');
      },
    );
  }
  
  /// Stop monitoring network changes
  void stopMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
  
  /// Get estimated download speed in Mbps
  Future<double> getEstimatedDownloadSpeed() async {
    try {
      final speedResult = await _performSpeedTest();
      return speedResult.downloadSpeedMbps;
    } catch (e) {
      debugPrint('Error getting download speed: $e');
      return 0.0;
    }
  }
  
  /// Get estimated upload speed in Mbps
  Future<double> getEstimatedUploadSpeed() async {
    try {
      final speedResult = await _performSpeedTest();
      return speedResult.uploadSpeedMbps;
    } catch (e) {
      debugPrint('Error getting upload speed: $e');
      return 0.0;
    }
  }
  
  // Private helper methods
  
  Future<bool> _isConnected() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      return !connectivityResults.contains(ConnectivityResult.none) && connectivityResults.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  Future<_SpeedTestResult> _performSpeedTest() async {
    try {
      // Simple speed test using HTTP request timing
      final stopwatch = Stopwatch()..start();
      
      // Test download speed with a small file
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      
      // Use a reliable test endpoint (Google's generate_204 for connectivity)
      final request = await client.getUrl(Uri.parse('http://connectivitycheck.gstatic.com/generate_204'));
      await request.close();
      
      stopwatch.stop();
      client.close();
      
      // Calculate approximate speed based on response time
      final responseTimeMs = stopwatch.elapsedMilliseconds;
      
      // Estimate speeds based on response time (simplified heuristic)
      double downloadSpeed = 0.0;
      double uploadSpeed = 0.0;
      
      if (responseTimeMs < 100) {
        downloadSpeed = 50.0; // Excellent connection
        uploadSpeed = 25.0;
      } else if (responseTimeMs < 300) {
        downloadSpeed = 25.0; // Good connection
        uploadSpeed = 12.0;
      } else if (responseTimeMs < 1000) {
        downloadSpeed = 10.0; // Fair connection
        uploadSpeed = 5.0;
      } else {
        downloadSpeed = 2.0; // Poor connection
        uploadSpeed = 1.0;
      }
      
      return _SpeedTestResult(
        downloadSpeedMbps: downloadSpeed,
        uploadSpeedMbps: uploadSpeed,
        latencyMs: responseTimeMs,
      );
    } catch (e) {
      debugPrint('Speed test failed: $e');
      return const _SpeedTestResult(
        downloadSpeedMbps: 1.0,
        uploadSpeedMbps: 0.5,
        latencyMs: 2000,
      );
    }
  }
  
  NetworkQuality _classifyWifiQuality(_SpeedTestResult speedResult) {
    if (speedResult.downloadSpeedMbps >= 25 && speedResult.latencyMs < 100) {
      return NetworkQuality.excellent;
    } else if (speedResult.downloadSpeedMbps >= 10 && speedResult.latencyMs < 300) {
      return NetworkQuality.good;
    } else if (speedResult.downloadSpeedMbps >= 5 && speedResult.latencyMs < 1000) {
      return NetworkQuality.fair;
    } else {
      return NetworkQuality.poor;
    }
  }
  
  NetworkQuality _classifyMobileQuality(_SpeedTestResult speedResult) {
    // Mobile connections typically have lower expectations
    if (speedResult.downloadSpeedMbps >= 15 && speedResult.latencyMs < 200) {
      return NetworkQuality.excellent;
    } else if (speedResult.downloadSpeedMbps >= 8 && speedResult.latencyMs < 500) {
      return NetworkQuality.good;
    } else if (speedResult.downloadSpeedMbps >= 3 && speedResult.latencyMs < 1500) {
      return NetworkQuality.fair;
    } else {
      return NetworkQuality.poor;
    }
  }
  
  NetworkQuality _classifyVpnQuality(_SpeedTestResult speedResult) {
    // VPN connections have additional overhead
    if (speedResult.downloadSpeedMbps >= 20 && speedResult.latencyMs < 150) {
      return NetworkQuality.excellent;
    } else if (speedResult.downloadSpeedMbps >= 8 && speedResult.latencyMs < 400) {
      return NetworkQuality.good;
    } else if (speedResult.downloadSpeedMbps >= 3 && speedResult.latencyMs < 1200) {
      return NetworkQuality.fair;
    } else {
      return NetworkQuality.poor;
    }
  }
}

/// Internal class to hold speed test results
class _SpeedTestResult {
  final double downloadSpeedMbps;
  final double uploadSpeedMbps;
  final int latencyMs;
  
  const _SpeedTestResult({
    required this.downloadSpeedMbps,
    required this.uploadSpeedMbps,
    required this.latencyMs,
  });
  
  @override
  String toString() => 'SpeedTest(down: ${downloadSpeedMbps.toStringAsFixed(1)} Mbps, '
      'up: ${uploadSpeedMbps.toStringAsFixed(1)} Mbps, latency: ${latencyMs}ms)';
}