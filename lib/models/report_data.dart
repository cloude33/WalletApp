library;

import 'cash_flow_data.dart';
enum ReportType {
  income,
  expense,
  bill,
  custom
}
enum ReportPeriod {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
  custom
}
abstract class ReportData {
  final String title;
  final ReportType type;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime generatedAt;

  ReportData({
    required this.title,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson();
}
class IncomeSource {
  final String source;
  final double amount;
  final double percentage;
  final int transactionCount;

  IncomeSource({
    required this.source,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
  });

  Map<String, dynamic> toJson() => {
    'source': source,
    'amount': amount,
    'percentage': percentage,
    'transactionCount': transactionCount,
  };

  factory IncomeSource.fromJson(Map<String, dynamic> json) => IncomeSource(
    source: json['source'],
    amount: json['amount'],
    percentage: json['percentage'],
    transactionCount: json['transactionCount'],
  );
}
class IncomeReport extends ReportData {
  final double totalIncome;
  final List<IncomeSource> incomeSources;
  final List<MonthlyData> monthlyIncome;
  final TrendDirection trend;
  final double averageMonthly;
  final double? previousPeriodIncome;
  final double? changePercentage;
  final DateTime? highestIncomeMonth;
  final double? highestIncomeAmount;

  IncomeReport({
    required super.title,
    required super.startDate,
    required super.endDate,
    required super.generatedAt,
    required this.totalIncome,
    required this.incomeSources,
    required this.monthlyIncome,
    required this.trend,
    required this.averageMonthly,
    this.previousPeriodIncome,
    this.changePercentage,
    this.highestIncomeMonth,
    this.highestIncomeAmount,
  }) : super(type: ReportType.income);

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'type': type.name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'generatedAt': generatedAt.toIso8601String(),
    'totalIncome': totalIncome,
    'incomeSources': incomeSources.map((s) => s.toJson()).toList(),
    'monthlyIncome': monthlyIncome.map((m) => m.toJson()).toList(),
    'trend': trend.name,
    'averageMonthly': averageMonthly,
    'previousPeriodIncome': previousPeriodIncome,
    'changePercentage': changePercentage,
    'highestIncomeMonth': highestIncomeMonth?.toIso8601String(),
    'highestIncomeAmount': highestIncomeAmount,
  };

  factory IncomeReport.fromJson(Map<String, dynamic> json) => IncomeReport(
    title: json['title'],
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    generatedAt: DateTime.parse(json['generatedAt']),
    totalIncome: json['totalIncome'],
    incomeSources: (json['incomeSources'] as List)
        .map((s) => IncomeSource.fromJson(s))
        .toList(),
    monthlyIncome: (json['monthlyIncome'] as List)
        .map((m) => MonthlyData.fromJson(m))
        .toList(),
    trend: TrendDirection.values.firstWhere(
      (t) => t.name == json['trend'],
      orElse: () => TrendDirection.stable,
    ),
    averageMonthly: json['averageMonthly'],
    previousPeriodIncome: json['previousPeriodIncome'],
    changePercentage: json['changePercentage'],
    highestIncomeMonth: json['highestIncomeMonth'] != null
        ? DateTime.parse(json['highestIncomeMonth'])
        : null,
    highestIncomeAmount: json['highestIncomeAmount'],
  );
}
class ExpenseCategory {
  final String category;
  final double amount;
  final double percentage;
  final int transactionCount;
  final bool isFixed;

  ExpenseCategory({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
    required this.isFixed,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'amount': amount,
    'percentage': percentage,
    'transactionCount': transactionCount,
    'isFixed': isFixed,
  };

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) => ExpenseCategory(
    category: json['category'],
    amount: json['amount'],
    percentage: json['percentage'],
    transactionCount: json['transactionCount'],
    isFixed: json['isFixed'],
  );
}
class OptimizationSuggestion {
  final String category;
  final String suggestion;
  final double potentialSavings;
  final int priority;

  OptimizationSuggestion({
    required this.category,
    required this.suggestion,
    required this.potentialSavings,
    required this.priority,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'suggestion': suggestion,
    'potentialSavings': potentialSavings,
    'priority': priority,
  };

  factory OptimizationSuggestion.fromJson(Map<String, dynamic> json) => OptimizationSuggestion(
    category: json['category'],
    suggestion: json['suggestion'],
    potentialSavings: json['potentialSavings'],
    priority: json['priority'],
  );
}
class ExpenseReport extends ReportData {
  final double totalExpense;
  final List<ExpenseCategory> expenseCategories;
  final List<MonthlyData> monthlyExpense;
  final TrendDirection trend;
  final double averageMonthly;
  final double totalFixedExpense;
  final double totalVariableExpense;
  final double? previousPeriodExpense;
  final double? changePercentage;
  final List<OptimizationSuggestion> optimizationSuggestions;

