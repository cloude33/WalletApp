import 'package:flutter_test/flutter_test.dart';
import 'package:money/models/report_data.dart';
import 'package:money/models/cash_flow_data.dart';

void main() {
  group('Report Data Models', () {
    test('should serialize and deserialize IncomeReport', () {
      final report = IncomeReport(
        title: 'Test Report',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        generatedAt: DateTime.now(),
        totalIncome: 5000.0,
        incomeSources: [
          IncomeSource(
            source: 'Salary',
            amount: 5000.0,
            percentage: 100.0,
            transactionCount: 1,
          ),
        ],
        monthlyIncome: [
          MonthlyData(
            month: DateTime(2024, 1, 1),
            income: 5000.0,
            expense: 0.0,
            netFlow: 5000.0,
          ),
        ],
        trend: TrendDirection.stable,
        averageMonthly: 5000.0,
      );

      final json = report.toJson();
      final deserialized = IncomeReport.fromJson(json);

      expect(deserialized.totalIncome, equals(report.totalIncome));
      expect(deserialized.title, equals(report.title));
      expect(deserialized.trend, equals(report.trend));
    });

    test('should serialize and deserialize ExpenseReport', () {
      final report = ExpenseReport(
        title: 'Test Report',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        generatedAt: DateTime.now(),
        totalExpense: 3000.0,
        expenseCategories: [
          ExpenseCategory(
            category: 'Market',
            amount: 1000.0,
            percentage: 33.33,
            transactionCount: 5,
            isFixed: false,
          ),
        ],
        monthlyExpense: [
          MonthlyData(
            month: DateTime(2024, 1, 1),
            income: 0.0,
            expense: 3000.0,
            netFlow: -3000.0,
          ),
        ],
        trend: TrendDirection.up,
        averageMonthly: 3000.0,
        totalFixedExpense: 1000.0,
        totalVariableExpense: 2000.0,
        optimizationSuggestions: [],
      );

      final json = report.toJson();
      final deserialized = ExpenseReport.fromJson(json);

      expect(deserialized.totalExpense, equals(report.totalExpense));
      expect(deserialized.totalFixedExpense, equals(report.totalFixedExpense));
      expect(
        deserialized.totalVariableExpense,
        equals(report.totalVariableExpense),
      );
    });

    test('should serialize and deserialize BillReport', () {
      final report = BillReport(
        title: 'Test Report',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        generatedAt: DateTime.now(),
        totalPaid: 1500.0,
        billCount: 5,
        onTimeCount: 4,
        lateCount: 1,
        onTimePercentage: 80.0,
        billPayments: [],
        categoryBreakdown: {'Elektrik': 500.0, 'Su': 200.0},
        averageBillAmount: 300.0,
        upcomingBills: [],
      );

      final json = report.toJson();
      final deserialized = BillReport.fromJson(json);

      expect(deserialized.totalPaid, equals(report.totalPaid));
      expect(deserialized.billCount, equals(report.billCount));
      expect(deserialized.onTimePercentage, equals(report.onTimePercentage));
    });

    test('should serialize and deserialize CustomReport', () {
      final filters = CustomReportFilters(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        categories: ['Market'],
      );

      final report = CustomReport(
        title: 'Test Report',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        generatedAt: DateTime.now(),
        filters: filters,
        totalIncome: 5000.0,
        totalExpense: 3000.0,
        netAmount: 2000.0,
        transactionCount: 10,
        categoryBreakdown: {'Market': 1000.0},
        walletBreakdown: {'Card 1': 1000.0},
        monthlyData: [],
      );

      final json = report.toJson();
      final deserialized = CustomReport.fromJson(json);

      expect(deserialized.totalIncome, equals(report.totalIncome));
      expect(deserialized.totalExpense, equals(report.totalExpense));
      expect(deserialized.netAmount, equals(report.netAmount));
    });
  });
}
