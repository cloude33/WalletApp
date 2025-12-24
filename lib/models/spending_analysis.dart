library;

import 'cash_flow_data.dart';
enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday
}
class MonthlySpending {
  final DateTime month;
  final double amount;

  MonthlySpending({
    required this.month,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'month': month.toIso8601String(),
    'amount': amount,
  };

  factory MonthlySpending.fromJson(Map<String, dynamic> json) => MonthlySpending(
    month: DateTime.parse(json['month']),
    amount: json['amount'],
  );
}
class CategoryTrend {
  final String category;
  final List<MonthlySpending> monthlySpending;
  final TrendDirection trend;
  final double changePercentage;

  CategoryTrend({
    required this.category,
    required this.monthlySpending,
    required this.trend,
    required this.changePercentage,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'monthlySpending': monthlySpending.map((m) => m.toJson()).toList(),
    'trend': trend.name,
    'changePercentage': changePercentage,
  };

  factory CategoryTrend.fromJson(Map<String, dynamic> json) => CategoryTrend(
    category: json['category'],
    monthlySpending: (json['monthlySpending'] as List)
        .map((m) => MonthlySpending.fromJson(m))
        .toList(),
    trend: TrendDirection.values.firstWhere(
      (t) => t.name == json['trend'],
      orElse: () => TrendDirection.stable,
    ),
    changePercentage: json['changePercentage'],
  );
}
class BudgetComparison {
  final String category;
  final double budget;
  final double actual;
  final double remaining;
  final double usagePercentage;
  final bool exceeded;

  BudgetComparison({
    required this.category,
    required this.budget,
    required this.actual,
    required this.remaining,
    required this.usagePercentage,
    required this.exceeded,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'budget': budget,
    'actual': actual,
    'remaining': remaining,
    'usagePercentage': usagePercentage,
    'exceeded': exceeded,
  };

  factory BudgetComparison.fromJson(Map<String, dynamic> json) => BudgetComparison(
    category: json['category'],
    budget: json['budget'],
    actual: json['actual'],
    remaining: json['remaining'],
    usagePercentage: json['usagePercentage'],
    exceeded: json['exceeded'],
  );
}
class SpendingAnalysis {
  final double totalSpending;
  final Map<String, double> categoryBreakdown;
  final Map<String, double> paymentMethodBreakdown;
  final List<CategoryTrend> categoryTrends;
  final Map<String, BudgetComparison> budgetComparisons;
  final String topCategory;
  final double topCategoryAmount;
  final DayOfWeek mostSpendingDay;
  final int mostSpendingHour;

  SpendingAnalysis({
    required this.totalSpending,
    required this.categoryBreakdown,
    required this.paymentMethodBreakdown,
    required this.categoryTrends,
    required this.budgetComparisons,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.mostSpendingDay,
    required this.mostSpendingHour,
  });

  Map<String, dynamic> toJson() => {
    'totalSpending': totalSpending,
    'categoryBreakdown': categoryBreakdown,
    'paymentMethodBreakdown': paymentMethodBreakdown,
    'categoryTrends': categoryTrends.map((t) => t.toJson()).toList(),
    'budgetComparisons': budgetComparisons.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'topCategory': topCategory,
    'topCategoryAmount': topCategoryAmount,
    'mostSpendingDay': mostSpendingDay.name,
    'mostSpendingHour': mostSpendingHour,
  };

  factory SpendingAnalysis.fromJson(Map<String, dynamic> json) => SpendingAnalysis(
    totalSpending: json['totalSpending'],
    categoryBreakdown: Map<String, double>.from(json['categoryBreakdown']),
    paymentMethodBreakdown: Map<String, double>.from(json['paymentMethodBreakdown']),
    categoryTrends: (json['categoryTrends'] as List)
        .map((t) => CategoryTrend.fromJson(t))
        .toList(),
    budgetComparisons: (json['budgetComparisons'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, BudgetComparison.fromJson(value)),
    ),
    topCategory: json['topCategory'],
    topCategoryAmount: json['topCategoryAmount'],
    mostSpendingDay: DayOfWeek.values.firstWhere(
      (d) => d.name == json['mostSpendingDay'],
      orElse: () => DayOfWeek.monday,
    ),
    mostSpendingHour: json['mostSpendingHour'],
  );
}
