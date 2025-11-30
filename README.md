# 💰 Wallet App - Para Yönetimi Uygulaması

Kişisel bütçe, kredi kartı ve kredi takibi yapabileceğiniz modern bir Flutter uygulaması.

[![Download APK](https://img.shields.io/badge/Download-APK-green.svg)](https://github.com/cloude33/WalletApp/releases/latest)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 📥 İndir

[**APK İndir (v1.0.0)**](https://github.com/cloude33/WalletApp/releases/download/v1.0.0/WalletApp-v1.0.0.apk)

> **Not:** Android 5.0 (API 21) veya üzeri gereklidir.

## Özellikler

### ✨ Özellikler

#### 💳 Finansal Yönetim
- **Gelir/Gider Takibi**: Tüm finansal hareketlerinizi kaydedin
- **Cüzdan Yönetimi**: Nakit, kredi kartı ve banka hesaplarınızı yönetin
- **Kredi Kartı Yönetimi**: Kredi kartı ekstreleri, taksitler, ödemeler
- **Borç/Alacak Takibi**: Borç ve alacaklarınızı takip edin, hatırlatıcılar ayarlayın
- **Taksit Sistemi**: 2-12 ay arası taksitli alışveriş takibi

#### 🔄 Otomasyon
- **Tekrarlayan İşlemler**: Düzenli ödemeleri otomatikleştirin
  - Günlük, haftalık, aylık, yıllık tekrar
  - Hazır şablonlar (kira, faturalar, maaş, abonelikler)
  - Otomatik işlem oluşturma
- **Bildirimler**: Ödeme hatırlatıcıları ve bütçe uyarıları

#### 📊 Analiz ve Raporlama
- **İstatistikler**: Pasta grafikleri ile harcama analizi
- **Takvim Görünümü**: Günlük bazda gelir-gider takibi
- **Kategori Bazlı Takip**: 10+ hazır kategori
- **Export**: Excel, PDF, CSV formatında dışa aktarma

#### 🔒 Güvenlik
- **PIN Koruması**: 4 haneli PIN ile uygulama kilidi
- **Biyometrik Kimlik**: Parmak izi ile giriş
- **Otomatik Kilit**: Belirlenen süre sonra otomatik kilitleme

#### 👥 Kullanıcı Yönetimi
- **Çoklu Kullanıcı**: Aile üyeleri için ayrı profiller
- **Para Birimi Desteği**: 12 farklı para birimi (TRY, USD, EUR, GBP, vb.)
- **Profil Özelleştirme**: Avatar, isim, e-posta

#### 💾 Veri Yönetimi
- **Yedekleme**: Verilerinizi yedekleyin
- **Geri Yükleme**: Yedekten geri yükleyin
- **Otomatik Yedekleme**: Günlük/haftalık otomatik yedekleme
- **Yerel Depolama**: SharedPreferences ve Hive ile güvenli saklama

#### 🎨 Kullanıcı Deneyimi
- **Karanlık Mod**: Göz dostu karanlık tema
- **Modern Tasarım**: Kullanıcı dostu arayüz
- **Türkçe Dil Desteği**: Tam Türkçe arayüz

### 📱 Ekranlar

1. **Kullanıcı Seçimi**: Kullanıcı ekleme ve seçme ekranı
2. **Ana Sayfa**: Cüzdanlar, bütçe ve hedefler (dinamik veriler)
3. **Cüzdan Yönetimi**: Cüzdan ekleme, düzenleme ve silme
4. **Hedef Yönetimi**: Hedef ekleme, düzenleme ve silme
5. **İşlem Ekleme**: Gelir, gider veya transfer kaydı (cüzdan bakiyesi otomatik güncellenir)
6. **İstatistikler**: Grafik ve kategori bazlı analiz (gerçek verilerle)
7. **Takvim**: Aylık gelir-gider görünümü (gerçek işlemlerle)
8. **Kategoriler**: Kategori yönetimi

## Kurulum

### Gereksinimler

- Flutter SDK (3.10.0 veya üzeri)
- Dart SDK
- Android Studio / Xcode / Visual Studio (platform bazlı)

### Adımlar

1. Projeyi klonlayın:
```bash
git clone <repo-url>
cd money
```

2. Bağımlılıkları yükleyin:
```bash
flutter pub get
```

3. Uygulamayı çalıştırın:

**Android için:**
```bash
flutter run -d android
```

**iOS için:**
```bash
flutter run -d ios
```

**Web için:**
```bash
flutter run -d chrome
```

**Windows için:**
```bash
flutter run -d windows
```

## Kullanılan Paketler

- `fl_chart`: Grafik ve istatistikler için
- `intl`: Tarih ve para formatlaması için
- `shared_preferences`: Yerel veri saklama için
- `image_picker`: Fotoğraf ekleme için
- `hive` & `hive_flutter`: Tekrarlayan işlemler için NoSQL veritabanı
- `workmanager`: Background task yönetimi için

## Proje Yapısı

```
lib/
├── models/           # Veri modelleri
│   ├── transaction.dart
│   ├── wallet.dart
│   ├── category.dart
│   └── goal.dart
├── screens/          # Uygulama ekranları
│   ├── home_screen.dart
│   ├── add_transaction_screen.dart
│   ├── statistics_screen.dart
│   ├── calendar_screen.dart
│   └── categories_screen.dart
└── main.dart         # Ana uygulama dosyası
```

## Özelleştirme

### Renk Teması
Ana renk: `#FDB32A` (Sarı/Turuncu)

Tema renklerini değiştirmek için `lib/main.dart` dosyasındaki `ThemeData` bölümünü düzenleyin.

### Kategoriler
Varsayılan kategorileri değiştirmek için `lib/models/category.dart` dosyasını düzenleyin.

## Kullanım

1. Uygulamayı başlattığınızda kullanıcı seçim ekranı açılır
2. "Kullanıcı Ekle" butonuna tıklayarak yeni kullanıcı oluşturun
3. Kullanıcı seçtikten sonra ana sayfaya yönlendirilirsiniz
4. İlk kullanımda örnek cüzdanlar ve hedef otomatik eklenir
5. "+" butonuna tıklayarak yeni işlem ekleyin
6. Cüzdan eklemek için cüzdan bölümündeki "+" kartına tıklayın
7. Hedef eklemek için "Hedef Ekle" butonuna tıklayın
8. Alt menüden istatistikler, takvim ve kategoriler arasında geçiş yapın

## Özellikler Detayı

### Kullanıcı Yönetimi
- Çoklu kullanıcı desteği
- Her kullanıcı için ayrı veriler
- Kullanıcı değiştirme özelliği

### Cüzdan Yönetimi
- 3 farklı cüzdan tipi: Nakit, Kredi Kartı, Banka
- 8 farklı renk seçeneği
- Otomatik bakiye güncelleme
- Sınırsız cüzdan ekleme

### İşlem Yönetimi
- Gelir, Gider ve Transfer işlemleri
- Kategori seçimi
- Cüzdan seçimi
- Not ekleme
- Fotoğraf ekleme (hazır)
- Otomatik cüzdan bakiyesi güncelleme

### İstatistikler
- Aylık gelir-gider özeti
- Kategori bazlı harcama analizi
- Pasta grafikleri
- Ay bazında gezinme

### Takvim
- Günlük işlem görünümü
- Aylık özet
- Gün seçimi

## Geliştirme Notları

- Tüm veriler SharedPreferences ile yerel olarak saklanır
- Veritabanı entegrasyonu için SQLite veya Hive eklenebilir
- Bulut senkronizasyonu için Firebase entegrasyonu yapılabilir
- Çoklu dil desteği eklenebilir
- Fotoğraf ekleme özelliği image_picker ile genişletilebilir

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır.
