# Tasarım Dokümanı

## Genel Bakış

Bu tasarım dokümanı, mevcut Flutter tabanlı kredi kartı takip sistemine eklenecek gelişmiş özelliklerin teknik mimarisini tanımlar. Sistem, Hive veritabanı kullanarak yerel veri saklama, Repository pattern ile veri erişimi ve Service katmanı ile iş mantığı yönetimi sağlamaktadır.

Yeni özellikler mevcut mimariyi genişletecek şekilde tasarlanmıştır:
- Puan/Mil/Cashback takip sistemi
- Ertelenmiş taksit desteği
- Gelişmiş bildirim sistemi (limit uyarıları, ekstre kesim bildirimleri)
- Faiz simülasyon araçları
- Nakit avans ayrı takibi
- Kart bazlı raporlama ve analiz
- SMS entegrasyonu (Android)
- Dashboard özet görünümü

## Mimari

### Mevcut Mimari Yapı

Uygulama üç katmanlı mimari kullanmaktadır:

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│  (Screens, Widgets, UI Components)  │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│          Service Layer              │
│  (Business Logic, Calculations)     │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│        Repository Layer             │
│     (Data Access, Hive Boxes)       │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│          Data Layer                 │
│    (Hive Database, Models)          │
└─────────────────────────────────────┘
```

### Yeni Bileşenler

Gelişmiş özellikler için eklenecek yeni bileşenler:

1. **RewardPointsService**: Puan/Mil/Cashback yönetimi
2. **DeferredInstallmentService**: Ertelenmiş taksit takibi
3. **LimitAlertService**: Limit uyarı sistemi
4. **PaymentSimulatorService**: Faiz ve ödeme simülasyonları
5. **CashAdvanceService**: Nakit avans takibi
6. **CardReportingService**: Kart bazlı raporlama
7. **SMSParserService**: SMS okuma ve parse etme (Android)
8. **DashboardService**: Dashboard özet hesaplamaları

## Bileşenler ve Arayüzler

### 1. Veri Modelleri

#### RewardPoints (Yeni Model)
```dart
@HiveType(typeId: 20)
class RewardPoints {
  @HiveField(0) String id;
  @HiveField(1) String cardId;
  @HiveField(2) String rewardType; // 'bonus', 'worldpuan', 'miles', 'cashback'
  @HiveField(3) double pointsBalance;
  @HiveField(4) double conversionRate; // 1 puan = X TL
  @HiveField(5) DateTime lastUpdated;
  @HiveField(6) DateTime createdAt;
}
```

#### RewardTransaction (Yeni Model)
```dart
@HiveType(typeId: 21)
class RewardTransaction {
  @HiveField(0) String id;
  @HiveField(1) String cardId;
  @HiveField(2) String transactionId; // İlişkili harcama
  @HiveField(3) double pointsEarned;
  @HiveField(4) double pointsSpent;
  @HiveField(5) String description;
  @HiveField(6) DateTime transactionDate;
  @HiveField(7) DateTime createdAt;
}
```

#### CreditCard (Genişletilmiş)
Mevcut CreditCard modeline eklenecek alanlar:
```dart
@HiveField(12) String? cardImagePath; // Kullanıcı yüklediği fotoğraf
@HiveField(13) String? iconName; // Seçilen ikon
@HiveField(14) String? rewardType; // 'bonus', 'worldpuan', 'miles', 'cashback'
@HiveField(15) double? pointsConversionRate; // 1 puan = X TL
@HiveField(16) double? cashAdvanceRate; // Nakit avans faiz oranı
@HiveField(17) double? cashAdvanceLimit; // Nakit avans limiti
```

#### CreditCardTransaction (Genişletilmiş)
Mevcut CreditCardTransaction modeline eklenecek alanlar:
```dart
@HiveField(9) int? deferredMonths; // Ertelenmiş taksit için kaç ay sonra başlayacak
@HiveField(10) DateTime? installmentStartDate; // Taksit başlangıç tarihi
@HiveField(11) bool isCashAdvance; // Nakit avans mı?
@HiveField(12) double? pointsEarned; // Bu işlemden kazanılan puan
```

#### LimitAlert (Yeni Model)
```dart
@HiveType(typeId: 22)
class LimitAlert {
  @HiveField(0) String id;
  @HiveField(1) String cardId;
  @HiveField(2) double threshold; // %80, %90, %100
  @HiveField(3) bool isTriggered;
  @HiveField(4) DateTime? triggeredAt;
  @HiveField(5) DateTime createdAt;
}
```

#### PaymentSimulation (Yeni Model)
```dart
@HiveType(typeId: 23)
class PaymentSimulation {
  @HiveField(0) String id;
  @HiveField(1) String cardId;
  @HiveField(2) double currentDebt;
  @HiveField(3) double proposedPayment;
  @HiveField(4) double remainingDebt;
  @HiveField(5) double interestCharged;
  @HiveField(6) int monthsToPayoff;
  @HiveField(7) double totalCost;
  @HiveField(8) DateTime simulationDate;
}
```

### 2. Repository Katmanı

#### RewardPointsRepository (Yeni)
```dart
class RewardPointsRepository {
  Future<RewardPoints?> findByCardId(String cardId);
  Future<void> save(RewardPoints points);
  Future<void> update(RewardPoints points);
  Future<List<RewardTransaction>> getTransactions(String cardId);
  Future<void> addTransaction(RewardTransaction transaction);
}
```

#### LimitAlertRepository (Yeni)
```dart
class LimitAlertRepository {
  Future<List<LimitAlert>> findByCardId(String cardId);
  Future<void> save(LimitAlert alert);
  Future<void> update(LimitAlert alert);
  Future<void> resetAlerts(String cardId);
}
```

### 3. Service Katmanı

#### RewardPointsService (Yeni)
```dart
class RewardPointsService {
  // Puan yönetimi
  Future<RewardPoints> initializeRewards(String cardId, String rewardType, double conversionRate);
  Future<void> addPoints(String cardId, double points, String description);
  Future<void> spendPoints(String cardId, double points, String description);
  Future<double> getPointsBalance(String cardId);
  Future<double> getPointsValueInCurrency(String cardId);
  
