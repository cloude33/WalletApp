import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:money/services/auth/audit_logger_service.dart';
import 'package:money/models/security/security_event.dart';

// Mock path provider for testing
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    // Create a unique temp directory for each test
    final tempDir = Directory.systemTemp;
    final testDir = Directory(
      '${tempDir.path}/audit_test_${DateTime.now().millisecondsSinceEpoch}',
    );
    await testDir.create(recursive: true);
    return testDir.path;
  }
}

void main() {
  group('AuditLoggerService', () {
    late AuditLoggerService auditLogger;

    setUpAll(() {
      // Initialize Flutter binding for tests
      TestWidgetsFlutterBinding.ensureInitialized();

      // Mock secure storage method channel using the new API
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
            (MethodCall methodCall) async {
              switch (methodCall.method) {
                case 'read':
                  return null; // Return null for all reads (no stored data)
                case 'write':
                  return null; // Success
                case 'delete':
                  return null; // Success
                case 'deleteAll':
                  return null; // Success
                case 'readAll':
                  return <String, String>{}; // Empty map
                default:
                  return null;
              }
            },
          );

      // Mock shared preferences method channel using the new API
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/shared_preferences'),
            (MethodCall methodCall) async {
              switch (methodCall.method) {
                case 'getAll':
                  return <String, dynamic>{}; // Empty map
                case 'setBool':
                case 'setInt':
                case 'setDouble':
                case 'setString':
                case 'setStringList':
                  return true; // Success
                case 'remove':
                  return true; // Success
                case 'clear':
                  return true; // Success
                default:
                  return null;
              }
            },
          );
    });

    setUp(() {
      // Register mock path provider for each test
      PathProviderPlatform.instance = MockPathProviderPlatform();
      auditLogger = AuditLoggerService();
    });

    test('should initialize successfully', () async {
      await auditLogger.initialize();
      expect(true, isTrue); // If we get here, initialization succeeded
    });

    test('should log security events', () async {
      await auditLogger.initialize();

      final event = SecurityEvent.biometricEnrolled(
        userId: 'test_user',
        biometricType: 'fingerprint',
        metadata: {'test': 'data'},
      );

      final result = await auditLogger.logSecurityEvent(event);
      expect(result, isTrue);
    });

    test('should handle configuration updates', () async {
      await auditLogger.initialize();

      final newConfig = AuditLogConfig(
        maxLogFileSize: 2048 * 1024, // 2MB
        maxLogFiles: 5,
        maxLogAge: 15,
        maxEventsPerFile: 500,
      );

      final result = await auditLogger.updateConfiguration(newConfig);
      expect(result, isTrue);

      final retrievedConfig = await auditLogger.getConfiguration();
      expect(retrievedConfig.maxLogFileSize, equals(2048 * 1024));
      expect(retrievedConfig.maxLogFiles, equals(5));
      expect(retrievedConfig.maxLogAge, equals(15));
      expect(retrievedConfig.maxEventsPerFile, equals(500));
    });

    test('should get storage statistics', () async {
      await auditLogger.initialize();

      final stats = await auditLogger.getStorageStats();

      expect(stats.totalFiles, greaterThanOrEqualTo(0));
      expect(stats.totalSize, greaterThanOrEqualTo(0));
      expect(stats.totalEvents, greaterThanOrEqualTo(0));
    });

    test('should clear old logs', () async {
      await auditLogger.initialize();

      final removedCount = await auditLogger.clearOldLogs();
      expect(removedCount, greaterThanOrEqualTo(0));
    });

    test('should generate security report with empty data', () async {
      await auditLogger.initialize();

      final report = await auditLogger.generateSecurityReport();

      expect(report.totalEvents, greaterThanOrEqualTo(0));
      expect(report.statistics, isNotEmpty);
      expect(report.statistics['totalEvents'], greaterThanOrEqualTo(0));
      expect(report.statistics['eventTypeCounts'], isA<Map<String, int>>());
      expect(report.statistics['severityCounts'], isA<Map<String, int>>());
    });

    test('should export empty security logs to JSON', () async {
      await auditLogger.initialize();

      final jsonExport = await auditLogger.exportSecurityLogs(format: 'json');

      expect(jsonExport, isNotEmpty);
      expect(jsonExport, contains('exportedAt'));
      expect(jsonExport, contains('totalEvents'));
      expect(jsonExport, contains('events'));
    });

    test('should export empty security logs to CSV', () async {
      await auditLogger.initialize();

      final csvExport = await auditLogger.exportSecurityLogs(format: 'csv');

      expect(csvExport, isNotEmpty);
      expect(csvExport, contains('EventID,Type,Timestamp'));
    });
  });

  group('AuditLogConfig', () {
    test('should serialize to and from JSON', () {
      final config = AuditLogConfig(
        maxLogFileSize: 1024 * 1024,
        maxLogFiles: 10,
        maxLogAge: 30,
        maxEventsPerFile: 1000,
      );

      final json = config.toJson();
      final restored = AuditLogConfig.fromJson(json);

      expect(restored.maxLogFileSize, equals(config.maxLogFileSize));
      expect(restored.maxLogFiles, equals(config.maxLogFiles));
      expect(restored.maxLogAge, equals(config.maxLogAge));
      expect(restored.maxEventsPerFile, equals(config.maxEventsPerFile));
    });
  });

  group('SecurityReport', () {
    test('should serialize to and from JSON', () {
      final now = DateTime.now();
      final events = [
        SecurityEvent.biometricEnrolled(userId: 'user1', biometricType: 'fingerprint'),
        SecurityEvent.biometricVerified(userId: 'user1', biometricType: 'fingerprint'),
      ];

      final report = SecurityReport(
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now,
        totalEvents: events.length,
        statistics: {'test': 'data'},
        events: events,
        generatedAt: now,
      );

      final json = report.toJson();
      final restored = SecurityReport.fromJson(json);

      expect(restored.totalEvents, equals(report.totalEvents));
      expect(restored.events.length, equals(report.events.length));
      expect(restored.statistics, equals(report.statistics));
    });
  });

  group('LogStorageStats', () {
    test('should serialize to and from JSON', () {
      final now = DateTime.now();
      final stats = LogStorageStats(
        totalFiles: 5,
        totalSize: 1024,
        totalEvents: 100,
        oldestLog: now.subtract(const Duration(days: 7)),
        newestLog: now,
        averageFileSize: 204.8,
      );

      final json = stats.toJson();
      final restored = LogStorageStats.fromJson(json);

      expect(restored.totalFiles, equals(stats.totalFiles));
      expect(restored.totalSize, equals(stats.totalSize));
      expect(restored.totalEvents, equals(stats.totalEvents));
      expect(restored.averageFileSize, equals(stats.averageFileSize));
    });
  });
}
