import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/widgets/statistics/cash_flow_tab.dart';
import '../test_setup.dart';

void main() {
  setUpAll(() async {
    await TestSetup.initializeTestEnvironment();
  });

  setUp(() async {
    await TestSetup.setupTest();
  });

  tearDown(() async {
    await TestSetup.tearDownTest();
  });

  tearDownAll(() async {
    await TestSetup.cleanupTestEnvironment();
  });

  group('CashFlowTab Widget Tests', () {
    testWidgets('should display loading indicator initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        TestSetup.createTestWidget(
          CashFlowTab(
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 12, 31),
          ),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error message when data loading fails',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        TestSetup.createTestWidget(
          CashFlowTab(
            startDate: DateTime(2024, 12, 31), // Invalid: end before start
            endDate: DateTime(2024, 1, 1),
          ),
        ),
      );

      // Wait for the future to complete
      await tester.pumpAndSettle();

      // Should show error icon
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Tekrar Dene'), findsOneWidget);
    });

    testWidgets('should display error or data after loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        TestSetup.createTestWidget(
          CashFlowTab(
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 12, 31),
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Should either show error or have loaded data (not loading anymore)
      expect(find.byType(CircularProgressIndicator), findsNothing);
      
      // Should have either error icon or refresh indicator
      final hasError = find.byIcon(Icons.error_outline).evaluate().isNotEmpty;
      final hasRefresh = find.byType(RefreshIndicator).evaluate().isNotEmpty;
      
      expect(hasError || hasRefresh, isTrue);
    });

    testWidgets('should update when date range changes',
        (WidgetTester tester) async {
      final startDate1 = DateTime(2024, 1, 1);
      final endDate1 = DateTime(2024, 6, 30);
      final startDate2 = DateTime(2024, 7, 1);
      final endDate2 = DateTime(2024, 12, 31);

      await tester.pumpWidget(
        TestSetup.createTestWidget(
          CashFlowTab(
            startDate: startDate1,
            endDate: endDate1,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Update with new dates
      await tester.pumpWidget(
        TestSetup.createTestWidget(
          CashFlowTab(
            startDate: startDate2,
            endDate: endDate2,
          ),
        ),
      );

      // Should show loading again
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should create widget with all required parameters',
        (WidgetTester tester) async {
      final widget = CashFlowTab(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        walletId: 'test-wallet',
        category: 'test-category',
      );

      expect(widget.startDate, DateTime(2024, 1, 1));
      expect(widget.endDate, DateTime(2024, 12, 31));
      expect(widget.walletId, 'test-wallet');
      expect(widget.category, 'test-category');
    });

    testWidgets('should handle null optional parameters',
        (WidgetTester tester) async {
      final widget = CashFlowTab(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );

      expect(widget.walletId, isNull);
      expect(widget.category, isNull);
    });
  });
}
