import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @home.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get home;

  /// No description provided for @cards.
  ///
  /// In tr, this message translates to:
  /// **'Kartlar'**
  String get cards;

  /// No description provided for @stats.
  ///
  /// In tr, this message translates to:
  /// **'İstatistik'**
  String get stats;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @income.
  ///
  /// In tr, this message translates to:
  /// **'Gelir'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In tr, this message translates to:
  /// **'Gider'**
  String get expense;

  /// No description provided for @addTransaction.
  ///
  /// In tr, this message translates to:
  /// **'İşlem Ekle'**
  String get addTransaction;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @generalSettings.
  ///
  /// In tr, this message translates to:
  /// **'Genel Ayarlar'**
  String get generalSettings;

  /// No description provided for @theme.
  ///
  /// In tr, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @netWorth.
  ///
  /// In tr, this message translates to:
  /// **'Net Varlık'**
  String get netWorth;

  /// No description provided for @totalAssets.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Varlık'**
  String get totalAssets;

  /// No description provided for @totalDebts.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Borç'**
  String get totalDebts;

  /// No description provided for @selectLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Dil Seçin'**
  String get selectLanguage;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @transactions.
  ///
  /// In tr, this message translates to:
  /// **'İşlemler'**
  String get transactions;

  /// No description provided for @today.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get yesterday;

  /// No description provided for @addExpense.
  ///
  /// In tr, this message translates to:
  /// **'Gider Ekle'**
  String get addExpense;

  /// No description provided for @addIncome.
  ///
  /// In tr, this message translates to:
  /// **'Gelir Ekle'**
  String get addIncome;

  /// No description provided for @addBill.
  ///
  /// In tr, this message translates to:
  /// **'Fatura Ekle'**
  String get addBill;

  /// No description provided for @addWallet.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan Ekle'**
  String get addWallet;

  /// No description provided for @netLoss.
  ///
  /// In tr, this message translates to:
  /// **'Net Kayıp'**
  String get netLoss;

  /// No description provided for @netGain.
  ///
  /// In tr, this message translates to:
  /// **'Net Kâr'**
  String get netGain;

  /// No description provided for @accountSection.
  ///
  /// In tr, this message translates to:
  /// **'HESAP'**
  String get accountSection;

  /// No description provided for @generalSection.
  ///
  /// In tr, this message translates to:
  /// **'GENEL'**
  String get generalSection;

  /// No description provided for @dataSection.
  ///
  /// In tr, this message translates to:
  /// **'VERİ YÖNETİMİ'**
  String get dataSection;

  /// No description provided for @securitySection.
  ///
  /// In tr, this message translates to:
  /// **'GÜVENLİK'**
  String get securitySection;

  /// No description provided for @otherSection.
  ///
  /// In tr, this message translates to:
  /// **'DİĞER'**
  String get otherSection;

  /// No description provided for @dangerZone.
  ///
  /// In tr, this message translates to:
  /// **'TEHLİKELİ BÖLGE'**
  String get dangerZone;

  /// No description provided for @profile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @email.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// No description provided for @changePassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Değiştir'**
  String get changePassword;

  /// No description provided for @myWallets.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdanlarım'**
  String get myWallets;

  /// No description provided for @myBills.
  ///
  /// In tr, this message translates to:
  /// **'Faturalarım'**
  String get myBills;

  /// No description provided for @categories.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriler'**
  String get categories;

  /// No description provided for @debts.
  ///
  /// In tr, this message translates to:
  /// **'Borç/Alacak Takibi'**
  String get debts;

  /// No description provided for @recurringTransactions.
  ///
  /// In tr, this message translates to:
  /// **'Tekrarlayan İşlemler'**
  String get recurringTransactions;

  /// No description provided for @notifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notifications;

  /// No description provided for @currency.
  ///
  /// In tr, this message translates to:
  /// **'Para Birimi'**
  String get currency;

  /// No description provided for @export.
  ///
  /// In tr, this message translates to:
  /// **'Dışa Aktar'**
  String get export;

  /// No description provided for @backup.
  ///
  /// In tr, this message translates to:
  /// **'Yedekle'**
  String get backup;

  /// No description provided for @restore.
  ///
  /// In tr, this message translates to:
  /// **'Geri Yükle'**
  String get restore;

  /// No description provided for @cloudBackup.
  ///
  /// In tr, this message translates to:
  /// **'Bulut Yedekleme'**
  String get cloudBackup;

  /// No description provided for @autoLock.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik Kilit'**
  String get autoLock;

  /// No description provided for @biometricAuth.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik Kimlik Doğrulama'**
  String get biometricAuth;

  /// No description provided for @help.
  ///
  /// In tr, this message translates to:
  /// **'Yardım'**
  String get help;

  /// No description provided for @about.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get about;

  /// No description provided for @logout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logout;

  /// No description provided for @resetApp.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı Sıfırla'**
  String get resetApp;

  /// No description provided for @userDefault.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get userDefault;

  /// No description provided for @notSpecified.
  ///
  /// In tr, this message translates to:
  /// **'Belirtilmemiş'**
  String get notSpecified;

  /// No description provided for @updatePasswordDesc.
  ///
  /// In tr, this message translates to:
  /// **'Giriş şifrenizi güncelleyin'**
  String get updatePasswordDesc;

  /// No description provided for @manageWalletsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdanlarınızı ve hesaplarınızı yönetin'**
  String get manageWalletsDesc;

  /// No description provided for @manageBillsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Fatura şablonlarınızı yönetin'**
  String get manageBillsDesc;

  /// No description provided for @manageCategoriesDesc.
  ///
  /// In tr, this message translates to:
  /// **'Gelir ve gider kategorilerini yönetin'**
  String get manageCategoriesDesc;

  /// No description provided for @trackDebtsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Borç ve alacaklarınızı takip edin'**
  String get trackDebtsDesc;

  /// No description provided for @manageRecurringDesc.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik işlemlerinizi yönetin'**
  String get manageRecurringDesc;

  /// No description provided for @notificationsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatmalar ve uyarılar'**
  String get notificationsDesc;

  /// No description provided for @exportDesc.
  ///
  /// In tr, this message translates to:
  /// **'Verileri dışa aktar'**
  String get exportDesc;

  /// No description provided for @backupDesc.
  ///
  /// In tr, this message translates to:
  /// **'Verilerinizi yedekleyin'**
  String get backupDesc;

  /// No description provided for @restoreDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yedekten geri yükleyin'**
  String get restoreDesc;

  /// No description provided for @cloudBackupDesc.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive yedekleme'**
  String get cloudBackupDesc;

  /// No description provided for @biometricDesc.
  ///
  /// In tr, this message translates to:
  /// **'Parmak izi ile kilidi aç'**
  String get biometricDesc;

  /// No description provided for @faqDesc.
  ///
  /// In tr, this message translates to:
  /// **'SSS ve destek'**
  String get faqDesc;

  /// No description provided for @logoutDesc.
  ///
  /// In tr, this message translates to:
  /// **'Hesaptan çık'**
  String get logoutDesc;

  /// No description provided for @resetAppDesc.
  ///
  /// In tr, this message translates to:
  /// **'Tüm verileri sil ve baştan başla'**
  String get resetAppDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
