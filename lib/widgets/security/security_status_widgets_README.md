# Güvenlik Durumu Widget'ları

Bu dosya, güvenlik durumu widget'larının kullanımını ve özelliklerini açıklar.

## Widget'lar

### 1. SecurityLevelIndicator

Güvenlik seviyesini görsel olarak gösteren widget.

**Özellikler:**
- Renk kodlu güvenlik seviyesi göstergesi
- Özelleştirilebilir boyut
- İsteğe bağlı açıklama metni
- Animasyon desteği

**Kullanım:**
```dart
SecurityLevelIndicator(
  level: SecurityLevel.high,
  size: 80.0,
  showDescription: true,
  animated: true,
)
```

**Güvenlik Seviyeleri:**
- `SecurityLevel.high` - Yüksek güvenlik (Yeşil)
- `SecurityLevel.medium` - Orta güvenlik (Turuncu)
- `SecurityLevel.low` - Düşük güvenlik (Kırmızı)
- `SecurityLevel.critical` - Kritik risk (Koyu Kırmızı)

### 2. LockStatusWidget

Hesap kilitleme durumunu ve kalan süreyi gösteren widget.

**Özellikler:**
- Kilitleme durumu gösterimi
- Kalan süre sayacı
- Başarısız deneme sayısı
- Maksimum deneme sayısı gösterimi

**Kullanım:**
```dart
LockStatusWidget(
  isLocked: true,
  remainingDuration: Duration(minutes: 5, seconds: 30),
  failedAttempts: 5,
  maxAttempts: 5,
)
```

**Davranış:**
- Kilitli değilse ve başarısız deneme yoksa hiçbir şey göstermez
- Kilitli ise kalan süreyi gösterir
- Başarısız deneme varsa uyarı gösterir

### 3. SecurityWarningWidget

Tek bir güvenlik uyarısını gösteren widget.

**Özellikler:**
- Şiddet seviyesine göre renklendirme
- Kapatma butonu (opsiyonel)
- Detay gösterme butonu (opsiyonel)
- Açıklama metni desteği

**Kullanım:**
```dart
SecurityWarningWidget(
  warning: SecurityWarning(
    type: SecurityWarningType.rootDetected,
    severity: SecurityWarningSeverity.critical,
    message: 'Root tespit edildi',
    description: 'Cihazınızda root erişimi tespit edildi',
  ),
  onDismiss: () {
    // Uyarı kapatma işlemi
  },
  onShowDetails: () {
    // Detay gösterme işlemi
  },
)
```

**Uyarı Şiddet Seviyeleri:**
- `SecurityWarningSeverity.critical` - Kritik (Kırmızı)
- `SecurityWarningSeverity.high` - Yüksek (Turuncu)
- `SecurityWarningSeverity.medium` - Orta (Sarı)
- `SecurityWarningSeverity.low` - Düşük (Mavi)

### 4. SecurityWarningsList

Birden fazla güvenlik uyarısını liste halinde gösteren widget.

**Özellikler:**
- Uyarı sayısı gösterimi
- Maksimum uyarı limiti
- Toplu uyarı yönetimi
- "Daha fazla göster" özelliği

**Kullanım:**
```dart
SecurityWarningsList(
  warnings: [
    SecurityWarning(...),
    SecurityWarning(...),
  ],
  maxWarnings: 3,
  onDismissWarning: (warning) {
    // Uyarı kapatma işlemi
  },
  onShowWarningDetails: (warning) {
    // Detay gösterme işlemi
  },
)
```

### 5. SecurityStatusCard

Genel güvenlik durumunu özetleyen kart widget'ı.

**Özellikler:**
- Güvenlik seviyesi göstergesi
- Güvenlik özellikleri listesi
- Kimlik doğrulama durumu
- Root/jailbreak uyarısı
- Son kontrol zamanı

**Kullanım:**
```dart
SecurityStatusCard(
  status: SecurityStatus(
    isDeviceSecure: true,
    isRootDetected: false,
    isScreenshotBlocked: true,
    isBackgroundBlurEnabled: true,
    isClipboardSecurityEnabled: true,
    securityLevel: SecurityLevel.high,
  ),
  authState: AuthState.authenticated(
    sessionId: 'session-123',
    authMethod: AuthMethod.pin,
  ),
  onShowDetails: () {
    // Detay gösterme işlemi
  },
)
```

## Gereksinimler

Bu widget'lar aşağıdaki gereksinimleri karşılar:

- **Gereksinim 10.1**: Güvenlik dashboard açıldığında güvenlik durumu özetini göstermeli
- **Gereksinim 10.5**: Güvenlik açığı tespit edildiğinde kullanıcıyı uyarmalı ve önerilerde bulunmalı

## Örnekler

Detaylı kullanım örnekleri için `security_status_widgets_example.dart` dosyasına bakın.

### Basit Örnek

```dart
import 'package:flutter/material.dart';
import 'package:money/models/security/security_status.dart';
import 'package:money/widgets/security/security_status_widgets.dart';

class MySecurityScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final status = SecurityStatus(
      isDeviceSecure: true,
      isRootDetected: false,
      isScreenshotBlocked: true,
      isBackgroundBlurEnabled: true,
      isClipboardSecurityEnabled: true,
      securityLevel: SecurityLevel.high,
    );

    return Scaffold(
      appBar: AppBar(title: Text('Güvenlik')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SecurityStatusCard(status: status),
      ),
    );
  }
}
```

### Dashboard Örneği

```dart
class SecurityDashboard extends StatelessWidget {
  final SecurityStatus status;
  final List<SecurityWarning> warnings;
  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Güvenlik durumu kartı
        SecurityStatusCard(
          status: status,
          authState: authState,
        ),
        
        SizedBox(height: 16),
        
        // Güvenlik uyarıları
        if (warnings.isNotEmpty)
          SecurityWarningsList(
            warnings: warnings,
            maxWarnings: 5,
          ),
        
        SizedBox(height: 16),
        
        // Güvenlik seviyesi
        Center(
          child: SecurityLevelIndicator(
            level: status.securityLevel,
          ),
        ),
      ],
    );
  }
}
```

## Test

Widget'ların testleri `test/widgets/security/security_status_widgets_test.dart` dosyasında bulunur.

Testleri çalıştırmak için:
```bash
flutter test test/widgets/security/security_status_widgets_test.dart
```

## Stil ve Tema

Widget'lar Material Design prensiplerine uygun olarak tasarlanmıştır ve uygulamanın temasını otomatik olarak kullanır.

### Renk Şeması

- **Yüksek Güvenlik**: Yeşil (#4CAF50)
- **Orta Güvenlik**: Turuncu (#FF9800)
- **Düşük Güvenlik**: Kırmızı (#FF5722)
- **Kritik Risk**: Koyu Kırmızı (#D32F2F)

### Erişilebilirlik

Tüm widget'lar erişilebilirlik standartlarına uygun olarak tasarlanmıştır:
- Yeterli renk kontrastı
- Anlamlı semantik etiketler
- Ekran okuyucu desteği
- Dokunma hedefi boyutları

## Performans

Widget'lar performans için optimize edilmiştir:
- Minimal rebuild'ler
- Verimli state yönetimi
- Lazy loading desteği
- Bellek optimizasyonu

## Gelecek Geliştirmeler

Planlanan özellikler:
- Animasyonlu geçişler
- Özelleştirilebilir temalar
- Daha fazla güvenlik metrikleri
- Grafik ve chart desteği
- Export/paylaşım özellikleri
