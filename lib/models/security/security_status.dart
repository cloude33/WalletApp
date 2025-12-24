/// Güvenlik durumunu temsil eden model
class SecurityStatus {
  /// Cihaz güvenli mi?
  final bool isDeviceSecure;
  
  /// Root/jailbreak tespit edildi mi?
  final bool isRootDetected;
  
  /// Ekran görüntüsü engelleme aktif mi?
  final bool isScreenshotBlocked;
  
  /// Arka plan bulanıklaştırma aktif mi?
  final bool isBackgroundBlurEnabled;
  
  /// Clipboard güvenlik aktif mi?
  final bool isClipboardSecurityEnabled;
  
  /// Güvenlik seviyesi
  final SecurityLevel securityLevel;
  
  /// Son güvenlik kontrolü zamanı
  final DateTime lastSecurityCheck;
  
  /// Güvenlik uyarıları
  final List<SecurityWarning> warnings;
  
  /// Ek metadata
  final Map<String, dynamic>? metadata;

  SecurityStatus({
    required this.isDeviceSecure,
    required this.isRootDetected,
    required this.isScreenshotBlocked,
    required this.isBackgroundBlurEnabled,
    required this.isClipboardSecurityEnabled,
    required this.securityLevel,
    DateTime? lastSecurityCheck,
    this.warnings = const [],
    this.metadata,
  }) : lastSecurityCheck = lastSecurityCheck ?? DateTime.now();

  /// Güvenlik durumu özetini oluşturur
  factory SecurityStatus.summary({
    required bool isDeviceSecure,
    required bool isRootDetected,
    List<SecurityWarning> warnings = const [],
  }) {
    SecurityLevel level = SecurityLevel.high;
    
    if (isRootDetected) {
      level = SecurityLevel.critical;
    } else if (!isDeviceSecure || warnings.isNotEmpty) {
      level = SecurityLevel.medium;
    }
    
    return SecurityStatus(
      isDeviceSecure: isDeviceSecure,
      isRootDetected: isRootDetected,
      isScreenshotBlocked: false,
      isBackgroundBlurEnabled: false,
      isClipboardSecurityEnabled: false,
      securityLevel: level,
      warnings: warnings,
    );
  }

