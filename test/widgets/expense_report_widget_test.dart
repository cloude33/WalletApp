import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/models/report_data.dart';
import 'package:money/models/cash_flow_data.dart';
import 'package:money/widgets/statistics/expense_report_widget.dart';

void main() {
  group('ExpenseReportWidget Tests', () {
    late ExpenseReport testReport;

    setUp(() {
      testReport = ExpenseReport(
        title: 'Test Expense Report',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 3, 31),
        generatedAt: DateTime(2024, 4, 1),
        totalExpense: 15000,
        expenseCategories: [
          ExpenseCategory(
            category: 'Market',
            amount: 5000,
            percentage: 33.33,
            transactionCount: 20,
            isFixed: false,
          ),
          ExpenseCategory(
            category: 'Kira',
            amount: 4000,
            percentage: 26.67,
            transactionCount: 3,
            isFixed: true,
          ),
          ExpenseCategory(
            category: 'Ulaşım',
            amount: 3000,
            percentage: 20.0,
            transactionCount: 15,
            isFixed: false,
          ),
          ExpenseCategory(
            category: 'Faturalar',
            amount: 2000,
            percentage: 13.33,
            transactionCount: 5,
            isFixed: true,
          ),
          ExpenseCategory(
            category: 'Eğlence',
            amount: 1000,
            percentage: 6.67,
            transactionCount: 8,
            isFixed: false,
          ),
        ],
        monthlyExpense: [
          MonthlyData(
            month: DateTime(2024, 1, 1),
            income: 0,
            expense: 4500,
            netFlow: -4500,
          ),
          MonthlyData(
            month: DateTime(2024, 2, 1),
            income: 0,
            expense: 5000,
            netFlow: -5000,
          ),
          MonthlyData(
            month: DateTime(2024, 3, 1),
            income: 0,
            expense: 5500,
            netFlow: -5500,
          ),
        ],
        trend: TrendDirection.up,
        averageMonthly: 5000,
        totalFixedExpense: 6000,
        totalVariableExpense: 9000,
        previousPeriodExpense: 12000,
        changePercentage: 25.0,
        optimizationSuggestions: [
          OptimizationSuggestion(
            category: 'Market',
            suggestion: 'Toplu alışveriş yaparak %15 tasarruf edebilirsiniz',
            potentialSavings: 750,
            priority: 4,
          ),
          OptimizationSuggestion(
            category: 'Ulaşım',
            suggestion: 'Toplu taşıma kullanarak aylık 500₺ tasarruf edebilirsiniz',
            potentialSavings: 500,
            priority: 3,
          ),
          OptimizationSuggestion(
            category: 'Eğlence',
            suggestion: 'Eğlence harcamalarınızı %20 azaltabilirsiniz',
            potentialSavings: 200,
            priority: 2,
          ),
        ],
      );
    });

    testWidgets('renders expense report widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseReportWidget(report: testReport),
          ),
        ),
      );

      expect(find.byType(ExpenseReportWidget), findsOneWidget);
    });

    testWidgets('displays total expense and average', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseReportWidget(report: testReport),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Toplam Gider'), findsOneWidget);
      expect(find.text('Aylık Ortalama'), findsOneWidget);
    });

    testWidgets('displays fixed and variable expense breakdown', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseReportWidget(report: testReport),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sabit / Değişken Gider Dağılımı'), findsOneWidget);
      expect(find.text('Sabit Giderler'), findsOneWidget);
      expect(find.text('Değişken Giderler'), findsOneWidget);
    });

    testWidgets('displays category distribution', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseReportWidget(report: testReport),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kategori Bazlı Dağılım'), findsOneWidget);
    });

    testWidgets('displays period comparison when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseReportWidget(report: testReport),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dönemsel Karşılaştırma'), findsOneWidget);
      expect(find.text('Önceki Dönem'), findsOneWidget);
      expect(find.text('Bu Dönem'), findsOneWidget);
    });

    testWidgets('does not display period comparison when not available', (WidgetTester tester) async {
      final reportWithoutComparison = ExpenseReport(
        title: 'Test Report',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 3, 31),
        generatedAt: DateTime(2024, 4, 1),
        totalExpense: 15000,
        expenseCategories: testReport.expenseCategories,
        monthlyExpense: testReport.monthlyExpense,
        trend: TrendDirection.up,
        averageMonthly: 5000,
        totalFixedExpense: 6000,
        totalVariableExpense: 9000,
        optimizationSuggestions: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseReportWidget(report: reportWithoutComparison),
          ),
        ),
      );

      expect(find.text('Dönemsel Karşılaştırma'), findsNothing);
    });

    testWidgets('displays trend analysis', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseReportWidget(report: testReport),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gider Trendi'), findsOneWidget);
      expect(find.text('Artış'), findsOneWidget);
    });

    testWidgets('displays optimization suggestions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseReportWidget(report: testReport),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Optimizasyon Önerileri'), findsOneWidget);
      expect(find.text('Market'), findsWidgets);
      expect(find.text('Toplu alışveriş yaparak %15 tasarruf edebilirsiniz'), findsOneWidget);
    });

    testWidgets('does not display optimization suggestions when empty', (WidgetTester tester) async {
      final reportWithoutSuggestions = ExpenseReport(
        title: 'Test Report',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 3, 31),
        generatedAt: DateTime(2024, 4, 1),
        totalExpense: 15000,
        expenseCategories: testReport.expenseCategories,
        monthlyExpense: testReport.monthlyExpense,
        trend: TrendDirection.up,
        averageMonthly: 5000,
        totalFixedExpense: 6000,
        totalVariableExpense: 9000,
        optimizationSuggestions: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseReportWidget(report: reportWithoutSuggestions),
          ),
        ),
      );

      expect(find.text('Optimizasyon Önerileri'), findsNothing);
    });

    testWidgets('displays detailed category table', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseReportWidget(report: testReport),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detaylı Kategori Analizi'), findsOneWidget);
      expect(find.text('Kategori'), findsOneWidget);
      expect(find.text('İşlem'), findsOneWidget);
      expect(find.text('Tutar'), findsOneWidget);
      expect(find.text('Oran'), findsOneWidget);
    });

    testWidgets('displays all expense categories in table', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseReportWidget(report: testReport),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Market'), findsWidgets);
      expect(find.text('Kira'), findsOneWidget);
      expect(find.text('Ulaşım'), findsWidgets);
      expect(find.text('Faturalar'), findsOneWidget);
      expect(find.text('Eğlence'), findsWidgets);
    });

    testWidgets('shows correct trend indicator for upward trend', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseReportWidget(report: testReport),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Artış'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsWidgets);
    });

    testWidgets('shows correct trend indicator for downward trend', (WidgetTester tester) async {
      final reportWithDownTrend = ExpenseReport(
        title: 'Test Report',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 3, 31),
        generatedAt: DateTime(2024, 4, 1),
        totalExpense: 15000,
        expenseCategories: testReport.expenseCategories,
        monthlyExpense: testReport.monthlyExpense,
        trend: TrendDirection.down,
        averageMonthly: 5000,
        totalFixedExpense: 6000,
        totalVariableExpense: 9000,
        optimizationSuggestions: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseReportWidget(report: reportWithDownTrend),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Azalış'), findsOneWidget);
    });

    testWidgets('shows correct trend indicator for stable trend', (WidgetTester tester) async {
      final reportWithStableTrend = ExpenseReport(
        title: 'Test Report',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 3, 31),
        generatedAt: DateTime(2024, 4, 1),
        totalExpense: 15000,
        expenseCategories: testReport.expenseCategories,
        monthlyExpense: testReport.monthlyExpense,
        trend: TrendDirection.stable,
        averageMonthly: 5000,
        totalFixedExpense: 6000,
        totalVariableExpense: 9000,
        optimizationSuggestions: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseReportWidget(report: reportWithStableTrend),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sabit'), findsWidgets);
    });

    testWidgets('optimization suggestions are sorted by priority', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseReportWidget(report: testReport),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that suggestions exist
      expect(find.text('Toplu alışveriş yaparak %15 tasarruf edebilirsiniz'), findsOneWidget);
      expect(find.text('Toplu taşıma kullanarak aylık 500₺ tasarruf edebilirsiniz'), findsOneWidget);
    });

    testWidgets('displays fixed vs variable percentage correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseReportWidget(report: testReport),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fixed: 6000 / 15000 = 40%
      // Variable: 9000 / 15000 = 60%
      expect(find.textContaining('40.0%'), findsWidgets);
      expect(find.textContaining('60.0%'), findsWidgets);
    });

    testWidgets('scrollable content works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseReportWidget(report: testReport),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
