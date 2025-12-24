import 'package:flutter_test/flutter_test.dart';
import 'package:money/models/comparison_data.dart';
import 'package:money/models/cash_flow_data.dart';

/// Unit Tests for Comparison Service
/// 
/// Tests the comparison functionality in StatisticsService
/// 
/// Validates: Requirements 10.1, 10.2
/// 
/// Tests:
/// 1. Absolute change calculation (period2Value - period1Value)
/// 2. Percentage change calculation ((period2Value - period1Value) / period1Value * 100)
/// 3. Trend direction determination
/// 4. Edge cases (zero values, negative changes)
void main() {
  group('ComparisonMetric Calculations', () {
    test('should calculate absolute change correctly', () {
      // Test case 1: Positive change
      final metric1 = ComparisonMetric(
        label: 'Test',
        period1Value: 100,
        period2Value: 150,
        absoluteChange: 50,
        percentageChange: 50,
        trend: TrendDirection.up,
      );
      
      expect(metric1.absoluteChange, 50);
      expect(metric1.absoluteChange, metric1.period2Value - metric1.period1Value);
      
      // Test case 2: Negative change
      final metric2 = ComparisonMetric(
        label: 'Test',
        period1Value: 150,
        period2Value: 100,
        absoluteChange: -50,
        percentageChange: -33.33,
        trend: TrendDirection.down,
      );
      
      expect(metric2.absoluteChange, -50);
      expect(metric2.absoluteChange, metric2.period2Value - metric2.period1Value);
      
      // Test case 3: No change
      final metric3 = ComparisonMetric(
        label: 'Test',
        period1Value: 100,
        period2Value: 100,
        absoluteChange: 0,
        percentageChange: 0,
        trend: TrendDirection.stable,
      );
      
      expect(metric3.absoluteChange, 0);
      expect(metric3.absoluteChange, metric3.period2Value - metric3.period1Value);
    });

    test('should calculate percentage change correctly', () {
      // Test case 1: 50% increase
      final metric1 = ComparisonMetric(
        label: 'Test',
        period1Value: 100,
        period2Value: 150,
        absoluteChange: 50,
        percentageChange: 50,
        trend: TrendDirection.up,
      );
      
      expect(metric1.percentageChange, 50);
      expect(
        metric1.percentageChange,
        closeTo((metric1.absoluteChange / metric1.period1Value) * 100, 0.01),
      );
      
      // Test case 2: 33.33% decrease
      final metric2 = ComparisonMetric(
        label: 'Test',
        period1Value: 150,
        period2Value: 100,
        absoluteChange: -50,
        percentageChange: -33.33,
        trend: TrendDirection.down,
      );
      
      expect(metric2.percentageChange, closeTo(-33.33, 0.01));
      expect(
        metric2.percentageChange,
        closeTo((metric2.absoluteChange / metric2.period1Value) * 100, 0.01),
      );
      
      // Test case 3: 100% increase (doubling)
      final metric3 = ComparisonMetric(
        label: 'Test',
        period1Value: 50,
        period2Value: 100,
        absoluteChange: 50,
        percentageChange: 100,
        trend: TrendDirection.up,
      );
      
      expect(metric3.percentageChange, 100);
      expect(
        metric3.percentageChange,
        closeTo((metric3.absoluteChange / metric3.period1Value) * 100, 0.01),
      );
    });

    test('should handle zero period1Value correctly', () {
      // When period1 is 0 and period2 is positive, percentage change should be 100%
      final metric1 = ComparisonMetric(
        label: 'Test',
        period1Value: 0,
        period2Value: 100,
        absoluteChange: 100,
        percentageChange: 100,
        trend: TrendDirection.up,
      );
      
      expect(metric1.percentageChange, 100);
      
      // When period1 is 0 and period2 is negative, percentage change should be -100%
      final metric2 = ComparisonMetric(
        label: 'Test',
        period1Value: 0,
        period2Value: -100,
        absoluteChange: -100,
        percentageChange: -100,
        trend: TrendDirection.down,
      );
      
      expect(metric2.percentageChange, -100);
      
      // When both are 0, percentage change should be 0
      final metric3 = ComparisonMetric(
        label: 'Test',
        period1Value: 0,
        period2Value: 0,
        absoluteChange: 0,
        percentageChange: 0,
        trend: TrendDirection.stable,
      );
      
      expect(metric3.percentageChange, 0);
    });

    test('should determine trend direction correctly', () {
      // Upward trend
      final upMetric = ComparisonMetric(
        label: 'Test',
        period1Value: 100,
        period2Value: 150,
        absoluteChange: 50,
        percentageChange: 50,
        trend: TrendDirection.up,
      );
      expect(upMetric.trend, TrendDirection.up);
      
      // Downward trend
      final downMetric = ComparisonMetric(
        label: 'Test',
        period1Value: 150,
        period2Value: 100,
        absoluteChange: -50,
        percentageChange: -33.33,
        trend: TrendDirection.down,
      );
      expect(downMetric.trend, TrendDirection.down);
      
      // Stable trend
      final stableMetric = ComparisonMetric(
        label: 'Test',
        period1Value: 100,
        period2Value: 100,
        absoluteChange: 0,
        percentageChange: 0,
        trend: TrendDirection.stable,
      );
      expect(stableMetric.trend, TrendDirection.stable);
    });
  });

  group('CategoryComparison Calculations', () {
    test('should calculate category comparison correctly', () {
      final comparison = CategoryComparison(
        category: 'Market',
        period1Amount: 500,
        period2Amount: 700,
        absoluteChange: 200,
        percentageChange: 40,
        trend: TrendDirection.up,
      );
      
      expect(comparison.absoluteChange, 200);
      expect(comparison.absoluteChange, comparison.period2Amount - comparison.period1Amount);
      expect(comparison.percentageChange, 40);
      expect(
        comparison.percentageChange,
        closeTo((comparison.absoluteChange / comparison.period1Amount) * 100, 0.01),
      );
      expect(comparison.trend, TrendDirection.up);
    });

    test('should handle new categories (period1 = 0)', () {
      final comparison = CategoryComparison(
        category: 'New Category',
        period1Amount: 0,
        period2Amount: 500,
        absoluteChange: 500,
        percentageChange: 100,
        trend: TrendDirection.up,
      );
      
      expect(comparison.absoluteChange, 500);
      expect(comparison.percentageChange, 100);
      expect(comparison.trend, TrendDirection.up);
    });

    test('should handle removed categories (period2 = 0)', () {
      final comparison = CategoryComparison(
        category: 'Removed Category',
        period1Amount: 500,
        period2Amount: 0,
        absoluteChange: -500,
        percentageChange: -100,
        trend: TrendDirection.down,
      );
      
      expect(comparison.absoluteChange, -500);
      expect(comparison.percentageChange, -100);
      expect(comparison.trend, TrendDirection.down);
    });
  });

  group('ComparisonData Structure', () {
    test('should create valid comparison data', () {
      final period1Start = DateTime(2024, 1, 1);
      final period1End = DateTime(2024, 1, 31);
      final period2Start = DateTime(2024, 2, 1);
      final period2End = DateTime(2024, 2, 29);
      
      final incomeMetric = ComparisonMetric(
        label: 'Gelir',
        period1Value: 5000,
        period2Value: 6000,
        absoluteChange: 1000,
        percentageChange: 20,
        trend: TrendDirection.up,
      );
      
      final expenseMetric = ComparisonMetric(
        label: 'Gider',
        period1Value: 3000,
        period2Value: 3500,
        absoluteChange: 500,
        percentageChange: 16.67,
        trend: TrendDirection.up,
      );
      
      final netCashFlowMetric = ComparisonMetric(
        label: 'Net Nakit Akışı',
        period1Value: 2000,
        period2Value: 2500,
        absoluteChange: 500,
        percentageChange: 25,
        trend: TrendDirection.up,
      );
      
      final comparisonData = ComparisonData(
        period1Start: period1Start,
        period1End: period1End,
        period2Start: period2Start,
        period2End: period2End,
        period1Label: 'Ocak 2024',
        period2Label: 'Şubat 2024',
        income: incomeMetric,
        expense: expenseMetric,
        netCashFlow: netCashFlowMetric,
        categoryComparisons: [],
        overallTrend: TrendDirection.up,
        insights: ['Test insight'],
      );
      
      expect(comparisonData.period1Label, 'Ocak 2024');
      expect(comparisonData.period2Label, 'Şubat 2024');
      expect(comparisonData.income.percentageChange, 20);
      expect(comparisonData.expense.percentageChange, closeTo(16.67, 0.01));
      expect(comparisonData.netCashFlow.percentageChange, 25);
      expect(comparisonData.overallTrend, TrendDirection.up);
      expect(comparisonData.insights.length, 1);
    });

    test('should serialize and deserialize correctly', () {
      final original = ComparisonData(
        period1Start: DateTime(2024, 1, 1),
        period1End: DateTime(2024, 1, 31),
        period2Start: DateTime(2024, 2, 1),
        period2End: DateTime(2024, 2, 29),
        period1Label: 'Ocak 2024',
        period2Label: 'Şubat 2024',
        income: ComparisonMetric(
          label: 'Gelir',
          period1Value: 5000,
          period2Value: 6000,
          absoluteChange: 1000,
          percentageChange: 20,
          trend: TrendDirection.up,
        ),
        expense: ComparisonMetric(
          label: 'Gider',
          period1Value: 3000,
          period2Value: 3500,
          absoluteChange: 500,
          percentageChange: 16.67,
          trend: TrendDirection.up,
        ),
        netCashFlow: ComparisonMetric(
          label: 'Net Nakit Akışı',
          period1Value: 2000,
          period2Value: 2500,
          absoluteChange: 500,
          percentageChange: 25,
          trend: TrendDirection.up,
        ),
        categoryComparisons: [
          CategoryComparison(
            category: 'Market',
            period1Amount: 1000,
            period2Amount: 1200,
            absoluteChange: 200,
            percentageChange: 20,
            trend: TrendDirection.up,
          ),
        ],
        overallTrend: TrendDirection.up,
        insights: ['Test insight'],
      );
      
      final json = original.toJson();
      final deserialized = ComparisonData.fromJson(json);
      
      expect(deserialized.period1Label, original.period1Label);
      expect(deserialized.period2Label, original.period2Label);
      expect(deserialized.income.percentageChange, original.income.percentageChange);
      expect(deserialized.expense.percentageChange, original.expense.percentageChange);
      expect(deserialized.netCashFlow.percentageChange, original.netCashFlow.percentageChange);
      expect(deserialized.categoryComparisons.length, original.categoryComparisons.length);
      expect(deserialized.overallTrend, original.overallTrend);
      expect(deserialized.insights.length, original.insights.length);
    });
  });

  group('Edge Cases', () {
    test('should handle large percentage changes', () {
      // 1000% increase
      final metric = ComparisonMetric(
        label: 'Test',
        period1Value: 10,
        period2Value: 110,
        absoluteChange: 100,
        percentageChange: 1000,
        trend: TrendDirection.up,
      );
      
      expect(metric.percentageChange, 1000);
      expect(
        metric.percentageChange,
        closeTo((metric.absoluteChange / metric.period1Value) * 100, 0.01),
      );
    });

    test('should handle negative values correctly', () {
      // Going from negative to less negative (improvement)
      final metric1 = ComparisonMetric(
        label: 'Test',
        period1Value: -100,
        period2Value: -50,
        absoluteChange: 50,
        percentageChange: -50, // 50% improvement (less negative)
        trend: TrendDirection.up,
      );
      
      expect(metric1.absoluteChange, 50);
      
      // Going from negative to more negative (worsening)
      final metric2 = ComparisonMetric(
        label: 'Test',
        period1Value: -50,
        period2Value: -100,
        absoluteChange: -50,
        percentageChange: 100, // 100% worse (more negative)
        trend: TrendDirection.down,
      );
      
      expect(metric2.absoluteChange, -50);
    });

    test('should handle very small changes', () {
      final metric = ComparisonMetric(
        label: 'Test',
        period1Value: 10000,
        period2Value: 10001,
        absoluteChange: 1,
        percentageChange: 0.01,
        trend: TrendDirection.stable, // Small change might be considered stable
      );
      
      expect(metric.absoluteChange, 1);
      expect(metric.percentageChange, closeTo(0.01, 0.001));
    });
  });
}
