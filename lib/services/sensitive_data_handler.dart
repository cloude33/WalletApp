import '../utils/kmh_validator.dart';
class SensitiveDataHandler {
  static String? maskAccountNumber(String? accountNumber) {
    return KmhValidator.maskAccountNumber(accountNumber);
  }
  static String? maskCardNumber(String? cardNumber) {
    if (cardNumber == null || cardNumber.length < 4) {
      return cardNumber;
    }
    
    final lastFour = cardNumber.substring(cardNumber.length - 4);
    final masked = '*' * (cardNumber.length - 4);
    return masked + lastFour;
  }
  static String? maskIban(String? iban) {
    if (iban == null || iban.length < 6) {
      return iban;
    }
    
    final countryCode = iban.substring(0, 2);
    final lastFour = iban.substring(iban.length - 4);
    final masked = '*' * (iban.length - 6);
    return countryCode + masked + lastFour;
  }
  static String sanitizeForLogging(String data) {
    var sanitized = data.replaceAllMapped(
      RegExp(r'\d{10,}'),
      (match) => '*' * match.group(0)!.length,
    );
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'TR\d{24,}'),
      (match) {
        final matched = match.group(0)!;
        return 'TR${'*' * (matched.length - 2)}';
      },
    );
    
    return sanitized;
  }
  static bool isSafeForDisplay(String? data) {
    if (data == null || data.isEmpty) {
      return true;
    }
    if (RegExp(r'\d{10,}').hasMatch(data)) {
      return false;
    }
    if (RegExp(r'TR\d{24,}').hasMatch(data)) {
      return false;
    }
    
    return true;
  }
  static String formatMaskedNumber(String maskedNumber) {
    if (maskedNumber.length <= 4) {
      return maskedNumber;
    }
    
    final lastFour = maskedNumber.substring(maskedNumber.length - 4);
    final masked = maskedNumber.substring(0, maskedNumber.length - 4);
    return '$masked $lastFour';
  }
  static String getDisplaySafeIdentifier({
    required String bankName,
    String? accountNumber,
  }) {
    if (accountNumber == null || accountNumber.isEmpty) {
      return bankName;
    }
    
    final masked = maskAccountNumber(accountNumber);
    return '$bankName ${formatMaskedNumber(masked!)}';
  }
}