  // Otomatik puan hesaplama
  Future<double> calculatePointsForTransaction(String cardId, double amount);
  Future<void> awardPointsForTransaction(String transactionId);
  
  // Puan geçmişi
  Future<List<RewardTransaction>> getPointsHistory(String cardId);
  Future<Map<String, dynamic>> getPointsSummary(String cardId);
}
```

#### DeferredInstallmentService (Yeni)
```dart
class DeferredInstallmentService {
  // Ertelenmiş taksit yönetimi
  Future<CreditCardTransaction> createDeferredInstallment({
    required String cardId,
    required double amount,
    required String description,
    required int installmentCount,
    required int deferredMonths,
  });
  
  // Ertelenmiş taksit sorgulama
  Future<List<CreditCardTransaction>> getDeferredInstallments(String cardId);
  Future<List<CreditCardTransaction>> getInstallmentsStartingThisMonth(String cardId);
  Future<Map<DateTime, List<CreditCardTransaction>>> getDeferredInstallmentSchedule(String cardId);
  
  // Ertelenmiş taksit aktivasyonu
  Future<void> activateDeferredInstallments(DateTime currentDate);
}
```

#### LimitAlertService (Yeni)
```dart
class LimitAlertService {
  // Limit uyarı yönetimi
  Future<void> initializeAlertsForCard(String cardId);
  Future<void> checkAndTriggerAlerts(String cardId);
  Future<List<LimitAlert>> getActiveAlerts(String cardId);
  Future<void> resetAlertsAfterPayment(String cardId);
  
  // Limit hesaplamaları
  Future<double> calculateUtilizationPercentage(String cardId);
  Future<bool> shouldTriggerAlert(String cardId, double threshold);
  
  // Bildirim entegrasyonu
  Future<void> sendLimitNotification(String cardId, double utilization);
}
```

#### PaymentSimulatorService (Yeni)
```dart
class PaymentSimulatorService {
  // Ödeme simülasyonları
  Future<PaymentSimulation> simulatePayment({
    required String cardId,
    required double paymentAmount,
  });
  
  Future<Map<String, dynamic>> simulateMinimumPayment(String cardId);
  Future<Map<String, dynamic>> simulateFullPayment(String cardId);
  
  // Erken kapatma simülasyonu
  Future<Map<String, dynamic>> simulateEarlyPayoff(String cardId);
  
  // Karşılaştırmalı analiz
  Future<Map<String, dynamic>> comparePaymentOptions(String cardId, List<double> paymentAmounts);
  
  // Faiz tasarrufu hesaplama
  Future<double> calculateInterestSavings({
    required String cardId,
    required double proposedPayment,
  });
}
```

#### CashAdvanceService (Yeni)
```dart
class CashAdvanceService {
  // Nakit avans yönetimi
  Future<CreditCardTransaction> recordCashAdvance({
    required String cardId,
    required double amount,
    required String description,
  });
  
  // Nakit avans sorguları
  Future<List<CreditCardTransaction>> getCashAdvances(String cardId);
  Future<double> getTotalCashAdvanceDebt(String cardId);
  Future<double> getAvailableCashAdvanceLimit(String cardId);
  
  // Nakit avans faiz hesaplama
  Future<double> calculateCashAdvanceInterest(String cardId);
  Future<Map<String, dynamic>> getCashAdvanceSummary(String cardId);
}
```

#### CardReportingService (Yeni)
```dart
class CardReportingService {
  // Kart bazlı raporlama
  Future<Map<String, dynamic>> getMonthlySpendingTrend(String cardId, int months);
  Future<Map<String, dynamic>> compareCardUsage();
  Future<Map<String, dynamic>> getCategoryBreakdownByCard(String categoryId);
  Future<double> getTotalInterestPaidYearly(String cardId);
  
