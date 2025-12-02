# 💰 Para Yönetimi - Kişisel Finans Uygulaması

Modern Flutter tabanlı kişisel bütçe, kredi kartı ve fatura takip uygulaması.

[![Download APK](https://img.shields.io/badge/Download-APK-green.svg)](https://github.com/cloude33/WalletApp/releases/latest)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 📥 İndir

[**APK İndir (v1.0.0)**](https://github.com/cloude33/WalletApp/releases/download/v1.0.0/WalletApp-v1.0.0.apk)

> **Not:** Android 5.0 (API 21) veya üzeri gerektirir.

## ✨ Özellikler

### 💳 Finansal Yönetim
- **Gelir/Gider Takibi**: Tüm finansal işlemlerinizi kaydedin
- **Cüzdan Yönetimi**: Nakit, kredi kartı ve banka hesaplarını yönetin
- **Kredi Kartı Yönetimi**: Kredi kartı ekstreleri, taksitler, ödemeler
- **Borç/Alacak Takibi**: Borç ve alacakları hatırlatıcılarla takip edin
- **Fatura Takibi**: Düzenli faturaları yönetin (elektrik, su, internet, kira, vb.)
  - **Yeni Akış**: 
    - **Ayarlar > Faturalarım**: Sabit fatura tanımları (bir kez tanımla)
    - **Ana Sayfa > + Fatura Ekle**: Aylık fatura tutarı girişi
    - **İstatistikler > Raporlar**: Fatura takibi ve analizi
  - **Akıllı Fatura Girişi**: Kolay akış: İl → Kategori → Şirket
  - **Türkiye Geneli Sağlayıcı Veritabanı**:
    - 21 Elektrik Dağıtım Şirketi (BEDAŞ, AYEDAŞ, GEDİZ, vb.)
    - 81 İl Su ve Kanalizasyon İdaresi (İSKİ, ASKİ, İZSU, vb.)
    - 25+ Doğalgaz Dağıtım Şirketi (İGDAŞ, Başkentgaz, İzmirgaz, vb.)
    - 17+ İnternet Servis Sağlayıcısı (Türk Telekom, Superonline, Vodafone, vb.)
  - **9 Fatura Kategorisi**: Elektrik, Su, Doğalgaz, İnternet, Telefon, Kira, Sigorta, Abonelik, Diğer
  - **Carousel Görünüm**: Kategorilere göre kaydırılabilir kartlar
  - **Detaylı İstatistikler**: 
    - Ödenen, bekleyen ve gecikmiş fatura özeti
    - Kategorilere göre dağılım (carousel)
    - Zaman filtresi (günlük, haftalık, aylık, yıllık)
- **Taksit Sistemi**: Taksitli alışverişleri takip edin (2-12 ay)

### 🔄 Otomasyon
- **Tekrarlayan İşlemler**: Düzenli ödemeleri otomatikleştirin
  - Günlük, haftalık, aylık, yıllık tekrar
  - Hazır şablonlar (kira, faturalar, maaş, abonelikler)
  - Otomatik işlem oluşturma
- **Bildirimler**: Ödeme hatırlatıcıları ve bütçe uyarıları

### 📊 Analiz ve Raporlama
- **İstatistikler**: Pasta grafikleri ile harcama analizi
  - **5 Sekme**: Nakit akışı, Harcama, Kredi, Raporlar, Varlıklar
  - **Fatura Takibi**: Raporlar sekmesinde detaylı fatura analizi
  - **Carousel Görünüm**: Kategorilere göre kaydırılabilir fatura kartları
- **Takvim Görünümü**: Günlük gelir-gider takibi
- **Kategori Bazlı Takip**: 10+ hazır kategori
- **Dışa Aktarma**: Excel, PDF, CSV formatlarında dışa aktarma

### 🔒 Güvenlik
- **PIN Koruması**: 4 haneli PIN ile uygulama kilidi
- **Biyometrik Kimlik Doğrulama**: Parmak izi ile giriş
- **Otomatik Kilit**: Belirlenen süre sonra otomatik kilitleme

### 👥 Kullanıcı Yönetimi
- **Çoklu Kullanıcı**: Aile üyeleri için ayrı profiller
- **Para Birimi Desteği**: 12 farklı para birimi (TRY, USD, EUR, GBP, vb.)
- **Profil Özelleştirme**: Avatar, isim, e-posta
- **Google ve Apple ile Giriş**: Sosyal medya entegrasyonu

### 💾 Veri Yönetimi
- **Yedekleme**: Verilerinizi yedekleyin
- **Geri Yükleme**: Yedekten geri yükleyin
- **Otomatik Yedekleme**: Günlük/haftalık otomatik yedekleme
- **Yerel Depolama**: SharedPreferences ve Hive ile güvenli depolama
- **Veri Geçişi**: Eski fatura sistemi otomatik olarak yeni yapıya dönüştürülür

### 🎨 Kullanıcı Deneyimi
- **Karanlık Mod**: Göz dostu karanlık tema
- **Modern Tasarım**: Kullanıcı dostu arayüz
- **Özel Logo**: Giriş ekranlarında özel uygulama logosu
- **Türkçe Dil Desteği**: Tam Türkçe arayüz

## 🚀 Kurulum

### Gereksinimler

- Flutter SDK (3.10.0 veya üzeri)
- Dart SDK
- Android Studio / Xcode / Visual Studio (platforma göre)

### Adımlar

1. Projeyi klonlayın:
```bash
git clone https://github.com/cloude33/WalletApp.git
cd WalletApp
```

2. Bağımlılıkları yükleyin:
```bash
flutter pub get
```

3. Build runner'ı çalıştırın:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Uygulamayı çalıştırın:

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

## 📦 Kullanılan Paketler

- `fl_chart`: Grafik ve istatistikler için
- `intl`: Tarih ve para birimi formatlama
- `shared_preferences`: Yerel veri depolama
- `image_picker`: Fotoğraf yükleme
- `hive` & `hive_flutter`: NoSQL veritabanı
- `json_annotation` & `json_serializable`: JSON serileştirme
- `local_auth`: Biyometrik kimlik doğrulama
- `google_sign_in`: Google ile giriş
- `flutter_local_notifications`: Yerel bildirimler
- `excel`, `pdf`, `csv`: Dışa aktarma formatları

## 📁 Proje Yapısı

```
lib/
├── models/                    # Veri modelleri
│   ├── transaction.dart
│   ├── wallet.dart
│   ├── category.dart
│   ├── bill_template.dart     # Fatura şablonu (sabit tanımlar)
│   ├── bill_payment.dart      # Fatura ödemesi (aylık)
│   ├── debt.dart
│   ├── credit_card.dart
│   └── recurring_transaction.dart
├── screens/                   # Uygulama ekranları
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── welcome_screen.dart
│   ├── statistics_screen.dart # 5 sekme: Nakit, Harcama, Kredi, Raporlar, Varlıklar
│   ├── calendar_screen.dart
│   ├── bill_templates_screen.dart      # Faturalarım (Ayarlar)
│   ├── add_bill_template_screen.dart   # Fatura şablonu ekle
│   ├── add_bill_payment_screen.dart    # Fatura ödemesi ekle
│   ├── bill_history_screen.dart        # Fatura geçmişi
│   └── credit_card_list_screen.dart
├── services/                  # İş mantığı servisleri
│   ├── data_service.dart
│   ├── bill_template_service.dart      # Fatura şablonu servisi
│   ├── bill_payment_service.dart       # Fatura ödeme servisi
│   ├── bill_migration_service.dart     # Veri geçiş servisi
│   ├── debt_service.dart
│   ├── credit_card_service.dart
│   └── notification_service.dart
├── constants/                 # Sabit veriler
│   └── electricity_companies.dart # 140+ Türkiye sağlayıcı veritabanı
└── main.dart                  # Ana uygulama dosyası
```

## 📖 Fatura Takibi Kullanımı

### Fatura Şablonu Ekleme (Bir Kez)
1. **Ayarlar** → **Faturalarım** bölümüne gidin
2. **İl Seçimi**: 81 ilden birinizi seçin
3. **Kategori Seçimi**: Fatura kategorisini seçin (Elektrik, Su, Doğalgaz, vb.)
4. **Şirket Seçimi**: İl ve kategoriye göre otomatik filtrelenen sağlayıcı listesinden seçin
5. **Detaylar**:
   - Fatura adı otomatik oluşturulur (düzenlenebilir)
   - Hesap/abone numarası (opsiyonel)
   - GSM numarası (telefon faturaları için)
   - Açıklama (opsiyonel)

### Aylık Fatura Tutarı Girişi
1. **Ana Sayfa** → **+ Fatura Ekle** butonuna tıklayın
2. Tanımladığınız fatura şablonunu seçin
3. Bu ayın fatura tutarını girin (örn: 540 TL)
4. Son ödeme tarihini seçin
5. **Fatura Ekle** butonuna tıklayın

### Fatura İstatistikleri
1. **İstatistikler** sekmesine gidin
2. **Raporlar** tabına tıklayın
3. **Fatura Takibi** kartını görün:
   - ✅ Ödenen faturalar (yeşil)
   - ⏳ Bekleyen faturalar (turuncu)
   - ⚠️ Gecikmiş faturalar (kırmızı)
4. **Kategorilere Göre Dağılım**: Kaydırılabilir kartlar
   - Her kategori için ayrı kart
   - Kategori ikonu, tutar ve yüzde
   - Gradient arka plan
   - Yan yana kaydırma

## 🔄 Veri Geçişi

Eski fatura sistemi kullanıyorsanız:
- Uygulama ilk açılışta otomatik olarak verileri yeni yapıya dönüştürür
- Eski veriler `bills_backup` anahtarında yedeklenir
- Yeni yapı: `BillTemplate` (şablonlar) + `BillPayment` (ödemeler)

## 💻 Kod Yapısı

Bu proje temiz kod prensiplerini takip eder:
- Türkçe yorumlar (kullanıcı arayüzü Türkçe)
- Açık ve tanımlayıcı değişken/fonksiyon isimleri
- Endişelerin ayrılması (Models, Services, Screens)
- Servisler için Singleton pattern
- Veri modelleri için JSON serileştirme
- Migration servisi ile geriye dönük uyumluluk

## 🎨 Tasarım Özellikleri

- **Modern UI**: Material Design 3
- **Gradient Arka Planlar**: Giriş ekranları
- **Carousel Görünümler**: Fatura kategorileri
- **Özel Logo**: Tüm giriş ekranlarında
- **Responsive**: Farklı ekran boyutlarına uyumlu
- **Animasyonlar**: Yumuşak geçişler ve fade efektleri

## 🔧 Geliştirme Notları

- Tüm veriler SharedPreferences ile yerel olarak saklanır
- Hive NoSQL veritabanı tekrarlayan işlemler için kullanılır
- Firebase entegrasyonu ile bulut senkronizasyonu eklenebilir
- Çoklu dil desteği eklenebilir
- Fotoğraf yükleme özelliği image_picker ile genişletilebilir

## 📄 Lisans

Bu proje MIT Lisansı altında lisanslanmıştır.

## 🤝 Katkıda Bulunma

1. Bu depoyu fork edin
2. Yeni bir branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'feat: Add amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Bir Pull Request açın

## 📞 İletişim

Proje Sahibi: [@cloude33](https://github.com/cloude33)

Proje Linki: [https://github.com/cloude33/WalletApp](https://github.com/cloude33/WalletApp)

---

⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!
