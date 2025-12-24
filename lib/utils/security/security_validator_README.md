# Security Validator - Güvenlik Validasyon Yardımcıları

## Genel Bakış

`SecurityValidator` sınıfı, PIN güçlülük kontrolü, güvenlik konfigürasyon validasyonu ve kullanıcı dostu hata/başarı mesajları sağlar.

## Özellikler

### 1. PIN Güçlülük Kontrolü

PIN kodlarının güvenlik seviyesini analiz eder ve kullanıcıya geri bildirim sağlar.

**Kontrol Edilen Özellikler:**
- ✅ Uzunluk kontrolü (4-6 hane)
- ✅ Sadece rakam kontrolü
- ✅ Aynı rakamların tekrarı (örn: 1111)
- ✅ Ardışık rakamlar (örn: 1234, 4321)
- ✅ Yaygın PIN'ler (örn: 1234, 0000)
- ✅ Tekrarlayan çiftler (örn: 1212)
- ✅ Tarih benzeri desenler (örn: 0315)
- ✅ Benzersiz rakam sayısı bonusu
- ✅ Uzunluk bonusu

**Güçlülük Seviyeleri:**
- 🔴 Çok Zayıf (0-20 puan)
- 🟠 Zayıf (20-40 puan)
- 🟡 Orta (40-60 puan)
- 🟢 Güçlü (60-80 puan)
- 🟢 Çok Güçlü (80-100 puan)

### 2. Güvenlik Konfigürasyon Validasyonu

Tüm güvenlik konfigürasyonlarını validate eder:
- SecurityConfig
- PINConfiguration
- BiometricConfiguration
- SessionConfiguration
- TwoFactorConfiguration

### 3. Hata ve Başarı Mesajları

Kullanıcı dostu Türkçe hata ve başarı mesajları sağlar.

## Kullanım

### PIN Güçlülük Kontrolü

```dart
import 'package:money/utils/security/security_validator.dart';

// Basit kontrol
final result = SecurityValidator.checkPINStrength('1234');
print('Güçlülük: ${result.strength.description}');
print('Puan: ${result.score}');
print('Kabul edilebilir: ${result.isAcceptable}');
print('Uyarılar: ${result.warnings}');
print('Öneriler: ${result.suggestions}');

// Konfigürasyon ile kontrol
final config = PINConfiguration(
  minLength: 4,
  maxLength: 6,
  requireComplexPIN: true,
);

final result = SecurityValidator.checkPINStrength('1234', config: config);
```

### Güvenlik Konfigürasyon Validasyonu

```dart
final config = SecurityConfig.defaultConfig();
final error = SecurityValidator.validateSecurityConfig(config);

if (error == null) {
  print('Konfigürasyon geçerli');
} else {
  print('Hata: $error');
}
```

### Hata Mesajları

```dart
// Bağlam ile
final message = SecurityValidator.getErrorMessage(
  'pin_incorrect',
  context: {'remainingAttempts': 3},
);
print(message); // "Yanlış PIN. Kalan deneme: 3"

// Bağlam olmadan
final message = SecurityValidator.getErrorMessage('biometric_not_available');
print(message); // "Biyometrik doğrulama bu cihazda kullanılamıyor"
```

### Başarı Mesajları

```dart
final message = SecurityValidator.getSuccessMessage('pin_created');
print(message); // "PIN başarıyla oluşturuldu"
```

## API Referansı

### checkPINStrength

```dart
static PINStrengthResult checkPINStrength(
  String pin, {
  PINConfiguration? config,
})
```

PIN güçlülüğünü kontrol eder ve detaylı analiz sonucu döner.

**Parametreler:**
- `pin`: Kontrol edilecek PIN kodu
- `config`: Opsiyonel PIN konfigürasyonu

**Dönüş:** `PINStrengthResult` - Güçlülük analiz sonucu

### validateSecurityConfig

```dart
static String? validateSecurityConfig(SecurityConfig config)
```

Güvenlik konfigürasyonunu validate eder.

**Parametreler:**
- `config`: Validate edilecek güvenlik konfigürasyonu

**Dönüş:** Hata mesajı (null ise geçerli)

### getErrorMessage

```dart
static String getErrorMessage(
  String errorCode, {
  Map<String, dynamic>? context,
})
```

Kullanıcı dostu hata mesajı oluşturur.

**Parametreler:**
- `errorCode`: Hata kodu
- `context`: Opsiyonel bağlam bilgisi

**Dönüş:** Kullanıcı dostu hata mesajı

### getSuccessMessage

```dart
static String getSuccessMessage(
  String successCode, {
  Map<String, dynamic>? context,
})
```

Kullanıcı dostu başarı mesajı oluşturur.

**Parametreler:**
- `successCode`: Başarı kodu
- `context`: Opsiyonel bağlam bilgisi

**Dönüş:** Kullanıcı dostu başarı mesajı

## Hata Kodları

### PIN Hataları
- `pin_too_short` - PIN çok kısa
- `pin_too_long` - PIN çok uzun
- `pin_invalid_format` - Geçersiz format
- `pin_too_weak` - PIN çok zayıf
- `pin_incorrect` - Yanlış PIN
- `pin_locked` - Hesap kilitli

### Biyometrik Hataları
- `biometric_not_available` - Biyometrik kullanılamıyor
- `biometric_not_enrolled` - Biyometrik kayıtlı değil
- `biometric_failed` - Biyometrik başarısız
- `biometric_locked` - Biyometrik kilitli
- `biometric_timeout` - Zaman aşımı

### Oturum Hataları
- `session_expired` - Oturum sona erdi
- `session_invalid` - Geçersiz oturum

### Güvenlik Hataları
- `security_threat_detected` - Güvenlik tehdidi
- `device_not_secure` - Cihaz güvenli değil
- `screenshot_blocked` - Ekran görüntüsü engellendi

## Başarı Kodları

- `pin_created` - PIN oluşturuldu
- `pin_changed` - PIN değiştirildi
- `pin_reset` - PIN sıfırlandı
- `biometric_enrolled` - Biyometrik etkinleştirildi
- `biometric_disabled` - Biyometrik devre dışı
- `auth_success` - Giriş başarılı
- `config_saved` - Ayarlar kaydedildi
- `two_factor_enabled` - 2FA etkinleştirildi
- `two_factor_disabled` - 2FA devre dışı

## Test Coverage

✅ 53 test - Tümü başarılı
- PIN güçlülük testleri (14 test)
- Güvenlik konfigürasyon testleri (5 test)
- PIN konfigürasyon testleri (6 test)
- Hata mesajı testleri (6 test)
- Başarı mesajı testleri (4 test)
- PIN güçlülük enum testleri (3 test)
- Edge case testleri (5 test)
- Biyometrik konfigürasyon testleri (3 test)
- Oturum konfigürasyon testleri (3 test)
- İki faktörlü konfigürasyon testleri (3 test)

## Gereksinim Karşılama

✅ **Gereksinim 1.1**: PIN oluşturma ve uzunluk kontrolü
✅ **Gereksinim 7.1**: Güvenlik ayarları yönetimi

## Dosyalar

- `lib/utils/security/security_validator.dart` - Ana implementasyon
- `test/utils/security/security_validator_test.dart` - Testler
- `lib/utils/security/security_validator_example.dart` - Kullanım örnekleri
- `lib/utils/security/security_validator_README.md` - Dokümantasyon

## Notlar

- Tüm mesajlar Türkçe
- Kullanıcı dostu geri bildirimler
- Kapsamlı validasyon kuralları
- Yüksek test coverage
- Performanslı ve optimize edilmiş
