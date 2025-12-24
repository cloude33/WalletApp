import 'dart:io';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart' as local_auth;
import 'package:local_auth/error_codes.dart' as auth_error;
// ignore: depend_on_referenced_packages
import 'package:local_auth_android/local_auth_android.dart';

import '../../models/security/security_models.dart' as app_biometric;
import '../../models/security/auth_result.dart';
import '../../models/security/auth_state.dart';

/// Platform-specific biyometrik kimlik doğrulama servisi
/// Android fingerprint/face unlock ve iOS Touch ID/Face ID entegrasyonu sağlar
abstract class PlatformBiometricService {
  /// Platform-specific biyometrik desteği kontrol eder
  Future<bool> isPlatformBiometricSupported();

  /// Platform-specific mevcut biyometrik türleri döndürür
  Future<List<app_biometric.BiometricType>> getPlatformAvailableBiometrics();

  /// Platform-specific biyometrik kimlik doğrulama yapar
  Future<AuthResult> authenticateWithPlatformBiometric({
    String? localizedFallbackTitle,
    String? cancelButtonText,
    bool biometricOnly = false,
  });

  /// Platform-specific biyometrik kayıt durumunu kontrol eder
  Future<bool> isPlatformBiometricEnrolled();

  /// Platform-specific cihaz güvenlik durumunu kontrol eder
  Future<bool> isPlatformDeviceSecure();

  /// Platform-specific biyometrik ayarlar sayfasını açar
  Future<bool> openPlatformBiometricSettings();

  /// Platform bilgilerini döndürür
  PlatformBiometricInfo getPlatformInfo();
}

/// Platform biyometrik bilgilerini içeren model
class PlatformBiometricInfo {
  final String platformName;
  final String platformVersion;
  final List<String> supportedBiometricTypes;
  final bool hasSecureHardware;
  final bool hasStrongBiometric;

  const PlatformBiometricInfo({
    required this.platformName,
    required this.platformVersion,
    required this.supportedBiometricTypes,
    required this.hasSecureHardware,
    required this.hasStrongBiometric,
  });

  Map<String, dynamic> toJson() {
    return {
      'platformName': platformName,
      'platformVersion': platformVersion,
      'supportedBiometricTypes': supportedBiometricTypes,
      'hasSecureHardware': hasSecureHardware,
      'hasStrongBiometric': hasStrongBiometric,
    };
  }
}

/// Android platform-specific biyometrik servis implementasyonu
class AndroidBiometricService implements PlatformBiometricService {
  final local_auth.LocalAuthentication _localAuth;
  static const MethodChannel _channel = MethodChannel(
    'biometric_service/android',
  );

  AndroidBiometricService({local_auth.LocalAuthentication? localAuth})
    : _localAuth = localAuth ?? local_auth.LocalAuthentication();

