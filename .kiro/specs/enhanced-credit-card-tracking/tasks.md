# Uygulama Planı

- [ ] 1. Veri modellerini oluştur ve mevcut modelleri genişlet
  - Yeni Hive type ID'leri ile RewardPoints, RewardTransaction, LimitAlert, PaymentSimulation modellerini oluştur
  - CreditCard modeline yeni alanlar ekle (cardImagePath, iconName, rewardType, pointsConversionRate, cashAdvanceRate, cashAdvanceLimit)
  - CreditCardTransaction modeline yeni alanlar ekle (deferredMonths, installmentStartDate, isCashAdvance, pointsEarned)
  - Tüm modeller için Hive type adapter'ları oluştur (build_runner ile)
  - _Gereksinimler: 1.2, 1.3, 4.1, 4.2, 8.1, 3.2_

- [ ] 1.1 Veri modelleri için özellik testi yaz
  - **Özellik 2: Fotoğraf Optimizasyonu**
  - **Doğrular: Gereksinim 1.3**

- [ ] 1.2 Veri modelleri için özellik testi yaz
  - **Özellik 8: Puan Türü Kaydı**
  - **Doğrular: Gereksinim 4.1**

- [ ] 2. Repository katmanını oluştur
  - RewardPointsRepository oluştur (CRUD operasyonları)
  - LimitAlertRepository oluştur (CRUD operasyonları)
  - Mevcut repository'lere yeni model desteği ekle
  - _Gereksinimler: 4.1, 4.2, 6.1, 6.2, 6.3_

- [ ] 3. RewardPointsService'i implement et
  - Puan yönetimi metodlarını implement et (initializeRewards, addPoints, spendPoints)
  - Otomatik puan hesaplama metodlarını implement et (calculatePointsForTransaction, awardPointsForTransaction)
  - Puan geçmişi ve özet metodlarını implement et
  - _Gereksinimler: 4.1, 4.2, 4.3, 4.5_

- [ ] 3.1 RewardPointsService için özellik testi yaz
  - **Özellik 9: Puan Dönüşüm Oranı**
  - **Doğrular: Gereksinim 4.2**

- [ ] 3.2 RewardPointsService için özellik testi yaz
  - **Özellik 10: Otomatik Puan Hesaplama**
  - **Doğrular: Gereksinim 4.3**

- [ ] 3.3 RewardPointsService için özellik testi yaz
  - **Özellik 11: Puan Bakiyesi Invariant'ı**
  - **Doğrular: Gereksinim 4.5**

- [ ] 4. DeferredInstallmentService'i implement et
  - Ertelenmiş taksit oluşturma metodunu implement et
  - Ertelenmiş taksit sorgulama metodlarını implement et
  - Ertelenmiş taksit aktivasyon metodunu implement et
  - _Gereksinimler: 3.2, 3.4_

- [ ] 4.1 DeferredInstallmentService için özellik testi yaz
  - **Özellik 5: Taksitli İşlem Kaydı**
  - **Doğrular: Gereksinim 3.1**

- [ ] 4.2 DeferredInstallmentService için özellik testi yaz
  - **Özellik 6: Ertelenmiş Taksit Tarihi**
  - **Doğrular: Gereksinim 3.2**

- [ ] 4.3 DeferredInstallmentService için özellik testi yaz
  - **Özellik 7: Taksit Bitişi Bildirimi**
  - **Doğrular: Gereksinim 3.4**

- [ ] 5. LimitAlertService'i implement et
  - Limit uyarı yönetimi metodlarını implement et (initializeAlertsForCard, checkAndTriggerAlerts)
  - Limit hesaplama metodlarını implement et (calculateUtilizationPercentage, shouldTriggerAlert)
  - Bildirim entegrasyonu metodlarını implement et
  - _Gereksinimler: 6.1, 6.2, 6.3, 6.4, 6.5, 2.4_

- [ ] 5.1 LimitAlertService için özellik testi yaz
  - **Özellik 4: Limit Kullanım Vurgulama**
  - **Doğrular: Gereksinim 2.4**

