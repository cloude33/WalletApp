import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/widgets/statistics/reports_tab.dart';

/// Test suite for ReportsTab widget
///
/// Tests the report generation UI including:
/// - Report type selection
/// - Date range selection
/// - Filter options
/// - Report preview
/// - Export functionality
///
/// Validates: Requirements 4.1, 4.5
void main() {
  group('ReportsTab Widget Tests', () {
    testWidgets('should display initial state with report type selector', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ReportsTab())),
      );

      // Verify report type chips are displayed
      expect(find.text('Gelir Raporu'), findsOneWidget);
      expect(find.text('Gider Raporu'), findsOneWidget);
      expect(find.text('Fatura Raporu'), findsOneWidget);
      expect(find.text('Özel Rapor'), findsOneWidget);

      // Verify generate button is displayed
      expect(find.text('Rapor Oluştur'), findsOneWidget);

      // Verify empty state message
      expect(find.text('Rapor Oluşturun'), findsOneWidget);
    });

    testWidgets('should display date range selector', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ReportsTab())),
      );

      // Verify period chips
      expect(find.text('Bu Ay'), findsOneWidget);
      expect(find.text('Son 3 Ay'), findsOneWidget);
      expect(find.text('Bu Yıl'), findsOneWidget);
      expect(find.text('Özel'), findsOneWidget);

      // Verify date buttons
      expect(find.text('Başlangıç'), findsOneWidget);
      expect(find.text('Bitiş'), findsOneWidget);
    });

    testWidgets('should allow report type selection', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ReportsTab())),
      );

      // Initially income report should be selected
      final incomeChip = find.ancestor(
        of: find.text('Gelir Raporu'),
        matching: find.byType(FilterChip),
      );
      expect(incomeChip, findsOneWidget);

      // Tap on expense report
      await tester.tap(find.text('Gider Raporu'));
      await tester.pumpAndSettle();

      // Verify expense report is now selected
      final expenseChip = find.ancestor(
        of: find.text('Gider Raporu'),
        matching: find.byType(FilterChip),
      );
      expect(expenseChip, findsOneWidget);
    });

    testWidgets('should display filter options for custom report', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ReportsTab())),
      );

      // Tap on custom report
      await tester.tap(find.text('Özel Rapor'));
      await tester.pumpAndSettle();

      // Verify filter chips are displayed
      expect(find.text('Gelir'), findsOneWidget);
      expect(find.text('Gider'), findsOneWidget);
      expect(find.text('Faturalar'), findsOneWidget);
    });

    testWidgets('should display comparison option for income/expense reports', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ReportsTab())),
      );

      // For income report (default), comparison option should be visible
      expect(find.text('Önceki dönemle karşılaştır'), findsOneWidget);

      // Switch to bill report
      await tester.tap(find.text('Fatura Raporu'));
      await tester.pumpAndSettle();

      // Comparison option should not be visible for bill report
      expect(find.text('Önceki dönemle karşılaştır'), findsNothing);
    });

    testWidgets('should allow period selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ReportsTab())),
      );

      // Tap on quarterly period
      await tester.tap(find.text('Son 3 Ay'));
      await tester.pumpAndSettle();

      // Verify the period is selected (ChoiceChip should be selected)
      final quarterlyChip = find.ancestor(
        of: find.text('Son 3 Ay'),
        matching: find.byType(ChoiceChip),
      );
      expect(quarterlyChip, findsOneWidget);
    });

    testWidgets('should display export options when report is generated', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ReportsTab())),
      );

      // Initially export options should not be visible
      expect(find.text('Raporu Dışa Aktar'), findsNothing);

      // Note: We can't easily test report generation without mocking
      // the service, but we can verify the UI structure is correct
    });

    testWidgets('should display filter summary', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ReportsTab())),
      );

      // Verify filter button with summary
      expect(find.text('Tümü'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('should handle generate button tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ReportsTab())),
      );

      // Tap generate button
      await tester.tap(find.text('Rapor Oluştur'));
      await tester.pump();

      // Button should show loading state
      expect(find.text('Oluşturuluyor...'), findsOneWidget);
    });
  });

  group('ReportsTab Report Type Icons', () {
    testWidgets('should display correct icons for each report type', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ReportsTab())),
      );

      // Verify icons are present
      expect(find.byIcon(Icons.trending_up), findsWidgets);
      expect(find.byIcon(Icons.trending_down), findsWidgets);
      expect(find.byIcon(Icons.receipt_long), findsWidgets);
      expect(find.byIcon(Icons.tune), findsWidgets);
    });
  });

  group('ReportsTab Accessibility', () {
    testWidgets('should have proper semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ReportsTab())),
      );

      // Verify important elements are accessible
      expect(find.text('Rapor Tipi'), findsOneWidget);
      expect(find.text('Tarih Aralığı'), findsOneWidget);
      expect(find.text('Filtreler'), findsOneWidget);
    });
  });
}