  // Karşılaştırmalı analizler
  Future<Map<String, dynamic>> getMostUsedCard();
  Future<Map<String, dynamic>> getCardUtilizationComparison();
  Future<Map<String, dynamic>> getCardEfficiencyReport();
  
  // Trend analizleri
  Future<List<Map<String, dynamic>>> getSpendingTrendAllCards(int months);
  Future<Map<String, dynamic>> getYearlyCardSummary(String cardId, int year);
}
```

#### SMSParserService (Yeni - Android Only)
```dart
class SMSParserService {
  // SMS okuma ve parse
  Future<bool> requestSMSPermission();
  Future<List<String>> readBankSMS();
  Future<Map<String, dynamic>?> parseBankSMS(String smsBody);
  
  // Otomatik işlem önerisi
  Future<CreditCardTransaction?> createTransactionFromSMS(String smsBody);
  Future<List<Map<String, dynamic>>> getSuggestedTransactions();
  
  // Banka SMS formatları
  Map<String, RegExp> getBankSMSPatterns();
  String? detectBank(String smsBody);
}
```

#### DashboardService (Yeni)
```dart
class DashboardService {
  // Dashboard özet verileri
  Future<Map<String, dynamic>> getDashboardSummary();
  Future<double> getTotalDebtAllCards();
  Future<double> getTotalLimitAllCards();
  Future<double> getTotalAvailableCreditAllCards();
  Future<double> getOverallUtilizationPercentage();
  
  // Grafik verileri
  Future<Map<String, double>> getDebtDistributionByCard();
  Future<Map<String, double>> getLimitUtilizationByCard();
  
  // Yaklaşan ödemeler
  Future<List<Map<String, dynamic>>> getUpcomingPayments(int days);
  Future<double> getTotalDueNextWeek();
  Future<double> getTotalDueNextMonth();
}
```

### 4. Bildirim Sistemi Genişletmeleri

Mevcut `CreditCardNotificationService` genişletilecek:

```dart
class CreditCardNotificationService {
  // Mevcut metodlar...
  
  // Yeni bildirim tipleri
  Future<void> scheduleLimitAlert(String cardId, double utilization);
  Future<void> scheduleStatementCutNotification(String cardId, DateTime cutDate);
  Future<void> scheduleInstallmentEndingNotification(String transactionId);
  Future<void> scheduleDeferredInstallmentStartNotification(String transactionId);
  
  // Bildirim yönetimi
  Future<void> cancelLimitAlerts(String cardId);
  Future<void> updatePaymentReminders(String cardId);
}
```

## Veri Modelleri

### Hive Type ID Atamaları

Yeni modeller için Hive type ID'leri:
- RewardPoints: 20
- RewardTransaction: 21
- LimitAlert: 22
- PaymentSimulation: 23

### Veri İlişkileri

```
CreditCard (1) ─────── (1) RewardPoints
    │
    ├─── (N) CreditCardTransaction
    │         │
    │         └─── (1) RewardTransaction
    │
    ├─── (N) CreditCardStatement
    │         │
    │         └─── (N) CreditCardPayment
    │
    └─── (N) LimitAlert
```

### Veri Akışı

1. **Harcama Ekleme Akışı**:
   ```
   User Input → Validation → Transaction Creation → 
   Points Calculation → Limit Check → Alert Trigger → 
   Notification Schedule → Database Save
   ```

2. **Ödeme Akışı**:
   ```
   Payment Input → Statement Update → Debt Recalculation → 
   Alert Reset → Limit Update → Notification Cancel → 
   Database Save
   ```

3. **Ekstre Kesim Akışı**:
   ```
   Scheduled Job → Statement Generation → 
   Installment Processing → Interest Calculation → 
   Notification Send → Database Save
   ```

## Hata Yönetimi

### Hata Tipleri

1. **Validation Errors**: Model validasyon hataları
2. **Business Logic Errors**: İş kuralı ihlalleri (limit aşımı, vb.)
3. **Database Errors**: Hive veritabanı hataları
4. **Permission Errors**: SMS okuma izni hataları (Android)
5. **Calculation Errors**: Faiz hesaplama hataları

### Hata Yönetim Stratejisi

```dart
class CreditCardException implements Exception {
  final String message;
  final String code;
  final dynamic details;
  
  CreditCardException(this.message, this.code, [this.details]);
}

// Hata kodları
class ErrorCodes {
  static const String LIMIT_EXCEEDED = 'LIMIT_EXCEEDED';
  static const String INVALID_TRANSACTION = 'INVALID_TRANSACTION';
  static const String CARD_NOT_FOUND = 'CARD_NOT_FOUND';
  static const String INSUFFICIENT_POINTS = 'INSUFFICIENT_POINTS';
  static const String SMS_PERMISSION_DENIED = 'SMS_PERMISSION_DENIED';
  static const String CALCULATION_ERROR = 'CALCULATION_ERROR';
}
```

### Hata Yakalama ve Loglama

```dart
try {
  await service.addTransaction(transaction);
} on CreditCardException catch (e) {
  // Kullanıcıya anlamlı hata mesajı göster
  showErrorDialog(e.message);
  // Hata logla
  logger.error('Transaction failed: ${e.code}', e.details);
} catch (e) {
  // Beklenmeyen hatalar
  showErrorDialog('Bir hata oluştu');
  logger.error('Unexpected error', e);
}
```

## Test Stratejisi

### Test Piramidi

```
        ┌─────────────┐
        │  UI Tests   │  (Az sayıda)
        └─────────────┘
      ┌─────────────────┐
      │ Integration Tests│  (Orta sayıda)
      └─────────────────┘
    ┌───────────────────────┐
    │     Unit Tests        │  (Çok sayıda)
    └───────────────────────┘
