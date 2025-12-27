library;

import 'cash_flow_data.dart';
class ComparisonMetric {
  final String label;
  final double period1Value;
  final double period2Value;
  final double absoluteChange;
  final double percentageChange;
  final TrendDirection trend;

  ComparisonMetric({
    required this.label,
    required this.period1Value,
    required this.period2Value,
    required this.absoluteChange,
    required this.percentageChange,
    required this.trend,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'period1Value': period1Value,
    'period2Value': period2Value,
    'absoluteChange': absoluteChange,
    'percentageChange': percentageChange,
    'trend': trend.name,
  };

  factory ComparisonMetric.fromJson(Map<String, dynamic> json) => ComparisonMetric(
    label: json['label'],
    period1Value: json['period1Value'],
    period2Value: json['period2Value'],
    absoluteChange: json['absoluteChange'],
    percentageChange: json['percentageChange'],
    trend: TrendDirection.values.firstWhere(
      (t) => t.name == json['trend'],
      orElse: () => TrendDirection.stable,
    ),
  );
}
class CategoryComparison {
  final String category;
  final double period1Amount;
  final double period2Amount;
  final double absoluteChange;
  final double percentageChange;
  final TrendDirection trend;

  CategoryComparison({
    required this.category,
    required this.period1Amount,
    required this.period2Amount,
    required this.absoluteChange,
    required this.percentageChange,
    required this.trend,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'period1Amount': period1Amount,
    'period2Amount': period2Amount,
    'absoluteChange': absoluteChange,
    'percentageChange': percentageChange,
    'trend': trend.name,
  };

  factory CategoryComparison.fromJson(Map<String, dynamic> json) => CategoryComparison(
    category: json['category'],
    period1Amount: json['period1Amount'],
    period2Amount: json['period2Amount'],
    absoluteChange: json['absoluteChange'],
    percentageChange: json['percentageChange'],
    trend: TrendDirection.values.firstWhere(
      (t) => t.name == json['trend'],
      orElse: () => TrendDirection.stable,
    ),
  );
}
class ComparisonData {
  final DateTime period1Start;
  final DateTime period1End;
  final DateTime period2Start;
  final DateTime period2End;
  final String period1Label;
  final String period2Label;
  final ComparisonMetric income;
  final ComparisonMetric expense;
  final ComparisonMetric netCashFlow;
  final ComparisonMetric? savingsRate;
  final List<CategoryComparison> categoryComparisons;
  final TrendDirection overallTrend;
  final List<String> insights;

  ComparisonData({
    required this.period1Start,
    required this.period1End,
    required this.period2Start,
    required this.period2End,
    required this.period1Label,
    required this.period2Label,
    required this.income,
    required this.expense,
    required this.netCashFlow,
    this.savingsRate,
    required this.categoryComparisons,
    required this.overallTrend,
    required this.insights,
  });

  Map<String, dynamic> toJson() => {
    'period1Start': period1Start.toIso8601String(),
    'period1End': period1End.toIso8601String(),
    'period2Start': period2Start.toIso8601String(),
    'period2End': period2End.toIso8601String(),
    'period1Label': period1Label,
    'period2Label': period2Label,
    'income': income.toJson(),
    'expense': expense.toJson(),
    'netCashFlow': netCashFlow.toJson(),
    'savingsRate': savingsRate?.toJson(),
    'categoryComparisons': categoryComparisons.map((c) => c.toJson()).toList(),
    'overallTrend': overallTrend.name,
    'insights': insights,
  };

  factory ComparisonData.fromJson(Map<String, dynamic> json) => ComparisonData(
    period1Start: DateTime.parse(json['period1Start']),
    period1End: DateTime.parse(json['period1End']),
    period2Start: DateTime.parse(json['period2Start']),
    period2End: DateTime.parse(json['period2End']),
    period1Label: json['period1Label'],
    period2Label: json['period2Label'],
    income: ComparisonMetric.fromJson(json['income']),
    expense: ComparisonMetric.fromJson(json['expense']),
    netCashFlow: ComparisonMetric.fromJson(json['netCashFlow']),
    savingsRate: json['savingsRate'] != null 
        ? ComparisonMetric.fromJson(json['savingsRate'])
        : null,
    categoryComparisons: (json['categoryComparisons'] as List)
        .map((c) => CategoryComparison.fromJson(c))
        .toList(),
    overallTrend: TrendDirection.values.firstWhere(
      (t) => t.name == json['overallTrend'],
      orElse: () => TrendDirection.stable,
    ),
    insights: List<String>.from(json['insights']),
  );
}
