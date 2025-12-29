import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money/services/chart_service.dart';

void main() {
  late ChartService chartService;

  setUp(() {
    chartService = ChartService();
  });

  group('ChartService - Line Chart', () {
    test('should create line chart with valid data', () {
      // Arrange
      final spots = [
        const FlSpot(0, 100),
        const FlSpot(1, 200),
        const FlSpot(2, 150),
        const FlSpot(3, 300),
      ];

      // Act
      final lineChartData = chartService.createLineChart(
        spots: spots,
        color: Colors.blue,
      );

      // Assert
      expect(lineChartData, isNotNull);
      expect(lineChartData.lineBarsData.length, 1);
      expect(lineChartData.lineBarsData.first.spots.length, 4);
      expect(lineChartData.lineBarsData.first.color, Colors.blue);
    });

    test('should create line chart with empty data', () {
      // Arrange
      final spots = <FlSpot>[];

      // Act
      final lineChartData = chartService.createLineChart(
        spots: spots,
        color: Colors.blue,
      );

      // Assert
      expect(lineChartData, isNotNull);
      expect(lineChartData.lineBarsData.length, 1);
      expect(lineChartData.lineBarsData.first.spots.length, 0);
    });

    test('should create line chart with custom settings', () {
      // Arrange
      final spots = [
        const FlSpot(0, 100),
        const FlSpot(1, 200),
      ];

      // Act
      final lineChartData = chartService.createLineChart(
        spots: spots,
        color: Colors.red,
        showArea: false,
        showDots: false,
        lineWidth: 5.0,
        isCurved: false,
      );

      // Assert
      expect(lineChartData.lineBarsData.first.belowBarData.show, false);
      expect(lineChartData.lineBarsData.first.dotData.show, false);
      expect(lineChartData.lineBarsData.first.barWidth, 5.0);
      expect(lineChartData.lineBarsData.first.isCurved, false);
    });
  });

  group('ChartService - Pie Chart', () {
    test('should create pie chart with valid data', () {
      // Arrange
      final data = {
        'Category A': 100.0,
        'Category B': 200.0,
        'Category C': 150.0,
      };

      // Act
      final pieChartData = chartService.createPieChart(data: data);

      // Assert
      expect(pieChartData, isNotNull);
      expect(pieChartData.sections.length, 3);
      expect(pieChartData.sections[0].value, 100.0);
      expect(pieChartData.sections[1].value, 200.0);
      expect(pieChartData.sections[2].value, 150.0);
    });

    test('should create pie chart with empty data', () {
      // Arrange
      final data = <String, double>{};

      // Act
      final pieChartData = chartService.createPieChart(data: data);

      // Assert
      expect(pieChartData, isNotNull);
      expect(pieChartData.sections.length, 1);
      expect(pieChartData.sections.first.title, 'Veri Yok');
    });

    test('should calculate percentages correctly', () {
      // Arrange
      final data = {
        'Category A': 50.0,
        'Category B': 50.0,
      };

      // Act
      final pieChartData = chartService.createPieChart(
        data: data,
        showPercentage: true,
      );

      // Assert
      expect(pieChartData.sections[0].title, '50.0%');
      expect(pieChartData.sections[1].title, '50.0%');
    });

    test('should use custom colors when provided', () {
      // Arrange
      final data = {
        'Category A': 100.0,
        'Category B': 200.0,
      };
      final colors = {
        'Category A': Colors.red,
        'Category B': Colors.blue,
      };

      // Act
      final pieChartData = chartService.createPieChart(
        data: data,
        colors: colors,
      );

      // Assert
      expect(pieChartData.sections[0].color, Colors.red);
      expect(pieChartData.sections[1].color, Colors.blue);
    });
  });

  group('ChartService - Bar Chart', () {
    test('should create bar chart with valid data', () {
      // Arrange
      final data = {
        'Jan': 100.0,
        'Feb': 200.0,
        'Mar': 150.0,
      };

      // Act
      final barChartData = chartService.createBarChart(
        data: data,
        color: Colors.green,
      );

      // Assert
      expect(barChartData, isNotNull);
      expect(barChartData.barGroups.length, 3);
      expect(barChartData.barGroups[0].barRods.first.toY, 100.0);
      expect(barChartData.barGroups[1].barRods.first.toY, 200.0);
      expect(barChartData.barGroups[2].barRods.first.toY, 150.0);
    });

    test('should create bar chart with empty data', () {
      // Arrange
      final data = <String, double>{};

      // Act
      final barChartData = chartService.createBarChart(
        data: data,
        color: Colors.green,
      );

      // Assert
      expect(barChartData, isNotNull);
      expect(barChartData.barGroups.length, 0);
    });

    test('should use custom bar width', () {
      // Arrange
      final data = {
        'Jan': 100.0,
      };

      // Act
      final barChartData = chartService.createBarChart(
        data: data,
        color: Colors.green,
        barWidth: 30.0,
      );

      // Assert
      expect(barChartData.barGroups.first.barRods.first.width, 30.0);
    });
  });

  group('ChartService - Helper Methods', () {
    test('should get color for index', () {
      // Act
      final color0 = chartService.getColorForIndex(0);
      final color1 = chartService.getColorForIndex(1);
      final color10 = chartService.getColorForIndex(10);

      // Assert
      expect(color0, isNotNull);
      expect(color1, isNotNull);
      expect(color10, color0); // Should wrap around
    });

    test('should get color for positive value', () {
      // Act
      final color = chartService.getColorForValue(100.0);

      // Assert
      expect(color, ChartService.incomeColor);
    });

    test('should get color for negative value', () {
      // Act
      final color = chartService.getColorForValue(-100.0);

      // Assert
      expect(color, ChartService.expenseColor);
    });

    test('should get color for zero value', () {
      // Act
      final color = chartService.getColorForValue(0.0);

      // Assert
      expect(color, ChartService.neutralColor);
    });
  });

  group('ChartService - Widget Creation', () {
    testWidgets('should create tooltip widget', (WidgetTester tester) async {
      // Arrange
      final tooltip = chartService.createTooltip(
        title: 'Test',
        value: '100 TL',
        color: Colors.blue,
        subtitle: 'Subtitle',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: tooltip,
          ),
        ),
      );

      // Assert
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('100 TL'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
    });

    testWidgets('should create legend item widget', (WidgetTester tester) async {
      // Arrange
      final legendItem = chartService.createLegendItem(
        label: 'Category',
        color: Colors.red,
        value: '100 TL',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: legendItem,
          ),
        ),
      );

      // Assert
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('100 TL'), findsOneWidget);
    });

    testWidgets('should create chart legend', (WidgetTester tester) async {
      // Arrange
      final items = {
        'Category A': Colors.red,
        'Category B': Colors.blue,
      };
      final values = {
        'Category A': '100 TL',
        'Category B': '200 TL',
      };
      final legend = chartService.createChartLegend(
        items: items,
        values: values,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: legend,
          ),
        ),
      );

      // Assert
      expect(find.text('Category A'), findsOneWidget);
      expect(find.text('Category B'), findsOneWidget);
      expect(find.text('100 TL'), findsOneWidget);
      expect(find.text('200 TL'), findsOneWidget);
    });
  });
}
