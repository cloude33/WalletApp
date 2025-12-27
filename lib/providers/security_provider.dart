import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/security/auth_state.dart';
import '../models/security/security_event.dart';
import '../models/security/security_models.dart';
import '../models/security/session_data.dart';
import '../services/auth/auth_service.dart';
import '../services/auth/audit_logger_service.dart';
import '../services/auth/session_manager.dart'; // SessionState is defined here
import '../services/auth/security_service.dart';

class SecurityProvider extends ChangeNotifier {
  // Singleton pattern
  static final SecurityProvider _instance = SecurityProvider._internal();
  factory SecurityProvider() => _instance;
  SecurityProvider._internal();

  // Services
  final AuthService _authService = AuthService();
  final AuditLoggerService _auditLogger = AuditLoggerService();
  final SessionManager _sessionManager = SessionManager();
  final SecurityService _securityService = SecurityService();

  // State
  AuthState _authState = AuthState.unauthenticated();
  SecurityConfig? _securityConfig;
  SessionData? _sessionData;
  List<SecurityEvent> _recentEvents = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Stream subscriptions
  StreamSubscription<AuthState>? _authStateSubscription;
  StreamSubscription<SessionState>? _sessionStateSubscription;

  // Stream controllers for broadcasting events
  final StreamController<SecurityEvent> _securityEventController =
      StreamController<SecurityEvent>.broadcast();
  final StreamController<AuthState> _authStateController =
      StreamController<AuthState>.broadcast();

  // Getters
  
  /// Mevcut kimlik doğrulama durumu
  AuthState get authState => _authState;
  
  /// Kullanıcı kimlik doğrulaması yapılmış mı?
  bool get isAuthenticated => _authState.isAuthenticated;
  
  /// Güvenlik konfigürasyonu
  SecurityConfig? get securityConfig => _securityConfig;
  
  /// Mevcut oturum verisi
  SessionData? get sessionData => _sessionData;
  
  /// Son güvenlik olayları
  List<SecurityEvent> get recentEvents => List.unmodifiable(_recentEvents);
  
  /// Provider başlatıldı mı?
  bool get isInitialized => _isInitialized;
  
  /// Yükleniyor mu?
  bool get isLoading => _isLoading;
  
  /// Hata mesajı
  String? get errorMessage => _errorMessage;
  
  /// Güvenlik olayları stream'i
  Stream<SecurityEvent> get securityEventStream => _securityEventController.stream;
  
  /// Kimlik doğrulama durumu stream'i
  Stream<AuthState> get authStateStream => _authStateController.stream;

  /// Provider'ı başlatır
  /// 
  /// Tüm servisleri başlatır ve stream'leri dinlemeye başlar.
  /// 
  /// Throws [Exception] başlatma başarısız olursa
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _setLoading(true);
      _clearError();

      debugPrint('SecurityProvider: Initializing...');

      // Servisleri başlat
      await _authService.initialize();
      await _auditLogger.initialize();
      await _sessionManager.initialize();
      await _securityService.initialize();

      // Mevcut durumu yükle
      await _loadCurrentState();

      // Stream'leri dinle
      _setupStreamListeners();

