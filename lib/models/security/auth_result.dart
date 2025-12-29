import 'auth_state.dart';

/// Kimlik doğrulama işleminin sonucunu temsil eden model
class AuthResult {
  /// Kimlik doğrulama başarılı mı?
  final bool isSuccess;
  
  /// Kullanılan kimlik doğrulama yöntemi
  final AuthMethod method;
  
  /// Hata mesajı (başarısızlık durumunda)
  final String? errorMessage;
  
  /// Kilitleme süresi (hesap kilitlenmişse)
  final Duration? lockoutDuration;
  
  /// Kalan deneme hakkı
  final int? remainingAttempts;
  
  /// Kimlik doğrulama zamanı
  final DateTime timestamp;
  
  /// Ek metadata bilgileri
  final Map<String, dynamic>? metadata;

  AuthResult({
    required this.isSuccess,
    required this.method,
    this.errorMessage,
    this.lockoutDuration,
    this.remainingAttempts,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Başarılı kimlik doğrulama sonucu oluşturur
  factory AuthResult.success({
    required AuthMethod method,
    Map<String, dynamic>? metadata,
  }) {
    return AuthResult(
      isSuccess: true,
      method: method,
      metadata: metadata,
    );
  }

  /// Başarısız kimlik doğrulama sonucu oluşturur
  factory AuthResult.failure({
    required AuthMethod method,
    required String errorMessage,
    Duration? lockoutDuration,
    int? remainingAttempts,
    Map<String, dynamic>? metadata,
  }) {
    return AuthResult(
      isSuccess: false,
      method: method,
      errorMessage: errorMessage,
      lockoutDuration: lockoutDuration,
      remainingAttempts: remainingAttempts,
      metadata: metadata,
    );
  }

  /// JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'isSuccess': isSuccess,
      'method': method.toJson(),
      'errorMessage': errorMessage,
      'lockoutDuration': lockoutDuration?.inMilliseconds,
      'remainingAttempts': remainingAttempts,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// JSON'dan oluşturur
  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      isSuccess: json['isSuccess'] as bool? ?? false,
      method: AuthMethod.fromJson(json['method'] as String? ?? 'biometric'),
      errorMessage: json['errorMessage'] as String?,
      lockoutDuration: json['lockoutDuration'] != null
          ? Duration(milliseconds: json['lockoutDuration'] as int)
          : null,
      remainingAttempts: json['remainingAttempts'] as int?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Kopya oluşturur
  AuthResult copyWith({
    bool? isSuccess,
    AuthMethod? method,
    String? errorMessage,
    Duration? lockoutDuration,
    int? remainingAttempts,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return AuthResult(
      isSuccess: isSuccess ?? this.isSuccess,
      method: method ?? this.method,
      errorMessage: errorMessage ?? this.errorMessage,
      lockoutDuration: lockoutDuration ?? this.lockoutDuration,
      remainingAttempts: remainingAttempts ?? this.remainingAttempts,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Validasyon yapar
  String? validate() {
    if (!isSuccess && (errorMessage == null || errorMessage!.isEmpty)) {
      return 'Başarısız kimlik doğrulama için hata mesajı gerekli';
    }
    
    if (lockoutDuration != null && lockoutDuration!.isNegative) {
      return 'Kilitleme süresi negatif olamaz';
    }
    
    if (remainingAttempts != null && remainingAttempts! < 0) {
      return 'Kalan deneme sayısı negatif olamaz';
    }
    
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthResult &&
        other.isSuccess == isSuccess &&
        other.method == method &&
        other.errorMessage == errorMessage &&
        other.lockoutDuration == lockoutDuration &&
        other.remainingAttempts == remainingAttempts &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      isSuccess,
      method,
      errorMessage,
      lockoutDuration,
      remainingAttempts,
      timestamp,
    );
  }

  @override
  String toString() {
    return 'AuthResult(isSuccess: $isSuccess, method: $method, '
           'errorMessage: $errorMessage, lockoutDuration: $lockoutDuration, '
           'remainingAttempts: $remainingAttempts, timestamp: $timestamp)';
  }
}

