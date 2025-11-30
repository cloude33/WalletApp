import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Format a double value to Turkish currency format with 2 decimal places
  /// Example: 1234.56 -> "1.234,56"
  static String format(double value, {int decimalDigits = 2}) {
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '',
      decimalDigits: decimalDigits,
    );
    return formatter.format(value).trim();
  }

  /// Format a double value with currency symbol
  /// Example: 1234.56 -> "₺1.234,56"
  static String formatWithSymbol(double value, {String symbol = '₺', int decimalDigits = 2}) {
    return '$symbol${format(value, decimalDigits: decimalDigits)}';
  }

  /// Parse Turkish formatted string to double
  /// Example: "1.234,56" -> 1234.56
  static double parse(String value) {
    // Remove currency symbols and spaces
    String cleanValue = value.replaceAll(RegExp(r'[₺\s]'), '');
    
    // Remove thousands separators (dots)
    cleanValue = cleanValue.replaceAll('.', '');
    
    // Replace comma with dot for decimal
    cleanValue = cleanValue.replaceAll(',', '.');
    
    return double.tryParse(cleanValue) ?? 0.0;
  }

  /// Format for display in lists (compact format)
  /// Example: 1234567.89 -> "₺1,23 M" or "₺1.234,57"
  static String formatCompact(double value, {String symbol = '₺'}) {
    if (value.abs() >= 1000000) {
      return '$symbol${(value / 1000000).toStringAsFixed(2)} M';
    } else if (value.abs() >= 1000) {
      return formatWithSymbol(value, symbol: symbol, decimalDigits: 2);
    } else {
      return formatWithSymbol(value, symbol: symbol, decimalDigits: 2);
    }
  }
}
