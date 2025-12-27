class KmhSummary {
  final String walletId;
  final String walletName;
  final double currentBalance;
  final double creditLimit;
  final double interestRate;
  final double usedCredit;
  final double availableCredit;
  final double utilizationRate;
  final double accruedInterest;
  final DateTime? lastInterestDate;
  final double dailyInterestEstimate;
  final double monthlyInterestEstimate;
  final double annualInterestEstimate;
  final int totalTransactions;

  KmhSummary({
    required this.walletId,
    required this.walletName,
    required this.currentBalance,
    required this.creditLimit,
    required this.interestRate,
    required this.usedCredit,
    required this.availableCredit,
    required this.utilizationRate,
    required this.accruedInterest,
    this.lastInterestDate,
    required this.dailyInterestEstimate,
    required this.monthlyInterestEstimate,
    required this.annualInterestEstimate,
    required this.totalTransactions,
  });
  bool get isInDebt => currentBalance < 0;
  bool get isNearLimit => utilizationRate >= 80.0;
  bool get isCriticalLimit => utilizationRate >= 95.0;

  KmhSummary copyWith({
    String? walletId,
    String? walletName,
    double? currentBalance,
    double? creditLimit,
    double? interestRate,
    double? usedCredit,
    double? availableCredit,
    double? utilizationRate,
    double? accruedInterest,
    DateTime? lastInterestDate,
    double? dailyInterestEstimate,
    double? monthlyInterestEstimate,
    double? annualInterestEstimate,
    int? totalTransactions,
  }) {
    return KmhSummary(
      walletId: walletId ?? this.walletId,
      walletName: walletName ?? this.walletName,
      currentBalance: currentBalance ?? this.currentBalance,
      creditLimit: creditLimit ?? this.creditLimit,
      interestRate: interestRate ?? this.interestRate,
      usedCredit: usedCredit ?? this.usedCredit,
      availableCredit: availableCredit ?? this.availableCredit,
      utilizationRate: utilizationRate ?? this.utilizationRate,
      accruedInterest: accruedInterest ?? this.accruedInterest,
      lastInterestDate: lastInterestDate ?? this.lastInterestDate,
      dailyInterestEstimate: dailyInterestEstimate ?? this.dailyInterestEstimate,
      monthlyInterestEstimate: monthlyInterestEstimate ?? this.monthlyInterestEstimate,
      annualInterestEstimate: annualInterestEstimate ?? this.annualInterestEstimate,
      totalTransactions: totalTransactions ?? this.totalTransactions,
    );
  }
}
