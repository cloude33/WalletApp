import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/security/security_models.dart';
import 'secure_storage_service.dart';

/// PIN kodu yönetim servisi
///
/// Bu servis PIN kodu oluşturma, doğrulama, değiştirme ve güvenlik
/// kontrollerini yönetir. Deneme sayacı ve kilitleme mekanizmaları
/// ile güvenliği sağlar.
///
/// Özellikler:
/// - PIN oluşturma ve doğrulama
/// - Deneme sayacı yönetimi
/// - Otomatik kilitleme mekanizması
/// - Güvenli PIN depolama
/// - PIN değiştirme ve sıfırlama
class PINService {
  static final PINService _instance = PINService._internal();
  factory PINService() => _instance;
  PINService._internal();

  final AuthSecureStorageService _storage = AuthSecureStorageService();

  // Kilitleme süreleri (saniye cinsinden)
  static const int _firstLockoutDuration = 30; // 30 saniye
  static const int _secondLockoutDuration = 300; // 5 dakika
  static const int _maxLockoutDuration = 1800; // 30 dakika

  // Deneme sayısı eşikleri
  static const int _firstLockoutThreshold = 3;
  static const int _secondLockoutThreshold = 5;
  static const int _maxAttempts = 10;

  bool _isInitialized = false;

  // Performance optimization: Cache frequently accessed values
  int? _cachedFailedAttempts;
  DateTime? _cachedLockoutTime;
  bool? _cachedPINSet;
  DateTime? _cacheTimestamp;

