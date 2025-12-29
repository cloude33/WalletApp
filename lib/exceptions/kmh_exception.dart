import 'error_codes.dart';
class KmhException implements Exception {
  final String code;
  final String message;
  final dynamic details;

  KmhException(this.code, this.message, [this.details]);
  factory KmhException.fromCode(String code, [dynamic details]) {
    return KmhException(
      code,
      ErrorCodes.getUserMessage(code),
      details,
    );
  }
  factory KmhException.limitExceeded({
    required double requestedAmount,
    required double availableCredit,
  }) {
    return KmhException(
      ErrorCodes.LIMIT_EXCEEDED,
      ErrorCodes.getUserMessage(ErrorCodes.LIMIT_EXCEEDED),
      {
        'requestedAmount': requestedAmount,
        'availableCredit': availableCredit,
      },
    );
  }
  factory KmhException.insufficientCredit({
    required double requestedAmount,
    required double availableCredit,
  }) {
    return KmhException(
      ErrorCodes.INSUFFICIENT_LIMIT,
      ErrorCodes.getUserMessage(ErrorCodes.INSUFFICIENT_LIMIT),
      {
        'requestedAmount': requestedAmount,
        'availableCredit': availableCredit,
      },
    );
  }
  factory KmhException.invalidAmount(String reason) {
    return KmhException(
      ErrorCodes.INVALID_AMOUNT,
      ErrorCodes.getUserMessage(ErrorCodes.INVALID_AMOUNT),
      reason,
    );
  }
  factory KmhException.invalidLimit(String reason) {
    return KmhException(
      ErrorCodes.INVALID_LIMIT,
      ErrorCodes.getUserMessage(ErrorCodes.INVALID_LIMIT),
      reason,
    );
  }
  factory KmhException.invalidInterestRate(String reason) {
    return KmhException(
      ErrorCodes.INVALID_INTEREST_RATE,
      ErrorCodes.getUserMessage(ErrorCodes.INVALID_INTEREST_RATE),
      reason,
    );
  }

  @override
  String toString() {
    if (details != null) {
      return 'KmhException($code): $message - Details: $details';
    }
    return 'KmhException($code): $message';
  }
}
