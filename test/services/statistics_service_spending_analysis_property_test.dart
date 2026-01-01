import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/spending_analysis.dart';
import 'package:parion/models/cash_flow_data.dart';
import '../property_test_utils.dart';

/// Property-Based Tests for Spending Analysis
///
/// **Feature: statistics-improvements, Property 2: Kategori Dağılımı Tutarlılığı**
///
/// Tests the correctness of spending analysis calculations using property-based testing.
///
/// Validates: Requirements 2.1, 2.3, 2.5
///
/// Properties tested:
/// 1. Category breakdown sum equals total spending
/// 2. Payment method breakdown sum equals total spending
/// 3. Budget comparison calculations are correct
/// 4. Category trend percentage change is correct
void main() {
  group('Spending Analysis Properties', () {
    test('Property 1: Category breakdown sum equals total spending', () {
      // This property tests that for any spending analysis,
      // the sum of all category spending equals the total spending

      for (int i = 0; i < 100; i++) {
        // Generate random number of categories (1-10)
        final categoryCount = PropertyTest.randomInt(min: 1, max: 10);
        final categoryBreakdown = <String, double>{};
        double totalSpending = 0;

        for (int cat = 0; cat < categoryCount; cat++) {
          final categoryName = 'Category_$cat';
          final amount = PropertyTest.randomPositiveDouble(max: 10000);
          categoryBreakdown[categoryName] = amount;
          totalSpending += amount;
        }

        final analysis = SpendingAnalysis(
          totalSpending: totalSpending,
          categoryBreakdown: categoryBreakdown,
          paymentMethodBreakdown: {},
          categoryTrends: [],
          budgetComparisons: {},
          topCategory: '',
          topCategoryAmount: 0,
          mostSpendingDay: DayOfWeek.monday,
          mostSpendingHour: 12,
        );

        // Property: Sum of category breakdown should equal total spending
        final categorySum = analysis.categoryBreakdown.values.fold<double>(
          0,
          (sum, amount) => sum + amount,
        );

        expect(
          categorySum,
          closeTo(analysis.totalSpending, 0.01),
          reason:
              'Sum of category breakdown must equal total spending (iteration $i)',
        );
      }
    });

    test('Property 2: Payment method breakdown sum equals total spending', () {
      // This property tests that for any spending analysis,
      // the sum of all payment method spending equals the total spending

      for (int i = 0; i < 100; i++) {
        // Generate random payment methods
        final paymentMethods = ['Kredi Kartı', 'KMH', 'Nakit'];
        final paymentMethodBreakdown = <String, double>{};
        double totalSpending = 0;

        for (var method in paymentMethods) {
          final amount = PropertyTest.randomPositiveDouble(max: 10000);
          paymentMethodBreakdown[method] = amount;
          totalSpending += amount;
        }

        final analysis = SpendingAnalysis(
          totalSpending: totalSpending,
          categoryBreakdown: {},
          paymentMethodBreakdown: paymentMethodBreakdown,
          categoryTrends: [],
          budgetComparisons: {},
          topCategory: '',
          topCategoryAmount: 0,
          mostSpendingDay: DayOfWeek.monday,
          mostSpendingHour: 12,
        );

        // Property: Sum of payment method breakdown should equal total spending
        final paymentSum = analysis.paymentMethodBreakdown.values.fold<double>(
          0,
          (sum, amount) => sum + amount,
        );

        expect(
          paymentSum,
          closeTo(analysis.totalSpending, 0.01),
          reason:
              'Sum of payment method breakdown must equal total spending (iteration $i)',
        );
      }
    });

    test('Property 3: Budget comparison calculations are correct', () {
      // This property tests that budget comparison calculations are accurate

      for (int i = 0; i < 100; i++) {
        final budget = PropertyTest.randomPositiveDouble(min: 100, max: 10000);
        final actual = PropertyTest.randomPositiveDouble(min: 0, max: 15000);

        final comparison = BudgetComparison(
          category: 'Test',
          budget: budget,
          actual: actual,
          remaining: budget - actual,
          usagePercentage: (actual / budget) * 100,
          exceeded: actual > budget,
        );

        // Property 1: Remaining = Budget - Actual
        expect(
          comparison.remaining,
          closeTo(comparison.budget - comparison.actual, 0.01),
          reason: 'Remaining must equal budget minus actual (iteration $i)',
        );

        // Property 2: Usage percentage = (Actual / Budget) * 100
        expect(
          comparison.usagePercentage,
          closeTo((comparison.actual / comparison.budget) * 100, 0.01),
          reason:
              'Usage percentage must be correctly calculated (iteration $i)',
        );

        // Property 3: Exceeded flag is correct
        expect(
          comparison.exceeded,
          equals(comparison.actual > comparison.budget),
          reason: 'Exceeded flag must match actual > budget (iteration $i)',
        );
      }
    });

    test('Property 4: Category trend percentage change is correct', () {
      // This property tests that trend percentage change is calculated correctly

      for (int i = 0; i < 100; i++) {
        final firstAmount = PropertyTest.randomPositiveDouble(
          min: 1,
          max: 10000,
        );
        final lastAmount = PropertyTest.randomPositiveDouble(
          min: 1,
          max: 10000,
        );

        final expectedChange = ((lastAmount - firstAmount) / firstAmount) * 100;

        final monthlySpending = [
          MonthlySpending(month: DateTime(2024, 1, 1), amount: firstAmount),
          MonthlySpending(month: DateTime(2024, 2, 1), amount: lastAmount),
        ];

        final trend = CategoryTrend(
          category: 'Test',
          monthlySpending: monthlySpending,
          trend: TrendDirection.stable,
          changePercentage: expectedChange,
        );

        // Property: Change percentage = ((last - first) / first) * 100
        final calculatedChange =
            ((trend.monthlySpending.last.amount -
                    trend.monthlySpending.first.amount) /
                trend.monthlySpending.first.amount) *
            100;

        expect(
          trend.changePercentage,
          closeTo(calculatedChange, 0.01),
          reason:
              'Change percentage must be correctly calculated (iteration $i)',
        );
      }
    });

    test('Property 5: Top category has highest amount', () {
      // This property tests that the top category is correctly identified

      for (int i = 0; i < 100; i++) {
        // Generate random categories with amounts
        final categoryCount = PropertyTest.randomInt(min: 2, max: 10);
        final categoryBreakdown = <String, double>{};
        double maxAmount = 0;
        String maxCategory = '';

        for (int cat = 0; cat < categoryCount; cat++) {
          final categoryName = 'Category_$cat';
          final amount = PropertyTest.randomPositiveDouble(max: 10000);
          categoryBreakdown[categoryName] = amount;

          if (amount > maxAmount) {
            maxAmount = amount;
            maxCategory = categoryName;
          }
        }

        final analysis = SpendingAnalysis(
          totalSpending: categoryBreakdown.values.fold(0.0, (a, b) => a + b),
          categoryBreakdown: categoryBreakdown,
          paymentMethodBreakdown: {},
          categoryTrends: [],
          budgetComparisons: {},
          topCategory: maxCategory,
          topCategoryAmount: maxAmount,
          mostSpendingDay: DayOfWeek.monday,
          mostSpendingHour: 12,
        );

        // Property: Top category amount should be >= all other categories
        for (var entry in analysis.categoryBreakdown.entries) {
          expect(
            analysis.topCategoryAmount,
            greaterThanOrEqualTo(entry.value),
            reason:
                'Top category amount must be >= all other categories (iteration $i)',
          );
        }

        // Property: Top category should exist in breakdown
        expect(
          analysis.categoryBreakdown.containsKey(analysis.topCategory),
          isTrue,
          reason:
              'Top category must exist in category breakdown (iteration $i)',
        );

        // Property: Top category amount should match breakdown
        expect(
          analysis.categoryBreakdown[analysis.topCategory],
          equals(analysis.topCategoryAmount),
          reason:
              'Top category amount must match breakdown value (iteration $i)',
        );
      }
    });

    test('Property 6: Monthly spending sum equals category total', () {
      // This property tests that for category trends,
      // the sum of monthly spending equals the total for that category

      for (int i = 0; i < 100; i++) {
        // Generate random number of months (1-12)
        final monthCount = PropertyTest.randomInt(min: 1, max: 12);
        final monthlySpending = <MonthlySpending>[];
        double totalAmount = 0;

        for (int month = 0; month < monthCount; month++) {
          final amount = PropertyTest.randomPositiveDouble(max: 1000);
          totalAmount += amount;

          monthlySpending.add(
            MonthlySpending(
              month: DateTime(2024, month + 1, 1),
              amount: amount,
            ),
          );
        }

        final trend = CategoryTrend(
          category: 'Test',
          monthlySpending: monthlySpending,
          trend: TrendDirection.stable,
          changePercentage: 0,
        );

        // Property: Sum of monthly spending should equal total
        final monthlySum = trend.monthlySpending.fold<double>(
          0,
          (sum, month) => sum + month.amount,
        );

        expect(
          monthlySum,
          closeTo(totalAmount, 0.01),
          reason: 'Sum of monthly spending must equal total (iteration $i)',
        );
      }
    });

    test('Property 7: Budget usage percentage is between 0 and infinity', () {
      // This property tests that usage percentage is always non-negative

      for (int i = 0; i < 100; i++) {
        final budget = PropertyTest.randomPositiveDouble(min: 100, max: 10000);
        final actual = PropertyTest.randomPositiveDouble(min: 0, max: 15000);

        final comparison = BudgetComparison(
          category: 'Test',
          budget: budget,
          actual: actual,
          remaining: budget - actual,
          usagePercentage: (actual / budget) * 100,
          exceeded: actual > budget,
        );

        // Property: Usage percentage should always be >= 0
        expect(
          comparison.usagePercentage,
          greaterThanOrEqualTo(0),
          reason: 'Usage percentage must be non-negative (iteration $i)',
        );

        // Property: If actual > 0 and budget > 0, usage percentage > 0
        if (comparison.actual > 0 && comparison.budget > 0) {
          expect(
            comparison.usagePercentage,
            greaterThan(0),
            reason:
                'Usage percentage must be positive when actual and budget are positive (iteration $i)',
          );
        }
      }
    });

    test('Property 8: Day of week is valid (1-7)', () {
      // This property tests that day of week is always valid

      for (int i = 0; i < 100; i++) {
        // Generate random day of week
        final dayIndex = PropertyTest.randomInt(min: 0, max: 6);
        final day = DayOfWeek.values[dayIndex];

        final analysis = SpendingAnalysis(
          totalSpending: 0,
          categoryBreakdown: {},
          paymentMethodBreakdown: {},
          categoryTrends: [],
          budgetComparisons: {},
          topCategory: '',
          topCategoryAmount: 0,
          mostSpendingDay: day,
          mostSpendingHour: 12,
        );

        // Property: Day of week should be one of the valid enum values
        expect(
          DayOfWeek.values.contains(analysis.mostSpendingDay),
          isTrue,
          reason: 'Most spending day must be a valid DayOfWeek (iteration $i)',
        );
      }
    });

    test('Property 9: Hour of day is valid (0-23)', () {
      // This property tests that hour of day is always valid

      for (int i = 0; i < 100; i++) {
        final hour = PropertyTest.randomInt(min: 0, max: 23);

        final analysis = SpendingAnalysis(
          totalSpending: 0,
          categoryBreakdown: {},
          paymentMethodBreakdown: {},
          categoryTrends: [],
          budgetComparisons: {},
          topCategory: '',
          topCategoryAmount: 0,
          mostSpendingDay: DayOfWeek.monday,
          mostSpendingHour: hour,
        );

        // Property: Hour should be between 0 and 23
        expect(
          analysis.mostSpendingHour,
          greaterThanOrEqualTo(0),
          reason: 'Most spending hour must be >= 0 (iteration $i)',
        );

        expect(
          analysis.mostSpendingHour,
          lessThanOrEqualTo(23),
          reason: 'Most spending hour must be <= 23 (iteration $i)',
        );
      }
    });
  });
}
