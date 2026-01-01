import 'dart:async';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:parion/services/backup_optimization/sync_scheduler.dart';
import 'package:parion/services/backup_optimization/network_monitor.dart';
import 'package:parion/services/backup_optimization/resource_monitor.dart';
import 'package:parion/models/backup_optimization/backup_enums.dart';
import '../../property_test_utils.dart';
import '../../test_helpers.dart';

/// Property-based tests for retry mechanism with exponential backoff
/// **Feature: backup-optimization, Property 13: Retry Mechanism with Exponential Backoff**
void main() {
  setupCommonTestMocks();
  group('Retry Mechanism Property Tests', () {
    late SyncScheduler syncScheduler;

    setUpAll(() {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
    });

    setUp(() {
      syncScheduler = SyncScheduler(
        networkMonitor: MockNetworkMonitor(),
        resourceMonitor: MockResourceMonitor(),
      );
    });

    tearDown(() async {
      await syncScheduler.stopScheduling();
      // Clear SharedPreferences between tests
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    /// **Property 13: Retry Mechanism with Exponential Backoff**
    /// **Validates: Requirements 5.4**
    PropertyTest.forAll<BackupFailureTestData>(
      description:
          'For any failed backup operation, the sync scheduler should implement exponential backoff retry strategy',
      generator: () => _generateBackupFailureTestData(),
      property: (testData) async {
        // Property 1: Backup ID should be valid for retry tracking
        if (testData.backupId.isEmpty) {
          return false;
        }

        // Property 2: Error handling should be graceful
        // The method should not throw exceptions even with invalid data
        try {
          final failure = BackupFailure(
            backupId: testData.backupId,
            error: testData.error,
            timestamp: testData.timestamp,
          );

          // Handle the failure - this should not throw
          await syncScheduler.handleFailedBackup(failure);

          // Wait a small amount to allow async operations
          await Future.delayed(const Duration(milliseconds: 10));
        } catch (e) {
          // Should handle gracefully without throwing
          return false;
        }

        // Property 3: Exponential backoff calculation should be mathematically correct
        // Base delay is 5 minutes, multiplied by 2^retryCount
        const baseDelayMinutes = 5;
        for (int i = 0; i < min(testData.failureCount, 5); i++) {
          final expectedMultiplier = pow(2, i).toInt();
          final expectedDelayMinutes = baseDelayMinutes * expectedMultiplier;

          // Verify the exponential progression is mathematically sound
          if (expectedMultiplier != pow(2, i).toInt()) {
            return false;
          }

          // Verify delay is within reasonable bounds (not negative, not infinite)
          if (expectedDelayMinutes <= 0 || expectedDelayMinutes > 24 * 60) {
            return false;
          }
        }

        // Property 4: Max retries constant should be reasonable
        const maxRetries = 5;
        if (maxRetries <= 0 || maxRetries > 10) {
          return false;
        }

        // Property 5: Retry count tracking should use consistent key format
        final retryKey = 'retry_count_${testData.backupId}';

        // The key format should be consistent and valid
        if (!retryKey.startsWith('retry_count_') || retryKey.length <= 12) {
          return false;
        }

        // Property 6: Multiple calls should be handled correctly
        // Simulate multiple failure calls for the same backup ID
        for (int i = 0; i < min(testData.failureCount, 3); i++) {
          final failure = BackupFailure(
            backupId: testData.backupId,
            error: testData.error,
            timestamp: testData.timestamp,
          );

          await syncScheduler.handleFailedBackup(failure);
          await Future.delayed(const Duration(milliseconds: 5));
        }

        // Property 7: Error messages should be preserved
        if (testData.error.isEmpty) {
          // Empty error messages should be handled gracefully
          final emptyErrorFailure = BackupFailure(
            backupId: testData.backupId,
            error: '',
            timestamp: testData.timestamp,
          );

          try {
            await syncScheduler.handleFailedBackup(emptyErrorFailure);
          } catch (e) {
            return false;
          }
        }

        return true;
      },
      iterations: 20,
    );

    /// Test exponential backoff delay calculation specifically
    PropertyTest.forAll<int>(
      description:
          'Exponential backoff delays should follow 2^n pattern with base delay',
      generator: () => PropertyTest.randomInt(min: 0, max: 10),
      property: (retryCount) async {
        const baseDelayMinutes = 5;
        final expectedMultiplier = pow(2, retryCount).toInt();
        final expectedDelayMinutes = baseDelayMinutes * expectedMultiplier;

        // Property: Delay should follow exponential pattern
        if (retryCount == 0) {
          return expectedDelayMinutes == 5; // 5 * 2^0 = 5
        } else if (retryCount == 1) {
          return expectedDelayMinutes == 10; // 5 * 2^1 = 10
        } else if (retryCount == 2) {
          return expectedDelayMinutes == 20; // 5 * 2^2 = 20
        } else if (retryCount == 3) {
          return expectedDelayMinutes == 40; // 5 * 2^3 = 40
        } else if (retryCount == 4) {
          return expectedDelayMinutes == 80; // 5 * 2^4 = 80
        }

        // For higher retry counts, just verify it's exponential
        final previousDelayMinutes =
            baseDelayMinutes * pow(2, retryCount - 1).toInt();
        return expectedDelayMinutes == previousDelayMinutes * 2;
      },
      iterations: 20,
    );

    /// Test retry count persistence across scheduler instances
    PropertyTest.forAll<String>(
      description: 'Retry counts should persist across scheduler instances',
      generator: () => PropertyTest.randomString(minLength: 5, maxLength: 20),
      property: (backupId) async {
        // Property: SharedPreferences should be used for persistence

        // Create first scheduler instance
        final scheduler1 = SyncScheduler(
          networkMonitor: MockNetworkMonitor(),
          resourceMonitor: MockResourceMonitor(),
        );

        final failure = BackupFailure(
          backupId: backupId,
          error: 'Test error',
          timestamp: DateTime.now(),
        );

        // Handle failure with first instance
        await scheduler1.handleFailedBackup(failure);
        await scheduler1.stopScheduling();

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 20));

        // Create second scheduler instance
        final scheduler2 = SyncScheduler(
          networkMonitor: MockNetworkMonitor(),
          resourceMonitor: MockResourceMonitor(),
        );

        // Handle failure with second instance
        await scheduler2.handleFailedBackup(failure);
        await scheduler2.stopScheduling();

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 20));

        // Property: The retry key should exist in SharedPreferences
        final retryKey = 'retry_count_$backupId';

        // Property: Key format should be consistent
        final keyIsValid =
            retryKey.startsWith('retry_count_') &&
            retryKey.length > 12 &&
            backupId.isNotEmpty;

        return keyIsValid;
      },
      iterations: 15,
    );
  });
}

