import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:money/services/auth/audit_logger_service.dart';
import 'package:money/models/security/security_event.dart';
import '../../property_test_utils.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Security Event Logging Consistency Property Tests', () {
    late AuditLoggerService auditLogger;

    setUpAll(() {
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

    // **Feature: pin-biometric-auth, Property 9: Güvenlik Olayı Kayıt Tutarlılığı**
    // **Validates: Requirements 3.5, 7.5, 9.5**
    PropertyTest.forAll<SecurityEvent>(
      description:
          'Property 9: Güvenlik Olayı Kayıt Tutarlılığı - Herhangi bir güvenlik olayı için, olay audit loguna kaydedilmelidir',
      generator: () => _generateRandomSecurityEvent(),
      property: (securityEvent) async {
        try {
          // Initialize the audit logger
          await auditLogger.initialize();

          // Get initial event count (after initialization)
          final initialHistory = await auditLogger.getSecurityHistory();
          final initialCount = initialHistory.length;

          // Log the security event
          final logResult = await auditLogger.logSecurityEvent(securityEvent);

          // Property violation: Logging should always succeed
          if (!logResult) {
            print(
              'PROPERTY VIOLATION: Failed to log security event. Event: ${securityEvent.toString()}',
            );
            return false;
          }

          // Get updated event count
          final updatedHistory = await auditLogger.getSecurityHistory();
          final updatedCount = updatedHistory.length;

          // Property violation: Event count should increase by exactly 1
          if (updatedCount != initialCount + 1) {
            print(
              'PROPERTY VIOLATION: Event count did not increase by 1. Initial: $initialCount, Updated: $updatedCount, Event: ${securityEvent.toString()}',
            );
            return false;
          }

          // Property violation: The logged event should be retrievable
          // Look for our specific event by eventId instead of just taking the most recent
          final allEvents = await auditLogger.getSecurityHistory();
          final loggedEvent = allEvents.firstWhere(
            (e) => e.eventId == securityEvent.eventId,
            orElse: () => throw Exception('Event not found'),
          );

          // Property violation: The logged event should match the original event
          if (!_eventsMatch(securityEvent, loggedEvent)) {
            print(
              'PROPERTY VIOLATION: Logged event does not match original. Original: ${securityEvent.toString()}, Logged: ${loggedEvent.toString()}',
            );
            return false;
          }

          // Additional consistency check: Event should be findable by type filter
          final eventsByType = await auditLogger.getSecurityHistory(
            eventTypes: [securityEvent.type],
            limit: 10,
          );

          final foundEvent = eventsByType.any(
            (e) => e.eventId == securityEvent.eventId,
          );
          if (!foundEvent) {
            print(
              'PROPERTY VIOLATION: Event not found when filtering by type. Event: ${securityEvent.toString()}',
            );
            return false;
          }

          // Additional consistency check: Event should be findable by severity filter
          final eventsBySeverity = await auditLogger.getSecurityHistory(
            severities: [securityEvent.severity],
            limit: 10,
          );

          final foundBySeverity = eventsBySeverity.any(
            (e) => e.eventId == securityEvent.eventId,
          );
          if (!foundBySeverity) {
            print(
              'PROPERTY VIOLATION: Event not found when filtering by severity. Event: ${securityEvent.toString()}',
            );
            return false;
          }

          // Additional consistency check: Event should be findable by user ID filter (if userId is not null)
          if (securityEvent.userId != null) {
            final eventsByUser = await auditLogger.getSecurityHistory(
              userId: securityEvent.userId,
              limit: 10,
            );

            final foundByUser = eventsByUser.any(
              (e) => e.eventId == securityEvent.eventId,
            );
            if (!foundByUser) {
              print(
                'PROPERTY VIOLATION: Event not found when filtering by user ID. Event: ${securityEvent.toString()}',
              );
              return false;
            }
          }

          return true;
        } catch (e) {
          // Any exception means the property failed
          print(
            'PROPERTY VIOLATION: Exception occurred during logging test. Event: ${securityEvent.toString()}, Error: $e',
          );
          return false;
        }
      },
      iterations: 100,
    );
  });
}