```

### Unit Test Kapsamı

Her servis için unit testler yazılacak:

1. **RewardPointsService Tests**
   - Puan ekleme/çıkarma
   - Puan hesaplama
   - Dönüşüm oranı hesaplama

2. **DeferredInstallmentService Tests**
   - Ertelenmiş taksit oluşturma
   - Taksit aktivasyonu
   - Zamanlama hesaplamaları

3. **LimitAlertService Tests**
   - Limit kontrolü
   - Uyarı tetikleme
   - Eşik hesaplamaları

4. **PaymentSimulatorService Tests**
   - Faiz hesaplamaları
   - Ödeme simülasyonları
   - Karşılaştırma analizleri

5. **CashAdvanceService Tests**
   - Nakit avans kaydı
   - Faiz hesaplama
   - Limit kontrolü

6. **CardReportingService Tests**
   - Rapor oluşturma
   - Trend hesaplamaları
   - Karşılaştırma analizleri

7. **SMSParserService Tests**
   - SMS parse etme
   - Banka tespiti
   - İşlem önerisi oluşturma

8. **DashboardService Tests**
   - Özet hesaplamaları
   - Grafik veri hazırlama
   - Toplam hesaplamalar

### Property-Based Testing

Property-based testing için Dart'ta `test` paketi ve `faker` paketi kullanılacaktır. Her servis için önemli özellikler test edilecektir.

Test konfigürasyonu:
- Minimum 100 iterasyon
- Random seed kaydedilecek
- Başarısız durumlar için shrinking yapılacak

### Integration Tests

Servisler arası entegrasyon testleri:
- Transaction → Points → Notification akışı
- Payment → Statement → Alert akışı
- SMS → Transaction → Points akışı

### UI Tests

Kritik kullanıcı akışları için widget testleri:
- Kart ekleme akışı
- Harcama ekleme akışı
- Ödeme yapma akışı
- Dashboard görüntüleme

## Doğruluk Özellikleri


*Bir özellik, sistemin tüm geçerli yürütmelerinde doğru olması gereken bir karakteristik veya davranıştır - esasen, sistemin ne yapması gerektiği hakkında resmi bir ifadedir. Özellikler, insan tarafından okunabilir spesifikasyonlar ile makine tarafından doğrulanabilir doğruluk garantileri arasında köprü görevi görür.*

### Özellik Yansıması

Prework analizini gözden geçirdikten sonra, aşağıdaki özellikler belirlenmiştir. Gereksiz tekrarları önlemek için bazı özellikler birleştirilmiş veya kaldırılmıştır:

- Limit hesaplama özellikleri (2.2) ve borç azaltma özellikleri (15.2) temel invariant'lardır ve ayrı tutulmalıdır
- Bildirim özellikleri (5.1-5.3, 6.1-6.3, 13.1) benzer mantığa sahip ancak farklı tetikleyicilere sahiptir, bu nedenle ayrı tutulmalıdır
- UI render testleri (örnekler) özellik testlerinden ayrı tutulmalıdır
- Hesaplama özellikleri (faiz, puan, taksit) her biri benzersiz doğrulama değeri sağlar

### Doğruluk Özellikleri

#### Özellik 1: Kullanılabilir Limit Invariant'ı
*Herhangi bir* kredi kartı için, kullanılabilir limit her zaman toplam limitten toplam borç çıkartılarak hesaplanmalıdır
**Doğrular: Gereksinim 2.2**

#### Özellik 2: Fotoğraf Optimizasyonu
*Herhangi bir* yüklenen kart fotoğrafı için, sistem fotoğrafı optimize etmeli ve kart görseli olarak kaydetmelidir
**Doğrular: Gereksinim 1.3**

#### Özellik 3: Ekstre Kesim Tarihi Hesaplama
*Herhangi bir* kart açılış tarihi için, sistem ekstre kesim tarihini doğru hesaplamalıdır
**Doğrular: Gereksinim 1.4**

#### Özellik 4: Limit Kullanım Vurgulama
*Herhangi bir* kart için, kullanım oranı %80'i geçtiğinde sistem limite yaklaşma durumunu görsel olarak vurgulamalıdır
**Doğrular: Gereksinim 2.4**

#### Özellik 5: Taksitli İşlem Kaydı
*Herhangi bir* taksitli işlem için, sistem taksit sayısı, aylık tutar ve başlangıç tarihini doğru kaydetmelidir
**Doğrular: Gereksinim 3.1**

#### Özellik 6: Ertelenmiş Taksit Tarihi
*Herhangi bir* ertelenmiş taksit için, sistem taksit başlangıç tarihini belirtilen ay sayısı kadar ileriye ayarlamalıdır
**Doğrular: Gereksinim 3.2**

#### Özellik 7: Taksit Bitişi Bildirimi
*Herhangi bir* taksit için, son ödemeye ulaştığında sistem "taksit bitiyor" bildirimi göndermelidir
**Doğrular: Gereksinim 3.4**

#### Özellik 8: Puan Türü Kaydı
*Herhangi bir* puan türü seçimi için, sistem puan türünü doğru kaydetmelidir
**Doğrular: Gereksinim 4.1**

#### Özellik 9: Puan Dönüşüm Oranı
*Herhangi bir* dönüşüm oranı için, sistem oranı doğru saklamalı ve hesaplamalarda kullanmalıdır
**Doğrular: Gereksinim 4.2**

#### Özellik 10: Otomatik Puan Hesaplama
*Herhangi bir* harcama için, sistem kazanılan puanı otomatik olarak doğru hesaplamalıdır
**Doğrular: Gereksinim 4.3**

#### Özellik 11: Puan Bakiyesi Invariant'ı
*Herhangi bir* puan kullanımı için, yeni bakiye eski bakiyeden kullanılan puan çıkartılarak hesaplanmalıdır
**Doğrular: Gereksinim 4.5**

#### Özellik 12: 7 Gün Öncesi Ödeme Hatırlatması
*Herhangi bir* kart için, son ödeme tarihine 7 gün kaldığında sistem hatırlatma bildirimi göndermelidir
**Doğrular: Gereksinim 5.1**

#### Özellik 13: 3 Gün Öncesi Ödeme Hatırlatması
*Herhangi bir* kart için, son ödeme tarihine 3 gün kaldığında sistem ikinci hatırlatma bildirimi göndermelidir
**Doğrular: Gereksinim 5.2**

#### Özellik 14: Son Gün Ödeme Hatırlatması
*Herhangi bir* kart için, son ödeme tarihi geldiğinde sistem son hatırlatma bildirimi göndermelidir
**Doğrular: Gereksinim 5.3**

#### Özellik 15: Bildirim İçeriği Doğruluğu
*Herhangi bir* ödeme hatırlatma bildirimi için, bildirim asgari ödeme ve tam ödeme tutarlarını içermelidir
**Doğrular: Gereksinim 5.4**

#### Özellik 16: Bildirim Ayarları Uygulaması
*Herhangi bir* bildirim ayarı değişikliği için, sistem hatırlatma günlerini kullanıcı tercihine göre ayarlamalıdır
**Doğrular: Gereksinim 5.5**

#### Özellik 17: %80 Limit Uyarısı
*Herhangi bir* kart için, kullanım limitin %80'ine ulaştığında sistem uyarı bildirimi göndermelidir
**Doğrular: Gereksinim 6.1**

#### Özellik 18: %90 Limit Uyarısı
*Herhangi bir* kart için, kullanım limitin %90'ına ulaştığında sistem ikinci uyarı bildirimi göndermelidir
**Doğrular: Gereksinim 6.2**

#### Özellik 19: %100 Limit Uyarısı
*Herhangi bir* kart için, kullanım limitin %100'üne ulaştığında sistem limit doldu bildirimi göndermelidir
**Doğrular: Gereksinim 6.3**

#### Özellik 20: Limit Uyarısı İçeriği
*Herhangi bir* limit uyarısı için, bildirim kalan kullanılabilir limiti içermelidir
**Doğrular: Gereksinim 6.4**

#### Özellik 21: Ödeme Sonrası Limit Güncelleme
*Herhangi bir* ödeme için, sistem kullanılabilir limiti güncellemeli ve uyarı durumunu yeniden hesaplamalıdır
**Doğrular: Gereksinim 6.5**

#### Özellik 22: Kalan Borç ve Faiz Hesaplama
*Herhangi bir* ödeme tutarı için, sistem kalan borç ve oluşacak faizi doğru hesaplamalıdır
**Doğrular: Gereksinim 7.2**

#### Özellik 23: Asgari Ödeme Faiz Hesaplama
*Herhangi bir* asgari ödeme seçimi için, sistem kalan borca uygulanacak faizi doğru hesaplamalıdır
**Doğrular: Gereksinim 7.3**

#### Özellik 24: Erken Kapatma Faiz Tasarrufu
*Herhangi bir* erken kapatma simülasyonu için, sistem tüm borcu ödemenin faiz tasarrufunu doğru hesaplamalıdır
**Doğrular: Gereksinim 7.4**

#### Özellik 25: Nakit Avans İşaretleme
*Herhangi bir* nakit avans işlemi için, sistem işlemi nakit avans olarak işaretleyip kaydetmelidir
**Doğrular: Gereksinim 8.1**

#### Özellik 26: Nakit Avans Faiz Oranı
*Herhangi bir* nakit avans işlemi için, sistem nakit avans faiz oranını uygulamalıdır
**Doğrular: Gereksinim 8.2**

#### Özellik 27: Günlük Nakit Avans Faizi
*Herhangi bir* nakit avans borcu için, sistem günlük faiz hesaplaması yapmalıdır
**Doğrular: Gereksinim 8.4**

#### Özellik 28: Nakit Avans Ödeme Önceliği
*Herhangi bir* ödeme için, sistem önce nakit avans borcuna ödeme uygulamalıdır
**Doğrular: Gereksinim 8.5**

#### Özellik 29: Dönem Borcu Hesaplama
*Herhangi bir* ekstre kesim tarihi için, sistem dönem borcunu hesaplayıp kaydetmelidir
**Doğrular: Gereksinim 9.2**

#### Özellik 30: Harcama Dönem Borcu Ekleme
*Herhangi bir* yeni harcama için, yeni dönem borcu eski dönem borcuna harcama eklenerek hesaplanmalıdır
**Doğrular: Gereksinim 9.3**

#### Özellik 31: Eski Dönem Borcu Ödeme Önceliği
*Herhangi bir* ödeme için, sistem önce eski dönem borçlarına ödeme uygulamalıdır
**Doğrular: Gereksinim 9.4**

#### Özellik 32: Toplam Borç Hesaplama
*Herhangi bir* kart için, toplam borç tüm dönemlerin borçlarının toplamı olmalıdır
**Doğrular: Gereksinim 9.5**

#### Özellik 33: Tek Kart Filtreleme
*Herhangi bir* kart seçimi için, sistem sadece o karta ait işlemleri listelemelidir
**Doğrular: Gereksinim 10.2**

#### Özellik 34: Çoklu Kart Filtreleme
*Herhangi bir* çoklu kart seçimi için, sistem seçili kartların işlemlerini listelemelidir
**Doğrular: Gereksinim 10.3**

#### Özellik 35: Filtrelenmiş Toplam Hesaplama
*Herhangi bir* filtre uygulaması için, sistem filtrelenmiş toplam tutarı doğru hesaplamalıdır
**Doğrular: Gereksinim 10.4**

#### Özellik 36: Filtre Temizleme
*Herhangi bir* filtre temizleme için, sistem tüm kartların işlemlerini listelemelidir
**Doğrular: Gereksinim 10.5**

#### Özellik 37: En Çok Harcama Yapılan Kart
*Herhangi bir* rapor oluşturma için, sistem en çok harcama yapılan kartı doğru tespit etmelidir
**Doğrular: Gereksinim 11.2**

#### Özellik 38: Kategori Bazlı Kart Kullanımı
*Herhangi bir* kategori karşılaştırması için, sistem her kategoride hangi kartın ne kadar kullanıldığını doğru hesaplamalıdır
**Doğrular: Gereksinim 11.3**

#### Özellik 39: Yıllık Faiz Hesaplama
*Herhangi bir* yıllık rapor için, sistem toplam ödenen kredi kartı faizini doğru hesaplamalıdır
**Doğrular: Gereksinim 11.4**

#### Özellik 40: Kart Sıralama
*Herhangi bir* kart karşılaştırması için, sistem kartları harcama tutarına göre doğru sıralamalıdır
**Doğrular: Gereksinim 11.5**

#### Özellik 41: SMS Okuma ve Analiz
*Herhangi bir* SMS okuma izni için, sistem banka SMS'lerini okuyup analiz etmelidir
**Doğrular: Gereksinim 12.1**

#### Özellik 42: SMS Parse Etme
*Herhangi bir* banka SMS'i için, sistem SMS'ten tutar, tarih ve işlem türünü doğru çıkartmalıdır
**Doğrular: Gereksinim 12.2**

#### Özellik 43: SMS'ten İşlem Önerisi
*Herhangi bir* parse edilmiş SMS için, sistem otomatik işlem önerisi oluşturmalıdır
**Doğrular: Gereksinim 12.3**

#### Özellik 44: Öneri Onaylama
*Herhangi bir* öneri onayı için, sistem işlemi ilgili karta eklemelidir
**Doğrular: Gereksinim 12.4**

#### Özellik 45: Android SMS İzni
*Android platformunda*, sistem SMS okuma iznini kullanmalıdır
**Doğrular: Gereksinim 12.5**

#### Özellik 46: Ekstre Kesim Bildirimi
*Herhangi bir* ekstre kesim tarihi için, sistem ekstre kesildi bildirimi göndermelidir
**Doğrular: Gereksinim 13.1**

#### Özellik 47: Ekstre Bildirim İçeriği
*Herhangi bir* ekstre bildirimi için, bildirim dönem borcunu ve son ödeme tarihini içermelidir
**Doğrular: Gereksinim 13.2**

#### Özellik 48: Ekstre Sonrası Hesaplama
*Herhangi bir* ekstre kesimi için, sistem yeni dönem için borç hesaplamasını başlatmalıdır
**Doğrular: Gereksinim 13.4**

#### Özellik 49: Çoklu Ekstre Bildirimleri
*Herhangi bir* aynı gün ekstre kesimi için, sistem her kart için ayrı bildirim göndermelidir
**Doğrular: Gereksinim 13.5**

#### Özellik 50: Dashboard Kullanılabilir Limit
*Herhangi bir* dashboard özet hesaplaması için, sistem toplam kullanılabilir limiti doğru hesaplamalıdır
**Doğrular: Gereksinim 14.3**

#### Özellik 51: Ödeme Kaydı
*Herhangi bir* ödeme için, sistem ödeme tutarı, tarih ve ödeme türünü doğru kaydetmelidir
**Doğrular: Gereksinim 15.1**

#### Özellik 52: Ödeme Borç Azaltma Invariant'ı
*Herhangi bir* ödeme için, yeni borç eski borçtan ödeme tutarı çıkartılarak hesaplanmalıdır
**Doğrular: Gereksinim 15.2**

#### Özellik 53: Ödeme Kronolojik Sıralama
*Herhangi bir* ödeme geçmişi sorgusu için, sistem tüm ödemeleri kronolojik olarak sıralamalıdır
**Doğrular: Gereksinim 15.3**

## Test Stratejisi (Devam)

### Property-Based Testing Kütüphanesi

Dart için property-based testing kütüphanesi olarak **test** paketi ile birlikte **faker** paketi kullanılacaktır. Daha gelişmiş property-based testing için **glados** paketi değerlendirilebilir.

```yaml
dev_dependencies:
  test: ^1.24.0
  faker: ^2.1.0
  # glados: ^0.1.0  # Opsiyonel, daha gelişmiş PBT için
