import 'auth_state.dart';

/// Hassas işlem türleri
enum SensitiveOperationType {
  /// Para transferi işlemleri
  moneyTransfer,
  
  /// Güvenlik ayarları değişiklikleri
  securitySettingsChange,
  
  /// Hesap bilgileri görüntüleme
  accountInfoView,
  
  /// Veri export işlemleri
  dataExport,
  
  /// Kredi kartı ödeme işlemleri
  creditCardPayment,
  
  /// Borç yönetimi işlemleri
  debtManagement,
  
  /// Hedef değiştirme işlemleri
  goalModification,
  
  /// Cüzdan erişimi
  walletAccess,
  
  /// Rapor oluşturma
  reportGeneration;

  /// Kullanıcı dostu isim döndürür
  String get displayName {
    switch (this) {
      case SensitiveOperationType.moneyTransfer:
        return 'Para Transferi';
      case SensitiveOperationType.securitySettingsChange:
        return 'Güvenlik Ayarları';
      case SensitiveOperationType.accountInfoView:
        return 'Hesap Bilgileri';
      case SensitiveOperationType.dataExport:
        return 'Veri Export';
      case SensitiveOperationType.creditCardPayment:
        return 'Kredi Kartı Ödemesi';
      case SensitiveOperationType.debtManagement:
        return 'Borç Yönetimi';
      case SensitiveOperationType.goalModification:
        return 'Hedef Değiştirme';
      case SensitiveOperationType.walletAccess:
        return 'Cüzdan Erişimi';
      case SensitiveOperationType.reportGeneration:
        return 'Rapor Oluşturma';
    }
  }

  /// JSON'a çevirir
  String toJson() => name;

  /// JSON'dan oluşturur
  static SensitiveOperationType fromJson(String json) {
    return SensitiveOperationType.values.firstWhere(
      (type) => type.name == json,
      orElse: () => SensitiveOperationType.moneyTransfer,
    );
  }
}

/// İşlem güvenlik seviyeleri
enum OperationSecurityLevel {
  /// Standart seviye - temel kimlik doğrulama
  standard,
  
  /// Son 5 dakika içinde doğrulama gerekli
  recentAuth,
  
  /// Gelişmiş seviye - son 2 dakika içinde doğrulama
  enhanced,
  
  /// Çoklu yöntem doğrulama gerekli
  multiMethod,
  
  /// İki faktörlü doğrulama gerekli
  twoFactor,
  
  /// Tam kimlik doğrulama gerekli
  fullAuth;

  /// Kullanıcı dostu isim döndürür
  String get displayName {
    switch (this) {
      case OperationSecurityLevel.standard:
        return 'Standart';
      case OperationSecurityLevel.recentAuth:
        return 'Son Doğrulama';
      case OperationSecurityLevel.enhanced:
        return 'Gelişmiş';
      case OperationSecurityLevel.multiMethod:
        return 'Çoklu Yöntem';
      case OperationSecurityLevel.twoFactor:
        return 'İki Faktörlü';
      case OperationSecurityLevel.fullAuth:
        return 'Tam Doğrulama';
    }
  }

  /// JSON'a çevirir
  String toJson() => name;

  /// JSON'dan oluşturur
  static OperationSecurityLevel fromJson(String json) {
    return OperationSecurityLevel.values.firstWhere(
      (level) => level.name == json,
      orElse: () => OperationSecurityLevel.standard,
    );
  }
}

/// Hassas işlem sonucu
class SensitiveOperationResult {
  /// İşlem başarılı mı?
  final bool isSuccess;
  
  /// İşlem türü
  final SensitiveOperationType operationType;
  
  /// Gerekli güvenlik seviyesi
  final OperationSecurityLevel securityLevel;
  
  /// Kullanılan kimlik doğrulama yöntemi
  final AuthMethod authMethod;
  
  /// Hata mesajı (başarısızsa)
  final String? errorMessage;
  
  /// Kalan deneme sayısı
  final int? remainingAttempts;
  
  /// Kilitleme süresi
  final Duration? lockoutDuration;
  
  /// Ek metadata bilgileri
  final Map<String, dynamic>? metadata;

  const SensitiveOperationResult({
    required this.isSuccess,
    required this.operationType,
    required this.securityLevel,
    required this.authMethod,
    this.errorMessage,
    this.remainingAttempts,
    this.lockoutDuration,
    this.metadata,
  });

  /// Başarılı sonuç oluşturur
  factory SensitiveOperationResult.success({
    required SensitiveOperationType operationType,
    required OperationSecurityLevel securityLevel,
    required AuthMethod authMethod,
    Map<String, dynamic>? metadata,
  }) {
    return SensitiveOperationResult(
      isSuccess: true,
      operationType: operationType,
      securityLevel: securityLevel,
      authMethod: authMethod,
      metadata: metadata,
    );
  }

  /// Başarısız sonuç oluşturur
  factory SensitiveOperationResult.failure({
    required SensitiveOperationType operationType,
    required OperationSecurityLevel securityLevel,
    required AuthMethod authMethod,
    String? errorMessage,
    int? remainingAttempts,
    Duration? lockoutDuration,
    Map<String, dynamic>? metadata,
  }) {
    return SensitiveOperationResult(
      isSuccess: false,
      operationType: operationType,
      securityLevel: securityLevel,
      authMethod: authMethod,
      errorMessage: errorMessage,
      remainingAttempts: remainingAttempts,
      lockoutDuration: lockoutDuration,
      metadata: metadata,
    );
  }

