import 'package:flutter/material.dart';

class ErrorHandler {
  /// Hata mesajını kullanıcı dostu bir formata çevirir
  static String getErrorMessage(dynamic error) {
    if (error is FormatException) {
      return 'Geçersiz veri formatı. Lütfen tekrar deneyin.';
    } else if (error is Exception) {
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
      return error;
    }
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

