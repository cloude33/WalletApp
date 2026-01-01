import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/backup_optimization/performance_service.dart';

void main() {
  group('PerformanceService', () {
    late PerformanceService performanceService;
    late MetricsTracker metricsTracker;
    late ReportAnalyzer reportAnalyzer;

    setUp(() {
      metricsTracker = MetricsTracker();
      reportAnalyzer = ReportAnalyzer();
      performanceService = PerformanceService(
        metricsTracker: metricsTracker,
        reportAnalyzer: reportAnalyzer,
      );
    });

    group('Metrics Collection', () {
      test('should start and stop metrics collection successfully', () async {
        const operationId = 'test_backup_001';

        // Start metrics collection
        final trackingId = await performanceService.startMetricsCollection(
          operationId,
        );
        expect(trackingId, isNotEmpty);
        expect(trackingId, contains(operationId));

        // Simulate some operation time
        await Future.delayed(const Duration(milliseconds: 10));

        // Stop metrics collection
        final metrics = await performanceService.stopMetricsCollection(
          trackingId,
        );
        expect(metrics.operationId, equals(operationId));
        expect(metrics.totalDuration.inMilliseconds, greaterThan(0));
      });

      test('should track metrics in history after collection', () async {
        const operationId = 'test_backup_002';

        final trackingId = await performanceService.startMetricsCollection(
          operationId,
        );
        await Future.delayed(const Duration(milliseconds: 5));
        await performanceService.stopMetricsCollection(trackingId);

        final retrievedMetrics = await performanceService.getPerformanceMetrics(
          operationId,
        );
        expect(retrievedMetrics.operationId, equals(operationId));
        expect(performanceService.metricsHistory, hasLength(1));
      });

      test('should return empty metrics for unknown operation', () async {
        const unknownOperationId = 'unknown_operation';

        final metrics = await performanceService.getPerformanceMetrics(
          unknownOperationId,
        );
        expect(metrics.operationId, equals(unknownOperationId));
        expect(metrics.totalDuration, equals(Duration.zero));
        expect(metrics.successRate, equals(0.0));
      });
    });

    group('Performance Analysis', () {
      test('should detect abnormal backup duration', () async {
        // Add some normal duration metrics to history
        for (int i = 0; i < 5; i++) {
          final trackingId = await performanceService.startMetricsCollection(
            'normal_$i',
          );
          await Future.delayed(const Duration(milliseconds: 10));
          await performanceService.stopMetricsCollection(trackingId);
        }

        // Test with normal duration
        final normalDuration = const Duration(milliseconds: 15);
        final isNormalAbnormal = await performanceService
            .isBackupDurationAbnormal(normalDuration);
        expect(isNormalAbnormal, isFalse);

        // Test with abnormally long duration
        final longDuration = const Duration(seconds: 1);
        final isLongAbnormal = await performanceService
            .isBackupDurationAbnormal(longDuration);
        expect(isLongAbnormal, isTrue);
      });

      test('should detect excessive resource usage', () async {
        // Test normal resource usage
        final normalMetrics = BackupMetrics(
          operationId: 'normal_resources',
          startTime: DateTime.now().subtract(const Duration(minutes: 1)),
          endTime: DateTime.now(),
          totalDuration: const Duration(minutes: 1),
          compressionTime: const Duration(seconds: 10),
          uploadTime: const Duration(seconds: 30),
          validationTime: const Duration(seconds: 5),
          networkRetries: 1,
          averageUploadSpeed: 5.0,
          memoryUsage: 100 * 1024 * 1024, // 100MB
          cpuIntensiveDuration: const Duration(minutes: 1),
          networkBytesTransferred: 50 * 1024 * 1024, // 50MB
          successRate: 1.0,
        );

        final isNormalExcessive = await performanceService
            .isResourceUsageExcessive(normalMetrics);
        expect(isNormalExcessive, isFalse);

        // Test excessive memory usage
        final excessiveMemoryMetrics = BackupMetrics(
          operationId: 'excessive_memory',
          startTime: DateTime.now().subtract(const Duration(minutes: 1)),
          endTime: DateTime.now(),
          totalDuration: const Duration(minutes: 1),
          compressionTime: const Duration(seconds: 10),
          uploadTime: const Duration(seconds: 30),
          validationTime: const Duration(seconds: 5),
          networkRetries: 1,
          averageUploadSpeed: 5.0,
          memoryUsage: 600 * 1024 * 1024, // 600MB - exceeds 500MB threshold
          cpuIntensiveDuration: const Duration(minutes: 1),
          networkBytesTransferred: 50 * 1024 * 1024,
          successRate: 1.0,
        );

        final isMemoryExcessive = await performanceService
            .isResourceUsageExcessive(excessiveMemoryMetrics);
        expect(isMemoryExcessive, isTrue);

        // Test excessive CPU duration
        final excessiveCpuMetrics = BackupMetrics(
          operationId: 'excessive_cpu',
          startTime: DateTime.now().subtract(const Duration(minutes: 15)),
          endTime: DateTime.now(),
          totalDuration: const Duration(minutes: 15),
          compressionTime: const Duration(seconds: 10),
          uploadTime: const Duration(seconds: 30),
          validationTime: const Duration(seconds: 5),
          networkRetries: 1,
          averageUploadSpeed: 5.0,
          memoryUsage: 100 * 1024 * 1024,
          cpuIntensiveDuration: const Duration(
            minutes: 12,
          ), // Exceeds 10 minute threshold
          networkBytesTransferred: 50 * 1024 * 1024,
          successRate: 1.0,
        );

        final isCpuExcessive = await performanceService
            .isResourceUsageExcessive(excessiveCpuMetrics);
        expect(isCpuExcessive, isTrue);
      });

      test('should generate optimization recommendations', () async {
        // Add some metrics with performance issues
        final slowMetrics = BackupMetrics(
          operationId: 'slow_backup',
          startTime: DateTime.now().subtract(const Duration(minutes: 10)),
          endTime: DateTime.now(),
          totalDuration: const Duration(minutes: 10), // Very slow
          compressionTime: const Duration(minutes: 2),
          uploadTime: const Duration(minutes: 6),
          validationTime: const Duration(minutes: 1),
          networkRetries: 3,
          averageUploadSpeed: 0.5, // Very slow
          memoryUsage: 200 * 1024 * 1024,
          cpuIntensiveDuration: const Duration(minutes: 8),
          networkBytesTransferred: 100 * 1024 * 1024,
          successRate: 0.8, // Low success rate
        );

        performanceService.metricsHistory.add(slowMetrics);

        final recommendations = await performanceService
            .generateOptimizationRecommendations();
        expect(recommendations, isNotEmpty);

        // Should have recommendations for slow performance and low success rate
        final performanceRec = recommendations.where(
          (r) => r.type == RecommendationType.performance,
        );
        final reliabilityRec = recommendations.where(
          (r) => r.type == RecommendationType.reliability,
        );

        expect(performanceRec, isNotEmpty);
        expect(reliabilityRec, isNotEmpty);
      });
    });

    group('Performance Warnings', () {
      test('should warn about long backup duration', () async {
        // Clear any existing metrics first
        performanceService.metricsHistory.clear();

        // Add some normal duration metrics to establish baseline
        // Use fixed durations to avoid timing issues
        final baselineMetrics = [
          BackupMetrics(
            operationId: 'baseline_1',
            startTime: DateTime.now().subtract(const Duration(minutes: 5)),
            endTime: DateTime.now().subtract(const Duration(minutes: 4)),
            totalDuration: const Duration(minutes: 1),
            compressionTime: const Duration(seconds: 10),
            uploadTime: const Duration(seconds: 40),
            validationTime: const Duration(seconds: 10),
            networkRetries: 0,
            averageUploadSpeed: 5.0,
            memoryUsage: 100 * 1024 * 1024,
            cpuIntensiveDuration: const Duration(seconds: 50),
            networkBytesTransferred: 50 * 1024 * 1024,
            successRate: 1.0,
          ),
          BackupMetrics(
            operationId: 'baseline_2',
            startTime: DateTime.now().subtract(const Duration(minutes: 4)),
            endTime: DateTime.now().subtract(const Duration(minutes: 3)),
            totalDuration: const Duration(minutes: 1),
            compressionTime: const Duration(seconds: 10),
            uploadTime: const Duration(seconds: 40),
            validationTime: const Duration(seconds: 10),
            networkRetries: 0,
            averageUploadSpeed: 5.0,
            memoryUsage: 100 * 1024 * 1024,
            cpuIntensiveDuration: const Duration(seconds: 50),
            networkBytesTransferred: 50 * 1024 * 1024,
            successRate: 1.0,
          ),
        ];

        performanceService.metricsHistory.addAll(baselineMetrics);

        // Average duration is 1 minute, threshold is 1.5 minutes (90 seconds)

        // Test with normal duration - should not warn
        final normalDuration = const Duration(seconds: 80); // Under threshold
        final shouldWarnNormal = await performanceService
            .isBackupDurationAbnormal(normalDuration);
        expect(
          shouldWarnNormal,
          isFalse,
          reason: 'Normal duration should not trigger warning',
        );

        // Test with long duration - should warn
        final longDuration = const Duration(minutes: 2); // Over threshold
        final shouldWarnLong = await performanceService
            .isBackupDurationAbnormal(longDuration);
        expect(
          shouldWarnLong,
          isTrue,
          reason: 'Long duration should trigger warning',
        );

        // Test edge case - exactly at threshold (90 seconds)
        final thresholdDuration = const Duration(seconds: 90);
        final shouldWarnThreshold = await performanceService
            .isBackupDurationAbnormal(thresholdDuration);
        expect(
          shouldWarnThreshold,
          isFalse,
          reason: 'Duration exactly at threshold should not trigger warning',
        );

        // Test just over threshold - should warn
        final overThresholdDuration = const Duration(seconds: 91);
        final shouldWarnOverThreshold = await performanceService
            .isBackupDurationAbnormal(overThresholdDuration);
        expect(
          shouldWarnOverThreshold,
          isTrue,
          reason: 'Duration over threshold should trigger warning',
        );
      });

      test('should warn about excessive memory usage', () async {
        // Test normal memory usage - should not warn
        final normalMemoryMetrics = BackupMetrics(
          operationId: 'normal_memory_test',
          startTime: DateTime.now().subtract(const Duration(minutes: 2)),
          endTime: DateTime.now(),
          totalDuration: const Duration(minutes: 2),
          compressionTime: const Duration(seconds: 20),
          uploadTime: const Duration(minutes: 1),
          validationTime: const Duration(seconds: 10),
          networkRetries: 0,
          averageUploadSpeed: 5.0,
          memoryUsage: 300 * 1024 * 1024, // 300MB - under 500MB threshold
          cpuIntensiveDuration: const Duration(minutes: 1),
          networkBytesTransferred: 100 * 1024 * 1024,
          successRate: 1.0,
        );

        final shouldWarnNormalMemory = await performanceService
            .isResourceUsageExcessive(normalMemoryMetrics);
        expect(
          shouldWarnNormalMemory,
          isFalse,
          reason: 'Normal memory usage should not trigger warning',
        );

        // Test excessive memory usage - should warn
        final excessiveMemoryMetrics = BackupMetrics(
          operationId: 'excessive_memory_test',
          startTime: DateTime.now().subtract(const Duration(minutes: 2)),
          endTime: DateTime.now(),
          totalDuration: const Duration(minutes: 2),
          compressionTime: const Duration(seconds: 20),
          uploadTime: const Duration(minutes: 1),
          validationTime: const Duration(seconds: 10),
          networkRetries: 0,
          averageUploadSpeed: 5.0,
          memoryUsage: 600 * 1024 * 1024, // 600MB - over 500MB threshold
          cpuIntensiveDuration: const Duration(minutes: 1),
          networkBytesTransferred: 100 * 1024 * 1024,
          successRate: 1.0,
        );

        final shouldWarnExcessiveMemory = await performanceService
            .isResourceUsageExcessive(excessiveMemoryMetrics);
        expect(
          shouldWarnExcessiveMemory,
          isTrue,
          reason: 'Excessive memory usage should trigger warning',
        );

        // Test edge case - exactly at threshold
        final thresholdMemoryMetrics = BackupMetrics(
          operationId: 'threshold_memory_test',
          startTime: DateTime.now().subtract(const Duration(minutes: 2)),
          endTime: DateTime.now(),
          totalDuration: const Duration(minutes: 2),
          compressionTime: const Duration(seconds: 20),
          uploadTime: const Duration(minutes: 1),
          validationTime: const Duration(seconds: 10),
          networkRetries: 0,
          averageUploadSpeed: 5.0,
          memoryUsage: 500 * 1024 * 1024, // Exactly 500MB threshold
          cpuIntensiveDuration: const Duration(minutes: 1),
          networkBytesTransferred: 100 * 1024 * 1024,
          successRate: 1.0,
        );

        final shouldWarnThresholdMemory = await performanceService
            .isResourceUsageExcessive(thresholdMemoryMetrics);
        expect(
          shouldWarnThresholdMemory,
          isFalse,
          reason: 'Memory usage at threshold should not trigger warning',
        );
      });

      test('should warn about excessive CPU usage duration', () async {
        // Test normal CPU usage - should not warn
        final normalCpuMetrics = BackupMetrics(
          operationId: 'normal_cpu_test',
          startTime: DateTime.now().subtract(const Duration(minutes: 5)),
          endTime: DateTime.now(),
          totalDuration: const Duration(minutes: 5),
          compressionTime: const Duration(minutes: 1),
          uploadTime: const Duration(minutes: 3),
          validationTime: const Duration(seconds: 30),
          networkRetries: 0,
          averageUploadSpeed: 5.0,
          memoryUsage: 200 * 1024 * 1024,
          cpuIntensiveDuration: const Duration(
            minutes: 8,
          ), // Under 10 minute threshold
          networkBytesTransferred: 100 * 1024 * 1024,
          successRate: 1.0,
        );

        final shouldWarnNormalCpu = await performanceService
            .isResourceUsageExcessive(normalCpuMetrics);
        expect(
          shouldWarnNormalCpu,
          isFalse,
          reason: 'Normal CPU usage should not trigger warning',
        );

        // Test excessive CPU usage - should warn
        final excessiveCpuMetrics = BackupMetrics(
          operationId: 'excessive_cpu_test',
          startTime: DateTime.now().subtract(const Duration(minutes: 15)),
          endTime: DateTime.now(),
          totalDuration: const Duration(minutes: 15),
          compressionTime: const Duration(minutes: 2),
          uploadTime: const Duration(minutes: 10),
          validationTime: const Duration(minutes: 1),
          networkRetries: 0,
          averageUploadSpeed: 2.0,
          memoryUsage: 200 * 1024 * 1024,
          cpuIntensiveDuration: const Duration(
            minutes: 12,
          ), // Over 10 minute threshold
          networkBytesTransferred: 200 * 1024 * 1024,
          successRate: 1.0,
        );

        final shouldWarnExcessiveCpu = await performanceService
            .isResourceUsageExcessive(excessiveCpuMetrics);
        expect(
          shouldWarnExcessiveCpu,
          isTrue,
          reason: 'Excessive CPU usage should trigger warning',
        );
      });

      test('should warn about excessive network usage', () async {
        // Test normal network usage - should not warn
        final normalNetworkMetrics = BackupMetrics(
          operationId: 'normal_network_test',
          startTime: DateTime.now().subtract(const Duration(minutes: 3)),
          endTime: DateTime.now(),
          totalDuration: const Duration(minutes: 3),
          compressionTime: const Duration(seconds: 30),
          uploadTime: const Duration(minutes: 2),
          validationTime: const Duration(seconds: 15),
          networkRetries: 1,
          averageUploadSpeed: 5.0,
          memoryUsage: 200 * 1024 * 1024,
          cpuIntensiveDuration: const Duration(minutes: 2),
          networkBytesTransferred:
              500 * 1024 * 1024, // 500MB - under 1GB threshold
          successRate: 1.0,
        );

        final shouldWarnNormalNetwork = await performanceService
            .isResourceUsageExcessive(normalNetworkMetrics);
        expect(
          shouldWarnNormalNetwork,
          isFalse,
          reason: 'Normal network usage should not trigger warning',
        );

        // Test excessive network usage - should warn
        final excessiveNetworkMetrics = BackupMetrics(
          operationId: 'excessive_network_test',
          startTime: DateTime.now().subtract(const Duration(minutes: 10)),
          endTime: DateTime.now(),
          totalDuration: const Duration(minutes: 10),
          compressionTime: const Duration(minutes: 1),
          uploadTime: const Duration(minutes: 8),
          validationTime: const Duration(seconds: 30),
          networkRetries: 2,
          averageUploadSpeed: 2.0,
          memoryUsage: 300 * 1024 * 1024,
          cpuIntensiveDuration: const Duration(minutes: 5),
          networkBytesTransferred:
              1200 * 1024 * 1024, // 1.2GB - over 1GB threshold
          successRate: 1.0,
        );

        final shouldWarnExcessiveNetwork = await performanceService
            .isResourceUsageExcessive(excessiveNetworkMetrics);
        expect(
          shouldWarnExcessiveNetwork,
          isTrue,
          reason: 'Excessive network usage should trigger warning',
        );
      });

      test(
        'should provide optimization suggestions for resource usage',
        () async {
          // Create metrics with multiple resource issues
          final problematicMetrics = BackupMetrics(
            operationId: 'problematic_backup',
            startTime: DateTime.now().subtract(const Duration(minutes: 15)),
            endTime: DateTime.now(),
            totalDuration: const Duration(minutes: 15), // Long duration
            compressionTime: const Duration(minutes: 3),
            uploadTime: const Duration(minutes: 10),
            validationTime: const Duration(minutes: 1),
            networkRetries: 5, // Many retries
            averageUploadSpeed: 1.0, // Slow upload
            memoryUsage: 700 * 1024 * 1024, // High memory usage
            cpuIntensiveDuration: const Duration(minutes: 12), // High CPU usage
            networkBytesTransferred: 1500 * 1024 * 1024, // High network usage
            successRate: 0.7, // Low success rate
          );

          // Add to history for trend analysis
          performanceService.metricsHistory.clear();
          performanceService.metricsHistory.add(problematicMetrics);

          // Generate optimization recommendations
          final recommendations = await performanceService
              .generateOptimizationRecommendations();

          expect(
            recommendations,
            isNotEmpty,
            reason: 'Should generate recommendations for problematic metrics',
          );

          // Should have performance recommendation for slow backup
          final performanceRecs = recommendations.where(
            (r) => r.type == RecommendationType.performance,
          );
          expect(
            performanceRecs,
            isNotEmpty,
            reason: 'Should have performance recommendations',
          );

          // Should have reliability recommendation for low success rate
          final reliabilityRecs = recommendations.where(
            (r) => r.type == RecommendationType.reliability,
          );
          expect(
            reliabilityRecs,
            isNotEmpty,
            reason: 'Should have reliability recommendations',
          );

          // Check that recommendations have appropriate content
          final performanceRec = performanceRecs.first;
          expect(performanceRec.title, contains('Slow'));
          expect(performanceRec.description, isNotEmpty);
          expect(performanceRec.suggestion, isNotEmpty);

          final reliabilityRec = reliabilityRecs.first;
          expect(reliabilityRec.title, contains('Success Rate'));
          expect(reliabilityRec.priority, equals(RecommendationPriority.high));
        },
      );

      test(
        'should handle empty metrics history for duration warnings',
        () async {
          // Clear any existing metrics
          performanceService.metricsHistory.clear();

          // Test with empty history - should not warn regardless of duration
          final longDuration = const Duration(minutes: 10);
          final shouldWarn = await performanceService.isBackupDurationAbnormal(
            longDuration,
          );
          expect(
            shouldWarn,
            isFalse,
            reason: 'Should not warn when no baseline metrics exist',
          );

          final shortDuration = const Duration(seconds: 1);
          final shouldWarnShort = await performanceService
              .isBackupDurationAbnormal(shortDuration);
          expect(
            shouldWarnShort,
            isFalse,
            reason: 'Should not warn when no baseline metrics exist',
          );
        },
      );

      test(
        'should provide specific optimization suggestions based on resource type',
        () async {
          // Test memory-specific optimization
          final highMemoryMetrics = BackupMetrics(
            operationId: 'high_memory_backup',
            startTime: DateTime.now().subtract(const Duration(minutes: 8)),
            endTime: DateTime.now(),
            totalDuration: const Duration(minutes: 8),
            compressionTime: const Duration(minutes: 2),
            uploadTime: const Duration(minutes: 5),
            validationTime: const Duration(seconds: 30),
            networkRetries: 1,
            averageUploadSpeed: 3.0,
            memoryUsage: 800 * 1024 * 1024, // Very high memory
            cpuIntensiveDuration: const Duration(minutes: 3),
            networkBytesTransferred: 300 * 1024 * 1024,
            successRate: 1.0,
          );

          performanceService.metricsHistory.clear();
          performanceService.metricsHistory.add(highMemoryMetrics);

          final isExcessive = await performanceService.isResourceUsageExcessive(
            highMemoryMetrics,
          );
          expect(
            isExcessive,
            isTrue,
            reason: 'High memory usage should be detected as excessive',
          );

          final recommendations = await performanceService
              .generateOptimizationRecommendations();
          expect(
            recommendations,
            isNotEmpty,
            reason: 'Should generate recommendations for high memory usage',
          );

          // Verify that performance recommendations are generated
          final perfRecs = recommendations.where(
            (r) => r.type == RecommendationType.performance,
          );
          expect(
            perfRecs,
            isNotEmpty,
            reason: 'Should have performance recommendations for slow backup',
          );
        },
      );
    });

    group('Metrics History Management', () {
      test('should cleanup old metrics when limit exceeded', () {
        // Add more than 100 metrics
        for (int i = 0; i < 105; i++) {
          final metrics = BackupMetrics.empty('test_$i');
          performanceService.metricsHistory.add(metrics);
        }

        expect(performanceService.metricsHistory.length, equals(105));

        performanceService.cleanupOldMetrics();

        expect(performanceService.metricsHistory.length, equals(100));
      });

      test('should not cleanup when under limit', () {
        // Add less than 100 metrics
        for (int i = 0; i < 50; i++) {
          final metrics = BackupMetrics.empty('test_$i');
          performanceService.metricsHistory.add(metrics);
        }

        expect(performanceService.metricsHistory.length, equals(50));

        performanceService.cleanupOldMetrics();

        expect(performanceService.metricsHistory.length, equals(50));
      });
    });
  });

  group('MetricsTracker', () {
    late MetricsTracker tracker;

    setUp(() {
      tracker = MetricsTracker();
    });

    test('should track operation metrics correctly', () async {
      const operationId = 'test_operation';

      final trackingId = await tracker.startTracking(operationId);
      expect(trackingId, contains(operationId));

      // Record some metrics
      tracker.recordCompressionTime(trackingId, const Duration(seconds: 5));
      tracker.recordUploadTime(trackingId, const Duration(seconds: 10));
      tracker.recordValidationTime(trackingId, const Duration(seconds: 2));
      tracker.recordNetworkRetry(trackingId);
      tracker.recordNetworkRetry(trackingId);
      tracker.recordUploadSpeed(trackingId, 2.5);
      tracker.recordMemoryUsage(trackingId, 100 * 1024 * 1024);
      tracker.recordNetworkTransfer(trackingId, 50 * 1024 * 1024);

      await Future.delayed(const Duration(milliseconds: 10));

      final metrics = await tracker.stopTracking(trackingId);

      expect(metrics.operationId, equals(operationId));
      expect(metrics.compressionTime, equals(const Duration(seconds: 5)));
      expect(metrics.uploadTime, equals(const Duration(seconds: 10)));
      expect(metrics.validationTime, equals(const Duration(seconds: 2)));
      expect(metrics.networkRetries, equals(2));
      expect(metrics.averageUploadSpeed, equals(2.5));
      expect(metrics.memoryUsage, equals(100 * 1024 * 1024));
      expect(metrics.networkBytesTransferred, equals(50 * 1024 * 1024));
      expect(metrics.totalDuration.inMilliseconds, greaterThan(0));
    });

    test('should throw error for invalid tracking ID', () async {
      expect(
        () => tracker.stopTracking('invalid_id'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should handle multiple concurrent tracking sessions', () async {
      final trackingId1 = await tracker.startTracking('operation_1');
      final trackingId2 = await tracker.startTracking('operation_2');

      tracker.recordCompressionTime(trackingId1, const Duration(seconds: 3));
      tracker.recordCompressionTime(trackingId2, const Duration(seconds: 5));

      final metrics1 = await tracker.stopTracking(trackingId1);
      final metrics2 = await tracker.stopTracking(trackingId2);

      expect(metrics1.operationId, equals('operation_1'));
      expect(metrics1.compressionTime, equals(const Duration(seconds: 3)));

      expect(metrics2.operationId, equals('operation_2'));
      expect(metrics2.compressionTime, equals(const Duration(seconds: 5)));
    });
  });

  group('ReportAnalyzer', () {
    late ReportAnalyzer analyzer;

    setUp(() {
      analyzer = ReportAnalyzer();
    });

    test('should analyze trends from empty metrics', () async {
      final trends = await analyzer.analyzeTrends([]);

      expect(trends.averageDuration, equals(Duration.zero));
      expect(trends.averageSize, equals(0.0));
      expect(trends.successRate, equals(1.0));
      expect(trends.trend, equals(PerformanceTrend.stable));
      expect(trends.sampleSize, equals(0));
    });

    test('should analyze trends from metrics data', () async {
      final metrics = [
        BackupMetrics(
          operationId: 'backup_1',
          startTime: DateTime.now().subtract(const Duration(hours: 3)),
          endTime: DateTime.now()
              .subtract(const Duration(hours: 3))
              .add(const Duration(minutes: 2)),
          totalDuration: const Duration(minutes: 2),
          compressionTime: const Duration(seconds: 30),
          uploadTime: const Duration(minutes: 1),
          validationTime: const Duration(seconds: 10),
          networkRetries: 0,
          averageUploadSpeed: 5.0,
          memoryUsage: 100 * 1024 * 1024,
          cpuIntensiveDuration: const Duration(minutes: 1),
          networkBytesTransferred: 50 * 1024 * 1024,
          successRate: 1.0,
        ),
        BackupMetrics(
          operationId: 'backup_2',
          startTime: DateTime.now().subtract(const Duration(hours: 2)),
          endTime: DateTime.now()
              .subtract(const Duration(hours: 2))
              .add(const Duration(minutes: 3)),
          totalDuration: const Duration(minutes: 3),
          compressionTime: const Duration(seconds: 45),
          uploadTime: const Duration(minutes: 1, seconds: 30),
          validationTime: const Duration(seconds: 15),
          networkRetries: 1,
          averageUploadSpeed: 4.0,
          memoryUsage: 120 * 1024 * 1024,
          cpuIntensiveDuration: const Duration(minutes: 2),
          networkBytesTransferred: 60 * 1024 * 1024,
          successRate: 1.0,
        ),
        BackupMetrics(
          operationId: 'backup_3',
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          endTime: DateTime.now()
              .subtract(const Duration(hours: 1))
              .add(const Duration(minutes: 4)),
          totalDuration: const Duration(minutes: 4),
          compressionTime: const Duration(minutes: 1),
          uploadTime: const Duration(minutes: 2),
          validationTime: const Duration(seconds: 20),
          networkRetries: 2,
          averageUploadSpeed: 3.0,
          memoryUsage: 150 * 1024 * 1024,
          cpuIntensiveDuration: const Duration(minutes: 3),
          networkBytesTransferred: 70 * 1024 * 1024,
          successRate: 0.9,
        ),
      ];

      final trends = await analyzer.analyzeTrends(metrics);

      expect(trends.averageDuration, equals(const Duration(minutes: 3)));
      expect(
        trends.averageSize,
        equals(60 * 1024 * 1024),
      ); // Average of 50, 60, 70 MB
      expect(
        trends.successRate,
        closeTo(0.667, 0.01),
      ); // 2 out of 3 metrics have successRate > 0.9
      expect(
        trends.trend,
        equals(PerformanceTrend.degrading),
      ); // Duration increasing from 2 to 4 minutes
      expect(trends.sampleSize, equals(3));
    });

    test('should generate appropriate recommendations', () async {
      final trends = PerformanceTrendAnalysis(
        averageDuration: const Duration(minutes: 8), // Slow
        averageSize: 100 * 1024 * 1024,
        successRate: 0.7, // Low success rate
        trend: PerformanceTrend.degrading,
        sampleSize: 10,
        analysisDate: DateTime.now(),
      );

      final recommendations = await analyzer.generateRecommendations(
        trends,
        [],
      );

      expect(recommendations.length, greaterThanOrEqualTo(3));

      // Should have performance, reliability, and maintenance recommendations
      final types = recommendations.map((r) => r.type).toSet();
      expect(types, contains(RecommendationType.performance));
      expect(types, contains(RecommendationType.reliability));
      expect(types, contains(RecommendationType.maintenance));

      // Check priority levels
      final highPriorityRecs = recommendations.where(
        (r) => r.priority == RecommendationPriority.high,
      );
      expect(
        highPriorityRecs,
        isNotEmpty,
      ); // Low success rate should be high priority
    });
  });

  group('BackupMetrics', () {
    test('should create empty metrics correctly', () {
      const operationId = 'empty_test';
      final metrics = BackupMetrics.empty(operationId);

      expect(metrics.operationId, equals(operationId));
      expect(metrics.totalDuration, equals(Duration.zero));
      expect(metrics.successRate, equals(0.0));
      expect(metrics.networkRetries, equals(0));
      expect(metrics.memoryUsage, equals(0));
    });

    test('should serialize to JSON correctly', () {
      final now = DateTime.now();
      final metrics = BackupMetrics(
        operationId: 'json_test',
        startTime: now,
        endTime: now.add(const Duration(minutes: 5)),
        totalDuration: const Duration(minutes: 5),
        compressionTime: const Duration(minutes: 1),
        uploadTime: const Duration(minutes: 3),
        validationTime: const Duration(seconds: 30),
        networkRetries: 2,
        averageUploadSpeed: 4.5,
        memoryUsage: 200 * 1024 * 1024,
        cpuIntensiveDuration: const Duration(minutes: 4),
        networkBytesTransferred: 100 * 1024 * 1024,
        successRate: 0.95,
      );

      final json = metrics.toJson();

      expect(json['operationId'], equals('json_test'));
      expect(
        json['totalDuration'],
        equals(5 * 60 * 1000),
      ); // 5 minutes in milliseconds
      expect(json['networkRetries'], equals(2));
      expect(json['averageUploadSpeed'], equals(4.5));
      expect(json['successRate'], equals(0.95));
    });
  });
}