  /// JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'isSuccess': isSuccess,
      'operationType': operationType.toJson(),
      'securityLevel': securityLevel.toJson(),
      'authMethod': authMethod.toJson(),
      'errorMessage': errorMessage,
      'remainingAttempts': remainingAttempts,
      'lockoutDuration': lockoutDuration?.inMilliseconds,
      'metadata': metadata,
    };
  }

  /// JSON'dan oluşturur
  factory SensitiveOperationResult.fromJson(Map<String, dynamic> json) {
    return SensitiveOperationResult(
      isSuccess: json['isSuccess'] as bool,
      operationType: SensitiveOperationType.fromJson(json['operationType'] as String),
      securityLevel: OperationSecurityLevel.fromJson(json['securityLevel'] as String),
      authMethod: AuthMethod.fromJson(json['authMethod'] as String),
      errorMessage: json['errorMessage'] as String?,
      remainingAttempts: json['remainingAttempts'] as int?,
      lockoutDuration: json['lockoutDuration'] != null
          ? Duration(milliseconds: json['lockoutDuration'] as int)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'SensitiveOperationResult(isSuccess: $isSuccess, '
           'operationType: $operationType, securityLevel: $securityLevel, '
           'authMethod: $authMethod, errorMessage: $errorMessage)';
  }
}

/// Hassas işlem olayı
class SensitiveOperationEvent {
  /// Olay türü
  final SensitiveOperationEventType type;
  
  /// İşlem türü
  final SensitiveOperationType operationType;
  
  /// Kullanılan kimlik doğrulama yöntemi
  final AuthMethod? authMethod;
  
  /// Olay zamanı
  final DateTime timestamp;
  
  /// Hata mesajı (varsa)
  final String? errorMessage;
  
  /// Olay bağlamı
  final Map<String, dynamic>? context;

  const SensitiveOperationEvent({
    required this.type,
    required this.operationType,
    this.authMethod,
    required this.timestamp,
    this.errorMessage,
    this.context,
  });

  /// İşlem başlatıldı olayı
  factory SensitiveOperationEvent.started({
    required SensitiveOperationType operationType,
    Map<String, dynamic>? context,
  }) {
    return SensitiveOperationEvent(
      type: SensitiveOperationEventType.started,
      operationType: operationType,
      timestamp: DateTime.now(),
      context: context,
    );
  }

  /// Kimlik doğrulama başarılı olayı
  factory SensitiveOperationEvent.authenticated({
    required SensitiveOperationType operationType,
    required AuthMethod authMethod,
    Map<String, dynamic>? context,
  }) {
    return SensitiveOperationEvent(
      type: SensitiveOperationEventType.authenticated,
      operationType: operationType,
      authMethod: authMethod,
      timestamp: DateTime.now(),
      context: context,
    );
  }

  /// İşlem başarısız olayı
  factory SensitiveOperationEvent.failed({
    required SensitiveOperationType operationType,
    required AuthMethod authMethod,
    String? errorMessage,
    Map<String, dynamic>? context,
  }) {
    return SensitiveOperationEvent(
      type: SensitiveOperationEventType.failed,
      operationType: operationType,
      authMethod: authMethod,
      timestamp: DateTime.now(),
      errorMessage: errorMessage,
      context: context,
    );
  }

  /// Hata olayı
  factory SensitiveOperationEvent.error({
    required SensitiveOperationType operationType,
    required String errorMessage,
    Map<String, dynamic>? context,
  }) {
    return SensitiveOperationEvent(
      type: SensitiveOperationEventType.error,
      operationType: operationType,
      timestamp: DateTime.now(),
      errorMessage: errorMessage,
      context: context,
    );
  }

  /// JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'type': type.toJson(),
      'operationType': operationType.toJson(),
      'authMethod': authMethod?.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'errorMessage': errorMessage,
      'context': context,
    };
  }

  /// JSON'dan oluşturur
  factory SensitiveOperationEvent.fromJson(Map<String, dynamic> json) {
    return SensitiveOperationEvent(
      type: SensitiveOperationEventType.fromJson(json['type'] as String),
      operationType: SensitiveOperationType.fromJson(json['operationType'] as String),
      authMethod: json['authMethod'] != null
          ? AuthMethod.fromJson(json['authMethod'] as String)
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      errorMessage: json['errorMessage'] as String?,
      context: json['context'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'SensitiveOperationEvent(type: $type, operationType: $operationType, '
           'authMethod: $authMethod, timestamp: $timestamp)';
  }
}

/// Hassas işlem olay türleri
enum SensitiveOperationEventType {
  /// İşlem başlatıldı
  started,
  
  /// Kimlik doğrulama başarılı
  authenticated,
  
  /// İşlem başarısız
  failed,
  
  /// Hata oluştu
  error;

  /// Kullanıcı dostu isim döndürür
  String get displayName {
    switch (this) {
      case SensitiveOperationEventType.started:
        return 'Başlatıldı';
      case SensitiveOperationEventType.authenticated:
        return 'Doğrulandı';
      case SensitiveOperationEventType.failed:
        return 'Başarısız';
      case SensitiveOperationEventType.error:
        return 'Hata';
    }
  }

  /// JSON'a çevirir
  String toJson() => name;

  /// JSON'dan oluşturur
  static SensitiveOperationEventType fromJson(String json) {
    return SensitiveOperationEventType.values.firstWhere(
      (type) => type.name == json,
      orElse: () => SensitiveOperationEventType.error,
    );
  }
}