  /// JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'isDeviceSecure': isDeviceSecure,
      'isRootDetected': isRootDetected,
      'isScreenshotBlocked': isScreenshotBlocked,
      'isBackgroundBlurEnabled': isBackgroundBlurEnabled,
      'isClipboardSecurityEnabled': isClipboardSecurityEnabled,
      'securityLevel': securityLevel.toJson(),
      'lastSecurityCheck': lastSecurityCheck.toIso8601String(),
      'warnings': warnings.map((w) => w.toJson()).toList(),
      'metadata': metadata,
    };
  }

  /// JSON'dan oluşturur
  factory SecurityStatus.fromJson(Map<String, dynamic> json) {
    return SecurityStatus(
      isDeviceSecure: json['isDeviceSecure'] as bool? ?? false,
      isRootDetected: json['isRootDetected'] as bool? ?? false,
      isScreenshotBlocked: json['isScreenshotBlocked'] as bool? ?? false,
      isBackgroundBlurEnabled: json['isBackgroundBlurEnabled'] as bool? ?? false,
      isClipboardSecurityEnabled: json['isClipboardSecurityEnabled'] as bool? ?? false,
      securityLevel: SecurityLevel.fromJson(json['securityLevel'] as String? ?? 'medium'),
      lastSecurityCheck: json['lastSecurityCheck'] != null
          ? DateTime.parse(json['lastSecurityCheck'] as String)
          : DateTime.now(),
      warnings: (json['warnings'] as List<dynamic>?)
          ?.map((w) => SecurityWarning.fromJson(w as Map<String, dynamic>))
          .toList() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Kopya oluşturur
  SecurityStatus copyWith({
    bool? isDeviceSecure,
    bool? isRootDetected,
    bool? isScreenshotBlocked,
    bool? isBackgroundBlurEnabled,
    bool? isClipboardSecurityEnabled,
    SecurityLevel? securityLevel,
    DateTime? lastSecurityCheck,
    List<SecurityWarning>? warnings,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityStatus(
      isDeviceSecure: isDeviceSecure ?? this.isDeviceSecure,
      isRootDetected: isRootDetected ?? this.isRootDetected,
      isScreenshotBlocked: isScreenshotBlocked ?? this.isScreenshotBlocked,
      isBackgroundBlurEnabled: isBackgroundBlurEnabled ?? this.isBackgroundBlurEnabled,
      isClipboardSecurityEnabled: isClipboardSecurityEnabled ?? this.isClipboardSecurityEnabled,
      securityLevel: securityLevel ?? this.securityLevel,
      lastSecurityCheck: lastSecurityCheck ?? this.lastSecurityCheck,
      warnings: warnings ?? this.warnings,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Güvenlik durumu iyi mi?
  bool get isSecure {
    return isDeviceSecure && 
           !isRootDetected && 
           securityLevel != SecurityLevel.critical &&
           warnings.where((w) => w.severity == SecurityWarningSeverity.critical).isEmpty;
  }

  /// Kritik uyarı var mı?
  bool get hasCriticalWarnings {
    return warnings.any((w) => w.severity == SecurityWarningSeverity.critical);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SecurityStatus &&
        other.isDeviceSecure == isDeviceSecure &&
        other.isRootDetected == isRootDetected &&
        other.isScreenshotBlocked == isScreenshotBlocked &&
        other.isBackgroundBlurEnabled == isBackgroundBlurEnabled &&
        other.isClipboardSecurityEnabled == isClipboardSecurityEnabled &&
        other.securityLevel == securityLevel &&
        other.lastSecurityCheck == lastSecurityCheck;
  }

  @override
  int get hashCode {
    return Object.hash(
      isDeviceSecure,
      isRootDetected,
      isScreenshotBlocked,
      isBackgroundBlurEnabled,
      isClipboardSecurityEnabled,
      securityLevel,
      lastSecurityCheck,
    );
  }

  @override
  String toString() {
    return 'SecurityStatus(isDeviceSecure: $isDeviceSecure, '
           'isRootDetected: $isRootDetected, '
           'securityLevel: $securityLevel, '
           'warnings: ${warnings.length})';
  }
}

/// Güvenlik seviyesi
enum SecurityLevel {
  low,
  medium,
  high,
  critical;

  String toJson() => name;
  
  static SecurityLevel fromJson(String json) {
    return SecurityLevel.values.firstWhere(
      (level) => level.name == json,
      orElse: () => SecurityLevel.medium,
    );
  }

  /// Güvenlik seviyesi açıklaması
  String get description {
    switch (this) {
      case SecurityLevel.low:
        return 'Düşük güvenlik seviyesi';
      case SecurityLevel.medium:
        return 'Orta güvenlik seviyesi';
      case SecurityLevel.high:
        return 'Yüksek güvenlik seviyesi';
      case SecurityLevel.critical:
        return 'Kritik güvenlik riski';
    }
  }

  /// Güvenlik seviyesi rengi
  int get color {
    switch (this) {
      case SecurityLevel.low:
        return 0xFFFF5722; // Red
      case SecurityLevel.medium:
        return 0xFFFF9800; // Orange
      case SecurityLevel.high:
        return 0xFF4CAF50; // Green
      case SecurityLevel.critical:
        return 0xFFD32F2F; // Dark Red
    }
  }
}

/// Güvenlik uyarısı
class SecurityWarning {
  /// Uyarı türü
  final SecurityWarningType type;
  
  /// Uyarı şiddeti
  final SecurityWarningSeverity severity;
  
  /// Uyarı mesajı
  final String message;
  
  /// Uyarı açıklaması
  final String? description;
  
  /// Uyarı zamanı
  final DateTime timestamp;
  
  /// Ek bilgiler
  final Map<String, dynamic>? metadata;

  SecurityWarning({
    required this.type,
    required this.severity,
    required this.message,
    this.description,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  /// JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'type': type.toJson(),
      'severity': severity.toJson(),
      'message': message,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// JSON'dan oluşturur
  factory SecurityWarning.fromJson(Map<String, dynamic> json) {
    return SecurityWarning(
      type: SecurityWarningType.fromJson(json['type'] as String? ?? 'unknown'),
      severity: SecurityWarningSeverity.fromJson(json['severity'] as String? ?? 'medium'),
      message: json['message'] as String? ?? '',
      description: json['description'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SecurityWarning &&
        other.type == type &&
        other.severity == severity &&
        other.message == message &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(type, severity, message, timestamp);
  }

  @override
  String toString() {
    return 'SecurityWarning(type: $type, severity: $severity, message: $message)';
  }
}

/// Güvenlik uyarısı türü
enum SecurityWarningType {
  rootDetected,
  debuggerDetected,
  emulatorDetected,
  hookDetected,
  tamperingDetected,
  suspiciousActivity,
  weakSecurity,
  unknown;

  String toJson() => name;
  
  static SecurityWarningType fromJson(String json) {
    return SecurityWarningType.values.firstWhere(
      (type) => type.name == json,
      orElse: () => SecurityWarningType.unknown,
    );
  }
}

/// Güvenlik uyarısı şiddeti
enum SecurityWarningSeverity {
  low,
  medium,
  high,
  critical;

  String toJson() => name;
  
  static SecurityWarningSeverity fromJson(String json) {
    return SecurityWarningSeverity.values.firstWhere(
      (severity) => severity.name == json,
      orElse: () => SecurityWarningSeverity.medium,
    );
  }
}