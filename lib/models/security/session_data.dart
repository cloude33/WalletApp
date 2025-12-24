import 'auth_state.dart';

/// Oturum verilerini temsil eden model
class SessionData {
  /// Oturum ID'si
  final String sessionId;
  
  /// Oturum oluşturulma zamanı
  final DateTime createdAt;
  
  /// Son aktivite zamanı
  final DateTime lastActivity;
  
  /// Kullanılan kimlik doğrulama yöntemi
  final AuthMethod authMethod;
  
  /// Oturum metadata bilgileri
  final Map<String, dynamic> metadata;
  
  /// Oturum aktif mi?
  final bool isActive;
  
  /// Hassas işlem için son doğrulama zamanı
  final DateTime? lastSensitiveAuth;

  SessionData({
    required this.sessionId,
    required this.createdAt,
    required this.lastActivity,
    required this.authMethod,
    this.metadata = const {},
    this.isActive = true,
    this.lastSensitiveAuth,
  });

  /// Yeni oturum oluşturur
  factory SessionData.create({
    required String sessionId,
    required AuthMethod authMethod,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return SessionData(
      sessionId: sessionId,
      createdAt: now,
      lastActivity: now,
      authMethod: authMethod,
      metadata: metadata ?? {},
    );
  }

  /// JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'createdAt': createdAt.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'authMethod': authMethod.toJson(),
      'metadata': metadata,
      'isActive': isActive,
      'lastSensitiveAuth': lastSensitiveAuth?.toIso8601String(),
    };
  }

  /// JSON'dan oluşturur
  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      sessionId: json['sessionId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActivity: DateTime.parse(json['lastActivity'] as String),
      authMethod: AuthMethod.fromJson(json['authMethod'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      isActive: json['isActive'] as bool? ?? true,
      lastSensitiveAuth: json['lastSensitiveAuth'] != null
          ? DateTime.parse(json['lastSensitiveAuth'] as String)
          : null,
    );
  }

  /// Kopya oluşturur
  SessionData copyWith({
    String? sessionId,
    DateTime? createdAt,
    DateTime? lastActivity,
    AuthMethod? authMethod,
    Map<String, dynamic>? metadata,
    bool? isActive,
    DateTime? lastSensitiveAuth,
  }) {
    return SessionData(
      sessionId: sessionId ?? this.sessionId,
      createdAt: createdAt ?? this.createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      authMethod: authMethod ?? this.authMethod,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
      lastSensitiveAuth: lastSensitiveAuth ?? this.lastSensitiveAuth,
    );
  }

  /// Aktivite zamanını günceller
  SessionData updateActivity() {
    return copyWith(lastActivity: DateTime.now());
  }

  /// Hassas işlem doğrulama zamanını günceller
  SessionData updateSensitiveAuth() {
    return copyWith(lastSensitiveAuth: DateTime.now());
  }

  /// Oturumu sonlandırır
  SessionData terminate() {
    return copyWith(isActive: false);
  }

  /// Oturum süresi dolmuş mu kontrol eder
  bool isExpired(Duration sessionTimeout) {
    if (!isActive) return true;
    
    final now = DateTime.now();
    final timeSinceLastActivity = now.difference(lastActivity);
    
    return timeSinceLastActivity > sessionTimeout;
  }

  /// Hassas işlem için yeniden doğrulama gerekli mi kontrol eder
  bool requiresSensitiveAuth(Duration sensitiveTimeout) {
    if (!isActive) return true;
    
    if (lastSensitiveAuth == null) return true;
    
    final now = DateTime.now();
    final timeSinceLastSensitiveAuth = now.difference(lastSensitiveAuth!);
    
    return timeSinceLastSensitiveAuth > sensitiveTimeout;
  }

  /// Oturum süresini döndürür
  Duration get sessionDuration {
    return DateTime.now().difference(createdAt);
  }

  /// Son aktiviteden beri geçen süreyi döndürür
  Duration get timeSinceLastActivity {
    return DateTime.now().difference(lastActivity);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionData &&
        other.sessionId == sessionId &&
        other.createdAt == createdAt &&
        other.lastActivity == lastActivity &&
        other.authMethod == authMethod &&
        other.isActive == isActive &&
        other.lastSensitiveAuth == lastSensitiveAuth;
  }

  @override
  int get hashCode {
    return Object.hash(
      sessionId,
      createdAt,
      lastActivity,
      authMethod,
      isActive,
      lastSensitiveAuth,
    );
  }

  @override
  String toString() {
    return 'SessionData(sessionId: $sessionId, '
           'authMethod: $authMethod, isActive: $isActive, '
           'lastActivity: $lastActivity)';
  }
}