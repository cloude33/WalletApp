/// Biyometrik kimlik doğrulama türlerini tanımlayan enum
enum BiometricType {
  /// Parmak izi doğrulaması
  fingerprint,
  
  /// Yüz tanıma doğrulaması (Face ID/Face Unlock)
  face,
  
  /// Ses tanıma doğrulaması
  voice,
  
  /// Iris tarama doğrulaması
  iris;

  /// Enum değerini string'e çevirir
  String toJson() => name;

  /// String değerini enum'a çevirir
  static BiometricType fromJson(String json) {
    return BiometricType.values.firstWhere(
      (type) => type.name == json,
      orElse: () => BiometricType.fingerprint,
    );
  }

  /// Kullanıcı dostu isim döndürür
  String get displayName {
    switch (this) {
      case BiometricType.fingerprint:
        return 'Parmak İzi';
      case BiometricType.face:
        return 'Yüz Tanıma';
      case BiometricType.voice:
        return 'Ses Tanıma';
      case BiometricType.iris:
        return 'Iris Tarama';
    }
  }

  /// Platform-specific isim döndürür
  String get platformName {
    switch (this) {
      case BiometricType.fingerprint:
        return 'fingerprint';
      case BiometricType.face:
        return 'face';
      case BiometricType.voice:
        return 'voice';
      case BiometricType.iris:
        return 'iris';
    }
  }
}