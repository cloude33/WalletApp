import 'biometric_type.dart';

/// Güvenlik konfigürasyonunu temsil eden model
class SecurityConfig {
  /// PIN kodu etkin mi?
  final bool isPINEnabled;
  
  /// Biyometrik doğrulama etkin mi?
  final bool isBiometricEnabled;
  
  /// İki faktörlü doğrulama etkin mi?
  final bool isTwoFactorEnabled;
  
  /// Oturum zaman aşımı süresi
  final Duration sessionTimeout;
  
  /// Maksimum PIN deneme sayısı
  final int maxPINAttempts;
  
  /// Etkin biyometrik türler
  final List<BiometricType> enabledBiometrics;
  
  /// PIN konfigürasyonu
  final PINConfiguration pinConfig;
  
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
    this.isPINEnabled = true,
    this.isBiometricEnabled = false,
    this.isTwoFactorEnabled = false,
    this.sessionTimeout = const Duration(minutes: 5),
    this.maxPINAttempts = 5,
    this.enabledBiometrics = const [],
    required this.pinConfig,
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
      pinConfig: PINConfiguration.defaultConfig(),
      biometricConfig: BiometricConfiguration.defaultConfig(),
      sessionConfig: SessionConfiguration.defaultConfig(),
      twoFactorConfig: TwoFactorConfiguration.defaultConfig(),
    );
  }

  /// JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'isPINEnabled': isPINEnabled,
      'isBiometricEnabled': isBiometricEnabled,
      'isTwoFactorEnabled': isTwoFactorEnabled,
      'sessionTimeout': sessionTimeout.inMilliseconds,
      'maxPINAttempts': maxPINAttempts,
      'enabledBiometrics': enabledBiometrics.map((e) => e.toJson()).toList(),
      'pinConfig': pinConfig.toJson(),
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
      isPINEnabled: json['isPINEnabled'] as bool? ?? true,
      isBiometricEnabled: json['isBiometricEnabled'] as bool? ?? false,
      isTwoFactorEnabled: json['isTwoFactorEnabled'] as bool? ?? false,
      sessionTimeout: Duration(
        milliseconds: json['sessionTimeout'] as int? ?? 300000, // 5 minutes
      ),
      maxPINAttempts: json['maxPINAttempts'] as int? ?? 5,
      enabledBiometrics: (json['enabledBiometrics'] as List<dynamic>?)
          ?.map((e) => BiometricType.fromJson(e as String))
          .toList() ?? [],
      pinConfig: PINConfiguration.fromJson(
        json['pinConfig'] as Map<String, dynamic>? ?? {},
      ),
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
    bool? isPINEnabled,
    bool? isBiometricEnabled,
    bool? isTwoFactorEnabled,
    Duration? sessionTimeout,
    int? maxPINAttempts,
    List<BiometricType>? enabledBiometrics,
    PINConfiguration? pinConfig,
    BiometricConfiguration? biometricConfig,
    SessionConfiguration? sessionConfig,
    TwoFactorConfiguration? twoFactorConfig,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SecurityConfig(
      isPINEnabled: isPINEnabled ?? this.isPINEnabled,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isTwoFactorEnabled: isTwoFactorEnabled ?? this.isTwoFactorEnabled,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      maxPINAttempts: maxPINAttempts ?? this.maxPINAttempts,
      enabledBiometrics: enabledBiometrics ?? this.enabledBiometrics,
      pinConfig: pinConfig ?? this.pinConfig,
      biometricConfig: biometricConfig ?? this.biometricConfig,
      sessionConfig: sessionConfig ?? this.sessionConfig,
      twoFactorConfig: twoFactorConfig ?? this.twoFactorConfig,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Validasyon yapar
  String? validate() {
    if (maxPINAttempts <= 0) {
      return 'Maksimum PIN deneme sayısı pozitif olmalı';
    }
    
    if (maxPINAttempts > 10) {
      return 'Maksimum PIN deneme sayısı 10\'dan fazla olamaz';
    }
    
    if (sessionTimeout.inSeconds < 30) {
      return 'Oturum zaman aşımı en az 30 saniye olmalı';
    }
    
    if (sessionTimeout.inHours > 24) {
      return 'Oturum zaman aşımı 24 saatten fazla olamaz';
    }
    
    // Alt konfigürasyonları validate et
    String? pinValidation = pinConfig.validate();
    if (pinValidation != null) return pinValidation;
    
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
        other.isPINEnabled == isPINEnabled &&
        other.isBiometricEnabled == isBiometricEnabled &&
        other.isTwoFactorEnabled == isTwoFactorEnabled &&
        other.sessionTimeout == sessionTimeout &&
        other.maxPINAttempts == maxPINAttempts &&
        other.enabledBiometrics.length == enabledBiometrics.length &&
        other.pinConfig == pinConfig &&
        other.biometricConfig == biometricConfig &&
        other.sessionConfig == sessionConfig &&
        other.twoFactorConfig == twoFactorConfig;
  }

  @override
  int get hashCode {
    return Object.hash(
      isPINEnabled,
      isBiometricEnabled,
      isTwoFactorEnabled,
      sessionTimeout,
      maxPINAttempts,
      enabledBiometrics,
      pinConfig,
      biometricConfig,
      sessionConfig,
      twoFactorConfig,
    );
  }

  @override
  String toString() {
    return 'SecurityConfig(isPINEnabled: $isPINEnabled, '
           'isBiometricEnabled: $isBiometricEnabled, '
           'isTwoFactorEnabled: $isTwoFactorEnabled, '
           'sessionTimeout: $sessionTimeout, '
           'maxPINAttempts: $maxPINAttempts)';
  }
}