      _isInitialized = true;
      debugPrint('SecurityProvider: Initialized successfully');
    } catch (e) {
      _setError('Provider başlatma hatası: ${e.toString()}');
      debugPrint('SecurityProvider: Initialization failed: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Biyometrik kimlik doğrulama yapar
  /// 
  /// Returns [AuthResult] doğrulama sonucunu içeren nesne
  Future<AuthResult> authenticateWithBiometric() async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.authenticateWithBiometric();

      if (result.isSuccess) {
        debugPrint('SecurityProvider: Biometric authentication successful');
      } else {
        _setError(result.errorMessage ?? 'Biyometrik doğrulama başarısız');
      }

      return result;
    } catch (e) {
      _setError('Biyometrik doğrulama hatası: ${e.toString()}');
      return AuthResult.failure(
        method: AuthMethod.biometric,
        errorMessage: e.toString(),
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Hassas işlem için kimlik doğrulama yapar
  /// 
  /// [method] - Kullanılacak doğrulama yöntemi
  /// 
  /// Returns [AuthResult] doğrulama sonucunu içeren nesne
  Future<AuthResult> authenticateForSensitiveOperation({
    AuthMethod method = AuthMethod.biometric,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.authenticateForSensitiveOperation(
        method: method,
      );

      if (!result.isSuccess) {
        _setError(result.errorMessage ?? 'Hassas işlem doğrulaması başarısız');
      }

      return result;
    } catch (e) {
      _setError('Hassas işlem doğrulama hatası: ${e.toString()}');
      return AuthResult.failure(
        method: method,
        errorMessage: e.toString(),
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Oturumu sonlandırır
  /// 
  /// Implements Requirement 6.2: Oturum yönetimi
  Future<void> logout() async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.logout();
      
      // State güncellenir stream listener tarafından
      debugPrint('SecurityProvider: Logout successful');
    } catch (e) {
      _setError('Çıkış hatası: ${e.toString()}');
      debugPrint('SecurityProvider: Logout failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Güvenlik konfigürasyonunu günceller
  /// 
  /// [config] - Yeni güvenlik konfigürasyonu
  /// 
  /// Returns güncelleme başarılı ise true
  /// 
  /// Implements Requirement 7.5: Güvenlik ayarları değiştirildiğinde değişiklikleri audit loguna kaydetmeli
  Future<bool> updateSecurityConfig(SecurityConfig config) async {
    try {
      _setLoading(true);
      _clearError();

      // Eski konfigürasyonu al
      final oldConfig = _securityConfig;

      // Yeni konfigürasyonu kaydet
      final success = await _authService.updateSecurityConfig(config);

      if (success) {
        _securityConfig = config;
        
        // Güvenlik olayı kaydet
        await _logSecurityConfigChange(oldConfig, config);
        
        notifyListeners();
        debugPrint('SecurityProvider: Security config updated');
        return true;
      } else {
        _setError('Güvenlik konfigürasyonu güncellenemedi');
        return false;
      }
    } catch (e) {
      _setError('Konfigürasyon güncelleme hatası: ${e.toString()}');
      debugPrint('SecurityProvider: Config update failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Hassas işlem için kimlik doğrulama gerekli mi kontrol eder
  /// 
  /// Returns hassas işlem için yeniden doğrulama gerekiyorsa true
  Future<bool> requiresSensitiveAuth() async {
    try {
      return await _authService.requiresSensitiveAuth();
    } catch (e) {
      debugPrint('SecurityProvider: Sensitive auth check failed: $e');
      return true;
    }
  }

  /// Mevcut kimlik doğrulama durumunu kontrol eder
  /// 
  /// Returns kullanıcı kimlik doğrulaması yapılmışsa true
  Future<bool> checkAuthentication() async {
    try {
      return await _authService.isAuthenticated();
    } catch (e) {
      debugPrint('SecurityProvider: Authentication check failed: $e');
      return false;
    }
  }

  /// Uygulama arka plana geçtiğinde çağrılır
  Future<void> onAppBackground() async {
    try {
      await _authService.onAppBackground();
      debugPrint('SecurityProvider: App moved to background');
    } catch (e) {
      debugPrint('SecurityProvider: Background handling failed: $e');
    }
  }

  /// Uygulama ön plana geçtiğinde çağrılır
  Future<void> onAppForeground() async {
    try {
      await _authService.onAppForeground();
      debugPrint('SecurityProvider: App moved to foreground');
    } catch (e) {
      debugPrint('SecurityProvider: Foreground handling failed: $e');
    }
  }

  /// Son güvenlik olaylarını yükler
  /// 
  /// [limit] - Yüklenecek maksimum olay sayısı
  Future<void> loadRecentEvents({int limit = 10}) async {
    try {
      final events = await _auditLogger.getSecurityHistory(limit: limit);
      _recentEvents = events;
      notifyListeners();
      debugPrint('SecurityProvider: Loaded ${events.length} recent events');
    } catch (e) {
      debugPrint('SecurityProvider: Failed to load recent events: $e');
    }
  }

  /// Güvenlik olayı kaydeder
  /// 
  /// [event] - Kaydedilecek güvenlik olayı
  Future<void> logSecurityEvent(SecurityEvent event) async {
    try {
      await _auditLogger.logSecurityEvent(event);
      
      // Event'i broadcast et
      _securityEventController.add(event);
      
      // Recent events listesine ekle
      _recentEvents.insert(0, event);
      if (_recentEvents.length > 50) {
        _recentEvents = _recentEvents.sublist(0, 50);
      }
      
      notifyListeners();
      debugPrint('SecurityProvider: Security event logged: ${event.type}');
    } catch (e) {
      debugPrint('SecurityProvider: Failed to log security event: $e');
    }
  }

  /// Provider'ı temizler
  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _sessionStateSubscription?.cancel();
    _securityEventController.close();
    _authStateController.close();
    _authService.dispose();
    super.dispose();
  }

  /// Test amaçlı provider'ı sıfırlar
  @visibleForTesting
  void resetForTesting() {
    _authState = AuthState.unauthenticated();
    _securityConfig = null;
    _sessionData = null;
    _recentEvents = [];
    _isInitialized = false;
    _isLoading = false;
    _errorMessage = null;
    // ignore: invalid_use_of_visible_for_testing_member
    _authService.resetForTesting();
    // ignore: invalid_use_of_visible_for_testing_member
    _sessionManager.resetForTesting();
  }

  // Private helper methods

  /// Mevcut durumu yükler
  Future<void> _loadCurrentState() async {
    try {
      // Auth state'i yükle
      _authState = _authService.currentAuthState;
      
      // Security config'i yükle
      _securityConfig = await _authService.getSecurityConfig();
      
      // Session data'yı yükle
      _sessionData = _authService.currentSession;
      
      // Son olayları yükle
      await loadRecentEvents();
      
      notifyListeners();
    } catch (e) {
      debugPrint('SecurityProvider: Failed to load current state: $e');
    }
  }

  /// Stream listener'ları kurar
  void _setupStreamListeners() {
    // Auth state stream'ini dinle
    _authStateSubscription = _authService.authStateStream.listen(
      (authState) {
        _authState = authState;
        _sessionData = _authService.currentSession;
        
        // Broadcast et
        _authStateController.add(authState);
        
        notifyListeners();
        debugPrint('SecurityProvider: Auth state updated: ${authState.isAuthenticated}');
      },
      onError: (error) {
        debugPrint('SecurityProvider: Auth state stream error: $error');
      },
    );

    // Session state stream'ini dinle
    _sessionStateSubscription = _sessionManager.sessionStateStream.listen(
      (sessionState) {
        // Session state değişikliklerini takip et
        // Session data'yı auth service'den al
        _sessionData = _authService.currentSession;
        notifyListeners();
        debugPrint('SecurityProvider: Session state updated: ${sessionState.isActive}');
      },
      onError: (error) {
        debugPrint('SecurityProvider: Session state stream error: $error');
      },
    );
  }

  /// Güvenlik konfigürasyon değişikliğini loglar
  Future<void> _logSecurityConfigChange(
    SecurityConfig? oldConfig,
    SecurityConfig newConfig,
  ) async {
    try {
      // Değişiklikleri tespit et ve logla
      if (oldConfig == null) {
        await logSecurityEvent(
          SecurityEvent.securitySettingsChanged(
            setting: 'initial_config',
            oldValue: 'none',
            newValue: 'configured',
          ),
        );
      } else {
        // Biometric enabled değişikliği
        if (oldConfig.isBiometricEnabled != newConfig.isBiometricEnabled) {
          await logSecurityEvent(
            SecurityEvent.securitySettingsChanged(
              setting: 'biometric_enabled',
              oldValue: oldConfig.isBiometricEnabled.toString(),
              newValue: newConfig.isBiometricEnabled.toString(),
            ),
          );
        }
        
        // Session timeout değişikliği
        if (oldConfig.sessionTimeout != newConfig.sessionTimeout) {
          await logSecurityEvent(
            SecurityEvent.securitySettingsChanged(
              setting: 'session_timeout',
              oldValue: oldConfig.sessionTimeout.inMinutes.toString(),
              newValue: newConfig.sessionTimeout.inMinutes.toString(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('SecurityProvider: Failed to log config change: $e');
    }
  }

  /// Loading durumunu ayarlar
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Hata mesajını ayarlar
  void _setError(String? error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      notifyListeners();
    }
  }

  /// Hata mesajını temizler
  void _clearError() {
    _setError(null);
  }
}

/// Singleton instance helper
class SecurityProviderSingleton {
  static SecurityProvider? _instance;
  
  /// Singleton instance'ı döndürür
  static SecurityProvider get instance {
    _instance ??= SecurityProvider();
    return _instance!;
  }
  
  /// Test için instance'ı set eder
  static void setInstance(SecurityProvider provider) {
    _instance = provider;
  }
  
  /// Instance'ı temizler
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}
