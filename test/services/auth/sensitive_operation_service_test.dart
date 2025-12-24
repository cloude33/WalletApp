import 'package:flutter_test/flutter_test.dart';
import 'package:money/services/auth/sensitive_operation_service.dart';
import 'package:money/models/security/security_models.dart';

void main() {
  group('SensitiveOperationService', () {
    late SensitiveOperationService service;

    setUp(() {
      service = SensitiveOperationService();
    });

    tearDown(() {
      service.resetForTesting();
    });

    group('isSensitiveScreen', () {
      test('should return true for sensitive screens', () {
        // Arrange & Act & Assert
        expect(service.isSensitiveScreen('add_transaction_screen'), isTrue);
        expect(service.isSensitiveScreen('security_settings_screen'), isTrue);
        expect(service.isSensitiveScreen('credit_card_detail_screen'), isTrue);
        expect(service.isSensitiveScreen('export_screen'), isTrue);
      });

      test('should return false for non-sensitive screens', () {
        // Arrange & Act & Assert
        expect(service.isSensitiveScreen('home_screen'), isFalse);
        expect(service.isSensitiveScreen('about_screen'), isFalse);
        expect(service.isSensitiveScreen('help_screen'), isFalse);
      });
    });

    group('getOperationTypeFromScreen', () {
      test('should return correct operation type for transaction screens', () {
        // Arrange & Act
        final result1 = service.getOperationTypeFromScreen('add_transaction_screen');
        final result2 = service.getOperationTypeFromScreen('edit_transaction_screen');

        // Assert
        expect(result1, equals(SensitiveOperationType.moneyTransfer));
        expect(result2, equals(SensitiveOperationType.moneyTransfer));
      });

      test('should return correct operation type for security screens', () {
        // Arrange & Act
        final result1 = service.getOperationTypeFromScreen('security_settings_screen');
        final result2 = service.getOperationTypeFromScreen('pin_setup_screen');

        // Assert
        expect(result1, equals(SensitiveOperationType.securitySettingsChange));
        expect(result2, equals(SensitiveOperationType.securitySettingsChange));
      });

      test('should return correct operation type for detail screens', () {
        // Arrange & Act
        final result1 = service.getOperationTypeFromScreen('credit_card_detail_screen');
        final result2 = service.getOperationTypeFromScreen('kmh_account_detail_screen');

        // Assert
        expect(result1, equals(SensitiveOperationType.accountInfoView));
        expect(result2, equals(SensitiveOperationType.accountInfoView));
      });

      test('should return null for unknown screens', () {
        // Arrange & Act
        final result = service.getOperationTypeFromScreen('unknown_screen');

        // Assert
        expect(result, isNull);
      });
    });


  });

  group('SensitiveOperationResult', () {
    test('should create successful result correctly', () {
      // Arrange & Act
      final result = SensitiveOperationResult.success(
        operationType: SensitiveOperationType.moneyTransfer,
        securityLevel: OperationSecurityLevel.enhanced,
        authMethod: AuthMethod.pin,
        metadata: {'test': 'data'},
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.operationType, equals(SensitiveOperationType.moneyTransfer));
      expect(result.securityLevel, equals(OperationSecurityLevel.enhanced));
      expect(result.authMethod, equals(AuthMethod.pin));
      expect(result.errorMessage, isNull);
      expect(result.metadata?['test'], equals('data'));
    });

    test('should create failure result correctly', () {
      // Arrange & Act
      final result = SensitiveOperationResult.failure(
        operationType: SensitiveOperationType.securitySettingsChange,
        securityLevel: OperationSecurityLevel.multiMethod,
        authMethod: AuthMethod.biometric,
        errorMessage: 'Authentication failed',
        remainingAttempts: 2,
      );

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.operationType, equals(SensitiveOperationType.securitySettingsChange));
      expect(result.securityLevel, equals(OperationSecurityLevel.multiMethod));
      expect(result.authMethod, equals(AuthMethod.biometric));
      expect(result.errorMessage, equals('Authentication failed'));
      expect(result.remainingAttempts, equals(2));
    });
  });

  group('SensitiveOperationEvent', () {
    test('should create started event correctly', () {
      // Arrange & Act
      final event = SensitiveOperationEvent.started(
        operationType: SensitiveOperationType.dataExport,
        context: {'exportType': 'full'},
      );

      // Assert
      expect(event.type, equals(SensitiveOperationEventType.started));
      expect(event.operationType, equals(SensitiveOperationType.dataExport));
      expect(event.authMethod, isNull);
      expect(event.errorMessage, isNull);
      expect(event.context?['exportType'], equals('full'));
      expect(event.timestamp, isNotNull);
    });

    test('should create authenticated event correctly', () {
      // Arrange & Act
      final event = SensitiveOperationEvent.authenticated(
        operationType: SensitiveOperationType.accountInfoView,
        authMethod: AuthMethod.pin,
        context: {'userId': '123'},
      );

      // Assert
      expect(event.type, equals(SensitiveOperationEventType.authenticated));
      expect(event.operationType, equals(SensitiveOperationType.accountInfoView));
      expect(event.authMethod, equals(AuthMethod.pin));
      expect(event.errorMessage, isNull);
      expect(event.context?['userId'], equals('123'));
    });

    test('should create failed event correctly', () {
      // Arrange & Act
      final event = SensitiveOperationEvent.failed(
        operationType: SensitiveOperationType.moneyTransfer,
        authMethod: AuthMethod.biometric,
        errorMessage: 'Biometric authentication failed',
      );

      // Assert
      expect(event.type, equals(SensitiveOperationEventType.failed));
      expect(event.operationType, equals(SensitiveOperationType.moneyTransfer));
      expect(event.authMethod, equals(AuthMethod.biometric));
      expect(event.errorMessage, equals('Biometric authentication failed'));
    });

    test('should create error event correctly', () {
      // Arrange & Act
      final event = SensitiveOperationEvent.error(
        operationType: SensitiveOperationType.creditCardPayment,
        errorMessage: 'System error occurred',
        context: {'errorCode': '500'},
      );

      // Assert
      expect(event.type, equals(SensitiveOperationEventType.error));
      expect(event.operationType, equals(SensitiveOperationType.creditCardPayment));
      expect(event.authMethod, isNull);
      expect(event.errorMessage, equals('System error occurred'));
      expect(event.context?['errorCode'], equals('500'));
    });
  });

  group('Enums', () {
    test('SensitiveOperationType should have correct display names', () {
      expect(SensitiveOperationType.moneyTransfer.displayName, equals('Para Transferi'));
      expect(SensitiveOperationType.securitySettingsChange.displayName, equals('Güvenlik Ayarları'));
      expect(SensitiveOperationType.accountInfoView.displayName, equals('Hesap Bilgileri'));
      expect(SensitiveOperationType.dataExport.displayName, equals('Veri Export'));
    });

    test('OperationSecurityLevel should have correct display names', () {
      expect(OperationSecurityLevel.standard.displayName, equals('Standart'));
      expect(OperationSecurityLevel.recentAuth.displayName, equals('Son Doğrulama'));
      expect(OperationSecurityLevel.enhanced.displayName, equals('Gelişmiş'));
      expect(OperationSecurityLevel.multiMethod.displayName, equals('Çoklu Yöntem'));
      expect(OperationSecurityLevel.twoFactor.displayName, equals('İki Faktörlü'));
      expect(OperationSecurityLevel.fullAuth.displayName, equals('Tam Doğrulama'));
    });

    test('SensitiveOperationEventType should have correct display names', () {
      expect(SensitiveOperationEventType.started.displayName, equals('Başlatıldı'));
      expect(SensitiveOperationEventType.authenticated.displayName, equals('Doğrulandı'));
      expect(SensitiveOperationEventType.failed.displayName, equals('Başarısız'));
      expect(SensitiveOperationEventType.error.displayName, equals('Hata'));
    });
  });

  group('JSON Serialization', () {
    test('SensitiveOperationResult should serialize and deserialize correctly', () {
      // Arrange
      final original = SensitiveOperationResult.success(
        operationType: SensitiveOperationType.walletAccess,
        securityLevel: OperationSecurityLevel.recentAuth,
        authMethod: AuthMethod.pin,
        metadata: {'sessionId': 'abc123'},
      );

      // Act
      final json = original.toJson();
      final deserialized = SensitiveOperationResult.fromJson(json);

      // Assert
      expect(deserialized.isSuccess, equals(original.isSuccess));
      expect(deserialized.operationType, equals(original.operationType));
      expect(deserialized.securityLevel, equals(original.securityLevel));
      expect(deserialized.authMethod, equals(original.authMethod));
      expect(deserialized.metadata?['sessionId'], equals('abc123'));
    });

    test('SensitiveOperationEvent should serialize and deserialize correctly', () {
      // Arrange
      final original = SensitiveOperationEvent.authenticated(
        operationType: SensitiveOperationType.goalModification,
        authMethod: AuthMethod.biometric,
        context: {'goalId': '456'},
      );

      // Act
      final json = original.toJson();
      final deserialized = SensitiveOperationEvent.fromJson(json);

      // Assert
      expect(deserialized.type, equals(original.type));
      expect(deserialized.operationType, equals(original.operationType));
      expect(deserialized.authMethod, equals(original.authMethod));
      expect(deserialized.context?['goalId'], equals('456'));
      // Note: timestamp comparison might be slightly different due to serialization
    });
  });
}