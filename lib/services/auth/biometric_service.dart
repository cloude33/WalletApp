import 'dart:io';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart' as local_auth;
import '../../models/security/security_models.dart' as app_biometric;
import '../../models/security/auth_result.dart';
import '../../models/security/auth_state.dart';
import 'platform_biometric_service.dart';

/// Biyometrik kimlik doğrulama servisinin arayüzü
abstract class BiometricService {
  /// Cihazın biyometrik desteğini kontrol eder
  Future<bool> isBiometricAvailable();

  /// Mevcut biyometrik türleri döndürür
  Future<List<app_biometric.BiometricType>> getAvailableBiometrics();

  /// Biyometrik kimlik doğrulama yapar
  Future<AuthResult> authenticate({
    String? localizedFallbackTitle,
    String? cancelButtonText,
  });

  /// Biyometrik kayıt yapar
  Future<bool> enrollBiometric();

  /// Biyometrik doğrulamayı devre dışı bırakır
  Future<void> disableBiometric();

  /// Cihazın güvenli olup olmadığını kontrol eder
  Future<bool> isDeviceSecure();

  /// Biyometrik doğrulama durumunu kontrol eder
  Future<bool> canCheckBiometrics();
}

/// Biyometrik kimlik doğrulama servisinin implementasyonu
class BiometricServiceImpl implements BiometricService {
  final local_auth.LocalAuthentication _localAuth;
  final PlatformBiometricService? _platformService;

  // Performance optimization: Cache biometric availability
  bool? _cachedAvailability;
  List<app_biometric.BiometricType>? _cachedBiometrics;
  DateTime? _cacheTimestamp;
  static const Duration _cacheExpiry = Duration(minutes: 1);

  /// Constructor
  BiometricServiceImpl({
    local_auth.LocalAuthentication? localAuth,
    PlatformBiometricService? platformService,
  }) : _localAuth = localAuth ?? local_auth.LocalAuthentication(),
       _platformService = platformService ?? _createPlatformService();