```

### Property Test Yapılandırması

Her property-based test şu yapıda olacaktır:

```dart
import 'package:test/test.dart';
import 'package:faker/faker.dart';

void main() {
  group('RewardPointsService Property Tests', () {
    test('Property 11: Puan Bakiyesi Invariant\'ı', () {
      // Feature: enhanced-credit-card-tracking, Property 11: Puan Bakiyesi Invariant'ı
      final faker = Faker();
      
      for (int i = 0; i < 100; i++) {
        // Generate random test data
        final oldBalance = faker.randomGenerator.decimal(scale: 1000);
        final pointsUsed = faker.randomGenerator.decimal(scale: oldBalance);
        
        // Execute operation
        final newBalance = oldBalance - pointsUsed;
        
        // Assert property
        expect(newBalance, equals(oldBalance - pointsUsed));
        expect(newBalance, greaterThanOrEqualTo(0));
      }
    });
  });
}
```

### Unit Test Örnekleri

#### RewardPointsService Unit Tests

```dart
test('should calculate points correctly for transaction', () async {
  final service = RewardPointsService();
  final cardId = 'test-card-1';
  final amount = 100.0;
  
  // Setup: 1 TL = 1 puan
  await service.initializeRewards(cardId, 'bonus', 1.0);
  
  final points = await service.calculatePointsForTransaction(cardId, amount);
  
  expect(points, equals(100.0));
});

