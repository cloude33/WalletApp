import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/widgets/statistics/spending_tab.dart';

void main() {
  group('SpendingTab Widget Tests', () {
    testWidgets('should display loading indicator initially', (WidgetTester tester) async {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendingTab(
              startDate: startDate,
              endDate: endDate,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should complete loading and show content', (WidgetTester tester) async {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendingTab(
              startDate: startDate,
              endDate: endDate,
            ),
          ),
        ),
      );

      // Wait for the widget to finish loading
      await tester.pumpAndSettle();

      // Assert - Widget should complete loading and show some content
      // The loading indicator should be gone
      expect(find.byType(CircularProgressIndicator), findsNothing);
      
      // Should have the SpendingTab widget
      expect(find.byType(SpendingTab), findsOneWidget);
    });

    testWidgets('should rebuild when date range changes', (WidgetTester tester) async {
      // Arrange
      final startDate1 = DateTime(2024, 1, 1);
      final endDate1 = DateTime(2024, 1, 31);
      final startDate2 = DateTime(2024, 2, 1);
      final endDate2 = DateTime(2024, 2, 29);

      // Act - First render
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendingTab(
              key: const ValueKey('tab1'),
              startDate: startDate1,
              endDate: endDate1,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Update with new dates
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendingTab(
              key: const ValueKey('tab2'),
              startDate: startDate2,
              endDate: endDate2,
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert - Widget should rebuild with new key
      expect(find.byKey(const ValueKey('tab2')), findsOneWidget);
    });

    testWidgets('should accept optional categories filter', (WidgetTester tester) async {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      final categories = ['Market', 'Restoran'];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendingTab(
              startDate: startDate,
              endDate: endDate,
              categories: categories,
            ),
          ),
        ),
      );

      // Assert - Widget should render without errors
      expect(find.byType(SpendingTab), findsOneWidget);
    });

    testWidgets('should accept optional budgets parameter', (WidgetTester tester) async {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      final budgets = {
        'Market': 1000.0,
        'Restoran': 500.0,
      };

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendingTab(
              startDate: startDate,
              endDate: endDate,
              budgets: budgets,
            ),
          ),
        ),
      );

      // Assert - Widget should render without errors
      expect(find.byType(SpendingTab), findsOneWidget);
    });

    testWidgets('should render without errors', (WidgetTester tester) async {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendingTab(
              startDate: startDate,
              endDate: endDate,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Widget should render successfully
      expect(find.byType(SpendingTab), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('SpendingTab Integration Tests', () {
    testWidgets('should render complete widget tree', (WidgetTester tester) async {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendingTab(
              startDate: startDate,
              endDate: endDate,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Widget should render without throwing exceptions
      expect(tester.takeException(), isNull);
      expect(find.byType(SpendingTab), findsOneWidget);
    });
  });
}
