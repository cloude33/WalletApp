import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parion/utils/security/clipboard_security.dart';

void main() {
  group('ClipboardSecurity', () {
    late ClipboardSecurity clipboardSecurity;

    setUp(() async {
      // Initialize Flutter binding for tests
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      // Mock clipboard operations
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          return null;
        } else if (methodCall.method == 'Clipboard.getData') {
          return {'text': ''};
        }
        return null;
      });
      
      clipboardSecurity = ClipboardSecurity();
    });

    tearDown(() async {
      await clipboardSecurity.dispose();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        await clipboardSecurity.initialize();
        
        final status = await clipboardSecurity.getSecurityStatus();
        expect(status.isSecurityEnabled, isTrue);
        expect(status.isAutoCleanupEnabled, isTrue);
      });
    });

    group('Sensitive Data Detection', () {
      test('should detect PIN codes as sensitive', () async {
        await clipboardSecurity.initialize();
        
        // Test 4-digit PIN
        final result1 = await clipboardSecurity.copyText('1234');
        expect(result1, isFalse);
        
        // Test 6-digit PIN
        final result2 = await clipboardSecurity.copyText('123456');
        expect(result2, isFalse);
      });

      test('should detect credit card numbers as sensitive', () async {
        await clipboardSecurity.initialize();
        
        final result = await clipboardSecurity.copyText('4532 1234 5678 9012');
        expect(result, isFalse);
      });

      test('should detect IBAN numbers as sensitive', () async {
        await clipboardSecurity.initialize();
        
        final result = await clipboardSecurity.copyText('TR33 0006 1005 1978 6457 8413 26');
        expect(result, isFalse);
      });

      test('should allow non-sensitive text', () async {
        await clipboardSecurity.initialize();
        
        final result = await clipboardSecurity.copyText('Hello World');
        expect(result, isTrue);
      });
    });

    group('Security Controls', () {
      test('should allow copying when security is disabled', () async {
        await clipboardSecurity.initialize();
        await clipboardSecurity.disableClipboardSecurity();
        
        final result = await clipboardSecurity.copyText('1234');
        expect(result, isTrue);
      });

      test('should track blocked attempts', () async {
        await clipboardSecurity.initialize();
        
        // Try to copy sensitive data multiple times
        await clipboardSecurity.copyText('1234');
        await clipboardSecurity.copyText('5678');
        
        final status = await clipboardSecurity.getSecurityStatus();
        expect(status.blockedAttempts, equals(2));
      });

      test('should reset blocked attempts', () async {
        await clipboardSecurity.initialize();
        
        // Block some attempts
        await clipboardSecurity.copyText('1234');
        await clipboardSecurity.copyText('5678');
        
        // Reset
        await clipboardSecurity.resetBlockedAttempts();
        
        final status = await clipboardSecurity.getSecurityStatus();
        expect(status.blockedAttempts, equals(0));
      });
    });

    group('Auto Cleanup', () {
      test('should enable auto cleanup with custom interval', () async {
        await clipboardSecurity.initialize();
        
        const customInterval = Duration(minutes: 10);
        await clipboardSecurity.enableAutoCleanup(interval: customInterval);
        
        final status = await clipboardSecurity.getSecurityStatus();
        expect(status.isAutoCleanupEnabled, isTrue);
        expect(status.cleanupInterval, equals(customInterval));
      });

      test('should disable auto cleanup', () async {
        await clipboardSecurity.initialize();
        
        await clipboardSecurity.disableAutoCleanup();
        
        final status = await clipboardSecurity.getSecurityStatus();
        expect(status.isAutoCleanupEnabled, isFalse);
      });
    });

    group('Secure Share', () {
      test('should block sharing sensitive data', () async {
        await clipboardSecurity.initialize();
        
        final result = await clipboardSecurity.secureShare('1234');
        expect(result, isFalse);
      });

      test('should allow sharing non-sensitive data', () async {
        await clipboardSecurity.initialize();
        
        final result = await clipboardSecurity.secureShare('Hello World');
        expect(result, isTrue);
      });
    });

    group('Pattern Updates', () {
      test('should update sensitive patterns', () async {
        await clipboardSecurity.initialize();
        
        // Add custom pattern for email addresses
        final customPatterns = [
          RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
        ];
        
        clipboardSecurity.updateSensitivePatterns(customPatterns);
        
        // Test with email
        final result = await clipboardSecurity.copyText('test@example.com');
        expect(result, isFalse);
      });

      test('should update allowed apps', () async {
        await clipboardSecurity.initialize();
        
        final allowedApps = {'com.example.testapp'};
        clipboardSecurity.updateAllowedApps(allowedApps);
        
        // This would need platform channel implementation to fully test
        expect(() => clipboardSecurity.updateAllowedApps(allowedApps), returnsNormally);
      });
    });

    group('Status Serialization', () {
      test('should serialize and deserialize status correctly', () async {
        await clipboardSecurity.initialize();
        
        final originalStatus = await clipboardSecurity.getSecurityStatus();
        final json = originalStatus.toJson();
        final deserializedStatus = ClipboardSecurityStatus.fromJson(json);
        
        expect(deserializedStatus.isSecurityEnabled, equals(originalStatus.isSecurityEnabled));
        expect(deserializedStatus.isAutoCleanupEnabled, equals(originalStatus.isAutoCleanupEnabled));
        expect(deserializedStatus.cleanupInterval, equals(originalStatus.cleanupInterval));
        expect(deserializedStatus.blockedAttempts, equals(originalStatus.blockedAttempts));
      });
    });
  });
}