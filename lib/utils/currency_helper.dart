import 'package:intl/intl.dart';
import '../models/user.dart';

class CurrencyHelper {
  static String formatAmount(double amount, [User? user]) {
    final symbol = user?.currencySymbol ?? '₺';
    final formatted = NumberFormat('#,##0.00', 'tr_TR').format(amount);
    return '$symbol $formatted';
  }
  static String formatAmountCompact(double amount, [User? user]) {
    final symbol = user?.currencySymbol ?? '₺';
    final formatted = NumberFormat('#,##0.00', 'tr_TR').format(amount);
    return '$symbol$formatted';
  }
  static String formatAmountNoDecimal(double amount, [User? user]) {
    final symbol = user?.currencySymbol ?? '₺';
    final formatted = NumberFormat('#,##0', 'tr_TR').format(amount);
    return '$symbol$formatted';
  }
  static double parse(String value) {
    String cleanValue = value.replaceAll(RegExp(r'[₺$€£\s]'), '');
    cleanValue = cleanValue.replaceAll('.', '');
    cleanValue = cleanValue.replaceAll(',', '.');

    return double.tryParse(cleanValue) ?? 0.0;
  }
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
  static String formatAmountShort(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  static String getSymbol([User? user]) {
    return user?.currencySymbol ?? '₺';
  }

  static String getCode([User? user]) {
    return user?.currencyCode ?? 'TRY';
  }
}