  @override
  Future<bool> isBiometricAvailable() async {
    try {
      // Performance optimization: Use cached value if available and not expired
      if (_cachedAvailability != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheExpiry) {
          return _cachedAvailability!;
        }
      }

      // Platform-specific biyometrik desteği kontrol et
      bool isAvailable;
      if ((Platform.isAndroid || Platform.isIOS) && _platformService != null) {
        isAvailable = await _platformService!.isPlatformBiometricSupported();
      } else {
        // Fallback: Genel biyometrik desteği kontrol et
        final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
        if (!canCheckBiometrics) {
          isAvailable = false;
        } else {
          // Mevcut biyometrik türleri al
          final List<app_biometric.BiometricType> availableBiometrics =
              await getAvailableBiometrics();

          // En az bir biyometrik tür mevcut olmalı
          isAvailable = availableBiometrics.isNotEmpty;
        }
      }

      // Cache the result
      _cachedAvailability = isAvailable;
      _cacheTimestamp = DateTime.now();

      return isAvailable;
    } catch (e) {
      // Hata durumunda false döndür
      return false;
    }
  }

  @override
  Future<List<app_biometric.BiometricType>> getAvailableBiometrics() async {
    try {
      // Performance optimization: Use cached value if available and not expired
      if (_cachedBiometrics != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheExpiry) {
          return _cachedBiometrics!;
        }
      }

      List<app_biometric.BiometricType> availableBiometrics;

      // Platform-specific biyometrik türleri al
      if ((Platform.isAndroid || Platform.isIOS) && _platformService != null) {
        availableBiometrics = await _platformService!
            .getPlatformAvailableBiometrics();
      } else {
        // Fallback: Platform biyometrik türlerini al
        availableBiometrics = <app_biometric.BiometricType>[];
        final List<local_auth.BiometricType> platformBiometrics =
            await _localAuth.getAvailableBiometrics();

        // Platform türlerini kendi enum'umuza çevir
        for (final local_auth.BiometricType biometric in platformBiometrics) {
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
            case local_auth.BiometricType.strong:
              // Android specific types - map to fingerprint as default
              if (!availableBiometrics.contains(
                app_biometric.BiometricType.fingerprint,
              )) {
                availableBiometrics.add(
                  app_biometric.BiometricType.fingerprint,
                );
              }
              break;
          }
        }
      }

      // Cache the result
      _cachedBiometrics = availableBiometrics;
      _cacheTimestamp = DateTime.now();

      return availableBiometrics;
    } catch (e) {
      // Hata durumunda boş liste döndür
      return <app_biometric.BiometricType>[];
    }
  }

  @override
  Future<AuthResult> authenticate({
    String? localizedFallbackTitle,
    String? cancelButtonText,
  }) async {
    try {
      // Önce biyometrik desteği kontrol et
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return AuthResult.failure(
          method: AuthMethod.biometric,
          errorMessage: 'Biyometrik kimlik doğrulama bu cihazda desteklenmiyor',
        );
      }

      // Platform-specific biyometrik kimlik doğrulama
      if ((Platform.isAndroid || Platform.isIOS) && _platformService != null) {
        return await _platformService!.authenticateWithPlatformBiometric(
          localizedFallbackTitle: localizedFallbackTitle,
          cancelButtonText: cancelButtonText,
          biometricOnly: false,
        );
      }

      // Fallback: Genel biyometrik kimlik doğrulama
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Uygulamaya erişmek için kimliğinizi doğrulayın',
        biometricOnly: false,
      );

      if (didAuthenticate) {
        return AuthResult.success(
          method: AuthMethod.biometric,
          metadata: {
            'timestamp': DateTime.now().toIso8601String(),
            'availableBiometrics': (await getAvailableBiometrics())
                .map((e) => e.toJson())
                .toList(),
          },
        );
      } else {
        return AuthResult.failure(
          method: AuthMethod.biometric,
          errorMessage: 'Biyometrik kimlik doğrulama başarısız',
        );
      }
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    } catch (e) {
      return AuthResult.failure(
        method: AuthMethod.biometric,
        errorMessage: 'Beklenmeyen hata: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> enrollBiometric() async {
    try {
      // Platform-specific biyometrik kayıt
      if ((Platform.isAndroid || Platform.isIOS) && _platformService != null) {
        // Platform-specific ayarlar sayfasını aç
        final bool settingsOpened = await _platformService!
            .openPlatformBiometricSettings();
        if (settingsOpened) {
          // Ayarlar açıldıysa, kullanıcının kayıt yapmasını bekle
          // Gerçek implementasyonda bu async bir process olabilir
          return true;
        }

        // Ayarlar açılamazsa, mevcut kayıtları kontrol et
        return await _platformService!.isPlatformBiometricEnrolled();
      }

      // Fallback: Genel biyometrik kayıt kontrolü
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        return false;
      }

      // Mevcut biyometrik türleri kontrol et
      final List<app_biometric.BiometricType> availableBiometrics =
          await getAvailableBiometrics();

      // Biyometrik türler mevcutsa, kayıt başarılı kabul et
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> disableBiometric() async {
    try {
      // Biyometrik doğrulamayı devre dışı bırakma işlemi
      // Bu genellikle uygulama seviyesinde yapılır, cihaz seviyesinde değil
      // Gerçek implementasyonda secure storage'dan biyometrik ayarları silinir
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  @override
  Future<bool> isDeviceSecure() async {
    try {
      // Platform-specific cihaz güvenlik kontrolü
      if ((Platform.isAndroid || Platform.isIOS) && _platformService != null) {
        return await _platformService!.isPlatformDeviceSecure();
      }

      // Fallback: Genel cihaz güvenlik kontrolü
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;

      return isDeviceSupported && canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Platform servis oluşturur, test ortamında hata durumunda null döndürür
  static PlatformBiometricService? _createPlatformService() {
    try {
      return PlatformBiometricServiceSingleton.instance;
    } catch (e) {
      // Test ortamında veya desteklenmeyen platformlarda null döndür
      return null;
    }
  }

  /// Platform exception'larını handle eder
  AuthResult _handlePlatformException(PlatformException e) {
    String errorMessage;

    switch (e.code) {
      case 'NotAvailable':
        errorMessage = 'Biyometrik kimlik doğrulama bu cihazda mevcut değil';
        break;
      case 'NotEnrolled':
        errorMessage =
            'Cihazda kayıtlı biyometrik veri bulunamadı. Lütfen cihaz ayarlarından biyometrik doğrulamayı etkinleştirin';
        break;
      case 'LockedOut':
        errorMessage =
            'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin';
        break;
      case 'PermanentlyLockedOut':
        errorMessage =
            'Biyometrik doğrulama kalıcı olarak kilitlendi. Lütfen cihaz ayarlarını kontrol edin';
        break;
      case 'BiometricOnlyNotSupported':
        errorMessage =
            'Sadece biyometrik doğrulama desteklenmiyor. PIN ile doğrulama gerekli';
        break;
      case 'UserCancel':
        errorMessage = 'Kullanıcı kimlik doğrulamayı iptal etti';
        break;
      case 'UserFallback':
        errorMessage = 'Kullanıcı PIN ile doğrulamayı seçti';
        break;
      case 'SystemCancel':
        errorMessage = 'Sistem kimlik doğrulamayı iptal etti';
        break;
      case 'InvalidContext':
        errorMessage = 'Geçersiz kimlik doğrulama bağlamı';
        break;
      case 'BiometricNotRecognized':
        errorMessage = 'Biyometrik veri tanınmadı. Lütfen tekrar deneyin';
        break;
      default:
        errorMessage =
            'Biyometrik kimlik doğrulama hatası: ${e.message ?? e.code}';
    }

    return AuthResult.failure(
      method: AuthMethod.biometric,
      errorMessage: errorMessage,
      metadata: {
        'platformErrorCode': e.code,
        'platformErrorMessage': e.message,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}

/// Biyometrik servis için singleton instance
class BiometricServiceSingleton {
  static BiometricService? _instance;

  /// Singleton instance'ı döndürür
  static BiometricService get instance {
    _instance ??= BiometricServiceImpl();
    return _instance!;
  }

  /// Test için instance'ı set eder
  static void setInstance(BiometricService service) {
    _instance = service;
  }

  /// Instance'ı temizler
  static void reset() {
    _instance = null;
  }
}
