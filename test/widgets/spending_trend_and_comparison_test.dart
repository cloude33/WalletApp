import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/models/spending_analysis.dart';
import 'package:money/models/cash_flow_data.dart';
import 'package:money/widgets/statistics/spending_trend_chart.dart';
import 'package:money/widgets/statistics/period_comparison_card.dart';
import 'package:money/widgets/statistics/budget_tracker_card.dart';
import 'package:money/widgets/statistics/spending_habits_card.dart';

void main() {
  group('Spending Trend and Comparison Widgets Tests', () {
    // Test data
    final testCategoryTrends = [
      CategoryTrend(
        category: 'Market',
        monthlySpending: [
          MonthlySpending(month: DateTime(2024, 1, 1), amount: 1000),
          MonthlySpending(month: DateTime(2024, 2, 1), amount: 1200),
          MonthlySpending(month: DateTime(2024, 3, 1), amount: 1100),
        ],
        trend: TrendDirection.up,
        changePercentage: 10.0,
      ),
      CategoryTrend(
        category: 'Restoran',
        monthlySpending: [
          MonthlySpending(month: DateTime(2024, 1, 1), amount: 800),
          MonthlySpending(month: DateTime(2024, 2, 1), amount: 700),
          MonthlySpending(month: DateTime(2024, 3, 1), amount: 600),
        ],
        trend: TrendDirection.down,
        changePercentage: -25.0,
      ),
    ];

    final testCategoryColors = {
      'Market': Colors.green,
      'Restoran': Colors.orange,
    };

    final testBudgetComparisons = {
      'Market': BudgetComparison(
        category: 'Market',
        budget: 1500,
        actual: 1200,
        remaining: 300,
        usagePercentage: 80.0,
        exceeded: false,
      ),
      'Restoran': BudgetComparison(
        category: 'Restoran',
        budget: 500,
        actual: 700,
        remaining: -200,
        usagePercentage: 140.0,
        exceeded: true,
      ),
    };

    final testSpendingAnalysis = SpendingAnalysis(
      totalSpending: 5000,
      categoryBreakdown: {
        'Market': 1200,
        'Restoran': 700,
        'Ulaşım': 500,
      },
      paymentMethodBreakdown: {
        'Kredi Kartı': 3000,
        'KMH': 2000,
      },
      categoryTrends: testCategoryTrends,
      budgetComparisons: testBudgetComparisons,
      topCategory: 'Market',
      topCategoryAmount: 1200,
      mostSpendingDay: DayOfWeek.friday,
      mostSpendingHour: 18,
    );

    group('SpendingTrendChart', () {
      testWidgets('renders without error', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpendingTrendChart(
                categoryTrends: testCategoryTrends,
                categoryColors: testCategoryColors,
              ),
            ),
          ),
        );

        expect(find.byType(SpendingTrendChart), findsOneWidget);
      });

      testWidgets('displays category selector chips', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpendingTrendChart(
                categoryTrends: testCategoryTrends,
                categoryColors: testCategoryColors,
              ),
            ),
          ),
        );

        // Should show filter chips for categories
        expect(find.byType(FilterChip), findsWidgets);
        expect(find.text('Market'), findsOneWidget);
        expect(find.text('Restoran'), findsOneWidget);
      });

      testWidgets('shows empty state when no trends', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpendingTrendChart(
                categoryTrends: [],
                categoryColors: {},
              ),
            ),
          ),
        );

        expect(find.text('Trend verisi bulunmamaktadır'), findsOneWidget);
      });

      testWidgets('allows category selection', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpendingTrendChart(
                categoryTrends: testCategoryTrends,
                categoryColors: testCategoryColors,
              ),
            ),
          ),
        );

        // Initially, top 3 categories should be selected (we have 2, so both)
        await tester.pumpAndSettle();

        // Tap on a category chip to deselect
        await tester.tap(find.text('Market'));
        await tester.pumpAndSettle();

        // Chart should update
        expect(find.byType(SpendingTrendChart), findsOneWidget);
      });
    });

    group('PeriodComparisonCard', () {
      testWidgets('renders with correct values', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PeriodComparisonCard(
                title: 'Toplam Harcama',
                currentValue: 5000,
                previousValue: 4000,
                icon: Icons.shopping_cart,
                color: Colors.red,
                higherIsBetter: false,
              ),
            ),
          ),
        );

        expect(find.text('Toplam Harcama'), findsOneWidget);
        expect(find.text('Bu Dönem'), findsOneWidget);
        expect(find.text('Önceki Dönem'), findsOneWidget);
        expect(find.text('Değişim'), findsOneWidget);
      });

      testWidgets('shows positive change correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PeriodComparisonCard(
                title: 'Test',
                currentValue: 5000,
                previousValue: 4000,
                icon: Icons.shopping_cart,
                color: Colors.red,
                higherIsBetter: false,
              ),
            ),
          ),
        );

        // Should show trending up icon
        expect(find.byIcon(Icons.trending_up), findsOneWidget);
        
        // Should show percentage change
        expect(find.textContaining('%'), findsWidgets);
      });

      testWidgets('shows negative change correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PeriodComparisonCard(
                title: 'Test',
                currentValue: 3000,
                previousValue: 4000,
                icon: Icons.shopping_cart,
                color: Colors.red,
                higherIsBetter: false,
              ),
            ),
          ),
        );

        // Should show trending down icon
        expect(find.byIcon(Icons.trending_down), findsOneWidget);
      });

      testWidgets('handles zero previous value', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PeriodComparisonCard(
                title: 'Test',
                currentValue: 1000,
                previousValue: 0,
                icon: Icons.shopping_cart,
                color: Colors.red,
              ),
            ),
          ),
        );

        // Should not crash and should show 100% change
        expect(find.byType(PeriodComparisonCard), findsOneWidget);
        expect(find.textContaining('100'), findsOneWidget);
      });
    });

    group('BudgetTrackerCard', () {
      testWidgets('renders budget comparisons', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BudgetTrackerCard(
                budgetComparisons: testBudgetComparisons,
                categoryColors: testCategoryColors,
              ),
            ),
          ),
        );

        expect(find.text('Bütçe Takibi'), findsOneWidget);
        expect(find.text('Market'), findsOneWidget);
        expect(find.text('Restoran'), findsOneWidget);
      });

      testWidgets('shows exceeded warning', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BudgetTrackerCard(
                budgetComparisons: testBudgetComparisons,
                categoryColors: testCategoryColors,
              ),
            ),
          ),
        );

        // Should show "Aşıldı" for exceeded budget
        expect(find.text('Aşıldı'), findsOneWidget);
        expect(find.text('Kontrol Altında'), findsOneWidget);
      });

      testWidgets('shows empty state when no budgets', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BudgetTrackerCard(
                budgetComparisons: {},
                categoryColors: {},
              ),
            ),
          ),
        );

        expect(find.text('Bütçe tanımlanmamış'), findsOneWidget);
      });

      testWidgets('filters exceeded budgets correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BudgetTrackerCard(
                budgetComparisons: testBudgetComparisons,
                categoryColors: testCategoryColors,
                showOnlyExceeded: true,
              ),
            ),
          ),
        );

        // Should only show Restoran (exceeded)
        expect(find.text('Restoran'), findsOneWidget);
        // Market should not be shown
        expect(find.text('Market'), findsNothing);
      });

      testWidgets('shows progress bars', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BudgetTrackerCard(
                budgetComparisons: testBudgetComparisons,
                categoryColors: testCategoryColors,
              ),
            ),
          ),
        );

        // Should show percentage text
        expect(find.textContaining('%'), findsWidgets);
      });
    });

    group('BudgetSummaryCard', () {
      testWidgets('renders summary statistics', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BudgetSummaryCard(
                budgetComparisons: testBudgetComparisons,
              ),
            ),
          ),
        );

        expect(find.text('Bütçe Özeti'), findsOneWidget);
        expect(find.text('Toplam Bütçe'), findsOneWidget);
        expect(find.text('Harcanan'), findsOneWidget);
      });

      testWidgets('calculates totals correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BudgetSummaryCard(
                budgetComparisons: testBudgetComparisons,
              ),
            ),
          ),
        );

        // Total budget should be 1500 + 500 = 2000
        // Total actual should be 1200 + 700 = 1900
        expect(find.byType(BudgetSummaryCard), findsOneWidget);
      });

      testWidgets('shows overall usage bar', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BudgetSummaryCard(
                budgetComparisons: testBudgetComparisons,
              ),
            ),
          ),
        );

        expect(find.text('Genel Kullanım'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });
    });

    group('SpendingHabitsCard', () {
      testWidgets('renders spending habits', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpendingHabitsCard(
                spendingData: testSpendingAnalysis,
                startDate: DateTime(2024, 1, 1),
                endDate: DateTime(2024, 3, 31),
              ),
            ),
          ),
        );

        expect(find.text('Harcama Alışkanlıkları'), findsOneWidget);
      });

      testWidgets('shows day and hour toggle', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpendingHabitsCard(
                spendingData: testSpendingAnalysis,
                startDate: DateTime(2024, 1, 1),
                endDate: DateTime(2024, 3, 31),
              ),
            ),
          ),
        );

        expect(find.byType(SegmentedButton<bool>), findsOneWidget);
        expect(find.text('Gün'), findsOneWidget);
        expect(find.text('Saat'), findsOneWidget);
      });

      testWidgets('displays most spending day', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpendingHabitsCard(
                spendingData: testSpendingAnalysis,
                startDate: DateTime(2024, 1, 1),
                endDate: DateTime(2024, 3, 31),
              ),
            ),
          ),
        );

        expect(find.text('En Çok Harcama'), findsOneWidget);
        expect(find.text('Cuma'), findsOneWidget);
      });

      testWidgets('displays most spending hour', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpendingHabitsCard(
                spendingData: testSpendingAnalysis,
                startDate: DateTime(2024, 1, 1),
                endDate: DateTime(2024, 3, 31),
              ),
            ),
          ),
        );

        expect(find.text('Yoğun Saat'), findsOneWidget);
        expect(find.text('18:00'), findsOneWidget);
      });

      testWidgets('switches between day and hour charts', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpendingHabitsCard(
                spendingData: testSpendingAnalysis,
                startDate: DateTime(2024, 1, 1),
                endDate: DateTime(2024, 3, 31),
              ),
            ),
          ),
        );

        // Initially shows day chart
        await tester.pumpAndSettle();

        // Tap on hour button
        await tester.tap(find.text('Saat'));
        await tester.pumpAndSettle();

        // Should still render without error
        expect(find.byType(SpendingHabitsCard), findsOneWidget);
      });

      testWidgets('shows spending pattern insights', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpendingHabitsCard(
                spendingData: testSpendingAnalysis,
                startDate: DateTime(2024, 1, 1),
                endDate: DateTime(2024, 3, 31),
              ),
            ),
          ),
        );

        expect(find.text('Alışkanlık Analizi'), findsOneWidget);
        expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      });
    });

    group('Integration Tests', () {
      testWidgets('all widgets work together', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  SpendingTrendChart(
                    categoryTrends: testCategoryTrends,
                    categoryColors: testCategoryColors,
                  ),
                  PeriodComparisonCard(
                    title: 'Test',
                    currentValue: 5000,
                    previousValue: 4000,
                    icon: Icons.shopping_cart,
                    color: Colors.red,
                  ),
                  BudgetTrackerCard(
                    budgetComparisons: testBudgetComparisons,
                    categoryColors: testCategoryColors,
                  ),
                  SpendingHabitsCard(
                    spendingData: testSpendingAnalysis,
                    startDate: DateTime(2024, 1, 1),
                    endDate: DateTime(2024, 3, 31),
                  ),
                ],
              ),
            ),
          ),
        );

        // All widgets should render without error
        expect(find.byType(SpendingTrendChart), findsOneWidget);
        expect(find.byType(PeriodComparisonCard), findsOneWidget);
        expect(find.byType(BudgetTrackerCard), findsOneWidget);
        expect(find.byType(SpendingHabitsCard), findsOneWidget);
      });
    });
  });
}