- [ ] 5.2 LimitAlertService için özellik testi yaz
  - **Özellik 17: %80 Limit Uyarısı**
  - **Doğrular: Gereksinim 6.1**

- [ ] 5.3 LimitAlertService için özellik testi yaz
  - **Özellik 18: %90 Limit Uyarısı**
  - **Doğrular: Gereksinim 6.2**

- [ ] 5.4 LimitAlertService için özellik testi yaz
  - **Özellik 19: %100 Limit Uyarısı**
  - **Doğrular: Gereksinim 6.3**

- [ ] 5.5 LimitAlertService için özellik testi yaz
  - **Özellik 20: Limit Uyarısı İçeriği**
  - **Doğrular: Gereksinim 6.4**

- [ ] 5.6 LimitAlertService için özellik testi yaz
  - **Özellik 21: Ödeme Sonrası Limit Güncelleme**
  - **Doğrular: Gereksinim 6.5**

- [ ] 6. PaymentSimulatorService'i implement et
  - Ödeme simülasyon metodlarını implement et (simulatePayment, simulateMinimumPayment, simulateFullPayment)
  - Erken kapatma simülasyonu metodunu implement et
  - Karşılaştırmalı analiz metodlarını implement et
  - Faiz tasarrufu hesaplama metodunu implement et
  - _Gereksinimler: 7.2, 7.3, 7.4_

- [ ] 6.1 PaymentSimulatorService için özellik testi yaz
  - **Özellik 22: Kalan Borç ve Faiz Hesaplama**
  - **Doğrular: Gereksinim 7.2**

- [ ] 6.2 PaymentSimulatorService için özellik testi yaz
  - **Özellik 23: Asgari Ödeme Faiz Hesaplama**
  - **Doğrular: Gereksinim 7.3**

- [ ] 6.3 PaymentSimulatorService için özellik testi yaz
  - **Özellik 24: Erken Kapatma Faiz Tasarrufu**
  - **Doğrular: Gereksinim 7.4**

- [ ] 7. CashAdvanceService'i implement et
  - Nakit avans yönetimi metodlarını implement et (recordCashAdvance)
  - Nakit avans sorgu metodlarını implement et (getCashAdvances, getTotalCashAdvanceDebt)
  - Nakit avans faiz hesaplama metodlarını implement et
  - _Gereksinimler: 8.1, 8.2, 8.4, 8.5_

- [ ] 7.1 CashAdvanceService için özellik testi yaz
  - **Özellik 25: Nakit Avans İşaretleme**
  - **Doğrular: Gereksinim 8.1**

- [ ] 7.2 CashAdvanceService için özellik testi yaz
  - **Özellik 26: Nakit Avans Faiz Oranı**
  - **Doğrular: Gereksinim 8.2**

- [ ] 7.3 CashAdvanceService için özellik testi yaz
  - **Özellik 27: Günlük Nakit Avans Faizi**
  - **Doğrular: Gereksinim 8.4**

- [ ] 7.4 CashAdvanceService için özellik testi yaz
  - **Özellik 28: Nakit Avans Ödeme Önceliği**
  - **Doğrular: Gereksinim 8.5**

- [ ] 8. CardReportingService'i implement et
  - Kart bazlı raporlama metodlarını implement et (getMonthlySpendingTrend, compareCardUsage)
  - Karşılaştırmalı analiz metodlarını implement et (getMostUsedCard, getCardUtilizationComparison)
  - Trend analizi metodlarını implement et
  - _Gereksinimler: 11.2, 11.3, 11.4, 11.5_

- [ ] 8.1 CardReportingService için özellik testi yaz
  - **Özellik 37: En Çok Harcama Yapılan Kart**
  - **Doğrular: Gereksinim 11.2**

- [ ] 8.2 CardReportingService için özellik testi yaz
  - **Özellik 38: Kategori Bazlı Kart Kullanımı**
  - **Doğrular: Gereksinim 11.3**

- [ ] 8.3 CardReportingService için özellik testi yaz
  - **Özellik 39: Yıllık Faiz Hesaplama**
  - **Doğrular: Gereksinim 11.4**

