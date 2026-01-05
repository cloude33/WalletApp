import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/security/security_models.dart';
import 'secure_storage_service.dart';
import 'biometric_service.dart';
import 'session_manager.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final AuthSecureStorageService _storage = AuthSecureStorageService();
  final BiometricService _biometricService = BiometricServiceImpl();
  final SessionManager _sessionManager = SessionManager();

  // Oturum yönetimi için stream controller
  final StreamController<AuthState> _authStateController =
      StreamController<AuthState>.broadcast();

  // Mevcut kimlik doğrulama durumu
  AuthState _currentAuthState = AuthState.unauthenticated();

  // Oturum verileri
  SessionData? _currentSession;

  // Timer'lar
  Timer? _sessionTimeoutTimer;
  Timer? _backgroundLockTimer;
  DateTime? _backgroundTimestamp;

  bool _isInitialized = false;

  /// Kimlik doğrulama durumu stream'i
  Stream<AuthState> get authStateStream => _authStateController.stream;

  /// Mevcut kimlik doğrulama durumu
  AuthState get currentAuthState => _currentAuthState;

  /// Mevcut oturum verisi
  SessionData? get currentSession => _currentSession;

  /// Servisi başlatır
  ///
  /// Bu metod servisin kullanılmadan önce çağrılmalıdır.
  /// Tüm alt servisleri başlatır ve mevcut oturum durumunu yükler.
  ///
  /// Throws [Exception] başlatma başarısız olursa
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Alt servisleri başlat
      await _storage.initialize();
      await _sessionManager.initialize();

      // Mevcut oturum durumunu yükle
      await _loadStoredAuthState();

      _isInitialized = true;
      debugPrint('Auth Service initialized successfully');
    } catch (e) {
      throw Exception('Failed to initialize Auth service: ${e.toString()}');
    }
  }

  /// Biyometrik kimlik doğrulama yapar
  ///
  /// [localizedFallbackTitle] - Fallback PIN için başlık
  /// [cancelButtonText] - İptal butonu metni
  ///
  /// Returns [AuthResult] doğrulama sonucunu içeren nesne
  ///
  /// Implements Requirement 4.4: Biyometrik doğrulama başarılı olduğunda kullanıcı oturumu başlatmalı
  Future<AuthResult> authenticateWithBiometric({
    String? localizedFallbackTitle,
    String? cancelButtonText,
  }) async {
    try {
      await _ensureInitialized();

      // Biyometrik doğrulaması yap
      final result = await _biometricService.authenticate(
        localizedFallbackTitle: localizedFallbackTitle,
        cancelButtonText: cancelButtonText,
      );

      // Başarılı doğrulama durumunda oturum başlat
      if (result.isSuccess) {
        await _startSession(
          AuthMethod.biometric,
          result.metadata,
        );
        debugPrint('Biometric authentication successful, session started');
      }

      return result;
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      return AuthResult.failure(
        method: AuthMethod.biometric,
        errorMessage:
            'Biyometrik doğrulama sırasında hata oluştu: ${e.toString()}',
      );
    }
  }

  /// Mevcut kimlik doğrulama durumunu kontrol eder
  ///
  /// Returns kullanıcı kimlik doğrulaması yapılmışsa true
  ///
  /// Implements Requirement 6.3: Uygulama tekrar açıldığında kimlik doğrulama gerektirmeli
  Future<bool> isAuthenticated() async {
    try {
      await _ensureInitialized();

      // Oturum süresi kontrolü
      if (_currentAuthState.isAuthenticated && _currentSession != null) {
        final config = await _getSecurityConfig();

        if (_currentSession!.isExpired(config.sessionTimeout)) {
          // Oturum süresi dolmuş - oturumu sonlandır
          await logout();
          return false;
        }

        // Aktivite zamanını güncelle
        await _updateActivity();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Authentication check error: $e');
      return false;
    }
  }

  /// Hassas işlem için kimlik doğrulama gerekli mi kontrol eder
  ///
  /// Returns hassas işlem için yeniden doğrulama gerekiyorsa true
  ///
  /// Implements Requirement 8.1: Para transferi yapıldığında ek kimlik doğrulama gerektirmeli
  /// Implements Requirement 8.2: Güvenlik ayarları değiştirildiğinde PIN ve biyometrik doğrulama gerektirmeli
  /// Implements Requirement 8.4: Hesap bilgileri görüntülendiğinde son 5 dakika içinde doğrulama gerektirmeli
  Future<bool> requiresSensitiveAuth() async {
    try {
      await _ensureInitialized();

      if (!await isAuthenticated()) {
        return true;
      }

      if (_currentSession == null) {
        return true;
      }

      final config = await _getSecurityConfig();
      return _currentSession!.requiresSensitiveAuth(
        config.sessionConfig.sensitiveOperationTimeout,
      );
    } catch (e) {
      debugPrint('Sensitive auth check error: $e');
      return true;
    }
  }

  /// Hassas işlem için kimlik doğrulama yapar
  ///
  /// [method] - Kullanılacak doğrulama yöntemi
  /// [pin] - PIN kodu (PIN yöntemi seçilmişse)
  ///
  /// Returns [AuthResult] doğrulama sonucunu içeren nesne
  Future<AuthResult> authenticateForSensitiveOperation({
    AuthMethod method = AuthMethod.biometric,
    String? pin,
  }) async {
    try {
      await _ensureInitialized();

      AuthResult result;

      switch (method) {
        case AuthMethod.biometric:
          result = await _biometricService.authenticate(
            localizedFallbackTitle: 'PIN ile devam et',
            cancelButtonText: 'İptal',
          );
          break;

        default:
          result = AuthResult.failure(
            method: method,
            errorMessage: 'Desteklenmeyen doğrulama yöntemi',
          );
          break;
      }

      if (result.isSuccess && _currentSession != null) {
        // Hassas işlem doğrulama zamanını güncelle
        _currentSession = _currentSession!.updateSensitiveAuth();
        _currentAuthState = _currentAuthState.updateSensitiveAuth();

        // Durumu kaydet ve bildir
        await _saveAuthState();
        _authStateController.add(_currentAuthState);

        debugPrint('Sensitive operation authentication successful');
      }

      return result;
    } catch (e) {
      debugPrint('Sensitive operation authentication error: $e');
      return AuthResult.failure(
        method: method,
        errorMessage:
            'Hassas işlem doğrulaması sırasında hata oluştu: ${e.toString()}',
      );
    }
  }

  /// Oturumu sonlandırır
  ///
  /// Tüm oturum verilerini temizler ve kimlik doğrulama durumunu sıfırlar.
  Future<void> logout() async {
    try {
      await _ensureInitialized();

      // Timer'ları iptal et
      _sessionTimeoutTimer?.cancel();
      _backgroundLockTimer?.cancel();

      // Oturum verilerini temizle
      _currentSession = null;
      _currentAuthState = AuthState.unauthenticated();
      _backgroundTimestamp = null;

      // Depolanan durumu temizle
      await _clearStoredAuthState();
      await _storage.clearBackgroundTimestamp();

      // Durumu bildir
      _authStateController.add(_currentAuthState);

      debugPrint('User logged out successfully');
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  /// Kullanıcı aktivitesini kaydeder
  ///
  /// Oturum timer'ını yeniler ve son aktivite zamanını günceller.
  Future<void> recordActivity() async {
    try {
      await _ensureInitialized();

      if (!_currentAuthState.isAuthenticated || _currentSession == null) return;

      // SessionManager'a aktivite bildir
      await _sessionManager.recordActivity();

      // Son aktivite zamanını güncelle
      _currentSession = _currentSession!.updateActivity();
      _currentAuthState = _currentAuthState.updateActivity();

      // Durumu kaydet
      await _saveAuthState();

      debugPrint('User activity recorded, session manager notified');
    } catch (e) {
      debugPrint('Record activity error: $e');
    }
  }

  /// Uygulama arka plana geçtiğinde çağrılır
  ///
  /// Background handling is delegated to UnifiedAuthService to avoid timer conflicts.
  Future<void> onAppBackground() async {
    try {
      await _ensureInitialized();

      if (!_currentAuthState.isAuthenticated) return;

      // Cancel any existing background timer to avoid conflicts
      _backgroundLockTimer?.cancel();
      _backgroundLockTimer = null;

      debugPrint('AuthService: Background handling delegated to UnifiedAuthService');
    } catch (e) {
      debugPrint('App background handling error: $e');
    }
  }

  /// Uygulama ön plana geçtiğinde çağrılır
  ///
  /// Background handling is delegated to UnifiedAuthService to avoid conflicts.
  Future<void> onAppForeground() async {
    try {
      await _ensureInitialized();
      
      // Cancel any existing background timer to avoid conflicts
      _backgroundLockTimer?.cancel();
      _backgroundLockTimer = null;
      
      debugPrint('AuthService: Foreground handling delegated to UnifiedAuthService');
    } catch (e) {
      debugPrint('App foreground handling error: $e');
    }
  }

  /// Mevcut güvenlik konfigürasyonunu döndürür
  Future<SecurityConfig> getSecurityConfig() async {
    return await _getSecurityConfig();
  }

  /// Güvenlik konfigürasyonunu günceller
  ///
  /// [config] - Yeni güvenlik konfigürasyonu
  ///
  /// Returns güncelleme başarılı ise true
  Future<bool> updateSecurityConfig(SecurityConfig config) async {
    try {
      await _ensureInitialized();

      // Konfigürasyonu validate et
      final validation = config.validate();
      if (validation != null) {
        debugPrint('Security config validation failed: $validation');
        return false;
      }

      // Konfigürasyonu kaydet
      await _storage.storeSecurityConfig(config);

      // Oturum timer'ını güncelle
      await _updateSessionTimer();

      debugPrint('Security config updated successfully');
      return true;
    } catch (e) {
      debugPrint('Security config update error: $e');
      return false;
    }
  }

  /// Servisi temizler
  ///
  /// Tüm timer'ları iptal eder ve stream'i kapatır.
  ///
  /// Performance optimization: Proper cleanup to prevent memory leaks
  void dispose() {
    _sessionTimeoutTimer?.cancel();
    _sessionTimeoutTimer = null;
    _backgroundLockTimer?.cancel();
    _backgroundLockTimer = null;

    // Clear session data from memory
    _currentSession = null;
    _currentAuthState = AuthState.unauthenticated();
    _backgroundTimestamp = null;

    // Close stream controller if not already closed
    if (!_authStateController.isClosed) {
      _authStateController.close();
    }

    debugPrint('Auth Service disposed successfully');
  }

  /// Test amaçlı servisi sıfırlar
  ///
  /// Bu metod sadece test amaçlı kullanılmalıdır
  @visibleForTesting
  void resetForTesting() {
    _isInitialized = false;
    _currentAuthState = AuthState.unauthenticated();
    _currentSession = null;
    _sessionTimeoutTimer?.cancel();
    _sessionTimeoutTimer = null;
    _backgroundLockTimer?.cancel();
    _backgroundLockTimer = null;
    // ignore: invalid_use_of_visible_for_testing_member
    _storage.resetForTesting();
  }

  /// Test amaçlı biyometrik ayarını yapar
  ///
  /// Bu metod sadece test amaçlı kullanılmalıdır
  @visibleForTesting
  Future<void> setBiometricEnabled(bool enabled) async {
    await _ensureInitialized();
    await _storage.storeBiometricConfig(enabled, enabled ? 'fingerprint' : 'none');
  }

  /// Biyometrik ayarının aktif olup olmadığını kontrol eder
  ///
  /// Bu metod sadece test amaçlı kullanılmalıdır
  @visibleForTesting
  Future<bool> isBiometricEnabled() async {
    await _ensureInitialized();
    final config = await _storage.getBiometricConfig();
    return config?['enabled'] == true;
  }

  /// Test amaçlı kimlik doğrulama durumunu ayarlar
  ///
  /// Bu metod sadece test amaçlı kullanılmalıdır
  @visibleForTesting
  Future<void> setAuthenticatedForTesting({required AuthMethod method}) async {
    await _ensureInitialized();
    await _startSession(method, {'test': true});
  }

  // Private helper methods

  /// Servisin başlatıldığından emin olur
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Oturum başlatır
  ///
  /// [method] - Kullanılan kimlik doğrulama yöntemi
  /// [metadata] - Ek metadata bilgileri
  Future<void> _startSession(
    AuthMethod method,
    Map<String, dynamic>? metadata,
  ) async {
    // Yeni oturum ID'si oluştur
    final sessionId = _generateSessionId();

    // Oturum verilerini oluştur
    _currentSession = SessionData.create(
      sessionId: sessionId,
      authMethod: method,
      metadata: metadata,
    );

    // Kimlik doğrulama durumunu güncelle
    _currentAuthState = AuthState.authenticated(
      sessionId: sessionId,
      authMethod: method,
      metadata: metadata,
    );

    // Durumu kaydet
    await _saveAuthState();

    // Oturum timer'ını başlat
    await _startSessionTimer();

    // Durumu bildir
    _authStateController.add(_currentAuthState);

    debugPrint('Session started: $sessionId');
  }

  /// Aktivite zamanını günceller
  Future<void> _updateActivity() async {
    if (_currentSession != null) {
      _currentSession = _currentSession!.updateActivity();
      _currentAuthState = _currentAuthState.updateActivity();

      // Durumu kaydet
      await _saveAuthState();

      // Timer'ı yeniden başlat
      await _updateSessionTimer();
    }
  }

  /// Oturum timer'ını başlatır
  Future<void> _startSessionTimer() async {
    final config = await _getSecurityConfig();

    _sessionTimeoutTimer?.cancel();
    _sessionTimeoutTimer = Timer(config.sessionTimeout, () {
      logout();
    });
  }

  /// Oturum timer'ını günceller
  Future<void> _updateSessionTimer() async {
    if (_currentAuthState.isAuthenticated) {
      await _startSessionTimer();
    }
  }

  /// Güvenlik konfigürasyonunu alır
  Future<SecurityConfig> _getSecurityConfig() async {
    try {
      final config = await _storage.getSecurityConfig();
      return config ?? SecurityConfig.defaultConfig();
    } catch (e) {
      debugPrint('Failed to get security config: $e');
      return SecurityConfig.defaultConfig();
    }
  }

  /// Kimlik doğrulama durumunu kaydeder
  Future<void> _saveAuthState() async {
    try {
      await _storage.storeAuthState(_currentAuthState);
      if (_currentSession != null) {
        await _storage.storeSessionData(_currentSession!);
      }
    } catch (e) {
      debugPrint('Failed to save auth state: $e');
    }
  }

  /// Depolanan kimlik doğrulama durumunu yükler
  Future<void> _loadStoredAuthState() async {
    try {
      final storedAuthState = await _storage.getAuthState();
      final storedSessionData = await _storage.getSessionData();
      final backgroundTimestamp = await _storage.getBackgroundTimestamp();

      // Arka plan timestamp kontrolü - eğer varsa ve threshold'u aşmışsa oturumu temizle
      if (backgroundTimestamp != null) {
        final now = DateTime.now();
        final elapsedTime = now.difference(backgroundTimestamp);
        final config = await _getSecurityConfig();
        
        debugPrint('App restarted. Background timestamp found. Elapsed time: ${elapsedTime.inSeconds} seconds');
        
        if (config.sessionConfig.enableBackgroundLock && 
            elapsedTime >= config.sessionConfig.backgroundLockDelay) {
          // Arka planda çok uzun süre kaldı veya zorla kapatıldı - oturumu temizle
          debugPrint('Background time (${elapsedTime.inSeconds}s) exceeded threshold (${config.sessionConfig.backgroundLockDelay.inSeconds}s) on app restart, clearing session');
          await _clearStoredAuthState();
          await _storage.clearBackgroundTimestamp();
          return;
        }
      }

      if (storedAuthState != null && storedSessionData != null) {
        final config = await _getSecurityConfig();

        // Oturum süresi kontrolü
        if (!storedSessionData.isExpired(config.sessionTimeout)) {
          _currentAuthState = storedAuthState;
          _currentSession = storedSessionData;

          // Timer'ı başlat
          await _startSessionTimer();

          debugPrint('Stored auth state loaded successfully');
        } else {
          // Süresi dolmuş oturum - temizle
          await _clearStoredAuthState();
          await _storage.clearBackgroundTimestamp();
          debugPrint('Stored session expired, cleared');
        }
      }
    } catch (e) {
      debugPrint('Failed to load stored auth state: $e');
    }
  }

  /// Depolanan kimlik doğrulama durumunu temizler
  Future<void> _clearStoredAuthState() async {
    try {
      await _storage.clearAuthState();
      await _storage.clearSessionData();
    } catch (e) {
      debugPrint('Failed to clear stored auth state: $e');
    }
  }

  /// Benzersiz oturum ID'si oluşturur
  String _generateSessionId() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomBytes = List.generate(16, (_) => random.nextInt(256));
    final randomHex = randomBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${timestamp.toRadixString(16)}_$randomHex';
  }
}

/// Auth servis için singleton instance
class AuthServiceSingleton {
  static AuthService? _instance;

  /// Singleton instance'ı döndürür
  static AuthService get instance {
    _instance ??= AuthService();
    return _instance!;
  }

  /// Test için instance'ı set eder
  static void setInstance(AuthService service) {
    _instance = service;
  }

  /// Instance'ı temizler
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}
