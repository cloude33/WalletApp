/// Kimlik doğrulama durumunu temsil eden model
class AuthState {
  /// Kullanıcı kimlik doğrulaması yapılmış mı?
  final bool isAuthenticated;
  
  /// Aktif oturum ID'si
  final String? sessionId;
  
  /// Son kimlik doğrulama zamanı
  final DateTime? lastAuthTime;
  
  /// Kullanılan kimlik doğrulama yöntemi
  final AuthMethod? authMethod;
  
  /// Oturum başlangıç zamanı
  final DateTime? sessionStartTime;
  
  /// Son aktivite zamanı
  final DateTime? lastActivityTime;
  
  /// Hassas işlem için son doğrulama zamanı
  final DateTime? lastSensitiveAuthTime;
  
  /// Ek metadata bilgileri
  final Map<String, dynamic>? metadata;

  const AuthState({
    this.isAuthenticated = false,
    this.sessionId,
    this.lastAuthTime,
    this.authMethod,
    this.sessionStartTime,
    this.lastActivityTime,
    this.lastSensitiveAuthTime,
    this.metadata,
  });

  /// Kimlik doğrulanmamış durum
  factory AuthState.unauthenticated() {
    return const AuthState(isAuthenticated: false);
  }

  /// Kimlik doğrulanmış durum
  factory AuthState.authenticated({
    required String sessionId,
    required AuthMethod authMethod,
    DateTime? authTime,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return AuthState(
      isAuthenticated: true,
      sessionId: sessionId,
      lastAuthTime: authTime ?? now,
      authMethod: authMethod,
      sessionStartTime: now,
      lastActivityTime: now,
      metadata: metadata,
    );
  }

  /// JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'isAuthenticated': isAuthenticated,
      'sessionId': sessionId,
      'lastAuthTime': lastAuthTime?.toIso8601String(),
      'authMethod': authMethod?.toJson(),
      'sessionStartTime': sessionStartTime?.toIso8601String(),
      'lastActivityTime': lastActivityTime?.toIso8601String(),
      'lastSensitiveAuthTime': lastSensitiveAuthTime?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// JSON'dan oluşturur
  factory AuthState.fromJson(Map<String, dynamic> json) {
    return AuthState(
      isAuthenticated: json['isAuthenticated'] as bool? ?? false,
      sessionId: json['sessionId'] as String?,
      lastAuthTime: json['lastAuthTime'] != null
          ? DateTime.parse(json['lastAuthTime'] as String)
          : null,
      authMethod: json['authMethod'] != null
          ? AuthMethod.fromJson(json['authMethod'] as String)
          : null,
      sessionStartTime: json['sessionStartTime'] != null
          ? DateTime.parse(json['sessionStartTime'] as String)
          : null,
      lastActivityTime: json['lastActivityTime'] != null
          ? DateTime.parse(json['lastActivityTime'] as String)
          : null,
      lastSensitiveAuthTime: json['lastSensitiveAuthTime'] != null
          ? DateTime.parse(json['lastSensitiveAuthTime'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Kopya oluşturur
  AuthState copyWith({
    bool? isAuthenticated,
    String? sessionId,
    DateTime? lastAuthTime,
    AuthMethod? authMethod,
    DateTime? sessionStartTime,
    DateTime? lastActivityTime,
    DateTime? lastSensitiveAuthTime,
    Map<String, dynamic>? metadata,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      sessionId: sessionId ?? this.sessionId,
      lastAuthTime: lastAuthTime ?? this.lastAuthTime,
      authMethod: authMethod ?? this.authMethod,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      lastActivityTime: lastActivityTime ?? this.lastActivityTime,
      lastSensitiveAuthTime: lastSensitiveAuthTime ?? this.lastSensitiveAuthTime,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Aktivite zamanını günceller
  AuthState updateActivity() {
    return copyWith(lastActivityTime: DateTime.now());
  }

  /// Hassas işlem doğrulama zamanını günceller
  AuthState updateSensitiveAuth() {
    return copyWith(lastSensitiveAuthTime: DateTime.now());
  }

  /// Oturum süresi dolmuş mu kontrol eder
  bool isSessionExpired(Duration sessionTimeout) {
    if (!isAuthenticated || lastActivityTime == null) {
      return true;
    }
    
    final now = DateTime.now();
    final timeSinceLastActivity = now.difference(lastActivityTime!);
    
    return timeSinceLastActivity > sessionTimeout;
  }

  /// Hassas işlem için yeniden doğrulama gerekli mi kontrol eder
  bool requiresSensitiveAuth(Duration sensitiveTimeout) {
    if (!isAuthenticated) {
      return true;
    }
    
    if (lastSensitiveAuthTime == null) {
      return true;
    }
    
    final now = DateTime.now();
    final timeSinceLastSensitiveAuth = now.difference(lastSensitiveAuthTime!);
    
    return timeSinceLastSensitiveAuth > sensitiveTimeout;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.isAuthenticated == isAuthenticated &&
        other.sessionId == sessionId &&
        other.lastAuthTime == lastAuthTime &&
        other.authMethod == authMethod &&
        other.sessionStartTime == sessionStartTime &&
        other.lastActivityTime == lastActivityTime &&
        other.lastSensitiveAuthTime == lastSensitiveAuthTime;
  }

  @override
  int get hashCode {
    return Object.hash(
      isAuthenticated,
      sessionId,
      lastAuthTime,
      authMethod,
      sessionStartTime,
      lastActivityTime,
      lastSensitiveAuthTime,
    );
  }

  @override
  String toString() {
    return 'AuthState(isAuthenticated: $isAuthenticated, '
           'sessionId: $sessionId, authMethod: $authMethod, '
           'lastActivityTime: $lastActivityTime)';
  }
}

/// Kimlik doğrulama yöntemlerini tanımlayan enum
enum AuthMethod {
  /// Biyometrik doğrulama
  biometric,
  
  /// İki faktörlü doğrulama
  twoFactor,
  
  /// Güvenlik soruları ile doğrulama
  securityQuestions;

  /// Enum değerini string'e çevirir
  String toJson() => name;

  /// String değerini enum'a çevirir
  static AuthMethod fromJson(String json) {
    return AuthMethod.values.firstWhere(
      (method) => method.name == json,
      orElse: () => AuthMethod.biometric,
    );
  }

  /// Kullanıcı dostu isim döndürür
  String get displayName {
    switch (this) {
      case AuthMethod.biometric:
        return 'Biyometrik';
      case AuthMethod.twoFactor:
        return 'İki Faktörlü';
      case AuthMethod.securityQuestions:
        return 'Güvenlik Soruları';
    }
  }
}