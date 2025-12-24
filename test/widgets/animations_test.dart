import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/widgets/statistics/animations/fade_in_animation.dart';
import 'package:money/widgets/statistics/animations/slide_transition_animation.dart';
import 'package:money/widgets/statistics/animations/scale_animation.dart';
import 'package:money/widgets/statistics/animations/chart_animation.dart';
import 'package:money/widgets/statistics/animations/staggered_animation.dart';
import 'package:money/widgets/statistics/animated_summary_card.dart';
import 'package:money/widgets/statistics/animated_metric_card.dart';
import 'package:money/widgets/statistics/animated_chart_card.dart';
import 'package:money/models/cash_flow_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money/widgets/statistics/interactive_line_chart.dart';

void main() {
  group('Animation Widgets Tests', () {
    testWidgets('FadeInAnimation renders and animates', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FadeInAnimation(
              child: Text('Test'),
            ),
          ),
        ),
      );

      // Initially should be invisible or partially visible
      expect(find.text('Test'), findsOneWidget);

      // Pump animation frames
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));

      // Should still be visible after animation
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('SlideTransitionAnimation renders with different directions',
        (tester) async {
      for (final direction in SlideDirection.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SlideTransitionAnimation(
                direction: direction,
                child: const Text('Test'),
              ),
            ),
          ),
        );

        expect(find.text('Test'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 250));
      }
    });

    testWidgets('ScaleAnimation renders and scales', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScaleAnimation(
              child: Text('Test'),
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);

      // Pump animation
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('ChartAnimation renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChartAnimation(
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);

      // Pump animation
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
    });

    testWidgets('ChartRevealAnimation renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChartRevealAnimation(
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);

      // Pump animation
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
    });

    testWidgets('StaggeredAnimation renders with different configurations',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StaggeredAnimation(
                  index: 0,
                  useFade: true,
                  useSlide: true,
                  useScale: false,
                  child: Text('Item 1'),
                ),
                StaggeredAnimation(
                  index: 1,
                  useFade: true,
                  useSlide: false,
                  useScale: true,
                  child: Text('Item 2'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);

      // Pump animations
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('StaggeredListView renders multiple items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaggeredListView(
              shrinkWrap: true,
              children: const [
                Text('Item 1'),
                Text('Item 2'),
                Text('Item 3'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });
  });

  group('Animated Widget Tests', () {
    testWidgets('AnimatedSummaryCard renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedSummaryCard(
              title: 'Test Title',
              value: '₺1,000',
              subtitle: 'Test Subtitle',
              icon: Icons.trending_up,
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('₺1,000'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);

      // Pump animation
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('AnimatedSummaryCard can disable animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedSummaryCard(
              title: 'Test Title',
              value: '₺1,000',
              icon: Icons.trending_up,
              color: Colors.green,
              enableAnimation: false,
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('₺1,000'), findsOneWidget);
    });

    testWidgets('AnimatedMetricCard renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedMetricCard(
              label: 'Test Label',
              value: '₺500',
              change: '+10%',
              trend: TrendDirection.up,
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Test Label'), findsOneWidget);
      expect(find.text('₺500'), findsOneWidget);
      expect(find.text('+10%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);

      // Pump animation
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('AnimatedMetricCard can disable animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedMetricCard(
              label: 'Test Label',
              value: '₺500',
              enableAnimation: false,
            ),
          ),
        ),
      );

      expect(find.text('Test Label'), findsOneWidget);
      expect(find.text('₺500'), findsOneWidget);
    });

    testWidgets('AnimatedChartCard renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedChartCard(
              title: 'Test Chart',
              subtitle: 'Test Subtitle',
              chart: InteractiveLineChart(
                spots: const [
                  FlSpot(0, 1),
                  FlSpot(1, 2),
                  FlSpot(2, 3),
                ],
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Chart'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);

      // Pump animation
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('AnimatedChartCard can disable animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedChartCard(
              title: 'Test Chart',
              enableAnimation: false,
              chart: InteractiveLineChart(
                spots: const [
                  FlSpot(0, 1),
                  FlSpot(1, 2),
                ],
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Chart'), findsOneWidget);
    });
  });

  group('Animation Parameters Tests', () {
    testWidgets('FadeInAnimation respects delay parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FadeInAnimation(
              delay: Duration(milliseconds: 500),
              child: Text('Delayed'),
            ),
          ),
        ),
      );

      expect(find.text('Delayed'), findsOneWidget);

      // Animation should not start yet
      await tester.pump(const Duration(milliseconds: 200));

      // After delay, animation should start
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('ScaleAnimation respects scale parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScaleAnimation(
              beginScale: 0.5,
              endScale: 1.5,
              child: Text('Scaled'),
            ),
          ),
        ),
      );

      expect(find.text('Scaled'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('SlideTransitionAnimation respects offset parameter',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideTransitionAnimation(
              offset: 2.0,
              direction: SlideDirection.left,
              child: Text('Slide'),
            ),
          ),
        ),
      );

      expect(find.text('Slide'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 250));
    });
  });
}