/// Generate a random security event for testing
SecurityEvent _generateRandomSecurityEvent() {
  final eventTypes = SecurityEventType.values;
  final severities = SecurityEventSeverity.values;
  final sources = [
    'PINService',
    'BiometricService',
    'SecurityService',
    'SessionManager',
    'AuthService',
  ];

  final type =
      eventTypes[PropertyTest.randomInt(min: 0, max: eventTypes.length - 1)];
  final severity =
      severities[PropertyTest.randomInt(min: 0, max: severities.length - 1)];
  final source =
      sources[PropertyTest.randomInt(min: 0, max: sources.length - 1)];

  // Generate optional user ID (50% chance)
  final userId = PropertyTest.randomBool()
      ? 'user_${PropertyTest.randomString(minLength: 5, maxLength: 10)}'
      : null;

  // Generate random description
  final description =
      'Test event: ${PropertyTest.randomString(minLength: 10, maxLength: 50)}';

  // Generate random metadata
  final metadata = <String, dynamic>{
    'testData': PropertyTest.randomString(minLength: 5, maxLength: 20),
    'randomNumber': PropertyTest.randomInt(min: 1, max: 1000),
    'timestamp': DateTime.now().toIso8601String(),
  };

  // Add type-specific metadata
  switch (type) {
    case SecurityEventType.pinFailed:
      metadata['remainingAttempts'] = PropertyTest.randomInt(min: 0, max: 5);
      break;
    case SecurityEventType.biometricEnrolled:
    case SecurityEventType.biometricVerified:
    case SecurityEventType.biometricFailed:
      metadata['biometricType'] = [
        'fingerprint',
        'face',
        'voice',
      ][PropertyTest.randomInt(min: 0, max: 2)];
      break;
    case SecurityEventType.accountLocked:
      metadata['lockoutDuration'] = PropertyTest.randomInt(
        min: 30000,
        max: 300000,
      ); // 30s to 5min in ms
      metadata['reason'] = 'Too many failed attempts';
      break;
    case SecurityEventType.sessionStarted:
      metadata['authMethod'] = [
        'PIN',
        'Biometric',
        'TwoFactor',
      ][PropertyTest.randomInt(min: 0, max: 2)];
      break;
    case SecurityEventType.sessionEnded:
      metadata['reason'] = [
        'timeout',
        'logout',
        'lockout',
      ][PropertyTest.randomInt(min: 0, max: 2)];
      break;
    case SecurityEventType.securitySettingsChanged:
      metadata['setting'] = 'testSetting';
      metadata['oldValue'] = 'oldValue';
      metadata['newValue'] = 'newValue';
      break;
    default:
      // Keep default metadata
      break;
  }

  return SecurityEvent(
    type: type,
    userId: userId,
    description: description,
    severity: severity,
    source: source,
    metadata: metadata,
    timestamp: PropertyTest.randomDateTime(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    ),
  );
}

/// Check if two security events match (for logging consistency verification)
bool _eventsMatch(SecurityEvent original, SecurityEvent logged) {
  // Check core properties
  if (original.type != logged.type) return false;
  if (original.userId != logged.userId) return false;
  if (original.description != logged.description) return false;
  if (original.severity != logged.severity) return false;
  if (original.source != logged.source) return false;
  if (original.eventId != logged.eventId) return false;

  // Check timestamp (should be very close, allowing for small differences due to processing time)
  final timeDiff = original.timestamp.difference(logged.timestamp).abs();
  if (timeDiff.inSeconds > 5) return false; // Allow up to 5 seconds difference

  // Check metadata (should contain all original metadata)
  for (final key in original.metadata.keys) {
    if (!logged.metadata.containsKey(key)) return false;
    if (logged.metadata[key] != original.metadata[key]) return false;
  }

  return true;
}