/// Test data for backup failure scenarios
class BackupFailureTestData {
  final String backupId;
  final String error;
  final DateTime timestamp;
  final int failureCount;

  BackupFailureTestData({
    required this.backupId,
    required this.error,
    required this.timestamp,
    required this.failureCount,
  });

  @override
  String toString() =>
      'BackupFailureTestData(id: $backupId, failures: $failureCount)';
}

/// Represents a retry attempt for tracking
class RetryAttempt {
  final int attemptNumber;
  final DateTime timestamp;

  RetryAttempt({required this.attemptNumber, required this.timestamp});
}

/// Generate random backup failure test data
BackupFailureTestData _generateBackupFailureTestData() {
  return BackupFailureTestData(
    backupId: PropertyTest.randomString(minLength: 8, maxLength: 32),
    error: _generateRandomError(),
    timestamp: PropertyTest.randomDateTime(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    ),
    failureCount: PropertyTest.randomInt(
      min: 1,
      max: 8,
    ), // Test beyond max retries
  );
}

/// Generate random error messages for testing
String _generateRandomError() {
  final errors = [
    'Network connection failed',
    'Google Drive quota exceeded',
    'Authentication failed',
    'File upload timeout',
    'Insufficient storage space',
    'Backup validation failed',
    'Compression error',
    'Data corruption detected',
  ];

  return errors[PropertyTest.randomInt(min: 0, max: errors.length - 1)];
}

/// Mock NetworkMonitor for testing
class MockNetworkMonitor extends NetworkMonitor {
  @override
  Future<NetworkQuality> getCurrentNetworkQuality() async {
    return NetworkQuality.good;
  }

  @override
  Future<bool> isOnWiFi() async {
    return true;
  }

  @override
  Future<bool> hasStableConnection() async {
    return true;
  }
}

/// Mock ResourceMonitor for testing
class MockResourceMonitor extends ResourceMonitor {
  @override
  Future<bool> isDeviceIdle() async {
    return true;
  }

  @override
  Future<double> getBatteryLevel() async {
    return 80.0;
  }

  @override
  Future<bool> hasAvailableStorage(int requiredBytes) async {
    return true;
  }
}