  ExpenseReport({
    required super.title,
    required super.startDate,
    required super.endDate,
    required super.generatedAt,
    required this.totalExpense,
    required this.expenseCategories,
    required this.monthlyExpense,
    required this.trend,
    required this.averageMonthly,
    required this.totalFixedExpense,
    required this.totalVariableExpense,
    this.previousPeriodExpense,
    this.changePercentage,
    required this.optimizationSuggestions,
  }) : super(type: ReportType.expense);

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'type': type.name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'generatedAt': generatedAt.toIso8601String(),
    'totalExpense': totalExpense,
    'expenseCategories': expenseCategories.map((c) => c.toJson()).toList(),
    'monthlyExpense': monthlyExpense.map((m) => m.toJson()).toList(),
    'trend': trend.name,
    'averageMonthly': averageMonthly,
    'totalFixedExpense': totalFixedExpense,
    'totalVariableExpense': totalVariableExpense,
    'previousPeriodExpense': previousPeriodExpense,
    'changePercentage': changePercentage,
    'optimizationSuggestions': optimizationSuggestions.map((s) => s.toJson()).toList(),
  };

  factory ExpenseReport.fromJson(Map<String, dynamic> json) => ExpenseReport(
    title: json['title'],
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    generatedAt: DateTime.parse(json['generatedAt']),
    totalExpense: json['totalExpense'],
    expenseCategories: (json['expenseCategories'] as List)
        .map((c) => ExpenseCategory.fromJson(c))
        .toList(),
    monthlyExpense: (json['monthlyExpense'] as List)
        .map((m) => MonthlyData.fromJson(m))
        .toList(),
    trend: TrendDirection.values.firstWhere(
      (t) => t.name == json['trend'],
      orElse: () => TrendDirection.stable,
    ),
    averageMonthly: json['averageMonthly'],
    totalFixedExpense: json['totalFixedExpense'],
    totalVariableExpense: json['totalVariableExpense'],
    previousPeriodExpense: json['previousPeriodExpense'],
    changePercentage: json['changePercentage'],
    optimizationSuggestions: (json['optimizationSuggestions'] as List)
        .map((s) => OptimizationSuggestion.fromJson(s))
        .toList(),
  );
}
class BillPaymentData {
  final String billName;
  final double amount;
  final DateTime paymentDate;
  final DateTime dueDate;
  final bool onTime;
  final String category;
  final String paymentMethod;

  BillPaymentData({
    required this.billName,
    required this.amount,
    required this.paymentDate,
    required this.dueDate,
    required this.onTime,
    required this.category,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() => {
    'billName': billName,
    'amount': amount,
    'paymentDate': paymentDate.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'onTime': onTime,
    'category': category,
    'paymentMethod': paymentMethod,
  };

  factory BillPaymentData.fromJson(Map<String, dynamic> json) => BillPaymentData(
    billName: json['billName'],
    amount: json['amount'],
    paymentDate: DateTime.parse(json['paymentDate']),
    dueDate: DateTime.parse(json['dueDate']),
    onTime: json['onTime'],
    category: json['category'],
    paymentMethod: json['paymentMethod'],
  );
}
class BillReport extends ReportData {
  final double totalPaid;
  final int billCount;
  final int onTimeCount;
  final int lateCount;
  final double onTimePercentage;
  final List<BillPaymentData> billPayments;
  final Map<String, double> categoryBreakdown;
  final double averageBillAmount;
  final List<BillPaymentData> upcomingBills;

  BillReport({
    required super.title,
    required super.startDate,
    required super.endDate,
    required super.generatedAt,
    required this.totalPaid,
    required this.billCount,
    required this.onTimeCount,
    required this.lateCount,
    required this.onTimePercentage,
    required this.billPayments,
    required this.categoryBreakdown,
    required this.averageBillAmount,
    required this.upcomingBills,
  }) : super(type: ReportType.bill);

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'type': type.name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'generatedAt': generatedAt.toIso8601String(),
    'totalPaid': totalPaid,
    'billCount': billCount,
    'onTimeCount': onTimeCount,
    'lateCount': lateCount,
    'onTimePercentage': onTimePercentage,
    'billPayments': billPayments.map((b) => b.toJson()).toList(),
    'categoryBreakdown': categoryBreakdown,
    'averageBillAmount': averageBillAmount,
    'upcomingBills': upcomingBills.map((b) => b.toJson()).toList(),
  };

  factory BillReport.fromJson(Map<String, dynamic> json) => BillReport(
    title: json['title'],
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    generatedAt: DateTime.parse(json['generatedAt']),
    totalPaid: json['totalPaid'],
    billCount: json['billCount'],
    onTimeCount: json['onTimeCount'],
    lateCount: json['lateCount'],
    onTimePercentage: json['onTimePercentage'],
    billPayments: (json['billPayments'] as List)
        .map((b) => BillPaymentData.fromJson(b))
        .toList(),
    categoryBreakdown: Map<String, double>.from(json['categoryBreakdown']),
    averageBillAmount: json['averageBillAmount'],
    upcomingBills: (json['upcomingBills'] as List)
        .map((b) => BillPaymentData.fromJson(b))
        .toList(),
  );
}
class CustomReportFilters {
  final DateTime startDate;
  final DateTime endDate;
  final List<String>? categories;
  final List<String>? walletIds;
  final bool includeIncome;
  final bool includeExpenses;
  final bool includeBills;
  final double? minAmount;
  final double? maxAmount;

