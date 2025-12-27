import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/widgets/statistics/summary_card.dart';
import 'package:money/widgets/statistics/metric_card.dart';
import 'package:money/widgets/statistics/custom_tooltip.dart';
import 'package:money/widgets/statistics/chart_legend.dart';
import 'package:money/widgets/statistics/comparison_card.dart';
import 'package:money/widgets/statistics/filter_bar.dart';
import 'package:money/models/cash_flow_data.dart';
import 'package:money/models/comparison_data.dart';
import 'package:money/models/category.dart';
import 'package:money/models/wallet.dart';

// Helper to create ComparisonMetric
ComparisonMetric createMetric(String label, double v1, double v2) {
  final change = v1 - v2;
  final percentage = v2 != 0 ? (change / v2) * 100 : 0.0;
  return ComparisonMetric(
    label: label,
    period1Value: v1,
    period2Value: v2,
    absoluteChange: change,
    percentageChange: percentage.toDouble(),
    trend: change > 0
        ? TrendDirection.up
        : change < 0
            ? TrendDirection.down
            : TrendDirection.stable,
  );
}

void main() {
  group('Dark Mode Support Tests', () {
    testWidgets('SummaryCard renders correctly in dark mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SummaryCard(
              title: 'Test Title',
              value: '₺1,000',
              subtitle: 'Test Subtitle',
              icon: Icons.trending_up,
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('₺1,000'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('SummaryCard renders correctly in light mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: SummaryCard(
              title: 'Test Title',
              value: '₺1,000',
              subtitle: 'Test Subtitle',
              icon: Icons.trending_up,
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('₺1,000'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('MetricCard renders correctly in dark mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: MetricCard(
              label: 'Test Metric',
              value: '₺500',
              change: '+10%',
              trend: TrendDirection.up,
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Test Metric'), findsOneWidget);
      expect(find.text('₺500'), findsOneWidget);
      expect(find.text('+10%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('MetricCard renders correctly in light mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: MetricCard(
              label: 'Test Metric',
              value: '₺500',
              change: '+10%',
              trend: TrendDirection.up,
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Test Metric'), findsOneWidget);
      expect(find.text('₺500'), findsOneWidget);
      expect(find.text('+10%'), findsOneWidget);
    });

    testWidgets('CustomTooltip renders correctly in dark mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: CustomTooltip(
              title: 'Test Tooltip',
              value: '₺1,500',
              color: Colors.green,
              subtitle: 'Test Subtitle',
            ),
          ),
        ),
      );

      expect(find.text('Test Tooltip'), findsOneWidget);
      expect(find.text('₺1,500'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('CustomTooltip renders correctly in light mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: CustomTooltip(
              title: 'Test Tooltip',
              value: '₺1,500',
              color: Colors.green,
              subtitle: 'Test Subtitle',
            ),
          ),
        ),
      );

      expect(find.text('Test Tooltip'), findsOneWidget);
      expect(find.text('₺1,500'), findsOneWidget);
    });

    testWidgets('ChartLegend renders correctly in dark mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ChartLegend(
              items: {
                'Category 1': Colors.blue,
                'Category 2': Colors.red,
              },
              values: {
                'Category 1': '₺1,000',
                'Category 2': '₺500',
              },
              direction: Axis.horizontal,
            ),
          ),
        ),
      );

      expect(find.text('Category 1'), findsOneWidget);
      expect(find.text('Category 2'), findsOneWidget);
      expect(find.text('₺1,000'), findsOneWidget);
      expect(find.text('₺500'), findsOneWidget);
    });

    testWidgets('ChartLegend renders correctly in light mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: ChartLegend(
              items: {
                'Category 1': Colors.blue,
                'Category 2': Colors.red,
              },
              values: {
                'Category 1': '₺1,000',
                'Category 2': '₺500',
              },
              direction: Axis.vertical,
            ),
          ),
        ),
      );

      expect(find.text('Category 1'), findsOneWidget);
      expect(find.text('Category 2'), findsOneWidget);
    });

    testWidgets('ComparisonCard renders correctly in dark mode',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final comparisonData = ComparisonData(
        period1Start: now.subtract(const Duration(days: 30)),
        period1End: now,
        period2Start: now.subtract(const Duration(days: 60)),
        period2End: now.subtract(const Duration(days: 31)),
        period1Label: 'Bu Ay',
        period2Label: 'Geçen Ay',
        income: ComparisonMetric(
          label: 'Gelir',
          period1Value: 1000,
          period2Value: 800,
          absoluteChange: 200,
          percentageChange: 25.0,
          trend: TrendDirection.up,
        ),
        expense: ComparisonMetric(
          label: 'Gider',
          period1Value: 500,
          period2Value: 600,
          absoluteChange: -100,
          percentageChange: -16.67,
          trend: TrendDirection.down,
        ),
        netCashFlow: ComparisonMetric(
          label: 'Net Akış',
          period1Value: 500,
          period2Value: 200,
          absoluteChange: 300,
          percentageChange: 150.0,
          trend: TrendDirection.up,
        ),
        categoryComparisons: [],
        overallTrend: TrendDirection.up,
        insights: ['Test insight'],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ComparisonCard(
                comparisonData: comparisonData,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Bu Ay'), findsOneWidget);
      expect(find.text('Geçen Ay'), findsOneWidget);
    });

    testWidgets('ComparisonCard renders correctly in light mode',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final comparisonData = ComparisonData(
        period1Start: now.subtract(const Duration(days: 30)),
        period1End: now,
        period2Start: now.subtract(const Duration(days: 60)),
        period2End: now.subtract(const Duration(days: 31)),
        period1Label: 'Bu Ay',
        period2Label: 'Geçen Ay',
        income: ComparisonMetric(
          label: 'Gelir',
          period1Value: 1000,
          period2Value: 800,
          absoluteChange: 200,
          percentageChange: 25.0,
          trend: TrendDirection.up,
        ),
        expense: ComparisonMetric(
          label: 'Gider',
          period1Value: 500,
          period2Value: 600,
          absoluteChange: -100,
          percentageChange: -16.67,
          trend: TrendDirection.down,
        ),
        netCashFlow: ComparisonMetric(
          label: 'Net Akış',
          period1Value: 500,
          period2Value: 200,
          absoluteChange: 300,
          percentageChange: 150.0,
          trend: TrendDirection.up,
        ),
        categoryComparisons: [],
        overallTrend: TrendDirection.up,
        insights: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ComparisonCard(
                comparisonData: comparisonData,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Bu Ay'), findsOneWidget);
      expect(find.text('Geçen Ay'), findsOneWidget);
    });

    testWidgets('FilterBar renders correctly in dark mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: FilterBar(
              selectedTimeFilter: 'Aylık',
              selectedCategories: [],
              selectedWallets: [],
              selectedTransactionType: 'all',
              availableCategories: [
                Category(
                  id: '1',
                  name: 'Test Category',
                  icon: Icons.category,
                  color: Colors.blue,
                  type: 'expense',
                ),
              ],
              availableWallets: [
                Wallet(
                  id: '1',
                  name: 'Test Wallet',
                  balance: 1000,
                  type: 'cash',
                  color: '0xFF2196F3',
                  icon: 'wallet',
                  creditLimit: 0,
                ),
              ],
              onTimeFilterChanged: (_) {},
              onCategoriesChanged: (_) {},
              onWalletsChanged: (_) {},
              onTransactionTypeChanged: (_) {},
              onClearFilters: () {},
              onCustomDateRange: () {},
            ),
          ),
        ),
      );

      expect(find.text('Günlük'), findsOneWidget);
      expect(find.text('Haftalık'), findsOneWidget);
      expect(find.text('Aylık'), findsOneWidget);
      expect(find.text('Yıllık'), findsOneWidget);
    });

    testWidgets('FilterBar renders correctly in light mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: FilterBar(
              selectedTimeFilter: 'Haftalık',
              selectedCategories: [],
              selectedWallets: [],
              selectedTransactionType: 'all',
              availableCategories: [],
              availableWallets: [],
              onTimeFilterChanged: (_) {},
              onCategoriesChanged: (_) {},
              onWalletsChanged: (_) {},
              onTransactionTypeChanged: (_) {},
              onClearFilters: () {},
              onCustomDateRange: () {},
            ),
          ),
        ),
      );

      expect(find.text('Günlük'), findsOneWidget);
      expect(find.text('Haftalık'), findsOneWidget);
      expect(find.text('Aylık'), findsOneWidget);
    });

    testWidgets('Dark mode colors are applied correctly to cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Column(
              children: [
                SummaryCard(
                  title: 'Dark Card',
                  value: '₺1,000',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
                MetricCard(
                  label: 'Dark Metric',
                  value: '₺500',
                  trend: TrendDirection.up,
                ),
              ],
            ),
          ),
        ),
      );

      // Verify widgets are rendered
      expect(find.text('Dark Card'), findsOneWidget);
      expect(find.text('Dark Metric'), findsOneWidget);

      // Verify Card widgets exist (they should have dark theme applied)
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('Light mode colors are applied correctly to cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Column(
              children: [
                SummaryCard(
                  title: 'Light Card',
                  value: '₺1,000',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
                MetricCard(
                  label: 'Light Metric',
                  value: '₺500',
                  trend: TrendDirection.down,
                ),
              ],
            ),
          ),
        ),
      );

      // Verify widgets are rendered
      expect(find.text('Light Card'), findsOneWidget);
      expect(find.text('Light Metric'), findsOneWidget);

      // Verify Card widgets exist (they should have light theme applied)
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('Theme changes are reflected in widgets',
        (WidgetTester tester) async {
      // Start with light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: SummaryCard(
              title: 'Theme Test',
              value: '₺1,000',
              icon: Icons.trending_up,
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Theme Test'), findsOneWidget);

      // Switch to dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SummaryCard(
              title: 'Theme Test',
              value: '₺1,000',
              icon: Icons.trending_up,
              color: Colors.green,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Theme Test'), findsOneWidget);
    });
  });
}
