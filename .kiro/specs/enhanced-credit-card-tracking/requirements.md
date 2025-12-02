# Gereksinimler Dokümanı

## Giriş

Bu doküman, mevcut kredi kartı takip sistemine eklenecek gelişmiş özellikleri tanımlar. Türk bankacılık sistemine özel taksit takibi, puan/mil yönetimi, akıllı hatırlatmalar ve detaylı raporlama özellikleri içerir. Sistem, kullanıcıların birden fazla kredi kartını etkin şekilde yönetmesini, borç ve taksit planlaması yapmasını, faiz hesaplamaları ile bilinçli kararlar almasını sağlar.

## Sözlük

- **Sistem**: Kredi kartı takip uygulaması
- **Kullanıcı**: Uygulamayı kullanan kişi
- **Kart**: Kredi kartı
- **Ekstre**: Kredi kartı hesap özeti
- **Ekstre Kesim Tarihi**: Kartın aylık harcamalarının toplandığı tarih
- **Son Ödeme Tarihi**: Borç ödemesinin yapılması gereken son tarih
- **Asgari Ödeme**: Ödenebilecek minimum tutar
- **Tam Ödeme**: Toplam borcun tamamının ödenmesi
- **Taksit**: Bir harcamanın bölünmüş ödemeleri
- **Ertelenmiş Taksit**: Ödemesi ileri bir tarihte başlayan taksit
- **Puan/Mil/Cashback**: Kart kullanımından kazanılan ödül puanları
- **Nakit Avans**: Karttan çekilen nakit para
- **Dönem Borcu**: Mevcut ekstre dönemindeki borç
- **Toplam Borç**: Tüm dönemlerdeki toplam borç
- **Limit**: Kartın maksimum kullanım tutarı
- **Kullanılabilir Limit**: Kalan kullanılabilir tutar

## Gereksinimler

### Gereksinim 1: Çoklu Kart Yönetimi

**Kullanıcı Hikayesi:** Kullanıcı olarak, birden fazla kredi kartımı sisteme ekleyip yönetebilmek istiyorum, böylece tüm kartlarımı tek bir yerden takip edebilirim.

#### Kabul Kriterleri

1. WHEN Kullanıcı yeni kart ekleme işlemi başlattığında THEN Sistem kart adı, banka, limit, ekstre kesim günü, son ödeme günü girişi YAPACAKTIR
2. WHEN Kullanıcı kart için özel renk veya ikon seçtiğinde THEN Sistem bu görsel tercihi kaydedip dashboard'da GÖSTERECEKTIR
3. WHEN Kullanıcı kart için fotoğraf yüklediğinde THEN Sistem fotoğrafı optimize edip kart görseli olarak KULLANACAKTIR
4. WHEN Kullanıcı kartın açılış tarihini girdiğinde THEN Sistem ekstre kesim tarihini otomatik olarak HESAPLAYACAKTIR
5. WHEN Kullanıcı dashboard'a eriştiğinde THEN Sistem tüm kartları görsel kartlar halinde LİSTELEYECEKTİR

### Gereksinim 2: Kart Bilgileri ve Durum Gösterimi

**Kullanıcı Hikayesi:** Kullanıcı olarak, her kartımın güncel limit, borç ve ödeme bilgilerini görmek istiyorum, böylece finansal durumumu anlık takip edebilirim.

#### Kabul Kriterleri

1. WHEN Kullanıcı bir kartın detayına girdiğinde THEN Sistem toplam limit, kullanılabilir limit, toplam borç, dönem borcu, asgari ödeme ve son ödeme tarihini GÖSTERECEKTIR
2. WHEN Sistem kullanılabilir limit hesapladığında THEN Sistem toplam limitten toplam borcu çıkararak sonucu HESAPLAYACAKTIR
3. WHEN Kullanıcı ana ekrana eriştiğinde THEN Sistem tüm kartların toplam borcunu ve toplam limitini çember grafikte GÖSTERECEKTIR
4. WHEN Kartın kullanım oranı %80'i geçtiğinde THEN Sistem limite yaklaşma durumunu görsel olarak VURGULAYACAKTİR
5. WHEN Kullanıcı nakit avans kullandığında THEN Sistem nakit avans borcunu ayrı bir bölümde GÖSTERECEKTIR

### Gereksinim 3: Taksit Takibi

**Kullanıcı Hikayesi:** Kullanıcı olarak, kredi kartı taksitlerimi detaylı şekilde takip etmek istiyorum, böylece hangi taksitlerin ne zaman biteceğini ve aylık ödemelerimi görebilirim.

