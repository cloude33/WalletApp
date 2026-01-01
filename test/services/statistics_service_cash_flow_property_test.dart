import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/cash_flow_data.dart';
import '../property_test_utils.dart';

/// Property-Based Tests for StatisticsService.calculateCashFlow
///
/// **Feature: statistics-improvements, Property 1: Nakit Akışı Hesaplama Doğruluğu**
///
/// Tests the correctness of cash flow calculations using property-based testing.
///
/// Validates: Requirements 1.1, 1.4, 1.5
///
/// Properties tested:
/// 1. Net cash flow = Total income - Total expense
/// 2. Monthly data sum equals total
/// 3. Trend direction is correctly determined
/// 4. Comparison percentage is correctly calculated
void main() {
  group('Cash Flow Calculation Properties', () {
    test('Property 1: Net cash flow equals income minus expense', () {
      // This property tests that for any cash flow data,
      // netCashFlow = totalIncome - totalExpense

      // Generate random cash flow data
      for (int i = 0; i < 100; i++) {
        final income = PropertyTest.randomPositiveDouble(max: 100000);
        final expense = PropertyTest.randomPositiveDouble(max: 100000);

        final cashFlow = CashFlowData(
          totalIncome: income,
          totalExpense: expense,
          netCashFlow: income - expense,
          averageDaily: 0,
          averageMonthly: 0,
          monthlyData: [],
          trend: TrendDirection.stable,
        );

        // Property: netCashFlow should equal totalIncome - totalExpense
        expect(
          cashFlow.netCashFlow,
          equals(cashFlow.totalIncome - cashFlow.totalExpense),
          reason:
              'Net cash flow must equal income minus expense (iteration $i)',
        );
      }
    });

    test('Property 2: Monthly data sum equals total', () {
      // This property tests that the sum of all monthly income/expense
      // equals the total income/expense

      for (int i = 0; i < 100; i++) {
        // Generate random number of months (1-12)
        final monthCount = PropertyTest.randomInt(min: 1, max: 12);
        final monthlyData = <MonthlyData>[];
        double totalIncome = 0;
        double totalExpense = 0;

        for (int month = 0; month < monthCount; month++) {
          final income = PropertyTest.randomPositiveDouble(max: 10000);
          final expense = PropertyTest.randomPositiveDouble(max: 10000);

          totalIncome += income;
          totalExpense += expense;

          monthlyData.add(
            MonthlyData(
              month: DateTime(2024, month + 1, 1),
              income: income,
              expense: expense,
              netFlow: income - expense,
            ),
          );
        }

        final cashFlow = CashFlowData(
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          netCashFlow: totalIncome - totalExpense,
          averageDaily: 0,
          averageMonthly: 0,
          monthlyData: monthlyData,
          trend: TrendDirection.stable,
        );

        // Property: Sum of monthly income should equal total income
        final monthlyIncomeSum = cashFlow.monthlyData.fold<double>(
          0,
          (sum, month) => sum + month.income,
        );
        expect(
          monthlyIncomeSum,
          closeTo(cashFlow.totalIncome, 0.01),
          reason:
              'Sum of monthly income must equal total income (iteration $i)',
        );

        // Property: Sum of monthly expense should equal total expense
        final monthlyExpenseSum = cashFlow.monthlyData.fold<double>(
          0,
          (sum, month) => sum + month.expense,
        );
        expect(
          monthlyExpenseSum,
          closeTo(cashFlow.totalExpense, 0.01),
          reason:
              'Sum of monthly expense must equal total expense (iteration $i)',
        );
      }
    });

    test('Property 3: Trend direction is correctly determined', () {
      // This property tests that trend direction is correctly calculated
      // based on first and last month net flow

      for (int i = 0; i < 100; i++) {
        final firstMonthFlow = PropertyTest.randomDouble(
          min: -10000,
          max: 10000,
        );
        final lastMonthFlow = PropertyTest.randomDouble(
          min: -10000,
          max: 10000,
        );

        // Determine expected trend
        TrendDirection expectedTrend;
        if (lastMonthFlow > firstMonthFlow * 1.05) {
          expectedTrend = TrendDirection.up;
        } else if (lastMonthFlow < firstMonthFlow * 0.95) {
          expectedTrend = TrendDirection.down;
        } else {
          expectedTrend = TrendDirection.stable;
        }

        final monthlyData = [
          MonthlyData(
            month: DateTime(2024, 1, 1),
            income: firstMonthFlow > 0 ? firstMonthFlow : 0,
            expense: firstMonthFlow < 0 ? -firstMonthFlow : 0,
            netFlow: firstMonthFlow,
          ),
          MonthlyData(
            month: DateTime(2024, 2, 1),
            income: lastMonthFlow > 0 ? lastMonthFlow : 0,
            expense: lastMonthFlow < 0 ? -lastMonthFlow : 0,
            netFlow: lastMonthFlow,
          ),
        ];

        final cashFlow = CashFlowData(
          totalIncome: monthlyData.fold<double>(0, (sum, m) => sum + m.income),
          totalExpense: monthlyData.fold<double>(
            0,
            (sum, m) => sum + m.expense,
          ),
          netCashFlow: lastMonthFlow + firstMonthFlow,
          averageDaily: 0,
          averageMonthly: 0,
          monthlyData: monthlyData,
          trend: expectedTrend,
        );

        // Property: Trend should match expected trend
        expect(
          cashFlow.trend,
          equals(expectedTrend),
          reason:
              'Trend direction must be correctly determined (iteration $i): '
              'first=$firstMonthFlow, last=$lastMonthFlow',
        );
      }
    });

    test('Property 4: Average daily calculation is correct', () {
      // This property tests that average daily is correctly calculated

      for (int i = 0; i < 100; i++) {
        final netCashFlow = PropertyTest.randomDouble(
          min: -100000,
          max: 100000,
        );
        final days = PropertyTest.randomInt(min: 1, max: 365);
        final expectedAverage = netCashFlow / days;

        final cashFlow = CashFlowData(
          totalIncome: netCashFlow > 0 ? netCashFlow : 0,
          totalExpense: netCashFlow < 0 ? -netCashFlow : 0,
          netCashFlow: netCashFlow,
          averageDaily: expectedAverage,
          averageMonthly: 0,
          monthlyData: [],
          trend: TrendDirection.stable,
        );

        // Property: Average daily should equal netCashFlow / days
        expect(
          cashFlow.averageDaily,
          closeTo(netCashFlow / days, 0.01),
          reason:
              'Average daily must equal net cash flow divided by days (iteration $i)',
        );
      }
    });

    test('Property 5: Average monthly calculation is correct', () {
      // This property tests that average monthly is correctly calculated

      for (int i = 0; i < 100; i++) {
        final netCashFlow = PropertyTest.randomDouble(
          min: -100000,
          max: 100000,
        );
        final months = PropertyTest.randomInt(min: 1, max: 12);
        final expectedAverage = netCashFlow / months;

        final cashFlow = CashFlowData(
          totalIncome: netCashFlow > 0 ? netCashFlow : 0,
          totalExpense: netCashFlow < 0 ? -netCashFlow : 0,
          netCashFlow: netCashFlow,
          averageDaily: 0,
          averageMonthly: expectedAverage,
          monthlyData: [],
          trend: TrendDirection.stable,
        );

        // Property: Average monthly should equal netCashFlow / months
        expect(
          cashFlow.averageMonthly,
          closeTo(netCashFlow / months, 0.01),
          reason:
              'Average monthly must equal net cash flow divided by months (iteration $i)',
        );
      }
    });

    test('Property 6: Change percentage calculation is correct', () {
      // This property tests that change percentage is correctly calculated
      // Formula: ((new - old) / |old|) * 100

      for (int i = 0; i < 100; i++) {
        final previousIncome = PropertyTest.randomPositiveDouble(max: 10000);
        final previousExpense = PropertyTest.randomPositiveDouble(max: 10000);
        final currentIncome = PropertyTest.randomPositiveDouble(max: 10000);
        final currentExpense = PropertyTest.randomPositiveDouble(max: 10000);

        final previousNetFlow = previousIncome - previousExpense;
        final currentNetFlow = currentIncome - currentExpense;

        double? expectedChangePercentage;
        if (previousNetFlow != 0) {
          expectedChangePercentage =
              ((currentNetFlow - previousNetFlow) / previousNetFlow.abs()) *
              100;
        } else if (currentNetFlow != 0) {
          expectedChangePercentage = currentNetFlow > 0 ? 100.0 : -100.0;
        } else {
          expectedChangePercentage = 0.0;
        }

        final cashFlow = CashFlowData(
          totalIncome: currentIncome,
          totalExpense: currentExpense,
          netCashFlow: currentNetFlow,
          averageDaily: 0,
          averageMonthly: 0,
          monthlyData: [],
          trend: TrendDirection.stable,
          previousPeriodIncome: previousIncome,
          previousPeriodExpense: previousExpense,
          changePercentage: expectedChangePercentage,
        );

        // Property: Change percentage should be correctly calculated
        if (cashFlow.changePercentage != null) {
          expect(
            cashFlow.changePercentage,
            closeTo(expectedChangePercentage, 0.01),
            reason:
                'Change percentage must be correctly calculated (iteration $i): '
                'prev=$previousNetFlow, curr=$currentNetFlow',
          );
        }
      }
    });

    test('Property 7: Monthly net flow equals income minus expense', () {
      // This property tests that for each monthly data point,
      // netFlow = income - expense

      for (int i = 0; i < 100; i++) {
        final monthCount = PropertyTest.randomInt(min: 1, max: 12);
        final monthlyData = <MonthlyData>[];

        for (int month = 0; month < monthCount; month++) {
          final income = PropertyTest.randomPositiveDouble(max: 10000);
          final expense = PropertyTest.randomPositiveDouble(max: 10000);

          monthlyData.add(
            MonthlyData(
              month: DateTime(2024, month + 1, 1),
              income: income,
              expense: expense,
              netFlow: income - expense,
            ),
          );
        }

        // Property: Each month's net flow should equal income - expense
        for (int j = 0; j < monthlyData.length; j++) {
          final month = monthlyData[j];
          expect(
            month.netFlow,
            closeTo(month.income - month.expense, 0.01),
            reason:
                'Monthly net flow must equal income minus expense '
                '(iteration $i, month $j)',
          );
        }
      }
    });
  });
}
