import 'kmh_transaction.dart';
class KmhStatement {
  final String walletId;
  final String walletName;
  final DateTime startDate;
  final DateTime endDate;
  final List<KmhTransaction> transactions;
  final double totalWithdrawals;
  final double totalDeposits;
  final double totalInterest;
  final double openingBalance;
  final double closingBalance;

  KmhStatement({
    required this.walletId,
    required this.walletName,
    required this.startDate,
    required this.endDate,
    required this.transactions,
    required this.totalWithdrawals,
    required this.totalDeposits,
    required this.totalInterest,
    required this.openingBalance,
    required this.closingBalance,
  });
  double get netChange => closingBalance - openingBalance;
  int get transactionCount => transactions.length;

  KmhStatement copyWith({
    String? walletId,
    String? walletName,
    DateTime? startDate,
    DateTime? endDate,
    List<KmhTransaction>? transactions,
    double? totalWithdrawals,
    double? totalDeposits,
    double? totalInterest,
    double? openingBalance,
    double? closingBalance,
  }) {
    return KmhStatement(
      walletId: walletId ?? this.walletId,
      walletName: walletName ?? this.walletName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      transactions: transactions ?? this.transactions,
      totalWithdrawals: totalWithdrawals ?? this.totalWithdrawals,
      totalDeposits: totalDeposits ?? this.totalDeposits,
      totalInterest: totalInterest ?? this.totalInterest,
      openingBalance: openingBalance ?? this.openingBalance,
      closingBalance: closingBalance ?? this.closingBalance,
    );
  }
}
