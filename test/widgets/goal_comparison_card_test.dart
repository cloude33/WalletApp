import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/goal_comparison.dart';
import 'package:parion/widgets/statistics/goal_comparison_card.dart';

void main() {
  group('GoalComparisonCard Widget Tests', () {
    testWidgets('displays empty state when no goals', (WidgetTester tester) async {
      final summary = GoalComparisonSummary(
        goals: [],
        totalGoals: 0,
        achievedGoals: 0,
        inProgressGoals: 0,
        overdueGoals: 0,
        overallAchievementRate: 0.0,
        totalTargetAmount: 0.0,
        totalActualAmount: 0.0,
        totalRemainingAmount: 0.0,
        insights: ['Henüz hedef belirlenmemiş'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoalComparisonCard(summary: summary),
          ),
        ),
      );

      expect(find.text('Hedef Karşılaştırma'), findsOneWidget);
      expect(find.text('Henüz hedef belirlenmemiş'), findsOneWidget);
      expect(find.text('%0.0'), findsOneWidget);
    });

    testWidgets('displays goal statistics correctly', (WidgetTester tester) async {
      final summary = GoalComparisonSummary(
        goals: [],
        totalGoals: 5,
        achievedGoals: 2,
        inProgressGoals: 2,
        overdueGoals: 1,
        overallAchievementRate: 60.0,
        totalTargetAmount: 10000.0,
        totalActualAmount: 6000.0,
        totalRemainingAmount: 4000.0,
        insights: ['İyi gidiyorsunuz!'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoalComparisonCard(summary: summary),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget); // Total goals
      expect(find.text('2'), findsNWidgets(2)); // Achieved and in-progress
      expect(find.text('1'), findsOneWidget); // Overdue
      expect(find.text('%60.0'), findsOneWidget);
    });

    testWidgets('displays individual goal with progress', (WidgetTester tester) async {
      final goal = GoalComparison(
        goalId: '1',
        goalName: 'Tatil Fonu',
        targetAmount: 5000.0,
        actualAmount: 3000.0,
        remainingAmount: 2000.0,
        achievementPercentage: 60.0,
        isAchieved: false,
        deadline: DateTime.now().add(const Duration(days: 30)),
        daysRemaining: 30,
        isOverdue: false,
        status: GoalStatus.inProgress,
      );

      final summary = GoalComparisonSummary(
        goals: [goal],
        totalGoals: 1,
        achievedGoals: 0,
        inProgressGoals: 1,
        overdueGoals: 0,
        overallAchievementRate: 60.0,
        totalTargetAmount: 5000.0,
        totalActualAmount: 3000.0,
        totalRemainingAmount: 2000.0,
        insights: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoalComparisonCard(summary: summary),
          ),
        ),
      );

      expect(find.text('Tatil Fonu'), findsOneWidget);
      expect(find.text('₺3000.00 / ₺5000.00'), findsOneWidget);
      expect(find.text('%60.0'), findsNWidgets(2)); // Overall + individual goal
      expect(find.text('30 gün kaldı'), findsOneWidget);
      expect(find.text('Devam Ediyor'), findsOneWidget);
    });

    testWidgets('displays achieved goal correctly', (WidgetTester tester) async {
      final goal = GoalComparison(
        goalId: '1',
        goalName: 'Acil Fon',
        targetAmount: 10000.0,
        actualAmount: 10000.0,
        remainingAmount: 0.0,
        achievementPercentage: 100.0,
        isAchieved: true,
        status: GoalStatus.achieved,
      );

      final summary = GoalComparisonSummary(
        goals: [goal],
        totalGoals: 1,
        achievedGoals: 1,
        inProgressGoals: 0,
        overdueGoals: 0,
        overallAchievementRate: 100.0,
        totalTargetAmount: 10000.0,
        totalActualAmount: 10000.0,
        totalRemainingAmount: 0.0,
        insights: ['1 hedef başarıyla tamamlandı! 🎉'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoalComparisonCard(summary: summary),
          ),
        ),
      );

      expect(find.text('Acil Fon'), findsOneWidget);
      expect(find.text('Tamamlandı'), findsOneWidget);
      expect(find.text('%100.0'), findsNWidgets(2)); // Overall + individual goal
      expect(find.text('1 hedef başarıyla tamamlandı! 🎉'), findsOneWidget);
    });

    testWidgets('displays overdue goal with warning', (WidgetTester tester) async {
      final goal = GoalComparison(
        goalId: '1',
        goalName: 'Araba Fonu',
        targetAmount: 50000.0,
        actualAmount: 30000.0,
        remainingAmount: 20000.0,
        achievementPercentage: 60.0,
        isAchieved: false,
        deadline: DateTime.now().subtract(const Duration(days: 10)),
        daysRemaining: -10,
        isOverdue: true,
        status: GoalStatus.overdue,
      );

      final summary = GoalComparisonSummary(
        goals: [goal],
        totalGoals: 1,
        achievedGoals: 0,
        inProgressGoals: 0,
        overdueGoals: 1,
        overallAchievementRate: 60.0,
        totalTargetAmount: 50000.0,
        totalActualAmount: 30000.0,
        totalRemainingAmount: 20000.0,
        insights: ['⚠️ 1 hedefin süresi doldu. Gözden geçirmeniz önerilir.'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoalComparisonCard(summary: summary),
          ),
        ),
      );

      expect(find.text('Araba Fonu'), findsOneWidget);
      expect(find.text('Gecikmiş'), findsNWidgets(2)); // Stat card + status chip
      expect(find.text('Süre doldu (10 gün önce)'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsWidgets);
    });

    testWidgets('displays at-risk goal', (WidgetTester tester) async {
      final goal = GoalComparison(
        goalId: '1',
        goalName: 'Eğitim Fonu',
        targetAmount: 20000.0,
        actualAmount: 10000.0,
        remainingAmount: 10000.0,
        achievementPercentage: 50.0,
        isAchieved: false,
        deadline: DateTime.now().add(const Duration(days: 20)),
        daysRemaining: 20,
        isOverdue: false,
        status: GoalStatus.atRisk,
      );

      final summary = GoalComparisonSummary(
        goals: [goal],
        totalGoals: 1,
        achievedGoals: 0,
        inProgressGoals: 1,
        overdueGoals: 0,
        overallAchievementRate: 50.0,
        totalTargetAmount: 20000.0,
        totalActualAmount: 10000.0,
        totalRemainingAmount: 10000.0,
        insights: ['1 hedef risk altında. Hızlı aksiyon gerekebilir.'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoalComparisonCard(summary: summary),
          ),
        ),
      );

      expect(find.text('Eğitim Fonu'), findsOneWidget);
      expect(find.text('Risk Altında'), findsOneWidget);
      expect(find.text('1 hedef risk altında. Hızlı aksiyon gerekebilir.'), findsOneWidget);
    });

    testWidgets('calls onGoalTap when add button is pressed', (WidgetTester tester) async {
      bool tapped = false;
      
      final summary = GoalComparisonSummary(
        goals: [],
        totalGoals: 0,
        achievedGoals: 0,
        inProgressGoals: 0,
        overdueGoals: 0,
        overallAchievementRate: 0.0,
        totalTargetAmount: 0.0,
        totalActualAmount: 0.0,
        totalRemainingAmount: 0.0,
        insights: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoalComparisonCard(
              summary: summary,
              onGoalTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      expect(tapped, true);
    });

    testWidgets('displays multiple goals', (WidgetTester tester) async {
      final goals = [
        GoalComparison(
          goalId: '1',
          goalName: 'Hedef 1',
          targetAmount: 5000.0,
          actualAmount: 4000.0,
          remainingAmount: 1000.0,
          achievementPercentage: 80.0,
          isAchieved: false,
          status: GoalStatus.inProgress,
        ),
        GoalComparison(
          goalId: '2',
          goalName: 'Hedef 2',
          targetAmount: 10000.0,
          actualAmount: 10000.0,
          remainingAmount: 0.0,
          achievementPercentage: 100.0,
          isAchieved: true,
          status: GoalStatus.achieved,
        ),
        GoalComparison(
          goalId: '3',
          goalName: 'Hedef 3',
          targetAmount: 8000.0,
          actualAmount: 2000.0,
          remainingAmount: 6000.0,
          achievementPercentage: 25.0,
          isAchieved: false,
          status: GoalStatus.behindSchedule,
        ),
      ];

      final summary = GoalComparisonSummary(
        goals: goals,
        totalGoals: 3,
        achievedGoals: 1,
        inProgressGoals: 2,
        overdueGoals: 0,
        overallAchievementRate: 68.3,
        totalTargetAmount: 23000.0,
        totalActualAmount: 16000.0,
        totalRemainingAmount: 7000.0,
        insights: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GoalComparisonCard(summary: summary),
            ),
          ),
        ),
      );

      expect(find.text('Hedef 1'), findsOneWidget);
      expect(find.text('Hedef 2'), findsOneWidget);
      expect(find.text('Hedef 3'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(4)); // 3 goals + 1 overall
    });

    testWidgets('displays insights section', (WidgetTester tester) async {
      final summary = GoalComparisonSummary(
        goals: [],
        totalGoals: 3,
        achievedGoals: 2,
        inProgressGoals: 1,
        overdueGoals: 0,
        overallAchievementRate: 85.0,
        totalTargetAmount: 10000.0,
        totalActualAmount: 8500.0,
        totalRemainingAmount: 1500.0,
        insights: [
          'İyi gidiyorsunuz! Hedeflerinizin %85\'ini tamamladınız.',
          '2 hedef başarıyla tamamlandı! 🎉',
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GoalComparisonCard(summary: summary),
            ),
          ),
        ),
      );

      expect(find.text('İçgörüler'), findsOneWidget);
      expect(find.text('İyi gidiyorsunuz! Hedeflerinizin %85\'ini tamamladınız.'), findsOneWidget);
      expect(find.text('2 hedef başarıyla tamamlandı! 🎉'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsNWidgets(2));
    });
  });
}
