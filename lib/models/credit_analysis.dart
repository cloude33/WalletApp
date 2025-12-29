library;
class CreditCardSummary {
  final String cardId;
  final String cardName;
  final double debt;
  final double limit;
  final double utilizationRate;
  final double? minimumPayment;
  final DateTime? dueDate;

  CreditCardSummary({
    required this.cardId,
    required this.cardName,
    required this.debt,
    required this.limit,
    required this.utilizationRate,
    this.minimumPayment,
    this.dueDate,
  });

  Map<String, dynamic> toJson() => {
    'cardId': cardId,
    'cardName': cardName,
    'debt': debt,
    'limit': limit,
    'utilizationRate': utilizationRate,
    'minimumPayment': minimumPayment,
    'dueDate': dueDate?.toIso8601String(),
  };

  factory CreditCardSummary.fromJson(Map<String, dynamic> json) => CreditCardSummary(
    cardId: json['cardId'],
    cardName: json['cardName'],
    debt: json['debt'],
    limit: json['limit'],
    utilizationRate: json['utilizationRate'],
    minimumPayment: json['minimumPayment'],
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
  );
}
class KmhSummary {
  final String accountId;
  final String bankName;
  final double balance;
  final double limit;
  final double utilizationRate;
  final double interestRate;
  final double dailyInterest;

  KmhSummary({
    required this.accountId,
    required this.bankName,
    required this.balance,
    required this.limit,
    required this.utilizationRate,
    required this.interestRate,
    required this.dailyInterest,
  });

  Map<String, dynamic> toJson() => {
    'accountId': accountId,
    'bankName': bankName,
    'balance': balance,
    'limit': limit,
    'utilizationRate': utilizationRate,
    'interestRate': interestRate,
    'dailyInterest': dailyInterest,
  };

  factory KmhSummary.fromJson(Map<String, dynamic> json) => KmhSummary(
    accountId: json['accountId'],
    bankName: json['bankName'],
    balance: json['balance'],
    limit: json['limit'],
    utilizationRate: json['utilizationRate'],
    interestRate: json['interestRate'],
    dailyInterest: json['dailyInterest'],
  );
}
class DebtTrendData {
  final DateTime date;
  final double creditCardDebt;
  final double kmhDebt;
  final double totalDebt;

  DebtTrendData({
    required this.date,
    required this.creditCardDebt,
    required this.kmhDebt,
    required this.totalDebt,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'creditCardDebt': creditCardDebt,
    'kmhDebt': kmhDebt,
    'totalDebt': totalDebt,
  };

  factory DebtTrendData.fromJson(Map<String, dynamic> json) => DebtTrendData(
    date: DateTime.parse(json['date']),
    creditCardDebt: json['creditCardDebt'],
    kmhDebt: json['kmhDebt'],
    totalDebt: json['totalDebt'],
  );
}
class CreditAnalysis {
  final double totalCreditCardDebt;
  final double totalCreditLimit;
  final double creditUtilization;
  final List<CreditCardSummary> creditCards;
  final double totalKmhDebt;
  final double totalKmhLimit;
  final double kmhUtilization;
  final List<KmhSummary> kmhAccounts;
  final double dailyInterest;
  final double monthlyInterest;
  final double annualInterest;
  final double totalDebt;
  final double? debtToIncomeRatio;
  final List<DebtTrendData> debtTrend;

  CreditAnalysis({
    required this.totalCreditCardDebt,
    required this.totalCreditLimit,
    required this.creditUtilization,
    required this.creditCards,
    required this.totalKmhDebt,
    required this.totalKmhLimit,
    required this.kmhUtilization,
    required this.kmhAccounts,
    required this.dailyInterest,
    required this.monthlyInterest,
    required this.annualInterest,
    required this.totalDebt,
    this.debtToIncomeRatio,
    required this.debtTrend,
  });

  Map<String, dynamic> toJson() => {
    'totalCreditCardDebt': totalCreditCardDebt,
    'totalCreditLimit': totalCreditLimit,
    'creditUtilization': creditUtilization,
    'creditCards': creditCards.map((c) => c.toJson()).toList(),
    'totalKmhDebt': totalKmhDebt,
    'totalKmhLimit': totalKmhLimit,
    'kmhUtilization': kmhUtilization,
    'kmhAccounts': kmhAccounts.map((k) => k.toJson()).toList(),
    'dailyInterest': dailyInterest,
    'monthlyInterest': monthlyInterest,
    'annualInterest': annualInterest,
    'totalDebt': totalDebt,
    'debtToIncomeRatio': debtToIncomeRatio,
    'debtTrend': debtTrend.map((d) => d.toJson()).toList(),
  };

  factory CreditAnalysis.fromJson(Map<String, dynamic> json) => CreditAnalysis(
    totalCreditCardDebt: json['totalCreditCardDebt'],
    totalCreditLimit: json['totalCreditLimit'],
    creditUtilization: json['creditUtilization'],
    creditCards: (json['creditCards'] as List)
        .map((c) => CreditCardSummary.fromJson(c))
        .toList(),
    totalKmhDebt: json['totalKmhDebt'],
    totalKmhLimit: json['totalKmhLimit'],
    kmhUtilization: json['kmhUtilization'],
    kmhAccounts: (json['kmhAccounts'] as List)
        .map((k) => KmhSummary.fromJson(k))
        .toList(),
    dailyInterest: json['dailyInterest'],
    monthlyInterest: json['monthlyInterest'],
    annualInterest: json['annualInterest'],
    totalDebt: json['totalDebt'],
    debtToIncomeRatio: json['debtToIncomeRatio'],
    debtTrend: (json['debtTrend'] as List)
        .map((d) => DebtTrendData.fromJson(d))
        .toList(),
  );
}
