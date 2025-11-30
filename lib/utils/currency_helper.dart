import 'package:intl/intl.dart';
import '../models/user.dart';

class CurrencyHelper {
  static String formatAmount(double amount, User? user) {
    final symbol = user?.currencySymbol ?? '₺';
    final formatted = NumberFormat('#,##0.00', 'tr_TR').format(amount);
    return '$symbol $formatted';
  }

  static String formatAmountCompact(double amount, User? user) {
    final symbol = user?.currencySymbol ?? '₺';
    final formatted = NumberFormat('#,##0', 'tr_TR').format(amount);
    return '$symbol $formatted';
  }

  static String getSymbol(User? user) {
    return user?.currencySymbol ?? '₺';
  }

  static String getCode(User? user) {
    return user?.currencyCode ?? 'TRY';
  }
}