- [ ] 8.4 CardReportingService için özellik testi yaz
  - **Özellik 40: Kart Sıralama**
  - **Doğrular: Gereksinim 11.5**

- [ ] 9. DashboardService'i implement et
  - Dashboard özet veri metodlarını implement et (getDashboardSummary, getTotalDebtAllCards)
  - Grafik veri hazırlama metodlarını implement et
  - Yaklaşan ödeme metodlarını implement et
  - _Gereksinimler: 14.1, 14.2, 14.3_

- [ ] 9.1 DashboardService için özellik testi yaz
  - **Özellik 1: Kullanılabilir Limit Invariant'ı**
  - **Doğrular: Gereksinim 2.2**

- [ ] 9.2 DashboardService için özellik testi yaz
  - **Özellik 50: Dashboard Kullanılabilir Limit**
  - **Doğrular: Gereksinim 14.3**

- [ ] 10. SMSParserService'i implement et (Android)
  - SMS okuma ve izin yönetimi metodlarını implement et
  - SMS parse etme metodlarını implement et (parseBankSMS, detectBank)
  - Otomatik işlem önerisi metodlarını implement et
  - Banka SMS formatları için regex pattern'ları tanımla
  - _Gereksinimler: 12.1, 12.2, 12.3, 12.4, 12.5_

- [ ] 10.1 SMSParserService için özellik testi yaz
  - **Özellik 41: SMS Okuma ve Analiz**
  - **Doğrular: Gereksinim 12.1**

- [ ] 10.2 SMSParserService için özellik testi yaz
  - **Özellik 42: SMS Parse Etme**
  - **Doğrular: Gereksinim 12.2**

- [ ] 10.3 SMSParserService için özellik testi yaz
  - **Özellik 43: SMS'ten İşlem Önerisi**
  - **Doğrular: Gereksinim 12.3**

- [ ] 10.4 SMSParserService için özellik testi yaz
  - **Özellik 44: Öneri Onaylama**
  - **Doğrular: Gereksinim 12.4**

- [ ] 11. Bildirim sistemini genişlet
  - CreditCardNotificationService'e yeni bildirim tipleri ekle
  - Limit uyarı bildirimleri implement et (scheduleLimitAlert)
  - Ekstre kesim bildirimleri implement et (scheduleStatementCutNotification)
  - Taksit bitişi bildirimleri implement et (scheduleInstallmentEndingNotification)
  - Ertelenmiş taksit başlangıç bildirimleri implement et
  - _Gereksinimler: 5.1, 5.2, 5.3, 5.4, 5.5, 13.1, 13.2_

- [ ] 11.1 Bildirim sistemi için özellik testi yaz
  - **Özellik 12: 7 Gün Öncesi Ödeme Hatırlatması**
  - **Doğrular: Gereksinim 5.1**

- [ ] 11.2 Bildirim sistemi için özellik testi yaz
  - **Özellik 13: 3 Gün Öncesi Ödeme Hatırlatması**
  - **Doğrular: Gereksinim 5.2**

- [ ] 11.3 Bildirim sistemi için özellik testi yaz
  - **Özellik 14: Son Gün Ödeme Hatırlatması**
  - **Doğrular: Gereksinim 5.3**

- [ ] 11.4 Bildirim sistemi için özellik testi yaz
  - **Özellik 15: Bildirim İçeriği Doğruluğu**
  - **Doğrular: Gereksinim 5.4**

- [ ] 11.5 Bildirim sistemi için özellik testi yaz
  - **Özellik 16: Bildirim Ayarları Uygulaması**
  - **Doğrular: Gereksinim 5.5**

- [ ] 11.6 Bildirim sistemi için özellik testi yaz
  - **Özellik 46: Ekstre Kesim Bildirimi**
  - **Doğrular: Gereksinim 13.1**

- [ ] 11.7 Bildirim sistemi için özellik testi yaz
  - **Özellik 47: Ekstre Bildirim İçeriği**
  - **Doğrular: Gereksinim 13.2**