  @override
  Future<bool> isPlatformBiometricSupported() async {
    try {
      // Android API 23+ (Marshmallow) gerekli
      if (!Platform.isAndroid) return false;

      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;

      return isDeviceSupported && canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<app_biometric.BiometricType>>
  getPlatformAvailableBiometrics() async {
    try {
      final List<app_biometric.BiometricType> availableBiometrics = [];
      final List<local_auth.BiometricType> platformBiometrics = await _localAuth
          .getAvailableBiometrics();

      for (final BiometricType biometric in platformBiometrics) {
        switch (biometric) {
          case local_auth.BiometricType.fingerprint:
            availableBiometrics.add(app_biometric.BiometricType.fingerprint);
            break;
          case local_auth.BiometricType.face:
            availableBiometrics.add(app_biometric.BiometricType.face);
            break;
          case local_auth.BiometricType.iris:
            availableBiometrics.add(app_biometric.BiometricType.iris);
            break;
          case local_auth.BiometricType.weak:
            // Android weak biometric - genellikle pattern, PIN, password
            // Bu durumda fingerprint olarak map ediyoruz
            if (!availableBiometrics.contains(
              app_biometric.BiometricType.fingerprint,
            )) {
              availableBiometrics.add(app_biometric.BiometricType.fingerprint);
            }
            break;
          case local_auth.BiometricType.strong:
            // Android strong biometric - fingerprint, face, iris
            // Zaten yukarıda handle edildi, ek işlem gerekmiyor
            break;
        }
      }

      return availableBiometrics;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<AuthResult> authenticateWithPlatformBiometric({
    String? localizedFallbackTitle,
    String? cancelButtonText,
    bool biometricOnly = false,
  }) async {
    try {
      // Android-specific authentication options
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason:
            'Uygulamaya erişmek için parmak izinizi veya yüzünüzü taratın',
        options: local_auth.AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
          sensitiveTransaction: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        final availableBiometrics = await getPlatformAvailableBiometrics();
        return AuthResult.success(
          method: AuthMethod.biometric,
          metadata: {
            'platform': 'android',
            'timestamp': DateTime.now().toIso8601String(),
            'availableBiometrics': availableBiometrics
                .map((e) => e.toJson())
                .toList(),
            'biometricOnly': biometricOnly,
          },
        );
      } else {
        return AuthResult.failure(
          method: AuthMethod.biometric,
          errorMessage: 'Android biyometrik kimlik doğrulama başarısız',
        );
      }
    } on PlatformException catch (e) {
      return _handleAndroidPlatformException(e);
    } catch (e) {
      return AuthResult.failure(
        method: AuthMethod.biometric,
        errorMessage: 'Android biyometrik doğrulama hatası: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> isPlatformBiometricEnrolled() async {
    try {
      final availableBiometrics = await getPlatformAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isPlatformDeviceSecure() async {
    try {
      // Android cihazın güvenli olup olmadığını kontrol et
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;

      // Android-specific güvenlik kontrolü
      try {
        final bool hasSecureLockScreen =
            await _channel.invokeMethod('hasSecureLockScreen') ?? false;
        return isDeviceSupported && canCheckBiometrics && hasSecureLockScreen;
      } catch (e) {
        // Method channel hatası durumunda temel kontrol yap
        return isDeviceSupported && canCheckBiometrics;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> openPlatformBiometricSettings() async {
    try {
      // Android biyometrik ayarlar sayfasını aç
      final bool result =
          await _channel.invokeMethod('openBiometricSettings') ?? false;
      return result;
    } catch (e) {
      return false;
    }
  }

  @override
  PlatformBiometricInfo getPlatformInfo() {
    return const PlatformBiometricInfo(
      platformName: 'Android',
      platformVersion: 'API 23+',
      supportedBiometricTypes: ['fingerprint', 'face', 'iris'],
      hasSecureHardware: true,
      hasStrongBiometric: true,
    );
  }

  /// Android-specific platform exception handler
  AuthResult _handleAndroidPlatformException(PlatformException e) {
    String errorMessage;

    switch (e.code) {
      case auth_error.notAvailable:
        errorMessage = 'Android cihazında biyometrik doğrulama mevcut değil';
        break;
      case auth_error.notEnrolled:
        errorMessage =
            'Android cihazında kayıtlı parmak izi veya yüz verisi bulunamadı. Lütfen cihaz ayarlarından biyometrik doğrulamayı etkinleştirin';
        break;
      case auth_error.lockedOut:
        errorMessage =
            'Çok fazla başarısız deneme. Android biyometrik doğrulama geçici olarak kilitlendi';
        break;
      case auth_error.permanentlyLockedOut:
        errorMessage =
            'Android biyometrik doğrulama kalıcı olarak kilitlendi. Lütfen cihaz ayarlarını kontrol edin';
        break;
      case 'BiometricNotRecognized':
        errorMessage = 'Parmak izi veya yüz tanınmadı. Lütfen tekrar deneyin';
        break;
      case 'UserCancel':
        errorMessage = 'Kullanıcı Android biyometrik doğrulamayı iptal etti';
        break;
      case 'UserFallback':
        errorMessage = 'Kullanıcı PIN ile doğrulamayı seçti';
        break;
      case 'SystemCancel':
        errorMessage = 'Android sistemi biyometrik doğrulamayı iptal etti';
        break;
      default:
        errorMessage =
            'Android biyometrik doğrulama hatası: ${e.message ?? e.code}';
    }

    return AuthResult.failure(
      method: AuthMethod.biometric,
      errorMessage: errorMessage,
      metadata: {
        'platform': 'android',
        'platformErrorCode': e.code,
        'platformErrorMessage': e.message,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}

/// iOS platform-specific biyometrik servis implementasyonu
class IOSBiometricService implements PlatformBiometricService {
  final local_auth.LocalAuthentication _localAuth;
  static const MethodChannel _channel = MethodChannel('biometric_service/ios');

  IOSBiometricService({local_auth.LocalAuthentication? localAuth})
    : _localAuth = localAuth ?? local_auth.LocalAuthentication();

  @override
  Future<bool> isPlatformBiometricSupported() async {
    try {
      // iOS 11.0+ gerekli
      if (!Platform.isIOS) return false;

      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;

      return isDeviceSupported && canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<app_biometric.BiometricType>>
  getPlatformAvailableBiometrics() async {
    try {
      final List<app_biometric.BiometricType> availableBiometrics = [];
      final List<local_auth.BiometricType> platformBiometrics = await _localAuth
          .getAvailableBiometrics();

      for (final local_auth.BiometricType biometric in platformBiometrics) {
        switch (biometric) {
          case local_auth.BiometricType.fingerprint:
            // iOS Touch ID
            availableBiometrics.add(app_biometric.BiometricType.fingerprint);
            break;
          case local_auth.BiometricType.face:
            // iOS Face ID
            availableBiometrics.add(app_biometric.BiometricType.face);
            break;
          case local_auth.BiometricType.iris:
            // iOS iris (gelecekte desteklenebilir)
            availableBiometrics.add(app_biometric.BiometricType.iris);
            break;
          case local_auth.BiometricType.weak:
          case local_auth.BiometricType.strong:
            // iOS'ta bu kategoriler kullanılmaz
            break;
        }
      }

      return availableBiometrics;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<AuthResult> authenticateWithPlatformBiometric({
    String? localizedFallbackTitle,
    String? cancelButtonText,
    bool biometricOnly = false,
  }) async {
    try {
      // iOS-specific authentication options
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Touch ID veya Face ID ile uygulamaya giriş yapın',
        options: local_auth.AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
          sensitiveTransaction: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        final availableBiometrics = await getPlatformAvailableBiometrics();

        // iOS-specific biometric type detection
        String? detectedBiometricType;
        try {
          detectedBiometricType = await _channel.invokeMethod(
            'getActiveBiometricType',
          );
        } catch (e) {
          // Method channel hatası durumunda null bırak
        }

        return AuthResult.success(
          method: AuthMethod.biometric,
          metadata: {
            'platform': 'ios',
            'timestamp': DateTime.now().toIso8601String(),
            'availableBiometrics': availableBiometrics
                .map((e) => e.toJson())
                .toList(),
            'detectedBiometricType': detectedBiometricType,
            'biometricOnly': biometricOnly,
          },
        );
      } else {
        return AuthResult.failure(
          method: AuthMethod.biometric,
          errorMessage: 'iOS biyometrik kimlik doğrulama başarısız',
        );
      }
    } on PlatformException catch (e) {
      return _handleIOSPlatformException(e);
    } catch (e) {
      return AuthResult.failure(
        method: AuthMethod.biometric,
        errorMessage: 'iOS biyometrik doğrulama hatası: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> isPlatformBiometricEnrolled() async {
    try {
      final availableBiometrics = await getPlatformAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isPlatformDeviceSecure() async {
    try {
      // iOS cihazın güvenli olup olmadığını kontrol et
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;

      // iOS-specific güvenlik kontrolü
      try {
        final bool hasPasscodeSet =
            await _channel.invokeMethod('hasPasscodeSet') ?? false;
        return isDeviceSupported && canCheckBiometrics && hasPasscodeSet;
      } catch (e) {
        // Method channel hatası durumunda temel kontrol yap
        return isDeviceSupported && canCheckBiometrics;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> openPlatformBiometricSettings() async {
    try {
      // iOS ayarlar sayfasını aç (Touch ID & Passcode veya Face ID & Passcode)
      final bool result =
          await _channel.invokeMethod('openBiometricSettings') ?? false;
      return result;
    } catch (e) {
      return false;
    }
  }

  @override
  PlatformBiometricInfo getPlatformInfo() {
    return const PlatformBiometricInfo(
      platformName: 'iOS',
      platformVersion: '11.0+',
      supportedBiometricTypes: ['touchid', 'faceid'],
      hasSecureHardware: true,
      hasStrongBiometric: true,
    );
  }

  /// iOS-specific platform exception handler
  AuthResult _handleIOSPlatformException(PlatformException e) {
    String errorMessage;

    switch (e.code) {
      case auth_error.notAvailable:
        errorMessage = 'iOS cihazında Touch ID veya Face ID mevcut değil';
        break;
      case auth_error.notEnrolled:
        errorMessage =
            'iOS cihazında kayıtlı Touch ID veya Face ID bulunamadı. Lütfen cihaz ayarlarından biyometrik doğrulamayı etkinleştirin';
        break;
      case auth_error.lockedOut:
        errorMessage =
            'Çok fazla başarısız deneme. Touch ID/Face ID geçici olarak kilitlendi';
        break;
      case auth_error.permanentlyLockedOut:
        errorMessage =
            'Touch ID/Face ID kalıcı olarak kilitlendi. Lütfen cihaz ayarlarını kontrol edin';
        break;
      case 'BiometricNotRecognized':
        errorMessage = 'Touch ID veya Face ID tanınmadı. Lütfen tekrar deneyin';
        break;
      case 'UserCancel':
        errorMessage = 'Kullanıcı Touch ID/Face ID doğrulamayı iptal etti';
        break;
      case 'UserFallback':
        errorMessage = 'Kullanıcı passcode ile doğrulamayı seçti';
        break;
      case 'SystemCancel':
        errorMessage = 'iOS sistemi biyometrik doğrulamayı iptal etti';
        break;
      case 'TouchIDNotAvailable':
        errorMessage = 'Touch ID bu cihazda mevcut değil';
        break;
      case 'TouchIDNotEnrolled':
        errorMessage =
            'Touch ID kayıtlı değil. Lütfen cihaz ayarlarından Touch ID ekleyin';
        break;
      case 'TouchIDLockout':
        errorMessage =
            'Touch ID çok fazla başarısız deneme nedeniyle kilitlendi';
        break;
      case 'FaceIDNotAvailable':
        errorMessage = 'Face ID bu cihazda mevcut değil';
        break;
      case 'FaceIDNotEnrolled':
        errorMessage =
            'Face ID kayıtlı değil. Lütfen cihaz ayarlarından Face ID ekleyin';
        break;
      case 'FaceIDLockout':
        errorMessage =
            'Face ID çok fazla başarısız deneme nedeniyle kilitlendi';
        break;
      default:
        errorMessage =
            'iOS biyometrik doğrulama hatası: ${e.message ?? e.code}';
    }

    return AuthResult.failure(
      method: AuthMethod.biometric,
      errorMessage: errorMessage,
      metadata: {
        'platform': 'ios',
        'platformErrorCode': e.code,
        'platformErrorMessage': e.message,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}

/// Platform-specific biyometrik servis factory
class PlatformBiometricServiceFactory {
  /// Platform'a göre uygun servis instance'ı oluşturur
  static PlatformBiometricService create() {
    if (Platform.isAndroid) {
      return AndroidBiometricService();
    } else if (Platform.isIOS) {
      return IOSBiometricService();
    } else {
      throw UnsupportedError(
        'Platform biyometrik doğrulama bu platformda desteklenmiyor: ${Platform.operatingSystem}',
      );
    }
  }

  /// Test için custom servis instance'ı oluşturur
  static PlatformBiometricService createForTesting({
    required bool isAndroid,
    local_auth.LocalAuthentication? localAuth,
  }) {
    if (isAndroid) {
      return AndroidBiometricService(localAuth: localAuth);
    } else {
      return IOSBiometricService(localAuth: localAuth);
    }
  }
}

/// Platform-specific biyometrik servis singleton
class PlatformBiometricServiceSingleton {
  static PlatformBiometricService? _instance;

  /// Singleton instance'ı döndürür
  static PlatformBiometricService get instance {
    _instance ??= PlatformBiometricServiceFactory.create();
    return _instance!;
  }

  /// Test için instance'ı set eder
  static void setInstance(PlatformBiometricService service) {
    _instance = service;
  }

  /// Instance'ı temizler
  static void reset() {
    _instance = null;
  }
}
