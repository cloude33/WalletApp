import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/widgets/statistics/kmh_summary_cards.dart';
import 'package:parion/widgets/statistics/kmh_utilization_indicator.dart';
import 'package:parion/widgets/statistics/kmh_interest_card.dart';

void main() {
  group('KMH Dashboard Components Tests', () {
    testWidgets('KmhSummaryCards displays all summary information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KmhSummaryCards(
                totalDebt: 5000.0,
                totalLimit: 10000.0,
                utilizationRate: 50.0,
                accountCount: 2,
              ),
            ),
          ),
        ),
      );

      // Verify title
      expect(find.text('KMH Özeti'), findsOneWidget);

      // Verify summary cards are displayed
      expect(find.text('Toplam Borç'), findsOneWidget);
      expect(find.text('Toplam Limit'), findsOneWidget);
      expect(find.text('Kullanım Oranı'), findsOneWidget);
      expect(find.text('Kalan Limit'), findsOneWidget);

      // Verify values are formatted correctly
      expect(find.textContaining('₺'), findsWidgets);
      expect(find.textContaining('5'), findsWidgets);
      expect(find.textContaining('10'), findsWidgets);
      expect(find.textContaining('50'), findsOneWidget); // Utilization rate
    });

    testWidgets('KmhSummaryCards shows correct utilization labels', (
      WidgetTester tester,
    ) async {
      // Test low utilization
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KmhSummaryCards(
                totalDebt: 1000.0,
                totalLimit: 10000.0,
                utilizationRate: 10.0,
                accountCount: 1,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Düşük'), findsOneWidget);

      // Test high utilization
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KmhSummaryCards(
                totalDebt: 8500.0,
                totalLimit: 10000.0,
                utilizationRate: 85.0,
                accountCount: 1,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Çok yüksek'), findsOneWidget);
    });

    testWidgets('KmhUtilizationIndicator displays progress bar correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KmhUtilizationIndicator(
              utilizationRate: 60.0,
              usedAmount: 6000.0,
              totalLimit: 10000.0,
              showLabel: true,
              showAmounts: true,
            ),
          ),
        ),
      );

      // Verify label is shown
      expect(find.text('Kullanım Oranı'), findsOneWidget);
      expect(find.textContaining('60'), findsWidgets);

      // Verify amounts are shown
      expect(find.textContaining('Kullanılan:'), findsOneWidget);
      expect(find.textContaining('Limit:'), findsOneWidget);
    });

    testWidgets(
      'KmhUtilizationIndicator shows correct color for different rates',
      (WidgetTester tester) async {
        // Test low utilization (blue)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: KmhUtilizationIndicator(
                utilizationRate: 20.0,
                usedAmount: 2000.0,
                totalLimit: 10000.0,
                showLabel: true,
              ),
            ),
          ),
        );

        expect(find.text('Düşük'), findsOneWidget);

        // Test high utilization (red)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: KmhUtilizationIndicator(
                utilizationRate: 90.0,
                usedAmount: 9000.0,
                totalLimit: 10000.0,
                showLabel: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Çok Yüksek'), findsOneWidget);
      },
    );

    testWidgets(
      'KmhInterestCard displays interest information when there is debt',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: KmhInterestCard(
                dailyInterest: 10.0,
                monthlyInterest: 300.0,
                annualInterest: 3650.0,
              ),
            ),
          ),
        );

        // Verify title
        expect(find.text('Faiz Bilgileri'), findsOneWidget);

        // Verify interest rows
        expect(find.text('Günlük Faiz'), findsOneWidget);
        expect(find.text('Aylık Faiz (Tahmini)'), findsOneWidget);
        expect(find.text('Yıllık Faiz (Tahmini)'), findsOneWidget);

        // Verify amounts are displayed
        expect(find.textContaining('10'), findsWidgets);
        expect(find.textContaining('300'), findsOneWidget);
        expect(find.textContaining('3'), findsWidgets);

        // Verify warning message
        expect(
          find.textContaining('Faiz tutarları günlük olarak hesaplanır'),
          findsOneWidget,
        );
      },
    );

    testWidgets('KmhInterestCard shows no interest message when debt is zero', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KmhInterestCard(
              dailyInterest: 0.0,
              monthlyInterest: 0.0,
              annualInterest: 0.0,
            ),
          ),
        ),
      );

      // Verify title
      expect(find.text('Faiz Bilgileri'), findsOneWidget);

      // Verify no interest message
      expect(find.text('Faiz tahakkuku bulunmamaktadır'), findsOneWidget);
      expect(
        find.textContaining('KMH hesaplarınızda borç bulunmadığı için'),
        findsOneWidget,
      );

      // Verify interest rows are not displayed
      expect(find.text('Günlük Faiz'), findsNothing);
      expect(find.text('Aylık Faiz (Tahmini)'), findsNothing);
      expect(find.text('Yıllık Faiz (Tahmini)'), findsNothing);
    });

    testWidgets('KmhUtilizationIndicator handles zero utilization', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KmhUtilizationIndicator(
              utilizationRate: 0.0,
              usedAmount: 0.0,
              totalLimit: 10000.0,
              showLabel: true,
            ),
          ),
        ),
      );

      expect(find.text('Borç Yok'), findsOneWidget);
      expect(find.textContaining('0'), findsWidgets);
    });

    testWidgets('KmhUtilizationIndicator handles 100% utilization', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KmhUtilizationIndicator(
              utilizationRate: 100.0,
              usedAmount: 10000.0,
              totalLimit: 10000.0,
              showLabel: true,
            ),
          ),
        ),
      );

      expect(find.text('Çok Yüksek'), findsOneWidget);
      expect(find.textContaining('100'), findsWidgets);
    });

    testWidgets('KmhSummaryCards handles zero debt correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KmhSummaryCards(
                totalDebt: 0.0,
                totalLimit: 10000.0,
                utilizationRate: 0.0,
                accountCount: 1,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Borç yok'), findsOneWidget);
      expect(find.textContaining('0'), findsWidgets);
    });

    testWidgets('KmhInterestCard displays correct subtitles', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KmhInterestCard(
              dailyInterest: 15.5,
              monthlyInterest: 465.0,
              annualInterest: 5657.5,
            ),
          ),
        ),
      );

      // Verify subtitles
      expect(find.text('Her gün tahakkuk eden'), findsOneWidget);
      expect(find.text('30 günlük projeksiyon'), findsOneWidget);
      expect(find.text('365 günlük projeksiyon'), findsOneWidget);
    });
  });
}