- [ ] 12. Mevcut CreditCardService'i güncelle
  - Puan kazanımı entegrasyonu ekle (harcama eklendiğinde otomatik puan)
  - Nakit avans kontrolü ekle (işlem eklenirken)
  - Limit uyarı kontrolü ekle (işlem ve ödeme sonrası)
  - Dönem borcu hesaplama güncelle
  - _Gereksinimler: 4.3, 8.1, 6.5, 9.2, 9.3_

- [ ] 12.1 CreditCardService güncellemeleri için özellik testi yaz
  - **Özellik 29: Dönem Borcu Hesaplama**
  - **Doğrular: Gereksinim 9.2**

- [ ] 12.2 CreditCardService güncellemeleri için özellik testi yaz
  - **Özellik 30: Harcama Dönem Borcu Ekleme**
  - **Doğrular: Gereksinim 9.3**

- [ ] 12.3 CreditCardService güncellemeleri için özellik testi yaz
  - **Özellik 31: Eski Dönem Borcu Ödeme Önceliği**
  - **Doğrular: Gereksinim 9.4**

- [ ] 12.4 CreditCardService güncellemeleri için özellik testi yaz
  - **Özellik 32: Toplam Borç Hesaplama**
  - **Doğrular: Gereksinim 9.5**

- [ ] 13. Checkpoint - Tüm testlerin geçtiğinden emin ol
  - Tüm testlerin geçtiğinden emin ol, sorular çıkarsa kullanıcıya sor.

- [ ] 14. Kart ekleme/düzenleme ekranlarını güncelle
  - AddCreditCardScreen'e yeni alanlar ekle (puan türü, dönüşüm oranı, nakit avans oranı)
  - Kart fotoğrafı yükleme özelliği ekle
  - Renk ve ikon seçici ekle
  - Form validasyonlarını güncelle
  - _Gereksinimler: 1.1, 1.2, 1.3, 4.1, 4.2_

- [ ] 15. Kart detay ekranını güncelle
  - Puan bakiyesi ve TL karşılığı gösterimi ekle
  - Nakit avans borcu ayrı bölümü ekle
  - Dönem borcu ve toplam borç ayrımı ekle
  - Aktif taksitler tablosu ekle
  - Kullanılabilir limit gösterimi güncelle
  - _Gereksinimler: 2.1, 2.2, 2.5, 3.3, 4.4, 8.3, 9.1_

- [ ] 16. Dashboard ekranını güncelle
  - Tüm kartların toplam borç/limit çember grafiği ekle
  - Kart listesi görünümünü güncelle (fotoğraf/ikon desteği)
  - Limit kullanım oranı vurgulama ekle
  - Yaklaşan ödemeler özeti ekle
  - _Gereksinimler: 1.5, 2.3, 2.4, 14.1, 14.2, 14.3, 14.4, 14.5_

- [ ] 17. Ödeme Planlayıcı ekranını oluştur
  - Ödeme tutarı giriş formu oluştur
  - Kalan borç ve faiz hesaplama gösterimi ekle
  - Asgari/tam/kısmi ödeme seçenekleri ekle
  - Erken kapatma simülasyonu bölümü ekle
  - Karşılaştırmalı sonuçlar gösterimi ekle
  - _Gereksinimler: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 18. Puan yönetimi ekranlarını oluştur
  - Puan bakiyesi ve geçmişi ekranı oluştur
  - Puan kullanma formu ekle
  - Puan kazanım geçmişi listesi ekle
  - TL karşılığı hesaplama gösterimi ekle
  - _Gereksinimler: 4.4, 4.5_

- [ ] 19. Taksit detay ekranını oluştur
  - Taksit ödeme takvimi gösterimi ekle
  - Kalan taksit sayısı ve tutar gösterimi ekle
  - Ertelenmiş taksitler için başlangıç tarihi gösterimi ekle
  - Taksit bitişi yaklaşırken uyarı gösterimi ekle
  - _Gereksinimler: 3.3, 3.5_

- [ ] 20. İşlem filtreleme özelliğini ekle
  - İşlemler ekranına kart filtresi ekle
  - Tek ve çoklu kart seçimi desteği ekle
  - Filtrelenmiş toplam tutar gösterimi ekle
  - Filtre temizleme butonu ekle
  - _Gereksinimler: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ] 20.1 İşlem filtreleme için özellik testi yaz
  - **Özellik 33: Tek Kart Filtreleme**
  - **Doğrular: Gereksinim 10.2**

