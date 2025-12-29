import 'dart:developer' as developer;
import '../exceptions/credit_card_exception.dart';
class ErrorLoggerService {
  static final ErrorLoggerService _instance = ErrorLoggerService._internal();
  factory ErrorLoggerService() => _instance;
  ErrorLoggerService._internal();
  static const String _levelError = 'ERROR';
  static const String _levelWarning = 'WARNING';
  static const String _levelInfo = 'INFO';
  static const String _levelDebug = 'DEBUG';
  void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? context,
  }) {
    _log(
      level: _levelError,
      message: message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }
  void warning(
    String message, {
    dynamic details,
    String? context,
  }) {
    _log(
      level: _levelWarning,
      message: message,
      error: details,
      context: context,
    );
  }
  void info(
    String message, {
    dynamic details,
    String? context,
  }) {
    _log(
      level: _levelInfo,
      message: message,
      error: details,
      context: context,
    );
  }
  void debug(
    String message, {
    dynamic details,
    String? context,
  }) {
    _log(
      level: _levelDebug,
      message: message,
      error: details,
      context: context,
    );
  }
  void _log({
    required String level,
    required String message,
    dynamic error,
    StackTrace? stackTrace,
    String? context,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? '[$context] ' : '';
    final logMessage = '$timestamp [$level] $contextStr$message';
    developer.log(
      logMessage,
      name: 'CreditCardApp',
      error: error,
      stackTrace: stackTrace,
      level: _getLogLevel(level),
    );
  }
  int _getLogLevel(String level) {
    switch (level) {
      case _levelError:
        return 1000;
      case _levelWarning:
        return 900;
      case _levelInfo:
        return 800;
      case _levelDebug:
        return 700;
      default:
        return 500;
    }
  }
  void logException(
    CreditCardException exception, {
    String? context,
  }) {
    error(
      exception.message,
      error: exception,
      stackTrace: exception.stackTrace,
      context: context ?? 'CreditCardException',
    );
  }
  void logGenericException(
    dynamic exception, {
    StackTrace? stackTrace,
    String? context,
  }) {
    error(
      exception.toString(),
      error: exception,
      stackTrace: stackTrace,
      context: context ?? 'Exception',
    );
  }
  void logValidationError(
    String message, {
    String? field,
    dynamic value,
    String? context,
  }) {
    warning(
      message,
      details: {
        'field': field,
        'value': value,
      },
      context: context ?? 'Validation',
    );
  }
  void logDatabaseOperation(
    String operation,
    String entity, {
    bool success = true,
    dynamic error,
    String? details,
  }) {
    if (success) {
      debug(
        '$operation $entity',
        details: details,
        context: 'Database',
      );
    } else {
      error(
        'Failed to $operation $entity',
        error: error,
        context: 'Database',
      );
    }
  }
  void logServiceOperation(
    String service,
    String operation, {
    bool success = true,
    dynamic error,
    String? details,
  }) {
    if (success) {
      debug(
        '$operation in $service',
        details: details,
        context: service,
      );
    } else {
      error(
        'Failed $operation in $service',
        error: error,
        context: service,
      );
    }
  }
}
