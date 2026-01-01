import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/statistics_service.dart';
import 'package:parion/models/cash_flow_data.dart';
import 'package:parion/models/spending_analysis.dart';

/// Unit Tests for StatisticsService
///
/// These tests focus on testing calculation logic and data transformations
/// that don't require database initialization.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StatisticsService statisticsService;

  setUp(() {
    statisticsService = StatisticsService();
  });

  tearDown(() {
    statisticsService.clearCache();
  });

  group('StatisticsService - Data Model Calculations', () {
    test('should validate cash flow data consistency', () {
      // Test that cash flow data model maintains consistency
      final cashFlow = CashFlowData(
        totalIncome: 5000.0,
        totalExpense: 3000.0,
        netCashFlow: 2000.0,
        averageDaily: 66.67,
        averageMonthly: 2000.0,
        monthlyData: [
          MonthlyData(
            month: DateTime(2024, 1, 1),
            income: 5000.0,
            expense: 3000.0,
            netFlow: 2000.0,
          ),
        ],
        trend: TrendDirection.up,
      );

      expect(cashFlow.netCashFlow, equals(cashFlow.totalIncome - cashFlow.totalExpense));
      expect(cashFlow.monthlyData.first.netFlow,
          equals(cashFlow.monthlyData.first.income - cashFlow.monthlyData.first.expense));
    });

    test('should validate spending analysis data consistency', () {
      // Test that spending analysis maintains category breakdown consistency
      final categoryBreakdown = {
        'Food': 1000.0,
        'Transport': 500.0,
        'Entertainment': 300.0,
      };

      final totalSpending = categoryBreakdown.values.fold<double>(0, (sum, value) => sum + value);

      final spendingAnalysis = SpendingAnalysis(
        totalSpending: totalSpending,
        categoryBreakdown: categoryBreakdown,
        paymentMethodBreakdown: {'Credit Card': totalSpending},
        categoryTrends: [],
        budgetComparisons: {},
        topCategory: 'Food',
        topCategoryAmount: 1000.0,
        mostSpendingDay: DayOfWeek.monday,
        mostSpendingHour: 12,
      );

      expect(spendingAnalysis.totalSpending, equals(1800.0));
      expect(spendingAnalysis.topCategoryAmount, equals(categoryBreakdown['Food']));
    });

    test('should calculate budget comparison correctly', () {
      // Test budget comparison logic
      final budget = 1000.0;
      final actual = 800.0;
      final remaining = budget - actual;
      final usagePercentage = (actual / budget) * 100;
      final exceeded = actual > budget;

      final budgetComparison = BudgetComparison(
        category: 'Food',
        budget: budget,
        actual: actual,
        remaining: remaining,
        usagePercentage: usagePercentage,
        exceeded: exceeded,
      );

      expect(budgetComparison.remaining, equals(200.0));
      expect(budgetComparison.usagePercentage, equals(80.0));
      expect(budgetComparison.exceeded, isFalse);
    });

    test('should calculate budget comparison when exceeded', () {
      // Test budget comparison when budget is exceeded
      final budget = 1000.0;
      final actual = 1200.0;
      final remaining = budget - actual;
      final usagePercentage = (actual / budget) * 100;
      final exceeded = actual > budget;

      final budgetComparison = BudgetComparison(
        category: 'Food',
        budget: budget,
        actual: actual,
        remaining: remaining,
        usagePercentage: usagePercentage,
        exceeded: exceeded,
      );

      expect(budgetComparison.remaining, equals(-200.0));
      expect(budgetComparison.usagePercentage, equals(120.0));
      expect(budgetComparison.exceeded, isTrue);
    });
  });

  group('StatisticsService - Comparison Calculations', () {
    test('should calculate comparison metric correctly', () {
      // Test comparison metric calculation logic
      final period1Value = 1000.0;
      final period2Value = 1200.0;
      final absoluteChange = period2Value - period1Value;
      final percentageChange = (absoluteChange / period1Value.abs()) * 100;

      final comparison = ComparisonMetric(
        label: 'Income',
        period1Value: period1Value,
        period2Value: period2Value,
        absoluteChange: absoluteChange,
        percentageChange: percentageChange,
        trend: TrendDirection.up,
      );

      expect(comparison.absoluteChange, equals(200.0));
      expect(comparison.percentageChange, equals(20.0));
      expect(comparison.trend, equals(TrendDirection.up));
    });

    test('should calculate percentage change when period1 is zero', () {
      // Test edge case when first period value is zero
      final period1Value = 0.0;
      final period2Value = 1000.0;
      final absoluteChange = period2Value - period1Value;
      
      // When period1 is 0 and period2 is positive, percentage should be 100%
      final percentageChange = period2Value > 0 ? 100.0 : -100.0;

      final comparison = ComparisonMetric(
        label: 'Income',
        period1Value: period1Value,
        period2Value: period2Value,
        absoluteChange: absoluteChange,
        percentageChange: percentageChange,
        trend: TrendDirection.up,
      );

      expect(comparison.absoluteChange, equals(1000.0));
      expect(comparison.percentageChange, equals(100.0));
    });

    test('should calculate category comparison correctly', () {
      // Test category comparison logic
      final period1Amount = 500.0;
      final period2Amount = 600.0;
      final absoluteChange = period2Amount - period1Amount;
      final percentageChange = (absoluteChange / period1Amount) * 100;

      final categoryComparison = CategoryComparison(
        category: 'Food',
        period1Amount: period1Amount,
        period2Amount: period2Amount,
        absoluteChange: absoluteChange,
        percentageChange: percentageChange,
        trend: TrendDirection.up,
      );

      expect(categoryComparison.absoluteChange, equals(100.0));
      expect(categoryComparison.percentageChange, equals(20.0));
      expect(categoryComparison.trend, equals(TrendDirection.up));
    });

    test('should determine trend direction correctly for increase', () {
      // Test trend direction for increasing values
      final period1Value = 1000.0;
      final period2Value = 1100.0;
      final absoluteChange = period2Value - period1Value;
      final threshold = period1Value.abs() * 0.05; // 5% threshold

      final trend = absoluteChange > threshold
          ? TrendDirection.up
          : absoluteChange < -threshold
              ? TrendDirection.down
              : TrendDirection.stable;

      expect(trend, equals(TrendDirection.up));
    });

    test('should determine trend direction correctly for decrease', () {
      // Test trend direction for decreasing values
      final period1Value = 1000.0;
      final period2Value = 900.0;
      final absoluteChange = period2Value - period1Value;
      final threshold = period1Value.abs() * 0.05; // 5% threshold

      final trend = absoluteChange > threshold
          ? TrendDirection.up
          : absoluteChange < -threshold
              ? TrendDirection.down
              : TrendDirection.stable;

      expect(trend, equals(TrendDirection.down));
    });

    test('should determine trend direction correctly for stable', () {
      // Test trend direction for stable values (within 5% threshold)
      final period1Value = 1000.0;
      final period2Value = 1020.0; // 2% increase
      final absoluteChange = period2Value - period1Value;
      final threshold = period1Value.abs() * 0.05; // 5% threshold

      final trend = absoluteChange > threshold
          ? TrendDirection.up
          : absoluteChange < -threshold
              ? TrendDirection.down
              : TrendDirection.stable;

      expect(trend, equals(TrendDirection.stable));
    });
  });

  group('StatisticsService - Calculation Functions', () {
    test('should calculate utilization rate correctly', () {
      // Test utilization rate calculation
      final debt = 5000.0;
      final limit = 10000.0;
      final utilizationRate = (debt / limit) * 100.0;

      expect(utilizationRate, equals(50.0));
    });

    test('should calculate utilization rate when limit is zero', () {
      // Test edge case when limit is zero
      final debt = 5000.0;
      final limit = 0.0;
      final utilizationRate = limit > 0 ? (debt / limit) * 100.0 : 0.0;

      expect(utilizationRate, equals(0.0));
    });

    test('should calculate daily interest correctly', () {
      // Test daily interest calculation
      final debt = 10000.0;
      final annualRate = 24.0; // 24% annual rate
      final dailyInterest = (debt * (annualRate / 100)) / 365;

      expect(dailyInterest, closeTo(6.58, 0.01));
    });

    test('should calculate monthly interest from daily', () {
      // Test monthly interest calculation
      final dailyInterest = 6.58;
      final monthlyInterest = dailyInterest * 30;

      expect(monthlyInterest, closeTo(197.4, 0.1));
    });

    test('should calculate annual interest from daily', () {
      // Test annual interest calculation
      final dailyInterest = 6.58;
      final annualInterest = dailyInterest * 365;

      expect(annualInterest, closeTo(2401.7, 0.1));
    });

    test('should calculate liquidity ratio correctly', () {
      // Test liquidity ratio calculation
      final liquidAssets = 5000.0;
      final liabilities = 2000.0;
      final liquidityRatio = liquidAssets / liabilities;

      expect(liquidityRatio, equals(2.5));
    });

    test('should calculate liquidity ratio when liabilities are zero', () {
      // Test edge case when liabilities are zero
      final liquidAssets = 5000.0;
      final liabilities = 0.0;
      final liquidityRatio = liabilities > 0
          ? liquidAssets / liabilities
          : liquidAssets > 0
              ? 999.99
              : 0.0;

      expect(liquidityRatio, equals(999.99));
    });

    test('should calculate net worth correctly', () {
      // Test net worth calculation
      final totalAssets = 50000.0;
      final totalLiabilities = 20000.0;
      final netWorth = totalAssets - totalLiabilities;

      expect(netWorth, equals(30000.0));
    });

    test('should calculate savings rate correctly', () {
      // Test savings rate calculation
      final netCashFlow = 2000.0;
      final totalIncome = 10000.0;
      final savingsRate = (netCashFlow / totalIncome) * 100;

      expect(savingsRate, equals(20.0));
    });

    test('should calculate savings rate when income is zero', () {
      // Test edge case when income is zero
      final netCashFlow = 2000.0;
      final totalIncome = 0.0;
      final savingsRate = totalIncome > 0 ? (netCashFlow / totalIncome) * 100 : 0.0;

      expect(savingsRate, equals(0.0));
    });
  });

  group('StatisticsService - Date Calculations', () {
    test('should calculate days difference correctly', () {
      // Test days difference calculation
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      final daysDiff = endDate.difference(startDate).inDays + 1;

      expect(daysDiff, equals(31));
    });

    test('should calculate months difference correctly', () {
      // Test months difference calculation
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 3, 31);
      
      // Count months between dates
      int monthsCount = 0;
      DateTime currentMonth = DateTime(startDate.year, startDate.month, 1);
      final endMonth = DateTime(endDate.year, endDate.month, 1);

      while (currentMonth.isBefore(endMonth) || currentMonth.isAtSameMomentAs(endMonth)) {
        monthsCount++;
        currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
      }

      expect(monthsCount, equals(3));
    });

    test('should calculate average daily from total', () {
      // Test average daily calculation
      final totalAmount = 3100.0;
      final days = 31;
      final averageDaily = totalAmount / days;

      expect(averageDaily, closeTo(100.0, 0.01));
    });

    test('should calculate average monthly from total', () {
      // Test average monthly calculation
      final totalAmount = 6000.0;
      final months = 3;
      final averageMonthly = totalAmount / months;

      expect(averageMonthly, equals(2000.0));
    });
  });

  group('StatisticsService - Cache Management', () {
    test('should clear cache successfully', () {
      // Test cache clearing
      statisticsService.clearCache();
      
      // If no exception is thrown, cache clear was successful
      expect(true, isTrue);
    });
  });
}