- [ ] 20.2 İşlem filtreleme için özellik testi yaz
  - **Özellik 34: Çoklu Kart Filtreleme**
  - **Doğrular: Gereksinim 10.3**

- [ ] 20.3 İşlem filtreleme için özellik testi yaz
  - **Özellik 35: Filtrelenmiş Toplam Hesaplama**
  - **Doğrular: Gereksinim 10.4**

- [ ] 20.4 İşlem filtreleme için özellik testi yaz
  - **Özellik 36: Filtre Temizleme**
  - **Doğrular: Gereksinim 10.5**

- [ ] 21. Raporlama ekranlarını oluştur
  - Kart bazlı aylık harcama trendi grafiği ekle
  - En çok harcama yapılan kart vurgulama ekle
  - Kategori karşılaştırması ekranı oluştur
  - Yıllık faiz raporu ekle
  - Kart karşılaştırma tablosu ekle
  - _Gereksinimler: 11.1, 11.2, 11.3, 11.4, 11.5_

- [ ] 22. SMS entegrasyonu ekranlarını oluştur (Android)
  - SMS izni isteme dialog'u oluştur
  - SMS'ten işlem önerileri listesi ekranı oluştur
  - Öneri onaylama/reddetme UI'ı ekle
  - SMS parse sonuçları gösterimi ekle
  - _Gereksinimler: 12.1, 12.3, 12.4_

- [ ] 23. Ödeme geçmişi ekranını güncelle
  - Ödeme türü (asgari/tam/kısmi) gösterimi ekle
  - Ödeme sonrası kalan borç gösterimi ekle
  - Kronolojik sıralama uygula
  - Ödeme detay sayfası oluştur
  - _Gereksinimler: 15.1, 15.2, 15.3, 15.4, 15.5_

- [ ] 23.1 Ödeme geçmişi için özellik testi yaz
  - **Özellik 51: Ödeme Kaydı**
  - **Doğrular: Gereksinim 15.1**

- [ ] 23.2 Ödeme geçmişi için özellik testi yaz
  - **Özellik 52: Ödeme Borç Azaltma Invariant'ı**
  - **Doğrular: Gereksinim 15.2**

- [ ] 23.3 Ödeme geçmişi için özellik testi yaz
  - **Özellik 53: Ödeme Kronolojik Sıralama**
  - **Doğrular: Gereksinim 15.3**

- [ ] 24. Bildirim ayarları ekranını güncelle
  - Ödeme hatırlatma gün seçenekleri ekle (3, 5, 7 gün)
  - Limit uyarı eşikleri ayarları ekle (%80, %90, %100)
  - Ekstre kesim bildirimi ayarı ekle
  - Taksit bitişi bildirimi ayarı ekle
  - _Gereksinimler: 5.5_

- [ ] 25. Hata yönetimi ve validasyonları ekle
  - CreditCardException sınıfını oluştur
  - ErrorCodes sabitlerini tanımla
  - Tüm servislere hata yakalama ekle
  - Kullanıcı dostu hata mesajları ekle
  - Hata loglama sistemi entegre et
  - _Gereksinimler: Tüm gereksinimler_

- [ ] 26. Performans optimizasyonları uygula
  - Kart fotoğrafları için image optimization ekle
  - Dashboard için caching mekanizması ekle
  - Uzun listeler için pagination ekle
  - Async operasyonları optimize et
  - _Gereksinimler: Tüm gereksinimler_

- [ ] 27. Veri migration scripti oluştur
  - Mevcut CreditCard verilerini yeni alanlara migrate et
  - Varsayılan değerler ata (rewardType, pointsConversionRate, vb.)
  - Migration test senaryoları oluştur
  - Rollback mekanizması ekle
  - _Gereksinimler: Tüm gereksinimler_

- [ ] 28. Final Checkpoint - Tüm testlerin geçtiğinden emin ol
  - Tüm testlerin geçtiğinden emin ol, sorular çıkarsa kullanıcıya sor.
