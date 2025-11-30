# Para Yönetimi Uygulaması

Kişisel bütçe, kredi kartı ve kredi takibi yapabileceğiniz modern bir Flutter uygulaması.

## Özellikler

### ✅ Tamamlanan Özellikler

- **Kullanıcı Yönetimi**: Çoklu kullanıcı desteği, kullanıcı ekleme ve seçme, para birimi seçimi
- **Para Birimi Desteği**: 12 farklı para birimi (TRY, USD, EUR, GBP, vb.), varsayılan Türk Lirası
- **Cüzdan Yönetimi**: Nakit, kredi kartı ve banka hesaplarınızı ekleyin, silin ve yönetin
- **Taksit Sistemi**: Kredi kartı ile 2-12 ay arası taksitli alışveriş
- **Gelir/Gider/Transfer İşlemleri**: Tüm finansal hareketlerinizi kaydedin ve cüzdan bakiyesi otomatik güncellensin
- **Kategori Bazlı Takip**: 10+ hazır kategori ile harcamalarınızı sınıflandırın
- **İstatistikler ve Grafikler**: Pasta grafikleri ile harcama dağılımınızı görün, aylık gelir-gider analizi
- **Takvim Görünümü**: Günlük bazda gelir ve giderlerinizi takip edin
- **Hedef Belirleme**: Finansal hedeflerinizi belirleyin, ilerlemenizi izleyin ve yönetin
- **Tekrarlayan İşlemler**: Düzenli ödemeleri otomatikleştirin (kira, faturalar, maaş, abonelikler)
  - Günlük, haftalık, aylık, yıllık tekrar seçenekleri
  - Hazır şablonlar (kira, elektrik, su, internet, maaş, vb.)
  - Otomatik işlem oluşturma
  - Bildirim desteği
- **Veri Saklama**: SharedPreferences ve Hive ile yerel veri saklama
- **Dinamik Veriler**: Tüm veriler gerçek zamanlı olarak güncellenir

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