  /// Servisi başlatır
  ///
  /// Bu metod servisin kullanılmadan önce çağrılmalıdır.
  /// Güvenli depolama servisini başlatır.
  ///
  /// Throws [Exception] başlatma başarısız olursa
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _storage.initialize();
      _isInitialized = true;
      debugPrint('PIN Service initialized successfully');
    } catch (e) {
      throw Exception('Failed to initialize PIN service: ${e.toString()}');
    }
  }

  /// PIN kodu oluşturur ve güvenli bir şekilde depolar
  ///
  /// [pin] - Oluşturulacak PIN kodu (4-6 haneli)
  ///
  /// Returns [AuthResult] işlem sonucunu içeren nesne
  ///
  /// Implements Requirement 1.1: 4-6 haneli sayısal PIN girişi kabul etmeli
  /// Implements Requirement 1.2: PIN'i AES-256 şifreleme ile depolamalı
  Future<AuthResult> setupPIN(String pin) async {
    try {
      // PIN formatını validate et (storage'dan önce)
      final validationError = _validatePINFormat(pin);
      if (validationError != null) {
        return AuthResult.failure(
          method: AuthMethod.pin,
          errorMessage: validationError,
        );
      }

      await _ensureInitialized();

      // Mevcut PIN varsa hata döndür
      if (await isPINSet()) {
        return AuthResult.failure(
          method: AuthMethod.pin,
          errorMessage:
              'PIN zaten ayarlanmış. Değiştirmek için changePIN kullanın.',
        );
      }

      // PIN'i güvenli bir şekilde depola
      final success = await _storage.storePIN(pin);
      if (!success) {
        return AuthResult.failure(
          method: AuthMethod.pin,
          errorMessage: 'PIN depolama başarısız oldu',
        );
      }

      // Deneme sayacını sıfırla
      await _storage.storeFailedAttempts(0);
      await _storage.clearLockout();

      // Invalidate cache after state change
      _invalidateCache();

      debugPrint('PIN setup completed successfully');
      return AuthResult.success(
        method: AuthMethod.pin,
        metadata: {'action': 'setup'},
      );
    } catch (e) {
      debugPrint('PIN setup failed: $e');
      return AuthResult.failure(
        method: AuthMethod.pin,
        errorMessage: 'PIN kurulumu sırasında hata oluştu: ${e.toString()}',
      );
    }
  }

  /// PIN kodunu doğrular
  ///
  /// [pin] - Doğrulanacak PIN kodu
  ///
  /// Returns [AuthResult] doğrulama sonucunu içeren nesne
  ///
  /// Implements Requirement 1.3: Şifrelenmiş PIN ile karşılaştırma yapmalı
  /// Implements Requirement 1.4: PIN başarıyla doğrulandığında kullanıcı oturumu başlatmalı
  /// Implements Requirement 1.5: Yanlış PIN girişinde deneme sayacını artırmalı
  /// Implements Requirement 2.1: 3 yanlış PIN girişinde hesabı geçici olarak kilitlemeli
  /// Implements Requirement 2.2: Hesap kilitlendiğinde 30 saniye bekleme süresi uygulamalı
  /// Implements Requirement 2.3: 5 yanlış PIN girişinde hesabı 5 dakika kilitlemeli
  /// Implements Requirement 2.4: Kilitleme süresi dolduğunda deneme sayacını sıfırlamalı
  Future<AuthResult> verifyPIN(String pin) async {
    try {
      // PIN formatını validate et (storage'dan önce)
      final validationError = _validatePINFormat(pin);
      if (validationError != null) {
        return AuthResult.failure(
          method: AuthMethod.pin,
          errorMessage: validationError,
        );
      }

      await _ensureInitialized();

      // PIN ayarlanmış mı kontrol et
      if (!await isPINSet()) {
        return AuthResult.failure(
          method: AuthMethod.pin,
          errorMessage: 'PIN ayarlanmamış',
        );
      }

      // Kilitleme durumunu kontrol et
      final lockoutResult = await _checkLockoutStatus();
      if (!lockoutResult.isSuccess) {
        return lockoutResult;
      }

      // PIN'i doğrula
      final isValid = await _storage.verifyPIN(pin);

      if (isValid) {
        // Başarılı doğrulama - sayaçları sıfırla
        await _storage.storeFailedAttempts(0);
        await _storage.clearLockout();

        // Invalidate cache after state change
        _invalidateCache();

        debugPrint('PIN verification successful');
        return AuthResult.success(
          method: AuthMethod.pin,
          metadata: {'action': 'verify'},
        );
      } else {
        // Başarısız doğrulama - deneme sayacını artır
        _invalidateCache(); // Invalidate before handling failed attempt
        return await _handleFailedAttempt();
      }
    } catch (e) {
      debugPrint('PIN verification failed: $e');
      return AuthResult.failure(
        method: AuthMethod.pin,
        errorMessage: 'PIN doğrulama sırasında hata oluştu: ${e.toString()}',
      );
    }
  }

  /// PIN kodunu değiştirir
  ///
  /// [oldPin] - Mevcut PIN kodu
  /// [newPin] - Yeni PIN kodu
  ///
  /// Returns [AuthResult] işlem sonucunu içeren nesne
  ///
  /// Implements Requirement 7.2: PIN değiştirme seçildiğinde mevcut PIN doğrulaması gerektirmeli
  Future<AuthResult> changePIN(String oldPin, String newPin) async {
    try {
      // Yeni PIN formatını validate et (storage'dan önce)
      final validationError = _validatePINFormat(newPin);
      if (validationError != null) {
        return AuthResult.failure(
          method: AuthMethod.pin,
          errorMessage: 'Yeni PIN geçersiz: $validationError',
        );
      }

      // Aynı PIN kontrolü (storage'dan önce)
      if (oldPin == newPin) {
        return AuthResult.failure(
          method: AuthMethod.pin,
          errorMessage: 'Yeni PIN mevcut PIN ile aynı olamaz',
        );
      }

      await _ensureInitialized();

      // Eski PIN'i doğrula
      final oldPinResult = await verifyPIN(oldPin);
      if (!oldPinResult.isSuccess) {
        return AuthResult.failure(
          method: AuthMethod.pin,
          errorMessage: 'Mevcut PIN yanlış: ${oldPinResult.errorMessage}',
        );
      }

      // Yeni PIN'i depola
      final success = await _storage.storePIN(newPin);
      if (!success) {
        return AuthResult.failure(
          method: AuthMethod.pin,
          errorMessage: 'Yeni PIN depolama başarısız oldu',
        );
      }

      // Sayaçları sıfırla
      await _storage.storeFailedAttempts(0);
      await _storage.clearLockout();

      // Invalidate cache after state change
      _invalidateCache();

      debugPrint('PIN change completed successfully');
      return AuthResult.success(
        method: AuthMethod.pin,
        metadata: {'action': 'change'},
      );
    } catch (e) {
      debugPrint('PIN change failed: $e');
      return AuthResult.failure(
        method: AuthMethod.pin,
        errorMessage: 'PIN değiştirme sırasında hata oluştu: ${e.toString()}',
      );
    }
  }

  /// PIN kodunu sıfırlar (güvenlik soruları ile)
  ///
  /// Bu metod güvenlik soruları doğrulandıktan sonra çağrılmalıdır.
  ///
  /// Returns [AuthResult] işlem sonucunu içeren nesne
  ///
  /// Implements Requirement 3.3: Yeni PIN oluşturulduğunda eski PIN'i silip yenisini depolamalı
  /// Implements Requirement 3.4: PIN sıfırlama işlemi tamamlandığında tüm aktif oturumları sonlandırmalı
  Future<AuthResult> resetPIN() async {
    try {
      await _ensureInitialized();

      // Mevcut PIN'i sil
      await _storage.removePIN();

      // Tüm sayaçları sıfırla
      await _storage.storeFailedAttempts(0);
      await _storage.clearLockout();

      // Invalidate cache after state change
      _invalidateCache();

      debugPrint('PIN reset completed successfully');
      return AuthResult.success(
        method: AuthMethod.pin,
        metadata: {'action': 'reset'},
      );
    } catch (e) {
      debugPrint('PIN reset failed: $e');
      return AuthResult.failure(
        method: AuthMethod.pin,
        errorMessage: 'PIN sıfırlama sırasında hata oluştu: ${e.toString()}',
      );
    }
  }

  /// Başarısız deneme sayısını döndürür
  ///
  /// Returns başarısız deneme sayısı
  ///
  /// Performance optimization: Uses cached value if available and recent
  Future<int> getFailedAttempts() async {
    try {
      await _ensureInitialized();

      // Use cache if available and recent (within 1 second)
      if (_cachedFailedAttempts != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge.inSeconds < 1) {
          return _cachedFailedAttempts!;
        }
      }

      final attempts = await _storage.getFailedAttempts();
      _cachedFailedAttempts = attempts;
      _cacheTimestamp = DateTime.now();
      return attempts;
    } catch (e) {
      debugPrint('Failed to get failed attempts: $e');
      return 0;
    }
  }

  /// Hesabın kilitli olup olmadığını kontrol eder
  ///
  /// Returns hesap kilitli ise true, değilse false
  ///
  /// Performance optimization: Uses cached value if available and recent
  Future<bool> isLocked() async {
    try {
      await _ensureInitialized();

      // Use cache if available and recent (within 1 second)
      if (_cachedLockoutTime != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge.inSeconds < 1) {
          return DateTime.now().isBefore(_cachedLockoutTime!);
        }
      }

      final lockoutTime = await _storage.getLockoutTime();
      _cachedLockoutTime = lockoutTime;
      _cacheTimestamp = DateTime.now();

      if (lockoutTime == null) return false;
      return DateTime.now().isBefore(lockoutTime);
    } catch (e) {
      debugPrint('Failed to check lock status: $e');
      return false;
    }
  }

  /// Kalan kilitleme süresini döndürür
  ///
  /// Returns kalan süre, kilitli değilse null
  Future<Duration?> getRemainingLockoutTime() async {
    try {
      await _ensureInitialized();
      final lockoutTime = await _storage.getLockoutTime();
      if (lockoutTime == null) return null;

      final now = DateTime.now();
      if (now.isBefore(lockoutTime)) {
        return lockoutTime.difference(now);
      }

      return null;
    } catch (e) {
      debugPrint('Failed to get remaining lockout time: $e');
      return null;
    }
  }

  /// PIN ayarlanmış mı kontrol eder
  ///
  /// Returns PIN ayarlanmışsa true, değilse false
  ///
  /// Performance optimization: Uses cached value if available and recent
  Future<bool> isPINSet() async {
    try {
      await _ensureInitialized();

      // Use cache if available and recent (within 5 seconds)
      if (_cachedPINSet != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge.inSeconds < 5) {
          return _cachedPINSet!;
        }
      }

      final isSet = await _storage.isPINSet();
      _cachedPINSet = isSet;
      _cacheTimestamp = DateTime.now();
      return isSet;
    } catch (e) {
      debugPrint('Failed to check PIN status: $e');
      return false;
    }
  }

  /// PIN güçlülüğünü kontrol eder
  ///
  /// [pin] - Kontrol edilecek PIN
  ///
  /// Returns güçlülük skoru (0-100)
  int checkPINStrength(String pin) {
    if (pin.isEmpty) return 0;

    int score = 0;

    // Uzunluk kontrolü
    if (pin.length >= 4) score += 20;
    if (pin.length >= 6) score += 20;

    // Tekrar eden rakam kontrolü
    final uniqueDigits = pin.split('').toSet().length;
    if (uniqueDigits > 2) score += 20;
    if (uniqueDigits > 3) score += 20;

    // Sıralı rakam kontrolü
    if (!_hasSequentialDigits(pin)) score += 20;

    return score;
  }

  /// Tüm PIN verilerini temizler
  ///
  /// Returns temizleme başarılı ise true
  Future<bool> clearAllPINData() async {
    try {
      await _ensureInitialized();

      await _storage.removePIN();
      await _storage.storeFailedAttempts(0);
      await _storage.clearLockout();

      // Invalidate cache after clearing data
      _invalidateCache();

      debugPrint('All PIN data cleared successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to clear PIN data: $e');
      return false;
    }
  }

  /// Invalidates the cache to force fresh reads from storage
  void _invalidateCache() {
    _cachedFailedAttempts = null;
    _cachedLockoutTime = null;
    _cachedPINSet = null;
    _cacheTimestamp = null;
  }

  // Private helper methods

  /// Servisin başlatıldığından emin olur
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// PIN formatını validate eder
  ///
  /// [pin] - Validate edilecek PIN
  ///
  /// Returns hata mesajı, geçerli ise null
  String? _validatePINFormat(String pin) {
    if (pin.isEmpty) {
      return 'PIN boş olamaz';
    }

    if (pin.length < 4) {
      return 'PIN en az 4 haneli olmalı';
    }

    if (pin.length > 6) {
      return 'PIN en fazla 6 haneli olmalı';
    }

    // Sadece rakam kontrolü
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      return 'PIN sadece rakamlardan oluşmalı';
    }

    return null;
  }

  /// Kilitleme durumunu kontrol eder
  ///
  /// Returns kilitleme durumu sonucu
  Future<AuthResult> _checkLockoutStatus() async {
    final lockoutTime = await _storage.getLockoutTime();
    if (lockoutTime == null) return AuthResult.success(method: AuthMethod.pin);

    final now = DateTime.now();
    if (now.isBefore(lockoutTime)) {
      final remainingTime = lockoutTime.difference(now);
      return AuthResult.failure(
        method: AuthMethod.pin,
        errorMessage: 'Hesap kilitli',
        lockoutDuration: remainingTime,
      );
    } else {
      // Kilitleme süresi dolmuş, sayaçları sıfırla
      await _storage.storeFailedAttempts(0);
      await _storage.clearLockout();
      return AuthResult.success(method: AuthMethod.pin);
    }
  }

  /// Başarısız deneme durumunu işler
  ///
  /// Returns işlem sonucu
  Future<AuthResult> _handleFailedAttempt() async {
    final currentAttempts = await _storage.getFailedAttempts();
    final newAttempts = currentAttempts + 1;

    await _storage.storeFailedAttempts(newAttempts);

    // Kilitleme kontrolü
    Duration? lockoutDuration;
    DateTime? lockoutTime;

    if (newAttempts >= _maxAttempts) {
      // Maksimum deneme aşıldı - uzun süreli kilitleme
      lockoutDuration = const Duration(seconds: _maxLockoutDuration);
      lockoutTime = DateTime.now().add(lockoutDuration);
      await _storage.storeLockoutTime(lockoutTime);

      debugPrint('Account locked for maximum attempts: $newAttempts');
      return AuthResult.failure(
        method: AuthMethod.pin,
        errorMessage:
            'Maksimum deneme sayısı aşıldı. Hesap 30 dakika kilitlendi.',
        lockoutDuration: lockoutDuration,
        remainingAttempts: 0,
      );
    } else if (newAttempts >= _secondLockoutThreshold) {
      // İkinci eşik - 5 dakika kilitleme
      lockoutDuration = const Duration(seconds: _secondLockoutDuration);
      lockoutTime = DateTime.now().add(lockoutDuration);
      await _storage.storeLockoutTime(lockoutTime);

      debugPrint('Account locked for second threshold: $newAttempts');
      return AuthResult.failure(
        method: AuthMethod.pin,
        errorMessage: 'Çok fazla yanlış deneme. Hesap 5 dakika kilitlendi.',
        lockoutDuration: lockoutDuration,
        remainingAttempts: _maxAttempts - newAttempts,
      );
    } else if (newAttempts >= _firstLockoutThreshold) {
      // İlk eşik - 30 saniye kilitleme
      lockoutDuration = const Duration(seconds: _firstLockoutDuration);
      lockoutTime = DateTime.now().add(lockoutDuration);
      await _storage.storeLockoutTime(lockoutTime);

      debugPrint('Account locked for first threshold: $newAttempts');
      return AuthResult.failure(
        method: AuthMethod.pin,
        errorMessage: 'Yanlış PIN. Hesap 30 saniye kilitlendi.',
        lockoutDuration: lockoutDuration,
        remainingAttempts: _maxAttempts - newAttempts,
      );
    } else {
      // Henüz kilitleme yok
      debugPrint('Failed PIN attempt: $newAttempts');
      return AuthResult.failure(
        method: AuthMethod.pin,
        errorMessage: 'Yanlış PIN',
        remainingAttempts: _maxAttempts - newAttempts,
      );
    }
  }

  /// Sıralı rakamları kontrol eder
  ///
  /// [pin] - Kontrol edilecek PIN
  ///
  /// Returns sıralı rakam varsa true
  bool _hasSequentialDigits(String pin) {
    for (int i = 0; i < pin.length - 2; i++) {
      final digit1 = int.tryParse(pin[i]) ?? -1;
      final digit2 = int.tryParse(pin[i + 1]) ?? -1;
      final digit3 = int.tryParse(pin[i + 2]) ?? -1;

      if (digit1 != -1 && digit2 != -1 && digit3 != -1) {
        // Artan sıra kontrolü
        if (digit2 == digit1 + 1 && digit3 == digit2 + 1) {
          return true;
        }
        // Azalan sıra kontrolü
        if (digit2 == digit1 - 1 && digit3 == digit2 - 1) {
          return true;
        }
      }
    }
    return false;
  }

  /// Test amaçlı servisi sıfırlar
  ///
  /// Bu metod sadece test amaçlı kullanılmalıdır
  @visibleForTesting
  void resetForTesting() {
    _isInitialized = false;
    _cachedFailedAttempts = null;
    _cachedLockoutTime = null;
    _cachedPINSet = null;
    _cacheTimestamp = null;
    // ignore: invalid_use_of_visible_for_testing_member
    _storage.resetForTesting();
  }
}
