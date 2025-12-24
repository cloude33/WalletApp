/// Uygulama genelinde kullanılan metin sabitleri
class AppStrings {
  // Private constructor to prevent instantiation
  AppStrings._();

  // App Info
  static const String appName = 'Para Yönetimi';
  static const String appVersion = '2.0.0';
  
  // General
  static const String ok = 'Tamam';
  static const String cancel = 'İptal';
  static const String save = 'Kaydet';
  static const String delete = 'Sil';
  static const String edit = 'Düzenle';
  static const String add = 'Ekle';
  static const String search = 'Ara';
  static const String filter = 'Filtrele';
  static const String close = 'Kapat';
  static const String back = 'Geri';
  static const String next = 'İleri';
  static const String done = 'Bitti';
  static const String loading = 'Yükleniyor...';
  static const String noData = 'Veri bulunamadı';
  static const String retry = 'Tekrar Dene';
  
  // Errors
  static const String errorTitle = 'Hata';
  static const String networkError = 'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.';
  static const String unknownError = 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
  static const String invalidInput = 'Geçersiz giriş';
  static const String serverError = 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
  static const String timeoutError = 'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.';
  static const String permissionDenied = 'İzin reddedildi';
  static const String notFound = 'Bulunamadı';
  
  // Validation Errors
  static const String emptyField = 'Bu alan boş bırakılamaz';
  static const String invalidAmount = 'Geçersiz tutar';
  static const String invalidDate = 'Geçersiz tarih';
  static const String invalidEmail = 'Geçersiz e-posta adresi';
  static const String invalidPhone = 'Geçersiz telefon numarası';
  static const String invalidPin = 'PIN en az 4 haneli olmalıdır';
  static const String invalidPassword = 'Şifre en az 8 karakter olmalıdır';
  static const String passwordMismatch = 'Şifreler eşleşmiyor';
  static const String amountTooLow = 'Tutar çok düşük';
  static const String amountTooHigh = 'Tutar çok yüksek';
  static const String invalidCreditLimit = 'Geçersiz kredi limiti';
  static const String invalidInterestRate = 'Geçersiz faiz oranı';
  
  // Success Messages
  static const String successTitle = 'Başarılı';
  static const String transactionAdded = 'İşlem başarıyla eklendi';
  static const String transactionUpdated = 'İşlem başarıyla güncellendi';
  static const String transactionDeleted = 'İşlem başarıyla silindi';
  static const String walletAdded = 'Cüzdan başarıyla eklendi';
  static const String walletUpdated = 'Cüzdan başarıyla güncellendi';
  static const String walletDeleted = 'Cüzdan başarıyla silindi';
  static const String categoryAdded = 'Kategori başarıyla eklendi';
  static const String categoryUpdated = 'Kategori başarıyla güncellendi';
  static const String categoryDeleted = 'Kategori başarıyla silindi';
  static const String billAdded = 'Fatura başarıyla eklendi';
  static const String billUpdated = 'Fatura başarıyla güncellendi';
  static const String billDeleted = 'Fatura başarıyla silindi';
  static const String debtAdded = 'Borç başarıyla eklendi';
  static const String debtUpdated = 'Borç başarıyla güncellendi';
  static const String debtDeleted = 'Borç başarıyla silindi';
  static const String savedSuccessfully = 'Başarıyla kaydedildi';
  static const String deletedSuccessfully = 'Başarıyla silindi';
  static const String updatedSuccessfully = 'Başarıyla güncellendi';
  
  // Confirmation Messages
  static const String confirmDelete = 'Silmek istediğinizden emin misiniz?';
  static const String confirmDeleteTransaction = 'Bu işlemi silmek istediğinizden emin misiniz?';
  static const String confirmDeleteWallet = 'Bu cüzdanı silmek istediğinizden emin misiniz?';
  static const String confirmDeleteAll = 'Tüm verileri silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';
  static const String confirmLogout = 'Çıkış yapmak istediğinizden emin misiniz?';
  
  // Transaction Types
  static const String income = 'Gelir';
  static const String expense = 'Gider';
  static const String transfer = 'Transfer';
  
  // Wallet Types
  static const String cash = 'Nakit';
  static const String bank = 'Banka Hesabı';
  static const String creditCard = 'Kredi Kartı';
  static const String overdraft = 'Kredili Mevduat Hesabı (KMH)';
  
