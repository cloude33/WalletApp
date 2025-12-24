import '../exceptions/kmh_exception.dart';
import '../exceptions/error_codes.dart';
class KmhValidator {
  static const double minCreditLimit = 1000.0;
  static const double maxCreditLimit = 100000.0;
  static const double minInterestRate = 0.0;
  static const double maxInterestRate = 100.0;
  static bool validateCreditLimit(double limit) {
    if (limit < minCreditLimit) {
      throw KmhException.invalidLimit(
        'Kredi limiti minimum $minCreditLimit TL olmalıdır',
      );
    }

    if (limit > maxCreditLimit) {
      throw KmhException.invalidLimit(
        'Kredi limiti maksimum $maxCreditLimit TL olmalıdır',
      );
    }

    return true;
  }
  static bool validateInterestRate(double rate) {
    if (rate < minInterestRate) {
      throw KmhException.invalidInterestRate(
        'Faiz oranı minimum $minInterestRate% olmalıdır',
      );
    }

    if (rate > maxInterestRate) {
      throw KmhException.invalidInterestRate(
        'Faiz oranı maksimum $maxInterestRate% olmalıdır',
      );
    }

    return true;
  }
  static bool validateAmount(double amount) {
    if (amount <= 0) {
      throw KmhException.invalidAmount('Tutar pozitif bir değer olmalıdır');
    }

    return true;
  }
  static bool validateWithdrawal({
    required double currentBalance,
    required double withdrawalAmount,
    required double creditLimit,
  }) {
    final balanceAfter = currentBalance - withdrawalAmount;
    if (balanceAfter < -creditLimit) {
      final availableCredit = creditLimit + currentBalance;
      throw KmhException.limitExceeded(
        requestedAmount: withdrawalAmount,
        availableCredit: availableCredit,
      );
    }

    return true;
  }
  static bool checkLimitAvailability({
    required double currentBalance,
    required double requestedAmount,
    required double creditLimit,
  }) {
    final balanceAfter = currentBalance - requestedAmount;
    return balanceAfter >= -creditLimit;
  }
  static double calculateAvailableCredit({
    required double currentBalance,
    required double creditLimit,
  }) {
    return creditLimit + currentBalance;
  }
  static String? maskAccountNumber(String? accountNumber) {
    if (accountNumber == null || accountNumber.length < 4) {
      return accountNumber;
    }

    final lastFour = accountNumber.substring(accountNumber.length - 4);
    final masked = '*' * (accountNumber.length - 4);
    return masked + lastFour;
  }
  static bool validateBankName(String bankName) {
    if (bankName.trim().isEmpty) {
      throw KmhException(ErrorCodes.INVALID_INPUT, 'Banka adı boş olamaz');
    }

    return true;
  }
  static bool validateDescription(String description) {
    if (description.trim().isEmpty) {
      throw KmhException(ErrorCodes.INVALID_INPUT, 'Açıklama boş olamaz');
    }

    return true;
  }
}
