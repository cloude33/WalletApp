import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Log seviyeleri
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Uygulama genelinde kullanılan logger servisi
class AppLogger {
  // Singleton pattern
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  late final Logger _logger;

  /// Logger'ı başlat
  void init({LogLevel level = LogLevel.debug}) {
    _logger = Logger(
      filter: ProductionFilter(),
      printer: PrettyPrinter(
        methodCount: 2, // Kaç method çağrısı gösterilsin
        errorMethodCount: 8, // Error'da kaç method gösterilsin
        lineLength: 120, // Satır uzunluğu
        colors: true, // Renkli output
        printEmojis: true, // Emoji kullan
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // Zaman göster
        noBoxingByDefault: false, // Box çizgisi kullan
      ),
      level: kDebugMode ? Level.debug : Level.info,
    );
  }

  /// Debug seviyesinde log
  void debug(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (data != null) {
      _logger.d('$message\nData: $data', error: error, stackTrace: stackTrace);
    } else {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Info seviyesinde log
  void info(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (data != null) {
      _logger.i('$message\nData: $data', error: error, stackTrace: stackTrace);
    } else {
      _logger.i(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Warning seviyesinde log
  void warning(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (data != null) {
      _logger.w('$message\nData: $data', error: error, stackTrace: stackTrace);
    } else {
      _logger.w(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Error seviyesinde log
  void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (data != null) {
      _logger.e('$message\nData: $data', error: error, stackTrace: stackTrace);
    } else {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Fatal seviyesinde log (kritik hatalar)
  void fatal(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (data != null) {
      _logger.f('$message\nData: $data', error: error, stackTrace: stackTrace);
    } else {
      _logger.f(message, error: error, stackTrace: stackTrace);
    }
  }

  /// API çağrısı log'u
  void apiCall({
    required String method,
    required String endpoint,
    Map<String, dynamic>? params,
    Map<String, dynamic>? body,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('API Call:');
    buffer.writeln('  Method: $method');
    buffer.writeln('  Endpoint: $endpoint');
    if (params != null && params.isNotEmpty) {
      buffer.writeln('  Params: $params');
    }
    if (body != null && body.isNotEmpty) {
      buffer.writeln('  Body: $body');
    }
    info(buffer.toString());
  }

  /// API yanıtı log'u
  void apiResponse({
    required String endpoint,
    required int statusCode,
    dynamic data,
    Duration? duration,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('API Response:');
    buffer.writeln('  Endpoint: $endpoint');
    buffer.writeln('  Status: $statusCode');
    if (duration != null) {
      buffer.writeln('  Duration: ${duration.inMilliseconds}ms');
    }
    if (data != null) {
      buffer.writeln('  Data: $data');
    }
    
    if (statusCode >= 200 && statusCode < 300) {
      info(buffer.toString());
    } else {
      error(buffer.toString());
    }
  }

  /// Database işlemi log'u
  void database({
    required String operation,
    required String table,
    Map<String, dynamic>? data,
    String? query,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Database Operation:');
    buffer.writeln('  Operation: $operation');
    buffer.writeln('  Table: $table');
    if (query != null) {
      buffer.writeln('  Query: $query');
    }
    if (data != null) {
      buffer.writeln('  Data: $data');
    }
    debug(buffer.toString());
  }

  /// Navigation log'u
  void navigation({
    required String from,
    required String to,
    Map<String, dynamic>? arguments,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Navigation:');
    buffer.writeln('  From: $from');
    buffer.writeln('  To: $to');
    if (arguments != null && arguments.isNotEmpty) {
      buffer.writeln('  Arguments: $arguments');
    }
    debug(buffer.toString());
  }

  /// User action log'u
  void userAction({
    required String action,
    String? screen,
    Map<String, dynamic>? data,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('User Action:');
    buffer.writeln('  Action: $action');
    if (screen != null) {
      buffer.writeln('  Screen: $screen');
    }
    if (data != null) {
      buffer.writeln('  Data: $data');
    }
    info(buffer.toString());
  }

  /// Performance log'u
  void performance({
    required String operation,
    required Duration duration,
    Map<String, dynamic>? data,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Performance:');
    buffer.writeln('  Operation: $operation');
    buffer.writeln('  Duration: ${duration.inMilliseconds}ms');
    if (data != null) {
      buffer.writeln('  Data: $data');
    }
    
    // Yavaş işlemler için warning
    if (duration.inMilliseconds > 1000) {
      warning(buffer.toString());
    } else {
      debug(buffer.toString());
    }
  }
}

/// Production filter - sadece production'da info ve üzeri logları göster
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kReleaseMode) {
      return event.level.index >= Level.info.index;
    }
    return true;
  }
}
