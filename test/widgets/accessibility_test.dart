import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/widgets/statistics/accessibility_helpers.dart';
import 'package:parion/models/cash_flow_data.dart';

void main() {
  group('StatisticsAccessibility', () {
    group('currencyLabel', () {
      test('formats positive amount correctly', () {
        final label = StatisticsAccessibility.currencyLabel(1500.50);
        expect(label, '1500.50 TL artı');
      });

      test('formats negative amount correctly', () {
        final label = StatisticsAccessibility.currencyLabel(-1500.50);
        expect(label, '1500.50 TL eksi');
      });

      test('formats zero correctly', () {
        final label = StatisticsAccessibility.currencyLabel(0);
        expect(label, 'Sıfır TL');
      });

      test('supports custom currency', () {
        final label = StatisticsAccessibility.currencyLabel(100, currency: 'USD');
        expect(label, '100.00 USD artı');
      });
    });

    group('percentageLabel', () {
      test('formats percentage correctly', () {
        final label = StatisticsAccessibility.percentageLabel(75.5);
        expect(label, 'Yüzde 75.5');
      });

      test('formats whole number percentage', () {
        final label = StatisticsAccessibility.percentageLabel(100);
        expect(label, 'Yüzde 100.0');
      });
    });

    group('dateLabel', () {
      test('formats date correctly', () {
        final date = DateTime(2024, 12, 7);
        final label = StatisticsAccessibility.dateLabel(date);
        expect(label, '7 Aralık 2024');
      });

      test('formats January correctly', () {
        final date = DateTime(2024, 1, 15);
        final label = StatisticsAccessibility.dateLabel(date);
        expect(label, '15 Ocak 2024');
      });
    });

    group('trendLabel', () {
      test('formats up trend correctly', () {
        final label = StatisticsAccessibility.trendLabel(TrendDirection.up);
        expect(label, 'Artış trendi');
      });

      test('formats down trend correctly', () {
        final label = StatisticsAccessibility.trendLabel(TrendDirection.down);
        expect(label, 'Azalış trendi');
      });

      test('formats stable trend correctly', () {
        final label = StatisticsAccessibility.trendLabel(TrendDirection.stable);
        expect(label, 'Sabit trend');
      });
    });

    group('metricCardLabel', () {
      test('creates label with all components', () {
        final label = StatisticsAccessibility.metricCardLabel(
          label: 'Toplam Gelir',
          value: '₺15,000',
          change: '+12%',
          trend: TrendDirection.up,
        );
        expect(label, 'Toplam Gelir: ₺15,000, değişim: +12%, Artış trendi');
      });

      test('creates label without change', () {
        final label = StatisticsAccessibility.metricCardLabel(
          label: 'Toplam Gelir',
          value: '₺15,000',
          trend: TrendDirection.up,
        );
        expect(label, 'Toplam Gelir: ₺15,000, Artış trendi');
      });

      test('creates label without trend', () {
        final label = StatisticsAccessibility.metricCardLabel(
          label: 'Toplam Gelir',
          value: '₺15,000',
          change: '+12%',
        );
        expect(label, 'Toplam Gelir: ₺15,000, değişim: +12%');
      });

      test('creates basic label', () {
        final label = StatisticsAccessibility.metricCardLabel(
          label: 'Toplam Gelir',
          value: '₺15,000',
        );
        expect(label, 'Toplam Gelir: ₺15,000');
      });
    });

    group('summaryCardLabel', () {
      test('creates label with subtitle', () {
        final label = StatisticsAccessibility.summaryCardLabel(
          title: 'Nakit Akışı',
          value: '₺5,000',
          subtitle: 'Bu ay',
        );
        expect(label, 'Nakit Akışı: ₺5,000, Bu ay');
      });

      test('creates label without subtitle', () {
        final label = StatisticsAccessibility.summaryCardLabel(
          title: 'Nakit Akışı',
          value: '₺5,000',
        );
        expect(label, 'Nakit Akışı: ₺5,000');
      });
    });

    group('chartLabel', () {
      test('creates label with description', () {
        final label = StatisticsAccessibility.chartLabel(
          title: 'Gelir Trendi',
          dataPointCount: 12,
          description: 'Son 12 ay',
        );
        expect(label, 'Gelir Trendi grafik, 12 veri noktası, Son 12 ay');
      });

      test('creates label without description', () {
        final label = StatisticsAccessibility.chartLabel(
          title: 'Gelir Trendi',
          dataPointCount: 12,
        );
        expect(label, 'Gelir Trendi grafik, 12 veri noktası');
      });
    });

    group('hasGoodContrast', () {
      test('returns true for good contrast (black on white)', () {
        final hasGoodContrast = StatisticsAccessibility.hasGoodContrast(
          Colors.black,
          Colors.white,
        );
        expect(hasGoodContrast, true);
      });

      test('returns true for good contrast (white on black)', () {
        final hasGoodContrast = StatisticsAccessibility.hasGoodContrast(
          Colors.white,
          Colors.black,
        );
        expect(hasGoodContrast, true);
      });

      test('returns true for dark blue on white', () {
        final hasGoodContrast = StatisticsAccessibility.hasGoodContrast(
          Colors.blue.shade900,
          Colors.white,
        );
        expect(hasGoodContrast, true);
      });

      test('returns false for poor contrast (yellow on white)', () {
        final hasGoodContrast = StatisticsAccessibility.hasGoodContrast(
          Colors.yellow.shade200,
          Colors.white,
        );
        expect(hasGoodContrast, false);
      });

      test('returns false for poor contrast (light grey on white)', () {
        final hasGoodContrast = StatisticsAccessibility.hasGoodContrast(
          Colors.grey.shade300,
          Colors.white,
        );
        expect(hasGoodContrast, false);
      });
    });

    group('getAccessibleColor', () {
      test('returns same color if contrast is good', () {
        final originalColor = Colors.blue.shade900;
        final accessibleColor = StatisticsAccessibility.getAccessibleColor(
          originalColor,
          Colors.white,
        );
        expect(accessibleColor, originalColor);
      });

      test('adjusts color if contrast is poor on light background', () {
        final originalColor = Colors.yellow.shade200;
        final accessibleColor = StatisticsAccessibility.getAccessibleColor(
          originalColor,
          Colors.white,
        );
        expect(accessibleColor, isNot(originalColor));
        // Should be darker
        expect(accessibleColor.computeLuminance() < originalColor.computeLuminance(), true);
      });

      test('adjusts color if contrast is poor on dark background', () {
        final originalColor = Colors.grey.shade800;
        final accessibleColor = StatisticsAccessibility.getAccessibleColor(
          originalColor,
          Colors.black,
        );
        expect(accessibleColor, isNot(originalColor));
        // Should be lighter
        expect(accessibleColor.computeLuminance() > originalColor.computeLuminance(), true);
      });
    });
  });

  group('AccessibleButton', () {
    testWidgets('has minimum touch target size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: () {},
              semanticLabel: 'Test Button',
              child: const Text('Test'),
            ),
          ),
        ),
      );

      // Find the ConstrainedBox that wraps the button
      final constrainedBoxes = find.byType(ConstrainedBox);
      expect(constrainedBoxes, findsWidgets);
      
      // Check that at least one has the minimum constraints
      bool hasMinConstraints = false;
      for (final element in constrainedBoxes.evaluate()) {
        final widget = element.widget as ConstrainedBox;
        if (widget.constraints.minHeight == 48.0 && widget.constraints.minWidth == 48.0) {
          hasMinConstraints = true;
          break;
        }
      }
      expect(hasMinConstraints, true);
    });

    testWidgets('renders button with text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: () {},
              semanticLabel: 'Test Button',
              child: const Text('Test'),
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: null,
              semanticLabel: 'Test Button',
              child: const Text('Test'),
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, null);
    });
  });

  group('AccessibleIconButton', () {
    testWidgets('has minimum touch target size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleIconButton(
              icon: Icons.download,
              onPressed: () {},
              semanticLabel: 'Download',
            ),
          ),
        ),
      );

      // Find the ConstrainedBox that wraps the icon button
      final constrainedBoxes = find.byType(ConstrainedBox);
      expect(constrainedBoxes, findsWidgets);
      
      // Check that at least one has the minimum constraints
      bool hasMinConstraints = false;
      for (final element in constrainedBoxes.evaluate()) {
        final widget = element.widget as ConstrainedBox;
        if (widget.constraints.minHeight == 48.0 && widget.constraints.minWidth == 48.0) {
          hasMinConstraints = true;
          break;
        }
      }
      expect(hasMinConstraints, true);
    });

    testWidgets('renders icon button with tooltip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleIconButton(
              icon: Icons.download,
              onPressed: () {},
              semanticLabel: 'Download',
              tooltip: 'Download file',
            ),
          ),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      
      final iconButton = tester.widget<IconButton>(
        find.byType(IconButton),
      );
      expect(iconButton.tooltip, 'Download file');
    });
  });

  group('AccessibleCard', () {
    testWidgets('renders card with content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleCard(
              semanticLabel: 'Test Card',
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('has minimum height when tappable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleCard(
              semanticLabel: 'Test Card',
              onTap: () {},
              child: const Text('Content'),
            ),
          ),
        ),
      );

      // Find the ConstrainedBox
      final constrainedBoxes = find.byType(ConstrainedBox);
      expect(constrainedBoxes, findsWidgets);
      
      // Check that at least one has the minimum height constraint
      bool hasMinHeight = false;
      for (final element in constrainedBoxes.evaluate()) {
        final widget = element.widget as ConstrainedBox;
        if (widget.constraints.minHeight == 48.0) {
          hasMinHeight = true;
          break;
        }
      }
      expect(hasMinHeight, true);
    });

    testWidgets('is tappable when onTap is provided', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleCard(
              semanticLabel: 'Test Card',
              onTap: () => tapped = true,
              child: const Text('Content'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, true);
    });
  });

  group('AccessibleFilterChip', () {
    testWidgets('has minimum height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleFilterChip(
              label: 'Test',
              selected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the ConstrainedBox
      final constrainedBoxes = find.byType(ConstrainedBox);
      expect(constrainedBoxes, findsWidgets);
      
      // Check that at least one has the minimum height constraint
      bool hasMinHeight = false;
      for (final element in constrainedBoxes.evaluate()) {
        final widget = element.widget as ConstrainedBox;
        if (widget.constraints.minHeight == 48.0) {
          hasMinHeight = true;
          break;
        }
      }
      expect(hasMinHeight, true);
    });

    testWidgets('renders filter chip with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleFilterChip(
              label: 'Test',
              selected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
      expect(find.byType(FilterChip), findsOneWidget);
    });

    testWidgets('shows selected state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleFilterChip(
              label: 'Test',
              selected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      final filterChip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(filterChip.selected, true);
    });
  });

  group('AccessibleProgress', () {
    testWidgets('displays label and progress indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleProgress(
              value: 0.5,
              label: 'Test Progress',
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Test Progress'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows correct progress value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleProgress(
              value: 0.75,
              label: 'Progress',
              color: Colors.blue,
            ),
          ),
        ),
      );

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 0.75);
    });
  });

  group('AccessibleListTile', () {
    testWidgets('has minimum height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleListTile(
              title: const Text('Title'),
              semanticLabel: 'Test Tile',
            ),
          ),
        ),
      );

      // Find the ConstrainedBox
      final constrainedBoxes = find.byType(ConstrainedBox);
      expect(constrainedBoxes, findsWidgets);
      
      // Check that at least one has the minimum height constraint
      bool hasMinHeight = false;
      for (final element in constrainedBoxes.evaluate()) {
        final widget = element.widget as ConstrainedBox;
        if (widget.constraints.minHeight == 48.0) {
          hasMinHeight = true;
          break;
        }
      }
      expect(hasMinHeight, true);
    });

    testWidgets('renders list tile with title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleListTile(
              title: const Text('Title'),
              subtitle: const Text('Subtitle'),
              semanticLabel: 'Test Tile',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });
  });
}
