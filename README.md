# 💰 Para Yönetimi - Kişisel Finans Uygulaması

Modern Flutter tabanlı kişisel bütçe, kredi kartı ve fatura takip uygulaması.

[![Download APK](https://img.shields.io/badge/Download-APK-green.svg)](https://github.com/cloude33/WalletApp/releases/latest)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-2.0.0-brightgreen.svg)](https://github.com/cloude33/WalletApp/releases/tag/v2.0.0)

## 📥 İndir

[**APK İndir (v2.0.0)**](https://github.com/cloude33/WalletApp/releases/download/v2.0.0/WalletApp-v2.0.0.apk)

> **Not:** Android 5.0 (API 21) veya üzeri gerektirir.

## 🎉 Yenilikler v2.0.0

**Büyük Güncelleme: KMH (Kredili Mevduat Hesabı) Yönetimi!**

- ✨ Otomatik günlük faiz hesaplama
- 🔔 Akıllı limit uyarıları (%80 ve %95)
- 📊 Ödeme planı oluşturma ve karşılaştırma
- 🔄 Çoklu hesap yönetimi ve karşılaştırma
- 📈 Detaylı ekstre ve raporlama
- 💡 En düşük faizli hesap önerileri

[Detaylı Sürüm Notları](RELEASE_NOTES.md) | [Değişiklik Günlüğü](CHANGELOG.md)

## ✨ Özellikler

### 💳 Finansal Yönetim
- **Gelir/Gider Takibi**: Tüm finansal işlemlerinizi kaydedin
- **Cüzdan Yönetimi**: Nakit, kredi kartı ve banka hesaplarını yönetin
- **KMH (Kredili Mevduat Hesabı) Yönetimi**: 
  - Kredili hesaplarınızı takip edin
  - Otomatik günlük faiz hesaplama
  - Limit uyarıları ve bildirimler
  - Ödeme planı oluşturma
  - Çoklu hesap karşılaştırma
  - Detaylı ekstre ve raporlama
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
- **Gelişmiş İstatistikler**: Kapsamlı finansal analiz ve görselleştirme
  - **5 Sekme**: Nakit akışı, Harcama, Kredi, Raporlar, Varlıklar
  - **İnteraktif Grafikler**: Tıklanabilir, zoom yapılabilir grafikler
  - **Trend Analizi**: Otomatik trend tespiti ve tahminler
  - **Karşılaştırma**: Dönemsel ve ortalama karşılaştırmaları
  - **Finansal Sağlık Skoru**: Likidite, borç yönetimi ve tasarruf skorları
- **Nakit Akışı Analizi**:
  - 12 aylık gelir-gider grafiği
  - Aylık detaylar ve trendler
  - Ortalama hesaplamalar
  - Dönemsel karşılaştırmalar
- **Harcama Analizi**:
  - Kategori bazlı pasta grafikleri
  - Ödeme yöntemi dağılımı
  - Bütçe takibi ve uyarıları
  - Harcama alışkanlıkları analizi
- **KMH Dashboard**:
  - Toplam borç ve limit gösterimi
  - Faiz hesaplama (günlük/aylık/yıllık)
  - 6 aylık trend grafikleri
  - Ödeme simülasyonu
  - Çoklu hesap karşılaştırma
- **Raporlar**:
  - Gelir/Gider raporları
  - Fatura takibi ve analizi
  - Özel rapor oluşturma
  - Carousel görünüm
- **Varlıklar**:
  - Net varlık hesaplama
  - Varlık dağılımı (pasta grafik)
  - 12 aylık net varlık trendi
  - Finansal sağlık skoru (0-100)
  - İyileştirme önerileri
- **Filtre ve Arama**:
  - Zaman filtreleri (günlük, haftalık, aylık, yıllık)
  - Kategori ve cüzdan filtreleri
  - Akıllı arama (fuzzy search)
  - Özel tarih aralığı
- **Dışa Aktarma**: 
  - PDF: Yazdırma ve arşivleme
  - Excel: Detaylı analiz
  - CSV: Veri aktarımı
  - PNG: Grafik paylaşımı
- **Performans Optimizasyonu**:
  - Lazy loading
  - Akıllı önbellekleme
  - Pagination
  - Background hesaplama
- **Takvim Görünümü**: Günlük gelir-gider takibi
- **Kategori Bazlı Takip**: 10+ hazır kategori

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

### Temel Paketler
- `fl_chart` (^0.69.2): İnteraktif grafikler ve istatistikler
- `intl`: Tarih ve para birimi formatlama
- `shared_preferences`: Yerel veri depolama
- `hive` & `hive_flutter`: NoSQL veritabanı
- `json_annotation` & `json_serializable`: JSON serileştirme

### Güvenlik ve Kimlik Doğrulama
- `local_auth`: Biyometrik kimlik doğrulama
- `google_sign_in`: Google ile giriş
- `flutter_secure_storage`: Güvenli veri saklama

### Bildirimler ve Medya
- `flutter_local_notifications`: Yerel bildirimler
- `image_picker`: Fotoğraf yükleme

### Dışa Aktarma
- `excel` (^4.0.6): Excel dosyası oluşturma
- `pdf` (^3.11.1): PDF rapor oluşturma
- `csv`: CSV formatında export
- `path_provider`: Dosya yolu yönetimi

### Test Paketleri
- `test`: Unit testler
- `flutter_test`: Widget testleri
- `faker`: Test verisi oluşturma
- `mockito`: Mock nesneler

## 📁 Proje Yapısı

```
lib/
├── models/                    # Veri modelleri
│   ├── transaction.dart
│   ├── wallet.dart            # KMH alanları ile genişletilmiş
│   ├── kmh_transaction.dart   # KMH işlemleri
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
│   ├── credit_card_list_screen.dart
│   ├── kmh_list_screen.dart            # KMH hesap listesi
│   ├── kmh_account_detail_screen.dart  # KMH hesap detayı
│   ├── kmh_transaction_screen.dart     # KMH işlem ekranı
│   ├── kmh_statement_screen.dart       # KMH ekstre
│   ├── kmh_payment_planner_screen.dart # Ödeme planlama
│   └── kmh_comparison_screen.dart      # Hesap karşılaştırma
├── services/                  # İş mantığı servisleri
│   ├── data_service.dart
│   ├── bill_template_service.dart      # Fatura şablonu servisi
│   ├── bill_payment_service.dart       # Fatura ödeme servisi
│   ├── bill_migration_service.dart     # Veri geçiş servisi
│   ├── debt_service.dart
│   ├── credit_card_service.dart
│   ├── notification_service.dart
│   ├── kmh_service.dart                # KMH ana servis
│   ├── kmh_interest_calculator.dart    # Faiz hesaplama
│   ├── kmh_alert_service.dart          # Uyarı servisi
│   ├── kmh_migration_service.dart      # KMH migrasyon
│   ├── kmh_interest_scheduler_service.dart # Otomatik faiz
│   └── payment_planner_service.dart    # Ödeme planlama
├── repositories/              # Veri erişim katmanı
│   ├── kmh_repository.dart             # KMH veri erişimi
│   └── payment_plan_repository.dart    # Ödeme planı veri erişimi
├── utils/                     # Yardımcı araçlar
│   ├── kmh_validator.dart              # KMH validasyon
│   └── cache_manager.dart              # Önbellek yönetimi
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

## 💰 KMH (Kredili Mevduat Hesabı) Kullanımı

### KMH Hesabı Ekleme
1. **Ana Sayfa** → **Cüzdanlar** → **+ Ekle**
2. **Banka Hesabı** seçin
3. Banka adı, kredi limiti ve faiz oranını girin
4. **Kaydet** butonuna tıklayın

### KMH Özellikleri
- **Otomatik Faiz Hesaplama**: Her gün saat 00:00'da otomatik faiz tahakkuku
- **Limit Uyarıları**: %80 ve %95 kullanımda otomatik bildirim
- **Ödeme Planlama**: Farklı ödeme senaryolarını karşılaştırın
- **Çoklu Hesap**: Birden fazla KMH hesabını karşılaştırın
- **Detaylı Raporlama**: Ekstre, işlem geçmişi ve istatistikler

### Detaylı Dokümantasyon
- 📘 [KMH Kullanıcı Kılavuzu](docs/KMH_USER_GUIDE.md) - Adım adım kullanım talimatları
- 📚 [KMH API Dokümantasyonu](docs/KMH_API.md) - Teknik detaylar ve kod örnekleri
- ❓ [KMH Sık Sorulan Sorular](docs/KMH_FAQ.md) - Yaygın sorular ve çözümler
- 📊 [İstatistik Kullanıcı Kılavuzu](docs/STATISTICS_USER_GUIDE.md) - İstatistik ekranı rehberi
- 🔧 [İstatistik API Dokümantasyonu](docs/STATISTICS_API.md) - İstatistik servisleri API'si

## 🔄 Veri Geçişi

Eski fatura sistemi kullanıyorsanız:
- Uygulama ilk açılışta otomatik olarak verileri yeni yapıya dönüştürür
- Eski veriler `bills_backup` anahtarında yedeklenir
- Yeni yapı: `BillTemplate` (şablonlar) + `BillPayment` (ödemeler)

## 💻 Kod Yapısı

Bu proje temiz kod prensiplerini ve modern Flutter best practice'lerini takip eder:

### Mimari
- **Katmanlı Mimari**: UI → Service → Repository → Data
- **Separation of Concerns**: Her katman kendi sorumluluğuna odaklanır
- **Dependency Injection**: Servisler singleton pattern ile yönetilir
- **State Management**: StatefulWidget ve FutureBuilder kombinasyonu

### Kod Kalitesi
- ✅ Türkçe yorumlar (kullanıcı arayüzü Türkçe)
- ✅ Açık ve tanımlayıcı değişken/fonksiyon isimleri
- ✅ Comprehensive API dokümantasyonu
- ✅ %85+ test coverage
- ✅ Property-based testing
- ✅ Performans optimizasyonları

### Veri Yönetimi
- **JSON Serileştirme**: Tüm modeller için otomatik serileştirme
- **Migration Servisleri**: Geriye dönük uyumluluk
- **Cache Yönetimi**: Akıllı önbellekleme stratejisi
- **Hata Yönetimi**: Merkezi hata yönetimi ve loglama

### Performans
- **Lazy Loading**: Sadece görünür widget'lar yüklenir
- **Pagination**: Büyük veri setleri sayfalanır
- **Background Compute**: Ağır hesaplamalar isolate'te çalışır
- **Debouncing/Throttling**: Gereksiz hesaplamalar önlenir
- **Memory Management**: Otomatik bellek optimizasyonu

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