#### Kabul Kriterleri

1. WHEN Kullanıcı taksitli işlem eklediğinde THEN Sistem taksit sayısı, aylık tutar ve başlangıç tarihini KAYDEDECEKTIR
2. WHEN Kullanıcı ertelenmiş taksit eklediğinde THEN Sistem taksit başlangıç tarihini gelecek bir ay olarak AYARLAYACAKTIR
3. WHEN Kullanıcı kart detayına girdiğinde THEN Sistem aktif taksitleri tablo halinde (kaç/kaç kaldı, aylık tutar) GÖSTERECEKTIR
4. WHEN Bir taksit son ödemeye ulaştığında THEN Sistem "taksit bitiyor" bildirimi GÖNDERECEKTIR
5. WHEN Kullanıcı taksit detayına tıkladığında THEN Sistem kalan taksit sayısı ve toplam kalan tutarı GÖSTERECEKTIR

### Gereksinim 4: Puan ve Ödül Takibi

**Kullanıcı Hikayesi:** Kullanıcı olarak, kredi kartlarımdan kazandığım puan, mil ve cashback'leri takip etmek istiyorum, böylece ödüllerimi etkin kullanabilirim.

#### Kabul Kriterleri

1. WHEN Kullanıcı kart eklerken puan türünü seçtiğinde THEN Sistem puan türünü (Bonus, WorldPuan, Mil, Cashback) KAYDEDECEKTIR
2. WHEN Kullanıcı puan değerini (1 puan = X TL) girdiğinde THEN Sistem bu dönüşüm oranını SAKLAYACAKTIR
3. WHEN Kullanıcı harcama eklediğinde THEN Sistem kazanılan puanı otomatik olarak HESAPLAYACAKTIR
4. WHEN Kullanıcı kart detayına girdiğinde THEN Sistem toplam birikmiş puan ve TL karşılığını GÖSTERECEKTIR
5. WHEN Kullanıcı puan kullandığında THEN Sistem puan bakiyesini güncelleyip işlem geçmişine EKLEYECEKTIR

### Gereksinim 5: Akıllı Ödeme Hatırlatmaları

**Kullanıcı Hikayesi:** Kullanıcı olarak, ödeme tarihlerimi kaçırmamak için zamanında bildirim almak istiyorum, böylece gecikme faizi ödemekten kaçınabilirim.

#### Kabul Kriterleri

1. WHEN Son ödeme tarihine 7 gün kaldığında THEN Sistem hatırlatma bildirimi GÖNDERECEKTIR
2. WHEN Son ödeme tarihine 3 gün kaldığında THEN Sistem ikinci hatırlatma bildirimi GÖNDERECEKTIR
3. WHEN Son ödeme tarihi geldiğinde THEN Sistem son hatırlatma bildirimi GÖNDERECEKTIR
4. WHEN Bildirim gönderildiğinde THEN Sistem bildirimde asgari ödeme ve tam ödeme tutarlarını GÖSTERECEKTIR
5. WHEN Kullanıcı bildirim ayarlarını değiştirdiğinde THEN Sistem hatırlatma günlerini kullanıcı tercihine göre AYARLAYACAKTIR

### Gereksinim 6: Limit Uyarıları

**Kullanıcı Hikayesi:** Kullanıcı olarak, kart limitime yaklaştığımda uyarı almak istiyorum, böylece limit aşımından kaçınabilirim.

#### Kabul Kriterleri

1. WHEN Kart kullanımı limitin %80'ine ulaştığında THEN Sistem uyarı bildirimi GÖNDERECEKTIR
2. WHEN Kart kullanımı limitin %90'ına ulaştığında THEN Sistem ikinci uyarı bildirimi GÖNDERECEKTIR
3. WHEN Kart kullanımı limitin %100'üne ulaştığında THEN Sistem limit doldu bildirimi GÖNDERECEKTIR
4. WHEN Limit uyarısı gönderildiğinde THEN Sistem kalan kullanılabilir limiti bildirimde GÖSTERECEKTIR
5. WHEN Kullanıcı ödeme yaptığında THEN Sistem kullanılabilir limiti güncelleyip uyarı durumunu YENİDEN HESAPLAYACAKTIR

### Gereksinim 7: Faiz ve Ödeme Simülasyonu

**Kullanıcı Hikayesi:** Kullanıcı olarak, farklı ödeme senaryolarının faiz etkisini görmek istiyorum, böylece en uygun ödeme planını yapabilirim.

#### Kabul Kriterleri

