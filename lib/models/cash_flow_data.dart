library;
class MonthlyData {
  final DateTime month;
  final double income;
  final double expense;
  final double netFlow;

  MonthlyData({
    required this.month,
    required this.income,
    required this.expense,
    required this.netFlow,
  });

  Map<String, dynamic> toJson() => {
    'month': month.toIso8601String(),
    'income': income,
    'expense': expense,
    'netFlow': netFlow,
  };

  factory MonthlyData.fromJson(Map<String, dynamic> json) => MonthlyData(
    month: DateTime.parse(json['month']),
    income: json['income'],
    expense: json['expense'],
    netFlow: json['netFlow'],
  );
}
enum TrendDirection {
  up,
  down,
  stable
}
class CashFlowData {
  final double totalIncome;
  final double totalExpense;
  final double netCashFlow;
  final double averageDaily;
  final double averageMonthly;
  final List<MonthlyData> monthlyData;
  final TrendDirection trend;
  final double? previousPeriodIncome;
  final double? previousPeriodExpense;
  final double? changePercentage;
  final double? predictedIncome;
  final double? predictedExpense;
  final double? predictedNetFlow;

  CashFlowData({
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashFlow,
    required this.averageDaily,
    required this.averageMonthly,
    required this.monthlyData,
    required this.trend,
    this.previousPeriodIncome,
    this.previousPeriodExpense,
    this.changePercentage,
    this.predictedIncome,
    this.predictedExpense,
    this.predictedNetFlow,
  });

  Map<String, dynamic> toJson() => {
    'totalIncome': totalIncome,
    'totalExpense': totalExpense,
    'netCashFlow': netCashFlow,
    'averageDaily': averageDaily,
    'averageMonthly': averageMonthly,
    'monthlyData': monthlyData.map((m) => m.toJson()).toList(),
    'trend': trend.name,
    'previousPeriodIncome': previousPeriodIncome,
    'previousPeriodExpense': previousPeriodExpense,
    'changePercentage': changePercentage,
    'predictedIncome': predictedIncome,
    'predictedExpense': predictedExpense,
    'predictedNetFlow': predictedNetFlow,
  };

  factory CashFlowData.fromJson(Map<String, dynamic> json) => CashFlowData(
    totalIncome: json['totalIncome'],
    totalExpense: json['totalExpense'],
    netCashFlow: json['netCashFlow'],
    averageDaily: json['averageDaily'],
    averageMonthly: json['averageMonthly'],
    monthlyData: (json['monthlyData'] as List)
        .map((m) => MonthlyData.fromJson(m))
        .toList(),
    trend: TrendDirection.values.firstWhere(
      (t) => t.name == json['trend'],
      orElse: () => TrendDirection.stable,
    ),
    previousPeriodIncome: json['previousPeriodIncome'],
    previousPeriodExpense: json['previousPeriodExpense'],
    changePercentage: json['changePercentage'],
    predictedIncome: json['predictedIncome'],
    predictedExpense: json['predictedExpense'],
    predictedNetFlow: json['predictedNetFlow'],
  );
}