/// PIN konfigürasyonu
class PINConfiguration {
  /// Minimum PIN uzunluğu
  final int minLength;
  
  /// Maksimum PIN uzunluğu
  final int maxLength;
  
  /// Maksimum deneme sayısı
  final int maxAttempts;
  
  /// Kilitleme süresi
  final Duration lockoutDuration;
  
  /// Karmaşık PIN gerekli mi?
  final bool requireComplexPIN;

  const PINConfiguration({
    this.minLength = 4,
    this.maxLength = 6,
    this.maxAttempts = 5,
    this.lockoutDuration = const Duration(minutes: 5),
    this.requireComplexPIN = false,
  });

  factory PINConfiguration.defaultConfig() {
    return const PINConfiguration();
  }

  Map<String, dynamic> toJson() {
    return {
      'minLength': minLength,
      'maxLength': maxLength,
      'maxAttempts': maxAttempts,
      'lockoutDuration': lockoutDuration.inMilliseconds,
      'requireComplexPIN': requireComplexPIN,
    };
  }

  factory PINConfiguration.fromJson(Map<String, dynamic> json) {
    return PINConfiguration(
      minLength: json['minLength'] as int? ?? 4,
      maxLength: json['maxLength'] as int? ?? 6,
      maxAttempts: json['maxAttempts'] as int? ?? 5,
      lockoutDuration: Duration(
        milliseconds: json['lockoutDuration'] as int? ?? 300000,
      ),
      requireComplexPIN: json['requireComplexPIN'] as bool? ?? false,
    );
  }

  PINConfiguration copyWith({
    int? minLength,
    int? maxLength,
    int? maxAttempts,
    Duration? lockoutDuration,
    bool? requireComplexPIN,
  }) {
    return PINConfiguration(
      minLength: minLength ?? this.minLength,
      maxLength: maxLength ?? this.maxLength,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      lockoutDuration: lockoutDuration ?? this.lockoutDuration,
      requireComplexPIN: requireComplexPIN ?? this.requireComplexPIN,
    );
  }

  String? validate() {
    if (minLength < 4) {
      return 'Minimum PIN uzunluğu 4 olmalı';
    }
    
    if (maxLength > 8) {
      return 'Maksimum PIN uzunluğu 8 olmalı';
    }
    
    if (minLength > maxLength) {
      return 'Minimum uzunluk maksimum uzunluktan büyük olamaz';
    }
    
    if (maxAttempts <= 0) {
      return 'Maksimum deneme sayısı pozitif olmalı';
    }
    
    if (lockoutDuration.inSeconds < 30) {
      return 'Kilitleme süresi en az 30 saniye olmalı';
    }
    
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PINConfiguration &&
        other.minLength == minLength &&
        other.maxLength == maxLength &&
        other.maxAttempts == maxAttempts &&
        other.lockoutDuration == lockoutDuration &&
        other.requireComplexPIN == requireComplexPIN;
  }

  @override
  int get hashCode {
    return Object.hash(
      minLength,
      maxLength,
      maxAttempts,
      lockoutDuration,
      requireComplexPIN,
    );
  }
}

/// Biyometrik konfigürasyonu
class BiometricConfiguration {
  /// Fallback PIN gerekli mi?
  final bool requireFallbackPIN;
  
  /// Maksimum deneme sayısı
  final int maxAttempts;
  
  /// Zaman aşımı süresi
  final Duration timeout;

  const BiometricConfiguration({
    this.requireFallbackPIN = true,
    this.maxAttempts = 3,
    this.timeout = const Duration(seconds: 30),
  });

  factory BiometricConfiguration.defaultConfig() {
    return const BiometricConfiguration();
  }

  Map<String, dynamic> toJson() {
    return {
      'requireFallbackPIN': requireFallbackPIN,
      'maxAttempts': maxAttempts,
      'timeout': timeout.inMilliseconds,
    };
  }

  factory BiometricConfiguration.fromJson(Map<String, dynamic> json) {
    return BiometricConfiguration(
      requireFallbackPIN: json['requireFallbackPIN'] as bool? ?? true,
      maxAttempts: json['maxAttempts'] as int? ?? 3,
      timeout: Duration(
        milliseconds: json['timeout'] as int? ?? 30000,
      ),
    );
  }

  BiometricConfiguration copyWith({
    bool? requireFallbackPIN,
    int? maxAttempts,
    Duration? timeout,
  }) {
    return BiometricConfiguration(
      requireFallbackPIN: requireFallbackPIN ?? this.requireFallbackPIN,
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
        other.requireFallbackPIN == requireFallbackPIN &&
        other.maxAttempts == maxAttempts &&
        other.timeout == timeout;
  }

  @override
  int get hashCode {
    return Object.hash(requireFallbackPIN, maxAttempts, timeout);
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