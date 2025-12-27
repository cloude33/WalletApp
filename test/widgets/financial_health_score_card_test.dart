import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/widgets/statistics/financial_health_score_card.dart';
import 'package:money/models/asset_analysis.dart';

/// Tests for FinancialHealthScoreCard widget
/// 
/// Validates:
/// - Widget renders correctly
/// - Displays all score components
/// - Shows recommendations
/// - Requirement 5.5: Financial health score display
void main() {
  group('FinancialHealthScoreCard', () {
    testWidgets('renders with all score components', (WidgetTester tester) async {
      final healthScore = FinancialHealthScore(
        liquidityScore: 75.0,
        debtManagementScore: 80.0,
        savingsScore: 65.0,
        investmentScore: 50.0,
        overallScore: 70.0,
        recommendations: [
          'Test recommendation 1',
          'Test recommendation 2',
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinancialHealthScoreCard(
              healthScore: healthScore,
            ),
          ),
        ),
      );

      // Verify title is displayed
      expect(find.text('Finansal Sağlık Skoru'), findsOneWidget);

      // Verify overall score is displayed
      expect(find.text('70/100'), findsOneWidget);

      // Verify individual scores are displayed
      expect(find.text('Likidite'), findsOneWidget);
      expect(find.text('Borç Yönetimi'), findsOneWidget);
      expect(find.text('Tasarruf'), findsOneWidget);
      expect(find.text('Yatırım'), findsOneWidget);

      // Verify recommendations section is displayed
      expect(find.text('Öneriler'), findsOneWidget);
      expect(find.text('Test recommendation 1'), findsOneWidget);
      expect(find.text('Test recommendation 2'), findsOneWidget);
    });

    testWidgets('displays correct score label for excellent score', (WidgetTester tester) async {
      final healthScore = FinancialHealthScore(
        liquidityScore: 90.0,
        debtManagementScore: 90.0,
        savingsScore: 90.0,
        investmentScore: 90.0,
        overallScore: 90.0,
        recommendations: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinancialHealthScoreCard(
              healthScore: healthScore,
            ),
          ),
        ),
      );

      expect(find.text('Mükemmel'), findsOneWidget);
    });

    testWidgets('displays correct score label for good score', (WidgetTester tester) async {
      final healthScore = FinancialHealthScore(
        liquidityScore: 70.0,
        debtManagementScore: 70.0,
        savingsScore: 70.0,
        investmentScore: 70.0,
        overallScore: 70.0,
        recommendations: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinancialHealthScoreCard(
              healthScore: healthScore,
            ),
          ),
        ),
      );

      expect(find.text('İyi'), findsOneWidget);
    });
  });
}
