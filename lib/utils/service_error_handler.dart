import '../exceptions/credit_card_exception.dart';
import '../exceptions/error_codes.dart';
import '../services/error_logger_service.dart';

/// Utility class for handling errors in service operations
class ServiceErrorHandler {
  static final ErrorLoggerService _logger = ErrorLoggerService();

  /// Execute a service operation with error handling
  static Future<T> execute<T>({
    required Future<T> Function() operation,
    required String serviceName,
    required String operationName,
    String? errorCode,
    String? errorMessage,
  }) async {
    try {
      _logger.debug(
        'Starting $operationName',
        context: serviceName,
      );

      final result = await operation();

      _logger.debug(
        'Completed $operationName',
        context: serviceName,
      );

      return result;
    } on CreditCardException catch (e) {
      _logger.logException(e, context: serviceName);
      rethrow;
    } catch (e, stackTrace) {
      _logger.error(
        'Error in $operationName',
        error: e,
        stackTrace: stackTrace,
        context: serviceName,
      );

      throw CreditCardException(
        errorMessage ?? 'İşlem başarısız: $operationName',
        errorCode ?? ErrorCodes.UNKNOWN_ERROR,
        e,
        stackTrace,
      );
    }
  }

  /// Execute a synchronous service operation with error handling
  static T executeSync<T>({
    required T Function() operation,
    required String serviceName,
    required String operationName,
    String? errorCode,
    String? errorMessage,
  }) {
    try {
      _logger.debug(
        'Starting $operationName',
        context: serviceName,
      );

      final result = operation();

      _logger.debug(
        'Completed $operationName',
        context: serviceName,
      );

      return result;
    } on CreditCardException catch (e) {
      _logger.logException(e, context: serviceName);
      rethrow;
    } catch (e, stackTrace) {
      _logger.error(
        'Error in $operationName',
        error: e,
        stackTrace: stackTrace,
        context: serviceName,
      );

      throw CreditCardException(
        errorMessage ?? 'İşlem başarısız: $operationName',
        errorCode ?? ErrorCodes.UNKNOWN_ERROR,
        e,
        stackTrace,
      );
    }
  }

  /// Validate input and throw CreditCardException if invalid
  static void validateInput({
    required bool condition,
    required String message,
    required String errorCode,
    dynamic details,
  }) {
    if (!condition) {
      _logger.logValidationError(message, context: 'Validation');
      throw CreditCardException(message, errorCode, details);
    }
  }

  /// Validate that a value is not null
  static T validateNotNull<T>({
    required T? value,
    required String message,
    required String errorCode,
  }) {
    if (value == null) {
      _logger.logValidationError(message, context: 'Validation');
      throw CreditCardException(message, errorCode);
    }
    return value;
  }

  /// Validate that a number is positive
  static void validatePositive({
    required double value,
    required String fieldName,
    String? errorCode,
  }) {
    if (value <= 0) {
      final message = '$fieldName sıfırdan büyük olmalıdır';
      _logger.logValidationError(
        message,
        field: fieldName,
        value: value,
        context: 'Validation',
      );
      throw CreditCardException(
        message,
        errorCode ?? ErrorCodes.INVALID_AMOUNT,
        {'field': fieldName, 'value': value},
      );
    }
  }

  /// Validate that a number is non-negative
  static void validateNonNegative({
    required double value,
    required String fieldName,
    String? errorCode,
  }) {
    if (value < 0) {
      final message = '$fieldName negatif olamaz';
      _logger.logValidationError(
        message,
        field: fieldName,
        value: value,
        context: 'Validation',
      );
      throw CreditCardException(
        message,
        errorCode ?? ErrorCodes.INVALID_AMOUNT,
        {'field': fieldName, 'value': value},
      );
    }
  }

  /// Validate that a date is not in the past
  static void validateFutureDate({
    required DateTime date,
    required String fieldName,
    String? errorCode,
  }) {
    if (date.isBefore(DateTime.now())) {
      final message = '$fieldName geçmiş bir tarih olamaz';
      _logger.logValidationError(
        message,
        field: fieldName,
        value: date,
        context: 'Validation',
      );
      throw CreditCardException(
        message,
        errorCode ?? ErrorCodes.INVALID_DATE,
        {'field': fieldName, 'value': date},
      );
    }
  }

  /// Validate that a string is not empty
  static void validateNotEmpty({
    required String value,
    required String fieldName,
    String? errorCode,
  }) {
    if (value.trim().isEmpty) {
      final message = '$fieldName boş olamaz';
      _logger.logValidationError(
        message,
        field: fieldName,
        value: value,
        context: 'Validation',
      );
      throw CreditCardException(
        message,
        errorCode ?? ErrorCodes.INVALID_INPUT,
        {'field': fieldName, 'value': value},
      );
    }
  }

  /// Validate that a value is within a range
  static void validateRange({
    required double value,
    required double min,
    required double max,
    required String fieldName,
    String? errorCode,
  }) {
    if (value < min || value > max) {
      final message = '$fieldName $min ile $max arasında olmalıdır';
      _logger.logValidationError(
        message,
        field: fieldName,
        value: value,
        context: 'Validation',
      );
      throw CreditCardException(
        message,
        errorCode ?? ErrorCodes.INVALID_INPUT,
        {'field': fieldName, 'value': value, 'min': min, 'max': max},
      );
    }
  }

  /// Validate that a value is in a list of allowed values
  static void validateInList<T>({
    required T value,
    required List<T> allowedValues,
    required String fieldName,
    String? errorCode,
  }) {
    if (!allowedValues.contains(value)) {
      final message = '$fieldName geçersiz. İzin verilen değerler: ${allowedValues.join(", ")}';
      _logger.logValidationError(
        message,
        field: fieldName,
        value: value,
        context: 'Validation',
      );
      throw CreditCardException(
        message,
        errorCode ?? ErrorCodes.INVALID_INPUT,
        {'field': fieldName, 'value': value, 'allowedValues': allowedValues},
      );
    }
  }
}