  CustomReportFilters({
    required this.startDate,
    required this.endDate,
    this.categories,
    this.walletIds,
    this.includeIncome = true,
    this.includeExpenses = true,
    this.includeBills = true,
    this.minAmount,
    this.maxAmount,
  });

  Map<String, dynamic> toJson() => {
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'categories': categories,
    'walletIds': walletIds,
    'includeIncome': includeIncome,
    'includeExpenses': includeExpenses,
    'includeBills': includeBills,
    'minAmount': minAmount,
    'maxAmount': maxAmount,
  };

  factory CustomReportFilters.fromJson(Map<String, dynamic> json) => CustomReportFilters(
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    categories: json['categories'] != null 
        ? List<String>.from(json['categories'])
        : null,
    walletIds: json['walletIds'] != null 
        ? List<String>.from(json['walletIds'])
        : null,
    includeIncome: json['includeIncome'] ?? true,
    includeExpenses: json['includeExpenses'] ?? true,
    includeBills: json['includeBills'] ?? true,
    minAmount: json['minAmount'],
    maxAmount: json['maxAmount'],
  );
}
class CustomReport extends ReportData {
  final CustomReportFilters filters;
  final double? totalIncome;
  final double? totalExpense;
  final double? totalBills;
  final double netAmount;
  final int transactionCount;
  final Map<String, double> categoryBreakdown;
  final Map<String, double> walletBreakdown;
  final List<MonthlyData> monthlyData;

  CustomReport({
    required super.title,
    required super.startDate,
    required super.endDate,
    required super.generatedAt,
    required this.filters,
    this.totalIncome,
    this.totalExpense,
    this.totalBills,
    required this.netAmount,
    required this.transactionCount,
    required this.categoryBreakdown,
    required this.walletBreakdown,
    required this.monthlyData,
  }) : super(type: ReportType.custom);

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'type': type.name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'generatedAt': generatedAt.toIso8601String(),
    'filters': filters.toJson(),
    'totalIncome': totalIncome,
    'totalExpense': totalExpense,
    'totalBills': totalBills,
    'netAmount': netAmount,
    'transactionCount': transactionCount,
    'categoryBreakdown': categoryBreakdown,
    'walletBreakdown': walletBreakdown,
    'monthlyData': monthlyData.map((m) => m.toJson()).toList(),
  };

  factory CustomReport.fromJson(Map<String, dynamic> json) => CustomReport(
    title: json['title'],
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    generatedAt: DateTime.parse(json['generatedAt']),
    filters: CustomReportFilters.fromJson(json['filters']),
    totalIncome: json['totalIncome'],
    totalExpense: json['totalExpense'],
    totalBills: json['totalBills'],
    netAmount: json['netAmount'],
    transactionCount: json['transactionCount'],
    categoryBreakdown: Map<String, double>.from(json['categoryBreakdown']),
    walletBreakdown: Map<String, double>.from(json['walletBreakdown']),
    monthlyData: (json['monthlyData'] as List)
        .map((m) => MonthlyData.fromJson(m))
        .toList(),
  );
}
