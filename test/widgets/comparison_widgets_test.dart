import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:parion/models/comparison_data.dart';
import 'package:parion/models/cash_flow_data.dart';
import 'package:parion/widgets/statistics/comparison_card.dart';
import 'package:parion/widgets/statistics/period_selector.dart';

/// Tests for comparison widgets
///
/// Requirements: 10.1, 10.2, 10.3
void main() {
  setUpAll(() async {
    // Initialize Turkish locale for date formatting
    await initializeDateFormatting('tr_TR', null);
  });
  group('ComparisonCard Tests', () {
    late ComparisonData sampleData;

    setUp(() {
      sampleData = ComparisonData(
        period1Start: DateTime(2024, 10, 1),
        period1End: DateTime(2024, 10, 31),
        period2Start: DateTime(2024, 11, 1),
        period2End: DateTime(2024, 11, 30),
        period1Label: 'Ekim 2024',
        period2Label: 'Kasım 2024',
        income: ComparisonMetric(
          label: 'Gelir',
          period1Value: 15000.0,
          period2Value: 18000.0,
          absoluteChange: 3000.0,
          percentageChange: 20.0,
          trend: TrendDirection.up,
        ),
        expense: ComparisonMetric(
          label: 'Gider',
          period1Value: 12000.0,
          period2Value: 11000.0,
          absoluteChange: -1000.0,
          percentageChange: -8.33,
          trend: TrendDirection.down,
        ),
        netCashFlow: ComparisonMetric(
          label: 'Net Akış',
          period1Value: 3000.0,
          period2Value: 7000.0,
          absoluteChange: 4000.0,
          percentageChange: 133.33,
          trend: TrendDirection.up,
        ),
        categoryComparisons: [],
        overallTrend: TrendDirection.up,
        insights: ['Test insight'],
      );
    });

    testWidgets('renders comparison card with all metrics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ComparisonCard(
                comparisonData: sampleData,
                showPeriodSelector: false,
              ),
            ),
          ),
        ),
      );

      // Check title
      expect(find.text('Dönem Karşılaştırması'), findsOneWidget);

      // Check period labels
      expect(find.text('Ekim 2024'), findsOneWidget);
      expect(find.text('Kasım 2024'), findsOneWidget);

      // Check metrics
      expect(find.text('Gelir'), findsOneWidget);
      expect(find.text('Gider'), findsOneWidget);
      expect(find.text('Net Akış'), findsOneWidget);
    });

    testWidgets('displays change indicators correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ComparisonCard(
                comparisonData: sampleData,
                showPeriodSelector: false,
              ),
            ),
          ),
        ),
      );

      // Check for percentage changes
      expect(find.textContaining('+20.0%'), findsOneWidget);
      expect(find.textContaining('-8.3%'), findsOneWidget);
      expect(find.textContaining('+133.3%'), findsOneWidget);
    });

    testWidgets('shows period selector button when enabled', (tester) async {
      bool periodChangedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ComparisonCard(
                comparisonData: sampleData,
                showPeriodSelector: true,
                onPeriodChanged: () {
                  periodChangedCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      // Find and tap the period selector button
      final button = find.byIcon(Icons.calendar_today);
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pump();

      expect(periodChangedCalled, true);
    });

    testWidgets('displays overall trend when not stable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ComparisonCard(
                comparisonData: sampleData,
                showPeriodSelector: false,
              ),
            ),
          ),
        ),
      );

      // Check for overall trend
      expect(find.text('Genel Durum İyileşiyor'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsWidgets);
    });

    testWidgets('displays insights when available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ComparisonCard(
                comparisonData: sampleData,
                showPeriodSelector: false,
              ),
            ),
          ),
        ),
      );

      // Check for insights section
      expect(find.text('Önemli Noktalar'), findsOneWidget);
      expect(find.text('Test insight'), findsOneWidget);
    });

    testWidgets('handles savings rate metric when present', (tester) async {
      final dataWithSavings = ComparisonData(
        period1Start: DateTime(2024, 10, 1),
        period1End: DateTime(2024, 10, 31),
        period2Start: DateTime(2024, 11, 1),
        period2End: DateTime(2024, 11, 30),
        period1Label: 'Ekim 2024',
        period2Label: 'Kasım 2024',
        income: sampleData.income,
        expense: sampleData.expense,
        netCashFlow: sampleData.netCashFlow,
        savingsRate: ComparisonMetric(
          label: 'Tasarruf Oranı',
          period1Value: 20.0,
          period2Value: 38.89,
          absoluteChange: 18.89,
          percentageChange: 94.45,
          trend: TrendDirection.up,
        ),
        categoryComparisons: [],
        overallTrend: TrendDirection.up,
        insights: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ComparisonCard(
                comparisonData: dataWithSavings,
                showPeriodSelector: false,
              ),
            ),
          ),
        ),
      );

      // Check for savings rate
      expect(find.text('Tasarruf Oranı'), findsOneWidget);
    });
  });

  group('PeriodSelector Tests', () {
    testWidgets('renders all period options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeriodSelector(
              selectedPeriod: PeriodType.thisMonthVsLastMonth,
              onPeriodChanged: (_) {},
            ),
          ),
        ),
      );

      // Check title
      expect(find.text('Karşılaştırma Dönemi'), findsOneWidget);

      // Check period options
      expect(find.text('Bu Ay vs Geçen Ay'), findsOneWidget);
      expect(find.text('Bu Yıl vs Geçen Yıl'), findsOneWidget);
      expect(find.text('Bu Çeyrek vs Geçen Çeyrek'), findsOneWidget);
      expect(find.text('Son 30 Gün vs Önceki 30 Gün'), findsOneWidget);
      expect(find.text('Özel Tarih'), findsOneWidget);
    });

    testWidgets('calls onPeriodChanged when period is selected', (
      tester,
    ) async {
      PeriodType? selectedPeriod;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeriodSelector(
              selectedPeriod: PeriodType.thisMonthVsLastMonth,
              onPeriodChanged: (period) {
                selectedPeriod = period;
              },
            ),
          ),
        ),
      );

      // Tap on a different period
      await tester.tap(find.text('Bu Yıl vs Geçen Yıl'));
      await tester.pump();

      expect(selectedPeriod, PeriodType.thisYearVsLastYear);
    });

    testWidgets('shows custom date range when custom period is selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeriodSelector(
              selectedPeriod: PeriodType.custom,
              onPeriodChanged: (_) {},
            ),
          ),
        ),
      );

      // Check for custom date range section
      expect(find.text('Özel Tarih Aralığı'), findsOneWidget);
      expect(find.text('Başlangıç'), findsOneWidget);
      expect(find.text('Bitiş'), findsOneWidget);
    });
  });

  group('PeriodHelper Tests', () {
    test('calculates this month vs last month correctly', () {
      final dates = PeriodHelper.getPeriodDates(
        PeriodType.thisMonthVsLastMonth,
      );

      expect(dates.period1Start.month, DateTime.now().month - 1);
      expect(dates.period2Start.month, DateTime.now().month);
    });

    test('calculates this year vs last year correctly', () {
      final dates = PeriodHelper.getPeriodDates(PeriodType.thisYearVsLastYear);

      expect(dates.period1Start.year, DateTime.now().year - 1);
      expect(dates.period2Start.year, DateTime.now().year);
    });

    test('calculates last 30 days correctly', () {
      final dates = PeriodHelper.getPeriodDates(
        PeriodType.last30DaysVsPrevious30Days,
      );

      final period2Duration = dates.period2End
          .difference(dates.period2Start)
          .inDays;
      final period1Duration = dates.period1End
          .difference(dates.period1Start)
          .inDays;

      expect(period2Duration, 30);
      expect(period1Duration, 30);
    });

    test('handles custom date range', () {
      final customStart = DateTime(2024, 1, 1);
      final customEnd = DateTime(2024, 1, 31);

      final dates = PeriodHelper.getPeriodDates(
        PeriodType.custom,
        customStart: customStart,
        customEnd: customEnd,
      );

      expect(dates.period2Start, customStart);
      expect(dates.period2End, customEnd);

      // Period 1 should be the same duration before period 2
      final duration = customEnd.difference(customStart);
      expect(dates.period1End.difference(dates.period1Start), duration);
    });
  });
}
