# Security Widgets

Bu klasör güvenlik ile ilgili widget'ları içerir.

## PINInputWidget

Özelleştirilebilir PIN kodu giriş widget'ı.

### Özellikler

- ✅ 4-8 haneli PIN desteği
- ✅ Animasyonlu feedback
- ✅ Erişilebilirlik desteği
- ✅ Sayı tuş takımı
- ✅ Görsel PIN göstergesi (dots)
- ✅ Haptic feedback
- ✅ Hata durumu gösterimi
- ✅ Yükleme durumu gösterimi
- ✅ Özelleştirilebilir tema

### Temel Kullanım

```dart
import 'package:flutter/material.dart';
import 'package:money/widgets/security/pin_input_widget.dart';

class MyPINScreen extends StatefulWidget {
  @override
  State<MyPINScreen> createState() => _MyPINScreenState();
}

class _MyPINScreenState extends State<MyPINScreen> {
  String _pin = '';
  bool _hasError = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: PINInputWidget(
          pin: _pin,
          onChanged: (pin) {
            setState(() {
              _pin = pin;
              _hasError = false;
            });
          },
          onCompleted: (pin) {
            // PIN tamamlandığında çağrılır
            _validatePIN(pin);
          },
          maxLength: 6,
          hasError: _hasError,
          isLoading: _isLoading,
        ),
      ),
    );
  }

  void _validatePIN(String pin) {
    setState(() => _isLoading = true);
    
    // PIN doğrulama işlemi
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
        _hasError = pin != '123456'; // Örnek doğrulama
      });
    });
  }
}
```

### Gelişmiş Kullanım

```dart
PINInputWidget(
  pin: _pin,
  onChanged: (pin) => setState(() => _pin = pin),
  onCompleted: (pin) => _validatePIN(pin),
  maxLength: 4,
  obscureText: true,
  enabled: true,
  hasError: false,
  isLoading: false,
  autoFocus: true,
  dotSize: 18.0,
  dotSpacing: 10.0,
  activeDotColor: Colors.blue,
  filledDotColor: Colors.blue,
  emptyDotColor: Colors.grey,
  showNumberPad: true,
  numberPadButtonSize: 65.0,
  animationDuration: Duration(milliseconds: 300),
)
```

### Tema Örnekleri

```dart
// Varsayılan tema
const PINInputTheme.defaultTheme

// Koyu tema
const PINInputTheme.darkTheme

// Kompakt tema
const PINInputTheme.compactTheme
```

### Parametreler

| Parametre | Tip | Varsayılan | Açıklama |
|-----------|-----|------------|----------|
| `pin` | `String` | - | Mevcut PIN değeri |
| `onChanged` | `ValueChanged<String>` | - | PIN değiştiğinde çağrılır |
| `onCompleted` | `ValueChanged<String>?` | `null` | PIN tamamlandığında çağrılır |
| `maxLength` | `int` | `6` | Maksimum PIN uzunluğu (4-8) |
| `obscureText` | `bool` | `true` | PIN karakterlerini gizle |
| `enabled` | `bool` | `true` | Widget'ın etkin olup olmadığı |
| `hasError` | `bool` | `false` | Hata durumu |
| `isLoading` | `bool` | `false` | Yükleme durumu |
| `autoFocus` | `bool` | `true` | Otomatik focus |
| `dotSize` | `double` | `16.0` | PIN dot boyutu |
| `dotSpacing` | `double` | `8.0` | PIN dot'ları arası boşluk |
| `activeDotColor` | `Color?` | `null` | Aktif dot rengi |
| `filledDotColor` | `Color?` | `null` | Dolu dot rengi |
| `emptyDotColor` | `Color?` | `null` | Boş dot rengi |
| `showNumberPad` | `bool` | `true` | Sayı tuş takımını göster |
| `numberPadButtonSize` | `double` | `60.0` | Sayı tuş takımı buton boyutu |
| `animationDuration` | `Duration` | `200ms` | Animasyon süresi |

### Erişilebilirlik

Widget otomatik olarak erişilebilirlik desteği sağlar:

- Screen reader desteği
- Semantik etiketler
- Klavye navigasyonu
- Haptic feedback

### Gereksinimler

Bu widget aşağıdaki gereksinimleri karşılar:

- **Gereksinim 1.1**: 4-6 haneli sayısal PIN girişi kabul etmeli
- **Gereksinim 2.5**: Kalan süreyi kullanıcıya göstermeli (loading durumu ile)

### Test Edilmiş Senaryolar

- ✅ PIN giriş ve değiştirme
- ✅ Maksimum uzunluk kontrolü
- ✅ Backspace işlevi
- ✅ Hata durumu gösterimi
- ✅ Yükleme durumu
- ✅ Sayı tuş takımı gizleme
- ✅ Özelleştirilebilir parametreler
- ✅ Tema desteği