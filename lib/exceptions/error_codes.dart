// ignore_for_file: constant_identifier_names

class ErrorCodes {
  static const String INVALID_INPUT = 'INVALID_INPUT';
  static const String INVALID_AMOUNT = 'INVALID_AMOUNT';
  static const String INVALID_DATE = 'INVALID_DATE';
  static const String INVALID_CARD_DATA = 'INVALID_CARD_DATA';
  static const String INVALID_TRANSACTION = 'INVALID_TRANSACTION';
  static const String INVALID_REWARD_TYPE = 'INVALID_REWARD_TYPE';
  static const String INVALID_CONVERSION_RATE = 'INVALID_CONVERSION_RATE';
  static const String INVALID_INSTALLMENT_COUNT = 'INVALID_INSTALLMENT_COUNT';
  static const String INVALID_DEFERRED_MONTHS = 'INVALID_DEFERRED_MONTHS';
  static const String INVALID_INTEREST_RATE = 'INVALID_INTEREST_RATE';
  static const String INVALID_LIMIT = 'INVALID_LIMIT';
  static const String INVALID_THRESHOLD = 'INVALID_THRESHOLD';
  static const String INVALID_PAYMENT_AMOUNT = 'INVALID_PAYMENT_AMOUNT';
  static const String LIMIT_EXCEEDED = 'LIMIT_EXCEEDED';
  static const String INSUFFICIENT_POINTS = 'INSUFFICIENT_POINTS';
  static const String INSUFFICIENT_BALANCE = 'INSUFFICIENT_BALANCE';
  static const String INSUFFICIENT_LIMIT = 'INSUFFICIENT_LIMIT';
  static const String CASH_ADVANCE_LIMIT_EXCEEDED = 'CASH_ADVANCE_LIMIT_EXCEEDED';
  static const String PAYMENT_EXCEEDS_DEBT = 'PAYMENT_EXCEEDS_DEBT';
  static const String ALREADY_EXISTS = 'ALREADY_EXISTS';
  static const String DUPLICATE_ENTRY = 'DUPLICATE_ENTRY';
  static const String OPERATION_NOT_ALLOWED = 'OPERATION_NOT_ALLOWED';
  static const String CARD_NOT_FOUND = 'CARD_NOT_FOUND';
  static const String TRANSACTION_NOT_FOUND = 'TRANSACTION_NOT_FOUND';
  static const String STATEMENT_NOT_FOUND = 'STATEMENT_NOT_FOUND';
  static const String PAYMENT_NOT_FOUND = 'PAYMENT_NOT_FOUND';
  static const String REWARD_POINTS_NOT_FOUND = 'REWARD_POINTS_NOT_FOUND';
  static const String LIMIT_ALERT_NOT_FOUND = 'LIMIT_ALERT_NOT_FOUND';
  static const String INSTALLMENT_NOT_FOUND = 'INSTALLMENT_NOT_FOUND';
  static const String CALCULATION_ERROR = 'CALCULATION_ERROR';
  static const String INTEREST_CALCULATION_ERROR = 'INTEREST_CALCULATION_ERROR';
  static const String POINTS_CALCULATION_ERROR = 'POINTS_CALCULATION_ERROR';
  static const String LIMIT_CALCULATION_ERROR = 'LIMIT_CALCULATION_ERROR';
  static const String DEBT_CALCULATION_ERROR = 'DEBT_CALCULATION_ERROR';
  static const String REPORT_GENERATION_ERROR = 'REPORT_GENERATION_ERROR';
  static const String DATABASE_ERROR = 'DATABASE_ERROR';
  static const String SAVE_FAILED = 'SAVE_FAILED';
  static const String UPDATE_FAILED = 'UPDATE_FAILED';
  static const String DELETE_FAILED = 'DELETE_FAILED';
  static const String QUERY_FAILED = 'QUERY_FAILED';
  static const String SMS_PERMISSION_DENIED = 'SMS_PERMISSION_DENIED';
  static const String NOTIFICATION_PERMISSION_DENIED = 'NOTIFICATION_PERMISSION_DENIED';
  static const String STORAGE_PERMISSION_DENIED = 'STORAGE_PERMISSION_DENIED';
  static const String SMS_PARSE_ERROR = 'SMS_PARSE_ERROR';
  static const String DATE_PARSE_ERROR = 'DATE_PARSE_ERROR';
  static const String AMOUNT_PARSE_ERROR = 'AMOUNT_PARSE_ERROR';
  static const String BANK_NOT_DETECTED = 'BANK_NOT_DETECTED';
  static const String NOTIFICATION_SCHEDULE_FAILED = 'NOTIFICATION_SCHEDULE_FAILED';
  static const String NOTIFICATION_CANCEL_FAILED = 'NOTIFICATION_CANCEL_FAILED';
  static const String NOTIFICATION_SEND_FAILED = 'NOTIFICATION_SEND_FAILED';
  static const String MIGRATION_FAILED = 'MIGRATION_FAILED';
  static const String MIGRATION_ROLLBACK_FAILED = 'MIGRATION_ROLLBACK_FAILED';
  static const String UNKNOWN_ERROR = 'UNKNOWN_ERROR';
  static const String NETWORK_ERROR = 'NETWORK_ERROR';
  static const String TIMEOUT_ERROR = 'TIMEOUT_ERROR';
  static const String UNIMPLEMENTED = 'UNIMPLEMENTED';
  static String getUserMessage(String code) {
    switch (code) {
      case INVALID_INPUT:
        return 'Geçersiz giriş. Lütfen bilgileri kontrol edin.';
      case INVALID_AMOUNT:
        return 'Geçersiz tutar. Lütfen pozitif bir değer girin.';
      case INVALID_DATE:
        return 'Geçersiz tarih. Lütfen geçerli bir tarih seçin.';
      case INVALID_CARD_DATA:
        return 'Geçersiz kart bilgisi. Lütfen tüm alanları doldurun.';
      case INVALID_TRANSACTION:
        return 'Geçersiz işlem. Lütfen bilgileri kontrol edin.';
      case INVALID_REWARD_TYPE:
        return 'Geçersiz puan türü. Lütfen geçerli bir tür seçin.';
      case INVALID_CONVERSION_RATE:
        return 'Geçersiz dönüşüm oranı. Lütfen pozitif bir değer girin.';
      case INVALID_INSTALLMENT_COUNT:
        return 'Geçersiz taksit sayısı. Lütfen geçerli bir sayı girin.';
      case INVALID_DEFERRED_MONTHS:
        return 'Geçersiz erteleme süresi. Lütfen geçerli bir süre girin.';
      case INVALID_INTEREST_RATE:
        return 'Geçersiz faiz oranı. Lütfen geçerli bir oran girin.';
      case INVALID_LIMIT:
        return 'Geçersiz limit. Lütfen pozitif bir değer girin.';
      case INVALID_THRESHOLD:
        return 'Geçersiz eşik değeri. Lütfen geçerli bir değer girin.';
      case INVALID_PAYMENT_AMOUNT:
        return 'Geçersiz ödeme tutarı. Lütfen pozitif bir değer girin.';
      case LIMIT_EXCEEDED:
        return 'Kart limiti aşıldı. Lütfen limitinizi kontrol edin.';
      case INSUFFICIENT_POINTS:
        return 'Yetersiz puan bakiyesi. Lütfen bakiyenizi kontrol edin.';
      case INSUFFICIENT_BALANCE:
        return 'Yetersiz bakiye. Lütfen bakiyenizi kontrol edin.';
      case INSUFFICIENT_LIMIT:
        return 'Yetersiz limit. Lütfen limitinizi kontrol edin.';
      case CASH_ADVANCE_LIMIT_EXCEEDED:
        return 'Nakit avans limiti aşıldı. Lütfen limitinizi kontrol edin.';
      case PAYMENT_EXCEEDS_DEBT:
        return 'Ödeme tutarı borçtan fazla. Lütfen tutarı kontrol edin.';
      case ALREADY_EXISTS:
        return 'Bu kayıt zaten mevcut.';
      case DUPLICATE_ENTRY:
        return 'Tekrarlayan kayıt. Bu kayıt zaten mevcut.';
      case OPERATION_NOT_ALLOWED:
        return 'Bu işlem şu anda yapılamaz.';
      case CARD_NOT_FOUND:
        return 'Kart bulunamadı. Lütfen kartı kontrol edin.';
      case TRANSACTION_NOT_FOUND:
        return 'İşlem bulunamadı.';
      case STATEMENT_NOT_FOUND:
        return 'Ekstre bulunamadı.';
      case PAYMENT_NOT_FOUND:
        return 'Ödeme bulunamadı.';
      case REWARD_POINTS_NOT_FOUND:
        return 'Puan sistemi bulunamadı.';
      case LIMIT_ALERT_NOT_FOUND:
        return 'Limit uyarısı bulunamadı.';
      case INSTALLMENT_NOT_FOUND:
        return 'Taksit bulunamadı.';
      case CALCULATION_ERROR:
        return 'Hesaplama hatası oluştu. Lütfen tekrar deneyin.';
      case INTEREST_CALCULATION_ERROR:
        return 'Faiz hesaplama hatası. Lütfen tekrar deneyin.';
      case POINTS_CALCULATION_ERROR:
        return 'Puan hesaplama hatası. Lütfen tekrar deneyin.';
      case LIMIT_CALCULATION_ERROR:
        return 'Limit hesaplama hatası. Lütfen tekrar deneyin.';
      case DEBT_CALCULATION_ERROR:
        return 'Borç hesaplama hatası. Lütfen tekrar deneyin.';
      case REPORT_GENERATION_ERROR:
        return 'Rapor oluşturma hatası. Lütfen tekrar deneyin.';
      case DATABASE_ERROR:
        return 'Veritabanı hatası. Lütfen tekrar deneyin.';
      case SAVE_FAILED:
        return 'Kaydetme başarısız. Lütfen tekrar deneyin.';
      case UPDATE_FAILED:
        return 'Güncelleme başarısız. Lütfen tekrar deneyin.';
      case DELETE_FAILED:
        return 'Silme başarısız. Lütfen tekrar deneyin.';
      case QUERY_FAILED:
        return 'Sorgu başarısız. Lütfen tekrar deneyin.';
      case SMS_PERMISSION_DENIED:
        return 'SMS okuma izni reddedildi. Lütfen ayarlardan izin verin.';
      case NOTIFICATION_PERMISSION_DENIED:
        return 'Bildirim izni reddedildi. Lütfen ayarlardan izin verin.';
      case STORAGE_PERMISSION_DENIED:
        return 'Depolama izni reddedildi. Lütfen ayarlardan izin verin.';
      case SMS_PARSE_ERROR:
        return 'SMS okunamadı. Lütfen tekrar deneyin.';
      case DATE_PARSE_ERROR:
        return 'Tarih okunamadı. Lütfen geçerli bir tarih girin.';
      case AMOUNT_PARSE_ERROR:
        return 'Tutar okunamadı. Lütfen geçerli bir tutar girin.';
      case BANK_NOT_DETECTED:
        return 'Banka tespit edilemedi.';
      case NOTIFICATION_SCHEDULE_FAILED:
        return 'Bildirim zamanlanamadı. Lütfen tekrar deneyin.';
      case NOTIFICATION_CANCEL_FAILED:
        return 'Bildirim iptal edilemedi. Lütfen tekrar deneyin.';
      case NOTIFICATION_SEND_FAILED:
        return 'Bildirim gönderilemedi. Lütfen tekrar deneyin.';
      case MIGRATION_FAILED:
        return 'Veri güncelleme başarısız oldu. Lütfen uygulamayı yeniden başlatın.';
      case MIGRATION_ROLLBACK_FAILED:
        return 'Geri alma işlemi başarısız oldu. Lütfen destek ekibiyle iletişime geçin.';
      case NETWORK_ERROR:
        return 'Ağ bağlantısı hatası. Lütfen internet bağlantınızı kontrol edin.';
      case TIMEOUT_ERROR:
        return 'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.';
      case UNIMPLEMENTED:
        return 'Bu özellik henüz uygulanmadı.';
      case UNKNOWN_ERROR:
      default:
        return 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
}
