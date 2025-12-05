# KMH Hesapları İstatistik Güncellemesi

## Sorun
KMH (Kredili Mevduat Hesabı) hesaplarında eksi bakiye borç anlamına gelir, ancak istatistik ekranında bu durum doğru şekilde gösterilmiyordu.

## Yapılan Değişiklikler

### 1. Varlıklar Sekmesi (_buildAssetsTab)

#### Önceki Durum
- Tüm hesapların bakiyesi mutlak değer olarak gösteriliyordu
- KMH borçları ayrı olarak vurgulanmıyordu
- Net toplam hesaplanmıyordu

#### Yeni Durum
```dart
// KMH hesaplarını ayır (creditLimit > 0 olan bank hesapları)
final kmhWallets = assetWallets
    .where((w) => w.type == 'bank' && w.creditLimit > 0)
    .toList();

// Pozitif varlıkları hesapla
final totalPositiveAssets = assetWallets
    .where((w) => w.balance > 0)
    .fold(0.0, (sum, w) => sum + w.balance);

// KMH borçlarını hesapla (negatif bakiyeler)
final totalKmhDebt = kmhWallets
    .where((w) => w.balance < 0)
    .fold(0.0, (sum, w) => sum + w.balance.abs());

// Net toplam (varlıklar - KMH borçları)
final totalAssets = totalPositiveAssets - totalKmhDebt;
```

**Görsel Değişiklikler:**
- Pozitif bakiyeli hesaplar yeşil renkte gösteriliyor
- KMH borçları ayrı bir bölümde kırmızı renkte listeleniyor
- Her KMH hesabının limiti gösteriliyor
- Net toplam hesaplanıyor (varlıklar - borçlar)

### 2. Finansal Varlıklar Kartı (_buildFinancialAssetsCard)

#### Önceki Durum
- Tüm negatif bakiyeler "Borçlar (KMH vb.)" olarak gösteriliyordu
- Net varlık hesaplanmıyordu

#### Yeni Durum
```dart
// KMH hesaplarını ayır
final kmhWallets = assetWallets
    .where((w) => w.type == 'bank' && w.creditLimit > 0)
    .toList();

// KMH borçlarını hesapla
final kmhDebts = kmhWallets
    .where((w) => w.balance < 0)
    .fold(0.0, (sum, w) => sum + w.balance.abs());

// Net toplam varlık
final totalAssets = positiveAssets - kmhDebts;
```

**Görsel Değişiklikler:**
- Pasta grafiğinde KMH borçları kırmızı renkte gösteriliyor
- Merkezdeki toplam net varlık olarak gösteriliyor
- Net varlık negatifse kırmızı renkte gösteriliyor
- "KMH Borçları" satırı ayrı olarak listeleniyor

### 3. Borç ve Alacak Durumu Paneli (_buildDebtReceivablePanel)

#### Önceki Durum
- Sadece kredi kartı ve kredi borçları gösteriliyordu
- KMH borçları dahil edilmiyordu

#### Yeni Durum
```dart
// KMH borçlarını hesapla
final kmhDebts = widget.wallets
    .where((w) => w.type == 'bank' && w.creditLimit > 0 && w.balance < 0)
    .fold(0.0, (sum, w) => sum + w.balance.abs());

// Toplam borç
final totalDebt = totalLoanDebt + creditCardDebts + kmhDebts;
```

**Görsel Değişiklikler:**
- Borç detaylarına "KMH Borçları" satırı eklendi
- Turuncu renkte ve cüzdan ikonu ile gösteriliyor
- Toplam borç hesaplamasına dahil ediliyor

## KMH Hesabı Tanımı

Bir hesabın KMH hesabı olması için:
```dart
w.type == 'bank' && w.creditLimit > 0
```

- `type`: 'bank' olmalı
- `creditLimit`: 0'dan büyük olmalı
- `balance < 0`: Eksi bakiye borç anlamına gelir

## Örnek Senaryolar

### Senaryo 1: KMH Hesabı Pozitif Bakiyeli
```
Hesap: Ziraat KMH
Tip: bank
Limit: 10,000 TL
Bakiye: +2,000 TL
Durum: Varlık olarak gösterilir (yeşil)
```

### Senaryo 2: KMH Hesabı Negatif Bakiyeli
```
Hesap: Ziraat KMH
Tip: bank
Limit: 10,000 TL
Bakiye: -3,000 TL
Durum: Borç olarak gösterilir (kırmızı)
Açıklama: "KMH Borcu - Limit: ₺10,000"
```

### Senaryo 3: Normal Banka Hesabı
```
Hesap: Vadesiz Hesap
Tip: bank
Limit: 0 TL
Bakiye: +5,000 TL
Durum: Normal varlık olarak gösterilir
```

## Hesaplama Formülleri

### Net Varlık
```
Net Varlık = Pozitif Bakiyeler - KMH Borçları
```

### Toplam Borç
```
Toplam Borç = Kredi Kartı Borçları + Kredi Borçları + KMH Borçları
```

### Grafik Yüzdeleri
```
KMH Borç Yüzdesi = (KMH Borçları / (Pozitif Varlıklar + KMH Borçları)) * 100
```

## Test Önerileri

1. **KMH Hesabı Oluşturma**
   - Bank tipinde hesap oluştur
   - Credit limit > 0 ayarla
   - Negatif bakiye gir

2. **İstatistik Kontrolü**
   - Varlıklar sekmesinde KMH borçlarının ayrı gösterildiğini kontrol et
   - Net toplamın doğru hesaplandığını kontrol et
   - Finansal varlıklar kartında KMH borçlarının gösterildiğini kontrol et

3. **Borç Paneli Kontrolü**
   - Borç ve alacak durumu panelinde KMH borçlarının gösterildiğini kontrol et
   - Toplam borcun doğru hesaplandığını kontrol et

## Notlar

- KMH hesapları sadece `type == 'bank'` ve `creditLimit > 0` olan hesaplardır
- Eksi bakiye her zaman borç anlamına gelir
- Pozitif bakiyeli KMH hesapları normal varlık olarak gösterilir
- Tüm hesaplamalar net değer üzerinden yapılır (varlıklar - borçlar)
