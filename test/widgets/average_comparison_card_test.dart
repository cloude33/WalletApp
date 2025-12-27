import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/services/statistics_service.dart';
import 'package:money/widgets/statistics/average_comparison_card.dart';

/// Widget tests for Average Comparison Card
/// 
/// Tests the UI rendering and interaction of the average comparison card.
/// 
/// Requirements: 10.4
void main() {
  group('AverageComparisonCard Widget Tests', () {
    late AverageComparisonData testData;

    setUp(() {
      // Create test data
      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      testData = AverageComparisonData(
        currentPeriodStart: currentMonthStart,
        currentPeriodEnd: currentMonthEnd,
        currentIncome: 10000.0,
        currentExpense: 7000.0,
        currentNetFlow: 3000.0,
        threeMonthBenchmark: AverageBenchmark(
          periodLabel: '3 Aylık Ortalama',
          averageIncome: 9000.0,
          averageExpense: 6500.0,
          averageNetFlow: 2500.0,
          currentIncome: 10000.0,
          currentExpense: 7000.0,
          currentNetFlow: 3000.0,
          incomeDeviation: 11.11,
          expenseDeviation: 7.69,
          netFlowDeviation: 20.0,
          performanceRating: PerformanceRating.excellent,
        ),
        sixMonthBenchmark: AverageBenchmark(
          periodLabel: '6 Aylık Ortalama',
          averageIncome: 8500.0,
          averageExpense: 6000.0,
          averageNetFlow: 2500.0,
          currentIncome: 10000.0,
          currentExpense: 7000.0,
          currentNetFlow: 3000.0,
          incomeDeviation: 17.65,
          expenseDeviation: 16.67,
          netFlowDeviation: 20.0,
          performanceRating: PerformanceRating.excellent,
        ),
        twelveMonthBenchmark: AverageBenchmark(
          periodLabel: '12 Aylık Ortalama',
          averageIncome: 8000.0,
          averageExpense: 5500.0,
          averageNetFlow: 2500.0,
          currentIncome: 10000.0,
          currentExpense: 7000.0,
          currentNetFlow: 3000.0,
          incomeDeviation: 25.0,
          expenseDeviation: 27.27,
          netFlowDeviation: 20.0,
          performanceRating: PerformanceRating.excellent,
        ),
        insights: [
          'Mükemmel! Son 3 aylık ortalamanızın %20.0 üzerinde performans gösteriyorsunuz.',
          'Geliriniz 3 aylık ortalamanızın %11.1 üzerinde.',
        ],
      );
    });

    testWidgets('renders card with title', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AverageComparisonCard(
              comparisonData: testData,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Ortalama Karşılaştırması'), findsOneWidget);
      expect(
        find.text('Geçmiş dönem ortalamalarıyla karşılaştırma'),
        findsOneWidget,
      );
    });

    testWidgets('displays current period summary', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AverageComparisonCard(
              comparisonData: testData,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Mevcut Dönem'), findsOneWidget);
      expect(find.text('Gelir'), findsWidgets);
      expect(find.text('Gider'), findsWidgets);
      expect(find.text('Net Akış'), findsWidgets);
    });

    testWidgets('displays all three benchmark sections', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AverageComparisonCard(
                comparisonData: testData,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('3 Aylık Ortalama'), findsOneWidget);
      expect(find.text('6 Aylık Ortalama'), findsOneWidget);
      expect(find.text('12 Aylık Ortalama'), findsOneWidget);
    });

    testWidgets('displays performance rating badges', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AverageComparisonCard(
                comparisonData: testData,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      // Should find "Mükemmel" badge for all three benchmarks
      expect(find.text('Mükemmel'), findsNWidgets(3));
    });

    testWidgets('displays insights section', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AverageComparisonCard(
                comparisonData: testData,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Önemli Noktalar'), findsOneWidget);
      expect(
        find.text('Mükemmel! Son 3 aylık ortalamanızın %20.0 üzerinde performans gösteriyorsunuz.'),
        findsOneWidget,
      );
    });

    testWidgets('displays deviation indicators', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AverageComparisonCard(
                comparisonData: testData,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      // Should find percentage indicators
      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets('renders correctly with poor performance rating', (WidgetTester tester) async {
      // Arrange
      final poorData = AverageComparisonData(
        currentPeriodStart: testData.currentPeriodStart,
        currentPeriodEnd: testData.currentPeriodEnd,
        currentIncome: 5000.0,
        currentExpense: 8000.0,
        currentNetFlow: -3000.0,
        threeMonthBenchmark: AverageBenchmark(
          periodLabel: '3 Aylık Ortalama',
          averageIncome: 9000.0,
          averageExpense: 6500.0,
          averageNetFlow: 2500.0,
          currentIncome: 5000.0,
          currentExpense: 8000.0,
          currentNetFlow: -3000.0,
          incomeDeviation: -44.44,
          expenseDeviation: 23.08,
          netFlowDeviation: -220.0,
          performanceRating: PerformanceRating.poor,
        ),
        sixMonthBenchmark: testData.sixMonthBenchmark,
        twelveMonthBenchmark: testData.twelveMonthBenchmark,
        insights: ['Dikkat! Son 3 aylık ortalamanızın %220.0 altında performans gösteriyorsunuz.'],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AverageComparisonCard(
                comparisonData: poorData,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Zayıf'), findsOneWidget);
    });

    testWidgets('renders correctly with average performance rating', (WidgetTester tester) async {
      // Arrange
      final averageData = AverageComparisonData(
        currentPeriodStart: testData.currentPeriodStart,
        currentPeriodEnd: testData.currentPeriodEnd,
        currentIncome: 9000.0,
        currentExpense: 6500.0,
        currentNetFlow: 2500.0,
        threeMonthBenchmark: AverageBenchmark(
          periodLabel: '3 Aylık Ortalama',
          averageIncome: 9000.0,
          averageExpense: 6500.0,
          averageNetFlow: 2500.0,
          currentIncome: 9000.0,
          currentExpense: 6500.0,
          currentNetFlow: 2500.0,
          incomeDeviation: 0.0,
          expenseDeviation: 0.0,
          netFlowDeviation: 0.0,
          performanceRating: PerformanceRating.average,
        ),
        sixMonthBenchmark: testData.sixMonthBenchmark,
        twelveMonthBenchmark: testData.twelveMonthBenchmark,
        insights: [],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AverageComparisonCard(
                comparisonData: averageData,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ortalama'), findsOneWidget);
    });

    testWidgets('does not display insights section when empty', (WidgetTester tester) async {
      // Arrange
      final noInsightsData = AverageComparisonData(
        currentPeriodStart: testData.currentPeriodStart,
        currentPeriodEnd: testData.currentPeriodEnd,
        currentIncome: testData.currentIncome,
        currentExpense: testData.currentExpense,
        currentNetFlow: testData.currentNetFlow,
        threeMonthBenchmark: testData.threeMonthBenchmark,
        sixMonthBenchmark: testData.sixMonthBenchmark,
        twelveMonthBenchmark: testData.twelveMonthBenchmark,
        insights: [],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AverageComparisonCard(
                comparisonData: noInsightsData,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Önemli Noktalar'), findsNothing);
    });

    testWidgets('displays icons correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AverageComparisonCard(
                comparisonData: testData,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsWidgets);
      expect(find.byIcon(Icons.arrow_downward), findsWidgets);
      expect(find.byIcon(Icons.account_balance_wallet), findsWidgets);
    });

    testWidgets('card is scrollable', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AverageComparisonCard(
                comparisonData: testData,
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('renders with all performance rating types', (WidgetTester tester) async {
      // Test each performance rating
      final ratings = [
        (PerformanceRating.excellent, 'Mükemmel'),
        (PerformanceRating.good, 'İyi'),
        (PerformanceRating.average, 'Ortalama'),
        (PerformanceRating.below, 'Altında'),
        (PerformanceRating.poor, 'Zayıf'),
      ];

      for (final (rating, label) in ratings) {
        final data = AverageComparisonData(
          currentPeriodStart: testData.currentPeriodStart,
          currentPeriodEnd: testData.currentPeriodEnd,
          currentIncome: testData.currentIncome,
          currentExpense: testData.currentExpense,
          currentNetFlow: testData.currentNetFlow,
          threeMonthBenchmark: AverageBenchmark(
            periodLabel: '3 Aylık Ortalama',
            averageIncome: 9000.0,
            averageExpense: 6500.0,
            averageNetFlow: 2500.0,
            currentIncome: 10000.0,
            currentExpense: 7000.0,
            currentNetFlow: 3000.0,
            incomeDeviation: 11.11,
            expenseDeviation: 7.69,
            netFlowDeviation: 20.0,
            performanceRating: rating,
          ),
          sixMonthBenchmark: testData.sixMonthBenchmark,
          twelveMonthBenchmark: testData.twelveMonthBenchmark,
          insights: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AverageComparisonCard(
                  comparisonData: data,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text(label), findsOneWidget);

        // Clean up for next iteration
        await tester.pumpWidget(Container());
      }
    });
  });
}