test('should throw error when spending more points than available', () async {
  final service = RewardPointsService();
  final cardId = 'test-card-1';
  
  await service.initializeRewards(cardId, 'bonus', 1.0);
  await service.addPoints(cardId, 50.0, 'Test');
  
  expect(
    () => service.spendPoints(cardId, 100.0, 'Test'),
    throwsA(isA<CreditCardException>()),
  );
});
```

#### PaymentSimulatorService Unit Tests

```dart
test('should calculate interest correctly for minimum payment', () async {
  final service = PaymentSimulatorService();
  final cardId = 'test-card-1';
  
  // Setup card with debt
  final simulation = await service.simulateMinimumPayment(cardId);
  
  expect(simulation['remainingDebt'], greaterThan(0));
  expect(simulation['interestCharged'], greaterThan(0));
});

test('should show zero interest for full payment', () async {
  final service = PaymentSimulatorService();
  final cardId = 'test-card-1';
  
  final simulation = await service.simulateFullPayment(cardId);
  
  expect(simulation['remainingDebt'], equals(0));
  expect(simulation['interestCharged'], equals(0));
});
```

### Integration Test Örnekleri

```dart
testWidgets('Complete transaction flow with points', (tester) async {
  // 1. Add transaction
  await tester.tap(find.byKey(Key('add-transaction-button')));
  await tester.pumpAndSettle();
  
  // 2. Fill form
  await tester.enterText(find.byKey(Key('amount-field')), '100');
  await tester.tap(find.byKey(Key('save-button')));
  await tester.pumpAndSettle();
  
  // 3. Verify points were awarded
  expect(find.text('100 puan kazandınız'), findsOneWidget);
  
  // 4. Verify limit was updated
  final limitWidget = find.byKey(Key('available-limit'));
  expect(limitWidget, findsOneWidget);
});
```

### Test Coverage Hedefleri

- Unit Tests: %80+ kod coverage
- Property Tests: Tüm kritik özellikler için
- Integration Tests: Ana kullanıcı akışları için
- Widget Tests: Tüm ekranlar için

### Continuous Testing

Test otomasyonu için GitHub Actions veya benzeri CI/CD araçları kullanılacaktır:

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - run: flutter test --coverage --reporter=json > test-results.json
```

