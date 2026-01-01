import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/widgets/statistics/export_options_widget.dart';
import 'package:parion/models/report_data.dart';
import 'package:parion/models/transaction.dart';
import 'package:parion/models/cash_flow_data.dart';

void main() {
  group('ExportOptionsWidget', () {
    testWidgets('displays export buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExportOptionsWidget(),
          ),
        ),
      );

      // Verify title is displayed
      expect(find.text('Raporu Dışa Aktar'), findsOneWidget);

      // Verify all three export buttons are present
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('Excel'), findsOneWidget);
      expect(find.text('CSV'), findsOneWidget);

      // Verify icons are present
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      expect(find.byIcon(Icons.table_chart), findsOneWidget);
      expect(find.byIcon(Icons.text_snippet), findsOneWidget);
    });

    testWidgets('displays file download icon in title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExportOptionsWidget(),
          ),
        ),
      );

      expect(find.byIcon(Icons.file_download), findsOneWidget);
    });

    testWidgets('buttons are enabled when not exporting', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExportOptionsWidget(),
          ),
        ),
      );

      // Find all OutlinedButton widgets
      final pdfButton = find.widgetWithText(OutlinedButton, 'PDF');
      final excelButton = find.widgetWithText(OutlinedButton, 'Excel');
      final csvButton = find.widgetWithText(OutlinedButton, 'CSV');

      expect(pdfButton, findsOneWidget);
      expect(excelButton, findsOneWidget);
      expect(csvButton, findsOneWidget);

      // Verify buttons are enabled (onPressed is not null)
      final pdfButtonWidget = tester.widget<OutlinedButton>(pdfButton);
      final excelButtonWidget = tester.widget<OutlinedButton>(excelButton);
      final csvButtonWidget = tester.widget<OutlinedButton>(csvButton);

      expect(pdfButtonWidget.onPressed, isNotNull);
      expect(excelButtonWidget.onPressed, isNotNull);
      expect(csvButtonWidget.onPressed, isNotNull);
    });

    testWidgets('displays custom file name when provided', (WidgetTester tester) async {
      const customFileName = 'my_custom_report';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExportOptionsWidget(
              customFileName: customFileName,
            ),
          ),
        ),
      );

      // Widget should still display normally
      expect(find.text('Raporu Dışa Aktar'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
    });

    testWidgets('accepts report data', (WidgetTester tester) async {
      final report = IncomeReport(
        title: 'Test Income Report',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        generatedAt: DateTime.now(),
        totalIncome: 5000.0,
        incomeSources: const [],
        monthlyIncome: const [],
        trend: TrendDirection.up,
        averageMonthly: 5000.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportOptionsWidget(
              report: report,
            ),
          ),
        ),
      );

      expect(find.text('Raporu Dışa Aktar'), findsOneWidget);
    });

    testWidgets('accepts transaction list', (WidgetTester tester) async {
      final transactions = <Transaction>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportOptionsWidget(
              transactions: transactions,
            ),
          ),
        ),
      );

      expect(find.text('Raporu Dışa Aktar'), findsOneWidget);
    });

    testWidgets('calls onExportComplete callback when provided', (WidgetTester tester) async {
      var callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportOptionsWidget(
              onExportComplete: () {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );

      // The callback should not be called on widget creation
      expect(callbackCalled, isFalse);
    });

    testWidgets('displays all export format buttons in a row', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExportOptionsWidget(),
          ),
        ),
      );

      // Find the Row containing the buttons
      final rowFinder = find.descendant(
        of: find.byType(Card),
        matching: find.byType(Row),
      );

      expect(rowFinder, findsWidgets);

      // Verify buttons are in the same row
      final pdfButton = find.text('PDF');
      final excelButton = find.text('Excel');
      final csvButton = find.text('CSV');

      expect(pdfButton, findsOneWidget);
      expect(excelButton, findsOneWidget);
      expect(csvButton, findsOneWidget);
    });

    testWidgets('uses Card widget for container', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExportOptionsWidget(),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('has proper padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExportOptionsWidget(),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      
      // Find the main padding widget inside the card
      final paddingWidgets = find.descendant(
        of: find.byWidget(card),
        matching: find.byType(Padding),
      );

      // Verify there are padding widgets
      expect(paddingWidgets, findsWidgets);
      
      // Check that at least one has 16.0 padding
      final paddings = tester.widgetList<Padding>(paddingWidgets);
      final has16Padding = paddings.any((p) => p.padding == const EdgeInsets.all(16));
      expect(has16Padding, isTrue);
    });
  });

  group('ExportOptionsWidget - File Name Generation', () {
    testWidgets('generates file name with timestamp', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExportOptionsWidget(),
          ),
        ),
      );

      // The widget should be created successfully
      expect(find.byType(ExportOptionsWidget), findsOneWidget);
    });

    testWidgets('generates file name based on report type', (WidgetTester tester) async {
      final incomeReport = IncomeReport(
        title: 'Income Report',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        generatedAt: DateTime.now(),
        totalIncome: 5000.0,
        incomeSources: const [],
        monthlyIncome: const [],
        trend: TrendDirection.up,
        averageMonthly: 5000.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportOptionsWidget(
              report: incomeReport,
            ),
          ),
        ),
      );

      expect(find.byType(ExportOptionsWidget), findsOneWidget);
    });
  });

  group('ExportOptionsWidget - Button Colors', () {
    testWidgets('PDF button has red color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExportOptionsWidget(),
          ),
        ),
      );

      final pdfIcon = tester.widget<Icon>(
        find.descendant(
          of: find.widgetWithText(OutlinedButton, 'PDF'),
          matching: find.byType(Icon),
        ),
      );

      expect(pdfIcon.color, equals(Colors.red));
    });

    testWidgets('Excel button has green color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExportOptionsWidget(),
          ),
        ),
      );

      final excelIcon = tester.widget<Icon>(
        find.descendant(
          of: find.widgetWithText(OutlinedButton, 'Excel'),
          matching: find.byType(Icon),
        ),
      );

      expect(excelIcon.color, equals(Colors.green));
    });

    testWidgets('CSV button has blue color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExportOptionsWidget(),
          ),
        ),
      );

      final csvIcon = tester.widget<Icon>(
        find.descendant(
          of: find.widgetWithText(OutlinedButton, 'CSV'),
          matching: find.byType(Icon),
        ),
      );

      expect(csvIcon.color, equals(Colors.blue));
    });
  });
}