1. WHEN Kullanıcı "Ödeme Planlayıcı" açtığında THEN Sistem ödeme tutarı girişi için form GÖSTERECEKTIR
2. WHEN Kullanıcı ödeme tutarı girdiğinde THEN Sistem kalan borç ve oluşacak faizi HESAPLAYACAKTIR
3. WHEN Kullanıcı asgari ödeme seçeneğini seçtiğinde THEN Sistem kalan borca uygulanacak faizi GÖSTERECEKTIR
4. WHEN Kullanıcı "Erken Kapatma" simülasyonu başlattığında THEN Sistem tüm borcu ödemenin faiz tasarrufunu HESAPLAYACAKTIR
5. WHEN Simülasyon sonucu gösterildiğinde THEN Sistem aylık faiz oranını ve toplam maliyeti GÖSTERECEKTIR

### Gereksinim 8: Nakit Avans Takibi

**Kullanıcı Hikayesi:** Kullanıcı olarak, nakit avans işlemlerimi ayrı takip etmek istiyorum, çünkü nakit avans farklı faiz oranına sahiptir.

#### Kabul Kriterleri

1. WHEN Kullanıcı nakit avans işlemi eklediğinde THEN Sistem işlemi nakit avans olarak işaretleyip KAYDEDECEKTIR
2. WHEN Nakit avans işlemi kaydedildiğinde THEN Sistem nakit avans faiz oranını UYGULAYACAKTIR
3. WHEN Kullanıcı kart detayına girdiğinde THEN Sistem nakit avans borcunu ayrı bir bölümde GÖSTERECEKTIR
4. WHEN Nakit avans borcu hesaplandığında THEN Sistem günlük faiz hesaplaması YAPACAKTIR
5. WHEN Kullanıcı ödeme yaptığında THEN Sistem önce nakit avans borcuna ödeme UYGULAYACAKTIR

### Gereksinim 9: Dönem ve Toplam Borç Ayrımı

**Kullanıcı Hikayesi:** Kullanıcı olarak, mevcut dönem borcumu ve toplam borcumu ayrı görmek istiyorum, böylece ödeme planımı daha iyi yapabilirim.

#### Kabul Kriterleri

1. WHEN Kullanıcı kart detayına girdiğinde THEN Sistem dönem borcunu ve toplam borcu ayrı satırlarda GÖSTERECEKTIR
2. WHEN Ekstre kesim tarihi geldiğinde THEN Sistem dönem borcunu hesaplayıp KAYDEDECEKTIR
3. WHEN Yeni harcama eklendiğinde THEN Sistem harcamayı dönem borcuna EKLEYECEKTIR
4. WHEN Ödeme yapıldığında THEN Sistem önce eski dönem borçlarına ödeme UYGULAYACAKTIR
5. WHEN Toplam borç hesaplandığında THEN Sistem tüm dönemlerin borçlarını toplayıp GÖSTERECEKTIR

### Gereksinim 10: Kart Bazlı Harcama Filtreleme

**Kullanıcı Hikayesi:** Kullanıcı olarak, işlemlerimi kart bazında filtreleyebilmek istiyorum, böylece belirli bir kartın harcamalarını görebilirim.

#### Kabul Kriterleri

1. WHEN Kullanıcı işlemler sayfasına girdiğinde THEN Sistem kart filtresi seçeneği SUNACAKTIR
2. WHEN Kullanıcı bir kart seçtiğinde THEN Sistem sadece o karta ait işlemleri LİSTELEYECEKTİR
3. WHEN Kullanıcı birden fazla kart seçtiğinde THEN Sistem seçili kartların işlemlerini LİSTELEYECEKTİR
4. WHEN Filtre uygulandığında THEN Sistem filtrelenmiş toplam tutarı GÖSTERECEKTIR
5. WHEN Kullanıcı filtreyi temizlediğinde THEN Sistem tüm kartların işlemlerini LİSTELEYECEKTİR

### Gereksinim 11: Kart Bazlı Raporlama

**Kullanıcı Hikayesi:** Kullanıcı olarak, kartlarımın harcama analizlerini görmek istiyorum, böylece hangi kartı nasıl kullandığımı anlayabilirim.

#### Kabul Kriterleri

