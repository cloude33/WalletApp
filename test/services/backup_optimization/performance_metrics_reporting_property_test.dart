import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/backup_optimization/performance_service.dart';
import '../../property_test_utils.dart';

void main() {
  group('PerformanceService - Performance Metrics Reporting Property Tests', () {
    late PerformanceService performanceService;

    setUp(() {
      performanceService = PerformanceService();
    });

    /// **Feature: backup-optimization, Property 18: Performance Metrics Reporting**
    /// **Validates: Requirements 7.1**
    PropertyTest.forAll<CompletedBackupOperation>(
      description:
          'Property 18: For any completed backup operation, system should report duration, size and success rate',
      generator: _generateRandomCompletedBackupOperation,
      property: (operation) async {
        // Arrange - Start metrics collection using the performance service
        final trackingId = await performanceService.startMetricsCollection(
          operation.operationId,
        );

        // Simulate some operation time to ensure duration > 0
        await Future.delayed(const Duration(milliseconds: 1));

        // Complete the operation and get metrics
        await performanceService.stopMetricsCollection(trackingId);

        // Act - Get performance metrics from the service
        final retrievedMetrics = await performanceService.getPerformanceMetrics(
          operation.operationId,
        );

        // Property: The system should report all three required metrics (duration, size, success rate)
        final hasDuration = retrievedMetrics.totalDuration.inMilliseconds >= 0;
        final hasSize =
            retrievedMetrics.networkBytesTransferred >=
            0; // Size can be 0 for empty backups
        final hasSuccessRate =
            retrievedMetrics.successRate >= 0.0 &&
            retrievedMetrics.successRate <= 1.0;

        // The metrics should be retrievable and have valid structure
        final metricsRetrievable =
            retrievedMetrics.operationId == operation.operationId;
        final hasValidTimestamp =
            retrievedMetrics.startTime.isBefore(retrievedMetrics.endTime) ||
            retrievedMetrics.startTime.isAtSameMomentAs(
              retrievedMetrics.endTime,
            );

        return hasDuration &&
            hasSize &&
            hasSuccessRate &&
            metricsRetrievable &&
            hasValidTimestamp;
      },
      iterations: 20,
    );

    PropertyTest.forAll<BackupOperationWithMetrics>(
      description:
          'Property 18b: For any backup operation, reported metrics should contain required fields',
      generator: _generateBackupOperationWithMetrics,
      property: (operationData) async {
        // Arrange - Start and complete metrics collection
        final trackingId = await performanceService.startMetricsCollection(
          operationData.operationId,
        );

        // Simulate some operation time
        await Future.delayed(const Duration(milliseconds: 1));

        // Act - Stop tracking and get metrics
        final metrics = await performanceService.stopMetricsCollection(
          trackingId,
        );

        // Property: Reported metrics should contain all required fields with valid values
        final hasValidOperationId =
            metrics.operationId == operationData.operationId;
        final hasValidDuration = metrics.totalDuration.inMilliseconds >= 0;
        final hasValidSize = metrics.networkBytesTransferred >= 0;
        final hasValidSuccessRate =
            metrics.successRate >= 0.0 && metrics.successRate <= 1.0;
        final hasValidTimestamps =
            metrics.startTime.isBefore(metrics.endTime) ||
            metrics.startTime.isAtSameMomentAs(metrics.endTime);

        // Component times should be non-negative
        final hasValidComponentTimes =
            metrics.compressionTime.inMilliseconds >= 0 &&
            metrics.uploadTime.inMilliseconds >= 0 &&
            metrics.validationTime.inMilliseconds >= 0;

        // Network metrics should be valid
        final hasValidNetworkMetrics =
            metrics.networkRetries >= 0 && metrics.averageUploadSpeed >= 0.0;

        return hasValidOperationId &&
            hasValidDuration &&
            hasValidSize &&
            hasValidSuccessRate &&
            hasValidTimestamps &&
            hasValidComponentTimes &&
            hasValidNetworkMetrics;
      },
      iterations: 20,
    );

    PropertyTest.forAll<MultipleBackupOperations>(
      description:
          'Property 18c: For any series of backup operations, each should have distinct metrics reporting',
      generator: _generateMultipleBackupOperations,
      property: (operations) async {
        // Arrange - Process multiple operations using the performance service
        final completedOperations = <String>[];

        for (final operation in operations.operations) {
          final trackingId = await performanceService.startMetricsCollection(
            operation.operationId,
          );

          // Simulate some operation time
          await Future.delayed(const Duration(milliseconds: 1));

          await performanceService.stopMetricsCollection(trackingId);
          completedOperations.add(operation.operationId);
        }

        // Act & Property: Each operation should have distinct metrics
        final uniqueOperations =
            completedOperations.toSet().length == operations.operations.length;

        // Each operation should be retrievable with correct metrics
        bool allOperationsRetrievable = true;
        for (final operation in operations.operations) {
          final retrievedMetrics = await performanceService
              .getPerformanceMetrics(operation.operationId);
          if (retrievedMetrics.operationId != operation.operationId) {
            allOperationsRetrievable = false;
            break;
          }

          // Each should have valid metrics structure
          final hasValidMetrics =
              retrievedMetrics.totalDuration.inMilliseconds >= 0 &&
              retrievedMetrics.successRate >= 0.0 &&
              retrievedMetrics.successRate <= 1.0;
          if (!hasValidMetrics) {
            allOperationsRetrievable = false;
            break;
          }
        }

        return uniqueOperations && allOperationsRetrievable;
      },
      iterations: 20,
    );
  });
}

