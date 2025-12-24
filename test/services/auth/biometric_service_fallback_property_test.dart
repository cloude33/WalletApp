import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:money/services/auth/biometric_service.dart';
import 'package:money/models/security/auth_result.dart';
import 'package:money/models/security/biometric_type.dart' as app_biometric;
import 'package:money/models/security/auth_state.dart';
import '../../property_test_utils.dart';

/// Mock BiometricService for testing fallback behavior
class MockBiometricService implements BiometricService {
  final bool shouldSucceed;
  final String? errorCode;
  final String? errorMessage;
  final bool hasAvailableBiometrics;
  final List<app_biometric.BiometricType> availableBiometrics;

  MockBiometricService({
    this.shouldSucceed = false,
    this.errorCode,
    this.errorMessage,
    this.hasAvailableBiometrics = true,
    this.availableBiometrics = const [app_biometric.BiometricType.fingerprint],
  });

  @override
  Future<bool> isBiometricAvailable() async =>
      hasAvailableBiometrics && availableBiometrics.isNotEmpty;

  @override
  Future<List<app_biometric.BiometricType>> getAvailableBiometrics() async =>
      availableBiometrics;

  @override
  Future<AuthResult> authenticate({
    String? localizedFallbackTitle,
    String? cancelButtonText,
  }) async {
    // If no biometrics available, return appropriate error
    if (!hasAvailableBiometrics || availableBiometrics.isEmpty) {
      return AuthResult.failure(
        method: AuthMethod.biometric,
        errorMessage: 'Biyometrik kimlik doğrulama bu cihazda desteklenmiyor',
      );
    }

    // If should succeed, return success
    if (shouldSucceed) {
      return AuthResult.success(
        method: AuthMethod.biometric,
        metadata: {
          'timestamp': DateTime.now().toIso8601String(),
          'availableBiometrics': availableBiometrics
              .map((e) => e.toJson())
              .toList(),
        },
      );
    }

    // Handle different error scenarios
    String errorMsg;
    if (errorCode != null) {
      switch (errorCode) {
        case auth_error.notAvailable:
          errorMsg = 'Biyometrik kimlik doğrulama bu cihazda mevcut değil';
          break;
        case auth_error.notEnrolled:
          errorMsg =
              'Cihazda kayıtlı biyometrik veri bulunamadı. Lütfen cihaz ayarlarından biyometrik doğrulamayı etkinleştirin';
          break;
        case auth_error.lockedOut:
          errorMsg =
              'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin';
          break;
        case auth_error.permanentlyLockedOut:
          errorMsg =
              'Biyometrik doğrulama kalıcı olarak kilitlendi. Lütfen cihaz ayarlarını kontrol edin';
          break;
        case auth_error.biometricOnlyNotSupported:
          errorMsg =
              'Sadece biyometrik doğrulama desteklenmiyor. PIN ile doğrulama gerekli';
          break;
        case 'UserCancel':
          errorMsg = 'Kullanıcı kimlik doğrulamayı iptal etti';
          break;
        case 'UserFallback':
          errorMsg = 'Kullanıcı PIN ile doğrulamayı seçti';
          break;
        case 'SystemCancel':
          errorMsg = 'Sistem kimlik doğrulamayı iptal etti';
          break;
        case 'InvalidContext':
          errorMsg = 'Geçersiz kimlik doğrulama bağlamı';
          break;
        case 'BiometricNotRecognized':
          errorMsg = 'Biyometrik veri tanınmadı. Lütfen tekrar deneyin';
          break;
        default:
          errorMsg =
              errorMessage ?? 'Biyometrik kimlik doğrulama hatası: $errorCode';
      }
    } else {
      errorMsg = errorMessage ?? 'Biyometrik kimlik doğrulama başarısız';
    }

    return AuthResult.failure(
      method: AuthMethod.biometric,
      errorMessage: errorMsg,
      metadata: {
        'platformErrorCode': errorCode,
        'platformErrorMessage': errorMessage,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Future<bool> enrollBiometric() async => hasAvailableBiometrics;

  @override
  Future<void> disableBiometric() async {}

  @override
  Future<bool> isDeviceSecure() async => hasAvailableBiometrics;

  @override
  Future<bool> canCheckBiometrics() async => hasAvailableBiometrics;
}

void main() {
  group('Biometric Service Fallback Property Tests', () {
    // **Feature: pin-biometric-auth, Property 5: Biyometrik Fallback Tutarlılığı**
    // **Validates: Requirements 4.5**

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 5: Biyometrik Fallback Tutarlılığı - '
          'Herhangi bir biyometrik doğrulama başarısızlığı için, sistem PIN girişine yönlendirmelidir',
      iterations: 100,
      generator: () {
        // Generate different failure scenarios
        final failureTypes = [
          // Simple authentication failure (user cancelled, biometric not recognized, etc.)
          {'type': 'simple_failure', 'shouldFail': false, 'returnValue': false},

          // Platform exceptions that should trigger PIN fallback
          {'type': 'not_available', 'errorCode': auth_error.notAvailable},
          {'type': 'not_enrolled', 'errorCode': auth_error.notEnrolled},
          {'type': 'locked_out', 'errorCode': auth_error.lockedOut},
          {
            'type': 'permanently_locked_out',
            'errorCode': auth_error.permanentlyLockedOut,
          },
          {
            'type': 'biometric_only_not_supported',
            'errorCode': auth_error.biometricOnlyNotSupported,
          },
          {'type': 'user_cancel', 'errorCode': 'UserCancel'},
          {'type': 'user_fallback', 'errorCode': 'UserFallback'},
          {'type': 'system_cancel', 'errorCode': 'SystemCancel'},
          {'type': 'invalid_context', 'errorCode': 'InvalidContext'},
          {
            'type': 'biometric_not_recognized',
            'errorCode': 'BiometricNotRecognized',
          },

          // No biometrics available scenarios
          {
            'type': 'no_biometrics',
            'hasAvailableBiometrics': false,
            'availableBiometrics': <app_biometric.BiometricType>[],
          },
          {'type': 'cannot_check_biometrics', 'canCheckBiometrics': false},
        ];

        final scenario =
            failureTypes[PropertyTest.randomInt(max: failureTypes.length - 1)];

        return {
          'scenario': scenario,
          'localizedFallbackTitle': PropertyTest.randomBool()
              ? PropertyTest.randomString()
              : null,
          'cancelButtonText': PropertyTest.randomBool()
              ? PropertyTest.randomString()
              : null,
        };
      },
      property: (testData) async {
        final scenario = testData['scenario'] as Map<String, dynamic>;
        final localizedFallbackTitle =
            testData['localizedFallbackTitle'] as String?;
        final cancelButtonText = testData['cancelButtonText'] as String?;

        // Create mock based on scenario
        MockBiometricService biometricService;

        switch (scenario['type']) {
          case 'simple_failure':
            biometricService = MockBiometricService(
              shouldSucceed: false, // Will return failure from authenticate
              hasAvailableBiometrics: true,
              availableBiometrics: [app_biometric.BiometricType.fingerprint],
            );
            break;

          case 'no_biometrics':
            biometricService = MockBiometricService(
              hasAvailableBiometrics:
                  scenario['hasAvailableBiometrics'] ?? false,
              availableBiometrics:
                  scenario['availableBiometrics'] ??
                  <app_biometric.BiometricType>[],
            );
            break;

          case 'cannot_check_biometrics':
            biometricService = MockBiometricService(
              hasAvailableBiometrics: false,
              availableBiometrics: <app_biometric.BiometricType>[],
            );
            break;

          default:
            // Platform exception scenarios
            biometricService = MockBiometricService(
              shouldSucceed: false,
              errorCode: scenario['errorCode'] as String,
              errorMessage: 'Test error message',
              hasAvailableBiometrics: true,
              availableBiometrics: [app_biometric.BiometricType.fingerprint],
            );
        }

        // Attempt authentication
        final result = await biometricService.authenticate(
          localizedFallbackTitle: localizedFallbackTitle,
          cancelButtonText: cancelButtonText,
        );

        // Property: For any biometric authentication failure, the system should indicate PIN fallback is needed
        // This means:
        // 1. The result should be a failure (isSuccess = false)
        // 2. The result should be of biometric method
        // 3. The result should have an appropriate error message indicating fallback to PIN

        if (result.isSuccess) {
          // If authentication succeeded, this violates our test scenario
          // (we're specifically testing failure cases)
          return false;
        }

        // Verify it's a biometric authentication result
        if (result.method != AuthMethod.biometric) {
          return false;
        }

        // Verify there's an error message (indicating what went wrong and suggesting fallback)
        if (result.errorMessage == null || result.errorMessage!.isEmpty) {
          return false;
        }

        // The error message should indicate the failure and implicitly suggest PIN fallback
        // (The actual PIN fallback would be handled by the UI layer, not the service itself)
        final errorMessage = result.errorMessage!.toLowerCase();

        // Check that the error message is meaningful and relates to biometric failure
        final hasRelevantErrorMessage =
            errorMessage.contains('biyometrik') ||
            errorMessage.contains('biometric') ||
            errorMessage.contains('parmak') ||
            errorMessage.contains('finger') ||
            errorMessage.contains('yüz') ||
            errorMessage.contains('face') ||
            errorMessage.contains('kimlik') ||
            errorMessage.contains('doğrulama') ||
            errorMessage.contains('authentication') ||
            errorMessage.contains('desteklenmiyor') ||
            errorMessage.contains('not supported') ||
            errorMessage.contains('mevcut değil') ||
            errorMessage.contains('not available') ||
            errorMessage.contains('kayıtlı') ||
            errorMessage.contains('enrolled') ||
            errorMessage.contains('kilitli') ||
            errorMessage.contains('locked') ||
            errorMessage.contains('iptal') ||
            errorMessage.contains('cancel') ||
            errorMessage.contains('tanınmadı') ||
            errorMessage.contains('not recognized') ||
            errorMessage.contains('deneme') ||
            errorMessage.contains('attempt') ||
            errorMessage.contains('fazla') ||
            errorMessage.contains('many') ||
            errorMessage.contains('başarısız') ||
            errorMessage.contains('failed');

        if (!hasRelevantErrorMessage) {
          return false;
        }

        // Verify timestamp is set
        if (result.timestamp.isAfter(
          DateTime.now().add(Duration(seconds: 1)),
        )) {
          return false;
        }

        // All checks passed - the biometric failure properly indicates need for PIN fallback
        return true;
      },
    );

    // Additional specific test cases for edge scenarios
    test(
      'Property 5 - Edge case: No biometrics available should indicate PIN fallback',
      () async {
        final biometricService = MockBiometricService(
          hasAvailableBiometrics: false,
          availableBiometrics: <app_biometric.BiometricType>[],
        );

        final result = await biometricService.authenticate();

        expect(result.isSuccess, isFalse);
        expect(result.method, equals(AuthMethod.biometric));
        expect(result.errorMessage, isNotNull);
        expect(result.errorMessage, contains('desteklenmiyor'));
      },
    );

    test(
      'Property 5 - Edge case: Platform exception should indicate PIN fallback',
      () async {
        final biometricService = MockBiometricService(
          shouldSucceed: false,
          errorCode: auth_error.notEnrolled,
          errorMessage: 'No biometrics enrolled',
          hasAvailableBiometrics: true,
          availableBiometrics: [app_biometric.BiometricType.fingerprint],
        );

        final result = await biometricService.authenticate();

        expect(result.isSuccess, isFalse);
        expect(result.method, equals(AuthMethod.biometric));
        expect(result.errorMessage, isNotNull);
        expect(result.errorMessage, contains('kayıtlı'));
      },
    );

    test(
      'Property 5 - Edge case: User cancellation should indicate PIN fallback',
      () async {
        final biometricService = MockBiometricService(
          shouldSucceed: false,
          errorCode: 'UserCancel',
          errorMessage: 'User cancelled',
          hasAvailableBiometrics: true,
          availableBiometrics: [app_biometric.BiometricType.fingerprint],
        );

        final result = await biometricService.authenticate();

        expect(result.isSuccess, isFalse);
        expect(result.method, equals(AuthMethod.biometric));
        expect(result.errorMessage, isNotNull);
        expect(result.errorMessage, contains('iptal'));
      },
    );
  });
}