1. WHEN Kullanıcı raporlar sayfasına girdiğinde THEN Sistem kart bazlı aylık harcama trendini grafik olarak GÖSTERECEKTIR
2. WHEN Rapor oluşturulduğunda THEN Sistem en çok harcama yapılan kartı VURGULAYACAKTİR
3. WHEN Kullanıcı kategori karşılaştırması seçtiğinde THEN Sistem her kategoride hangi kartın ne kadar kullanıldığını GÖSTERECEKTIR
4. WHEN Yıllık rapor görüntülendiğinde THEN Sistem toplam ödenen kredi kartı faizini HESAPLAYACAKTIR
5. WHEN Kart karşılaştırması yapıldığında THEN Sistem kartları harcama tutarına göre sıralayıp GÖSTERECEKTIR

### Gereksinim 12: SMS ve Bildirim Entegrasyonu

**Kullanıcı Hikayesi:** Kullanıcı olarak, banka SMS'lerinden otomatik işlem oluşturabilmek istiyorum, böylece manuel veri girişi yapmaktan kurtulabilirim.

#### Kabul Kriterleri

1. WHEN Kullanıcı SMS okuma izni verdiğinde THEN Sistem banka SMS'lerini okuyup ANALIZ EDECEKTIR
2. WHEN Banka SMS'i algılandığında THEN Sistem SMS'ten tutar, tarih ve işlem türünü ÇIKARTACAKTIR
3. WHEN SMS parse edildiğinde THEN Sistem otomatik işlem önerisi OLUŞTURACAKTIR
4. WHEN Kullanıcı öneriyi onayladığında THEN Sistem işlemi ilgili karta EKLEYECEKTIR
5. WHERE Android platformunda THEN Sistem SMS okuma iznini KULLANACAKTIR

### Gereksinim 13: Ekstre Kesim Bildirimi

**Kullanıcı Hikayesi:** Kullanıcı olarak, ekstre kesildiğinde bildirim almak istiyorum, böylece aylık harcamalarımı gözden geçirebilirim.

#### Kabul Kriterleri

1. WHEN Ekstre kesim tarihi geldiğinde THEN Sistem ekstre kesildi bildirimi GÖNDERECEKTIR
2. WHEN Bildirim gönderildiğinde THEN Sistem dönem borcunu ve son ödeme tarihini bildirimde GÖSTERECEKTIR
3. WHEN Kullanıcı bildirime tıkladığında THEN Sistem kart detay sayfasını AÇACAKTIR
4. WHEN Ekstre kesildiğinde THEN Sistem yeni dönem için borç hesaplamasını BAŞLATACAKTIR
5. WHEN Birden fazla kartın ekstre kesim tarihi aynı günse THEN Sistem her kart için ayrı bildirim GÖNDERECEKTIR

### Gereksinim 14: Dashboard Özet Görünümü

**Kullanıcı Hikayesi:** Kullanıcı olarak, tüm kartlarımın özetini tek bakışta görmek istiyorum, böylece genel finansal durumumu hızlıca anlayabilirim.

#### Kabul Kriterleri

1. WHEN Kullanıcı ana ekrana girdiğinde THEN Sistem tüm kartların toplam borcunu GÖSTERECEKTIR
2. WHEN Dashboard yüklendiğinde THEN Sistem tüm kartların toplam limitini GÖSTERECEKTIR
3. WHEN Özet hesaplandığında THEN Sistem toplam kullanılabilir limiti çember grafikte GÖSTERECEKTIR
4. WHEN Grafik gösterildiğinde THEN Sistem kullanılan ve kalan limiti farklı renklerle AYIRACAKTIR
5. WHEN Kullanıcı grafiğe tıkladığında THEN Sistem kart listesi sayfasına YÖNLENDİRECEKTİR

### Gereksinim 15: Ödeme Geçmişi ve Takibi

**Kullanıcı Hikayesi:** Kullanıcı olarak, kredi kartı ödemelerimi kaydetmek ve geçmişini görmek istiyorum, böylece ödeme alışkanlıklarımı takip edebilirim.

#### Kabul Kriterleri

1. WHEN Kullanıcı ödeme eklediğinde THEN Sistem ödeme tutarı, tarih ve ödeme türünü (asgari/tam/kısmi) KAYDEDECEKTIR
2. WHEN Ödeme kaydedildiğinde THEN Sistem kart borcunu ödeme tutarı kadar AZALTACAKTIR
3. WHEN Kullanıcı ödeme geçmişine girdiğinde THEN Sistem tüm ödemeleri kronolojik olarak LİSTELEYECEKTİR
4. WHEN Ödeme listesi gösterildiğinde THEN Sistem her ödemenin türünü (asgari/tam/kısmi) GÖSTERECEKTIR
5. WHEN Kullanıcı ödeme detayına tıkladığında THEN Sistem ödeme sonrası kalan borcu GÖSTERECEKTIR
