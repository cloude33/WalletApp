import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/models/transaction.dart';
import 'package:money/models/credit_card_transaction.dart';
import 'package:money/widgets/statistics/search_results.dart';

void main() {
  group('SearchResults Widget Tests', () {
    late List<Transaction> testTransactions;
    late List<CreditCardTransaction> testCreditCardTransactions;

    setUp(() {
      testTransactions = [
        Transaction(
          id: '1',
          amount: 100.0,
          description: 'Market alışverişi',
          category: 'Gıda',
          type: 'expense',
          date: DateTime(2024, 1, 15),
          walletId: 'wallet1',
        ),
        Transaction(
          id: '2',
          amount: 200.0,
          description: 'Maaş',
          category: 'Gelir',
          type: 'income',
          date: DateTime(2024, 1, 20),
          walletId: 'wallet1',
        ),
      ];

      testCreditCardTransactions = [
        CreditCardTransaction(
          id: 'cc1',
          amount: 150.0,
          description: 'Online alışveriş',
          category: 'Alışveriş',
          transactionDate: DateTime(2024, 1, 18),
          cardId: 'card1',
          installmentCount: 1,
          createdAt: DateTime(2024, 1, 18),
        ),
      ];
    });

    testWidgets('should not display when search query is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: testTransactions,
              searchQuery: '',
            ),
          ),
        ),
      );

      expect(find.byType(SearchResults), findsOneWidget);
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('should display empty state when no results found',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: const [],
              searchQuery: 'test query',
            ),
          ),
        ),
      );

      expect(find.text('Sonuç bulunamadı'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.textContaining('test query'), findsOneWidget);
    });

    testWidgets('should display result count', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: testTransactions,
              searchQuery: 'test',
            ),
          ),
        ),
      );

      expect(find.text('2 sonuç bulundu'), findsOneWidget);
    });

    testWidgets('should display transaction results',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: testTransactions,
              searchQuery: 'test',
            ),
          ),
        ),
      );

      expect(find.text('Market alışverişi'), findsOneWidget);
      expect(find.text('Maaş'), findsOneWidget);
      expect(find.text('Gıda'), findsOneWidget);
      expect(find.text('Gelir'), findsOneWidget);
    });

    testWidgets('should display credit card transaction results',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: testCreditCardTransactions,
              searchQuery: 'test',
            ),
          ),
        ),
      );

      expect(find.text('Online alışveriş'), findsOneWidget);
      expect(find.text('Alışveriş'), findsOneWidget);
      expect(find.byIcon(Icons.credit_card), findsOneWidget);
    });

    testWidgets('should display mixed results', (WidgetTester tester) async {
      final mixed = [...testTransactions, ...testCreditCardTransactions];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: mixed,
              searchQuery: 'test',
            ),
          ),
        ),
      );

      expect(find.text('3 sonuç bulundu'), findsOneWidget);
      expect(find.text('Market alışverişi'), findsOneWidget);
      expect(find.text('Online alışveriş'), findsOneWidget);
    });

    testWidgets('should show income with green color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: [testTransactions[1]], // Income transaction
              searchQuery: 'test',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.textContaining('+'), findsOneWidget);
    });

    testWidgets('should show expense with red color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: [testTransactions[0]], // Expense transaction
              searchQuery: 'test',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.trending_down), findsOneWidget);
      expect(find.textContaining('-'), findsOneWidget);
    });

    testWidgets('should limit results to 10', (WidgetTester tester) async {
      final manyTransactions = List.generate(
        15,
        (index) => Transaction(
          id: 'id$index',
          amount: 100.0,
          description: 'Transaction $index',
          category: 'Category',
          type: 'expense',
          date: DateTime(2024, 1, 15),
          walletId: 'wallet1',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SearchResults(
                results: manyTransactions,
                searchQuery: 'test',
              ),
            ),
          ),
        ),
      );

      expect(find.text('15 sonuç bulundu'), findsOneWidget);
      expect(find.text('+5 daha fazla sonuç'), findsOneWidget);
      
      // Should only display 10 items
      expect(find.byType(ListTile), findsNWidgets(10));
    });

    testWidgets('should call onResultTap when item is tapped',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: testTransactions,
              searchQuery: 'test',
              onResultTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile).first);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('should display formatted dates', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: testTransactions,
              searchQuery: 'test',
            ),
          ),
        ),
      );

      // Check if dates are displayed (format: dd MMM yyyy)
      expect(find.textContaining('15'), findsWidgets);
      expect(find.textContaining('20'), findsWidgets);
    });

    testWidgets('should display formatted amounts', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: testTransactions,
              searchQuery: 'test',
            ),
          ),
        ),
      );

      // Check if amounts are displayed with currency format
      expect(find.textContaining('100'), findsWidgets);
      expect(find.textContaining('200'), findsWidgets);
    });

    testWidgets('should have proper styling in light mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: SearchResults(
              results: testTransactions,
              searchQuery: 'test',
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );

      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.white));
    });

    testWidgets('should have proper styling in dark mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SearchResults(
              results: testTransactions,
              searchQuery: 'test',
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );

      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFF1C1C1E)));
    });

    testWidgets('should display search icon in header',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: testTransactions,
              searchQuery: 'test',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should display dividers between results',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: testTransactions,
              searchQuery: 'test',
            ),
          ),
        ),
      );

      // Should have dividers between items (n-1 dividers for n items)
      expect(find.byType(Divider), findsNWidgets(2)); // 1 header divider + 1 between items
    });
  });
}