  // Categories
  static const String food = 'Yemek';
  static const String transport = 'Ulaşım';
  static const String shopping = 'Alışveriş';
  static const String bills = 'Faturalar';
  static const String entertainment = 'Eğlence';
  static const String health = 'Sağlık';
  static const String education = 'Eğitim';
  static const String other = 'Diğer';
  
  // Bill Categories
  static const String electricity = 'Elektrik';
  static const String water = 'Su';
  static const String gas = 'Doğalgaz';
  static const String internet = 'İnternet';
  static const String phone = 'Telefon';
  static const String rent = 'Kira';
  static const String insurance = 'Sigorta';
  static const String subscription = 'Abonelik';
  
  // Statistics
  static const String statistics = 'İstatistikler';
  static const String cashFlow = 'Nakit Akışı';
  static const String spending = 'Harcama';
  static const String credit = 'Kredi';
  static const String reports = 'Raporlar';
  static const String assets = 'Varlıklar';
  static const String totalIncome = 'Toplam Gelir';
  static const String totalExpense = 'Toplam Gider';
  static const String netCashFlow = 'Net Nakit Akışı';
  static const String balance = 'Bakiye';
  static const String totalAssets = 'Toplam Varlık';
  static const String totalLiabilities = 'Toplam Borç';
  static const String netWorth = 'Net Değer';
  
  // Time Periods
  static const String today = 'Bugün';
  static const String yesterday = 'Dün';
  static const String thisWeek = 'Bu Hafta';
  static const String thisMonth = 'Bu Ay';
  static const String thisYear = 'Bu Yıl';
  static const String lastWeek = 'Geçen Hafta';
  static const String lastMonth = 'Geçen Ay';
  static const String lastYear = 'Geçen Yıl';
  static const String custom = 'Özel';
  static const String all = 'Tümü';
  
  // Security
  static const String enterPin = 'PIN kodunuzu girin';
  static const String createPin = 'PIN kodu oluşturun';
  static const String confirmPin = 'PIN kodunuzu onaylayın';
  static const String wrongPin = 'Yanlış PIN kodu';
  static const String pinMismatch = 'PIN kodları eşleşmiyor';
  static const String biometricAuth = 'Biyometrik Kimlik Doğrulama';
  static const String useBiometric = 'Parmak izi kullan';
  static const String biometricNotAvailable = 'Biyometrik kimlik doğrulama kullanılamıyor';
  static const String tooManyAttempts = 'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.';
  
  // Backup & Restore
  static const String backup = 'Yedekle';
  static const String restore = 'Geri Yükle';
  static const String backupSuccess = 'Yedekleme başarılı';
  static const String restoreSuccess = 'Geri yükleme başarılı';
  static const String backupFailed = 'Yedekleme başarısız';
  static const String restoreFailed = 'Geri yükleme başarısız';
  
  // Export
  static const String export = 'Dışa Aktar';
  static const String exportPdf = 'PDF olarak dışa aktar';
  static const String exportExcel = 'Excel olarak dışa aktar';
  static const String exportCsv = 'CSV olarak dışa aktar';
  static const String exportSuccess = 'Dışa aktarma başarılı';
  static const String exportFailed = 'Dışa aktarma başarısız';
  
  // Settings
  static const String settings = 'Ayarlar';
  static const String profile = 'Profil';
  static const String theme = 'Tema';
  static const String language = 'Dil';
  static const String currency = 'Para Birimi';
  static const String notifications = 'Bildirimler';
  static const String security = 'Güvenlik';
  static const String about = 'Hakkında';
  static const String logout = 'Çıkış Yap';
  
  // Theme
  static const String lightTheme = 'Açık Tema';
  static const String darkTheme = 'Koyu Tema';
  static const String systemTheme = 'Sistem Teması';
  
  // Notifications
  static const String billReminder = 'Fatura Hatırlatıcısı';
  static const String debtReminder = 'Borç Hatırlatıcısı';
  static const String installmentReminder = 'Taksit Hatırlatıcısı';
  static const String kmhAlert = 'KMH Uyarısı';
  static const String limitAlert = 'Limit Uyarısı';
  
  // Empty States
  static const String noTransactions = 'Henüz işlem yok';
  static const String noWallets = 'Henüz cüzdan yok';
  static const String noBills = 'Henüz fatura yok';
  static const String noDebts = 'Henüz borç yok';
  static const String noGoals = 'Henüz hedef yok';
  static const String addFirstTransaction = 'İlk işleminizi ekleyin';
  static const String addFirstWallet = 'İlk cüzdanınızı ekleyin';
}
