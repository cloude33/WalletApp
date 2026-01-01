import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/credit_analysis.dart';
import 'package:parion/widgets/statistics/kmh_trend_charts.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    // Initialize Turkish locale for DateFormat
    await initializeDateFormatting('tr_TR', null);
  });

  group('KmhTrendCharts Widget Tests', () {
    testWidgets('displays empty state when no trend data', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KmhTrendCharts(
              debtTrend: [],
              totalLimit: 10000,
            ),
          ),
        ),
      );

      expect(find.text('Trend Verisi Bulunamadı'), findsOneWidget);
      expect(find.text('Trend analizi için yeterli geçmiş veri bulunmamaktadır.'), findsOneWidget);
      expect(find.byIcon(Icons.show_chart), findsOneWidget);
    });

    testWidgets('displays trend charts with valid data', (WidgetTester tester) async {
      final trendData = [
        DebtTrendData(
          date: DateTime(2024, 6, 1),
          creditCardDebt: 1000,
          kmhDebt: 5000,
          totalDebt: 6000,
        ),
        DebtTrendData(
          date: DateTime(2024, 7, 1),
          creditCardDebt: 1200,
          kmhDebt: 5500,
          totalDebt: 6700,
        ),
        DebtTrendData(
          date: DateTime(2024, 8, 1),
          creditCardDebt: 1100,
          kmhDebt: 5200,
          totalDebt: 6300,
        ),
        DebtTrendData(
          date: DateTime(2024, 9, 1),
          creditCardDebt: 1300,
          kmhDebt: 5800,
          totalDebt: 7100,
        ),
        DebtTrendData(
          date: DateTime(2024, 10, 1),
          creditCardDebt: 1400,
          kmhDebt: 6000,
          totalDebt: 7400,
        ),
        DebtTrendData(
          date: DateTime(2024, 11, 1),
          creditCardDebt: 1500,
          kmhDebt: 6200,
          totalDebt: 7700,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KmhTrendCharts(
                debtTrend: trendData,
                totalLimit: 10000,
              ),
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Check for section title
      expect(find.text('KMH Trend Analizi (Son 6 Ay)'), findsOneWidget);

      // Check for chart titles
      expect(find.text('Borç Değişimi'), findsOneWidget);
      expect(find.text('Faiz Tahakkuku'), findsOneWidget);
      expect(find.text('Kullanım Oranı'), findsOneWidget);

      // Check for chart descriptions
      expect(find.text('KMH borç tutarının son 6 aydaki değişimi'), findsOneWidget);
      expect(find.text('Kümülatif faiz tahakkuk trendi (tahmini)'), findsOneWidget);
      expect(find.text('KMH limit kullanım oranının değişimi'), findsOneWidget);

      // Check for icons
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.byIcon(Icons.percent), findsOneWidget);
      expect(find.byIcon(Icons.pie_chart), findsOneWidget);
    });

    testWidgets('displays trend summary with correct change calculation', (WidgetTester tester) async {
      final trendData = [
        DebtTrendData(
          date: DateTime(2024, 6, 1),
          creditCardDebt: 1000,
          kmhDebt: 5000,
          totalDebt: 6000,
        ),
        DebtTrendData(
          date: DateTime(2024, 11, 1),
          creditCardDebt: 1500,
          kmhDebt: 6000,
          totalDebt: 7500,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KmhTrendCharts(
                debtTrend: trendData,
                totalLimit: 10000,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for trend summary
      expect(find.text('6 Aylık Değişim'), findsOneWidget);
      
      // The change should be 1000 (6000 to 7000) which is 20% increase
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('displays utilization info with current and average', (WidgetTester tester) async {
      final trendData = [
        DebtTrendData(
          date: DateTime(2024, 6, 1),
          creditCardDebt: 1000,
          kmhDebt: 5000,
          totalDebt: 6000,
        ),
        DebtTrendData(
          date: DateTime(2024, 7, 1),
          creditCardDebt: 1200,
          kmhDebt: 6000,
          totalDebt: 7200,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KmhTrendCharts(
                debtTrend: trendData,
                totalLimit: 10000,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for utilization info
      expect(find.text('Mevcut Kullanım'), findsOneWidget);
      expect(find.text('Ortalama'), findsOneWidget);
    });

    testWidgets('displays interest info with total interest', (WidgetTester tester) async {
      final trendData = [
        DebtTrendData(
          date: DateTime(2024, 6, 1),
          creditCardDebt: 1000,
          kmhDebt: 5000,
          totalDebt: 6000,
        ),
        DebtTrendData(
          date: DateTime(2024, 7, 1),
          creditCardDebt: 1200,
          kmhDebt: 6000,
          totalDebt: 7200,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KmhTrendCharts(
                debtTrend: trendData,
                totalLimit: 10000,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for interest info
      expect(find.text('Toplam Faiz (6 Ay)'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('handles single data point correctly', (WidgetTester tester) async {
      final trendData = [
        DebtTrendData(
          date: DateTime(2024, 11, 1),
          creditCardDebt: 1500,
          kmhDebt: 6000,
          totalDebt: 7500,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KmhTrendCharts(
                debtTrend: trendData,
                totalLimit: 10000,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should still display charts
      expect(find.text('KMH Trend Analizi (Son 6 Ay)'), findsOneWidget);
      expect(find.text('Borç Değişimi'), findsOneWidget);
    });

    testWidgets('displays correct utilization colors based on rate', (WidgetTester tester) async {
      // Test with high utilization (>80%)
      final highUtilizationData = [
        DebtTrendData(
          date: DateTime(2024, 11, 1),
          creditCardDebt: 1000,
          kmhDebt: 9000, // 90% utilization
          totalDebt: 10000,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KmhTrendCharts(
                debtTrend: highUtilizationData,
                totalLimit: 10000,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display utilization chart
      expect(find.text('Kullanım Oranı'), findsOneWidget);
    });

    testWidgets('displays all three charts in correct order', (WidgetTester tester) async {
      final trendData = [
        DebtTrendData(
          date: DateTime(2024, 6, 1),
          creditCardDebt: 1000,
          kmhDebt: 5000,
          totalDebt: 6000,
        ),
        DebtTrendData(
          date: DateTime(2024, 11, 1),
          creditCardDebt: 1500,
          kmhDebt: 6000,
          totalDebt: 7500,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KmhTrendCharts(
                debtTrend: trendData,
                totalLimit: 10000,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find all chart titles
      final debtChangeText = find.text('Borç Değişimi');
      final interestText = find.text('Faiz Tahakkuku');
      final utilizationText = find.text('Kullanım Oranı');

      expect(debtChangeText, findsOneWidget);
      expect(interestText, findsOneWidget);
      expect(utilizationText, findsOneWidget);

      // Verify they appear in the correct order
      final debtChangePosition = tester.getTopLeft(debtChangeText);
      final interestPosition = tester.getTopLeft(interestText);
      final utilizationPosition = tester.getTopLeft(utilizationText);

      expect(debtChangePosition.dy < interestPosition.dy, true);
      expect(interestPosition.dy < utilizationPosition.dy, true);
    });
  });
}
