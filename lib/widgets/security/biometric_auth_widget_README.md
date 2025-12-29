# BiometricAuthWidget

Biyometrik kimlik doğrulama için kullanılan Flutter widget'ı.

## Özellikler

- ✅ Platform-specific biyometrik UI (Android ve iOS)
- ✅ Fallback PIN gösterimi
- ✅ Durum göstergeleri (idle, authenticating, success, failure, error, notAvailable)
- ✅ Animasyonlu feedback (pulse ve shake animasyonları)
- ✅ Erişilebilirlik desteği
- ✅ Özelleştirilebilir tema ve boyutlar
- ✅ Kompakt mod desteği
- ✅ Otomatik başlatma seçeneği
- ✅ Haptic feedback

## Gereksinimler

Bu widget aşağıdaki gereksinimleri karşılar:

- **Gereksinim 4.1**: Cihazın biyometrik desteğini kontrol eder
- **Gereksinim 4.2**: Parmak izi doğrulaması sunar
- **Gereksinim 4.3**: Yüz tanıma doğrulaması sunar
- **Gereksinim 4.5**: Biyometrik doğrulama başarısız olduğunda PIN girişine yönlendirir

## Kullanım

### Temel Kullanım

```dart
BiometricAuthWidget(
  onAuthSuccess: () {
    // Başarılı doğrulama sonrası işlemler
    print('Kimlik doğrulama başarılı!');
  },
  onAuthFailure: (error) {
    // Başarısız doğrulama sonrası işlemler
    print('Hata: $error');
  },
  onFallbackToPIN: () {
    // PIN girişine yönlendirme
    Navigator.pushNamed(context, '/pin-login');
  },
)
```

### Özelleştirilmiş Kullanım

```dart
BiometricAuthWidget(
  title: 'Güvenli Giriş',
  subtitle: 'Kimliğinizi doğrulayın',
  autoStart: true,
  compact: false,
  iconSize: 100.0,
  animationDuration: Duration(milliseconds: 400),
  fallbackButtonText: 'PIN ile giriş yap',
  cancelButtonText: 'İptal',
  onAuthSuccess: () {
    // Başarılı doğrulama
  },
  onAuthFailure: (error) {
    // Başarısız doğrulama
  },
  onFallbackToPIN: () {
    // PIN fallback
  },
)
```

### Kompakt Mod

```dart
BiometricAuthWidget(
  compact: true,
  autoStart: true,
  onAuthSuccess: () {
    // Başarılı doğrulama
  },
)
```

## Parametreler

| Parametre | Tip | Varsayılan | Açıklama |
|-----------|-----|-----------|----------|
| `onAuthSuccess` | `VoidCallback?` | `null` | Başarılı doğrulama callback'i |
| `onAuthFailure` | `ValueChanged<String>?` | `null` | Başarısız doğrulama callback'i |
| `onFallbackToPIN` | `VoidCallback?` | `null` | PIN fallback callback'i |
| `biometricService` | `BiometricService?` | `null` | Biyometrik servis (test için) |
| `autoStart` | `bool` | `false` | Otomatik başlatma |
| `title` | `String?` | `null` | Başlık metni |
| `subtitle` | `String?` | `null` | Alt başlık metni |
| `fallbackButtonText` | `String?` | `null` | Fallback buton metni |
| `cancelButtonText` | `String?` | `null` | İptal buton metni |
| `enabled` | `bool` | `true` | Widget etkin mi? |
| `compact` | `bool` | `false` | Kompakt mod |
| `iconSize` | `double` | `80.0` | Icon boyutu |
| `animationDuration` | `Duration` | `300ms` | Animasyon süresi |

## Durumlar (BiometricAuthState)

Widget aşağıdaki durumları destekler:

- `idle`: Başlangıç durumu
- `authenticating`: Kimlik doğrulama yapılıyor
- `success`: Kimlik doğrulama başarılı
- `failure`: Kimlik doğrulama başarısız
- `error`: Hata oluştu
- `notAvailable`: Biyometrik doğrulama kullanılamıyor

## Temalar (BiometricAuthTheme)

Widget için önceden tanımlanmış temalar:

### Varsayılan Tema
```dart
BiometricAuthTheme.defaultTheme
// iconSize: 80.0
// animationDuration: 300ms
```

### Kompakt Tema
```dart
BiometricAuthTheme.compactTheme
// iconSize: 60.0
// animationDuration: 200ms
```

### Büyük Tema
```dart
BiometricAuthTheme.largeTheme
// iconSize: 100.0
// animationDuration: 400ms
```

## Biyometrik Türler

Widget aşağıdaki biyometrik türleri destekler:

- **Parmak İzi** (Fingerprint)
- **Yüz Tanıma** (Face ID / Face Unlock)
- **Iris Tarama** (Iris)
- **Ses Tanıma** (Voice)

Her biyometrik tür için uygun icon ve mesajlar otomatik olarak gösterilir.

## Platform Desteği

### Android
- Fingerprint API
- BiometricPrompt API
- Face Unlock (destekleyen cihazlarda)

### iOS
- Touch ID
- Face ID

## Animasyonlar

Widget iki tür animasyon içerir:

1. **Pulse Animasyonu**: Kimlik doğrulama sırasında icon'da pulse efekti
2. **Shake Animasyonu**: Başarısız doğrulama sonrası shake efekti

## Erişilebilirlik

Widget tam erişilebilirlik desteği sunar:

- Semantics etiketleri
- Ekran okuyucu desteği
- Haptic feedback
- Yüksek kontrast desteği

## Test

Widget için kapsamlı test suite mevcuttur:

```bash
flutter test test/widgets/security/biometric_auth_widget_test.dart
```

Test coverage:
- ✅ Icon ve mesaj gösterimi
- ✅ Başarılı doğrulama akışı
- ✅ Başarısız doğrulama akışı
- ✅ Fallback PIN akışı
- ✅ Otomatik başlatma
- ✅ Kompakt mod
- ✅ Özel tema
- ✅ Erişilebilirlik

## Örnekler

Detaylı kullanım örnekleri için `biometric_auth_example.dart` dosyasına bakın:

- Temel kullanım örneği
- Kompakt mod örneği
- Otomatik başlatma örneği
- Özel tema örneği

## Notlar

- Widget, biyometrik servis kullanılamadığında otomatik olarak uygun mesajı gösterir
- Birden fazla biyometrik tür mevcutsa, hepsi chip olarak listelenir
- Platform-specific icon'lar otomatik olarak seçilir (iOS için Face ID, Android için Face Unlock)
- Haptic feedback kullanıcı deneyimini geliştirir

## Lisans

Bu widget, Money uygulamasının bir parçasıdır ve aynı lisans altında dağıtılır.
