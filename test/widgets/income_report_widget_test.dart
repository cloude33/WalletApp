import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money/models/report_data.dart';
import 'package:money/models/cash_flow_data.dart';
import 'package:money/widgets/statistics/income_report_widget.dart';

void main() {
  group('IncomeReportWidget', () {
    late IncomeReport testReport;

    setUpAll(() async {
      // Initialize Turkish locale data for date formatting
      await initializeDateFormatting('tr_TR', null);
    });

    // Helper function to wrap widget with MaterialApp and localization
    Widget wrapWidget(Widget child) {
      return MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('tr', 'TR'),
        ],
        locale: const Locale('tr', 'TR'),
        home: Scaffold(
          body: child,
        ),
      );
    }

    setUp(() {
      // Create test data
      testReport = IncomeReport(
        title: 'Test Gelir Raporu',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 3, 31),
        generatedAt: DateTime(2024, 4, 1),
        totalIncome: 15000.0,
        incomeSources: [
          IncomeSource(
            source: 'Maaş',
            amount: 10000.0,
            percentage: 66.67,
            transactionCount: 3,
          ),
          IncomeSource(
            source: 'Freelance',
            amount: 3000.0,
            percentage: 20.0,
            transactionCount: 5,
          ),
          IncomeSource(
            source: 'Yatırım',
            amount: 2000.0,
            percentage: 13.33,
            transactionCount: 2,
          ),
        ],
        monthlyIncome: [
          MonthlyData(
            month: DateTime(2024, 1, 1),
            income: 5000.0,
            expense: 0,
            netFlow: 5000.0,
          ),
          MonthlyData(
            month: DateTime(2024, 2, 1),
            income: 4500.0,
            expense: 0,
            netFlow: 4500.0,
          ),
          MonthlyData(
            month: DateTime(2024, 3, 1),
            income: 5500.0,
            expense: 0,
            netFlow: 5500.0,
          ),
        ],
        trend: TrendDirection.up,
        averageMonthly: 5000.0,
        previousPeriodIncome: 12000.0,
        changePercentage: 25.0,
        highestIncomeMonth: DateTime(2024, 3, 1),
        highestIncomeAmount: 5500.0,
      );
    });

    testWidgets('displays summary cards correctly', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWidget(IncomeReportWidget(report: testReport)));

      // Verify summary cards are displayed
      expect(find.text('Toplam Gelir'), findsOneWidget);
      expect(find.text('Aylık Ortalama'), findsOneWidget);
      expect(find.text('En Yüksek Gelir'), findsOneWidget);
      expect(find.text('En Yüksek Ay'), findsOneWidget);
    });

    testWidgets('displays period comparison when available', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWidget(IncomeReportWidget(report: testReport)));

      // Verify period comparison is displayed
      expect(find.text('Dönemsel Karşılaştırma'), findsOneWidget);
      expect(find.text('Önceki Dönem'), findsOneWidget);
      expect(find.text('Bu Dönem'), findsOneWidget);
      expect(find.text('artış'), findsOneWidget);
    });

    testWidgets('displays income source distribution', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWidget(IncomeReportWidget(report: testReport)));

      // Verify income sources are displayed
      expect(find.text('Gelir Kaynakları Dağılımı'), findsOneWidget);
      expect(find.text('Maaş'), findsOneWidget);
      expect(find.text('Freelance'), findsOneWidget);
      expect(find.text('Yatırım'), findsOneWidget);
    });

    testWidgets('displays trend analysis with correct indicator', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWidget(IncomeReportWidget(report: testReport)));

      // Verify trend analysis is displayed
      expect(find.text('Trend Analizi'), findsOneWidget);
      expect(find.text('Yükseliş'), findsOneWidget);
    });

    testWidgets('displays detailed table with monthly data', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWidget(IncomeReportWidget(report: testReport)));

      // Verify detailed table is displayed
      expect(find.text('Detaylı Tablo'), findsOneWidget);
      expect(find.text('Ay'), findsOneWidget);
      expect(find.text('Gelir'), findsOneWidget);
      expect(find.text('Ortalamadan Fark'), findsOneWidget);
      expect(find.text('Durum'), findsOneWidget);
    });

    testWidgets('handles empty income sources', (WidgetTester tester) async {
      final emptyReport = IncomeReport(
        title: 'Empty Report',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 3, 31),
        generatedAt: DateTime(2024, 4, 1),
        totalIncome: 0.0,
        incomeSources: [],
        monthlyIncome: [],
        trend: TrendDirection.stable,
        averageMonthly: 0.0,
      );

      await tester.pumpWidget(wrapWidget(IncomeReportWidget(report: emptyReport)));

      // Verify empty state messages
      expect(find.text('Bu dönemde gelir kaynağı bulunamadı'), findsOneWidget);
      expect(find.text('Trend verisi bulunamadı'), findsOneWidget);
      expect(find.text('Veri bulunamadı'), findsOneWidget);
    });

    testWidgets('displays correct trend indicator for down trend', (WidgetTester tester) async {
      final downTrendReport = IncomeReport(
        title: 'Down Trend Report',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 3, 31),
        generatedAt: DateTime(2024, 4, 1),
        totalIncome: 10000.0,
        incomeSources: [
          IncomeSource(
            source: 'Maaş',
            amount: 10000.0,
            percentage: 100.0,
            transactionCount: 3,
          ),
        ],
        monthlyIncome: [
          MonthlyData(
            month: DateTime(2024, 1, 1),
            income: 5000.0,
            expense: 0,
            netFlow: 5000.0,
          ),
          MonthlyData(
            month: DateTime(2024, 2, 1),
            income: 3000.0,
            expense: 0,
            netFlow: 3000.0,
          ),
          MonthlyData(
            month: DateTime(2024, 3, 1),
            income: 2000.0,
            expense: 0,
            netFlow: 2000.0,
          ),
        ],
        trend: TrendDirection.down,
        averageMonthly: 3333.33,
        previousPeriodIncome: 15000.0,
        changePercentage: -33.33,
      );

      await tester.pumpWidget(wrapWidget(IncomeReportWidget(report: downTrendReport)));

      // Verify down trend indicator
      expect(find.text('Düşüş'), findsOneWidget);
      expect(find.text('azalış'), findsOneWidget);
    });

    testWidgets('displays correct trend indicator for stable trend', (WidgetTester tester) async {
      final stableTrendReport = IncomeReport(
        title: 'Stable Trend Report',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 3, 31),
        generatedAt: DateTime(2024, 4, 1),
        totalIncome: 15000.0,
        incomeSources: [
          IncomeSource(
            source: 'Maaş',
            amount: 15000.0,
            percentage: 100.0,
            transactionCount: 3,
          ),
        ],
        monthlyIncome: [
          MonthlyData(
            month: DateTime(2024, 1, 1),
            income: 5000.0,
            expense: 0,
            netFlow: 5000.0,
          ),
          MonthlyData(
            month: DateTime(2024, 2, 1),
            income: 5000.0,
            expense: 0,
            netFlow: 5000.0,
          ),
          MonthlyData(
            month: DateTime(2024, 3, 1),
            income: 5000.0,
            expense: 0,
            netFlow: 5000.0,
          ),
        ],
        trend: TrendDirection.stable,
        averageMonthly: 5000.0,
      );

      await tester.pumpWidget(wrapWidget(IncomeReportWidget(report: stableTrendReport)));

      // Verify stable trend indicator
      expect(find.text('Sabit'), findsOneWidget);
    });

    testWidgets('formats currency correctly', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWidget(IncomeReportWidget(report: testReport)));

      // Verify currency formatting (Turkish locale)
      expect(find.textContaining('₺'), findsWidgets);
      expect(find.textContaining('15.000,00'), findsWidgets); // Can appear in multiple places
      expect(find.textContaining('5.000,00'), findsWidgets);
    });

    testWidgets('displays transaction counts for income sources', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWidget(IncomeReportWidget(report: testReport)));

      // Verify transaction counts
      expect(find.text('3 işlem'), findsOneWidget);
      expect(find.text('5 işlem'), findsOneWidget);
      expect(find.text('2 işlem'), findsOneWidget);
    });

    testWidgets('displays percentages for income sources', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWidget(IncomeReportWidget(report: testReport)));

      // Verify percentages are displayed
      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets('scrolls correctly', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWidget(IncomeReportWidget(report: testReport)));

      // Verify SingleChildScrollView is present
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });
}
