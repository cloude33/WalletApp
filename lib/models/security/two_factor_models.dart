

/// Two-factor authentication configuration model
class TwoFactorConfig {
  /// Whether two-factor authentication is enabled
  final bool isEnabled;
  
  /// Whether SMS verification is enabled
  final bool isSMSEnabled;
  
  /// Whether email verification is enabled
  final bool isEmailEnabled;
  
  /// Whether TOTP (Time-based One-Time Password) is enabled
  final bool isTOTPEnabled;
  
  /// Phone number for SMS verification
  final String? phoneNumber;
  
  /// Email address for email verification
  final String? emailAddress;
  
  /// TOTP secret key (base32 encoded)
  final String? totpSecret;
  
  /// TOTP issuer name
  final String? totpIssuer;
  
  /// TOTP account name
  final String? totpAccountName;
  
  /// Backup codes for recovery
  final List<String> backupCodes;
  
  /// Used backup codes
  final List<String> usedBackupCodes;
  
  /// Creation timestamp
  final DateTime createdAt;
  
  /// Last update timestamp
  final DateTime updatedAt;

  const TwoFactorConfig({
    this.isEnabled = false,
    this.isSMSEnabled = false,
    this.isEmailEnabled = false,
    this.isTOTPEnabled = false,
    this.phoneNumber,
    this.emailAddress,
    this.totpSecret,
    this.totpIssuer,
    this.totpAccountName,
    this.backupCodes = const [],
    this.usedBackupCodes = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create default configuration
  factory TwoFactorConfig.defaultConfig() {
    final now = DateTime.now();
    return TwoFactorConfig(
      createdAt: now,
      updatedAt: now,
    );
  }

  /// JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'isSMSEnabled': isSMSEnabled,
      'isEmailEnabled': isEmailEnabled,
      'isTOTPEnabled': isTOTPEnabled,
      'phoneNumber': phoneNumber,
      'emailAddress': emailAddress,
      'totpSecret': totpSecret,
      'totpIssuer': totpIssuer,
      'totpAccountName': totpAccountName,
      'backupCodes': backupCodes,
      'usedBackupCodes': usedBackupCodes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// JSON deserialization
  factory TwoFactorConfig.fromJson(Map<String, dynamic> json) {
    return TwoFactorConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      isSMSEnabled: json['isSMSEnabled'] as bool? ?? false,
      isEmailEnabled: json['isEmailEnabled'] as bool? ?? false,
      isTOTPEnabled: json['isTOTPEnabled'] as bool? ?? false,
      phoneNumber: json['phoneNumber'] as String?,
      emailAddress: json['emailAddress'] as String?,
      totpSecret: json['totpSecret'] as String?,
      totpIssuer: json['totpIssuer'] as String?,
      totpAccountName: json['totpAccountName'] as String?,
      backupCodes: List<String>.from(json['backupCodes'] as List? ?? []),
      usedBackupCodes: List<String>.from(json['usedBackupCodes'] as List? ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Create a copy with updated fields
  TwoFactorConfig copyWith({
    bool? isEnabled,
    bool? isSMSEnabled,
    bool? isEmailEnabled,
    bool? isTOTPEnabled,
    String? phoneNumber,
    String? emailAddress,
    String? totpSecret,
    String? totpIssuer,
    String? totpAccountName,
    List<String>? backupCodes,
    List<String>? usedBackupCodes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TwoFactorConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      isSMSEnabled: isSMSEnabled ?? this.isSMSEnabled,
      isEmailEnabled: isEmailEnabled ?? this.isEmailEnabled,
      isTOTPEnabled: isTOTPEnabled ?? this.isTOTPEnabled,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emailAddress: emailAddress ?? this.emailAddress,
      totpSecret: totpSecret ?? this.totpSecret,
      totpIssuer: totpIssuer ?? this.totpIssuer,
      totpAccountName: totpAccountName ?? this.totpAccountName,
      backupCodes: backupCodes ?? this.backupCodes,
      usedBackupCodes: usedBackupCodes ?? this.usedBackupCodes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TwoFactorConfig &&
        other.isEnabled == isEnabled &&
        other.isSMSEnabled == isSMSEnabled &&
        other.isEmailEnabled == isEmailEnabled &&
        other.isTOTPEnabled == isTOTPEnabled &&
        other.phoneNumber == phoneNumber &&
        other.emailAddress == emailAddress &&
        other.totpSecret == totpSecret &&
        other.totpIssuer == totpIssuer &&
        other.totpAccountName == totpAccountName;
  }

  @override
  int get hashCode {
    return Object.hash(
      isEnabled,
      isSMSEnabled,
      isEmailEnabled,
      isTOTPEnabled,
      phoneNumber,
      emailAddress,
      totpSecret,
      totpIssuer,
      totpAccountName,
    );
  }

  @override
  String toString() {
    return 'TwoFactorConfig(isEnabled: $isEnabled, '
           'isSMSEnabled: $isSMSEnabled, '
           'isEmailEnabled: $isEmailEnabled, '
           'isTOTPEnabled: $isTOTPEnabled)';
  }
}

/// Two-factor authentication verification result
class TwoFactorVerificationResult {
  /// Whether verification was successful
  final bool isSuccess;
  
  /// Verification method used
  final TwoFactorMethod method;
  
  /// Error message if verification failed
  final String? errorMessage;
  
  /// Remaining attempts before lockout
  final int? remainingAttempts;
  
  /// Lockout duration if account is locked
  final Duration? lockoutDuration;
  
  /// Additional metadata
  final Map<String, dynamic>? metadata;

  const TwoFactorVerificationResult({
    required this.isSuccess,
    required this.method,
    this.errorMessage,
    this.remainingAttempts,
    this.lockoutDuration,
    this.metadata,
  });

  /// Create successful result
  factory TwoFactorVerificationResult.success(TwoFactorMethod method) {
    return TwoFactorVerificationResult(
      isSuccess: true,
      method: method,
    );
  }

  /// Create failed result
  factory TwoFactorVerificationResult.failure(
    TwoFactorMethod method,
    String errorMessage, {
    int? remainingAttempts,
    Duration? lockoutDuration,
    Map<String, dynamic>? metadata,
  }) {
    return TwoFactorVerificationResult(
      isSuccess: false,
      method: method,
      errorMessage: errorMessage,
      remainingAttempts: remainingAttempts,
      lockoutDuration: lockoutDuration,
      metadata: metadata,
    );
  }

  @override
  String toString() {
    return 'TwoFactorVerificationResult(isSuccess: $isSuccess, '
           'method: $method, errorMessage: $errorMessage)';
  }
}

/// Two-factor authentication methods
enum TwoFactorMethod {
  /// SMS verification
  sms,
  
  /// Email verification
  email,
  
  /// TOTP (Time-based One-Time Password)
  totp,
  
  /// Backup code
  backupCode;

  /// Get display name for the method
  String get displayName {
    switch (this) {
      case TwoFactorMethod.sms:
        return 'SMS Doğrulama';
      case TwoFactorMethod.email:
        return 'E-posta Doğrulama';
      case TwoFactorMethod.totp:
        return 'Authenticator Uygulaması';
      case TwoFactorMethod.backupCode:
        return 'Yedek Kod';
    }
  }

  /// Get icon name for the method
  String get iconName {
    switch (this) {
      case TwoFactorMethod.sms:
        return 'sms';
      case TwoFactorMethod.email:
        return 'email';
      case TwoFactorMethod.totp:
        return 'security';
      case TwoFactorMethod.backupCode:
        return 'backup';
    }
  }
}

/// Two-factor authentication setup result
class TwoFactorSetupResult {
  /// Whether setup was successful
  final bool isSuccess;
  
  /// Setup method
  final TwoFactorMethod method;
  
  /// Error message if setup failed
  final String? errorMessage;
  
  /// TOTP secret for QR code generation (if applicable)
  final String? totpSecret;
  
  /// TOTP QR code URL (if applicable)
  final String? qrCodeUrl;
  
  /// Backup codes generated during setup
  final List<String>? backupCodes;
  
  /// Additional setup data
  final Map<String, dynamic>? setupData;

  const TwoFactorSetupResult({
    required this.isSuccess,
    required this.method,
    this.errorMessage,
    this.totpSecret,
    this.qrCodeUrl,
    this.backupCodes,
    this.setupData,
  });

  /// Create successful setup result
  factory TwoFactorSetupResult.success(
    TwoFactorMethod method, {
    String? totpSecret,
    String? qrCodeUrl,
    List<String>? backupCodes,
    Map<String, dynamic>? setupData,
  }) {
    return TwoFactorSetupResult(
      isSuccess: true,
      method: method,
      totpSecret: totpSecret,
      qrCodeUrl: qrCodeUrl,
      backupCodes: backupCodes,
      setupData: setupData,
    );
  }

  /// Create failed setup result
  factory TwoFactorSetupResult.failure(
    TwoFactorMethod method,
    String errorMessage,
  ) {
    return TwoFactorSetupResult(
      isSuccess: false,
      method: method,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return 'TwoFactorSetupResult(isSuccess: $isSuccess, '
           'method: $method, errorMessage: $errorMessage)';
  }
}

/// Two-factor authentication verification request
class TwoFactorVerificationRequest {
  /// Verification method
  final TwoFactorMethod method;
  
  /// Verification code
  final String code;
  
  /// Phone number (for SMS)
  final String? phoneNumber;
  
  /// Email address (for email)
  final String? emailAddress;
  
  /// Request timestamp
  final DateTime timestamp;
  
  /// Additional request data
  final Map<String, dynamic>? metadata;

  const TwoFactorVerificationRequest({
    required this.method,
    required this.code,
    this.phoneNumber,
    this.emailAddress,
    required this.timestamp,
    this.metadata,
  });

  /// Create SMS verification request
  factory TwoFactorVerificationRequest.sms(
    String code,
    String phoneNumber,
  ) {
    return TwoFactorVerificationRequest(
      method: TwoFactorMethod.sms,
      code: code,
      phoneNumber: phoneNumber,
      timestamp: DateTime.now(),
    );
  }

  /// Create email verification request
  factory TwoFactorVerificationRequest.email(
    String code,
    String emailAddress,
  ) {
    return TwoFactorVerificationRequest(
      method: TwoFactorMethod.email,
      code: code,
      emailAddress: emailAddress,
      timestamp: DateTime.now(),
    );
  }

  /// Create TOTP verification request
  factory TwoFactorVerificationRequest.totp(String code) {
    return TwoFactorVerificationRequest(
      method: TwoFactorMethod.totp,
      code: code,
      timestamp: DateTime.now(),
    );
  }

  /// Create backup code verification request
  factory TwoFactorVerificationRequest.backupCode(String code) {
    return TwoFactorVerificationRequest(
      method: TwoFactorMethod.backupCode,
      code: code,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'TwoFactorVerificationRequest(method: $method, '
           'code: ${code.replaceAll(RegExp(r'.'), '*')})';
  }
}