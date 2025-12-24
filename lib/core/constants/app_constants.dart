/// Uygulama genelinde kullanılan sabit değerler
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // Database
  static const String dbName = 'money_app.db';
  static const int dbVersion = 1;
  
  // SharedPreferences Keys
  static const String keyCurrentUser = 'current_user';
  static const String keyUsers = 'users';
  static const String keyWallets = 'wallets';
  static const String keyTransactions = 'transactions';
  static const String keyCategories = 'categories';
  static const String keyGoals = 'goals';
  static const String keyLoans = 'loans';
  static const String keyBillTemplates = 'bill_templates';
  static const String keyBillPayments = 'bill_payments';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int loadMoreThreshold = 80; // Load more when 80% scrolled
  
  // Cache
  static const Duration cacheExpiration = Duration(minutes: 5);
  static const Duration shortCacheExpiration = Duration(minutes: 1);
  static const Duration longCacheExpiration = Duration(hours: 1);
  
  // Validation
  static const int minPinLength = 4;
  static const int maxPinLength = 6;
  static const double minTransactionAmount = 0.01;
  static const double maxTransactionAmount = 1000000000.0; // 1 milyar
  static const int maxDescriptionLength = 200;
  static const int maxMemoLength = 500;
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  
  // Interest Rates
  static const double minInterestRate = 0.0;
  static const double maxInterestRate = 100.0;
  static const double defaultKmhInterestRate = 3.5; // Aylık %3.5
  
  // Credit Limits
  static const double minCreditLimit = 0.0;
  static const double maxCreditLimit = 10000000.0; // 10 milyon
  
  // Installments
  static const int minInstallments = 2;
  static const int maxInstallments = 36;
  static const List<int> commonInstallments = [2, 3, 4, 6, 9, 12, 18, 24, 36];
  
  // UI
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  static const double cardElevation = 2.0;
  
  // Animation
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Notification
  static const int defaultBillReminderDays = 3;
  static const int defaultDebtReminderDays = 7;
  static const int defaultInstallmentReminderDays = 3;
  
  // KMH Alerts
  static const double defaultKmhWarningThreshold = 80.0; // %80
  static const double defaultKmhCriticalThreshold = 95.0; // %95
  
  // Session
  static const Duration sessionTimeout = Duration(minutes: 30);
  static const Duration autoLockDuration = Duration(minutes: 5);
  
  // Rate Limiting
  static const int maxLoginAttempts = 5;
  static const Duration loginAttemptWindow = Duration(minutes: 15);
  static const int maxApiCallsPerMinute = 60;
  
  // File Upload
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  static const int imageQuality = 85;
  
  // Export
  static const String exportDateFormat = 'yyyy-MM-dd_HH-mm-ss';
  static const String displayDateFormat = 'dd.MM.yyyy';
  static const String displayDateTimeFormat = 'dd.MM.yyyy HH:mm';
  
  // Currency
  static const String defaultCurrency = 'TRY';
  static const List<String> supportedCurrencies = [
    'TRY',
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CHF',
    'CAD',
    'AUD',
    'CNY',
    'RUB',
    'SAR',
    'AED',
  ];
  
  // Locale
  static const String defaultLocale = 'tr_TR';
  
  // Chart
  static const int maxChartDataPoints = 12;
  static const double chartAnimationDuration = 1.5; // seconds
  
  // Backup
  static const int maxBackupFiles = 10;
  static const Duration autoBackupInterval = Duration(days: 7);
}