/// Generates a random completed backup operation for testing
CompletedBackupOperation _generateRandomCompletedBackupOperation() {
  final random = Random();

  return CompletedBackupOperation(
    operationId:
        'backup_${PropertyTest.randomString(minLength: 5, maxLength: 15)}',
    compressionTime: Duration(
      milliseconds: PropertyTest.randomInt(min: 100, max: 5000),
    ),
    uploadTime: Duration(seconds: PropertyTest.randomInt(min: 1, max: 120)),
    validationTime: Duration(
      milliseconds: PropertyTest.randomInt(min: 50, max: 2000),
    ),
    backupSize: PropertyTest.randomInt(
      min: 1024,
      max: 1024 * 1024 * 100,
    ), // 1KB to 100MB
    networkRetries: PropertyTest.randomInt(min: 0, max: 5),
    uploadSpeed: PropertyTest.randomPositiveDouble(min: 0.1, max: 50.0), // MB/s
    expectedSuccessRate: random.nextBool()
        ? 1.0
        : PropertyTest.randomPositiveDouble(min: 0.5, max: 1.0),
  );
}

/// Generates backup operation with detailed metrics for consistency testing
BackupOperationWithMetrics _generateBackupOperationWithMetrics() {
  return BackupOperationWithMetrics(
    operationId:
        'metrics_test_${PropertyTest.randomString(minLength: 5, maxLength: 10)}',
    compressionTime: Duration(
      milliseconds: PropertyTest.randomInt(min: 100, max: 3000),
    ),
    uploadTime: Duration(seconds: PropertyTest.randomInt(min: 5, max: 60)),
    validationTime: Duration(
      milliseconds: PropertyTest.randomInt(min: 100, max: 1000),
    ),
    totalBytes: PropertyTest.randomInt(
      min: 1024,
      max: 50 * 1024 * 1024,
    ), // 1KB to 50MB
    uploadSpeed: PropertyTest.randomPositiveDouble(min: 0.5, max: 20.0),
    retryCount: PropertyTest.randomInt(min: 0, max: 3),
  );
}

/// Generates multiple backup operations for distinct metrics testing
MultipleBackupOperations _generateMultipleBackupOperations() {
  final random = Random();
  final operationCount = 2 + random.nextInt(8); // 2 to 9 operations

  final operations = <CompletedBackupOperation>[];
  final usedIds = <String>{};

  for (int i = 0; i < operationCount; i++) {
    String operationId;
    do {
      operationId =
          'multi_backup_${i}_${PropertyTest.randomString(minLength: 3, maxLength: 8)}';
    } while (usedIds.contains(operationId));

    usedIds.add(operationId);

    operations.add(
      CompletedBackupOperation(
        operationId: operationId,
        compressionTime: Duration(
          milliseconds: PropertyTest.randomInt(min: 100, max: 2000),
        ),
        uploadTime: Duration(seconds: PropertyTest.randomInt(min: 1, max: 30)),
        validationTime: Duration(
          milliseconds: PropertyTest.randomInt(min: 50, max: 500),
        ),
        backupSize: PropertyTest.randomInt(
          min: 1024,
          max: 10 * 1024 * 1024,
        ), // 1KB to 10MB
        networkRetries: PropertyTest.randomInt(min: 0, max: 2),
        uploadSpeed: PropertyTest.randomPositiveDouble(min: 1.0, max: 10.0),
        expectedSuccessRate: 1.0, // Keep simple for multiple operations test
      ),
    );
  }

  return MultipleBackupOperations(operations: operations);
}

/// Helper class representing a completed backup operation
class CompletedBackupOperation {
  final String operationId;
  final Duration compressionTime;
  final Duration uploadTime;
  final Duration validationTime;
  final int backupSize;
  final int networkRetries;
  final double uploadSpeed;
  final double expectedSuccessRate;

  CompletedBackupOperation({
    required this.operationId,
    required this.compressionTime,
    required this.uploadTime,
    required this.validationTime,
    required this.backupSize,
    required this.networkRetries,
    required this.uploadSpeed,
    required this.expectedSuccessRate,
  });
}

/// Helper class for backup operation with detailed metrics
class BackupOperationWithMetrics {
  final String operationId;
  final Duration compressionTime;
  final Duration uploadTime;
  final Duration validationTime;
  final int totalBytes;
  final double uploadSpeed;
  final int retryCount;

  BackupOperationWithMetrics({
    required this.operationId,
    required this.compressionTime,
    required this.uploadTime,
    required this.validationTime,
    required this.totalBytes,
    required this.uploadSpeed,
    required this.retryCount,
  });
}

/// Helper class for multiple backup operations testing
class MultipleBackupOperations {
  final List<CompletedBackupOperation> operations;

  MultipleBackupOperations({required this.operations});
}
