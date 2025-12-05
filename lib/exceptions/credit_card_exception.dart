/// Custom exception class for credit card related errors
class CreditCardException implements Exception {
  final String message;
  final String code;
  final dynamic details;
  final StackTrace? stackTrace;

  CreditCardException(
    this.message,
    this.code, [
    this.details,
    this.stackTrace,
  ]);

  @override
  String toString() {
    if (details != null) {
      return 'CreditCardException [$code]: $message\nDetails: $details';
    }
    return 'CreditCardException [$code]: $message';
  }

  /// Create a user-friendly error message
  String toUserMessage() {
    return message;
  }
}
