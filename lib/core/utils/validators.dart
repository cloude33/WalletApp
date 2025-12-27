import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../exceptions/validation_exception.dart';

/// Uygulama genelinde kullanılan validasyon fonksiyonları
class Validators {
  // Private constructor to prevent instantiation
  Validators._();

  /// Boş alan kontrolü
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.emptyField;
    }
    return null;
  }

  /// Tutar validasyonu
  static String? validateAmount(String? value, {
    double? min,
    double? max,
  }) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.emptyField;
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return AppStrings.invalidAmount;
    }

    final minAmount = min ?? AppConstants.minTransactionAmount;
    final maxAmount = max ?? AppConstants.maxTransactionAmount;

    if (amount < minAmount) {
      return '${AppStrings.amountTooLow} (Min: $minAmount)';
    }

    if (amount > maxAmount) {
      return '${AppStrings.amountTooHigh} (Max: $maxAmount)';
    }

    return null;
  }

  /// E-posta validasyonu
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.emptyField;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return AppStrings.invalidEmail;
    }

    return null;
  }

  /// Telefon numarası validasyonu (Türkiye)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.emptyField;
    }

    // Türkiye telefon formatı: 05XX XXX XX XX veya +90 5XX XXX XX XX
    final phoneRegex = RegExp(
      r'^(\+90|0)?5\d{9}$',
    );

    final cleanedValue = value.replaceAll(RegExp(r'[\s-()]'), '');
    if (!phoneRegex.hasMatch(cleanedValue)) {
      return AppStrings.invalidPhone;
    }

    return null;
  }

  /// PIN validasyonu
  static String? validatePin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.emptyField;
    }

    if (value.length < AppConstants.minPinLength) {
      return AppStrings.invalidPin;
    }

    if (value.length > AppConstants.maxPinLength) {
      return AppStrings.invalidPin;
    }

    // Sadece rakam kontrolü
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'PIN sadece rakamlardan oluşmalıdır';
    }

    return null;
  }

  /// Şifre validasyonu
  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.emptyField;
    }

    if (value.length < AppConstants.minPasswordLength) {
      return AppStrings.invalidPassword;
    }

    if (value.length > AppConstants.maxPasswordLength) {
      return 'Şifre çok uzun';
    }

    return null;
  }

  /// Şifre eşleşme kontrolü
  static String? validatePasswordMatch(String? value, String? password) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.emptyField;
    }

    if (value != password) {
      return AppStrings.passwordMismatch;
    }

    return null;
  }

  /// Kredi limiti validasyonu
  static String? validateCreditLimit(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Opsiyonel
    }

    final limit = double.tryParse(value);
    if (limit == null) {
      return AppStrings.invalidCreditLimit;
    }

    if (limit < AppConstants.minCreditLimit) {
      return '${AppStrings.invalidCreditLimit} (Min: ${AppConstants.minCreditLimit})';
    }

    if (limit > AppConstants.maxCreditLimit) {
      return '${AppStrings.invalidCreditLimit} (Max: ${AppConstants.maxCreditLimit})';
    }

    return null;
  }

  /// Faiz oranı validasyonu
  static String? validateInterestRate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Opsiyonel
    }

    final rate = double.tryParse(value);
    if (rate == null) {
      return AppStrings.invalidInterestRate;
    }

    if (rate < AppConstants.minInterestRate) {
      return '${AppStrings.invalidInterestRate} (Min: ${AppConstants.minInterestRate}%)';
    }

    if (rate > AppConstants.maxInterestRate) {
      return '${AppStrings.invalidInterestRate} (Max: ${AppConstants.maxInterestRate}%)';
    }

    return null;
  }

  /// Taksit sayısı validasyonu
  static String? validateInstallments(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Opsiyonel
    }

    final installments = int.tryParse(value);
    if (installments == null) {
      return 'Geçersiz taksit sayısı';
    }

    if (installments < AppConstants.minInstallments) {
      return 'Minimum ${AppConstants.minInstallments} taksit olmalıdır';
    }

    if (installments > AppConstants.maxInstallments) {
      return 'Maximum ${AppConstants.maxInstallments} taksit olabilir';
    }

    return null;
  }

  /// Açıklama uzunluğu validasyonu
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.emptyField;
    }

    if (value.length > AppConstants.maxDescriptionLength) {
      return 'Açıklama çok uzun (Max: ${AppConstants.maxDescriptionLength} karakter)';
    }

    return null;
  }

  /// Not uzunluğu validasyonu
  static String? validateMemo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Opsiyonel
    }

    if (value.length > AppConstants.maxMemoLength) {
      return 'Not çok uzun (Max: ${AppConstants.maxMemoLength} karakter)';
    }

    return null;
  }

  /// Tarih validasyonu
  static String? validateDate(DateTime? value) {
    if (value == null) {
      return AppStrings.invalidDate;
    }

    // Gelecek tarih kontrolü (isteğe bağlı)
    final now = DateTime.now();
    if (value.isAfter(now.add(const Duration(days: 365)))) {
      return 'Tarih çok ileri bir tarih olamaz';
    }

    return null;
  }

  /// Model seviyesinde validasyon - Exception fırlatır
  static void validateAmountOrThrow(double amount, {String? field}) {
    if (amount < AppConstants.minTransactionAmount) {
      throw ValidationException(
        AppStrings.amountTooLow,
        field: field ?? 'amount',
        value: amount,
      );
    }

    if (amount > AppConstants.maxTransactionAmount) {
      throw ValidationException(
        AppStrings.amountTooHigh,
        field: field ?? 'amount',
        value: amount,
      );
    }
  }

  /// ID validasyonu
  static void validateIdOrThrow(String id, {String? field}) {
    if (id.trim().isEmpty) {
      throw ValidationException(
        'ID boş olamaz',
        field: field ?? 'id',
        value: id,
      );
    }
  }

  /// Kredi limiti validasyonu - Exception fırlatır
  static void validateCreditLimitOrThrow(double limit, {String? field}) {
    if (limit < AppConstants.minCreditLimit) {
      throw ValidationException(
        AppStrings.invalidCreditLimit,
        field: field ?? 'creditLimit',
        value: limit,
      );
    }

    if (limit > AppConstants.maxCreditLimit) {
      throw ValidationException(
        AppStrings.invalidCreditLimit,
        field: field ?? 'creditLimit',
        value: limit,
      );
    }
  }

  /// Faiz oranı validasyonu - Exception fırlatır
  static void validateInterestRateOrThrow(double rate, {String? field}) {
    if (rate < AppConstants.minInterestRate) {
      throw ValidationException(
        AppStrings.invalidInterestRate,
        field: field ?? 'interestRate',
        value: rate,
      );
    }

    if (rate > AppConstants.maxInterestRate) {
      throw ValidationException(
        AppStrings.invalidInterestRate,
        field: field ?? 'interestRate',
        value: rate,
      );
    }
  }
}
