import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/widgets/statistics/paginated_list_view.dart';

void main() {
  group('PaginatedListView', () {
    testWidgets('displays initial page of items', (WidgetTester tester) async {
      final items = List.generate(50, (index) => 'Item $index');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedListView<String>(
              items: items,
              itemsPerPage: 10,
              itemBuilder: (context, item, index) {
                return ListTile(
                  key: Key(item),
                  title: Text(item),
                );
              },
            ),
          ),
        ),
      );

      // Should display first 10 items
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 9'), findsOneWidget);
      expect(find.text('Item 10'), findsNothing);

      // Should show load more button
      expect(find.text('Daha Fazla Yükle'), findsOneWidget);
    });

    testWidgets('loads more items when button is tapped', (WidgetTester tester) async {
      final items = List.generate(50, (index) => 'Item $index');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedListView<String>(
              items: items,
              itemsPerPage: 10,
              itemBuilder: (context, item, index) {
                return ListTile(
                  key: Key(item),
                  title: Text(item),
                );
              },
            ),
          ),
        ),
      );

      // Scroll to and tap load more button
      await tester.ensureVisible(find.text('Daha Fazla Yükle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daha Fazla Yükle'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should now display 20 items
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 19'), findsOneWidget);
      expect(find.text('Item 20'), findsNothing);
    });

    testWidgets('hides load more button when all items are displayed', (WidgetTester tester) async {
      final items = List.generate(15, (index) => 'Item $index');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedListView<String>(
              items: items,
              itemsPerPage: 10,
              itemBuilder: (context, item, index) {
                return ListTile(
                  key: Key(item),
                  title: Text(item),
                );
              },
            ),
          ),
        ),
      );

      // Load more to show all items
      await tester.ensureVisible(find.text('Daha Fazla Yükle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daha Fazla Yükle'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should display all 15 items
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 14'), findsOneWidget);

      // Load more button should be gone
      expect(find.text('Daha Fazla Yükle'), findsNothing);

      // Should show completion message
      expect(find.text('Tüm öğeler gösteriliyor'), findsOneWidget);
    });

    testWidgets('displays empty widget when no items', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedListView<String>(
              items: const [],
              itemsPerPage: 10,
              itemBuilder: (context, item, index) {
                return ListTile(title: Text(item));
              },
              emptyWidget: const Text('No items found'),
            ),
          ),
        ),
      );

      expect(find.text('No items found'), findsOneWidget);
      expect(find.text('Daha Fazla Yükle'), findsNothing);
    });

    testWidgets('displays item count', (WidgetTester tester) async {
      final items = List.generate(50, (index) => 'Item $index');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedListView<String>(
              items: items,
              itemsPerPage: 10,
              showItemCount: true,
              itemBuilder: (context, item, index) {
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );

      expect(find.text('10 / 50 öğe gösteriliyor'), findsOneWidget);
    });

    testWidgets('shows loading indicator while loading', (WidgetTester tester) async {
      final items = List.generate(50, (index) => 'Item $index');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedListView<String>(
              items: items,
              itemsPerPage: 10,
              itemBuilder: (context, item, index) {
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );

      // Tap load more
      await tester.ensureVisible(find.text('Daha Fazla Yükle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daha Fazla Yükle'), warnIfMissed: false);
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Yükleniyor...'), findsOneWidget);
      
      // Wait for loading to complete
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    });
  });

  group('StatisticsPaginatedTable', () {
    testWidgets('displays table with headers and rows', (WidgetTester tester) async {
      final headers = ['Column 1', 'Column 2', 'Column 3'];
      final rows = List.generate(
        20,
        (index) => ['Row $index Col 1', 'Row $index Col 2', 'Row $index Col 3'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsPaginatedTable(
              headers: headers,
              rows: rows,
              rowsPerPage: 5,
            ),
          ),
        ),
      );

      // Should display headers
      expect(find.text('Column 1'), findsOneWidget);
      expect(find.text('Column 2'), findsOneWidget);
      expect(find.text('Column 3'), findsOneWidget);

      // Should display first 5 rows
      expect(find.text('Row 0 Col 1'), findsOneWidget);
      expect(find.text('Row 4 Col 1'), findsOneWidget);
      expect(find.text('Row 5 Col 1'), findsNothing);
    });

    testWidgets('navigates to next page', (WidgetTester tester) async {
      final headers = ['Column 1'];
      final rows = List.generate(20, (index) => ['Row $index']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsPaginatedTable(
              headers: headers,
              rows: rows,
              rowsPerPage: 5,
            ),
          ),
        ),
      );

      // Tap next page button
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      // Should display rows 5-9
      expect(find.text('Row 5'), findsOneWidget);
      expect(find.text('Row 9'), findsOneWidget);
      expect(find.text('Row 0'), findsNothing);
      expect(find.text('Row 10'), findsNothing);
    });

    testWidgets('navigates to previous page', (WidgetTester tester) async {
      final headers = ['Column 1'];
      final rows = List.generate(20, (index) => ['Row $index']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsPaginatedTable(
              headers: headers,
              rows: rows,
              rowsPerPage: 5,
            ),
          ),
        ),
      );

      // Go to next page first
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      // Then go back
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();

      // Should display rows 0-4 again
      expect(find.text('Row 0'), findsOneWidget);
      expect(find.text('Row 4'), findsOneWidget);
      expect(find.text('Row 5'), findsNothing);
    });

    testWidgets('displays page information', (WidgetTester tester) async {
      final headers = ['Column 1'];
      final rows = List.generate(20, (index) => ['Row $index']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsPaginatedTable(
              headers: headers,
              rows: rows,
              rowsPerPage: 5,
            ),
          ),
        ),
      );

      expect(find.text('Sayfa 1 / 4'), findsOneWidget);
    });

    testWidgets('disables previous button on first page', (WidgetTester tester) async {
      final headers = ['Column 1'];
      final rows = List.generate(20, (index) => ['Row $index']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsPaginatedTable(
              headers: headers,
              rows: rows,
              rowsPerPage: 5,
            ),
          ),
        ),
      );

      final previousButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_left),
      );

      expect(previousButton.onPressed, isNull);
    });

    testWidgets('disables next button on last page', (WidgetTester tester) async {
      final headers = ['Column 1'];
      final rows = List.generate(10, (index) => ['Row $index']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsPaginatedTable(
              headers: headers,
              rows: rows,
              rowsPerPage: 5,
            ),
          ),
        ),
      );

      // Go to last page
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      final nextButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );

      expect(nextButton.onPressed, isNull);
    });

    testWidgets('displays empty message when no rows', (WidgetTester tester) async {
      final headers = ['Column 1'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsPaginatedTable(
              headers: headers,
              rows: const [],
              rowsPerPage: 5,
            ),
          ),
        ),
      );

      expect(find.text('Gösterilecek veri bulunamadı'), findsOneWidget);
    });
  });
}
