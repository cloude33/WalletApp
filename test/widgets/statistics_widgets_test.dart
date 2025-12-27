import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/models/cash_flow_data.dart';
import 'package:money/widgets/statistics/statistics_widgets.dart';

void main() {
  group('SummaryCard', () {
    testWidgets('renders with all properties', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(
              title: 'Total Income',
              value: '₺10,000',
              subtitle: 'This month',
              icon: Icons.trending_up,
              color: Colors.green,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Total Income'), findsOneWidget);
      expect(find.text('₺10,000'), findsOneWidget);
      expect(find.text('This month'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);

      await tester.tap(find.byType(SummaryCard));
      expect(tapped, true);
    });

    testWidgets('renders without subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(
              title: 'Total Income',
              value: '₺10,000',
              icon: Icons.trending_up,
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Total Income'), findsOneWidget);
      expect(find.text('₺10,000'), findsOneWidget);
    });
  });

  group('MetricCard', () {
    testWidgets('renders with trend up', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetricCard(
              label: 'Net Flow',
              value: '₺5,000',
              change: '+15%',
              trend: TrendDirection.up,
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Net Flow'), findsOneWidget);
      expect(find.text('₺5,000'), findsOneWidget);
      expect(find.text('+15%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('renders with trend down', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetricCard(
              label: 'Expenses',
              value: '₺3,000',
              change: '-10%',
              trend: TrendDirection.down,
              color: Colors.red,
            ),
          ),
        ),
      );

      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('₺3,000'), findsOneWidget);
      expect(find.text('-10%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('renders with trend stable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetricCard(
              label: 'Balance',
              value: '₺2,000',
              change: '0%',
              trend: TrendDirection.stable,
            ),
          ),
        ),
      );

      expect(find.text('Balance'), findsOneWidget);
      expect(find.text('₺2,000'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_flat), findsOneWidget);
    });

    testWidgets('renders without trend', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetricCard(
              label: 'Balance',
              value: '₺2,000',
            ),
          ),
        ),
      );

      expect(find.text('Balance'), findsOneWidget);
      expect(find.text('₺2,000'), findsOneWidget);
    });
  });

  group('ChartCard', () {
    testWidgets('renders with title and chart', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartCard(
              title: 'Cash Flow',
              chart: Container(
                height: 200,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Cash Flow'), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders with subtitle and actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartCard(
              title: 'Cash Flow',
              subtitle: 'Last 12 months',
              chart: Container(height: 200),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Cash Flow'), findsOneWidget);
      expect(find.text('Last 12 months'), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });
  });

  group('StatisticsFilterChip', () {
    testWidgets('renders selected state', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsFilterChip(
              label: 'Monthly',
              selected: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Monthly'), findsOneWidget);

      await tester.tap(find.byType(StatisticsFilterChip));
      expect(tapped, true);
    });

    testWidgets('renders unselected state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsFilterChip(
              label: 'Weekly',
              selected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Weekly'), findsOneWidget);
    });
  });

  group('TimeFilterBar', () {
    testWidgets('renders all filters', (WidgetTester tester) async {
      String? selectedFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeFilterBar(
              selectedFilter: 'Monthly',
              filters: const ['Daily', 'Weekly', 'Monthly', 'Yearly'],
              onFilterChanged: (filter) => selectedFilter = filter,
            ),
          ),
        ),
      );

      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);

      await tester.tap(find.text('Weekly'));
      await tester.pump();

      expect(selectedFilter, 'Weekly');
    });

    testWidgets('scrolls horizontally', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeFilterBar(
              selectedFilter: 'Monthly',
              filters: const [
                'Daily',
                'Weekly',
                'Monthly',
                'Quarterly',
                'Yearly',
                'Custom'
              ],
              onFilterChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
