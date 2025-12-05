import 'package:flutter/material.dart';
import '../exceptions/credit_card_exception.dart';
import '../services/error_logger_service.dart';

class ErrorHandler {
  static final ErrorLoggerService _logger = ErrorLoggerService();

  /// Hata mesajını kullanıcı dostu bir formata çevirir
  static String getErrorMessage(dynamic error) {
    // Log the error
    if (error is CreditCardException) {
      _logger.logException(error);
      return error.toUserMessage();
    } else if (error is FormatException) {
      _logger.logGenericException(error, context: 'FormatException');
      return 'Geçersiz veri formatı. Lütfen tekrar deneyin.';
    } else if (error is Exception) {
      _logger.logGenericException(error, context: 'Exception');
      final message = error.toString();
      if (message.contains('not found')) {
        return 'Kayıt bulunamadı.';
      } else if (message.contains('balance')) {
        return 'Yetersiz bakiye.';
      } else if (message.contains('network')) {
        return 'Ağ bağlantısı hatası.';
      }
      return message;
    } else if (error is String) {
      _logger.warning(error, context: 'StringError');
      return error;
    }
    _logger.error('Unknown error type', error: error, context: 'ErrorHandler');
    return 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
  }

  /// Hata mesajını SnackBar olarak gösterir
  static void showError(BuildContext context, dynamic error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getErrorMessage(error)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Başarı mesajını SnackBar olarak gösterir
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Bilgi mesajını SnackBar olarak gösterir
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
