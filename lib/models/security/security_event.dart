/// Güvenlik olayını temsil eden model
class SecurityEvent {
  /// Olay türü
  final SecurityEventType type;
  
  /// Olay zamanı
  final DateTime timestamp;
  
  /// Kullanıcı ID'si (varsa)
  final String? userId;
  
  /// Olay açıklaması
  final String description;
  
  /// Olay şiddeti
  final SecurityEventSeverity severity;
  
  /// Olay kaynağı
  final String source;
  
  /// Ek metadata bilgileri
  final Map<String, dynamic> metadata;
  
  /// Olay ID'si
  final String eventId;

  SecurityEvent({
    required this.type,
    DateTime? timestamp,
    this.userId,
    required this.description,
    required this.severity,
    required this.source,
    this.metadata = const {},
    String? eventId,
  }) : timestamp = timestamp ?? DateTime.now(),
       eventId = eventId ?? _generateEventId();

  /// Olay ID'si oluşturur
  static String _generateEventId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Biyometrik kayıt olayı
  factory SecurityEvent.biometricEnrolled({
    String? userId,
    required String biometricType,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityEvent(
      type: SecurityEventType.biometricEnrolled,
      userId: userId,
      description: 'Biyometrik doğrulama kaydedildi: $biometricType',
      severity: SecurityEventSeverity.info,
      source: 'BiometricService',
      metadata: {
        'biometricType': biometricType,
        ...?metadata,
      },
    );
  }

  /// Biyometrik doğrulama başarılı olayı
  factory SecurityEvent.biometricVerified({
    String? userId,
    required String biometricType,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityEvent(
      type: SecurityEventType.biometricVerified,
      userId: userId,
      description: 'Biyometrik doğrulama başarılı: $biometricType',
      severity: SecurityEventSeverity.info,
      source: 'BiometricService',
      metadata: {
        'biometricType': biometricType,
        ...?metadata,
      },
    );
  }

  /// Biyometrik doğrulama başarısız olayı
  factory SecurityEvent.biometricFailed({
    String? userId,
    required String biometricType,
    String? reason,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityEvent(
      type: SecurityEventType.biometricFailed,
      userId: userId,
      description: 'Biyometrik doğrulama başarısız: $biometricType${reason != null ? ' ($reason)' : ''}',
      severity: SecurityEventSeverity.warning,
      source: 'BiometricService',
      metadata: {
        'biometricType': biometricType,
        'reason': reason,
        ...?metadata,
      },
    );
  }

  /// Hesap kilitleme olayı
  factory SecurityEvent.accountLocked({
    String? userId,
    required Duration lockoutDuration,
    required String reason,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityEvent(
      type: SecurityEventType.accountLocked,
      userId: userId,
      description: 'Hesap kilitlendi: $reason (süre: ${lockoutDuration.inMinutes} dakika)',
      severity: SecurityEventSeverity.error,
      source: 'SecurityService',
      metadata: {
        'lockoutDuration': lockoutDuration.inMilliseconds,
        'reason': reason,
        ...?metadata,
      },
    );
  }

  /// Oturum başlatma olayı
  factory SecurityEvent.sessionStarted({
    String? userId,
    required String authMethod,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityEvent(
      type: SecurityEventType.sessionStarted,
      userId: userId,
      description: 'Oturum başlatıldı: $authMethod',
      severity: SecurityEventSeverity.info,
      source: 'SessionManager',
      metadata: {
        'authMethod': authMethod,
        ...?metadata,
      },
    );
  }

  /// Oturum sonlandırma olayı
  factory SecurityEvent.sessionEnded({
    String? userId,
    required String reason,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityEvent(
      type: SecurityEventType.sessionEnded,
      userId: userId,
      description: 'Oturum sonlandırıldı: $reason',
      severity: SecurityEventSeverity.info,
      source: 'SessionManager',
      metadata: {
        'reason': reason,
        ...?metadata,
      },
    );
  }

  /// Şüpheli aktivite olayı
  factory SecurityEvent.suspiciousActivity({
    String? userId,
    required String activity,
    required String details,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityEvent(
      type: SecurityEventType.suspiciousActivity,
      userId: userId,
      description: 'Şüpheli aktivite tespit edildi: $activity',
      severity: SecurityEventSeverity.critical,
      source: 'SecurityService',
      metadata: {
        'activity': activity,
        'details': details,
        ...?metadata,
      },
    );
  }

  /// Root/jailbreak tespit olayı
  factory SecurityEvent.rootDetected({
    String? userId,
    required String details,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityEvent(
      type: SecurityEventType.rootDetected,
      userId: userId,
      description: 'Root/jailbreak tespit edildi',
      severity: SecurityEventSeverity.critical,
      source: 'SecurityService',
      metadata: {
        'details': details,
        ...?metadata,
      },
    );
  }

  /// Güvenlik ayarları değişiklik olayı
  factory SecurityEvent.securitySettingsChanged({
    String? userId,
    required String setting,
    required String oldValue,
    required String newValue,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityEvent(
      type: SecurityEventType.securitySettingsChanged,
      userId: userId,
      description: 'Güvenlik ayarı değiştirildi: $setting ($oldValue -> $newValue)',
      severity: SecurityEventSeverity.info,
      source: 'SecurityService',
      metadata: {
        'setting': setting,
        'oldValue': oldValue,
        'newValue': newValue,
        ...?metadata,
      },
    );
  }

  /// JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'type': type.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'description': description,
      'severity': severity.toJson(),
      'source': source,
      'metadata': metadata,
    };
  }

  /// JSON'dan oluşturur
  factory SecurityEvent.fromJson(Map<String, dynamic> json) {
    return SecurityEvent(
      eventId: json['eventId'] as String? ?? _generateEventId(),
      type: SecurityEventType.fromJson(json['type'] as String? ?? 'unknown'),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      userId: json['userId'] as String?,
      description: json['description'] as String? ?? '',
      severity: SecurityEventSeverity.fromJson(json['severity'] as String? ?? 'info'),
      source: json['source'] as String? ?? 'Unknown',
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Kopya oluşturur
  SecurityEvent copyWith({
    SecurityEventType? type,
    DateTime? timestamp,
    String? userId,
    String? description,
    SecurityEventSeverity? severity,
    String? source,
    Map<String, dynamic>? metadata,
    String? eventId,
  }) {
    return SecurityEvent(
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
      eventId: eventId ?? this.eventId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SecurityEvent &&
        other.eventId == eventId &&
        other.type == type &&
        other.timestamp == timestamp &&
        other.userId == userId &&
        other.description == description &&
        other.severity == severity &&
        other.source == source;
  }

  @override
  int get hashCode {
    return Object.hash(
      eventId,
      type,
      timestamp,
      userId,
      description,
      severity,
      source,
    );
  }

  @override
  String toString() {
    return 'SecurityEvent(eventId: $eventId, type: $type, '
           'severity: $severity, description: $description)';
  }
}

/// Güvenlik olayı türü
enum SecurityEventType {
  pinCreated,
  pinChanged,
  pinVerified,
  pinFailed,
  biometricEnrolled,
  biometricVerified,
  biometricFailed,
  accountLocked,
  sessionStarted,
  sessionEnded,
  suspiciousActivity,
  rootDetected,
  securitySettingsChanged,
  screenshotBlocked,
  clipboardBlocked,
  unknown;

  String toJson() => name;
  
  static SecurityEventType fromJson(String json) {
    return SecurityEventType.values.firstWhere(
      (type) => type.name == json,
      orElse: () => SecurityEventType.unknown,
    );
  }

  /// Olay türü açıklaması
  String get description {
    switch (this) {
      case SecurityEventType.pinCreated:
        return 'PIN Oluşturuldu';
      case SecurityEventType.pinChanged:
        return 'PIN Değiştirildi';
      case SecurityEventType.pinVerified:
        return 'PIN Doğrulandı';
      case SecurityEventType.pinFailed:
        return 'PIN Başarısız';
      case SecurityEventType.biometricEnrolled:
        return 'Biyometrik Kaydedildi';
      case SecurityEventType.biometricVerified:
        return 'Biyometrik Doğrulandı';
      case SecurityEventType.biometricFailed:
        return 'Biyometrik Başarısız';
      case SecurityEventType.accountLocked:
        return 'Hesap Kilitlendi';
      case SecurityEventType.sessionStarted:
        return 'Oturum Başlatıldı';
      case SecurityEventType.sessionEnded:
        return 'Oturum Sonlandırıldı';
      case SecurityEventType.suspiciousActivity:
        return 'Şüpheli Aktivite';
      case SecurityEventType.rootDetected:
        return 'Root Tespit Edildi';
      case SecurityEventType.securitySettingsChanged:
        return 'Güvenlik Ayarları Değişti';
      case SecurityEventType.screenshotBlocked:
        return 'Ekran Görüntüsü Engellendi';
      case SecurityEventType.clipboardBlocked:
        return 'Clipboard Engellendi';
      case SecurityEventType.unknown:
        return 'Bilinmeyen Olay';
    }
  }
}

/// Güvenlik olayı şiddeti
enum SecurityEventSeverity {
  info,
  warning,
  error,
  critical;

  String toJson() => name;
  
  static SecurityEventSeverity fromJson(String json) {
    return SecurityEventSeverity.values.firstWhere(
      (severity) => severity.name == json,
      orElse: () => SecurityEventSeverity.info,
    );
  }

  /// Şiddet seviyesi rengi
  int get color {
    switch (this) {
      case SecurityEventSeverity.info:
        return 0xFF2196F3; // Blue
      case SecurityEventSeverity.warning:
        return 0xFFFF9800; // Orange
      case SecurityEventSeverity.error:
        return 0xFFFF5722; // Red
      case SecurityEventSeverity.critical:
        return 0xFFD32F2F; // Dark Red
    }
  }

  /// Şiddet seviyesi açıklaması
  String get description {
    switch (this) {
      case SecurityEventSeverity.info:
        return 'Bilgi';
      case SecurityEventSeverity.warning:
        return 'Uyarı';
      case SecurityEventSeverity.error:
        return 'Hata';
      case SecurityEventSeverity.critical:
        return 'Kritik';
    }
  }
}