# Anasayfa Özet Kartları Güncellemesi

## Yapılan Değişiklikler

### 1. Kaydırılabilir Kart Sistemi

Anasayfadaki özet kartı PageView ile kaydırılabilir iki karta dönüştürüldü:

#### Kart 1: Net Kazanç/Kayıp
- **Başlık**: Ay ve yıl bilgisi eklendi (örn: "Aralık 2025 Net Kazanç")
- **İçerik**: 
  - Aylık net kazanç/kayıp tutarı
  - Aylık gelir
  - Aylık gider
- **Renk**: Kazanç için yeşil, kayıp için kırmızı

#### Kart 2: Toplam Borçlar
- **Başlık**: "Toplam Borçlar"
- **İçerik**:
  - Toplam borç tutarı
  - Kredi kartı borçları
  - KMH borçları
  - Kredi borçları
- **Renk**: Kırmızı tema

### 2. Borç Hesaplamaları

```dart
// 1. Kredi kartı borçları
final creditCardDebts = wallets
    .where((w) => w.type == 'credit_card')
    .fold(0.0, (sum, w) => sum + w.balance.abs());

// 2. KMH borçları (negatif bakiyeli bank hesapları)
final kmhDebts = wallets
    .where((w) => w.type == 'bank' && w.creditLimit > 0 && w.balance < 0)
    .fold(0.0, (sum, w) => sum + w.balance.abs());

// 3. Kredi borçları
final loanDebts = _loans.fold(0.0, (sum, loan) => sum + loan.remainingAmount);

// Toplam borç
final totalDebts = creditCardDebts + kmhDebts + loanDebts;
```

### 3. Ay İsimleri

Türkçe ay isimleri kullanılıyor:
```dart
final monthNames = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];
```

### 4. PageView Yapılandırması

```dart
SizedBox(
  height: 200,
  child: PageView(
    padEnds: false,
    controller: PageController(viewportFraction: 0.9),
    children: [
      _buildNetBalanceCard(...),
      _buildTotalDebtsCard(...),
    ],
  ),
)
```

**Özellikler:**
- `viewportFraction: 0.9`: Her kart ekranın %90'ını kaplar, yan kartlar görünür
- `padEnds: false`: Kenarlarda boşluk bırakmaz
- `height: 200`: Sabit yükseklik

## Kullanıcı Deneyimi

### Kaydırma
- Kullanıcı kartları sağa-sola kaydırarak değiştirebilir
- Yan kartlar hafif görünür (peek effect)
- Smooth animasyon

### Görsel Tasarım
- Her kart yuvarlatılmış köşelere sahip (24px)
- Gölge efekti ile derinlik
- Renk kodlaması:
  - Yeşil: Kazanç/Gelir
  - Kırmızı: Kayıp/Gider/Borç
  - Gri: Nötr bilgiler

### Responsive Davranış
- Kartlar ekran genişliğine göre ölçeklenir
- Padding ve spacing tutarlı
- İkonlar ve metinler okunabilir boyutta

## Borç Kartı Detayları

### Borç Türleri Gösterimi

Borç kartında sadece mevcut borç türleri gösterilir:

1. **Kredi Kartı Borçları**
   - İkon: `Icons.credit_card`
   - Renk: Kırmızı
   - Gösterim: Sadece creditCardDebts > 0 ise

2. **KMH Borçları**
   - İkon: `Icons.account_balance`
   - Renk: Kırmızı
   - Gösterim: Sadece kmhDebts > 0 ise

3. **Kredi Borçları**
   - İkon: `Icons.payments`
   - Renk: Kırmızı
   - Gösterim: Sadece loanDebts > 0 ise

### Borç Yoksa
Eğer hiç borç yoksa:
```
"Borç bulunmamaktadır"
```
mesajı gösterilir.

## Teknik Detaylar

### State Yönetimi
```dart
List<Loan> _loans = [];  // Yeni eklendi
```

### Veri Yükleme
```dart
final loadedLoans = await _dataService.getLoans();
setState(() {
  _loans = loadedLoans;
  // ...
});
```

### Kart Bileşenleri

#### _buildNetBalanceCard
- Parametreler: monthName, year, netBalance, monthlyIncome, monthlyExpense
- Döndürür: Net kazanç/kayıp kartı widget'ı

#### _buildTotalDebtsCard
- Parametreler: totalDebts, creditCardDebts, kmhDebts, loanDebts
- Döndürür: Toplam borçlar kartı widget'ı

#### _buildDebtStat
- Parametreler: label, amount, icon
- Döndürür: Tek bir borç türü istatistiği widget'ı

## Örnek Görünümler

### Senaryo 1: Kazançlı Ay
```
Kart 1:
┌─────────────────────────────┐
│ ↗ Aralık 2025 Net Kazanç    │
│   ₺5,250.00                  │
├─────────────────────────────┤
│ Gelir: ₺15,000  Gider: ₺9,750│
└─────────────────────────────┘
```

### Senaryo 2: Borçlar
```
Kart 2:
┌─────────────────────────────┐
│ 💳 Toplam Borçlar           │
│    ₺23,450.00               │
├─────────────────────────────┤
│ Kredi Kartı  KMH   Krediler │
│ ₺12,000   ₺5,450  ₺6,000    │
└─────────────────────────────┘
```

### Senaryo 3: Borç Yok
```
Kart 2:
┌─────────────────────────────┐
│ 💳 Toplam Borçlar           │
│    ₺0.00                    │
├─────────────────────────────┤
│ Borç bulunmamaktadır        │
└─────────────────────────────┘
```

## Test Önerileri

1. **Kaydırma Testi**
   - Kartları sağa-sola kaydırın
   - Animasyonun smooth olduğunu kontrol edin

2. **Borç Hesaplama Testi**
   - Farklı borç türleri ekleyin
   - Toplamın doğru hesaplandığını kontrol edin

3. **Ay Değişimi Testi**
   - Farklı aylarda uygulamayı açın
   - Ay isminin doğru gösterildiğini kontrol edin

4. **Borç Yoksa Testi**
   - Tüm borçları sıfırlayın
   - "Borç bulunmamaktadır" mesajını kontrol edin

5. **Responsive Test**
   - Farklı ekran boyutlarında test edin
   - Kartların düzgün görüntülendiğini kontrol edin
