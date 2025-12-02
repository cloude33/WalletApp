import 'package:intl/intl.dart';
import '../models/user.dart';

class CurrencyHelper {
  /// Format amount with 2 decimal places
  /// Example: 1234.56 -> "₺ 1.234,56"
  static String formatAmount(double amount, [User? user]) {
    final symbol = user?.currencySymbol ?? '₺';
    final formatted = NumberFormat('#,##0.00', 'tr_TR').format(amount);
    return '$symbol $formatted';
  }

  /// Format amount with 2 decimal places (compact version without space)
  /// Example: 1234.56 -> "₺1.234,56"
  static String formatAmountCompact(double amount, [User? user]) {
    final symbol = user?.currencySymbol ?? '₺';
    final formatted = NumberFormat('#,##0.00', 'tr_TR').format(amount);
    return '$symbol$formatted';
  }

  /// Format amount without decimal places (for display purposes)
  /// Example: 1234.56 -> "₺1.235"
  static String formatAmountNoDecimal(double amount, [User? user]) {
    final symbol = user?.currencySymbol ?? '₺';
    final formatted = NumberFormat('#,##0', 'tr_TR').format(amount);
    return '$symbol$formatted';
  }

  /// Parse Turkish formatted string to double
  /// Example: "1.234,56" -> 1234.56
  static double parse(String value) {
    // Remove currency symbols and spaces
    String cleanValue = value.replaceAll(RegExp(r'[₺$€£\s]'), '');
    
    // Remove thousands separators (dots)
    cleanValue = cleanValue.replaceAll('.', '');
    
    // Replace comma with dot for decimal
    cleanValue = cleanValue.replaceAll(',', '.');
    
    return double.tryParse(cleanValue) ?? 0.0;
  }

  /// Format for display in lists (compact format with M/K suffix)
  /// Example: 1234567.89 -> "₺1,23 M"
  static String formatCompact(double value, [User? user]) {
    final symbol = user?.currencySymbol ?? '₺';
    if (value.abs() >= 1000000) {
      return '$symbol${(value / 1000000).toStringAsFixed(2)} M';
    } else if (value.abs() >= 1000) {
      return formatAmountCompact(value, user);
    } else {
      return formatAmountCompact(value, user);
    }
  }

  static String getSymbol([User? user]) {
    return user?.currencySymbol ?? '₺';
  }

  static String getCode([User? user]) {
    return user?.currencyCode ?? 'TRY';
  }
}
