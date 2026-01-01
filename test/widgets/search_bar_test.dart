import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/widgets/statistics/search_bar.dart';

void main() {
  group('StatisticsSearchBar Widget Tests', () {
    testWidgets('should display search bar with hint text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsSearchBar(
              searchQuery: '',
              onSearchChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('İşlem veya kategori ara...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should display custom hint text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsSearchBar(
              searchQuery: '',
              onSearchChanged: (_) {},
              hintText: 'Özel arama metni',
            ),
          ),
        ),
      );

      expect(find.text('Özel arama metni'), findsOneWidget);
    });

    testWidgets('should show clear button when text is entered',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsSearchBar(
              searchQuery: '',
              onSearchChanged: (_) {},
            ),
          ),
        ),
      );

      // Initially no clear button
      expect(find.byIcon(Icons.clear), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Clear button should appear
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('should call onSearchChanged when text changes',
        (WidgetTester tester) async {
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsSearchBar(
              searchQuery: '',
              onSearchChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test query');
      
      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(changedValue, equals('test query'));
    });

    testWidgets('should clear text when clear button is pressed',
        (WidgetTester tester) async {
      String currentQuery = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsSearchBar(
              searchQuery: '',
              onSearchChanged: (value) {
                currentQuery = value;
              },
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Text should be cleared
      expect(find.text('test'), findsNothing);
      expect(currentQuery, equals(''));
    });

    testWidgets('should call onClear callback when clear button is pressed',
        (WidgetTester tester) async {
      bool clearCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsSearchBar(
              searchQuery: '',
              onSearchChanged: (_) {},
              onClear: () {
                clearCalled = true;
              },
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(clearCalled, isTrue);
    });

    testWidgets('should show loading indicator during debounce',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsSearchBar(
              searchQuery: '',
              onSearchChanged: (_) {},
              debounceMilliseconds: 500,
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Loading indicator should appear
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for debounce to complete
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Loading indicator should disappear
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should update when searchQuery prop changes',
        (WidgetTester tester) async {
      String searchQuery = '';

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    StatisticsSearchBar(
                      searchQuery: searchQuery,
                      onSearchChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          searchQuery = 'external update';
                        });
                      },
                      child: const Text('Update'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Tap button to update externally
      await tester.tap(find.text('Update'));
      await tester.pump();

      // TextField should show updated value
      expect(find.text('external update'), findsOneWidget);
    });

    testWidgets('should have proper styling in light mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: StatisticsSearchBar(
              searchQuery: '',
              onSearchChanged: (_) {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(TextField),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.white));
      expect(decoration.borderRadius, isNotNull);
    });

    testWidgets('should have proper styling in dark mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: StatisticsSearchBar(
              searchQuery: '',
              onSearchChanged: (_) {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(TextField),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFF1C1C1E)));
    });

    testWidgets('should debounce multiple rapid changes',
        (WidgetTester tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsSearchBar(
              searchQuery: '',
              onSearchChanged: (_) {
                callCount++;
              },
              debounceMilliseconds: 300,
            ),
          ),
        ),
      );

      // Enter text multiple times rapidly
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byType(TextField), 'ab');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump(const Duration(milliseconds: 50));

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      // Should only be called once after debounce
      expect(callCount, equals(1));
    });
  });
}
