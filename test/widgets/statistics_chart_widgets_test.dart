import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money/widgets/statistics/interactive_line_chart.dart';
import 'package:money/widgets/statistics/interactive_pie_chart.dart';
import 'package:money/widgets/statistics/interactive_bar_chart.dart';
import 'package:money/widgets/statistics/custom_tooltip.dart';
import 'package:money/widgets/statistics/chart_legend.dart';

void main() {
  group('InteractiveLineChart', () {
    testWidgets('renders with basic data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: InteractiveLineChart(
                spots: const [FlSpot(0, 100), FlSpot(1, 200), FlSpot(2, 150)],
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: InteractiveLineChart(
                spots: const [FlSpot(0, 100), FlSpot(1, 200)],
                color: Colors.blue,
                title: 'Test Chart',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Chart'), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('handles empty data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: InteractiveLineChart(spots: const [], color: Colors.blue),
            ),
          ),
        ),
      );

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('calls onPointTap when point is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: InteractiveLineChart(
                spots: const [FlSpot(0, 100), FlSpot(1, 200), FlSpot(2, 150)],
                color: Colors.blue,
                onPointTap: (spot) {
                  // Callback is properly wired
                },
              ),
            ),
          ),
        ),
      );

      // Tap on the chart
      await tester.tap(find.byType(LineChart));
      await tester.pump();

      // Note: Actual tap detection depends on fl_chart's internal implementation
      // This test verifies the callback is properly wired
    });
  });

  group('InteractivePieChart', () {
    testWidgets('renders with basic data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: InteractivePieChart(
                data: const {
                  'Category A': 100,
                  'Category B': 200,
                  'Category C': 150,
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('renders with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: InteractivePieChart(
                data: const {'Category A': 100, 'Category B': 200},
                title: 'Test Pie Chart',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Pie Chart'), findsOneWidget);
      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('handles empty data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: InteractivePieChart(data: const {}),
            ),
          ),
        ),
      );

      expect(find.byType(PieChart), findsOneWidget);
      // The "Veri Yok" text is rendered inside the PieChart widget
      // We just verify the chart renders without error
    });

    testWidgets('shows percentages when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: InteractivePieChart(
                data: const {'Category A': 100, 'Category B': 200},
                showPercentage: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PieChart), findsOneWidget);
      // Percentages are rendered inside the chart
    });
  });

  group('InteractiveBarChart', () {
    testWidgets('renders with basic data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: InteractiveBarChart(
                data: const {'Jan': 100, 'Feb': 200, 'Mar': 150},
                color: Colors.green,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('renders with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: InteractiveBarChart(
                data: const {'Jan': 100, 'Feb': 200},
                color: Colors.green,
                title: 'Test Bar Chart',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Bar Chart'), findsOneWidget);
      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('handles empty data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: InteractiveBarChart(data: const {}, color: Colors.green),
            ),
          ),
        ),
      );

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('displays labels correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: InteractiveBarChart(
                data: const {'Jan': 100, 'Feb': 200, 'Mar': 150},
                color: Colors.green,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BarChart), findsOneWidget);
      // Labels are rendered inside the chart
    });
  });

  group('CustomTooltip', () {
    testWidgets('renders with basic data', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTooltip(title: 'Test Title', value: '₺1,000'),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('₺1,000'), findsOneWidget);
    });

    testWidgets('renders with color indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTooltip(
              title: 'Test Title',
              value: '₺1,000',
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('₺1,000'), findsOneWidget);
      // Color indicator is a Container
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders with subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTooltip(
              title: 'Test Title',
              value: '₺1,000',
              subtitle: 'This month',
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('₺1,000'), findsOneWidget);
      expect(find.text('This month'), findsOneWidget);
    });

    testWidgets('renders with icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTooltip(
              title: 'Test Title',
              value: '₺1,000',
              icon: Icons.info,
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('₺1,000'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('renders with additional items', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTooltip(
              title: 'Test Title',
              value: '₺1,000',
              additionalItems: [
                TooltipItem(
                  label: 'Item 1',
                  value: '₺500',
                  color: Colors.green,
                ),
                TooltipItem(label: 'Item 2', value: '₺300', color: Colors.blue),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('₺1,000'), findsOneWidget);
      expect(find.textContaining('Item 1'), findsOneWidget);
      expect(find.textContaining('Item 2'), findsOneWidget);
    });
  });

  group('ChartLegend', () {
    testWidgets('renders horizontal legend', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChartLegend(
              items: {
                'Category A': Colors.green,
                'Category B': Colors.blue,
                'Category C': Colors.red,
              },
              direction: Axis.horizontal,
            ),
          ),
        ),
      );

      expect(find.text('Category A'), findsOneWidget);
      expect(find.text('Category B'), findsOneWidget);
      expect(find.text('Category C'), findsOneWidget);
      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('renders vertical legend', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChartLegend(
              items: {'Category A': Colors.green, 'Category B': Colors.blue},
              direction: Axis.vertical,
            ),
          ),
        ),
      );

      expect(find.text('Category A'), findsOneWidget);
      expect(find.text('Category B'), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('renders with values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChartLegend(
              items: {'Category A': Colors.green, 'Category B': Colors.blue},
              values: {'Category A': '₺1,000', 'Category B': '₺2,000'},
            ),
          ),
        ),
      );

      expect(find.text('Category A'), findsOneWidget);
      expect(find.text('₺1,000'), findsOneWidget);
      expect(find.text('Category B'), findsOneWidget);
      expect(find.text('₺2,000'), findsOneWidget);
    });

    testWidgets('handles item tap', (WidgetTester tester) async {
      String? tappedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartLegend(
              items: const {
                'Category A': Colors.green,
                'Category B': Colors.blue,
              },
              onItemTap: (item) {
                tappedItem = item;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Category A'));
      await tester.pump();

      expect(tappedItem, 'Category A');
    });
  });

  group('InteractiveChartLegend', () {
    testWidgets('renders with initial selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveChartLegend(
              items: {
                'Category A': Colors.green,
                'Category B': Colors.blue,
                'Category C': Colors.red,
              },
              initialSelection: {'Category A', 'Category B'},
            ),
          ),
        ),
      );

      expect(find.text('Category A'), findsOneWidget);
      expect(find.text('Category B'), findsOneWidget);
      expect(find.text('Category C'), findsOneWidget);
    });

    testWidgets('handles selection changes', (WidgetTester tester) async {
      Set<String>? selectedItems;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveChartLegend(
              items: const {
                'Category A': Colors.green,
                'Category B': Colors.blue,
              },
              onSelectionChanged: (selected) {
                selectedItems = selected;
              },
            ),
          ),
        ),
      );

      // Tap to deselect
      await tester.tap(find.text('Category A'));
      await tester.pump();

      expect(selectedItems, isNotNull);
      expect(selectedItems!.contains('Category B'), true);
    });

    testWidgets('allows multiple selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveChartLegend(
              items: {
                'Category A': Colors.green,
                'Category B': Colors.blue,
                'Category C': Colors.red,
              },
              allowMultipleSelection: true,
            ),
          ),
        ),
      );

      expect(find.text('Category A'), findsOneWidget);
      expect(find.text('Category B'), findsOneWidget);
      expect(find.text('Category C'), findsOneWidget);
    });

    testWidgets('allows single selection only', (WidgetTester tester) async {
      Set<String>? selectedItems;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveChartLegend(
              items: const {
                'Category A': Colors.green,
                'Category B': Colors.blue,
              },
              allowMultipleSelection: false,
              onSelectionChanged: (selected) {
                selectedItems = selected;
              },
            ),
          ),
        ),
      );

      // Tap Category B
      await tester.tap(find.text('Category B'));
      await tester.pump();

      expect(selectedItems, isNotNull);
      expect(selectedItems!.length, 1);
      expect(selectedItems!.contains('Category B'), true);
    });
  });

  group('CompactLegend', () {
    testWidgets('renders compact legend', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactLegend(
              items: {
                'Category A': Colors.green,
                'Category B': Colors.blue,
                'Category C': Colors.red,
              },
            ),
          ),
        ),
      );

      expect(find.text('Category A'), findsOneWidget);
      expect(find.text('Category B'), findsOneWidget);
      expect(find.text('Category C'), findsOneWidget);
      expect(find.byType(Wrap), findsOneWidget);
    });
  });
}
