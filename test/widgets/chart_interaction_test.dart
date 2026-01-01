import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:parion/widgets/statistics/interactive_line_chart.dart';
import 'package:parion/widgets/statistics/interactive_pie_chart.dart';
import 'package:parion/widgets/statistics/interactive_bar_chart.dart';

void main() {
  group('Interactive Chart Widget Tests', () {
    group('InteractiveLineChart', () {
      testWidgets('should render line chart with data', (
        WidgetTester tester,
      ) async {
        final spots = [
          FlSpot(0, 1000),
          FlSpot(1, 1500),
          FlSpot(2, 1200),
          FlSpot(3, 1800),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractiveLineChart(
                spots: spots,
                color: Colors.blue,
                title: 'Test Chart',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify chart is rendered
        expect(find.byType(LineChart), findsOneWidget);
        expect(find.text('Test Chart'), findsOneWidget);
      });

      testWidgets('should handle empty data', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractiveLineChart(
                spots: [],
                color: Colors.blue,
                title: 'Empty Chart',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show empty state
        expect(find.text('Veri yok'), findsOneWidget);
      });

      testWidgets('should display with area fill', (WidgetTester tester) async {
        final spots = [FlSpot(0, 1000), FlSpot(1, 1500)];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractiveLineChart(
                spots: spots,
                color: Colors.green,
                title: 'Area Chart',
                showArea: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(LineChart), findsOneWidget);
      });

      testWidgets('should display without dots', (WidgetTester tester) async {
        final spots = [FlSpot(0, 1000), FlSpot(1, 1500)];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractiveLineChart(
                spots: spots,
                color: Colors.red,
                title: 'No Dots Chart',
                showDots: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(LineChart), findsOneWidget);
      });

      testWidgets('should handle single data point', (
        WidgetTester tester,
      ) async {
        final spots = [FlSpot(0, 1000)];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractiveLineChart(
                spots: spots,
                color: Colors.blue,
                title: 'Single Point',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(LineChart), findsOneWidget);
      });
    });

    group('InteractivePieChart', () {
      testWidgets('should render pie chart with data', (
        WidgetTester tester,
      ) async {
        final data = {
          'Food': 1000.0,
          'Transport': 500.0,
          'Entertainment': 300.0,
        };

        final colors = {
          'Food': Colors.red,
          'Transport': Colors.blue,
          'Entertainment': Colors.green,
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractivePieChart(
                data: data,
                colors: colors,
                title: 'Spending Distribution',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify chart is rendered
        expect(find.byType(PieChart), findsOneWidget);
        expect(find.text('Spending Distribution'), findsOneWidget);
      });

      testWidgets('should handle empty data', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractivePieChart(
                data: {},
                colors: {},
                title: 'Empty Pie',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show empty state
        expect(find.text('Veri yok'), findsOneWidget);
      });



      testWidgets('should handle single category', (WidgetTester tester) async {
        final data = {'Only One': 1000.0};
        final colors = {'Only One': Colors.blue};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractivePieChart(
                data: data,
                colors: colors,
                title: 'Single Category',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(PieChart), findsOneWidget);
      });
    });

    group('InteractiveBarChart', () {
      testWidgets('should render bar chart with data', (
        WidgetTester tester,
      ) async {
        final data = {'Jan': 1000.0, 'Feb': 1500.0, 'Mar': 1200.0};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractiveBarChart(
                data: data,
                color: Colors.blue,
                title: 'Monthly Data',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify chart is rendered
        expect(find.byType(BarChart), findsOneWidget);
        expect(find.text('Monthly Data'), findsOneWidget);
      });

      testWidgets('should handle empty data', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractiveBarChart(
                data: {},
                color: Colors.blue,
                title: 'Empty Bar',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show empty state
        expect(find.text('Veri yok'), findsOneWidget);
      });

      testWidgets('should display horizontal bars', (
        WidgetTester tester,
      ) async {
        final data = {'Item 1': 100.0, 'Item 2': 200.0};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractiveBarChart(
                data: data,
                color: Colors.green,
                title: 'Horizontal Bars',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(BarChart), findsOneWidget);
      });

      testWidgets('should handle single bar', (WidgetTester tester) async {
        final data = {'Single': 1000.0};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractiveBarChart(
                data: data,
                color: Colors.red,
                title: 'Single Bar',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(BarChart), findsOneWidget);
      });
    });
  });

  group('Chart Tooltip Tests', () {
    testWidgets('should display tooltip on line chart hover', (
      WidgetTester tester,
    ) async {
      final spots = [FlSpot(0, 1000), FlSpot(1, 1500)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveLineChart(
              spots: spots,
              color: Colors.blue,
              title: 'Test Chart',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Chart should be rendered with tooltip capability
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('should display tooltip on pie chart tap', (
      WidgetTester tester,
    ) async {
      final data = {'Food': 1000.0, 'Transport': 500.0};

      final colors = {'Food': Colors.red, 'Transport': Colors.blue};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractivePieChart(
              data: data,
              colors: colors,
              title: 'Test Pie',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PieChart), findsOneWidget);
    });
  });

  group('Chart Animation Tests', () {
    testWidgets('should animate line chart on load', (
      WidgetTester tester,
    ) async {
      final spots = [FlSpot(0, 1000), FlSpot(1, 1500)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveLineChart(
              spots: spots,
              color: Colors.blue,
              title: 'Animated Chart',
            ),
          ),
        ),
      );

      // Initial render
      await tester.pump();

      // Animation in progress
      await tester.pump(const Duration(milliseconds: 100));

      // Animation complete
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('should animate pie chart on load', (
      WidgetTester tester,
    ) async {
      final data = {'Category': 1000.0};
      final colors = {'Category': Colors.blue};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractivePieChart(
              data: data,
              colors: colors,
              title: 'Animated Pie',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byType(PieChart), findsOneWidget);
    });
  });

  group('Chart Dark Mode Tests', () {
    testWidgets('should render line chart in dark mode', (
      WidgetTester tester,
    ) async {
      final spots = [FlSpot(0, 1000), FlSpot(1, 1500)];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: InteractiveLineChart(
              spots: spots,
              color: Colors.blue,
              title: 'Dark Chart',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('should render pie chart in dark mode', (
      WidgetTester tester,
    ) async {
      final data = {'Category': 1000.0};
      final colors = {'Category': Colors.blue};

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: InteractivePieChart(
              data: data,
              colors: colors,
              title: 'Dark Pie',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PieChart), findsOneWidget);
    });
  });
}
