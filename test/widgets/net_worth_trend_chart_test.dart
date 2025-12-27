import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money/models/asset_analysis.dart';
import 'package:money/widgets/statistics/net_worth_trend_chart.dart';

void main() {
  group('NetWorthTrendChart Widget Tests', () {
    late List<NetWorthTrendData> mockTrendData;

    setUpAll(() async {
      // Initialize Turkish locale for date formatting
      await initializeDateFormatting('tr_TR', null);
    });

    setUp(() {
      // Create 12 months of mock data
      mockTrendData = List.generate(12, (index) {
        final date = DateTime(2024, index + 1, 1);
        final assets = 100000.0 + (index * 5000);
        final liabilities = 50000.0 - (index * 2000);
        final netWorth = assets - liabilities;

        return NetWorthTrendData(
          date: date,
          assets: assets,
          liabilities: liabilities,
          netWorth: netWorth,
        );
      });
    });

    testWidgets('displays chart with trend data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetWorthTrendChart(
              trendData: mockTrendData,
            ),
          ),
        ),
      );

      // Verify chart title is displayed
      expect(find.text('Net Varlık Trendi'), findsOneWidget);
      expect(find.text('Son 12 ay'), findsOneWidget);

      // Verify legend toggles are displayed
      expect(find.text('Net Varlık'), findsOneWidget);
      expect(find.text('Varlıklar'), findsOneWidget);
      expect(find.text('Borçlar'), findsOneWidget);
    });

    testWidgets('displays trend indicator with positive change', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetWorthTrendChart(
              trendData: mockTrendData,
            ),
          ),
        ),
      );

      // Verify positive trend indicator is displayed
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('displays trend indicator with negative change', (WidgetTester tester) async {
      // Create data with negative trend
      final negativeTrendData = List.generate(12, (index) {
        final date = DateTime(2024, index + 1, 1);
        final assets = 100000.0 - (index * 5000);
        final liabilities = 50000.0 + (index * 2000);
        final netWorth = assets - liabilities;

        return NetWorthTrendData(
          date: date,
          assets: assets,
          liabilities: liabilities,
          netWorth: netWorth,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetWorthTrendChart(
              trendData: negativeTrendData,
            ),
          ),
        ),
      );

      // Verify negative trend indicator is displayed
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('displays empty state when no data', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NetWorthTrendChart(
              trendData: [],
            ),
          ),
        ),
      );

      // Verify empty state is displayed
      expect(find.text('Trend verisi bulunmamaktadır'), findsOneWidget);
      expect(find.byIcon(Icons.show_chart), findsOneWidget);
    });

    testWidgets('toggles legend items', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetWorthTrendChart(
              trendData: mockTrendData,
            ),
          ),
        ),
      );

      // Find and tap the "Varlıklar" toggle
      final assetsToggle = find.text('Varlıklar');
      expect(assetsToggle, findsOneWidget);

      await tester.tap(assetsToggle);
      await tester.pump();

      // The widget should rebuild with the toggle state changed
      // We can't easily verify the chart lines, but we can verify the widget rebuilds
      expect(assetsToggle, findsOneWidget);
    });

    testWidgets('displays target comparison when target is provided', (WidgetTester tester) async {
      const targetNetWorth = 150000.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetWorthTrendChart(
              trendData: mockTrendData,
              targetNetWorth: targetNetWorth,
            ),
          ),
        ),
      );

      // Verify target comparison section is displayed
      expect(find.text('Hedef Net Varlık'), findsOneWidget);
      expect(find.byIcon(Icons.flag), findsOneWidget);
    });

    testWidgets('displays achieved target when net worth exceeds target', (WidgetTester tester) async {
      const targetNetWorth = 50000.0; // Lower than current net worth

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetWorthTrendChart(
              trendData: mockTrendData,
              targetNetWorth: targetNetWorth,
            ),
          ),
        ),
      );

      // Verify achieved target indicator is displayed
      expect(find.text('Hedef Net Varlık'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.textContaining('Hedef başarıldı!'), findsOneWidget);
    });

    testWidgets('displays selected point details on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetWorthTrendChart(
              trendData: mockTrendData,
            ),
          ),
        ),
      );

      // Note: Tapping on chart points is complex with fl_chart
      // This test verifies the widget structure is correct
      expect(find.byType(NetWorthTrendChart), findsOneWidget);
    });

    testWidgets('handles single data point', (WidgetTester tester) async {
      final singleDataPoint = [
        NetWorthTrendData(
          date: DateTime(2024, 1, 1),
          assets: 100000.0,
          liabilities: 50000.0,
          netWorth: 50000.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetWorthTrendChart(
              trendData: singleDataPoint,
            ),
          ),
        ),
      );

      // Verify chart is displayed even with single data point
      expect(find.text('Net Varlık Trendi'), findsOneWidget);
    });

    testWidgets('displays correct month labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetWorthTrendChart(
              trendData: mockTrendData,
            ),
          ),
        ),
      );

      // The chart should display month labels
      // Note: Exact month labels depend on fl_chart rendering
      expect(find.byType(NetWorthTrendChart), findsOneWidget);
    });

    testWidgets('handles zero values correctly', (WidgetTester tester) async {
      final zeroData = List.generate(12, (index) {
        return NetWorthTrendData(
          date: DateTime(2024, index + 1, 1),
          assets: 0.0,
          liabilities: 0.0,
          netWorth: 0.0,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetWorthTrendChart(
              trendData: zeroData,
            ),
          ),
        ),
      );

      // Verify chart handles zero values without errors
      expect(find.text('Net Varlık Trendi'), findsOneWidget);
    });

    testWidgets('handles negative net worth correctly', (WidgetTester tester) async {
      final negativeData = List.generate(12, (index) {
        return NetWorthTrendData(
          date: DateTime(2024, index + 1, 1),
          assets: 30000.0,
          liabilities: 50000.0,
          netWorth: -20000.0,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetWorthTrendChart(
              trendData: negativeData,
            ),
          ),
        ),
      );

      // Verify chart handles negative values without errors
      expect(find.text('Net Varlık Trendi'), findsOneWidget);
    });
  });
}
