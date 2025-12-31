import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_config.dart';

void main() {
  group('Tab Switching Simple Tests', () {
    setUp(() async {
      await TestConfig.initializeMinimal();
    });

    testWidgets('should render TabBar with tabs', (WidgetTester tester) async {
      await TestUtils.pumpWidgetWithTimeout(
        tester,
        MaterialApp(
          home: DefaultTabController(
            length: 4,
            child: Scaffold(
              appBar: AppBar(
                bottom: const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Raporlar'),
                    Tab(text: 'Nakit akışı'),
                    Tab(text: 'Harcama'),
                    Tab(text: 'Kredi'),
                  ],
                ),
              ),
              body: const TabBarView(
                children: [
                  Center(child: Text('Genel Bakış')),
                  Center(child: Text('Gelir vs Gider')),
                  Center(child: Text('Harcama Analizi')),
                  Center(child: Text('Kredi Kartları')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Raporlar'), findsOneWidget);
      expect(find.text('Nakit akışı'), findsOneWidget);
      expect(find.text('Harcama'), findsOneWidget);
      expect(find.text('Kredi'), findsOneWidget);
      expect(find.text('Genel Bakış'), findsOneWidget);
    });

    testWidgets('should switch tabs when tapped', (WidgetTester tester) async {
      await TestUtils.pumpWidgetWithTimeout(
        tester,
        MaterialApp(
          home: DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Tab 1'),
                    Tab(text: 'Tab 2'),
                    Tab(text: 'Tab 3'),
                  ],
                ),
              ),
              body: const TabBarView(
                children: [
                  Center(child: Text('Content 1')),
                  Center(child: Text('Content 2')),
                  Center(child: Text('Content 3')),
                ],
              ),
            ),
          ),
        ),
      );

      // Initially should show first tab content
      expect(find.text('Content 1'), findsOneWidget);

      // Tap second tab
      await tester.tap(find.text('Tab 2'));
      await tester.pumpAndSettle();

      // Should show second tab content
      expect(find.text('Content 2'), findsOneWidget);

      // Tap third tab
      await tester.tap(find.text('Tab 3'));
      await tester.pumpAndSettle();

      // Should show third tab content
      expect(find.text('Content 3'), findsOneWidget);
    });

    testWidgets('should handle empty tab content', (WidgetTester tester) async {
      await TestUtils.pumpWidgetWithTimeout(
        tester,
        MaterialApp(
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Empty Tab'),
                    Tab(text: 'Content Tab'),
                  ],
                ),
              ),
              body: const TabBarView(
                children: [
                  Center(child: Text('Veri bulunamadı')),
                  Center(child: Text('İçerik mevcut')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Veri bulunamadı'), findsOneWidget);

      await tester.tap(find.text('Content Tab'));
      await tester.pumpAndSettle();

      expect(find.text('İçerik mevcut'), findsOneWidget);
    });

    testWidgets('should render scrollable TabBar', (WidgetTester tester) async {
      await TestUtils.pumpWidgetWithTimeout(
        tester,
        MaterialApp(
          home: DefaultTabController(
            length: 6,
            child: Scaffold(
              appBar: AppBar(
                bottom: const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Very Long Tab Name 1'),
                    Tab(text: 'Very Long Tab Name 2'),
                    Tab(text: 'Very Long Tab Name 3'),
                    Tab(text: 'Very Long Tab Name 4'),
                    Tab(text: 'Very Long Tab Name 5'),
                    Tab(text: 'Very Long Tab Name 6'),
                  ],
                ),
              ),
              body: const TabBarView(
                children: [
                  Text('Content 1'),
                  Text('Content 2'),
                  Text('Content 3'),
                  Text('Content 4'),
                  Text('Content 5'),
                  Text('Content 6'),
                ],
              ),
            ),
          ),
        ),
      );

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.isScrollable, isTrue);
      expect(find.text('Very Long Tab Name 1'), findsOneWidget);
    });

    testWidgets('should maintain tab state', (WidgetTester tester) async {
      int counter1 = 0;
      int counter2 = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Counter 1'),
                    Tab(text: 'Counter 2'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  StatefulBuilder(
                    builder: (context, setState) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Counter 1: $counter1'),
                        ElevatedButton(
                          onPressed: () => setState(() => counter1++),
                          child: const Text('Increment 1'),
                        ),
                      ],
                    ),
                  ),
                  StatefulBuilder(
                    builder: (context, setState) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Counter 2: $counter2'),
                        ElevatedButton(
                          onPressed: () => setState(() => counter2++),
                          child: const Text('Increment 2'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Increment counter in first tab
      await tester.tap(find.text('Increment 1'));
      await tester.pump();
      expect(find.text('Counter 1: 1'), findsOneWidget);

      // Switch to second tab
      await tester.tap(find.text('Counter 2'));
      await tester.pumpAndSettle();

      // Increment counter in second tab
      await tester.tap(find.text('Increment 2'));
      await tester.pump();
      expect(find.text('Counter 2: 1'), findsOneWidget);

      // Switch back to first tab
      await tester.tap(find.text('Counter 1'));
      await tester.pumpAndSettle();

      // First tab state should be maintained
      expect(find.text('Counter 1: 1'), findsOneWidget);
    });
  });
}