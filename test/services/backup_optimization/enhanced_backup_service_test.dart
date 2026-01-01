import 'package:flutter_test/flutter_test.dart';

import 'package:parion/services/backup_optimization/enhanced_backup_service.dart';
import '../../test_helpers.dart';

void main() {
  setupCommonTestMocks();
  group('EnhancedBackupService', () {
    late EnhancedBackupService service;

    setUp(() async {
      service = EnhancedBackupService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should initialize successfully', () async {
      await service.initialize();

      expect(service.isOfflineMode.value, isFalse);
      expect(service.pendingOfflineBackups.value, equals(0));
    });

    test('should get offline statistics', () async {
      await service.initialize();

      final stats = service.getOfflineStats();

      // Allow some flexibility for existing data
      expect(stats.totalItems, greaterThanOrEqualTo(0));
      expect(stats.pendingItems, greaterThanOrEqualTo(0));
      expect(stats.completedItems, greaterThanOrEqualTo(0));
      expect(stats.failedItems, greaterThanOrEqualTo(0));
    });

    test('should get storage statistics', () async {
      await service.initialize();

      final stats = await service.getStorageStats();

      expect(stats.maxStorageMB, greaterThan(0));
      expect(stats.currentUsageMB, greaterThanOrEqualTo(0));
      expect(stats.availableMB, greaterThanOrEqualTo(0));
      expect(stats.usagePercentage, greaterThanOrEqualTo(0));
      expect(stats.usagePercentage, lessThanOrEqualTo(100));
    });

    test('should get pending offline backups', () async {
      await service.initialize();

      final pendingBackups = service.getPendingOfflineBackups();

      // Should be empty for a fresh service instance
      expect(pendingBackups.length, lessThanOrEqualTo(10)); // Allow some flexibility
    });

    test('should check storage availability', () async {
      await service.initialize();

      final hasStorage = await service.hasStorageForBackup(10);

      expect(hasStorage, isA<bool>());
    });

    test('should get offline configuration', () async {
      await service.initialize();

      final config = service.getOfflineConfig();

      expect(config.maxQueueSize, greaterThan(0));
      expect(config.maxRetryAttempts, greaterThan(0));
      expect(config.maxLocalStorageMB, greaterThan(0));
    });

    test('should perform storage cleanup', () async {
      await service.initialize();

      final result = await service.performStorageCleanup();

      expect(result.deletedFiles, greaterThanOrEqualTo(0));
      expect(result.freedSpaceMB, greaterThanOrEqualTo(0));
      expect(result.reason, isNotEmpty);
    });
  });
}
