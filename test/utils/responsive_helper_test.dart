import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/utils/responsive_helper.dart';

void main() {
  group('ResponsiveHelper', () {
    testWidgets('isMobile returns true for mobile screen sizes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveHelper.isMobile(context), true);
                expect(ResponsiveHelper.isTablet(context), false);
                expect(ResponsiveHelper.isDesktop(context), false);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('isTablet returns true for tablet screen sizes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(700, 1000)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveHelper.isMobile(context), false);
                expect(ResponsiveHelper.isTablet(context), true);
                expect(ResponsiveHelper.isDesktop(context), false);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('isDesktop returns true for desktop screen sizes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1400, 1000)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveHelper.isMobile(context), false);
                expect(ResponsiveHelper.isTablet(context), false);
                expect(ResponsiveHelper.isDesktop(context), true);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('isLandscape returns true for landscape orientation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 400)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveHelper.isLandscape(context), true);
                expect(ResponsiveHelper.isPortrait(context), false);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('isPortrait returns true for portrait orientation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveHelper.isLandscape(context), false);
                expect(ResponsiveHelper.isPortrait(context), true);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getResponsiveValue returns correct value for mobile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                final value = ResponsiveHelper.getResponsiveValue<int>(
                  context: context,
                  mobile: 1,
                  tablet: 2,
                  desktop: 3,
                );
                expect(value, 1);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getResponsiveValue returns correct value for tablet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(700, 1000)),
            child: Builder(
              builder: (context) {
                final value = ResponsiveHelper.getResponsiveValue<int>(
                  context: context,
                  mobile: 1,
                  tablet: 2,
                  desktop: 3,
                );
                expect(value, 2);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getResponsiveValue returns correct value for desktop', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1400, 1000)),
            child: Builder(
              builder: (context) {
                final value = ResponsiveHelper.getResponsiveValue<int>(
                  context: context,
                  mobile: 1,
                  tablet: 2,
                  desktop: 3,
                );
                expect(value, 3);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getGridColumns returns correct columns for different screen sizes', (tester) async {
      // Mobile
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveHelper.getGridColumns(context), 1);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Tablet
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(700, 1000)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveHelper.getGridColumns(context), 2);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Desktop
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1400, 1000)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveHelper.getGridColumns(context), 3);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getChartHeight returns smaller height in landscape', (tester) async {
      // Portrait
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                final portraitHeight = ResponsiveHelper.getChartHeight(context);
                expect(portraitHeight, 300);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Landscape
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 400)),
            child: Builder(
              builder: (context) {
                final landscapeHeight = ResponsiveHelper.getChartHeight(context);
                // 800x400 is tablet landscape, so expect 250
                expect(landscapeHeight, 250);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('shouldUseSideBySideLayout returns true for tablet landscape', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1000, 700)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveHelper.shouldUseSideBySideLayout(context), true);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('shouldUseSideBySideLayout returns false for mobile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveHelper.shouldUseSideBySideLayout(context), false);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getItemsPerRow returns more items in landscape', (tester) async {
      // Portrait mobile
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveHelper.getItemsPerRow(context), 1);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Landscape mobile
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 400)),
            child: Builder(
              builder: (context) {
                // 800x400 is tablet landscape, so expect 3
                expect(ResponsiveHelper.getItemsPerRow(context), 3);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('shouldTabBarScroll returns true for mobile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveHelper.shouldTabBarScroll(context), true);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getResponsiveFontSize scales correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                final fontSize = ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 16,
                  desktop: 18,
                );
                expect(fontSize, 14);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });
  });
}
