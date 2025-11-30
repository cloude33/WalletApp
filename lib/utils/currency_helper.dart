import 'package:intl/intl.dart';
import '../models/user.dart';

class CurrencyHelper {
  /// Format amount with 2 decimal places
  /// Example: 1234.56 -> "₺ 1.234,56"
  static String formatAmount(double amount, User? user) {
    final symbol = user?.currencySymbol ?? '₺';
    final formatted = NumberFormat('#,##0.00', 'tr_TR').format(amount);
    return '$symbol $formatted';
  }

  /// Format amount with 2 decimal places (compact version without space)
  /// Example: 1234.56 -> "₺1.234,56"
  static String formatAmountCompact(double amount, User? user) {
    final symbol = user?.currencySymbol ?? '₺';
    final formatted = NumberFormat('#,##0.00', 'tr_TR').format(amount);
    return '$symbol$formatted';
  }

  /// Format amount without decimal places (for display purposes)
  /// Example: 1234.56 -> "₺1.235"
  static String formatAmountNoDecimal(double amount, User? user) {
    final symbol = user?.currencySymbol ?? '₺';
    final formatted = NumberFormat('#,##0', 'tr_TR').format(amount);
    return '$symbol$formatted';
  }

  static String getSymbol(User? user) {
    return user?.currencySymbol ?? '₺';
  }

  static String getCode(User? user) {
    return user?.currencyCode ?? 'TRY';
  }
}
