import 'biometric_type.dart';

/// Güvenlik konfigürasyonunu temsil eden model
class SecurityConfig {
  /// Biyometrik doğrulama etkin mi?
  final bool isBiometricEnabled;
  
  /// İki faktörlü doğrulama etkin mi?
  final bool isTwoFactorEnabled;
  
  /// Oturum zaman aşımı süresi
  final Duration sessionTimeout;

  /// Etkin biyometrik türler
  final List<BiometricType> enabledBiometrics;

  /// Biyometrik konfigürasyonu
  final BiometricConfiguration biometricConfig;
  
  /// Oturum konfigürasyonu
  final SessionConfiguration sessionConfig;
  
  /// İki faktörlü doğrulama konfigürasyonu
  final TwoFactorConfiguration twoFactorConfig;
  
  /// Oluşturulma zamanı
  final DateTime createdAt;
  
  /// Son güncellenme zamanı
  final DateTime updatedAt;

  SecurityConfig({
    this.isBiometricEnabled = false,
    this.isTwoFactorEnabled = false,
    this.sessionTimeout = const Duration(minutes: 5),
    this.enabledBiometrics = const [],
    required this.biometricConfig,
    required this.sessionConfig,
    required this.twoFactorConfig,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Varsayılan güvenlik konfigürasyonu oluşturur
  factory SecurityConfig.defaultConfig() {
    return SecurityConfig(
      biometricConfig: BiometricConfiguration.defaultConfig(),
      sessionConfig: SessionConfiguration.defaultConfig(),
      twoFactorConfig: TwoFactorConfiguration.defaultConfig(),
    );
  }

  /// JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'isBiometricEnabled': isBiometricEnabled,
      'isTwoFactorEnabled': isTwoFactorEnabled,
      'sessionTimeout': sessionTimeout.inMilliseconds,
      'enabledBiometrics': enabledBiometrics.map((e) => e.toJson()).toList(),
      'biometricConfig': biometricConfig.toJson(),
      'sessionConfig': sessionConfig.toJson(),
      'twoFactorConfig': twoFactorConfig.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// JSON'dan oluşturur
  factory SecurityConfig.fromJson(Map<String, dynamic> json) {
    return SecurityConfig(
      isBiometricEnabled: json['isBiometricEnabled'] as bool? ?? false,
      isTwoFactorEnabled: json['isTwoFactorEnabled'] as bool? ?? false,
      sessionTimeout: Duration(
        milliseconds: json['sessionTimeout'] as int? ?? 300000, // 5 minutes
      ),
      enabledBiometrics: (json['enabledBiometrics'] as List<dynamic>?)
          ?.map((e) => BiometricType.fromJson(e as String))
          .toList() ?? [],
      biometricConfig: BiometricConfiguration.fromJson(
        json['biometricConfig'] as Map<String, dynamic>? ?? {},
      ),
      sessionConfig: SessionConfiguration.fromJson(
        json['sessionConfig'] as Map<String, dynamic>? ?? {},
      ),
      twoFactorConfig: TwoFactorConfiguration.fromJson(
        json['twoFactorConfig'] as Map<String, dynamic>? ?? {},
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Kopya oluşturur
  SecurityConfig copyWith({
    bool? isBiometricEnabled,
    bool? isTwoFactorEnabled,
    Duration? sessionTimeout,
    List<BiometricType>? enabledBiometrics,
    BiometricConfiguration? biometricConfig,
    SessionConfiguration? sessionConfig,
    TwoFactorConfiguration? twoFactorConfig,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SecurityConfig(
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isTwoFactorEnabled: isTwoFactorEnabled ?? this.isTwoFactorEnabled,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      enabledBiometrics: enabledBiometrics ?? this.enabledBiometrics,
      biometricConfig: biometricConfig ?? this.biometricConfig,
      sessionConfig: sessionConfig ?? this.sessionConfig,
      twoFactorConfig: twoFactorConfig ?? this.twoFactorConfig,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Validasyon yapar
  String? validate() {
    if (sessionTimeout.inSeconds < 30) {
      return 'Oturum zaman aşımı en az 30 saniye olmalı';
    }
    
    if (sessionTimeout.inHours > 24) {
      return 'Oturum zaman aşımı 24 saatten fazla olamaz';
    }

    if (!isBiometricEnabled && !isTwoFactorEnabled) {
      return 'En az bir kimlik doğrulama yöntemi etkin olmalıdır';
    }

    if (isBiometricEnabled && enabledBiometrics.isEmpty) {
      return 'Biyometrik doğrulama etkinken en az bir biyometrik tür seçilmelidir';
    }

    if (isTwoFactorEnabled && 
        !twoFactorConfig.enableSMS && 
        !twoFactorConfig.enableEmail && 
        !twoFactorConfig.enableTOTP) {
      return 'İki faktörlü doğrulama etkinken en az bir yöntem (SMS, Email, TOTP) seçilmelidir';
    }
    
    // Alt konfigürasyonları validate et
    String? biometricValidation = biometricConfig.validate();
    if (biometricValidation != null) return biometricValidation;
    
    String? sessionValidation = sessionConfig.validate();
    if (sessionValidation != null) return sessionValidation;
    
    String? twoFactorValidation = twoFactorConfig.validate();
    if (twoFactorValidation != null) return twoFactorValidation;
    
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SecurityConfig &&
        other.isBiometricEnabled == isBiometricEnabled &&
        other.isTwoFactorEnabled == isTwoFactorEnabled &&
        other.sessionTimeout == sessionTimeout &&
        other.enabledBiometrics.length == enabledBiometrics.length &&
        other.biometricConfig == biometricConfig &&
        other.sessionConfig == sessionConfig &&
        other.twoFactorConfig == twoFactorConfig;
  }

  @override
  int get hashCode {
    return Object.hash(
      isBiometricEnabled,
      isTwoFactorEnabled,
      sessionTimeout,
      enabledBiometrics,
      biometricConfig,
      sessionConfig,
      twoFactorConfig,
    );
  }

  @override
  String toString() {
    return 'SecurityConfig('
           'isBiometricEnabled: $isBiometricEnabled, '
           'isTwoFactorEnabled: $isTwoFactorEnabled, '
           'sessionTimeout: $sessionTimeout)';
  }
}


/// Biyometrik konfigürasyonu
class BiometricConfiguration {
  /// Fallback şifre gerekli mi?
  final bool requireFallbackPassword;
  
  /// Maksimum deneme sayısı
  final int maxAttempts;
  
  /// Zaman aşımı süresi
  final Duration timeout;

  const BiometricConfiguration({
    this.requireFallbackPassword = true,
    this.maxAttempts = 3,
    this.timeout = const Duration(seconds: 30),
  });

  factory BiometricConfiguration.defaultConfig() {
    return const BiometricConfiguration();
  }

  Map<String, dynamic> toJson() {
    return {
      'requireFallbackPassword': requireFallbackPassword,
      'maxAttempts': maxAttempts,
      'timeout': timeout.inMilliseconds,
    };
  }

  factory BiometricConfiguration.fromJson(Map<String, dynamic> json) {
    return BiometricConfiguration(
      requireFallbackPassword: json['requireFallbackPassword'] as bool? ?? true,
      maxAttempts: json['maxAttempts'] as int? ?? 3,
      timeout: Duration(
        milliseconds: json['timeout'] as int? ?? 30000,
      ),
    );
  }

  BiometricConfiguration copyWith({
    bool? requireFallbackPassword,
    int? maxAttempts,
    Duration? timeout,
  }) {
    return BiometricConfiguration(
      requireFallbackPassword: requireFallbackPassword ?? this.requireFallbackPassword,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      timeout: timeout ?? this.timeout,
    );
  }

  String? validate() {
    if (maxAttempts <= 0) {
      return 'Maksimum deneme sayısı pozitif olmalı';
    }
    
    if (timeout.inSeconds < 10) {
      return 'Zaman aşımı en az 10 saniye olmalı';
    }
    
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BiometricConfiguration &&
        other.requireFallbackPassword == requireFallbackPassword &&
        other.maxAttempts == maxAttempts &&
        other.timeout == timeout;
  }

  @override
  int get hashCode {
    return Object.hash(requireFallbackPassword, maxAttempts, timeout);
  }
}

/// Oturum konfigürasyonu
class SessionConfiguration {
  /// Oturum zaman aşımı
  final Duration sessionTimeout;
  
  /// Hassas işlem zaman aşımı
  final Duration sensitiveOperationTimeout;
  
  /// Arka plan kilitleme etkin mi?
  final bool enableBackgroundLock;
  
  /// Arka plan kilitleme süresi
  final Duration backgroundLockDelay;

  const SessionConfiguration({
    this.sessionTimeout = const Duration(minutes: 5),
    this.sensitiveOperationTimeout = const Duration(minutes: 2),
    this.enableBackgroundLock = true,
    this.backgroundLockDelay = const Duration(seconds: 30),
  });

  factory SessionConfiguration.defaultConfig() {
    return const SessionConfiguration();
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionTimeout': sessionTimeout.inMilliseconds,
      'sensitiveOperationTimeout': sensitiveOperationTimeout.inMilliseconds,
      'enableBackgroundLock': enableBackgroundLock,
      'backgroundLockDelay': backgroundLockDelay.inMilliseconds,
    };
  }

  factory SessionConfiguration.fromJson(Map<String, dynamic> json) {
    return SessionConfiguration(
      sessionTimeout: Duration(
        milliseconds: json['sessionTimeout'] as int? ?? 300000,
      ),
      sensitiveOperationTimeout: Duration(
        milliseconds: json['sensitiveOperationTimeout'] as int? ?? 120000,
      ),
      enableBackgroundLock: json['enableBackgroundLock'] as bool? ?? true,
      backgroundLockDelay: Duration(
        milliseconds: json['backgroundLockDelay'] as int? ?? 30000,
      ),
    );
  }

  SessionConfiguration copyWith({
    Duration? sessionTimeout,
    Duration? sensitiveOperationTimeout,
    bool? enableBackgroundLock,
    Duration? backgroundLockDelay,
  }) {
    return SessionConfiguration(
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      sensitiveOperationTimeout: sensitiveOperationTimeout ?? this.sensitiveOperationTimeout,
      enableBackgroundLock: enableBackgroundLock ?? this.enableBackgroundLock,
      backgroundLockDelay: backgroundLockDelay ?? this.backgroundLockDelay,
    );
  }

  String? validate() {
    if (sessionTimeout.inSeconds < 30) {
      return 'Oturum zaman aşımı en az 30 saniye olmalı';
    }
    
    if (sensitiveOperationTimeout.inSeconds < 30) {
      return 'Hassas işlem zaman aşımı en az 30 saniye olmalı';
    }
    
    if (backgroundLockDelay.inSeconds < 0) {
      return 'Arka plan kilitleme gecikmesi negatif olamaz';
    }
    
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionConfiguration &&
        other.sessionTimeout == sessionTimeout &&
        other.sensitiveOperationTimeout == sensitiveOperationTimeout &&
        other.enableBackgroundLock == enableBackgroundLock &&
        other.backgroundLockDelay == backgroundLockDelay;
  }

  @override
  int get hashCode {
    return Object.hash(
      sessionTimeout,
      sensitiveOperationTimeout,
      enableBackgroundLock,
      backgroundLockDelay,
    );
  }
}

/// İki faktörlü doğrulama konfigürasyonu
class TwoFactorConfiguration {
  /// SMS etkin mi?
  final bool enableSMS;
  
  /// Email etkin mi?
  final bool enableEmail;
  
  /// TOTP etkin mi?
  final bool enableTOTP;
  
  /// Backup kodları etkin mi?
  final bool enableBackupCodes;
  
  /// Kod geçerlilik süresi
  final Duration codeValidityDuration;

  const TwoFactorConfiguration({
    this.enableSMS = false,
    this.enableEmail = false,
    this.enableTOTP = false,
    this.enableBackupCodes = false,
    this.codeValidityDuration = const Duration(minutes: 5),
  });

  factory TwoFactorConfiguration.defaultConfig() {
    return const TwoFactorConfiguration();
  }

  Map<String, dynamic> toJson() {
    return {
      'enableSMS': enableSMS,
      'enableEmail': enableEmail,
      'enableTOTP': enableTOTP,
      'enableBackupCodes': enableBackupCodes,
      'codeValidityDuration': codeValidityDuration.inMilliseconds,
    };
  }

  factory TwoFactorConfiguration.fromJson(Map<String, dynamic> json) {
    return TwoFactorConfiguration(
      enableSMS: json['enableSMS'] as bool? ?? false,
      enableEmail: json['enableEmail'] as bool? ?? false,
      enableTOTP: json['enableTOTP'] as bool? ?? false,
      enableBackupCodes: json['enableBackupCodes'] as bool? ?? false,
      codeValidityDuration: Duration(
        milliseconds: json['codeValidityDuration'] as int? ?? 300000,
      ),
    );
  }

  TwoFactorConfiguration copyWith({
    bool? enableSMS,
    bool? enableEmail,
    bool? enableTOTP,
    bool? enableBackupCodes,
    Duration? codeValidityDuration,
  }) {
    return TwoFactorConfiguration(
      enableSMS: enableSMS ?? this.enableSMS,
      enableEmail: enableEmail ?? this.enableEmail,
      enableTOTP: enableTOTP ?? this.enableTOTP,
      enableBackupCodes: enableBackupCodes ?? this.enableBackupCodes,
      codeValidityDuration: codeValidityDuration ?? this.codeValidityDuration,
    );
  }

  String? validate() {
    if (codeValidityDuration.inMinutes < 1) {
      return 'Kod geçerlilik süresi en az 1 dakika olmalı';
    }
    
    if (codeValidityDuration.inMinutes > 30) {
      return 'Kod geçerlilik süresi 30 dakikadan fazla olamaz';
    }
    
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TwoFactorConfiguration &&
        other.enableSMS == enableSMS &&
        other.enableEmail == enableEmail &&
        other.enableTOTP == enableTOTP &&
        other.enableBackupCodes == enableBackupCodes &&
        other.codeValidityDuration == codeValidityDuration;
  }

  @override
  int get hashCode {
    return Object.hash(
      enableSMS,
      enableEmail,
      enableTOTP,
      enableBackupCodes,
      codeValidityDuration,
    );
  }
}
