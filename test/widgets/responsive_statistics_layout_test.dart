import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/widgets/statistics/responsive_statistics_layout.dart';

void main() {
  group('ResponsiveStatisticsLayout', () {
    testWidgets('renders list layout on mobile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Scaffold(
              body: ResponsiveStatisticsLayout(
                children: [
                  Container(key: const Key('item1'), height: 100),
                  Container(key: const Key('item2'), height: 100),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('item1')), findsOneWidget);
      expect(find.byKey(const Key('item2')), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('renders grid layout on tablet when useGrid is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1000, 700)),
            child: Scaffold(
              body: ResponsiveStatisticsLayout(
                useGrid: true,
                children: [
                  Container(key: const Key('item1'), height: 100),
                  Container(key: const Key('item2'), height: 100),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('item1')), findsOneWidget);
      expect(find.byKey(const Key('item2')), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('ResponsiveCard', () {
    testWidgets('renders with default styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveCard(
              child: Text('Test Card'),
            ),
          ),
        ),
      );

      expect(find.text('Test Card'), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('applies custom color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveCard(
              color: Colors.red,
              child: Text('Test Card'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Test Card'),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.red);
    });
  });

  group('ResponsiveRow', () {
    testWidgets('renders as row on tablet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(700, 1000)),
            child: const Scaffold(
              body: ResponsiveRow(
                children: [
                  Text('Item 1'),
                  Text('Item 2'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('renders as column on mobile portrait', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: const Scaffold(
              body: ResponsiveRow(
                children: [
                  Text('Item 1'),
                  Text('Item 2'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });
  });

  group('ResponsiveChartContainer', () {
    testWidgets('renders chart with title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveChartContainer(
              title: 'Test Chart',
              chart: SizedBox(height: 200),
            ),
          ),
        ),
      );

      expect(find.text('Test Chart'), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders chart with subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveChartContainer(
              title: 'Test Chart',
              subtitle: 'Test Subtitle',
              chart: SizedBox(height: 200),
            ),
          ),
        ),
      );

      expect(find.text('Test Chart'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('renders chart with actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveChartContainer(
              title: 'Test Chart',
              chart: const SizedBox(height: 200),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test Chart'), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });
  });

  group('ResponsiveSummaryGrid', () {
    testWidgets('renders cards in grid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: const Scaffold(
              body: ResponsiveSummaryGrid(
                cards: [
                  Text('Card 1'),
                  Text('Card 2'),
                  Text('Card 3'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Card 1'), findsOneWidget);
      expect(find.text('Card 2'), findsOneWidget);
      expect(find.text('Card 3'), findsOneWidget);
    });

    testWidgets('adapts to screen size', (tester) async {
      // Mobile - 1 item per row
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: const Scaffold(
              body: ResponsiveSummaryGrid(
                cards: [
                  Text('Card 1'),
                  Text('Card 2'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Card 1'), findsOneWidget);
      expect(find.text('Card 2'), findsOneWidget);

      // Tablet - 2 items per row
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(700, 1000)),
            child: const Scaffold(
              body: ResponsiveSummaryGrid(
                cards: [
                  Text('Card 1'),
                  Text('Card 2'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Card 1'), findsOneWidget);
      expect(find.text('Card 2'), findsOneWidget);
    });
  });

  group('AdaptiveTabBar', () {
    testWidgets('renders tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Builder(
                    builder: (context) {
                      return AdaptiveTabBar(
                        controller: DefaultTabController.of(context),
                        tabs: const [
                          Tab(text: 'Tab 1'),
                          Tab(text: 'Tab 2'),
                          Tab(text: 'Tab 3'),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tab 1'), findsOneWidget);
      expect(find.text('Tab 2'), findsOneWidget);
      expect(find.text('Tab 3'), findsOneWidget);
    });

    testWidgets('scrolls on mobile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: DefaultTabController(
              length: 3,
              child: Scaffold(
                appBar: AppBar(
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: Builder(
                      builder: (context) {
                        return AdaptiveTabBar(
                          controller: DefaultTabController.of(context),
                          tabs: const [
                            Tab(text: 'Tab 1'),
                            Tab(text: 'Tab 2'),
                            Tab(text: 'Tab 3'),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.isScrollable, true);
    });
  });
}