## Performans Değerlendirmeleri

### Performans Hedefleri

1. **Veri Okuma**: < 50ms (Hive box'tan okuma)
2. **Veri Yazma**: < 100ms (Hive box'a yazma)
3. **Hesaplama İşlemleri**: < 200ms (faiz, puan hesaplamaları)
4. **Dashboard Yükleme**: < 500ms (tüm kartların özeti)
5. **Rapor Oluşturma**: < 1s (aylık raporlar)
6. **SMS Parse**: < 100ms (tek SMS)

### Optimizasyon Stratejileri

1. **Lazy Loading**: Büyük listeler için sayfalama
2. **Caching**: Sık kullanılan hesaplamaları cache'leme
3. **Batch Operations**: Toplu işlemler için batch API'ler
4. **Index Kullanımı**: Hive box'larda index kullanımı
5. **Async Operations**: Tüm I/O işlemleri async

### Bellek Yönetimi

1. **Image Optimization**: Kart fotoğrafları için otomatik sıkıştırma
2. **List Pagination**: Uzun listelerde sayfalama
3. **Dispose Pattern**: Widget'larda proper dispose
4. **Stream Subscription**: Stream'lerin düzgün kapatılması

## Güvenlik Değerlendirmeleri

### Veri Güvenliği

1. **Hive Encryption**: Hassas veriler için Hive encryption kullanımı
2. **Secure Storage**: PIN ve şifreler için flutter_secure_storage
3. **Data Validation**: Tüm input'lar için validasyon
4. **SQL Injection Prevention**: Hive NoSQL olduğu için risk yok

### İzin Yönetimi

1. **SMS Permission**: Android'de runtime permission
2. **Storage Permission**: Fotoğraf yükleme için
3. **Notification Permission**: Bildirimler için
4. **Permission Rationale**: Kullanıcıya izin gerekçesi gösterme

### Veri Gizliliği

1. **Local Storage**: Tüm veriler cihazda saklanır
2. **No Cloud Sync**: Varsayılan olarak cloud sync yok
3. **Export Encryption**: Export edilen verilerin şifrelenmesi
4. **Backup Security**: Backup dosyalarının şifrelenmesi

## Deployment Stratejisi

### Platform Desteği

- **Android**: API 21+ (Android 5.0+)
- **iOS**: iOS 12+
- **Web**: Modern browsers (Chrome, Firefox, Safari, Edge)
- **Desktop**: Windows, macOS, Linux (opsiyonel)

### Release Süreci

1. **Development**: Feature branch'lerde geliştirme
2. **Testing**: Test suite'in çalıştırılması
3. **Code Review**: PR review süreci
4. **Staging**: Beta test için staging release
5. **Production**: Store'lara production release

### Versiyonlama

Semantic versioning kullanılacaktır: MAJOR.MINOR.PATCH

- **MAJOR**: Breaking changes
- **MINOR**: Yeni özellikler (backward compatible)
- **PATCH**: Bug fixes

### Migration Stratejisi

Mevcut kullanıcılar için veri migration:

```dart
class MigrationService {
  Future<void> migrateToVersion2() async {
    // Add new fields to existing CreditCard models
    final cards = await _cardRepo.findAll();
    for (var card in cards) {
      final updated = card.copyWith(
        rewardType: 'bonus', // Default value
        pointsConversionRate: 1.0,
        cashAdvanceRate: card.monthlyInterestRate * 1.5,
      );
      await _cardRepo.update(updated);
    }
  }
}
```

## Bakım ve Destek

### Monitoring

1. **Error Tracking**: Sentry veya Firebase Crashlytics
2. **Analytics**: Firebase Analytics veya Mixpanel
3. **Performance Monitoring**: Firebase Performance
4. **User Feedback**: In-app feedback formu

### Dokümantasyon

1. **Code Documentation**: Dart doc comments
2. **API Documentation**: Service ve repository metodları için
3. **User Guide**: Kullanıcı kılavuzu
4. **Developer Guide**: Geliştirici dokümantasyonu

### Güncellemeler

1. **Bug Fixes**: Hızlı patch release'ler
2. **Feature Updates**: Aylık minor release'ler
3. **Major Updates**: Yıllık major release'ler
4. **Security Updates**: Gerektiğinde acil güncellemeler

## Sonuç

Bu tasarım dokümanı, gelişmiş kredi kartı takip özelliklerinin teknik mimarisini tanımlar. Mevcut Flutter/Hive mimarisi üzerine inşa edilmiş, test edilebilir ve ölçeklenebilir bir çözüm sunar. Property-based testing ile doğruluk garantisi, kapsamlı hata yönetimi ve performans optimizasyonları ile kullanıcı deneyimini ön planda tutar.
