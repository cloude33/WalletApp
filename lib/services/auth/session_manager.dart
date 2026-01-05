import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../models/security/security_models.dart';
import '../../models/security/session_data.dart';
import '../../models/security/auth_state.dart';
import 'secure_storage_service.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final AuthSecureStorageService _storage = AuthSecureStorageService();
  
  // Oturum durumu stream controller
  final StreamController<SessionState> _sessionStateController = StreamController<SessionState>.broadcast();
  
  // Mevcut oturum durumu
  SessionState _currentSessionState = SessionState.inactive();
  
  // Timer'lar
  Timer? _sessionTimeoutTimer;
  Timer? _backgroundLockTimer;
  Timer? _sensitiveOperationTimer;
  Timer? _activityCheckTimer;
  
  // Uygulama yaşam döngüsü durumu
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  
  // Son aktivite zamanı
  DateTime _lastActivityTime = DateTime.now();
  
  // Hassas ekran durumu
  bool _isInSensitiveScreen = false;
  
  bool _isInitialized = false;

  /// Oturum durumu stream'i
  Stream<SessionState> get sessionStateStream => _sessionStateController.stream;
  
  /// Mevcut oturum durumu
  SessionState get currentSessionState => _currentSessionState;
  
  /// Son aktivite zamanı
  DateTime get lastActivityTime => _lastActivityTime;
  
  /// Hassas ekran durumu
  bool get isInSensitiveScreen => _isInSensitiveScreen;
  
  /// Uygulama yaşam döngüsü durumu
  AppLifecycleState get appLifecycleState => _appLifecycleState;

  /// Servisi başlatır
  /// 
  /// Bu metod servisin kullanılmadan önce çağrılmalıdır.
  /// Uygulama yaşam döngüsü observer'ını başlatır ve mevcut oturum durumunu yükler.
  /// 
  /// Throws [Exception] başlatma başarısız olursa
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Storage servisini başlat
      await _storage.initialize();
      
      // Mevcut oturum durumunu yükle
      await _loadStoredSessionState();
      
      // Aktivite kontrol timer'ını başlat
      _startActivityCheckTimer();
      
      _isInitialized = true;
      debugPrint('Session Manager initialized successfully');
    } catch (e) {
      throw Exception('Failed to initialize Session Manager: ${e.toString()}');
    }
  }

  /// Oturum başlatır
  /// 
  /// [sessionData] - Başlatılacak oturum verisi
  /// [authMethod] - Kullanılan kimlik doğrulama yöntemi
  /// [metadata] - Ek metadata bilgileri
  /// 
  /// Returns başarılı ise true
  /// 
  /// Implements Requirement 6.1: Oturum zamanlayıcısını başlatmalı
  Future<bool> startSession({
    required SessionData sessionData,
    required AuthMethod authMethod,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _ensureInitialized();
      
      // Mevcut oturumu sonlandır
      await stopSession();
      
      // Yeni oturum durumu oluştur
      _currentSessionState = SessionState.active(
        sessionData: sessionData,
        authMethod: authMethod,
        metadata: metadata,
      );
      
      // Son aktivite zamanını güncelle
      _lastActivityTime = DateTime.now();
      
      // Oturum timer'ını başlat
      await _startSessionTimer();
      
      // Durumu kaydet
      await _saveSessionState();
      
      // Durumu bildir
      _sessionStateController.add(_currentSessionState);
      
      debugPrint('Session started: ${sessionData.sessionId}');
      return true;
    } catch (e) {
      debugPrint('Failed to start session: $e');
      return false;
    }
  }

  /// Oturumu sonlandırır
  /// 
  /// Tüm timer'ları iptal eder ve oturum verilerini temizler.
  /// 
  /// Implements Requirement 6.2: Oturumu sonlandırmalı
  Future<void> stopSession() async {
    try {
      await _ensureInitialized();
      
      // Timer'ları iptal et
      _sessionTimeoutTimer?.cancel();
      _backgroundLockTimer?.cancel();
      _sensitiveOperationTimer?.cancel();
      
      // Oturum durumunu güncelle
      if (_currentSessionState.isActive) {
        _currentSessionState = _currentSessionState.terminate();
        
        // Durumu kaydet
        await _saveSessionState();
        
        // Durumu bildir
        _sessionStateController.add(_currentSessionState);
      }
      
      debugPrint('Session stopped');
    } catch (e) {
      debugPrint('Failed to stop session: $e');
    }
  }

  /// Aktivite kaydeder
  /// 
  /// Kullanıcı aktivitesi olduğunda çağrılır.
  /// Oturum timer'ını yeniler ve son aktivite zamanını günceller.
  /// 
  /// Implements Requirement 6.2: Aktivite olmadığında oturumu sonlandırmalı
  Future<void> recordActivity() async {
    try {
      await _ensureInitialized();
      
      if (!_currentSessionState.isActive) return;
      
      // Son aktivite zamanını güncelle
      _lastActivityTime = DateTime.now();
      
      // Oturum durumunu güncelle
      _currentSessionState = _currentSessionState.updateActivity();
      
      // Oturum timer'ını yenile
      await _refreshSessionTimer();
      
      // Durumu kaydet (throttle edilmiş)
      await _saveSessionStateThrottled();
      
      debugPrint('Activity recorded');
    } catch (e) {
      debugPrint('Failed to record activity: $e');
    }
  }

  /// Uygulama arka plana geçtiğinde çağrılır
  /// 
  /// Background timer management is delegated to UnifiedAuthService to avoid conflicts.
  /// 
  /// Implements Requirement 6.1: Arka plana geçtiğinde oturum zamanlayıcısını başlatmalı
  Future<void> onAppBackground() async {
    try {
      await _ensureInitialized();
      
      _appLifecycleState = AppLifecycleState.paused;
      
      if (!_currentSessionState.isActive) return;
      
      // Cancel any existing background timer to avoid conflicts with UnifiedAuthService
      _backgroundLockTimer?.cancel();
      _backgroundLockTimer = null;
      
      // Update session state to reflect background mode
      _currentSessionState = _currentSessionState.enterBackground();
      _sessionStateController.add(_currentSessionState);
      
      debugPrint('SessionManager: Background handling delegated to UnifiedAuthService');
      
    } catch (e) {
      debugPrint('App background handling error: $e');
    }
  }

  /// Uygulama ön plana geçtiğinde çağrılır
  /// 
  /// Background timer management is delegated to UnifiedAuthService to avoid conflicts.
  /// 
  /// Implements Requirement 6.3: Tekrar açıldığında kimlik doğrulama gerektirmeli
  Future<void> onAppForeground() async {
    try {
      await _ensureInitialized();
      
      _appLifecycleState = AppLifecycleState.resumed;
      
      // Cancel any existing background timer to avoid conflicts
      _backgroundLockTimer?.cancel();
      _backgroundLockTimer = null;
      
      if (!_currentSessionState.isActive) return;
      
      // Update session state to reflect foreground mode
      _currentSessionState = _currentSessionState.enterForeground();
      _sessionStateController.add(_currentSessionState);
      
      // Refresh session timer
      await _refreshSessionTimer();
      
      debugPrint('SessionManager: Foreground handling delegated to UnifiedAuthService');
      
    } catch (e) {
      debugPrint('App foreground handling error: $e');
    }
  }

  /// Hassas ekran durumunu ayarlar
  /// 
  /// [isSensitive] - Hassas ekran durumu
  /// 
  /// Implements Requirement 6.4: Hassas ekranlarda 2 dakika sonra kilitleme yapmalı
  Future<void> setSensitiveScreenState(bool isSensitive) async {
    try {
      await _ensureInitialized();
      
      _isInSensitiveScreen = isSensitive;
      
      if (!_currentSessionState.isActive) return;
      
      if (isSensitive) {
        // Hassas ekran timer'ını başlat
        await _startSensitiveOperationTimer();
        debugPrint('Sensitive screen mode activated');
      } else {
        // Hassas ekran timer'ını iptal et
        _sensitiveOperationTimer?.cancel();
        debugPrint('Sensitive screen mode deactivated');
      }
      
      // Oturum durumunu güncelle
      _currentSessionState = _currentSessionState.setSensitiveScreen(isSensitive);
      _sessionStateController.add(_currentSessionState);
      
    } catch (e) {
      debugPrint('Failed to set sensitive screen state: $e');
    }
  }

  /// Oturum aktif mi kontrol eder
  /// 
  /// Returns oturum aktif ise true
  Future<bool> isSessionActive() async {
    try {
      await _ensureInitialized();
      
      if (!_currentSessionState.isActive) return false;
      
      // Zaman aşımı kontrolü
      final config = await _getSecurityConfig();
      final timeSinceLastActivity = DateTime.now().difference(_lastActivityTime);
      
      if (timeSinceLastActivity > config.sessionTimeout) {
        // Oturum süresi dolmuş
        await stopSession();
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Session active check error: $e');
      return false;
    }
  }

  /// Oturum kalan süresini döndürür
  /// 
  /// Returns kalan süre, oturum aktif değilse null
  Future<Duration?> getSessionRemainingTime() async {
    try {
      await _ensureInitialized();
      
      if (!_currentSessionState.isActive) return null;
      
      final config = await _getSecurityConfig();
      final timeSinceLastActivity = DateTime.now().difference(_lastActivityTime);
      final remainingTime = config.sessionTimeout - timeSinceLastActivity;
      
      return remainingTime.isNegative ? Duration.zero : remainingTime;
    } catch (e) {
      debugPrint('Get session remaining time error: $e');
      return null;
    }
  }

  /// Güvenlik konfigürasyonunu günceller
  /// 
  /// [config] - Yeni güvenlik konfigürasyonu
  /// 
  /// Implements Requirement 6.5: Özelleştirilebilir zaman aşımı uygulamalı
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
      
      // Aktif oturum varsa timer'ları güncelle
      if (_currentSessionState.isActive) {
        await _refreshSessionTimer();
        
        if (_isInSensitiveScreen) {
          await _startSensitiveOperationTimer();
        }
      }
      
      debugPrint('Security config updated, timers refreshed');
      return true;
    } catch (e) {
      debugPrint('Security config update error: $e');
      return false;
    }
  }

  /// Servisi temizler
  /// 
  /// Tüm timer'ları iptal eder ve stream'i kapatır.
  void dispose() {
    _sessionTimeoutTimer?.cancel();
    _backgroundLockTimer?.cancel();
    _sensitiveOperationTimer?.cancel();
    _activityCheckTimer?.cancel();
    _sessionStateController.close();
  }

  /// Test amaçlı servisi sıfırlar
  /// 
  /// Bu metod sadece test amaçlı kullanılmalıdır
  @visibleForTesting
  void resetForTesting() {
    _isInitialized = false;
    _currentSessionState = SessionState.inactive();
    _lastActivityTime = DateTime.now();
    _isInSensitiveScreen = false;
    _appLifecycleState = AppLifecycleState.resumed;
    _sessionTimeoutTimer?.cancel();
    _backgroundLockTimer?.cancel();
    _sensitiveOperationTimer?.cancel();
    _activityCheckTimer?.cancel();
    // ignore: invalid_use_of_visible_for_testing_member
    _storage.resetForTesting();
  }

  // Private helper methods

  /// Servisin başlatıldığından emin olur
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Oturum timer'ını başlatır
  Future<void> _startSessionTimer() async {
    final config = await _getSecurityConfig();
    
    _sessionTimeoutTimer?.cancel();
    _sessionTimeoutTimer = Timer(config.sessionTimeout, () {
      _onSessionTimeout();
    });
    
    debugPrint('Session timer started: ${config.sessionTimeout}');
  }

  /// Oturum timer'ını yeniler
  Future<void> _refreshSessionTimer() async {
    if (_currentSessionState.isActive) {
      await _startSessionTimer();
    }
  }

  /// Hassas işlem timer'ını başlatır
  Future<void> _startSensitiveOperationTimer() async {
    final config = await _getSecurityConfig();
    
    _sensitiveOperationTimer?.cancel();
    _sensitiveOperationTimer = Timer(config.sessionConfig.sensitiveOperationTimeout, () {
      _onSensitiveOperationTimeout();
    });
    
    debugPrint('Sensitive operation timer started: ${config.sessionConfig.sensitiveOperationTimeout}');
  }

  /// Aktivite kontrol timer'ını başlatır
  void _startActivityCheckTimer() {
    _activityCheckTimer?.cancel();
    _activityCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkSessionActivity();
    });
  }

  /// Oturum zaman aşımı callback'i
  void _onSessionTimeout() {
    debugPrint('Session timeout occurred');
    stopSession();
  }

  /// Arka plan kilitleme zaman aşımı callback'i
  void _onBackgroundLockTimeout() {
    debugPrint('Background lock timeout occurred');
    stopSession();
  }

  /// Hassas işlem zaman aşımı callback'i
  void _onSensitiveOperationTimeout() {
    debugPrint('Sensitive operation timeout occurred');
    stopSession();
  }

  /// Oturum aktivitesini kontrol eder
  Future<void> _checkSessionActivity() async {
    try {
      if (!_currentSessionState.isActive) return;
      
      final config = await _getSecurityConfig();
      final timeSinceLastActivity = DateTime.now().difference(_lastActivityTime);
      
      if (timeSinceLastActivity > config.sessionTimeout) {
        debugPrint('Session inactive for too long, terminating');
        await stopSession();
      }
    } catch (e) {
      debugPrint('Session activity check error: $e');
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

  /// Oturum durumunu kaydeder
  Future<void> _saveSessionState() async {
    try {
      await _storage.storeSessionState(_currentSessionState);
    } catch (e) {
      debugPrint('Failed to save session state: $e');
    }
  }

  /// Oturum durumunu throttle edilmiş şekilde kaydeder
  Timer? _saveThrottleTimer;
  Future<void> _saveSessionStateThrottled() async {
    _saveThrottleTimer?.cancel();
    _saveThrottleTimer = Timer(const Duration(seconds: 5), () {
      _saveSessionState();
    });
  }

  /// Depolanan oturum durumunu yükler
  Future<void> _loadStoredSessionState() async {
    try {
      final storedStateMap = await _storage.getSessionState();
      
      if (storedStateMap != null) {
        final storedSessionState = SessionState.fromJson(storedStateMap as Map<String, dynamic>);
        
        if (storedSessionState.isActive) {
          final config = await _getSecurityConfig();
          
          // Oturum süresi kontrolü
          final timeSinceLastActivity = DateTime.now().difference(storedSessionState.lastActivityTime);
          
          if (timeSinceLastActivity <= config.sessionTimeout) {
            _currentSessionState = storedSessionState;
            _lastActivityTime = storedSessionState.lastActivityTime;
            
            // Timer'ları başlat
            await _startSessionTimer();
            
            debugPrint('Stored session state loaded successfully');
          } else {
            // Süresi dolmuş oturum - temizle
            await _clearStoredSessionState();
            debugPrint('Stored session expired, cleared');
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load stored session state: $e');
    }
  }

  /// Depolanan oturum durumunu temizler
  Future<void> _clearStoredSessionState() async {
    try {
      await _storage.clearSessionState();
    } catch (e) {
      debugPrint('Failed to clear stored session state: $e');
    }
  }
}

/// Oturum durumunu temsil eden model
class SessionState {
  /// Oturum aktif mi?
  final bool isActive;
  
  /// Oturum verisi
  final SessionData? sessionData;
  
  /// Kullanılan kimlik doğrulama yöntemi
  final AuthMethod? authMethod;
  
  /// Son aktivite zamanı
  final DateTime lastActivityTime;
  
  /// Uygulama arka planda mı?
  final bool isInBackground;
  
  /// Hassas ekranda mı?
  final bool isInSensitiveScreen;
  
  /// Ek metadata bilgileri
  final Map<String, dynamic>? metadata;

  const SessionState({
    this.isActive = false,
    this.sessionData,
    this.authMethod,
    required this.lastActivityTime,
    this.isInBackground = false,
    this.isInSensitiveScreen = false,
    this.metadata,
  });

  /// Aktif olmayan oturum durumu
  factory SessionState.inactive() {
    return SessionState(
      isActive: false,
      lastActivityTime: DateTime.now(),
    );
  }

  /// Aktif oturum durumu
  factory SessionState.active({
    required SessionData sessionData,
    required AuthMethod authMethod,
    Map<String, dynamic>? metadata,
  }) {
    return SessionState(
      isActive: true,
      sessionData: sessionData,
      authMethod: authMethod,
      lastActivityTime: DateTime.now(),
      metadata: metadata,
    );
  }

  /// JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'sessionData': sessionData?.toJson(),
      'authMethod': authMethod?.toJson(),
      'lastActivityTime': lastActivityTime.toIso8601String(),
      'isInBackground': isInBackground,
      'isInSensitiveScreen': isInSensitiveScreen,
      'metadata': metadata,
    };
  }

  /// JSON'dan oluşturur
  factory SessionState.fromJson(Map<String, dynamic> json) {
    return SessionState(
      isActive: json['isActive'] as bool? ?? false,
      sessionData: json['sessionData'] != null
          ? SessionData.fromJson(json['sessionData'] as Map<String, dynamic>)
          : null,
      authMethod: json['authMethod'] != null
          ? AuthMethod.fromJson(json['authMethod'] as String)
          : null,
      lastActivityTime: DateTime.parse(json['lastActivityTime'] as String),
      isInBackground: json['isInBackground'] as bool? ?? false,
      isInSensitiveScreen: json['isInSensitiveScreen'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Kopya oluşturur
  SessionState copyWith({
    bool? isActive,
    SessionData? sessionData,
    AuthMethod? authMethod,
    DateTime? lastActivityTime,
    bool? isInBackground,
    bool? isInSensitiveScreen,
    Map<String, dynamic>? metadata,
  }) {
    return SessionState(
      isActive: isActive ?? this.isActive,
      sessionData: sessionData ?? this.sessionData,
      authMethod: authMethod ?? this.authMethod,
      lastActivityTime: lastActivityTime ?? this.lastActivityTime,
      isInBackground: isInBackground ?? this.isInBackground,
      isInSensitiveScreen: isInSensitiveScreen ?? this.isInSensitiveScreen,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Aktivite zamanını günceller
  SessionState updateActivity() {
    return copyWith(lastActivityTime: DateTime.now());
  }

  /// Oturumu sonlandırır
  SessionState terminate() {
    return SessionState(
      isActive: false,
      sessionData: null,
      authMethod: null,
      lastActivityTime: lastActivityTime,
      isInBackground: false,
      isInSensitiveScreen: false,
      metadata: null,
    );
  }

  /// Arka plan durumuna geçer
  SessionState enterBackground() {
    return copyWith(isInBackground: true);
  }

  /// Ön plan durumuna geçer
  SessionState enterForeground() {
    return copyWith(isInBackground: false);
  }

  /// Hassas ekran durumunu ayarlar
  SessionState setSensitiveScreen(bool isSensitive) {
    return copyWith(isInSensitiveScreen: isSensitive);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionState &&
        other.isActive == isActive &&
        other.sessionData == sessionData &&
        other.authMethod == authMethod &&
        other.lastActivityTime == lastActivityTime &&
        other.isInBackground == isInBackground &&
        other.isInSensitiveScreen == isInSensitiveScreen;
  }

  @override
  int get hashCode {
    return Object.hash(
      isActive,
      sessionData,
      authMethod,
      lastActivityTime,
      isInBackground,
      isInSensitiveScreen,
    );
  }

  @override
  String toString() {
    return 'SessionState(isActive: $isActive, '
           'authMethod: $authMethod, '
           'lastActivityTime: $lastActivityTime, '
           'isInBackground: $isInBackground, '
           'isInSensitiveScreen: $isInSensitiveScreen)';
  }
}

/// Session manager için singleton instance
class SessionManagerSingleton {
  static SessionManager? _instance;
  
  /// Singleton instance'ı döndürür
  static SessionManager get instance {
    _instance ??= SessionManager();
    return _instance!;
  }
  
  /// Test için instance'ı set eder
  static void setInstance(SessionManager manager) {
    _instance = manager;
  }
  
  /// Instance'ı temizler
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}