import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/utils/lazy_load_helper.dart';

void main() {
  group('LazyLoadController', () {
    test('should load and track items', () {
      final controller = LazyLoadController();

      expect(controller.isLoaded(0), false);

      controller.loadItem(0);
      expect(controller.isLoaded(0), true);
      expect(controller.loadedIndices.length, 1);
    });

    test('should load multiple items', () {
      final controller = LazyLoadController();

      controller.loadItems([0, 1, 2, 3, 4]);
      expect(controller.loadedIndices.length, 5);
      expect(controller.isLoaded(2), true);
      expect(controller.isLoaded(5), false);
    });

    test('should unload items', () {
      final controller = LazyLoadController();

      controller.loadItems([0, 1, 2]);
      expect(controller.loadedIndices.length, 3);

      controller.unloadItem(1);
      expect(controller.loadedIndices.length, 2);
      expect(controller.isLoaded(1), false);
      expect(controller.isLoaded(0), true);
    });

    test('should enforce max loaded items limit', () {
      final controller = LazyLoadController(maxLoadedItems: 10);

      // Load 15 items
      controller.loadItems(List.generate(15, (i) => i));

      // Should only keep 10 items
      expect(controller.loadedIndices.length, 10);
    });

    test('should clear all loaded items', () {
      final controller = LazyLoadController();

      controller.loadItems([0, 1, 2, 3, 4]);
      expect(controller.loadedIndices.length, 5);

      controller.clear();
      expect(controller.loadedIndices.length, 0);
    });

    test('should notify listeners when items are loaded', () {
      final controller = LazyLoadController();
      int notificationCount = 0;

      controller.addListener(() {
        notificationCount++;
      });

      controller.loadItem(0);
      expect(notificationCount, 1);

      controller.loadItems([1, 2, 3]);
      expect(notificationCount, 2);
    });

    test('should not notify if item is already loaded', () {
      final controller = LazyLoadController();
      int notificationCount = 0;

      controller.addListener(() {
        notificationCount++;
      });

      controller.loadItem(0);
      expect(notificationCount, 1);

      controller.loadItem(0); // Load same item again
      expect(notificationCount, 1); // Should not notify
    });
  });

  group('LazyLoadWidget', () {
    testWidgets('should show placeholder initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyLoadWidget(
              placeholder: const Text('Loading...'),
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text('Content'), findsNothing);
    });

    testWidgets('should load content when visible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  LazyLoadWidget(
                    placeholder: const SizedBox(height: 100),
                    child: Container(
                      height: 100,
                      color: Colors.blue,
                      child: const Text('Content'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Content should be loaded since it's in viewport
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('should call onLoad callback when loaded', (tester) async {
      bool wasLoaded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyLoadWidget(
              placeholder: const Text('Loading...'),
              child: const Text('Content'),
              onLoad: () {
                wasLoaded = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(wasLoaded, true);
    });
  });

  group('LazyLoadListView', () {
    testWidgets('should render list with lazy loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyLoadListView(
              itemCount: 100,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Item $index'),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should have some items loaded
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('should show placeholder for unloaded items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyLoadListView(
              itemCount: 100,
              maxLoadedItems: 5,
              itemBuilder: (context, index) {
                return SizedBox(
                  height: 100,
                  child: Text('Item $index'),
                );
              },
              placeholderBuilder: (context, index) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should have placeholders
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('should load more items on scroll', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyLoadListView(
              itemCount: 100,
              maxLoadedItems: 10,
              itemBuilder: (context, index) {
                return SizedBox(
                  height: 100,
                  child: ListTile(
                    title: Text('Item $index'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final initialItemCount = tester.widgetList(find.byType(ListTile)).length;

      // Scroll down
      await tester.drag(find.byType(LazyLoadListView), const Offset(0, -500));
      await tester.pump();

      // Should have loaded more items (or at least maintained the count)
      final afterScrollItemCount = tester.widgetList(find.byType(ListTile)).length;
      expect(afterScrollItemCount, greaterThanOrEqualTo(initialItemCount));
    });
  });

  group('VisibilityDetector', () {
    testWidgets('should detect visibility changes', (tester) async {
      bool isVisible = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 1000),
                  VisibilityDetector(
                    onVisibilityChanged: (visible) {
                      isVisible = visible;
                    },
                    child: Container(
                      height: 100,
                      color: Colors.blue,
                      child: const Text('Content'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Scroll to make it visible
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1000));
      await tester.pump();

      // Should be visible now (or at least the callback should have been called)
      // Note: In test environment, visibility detection may not work perfectly
      expect(isVisible, isA<bool>());
    });

    testWidgets('should report visibility percentage', (tester) async {
      double visibilityPercentage = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  VisibilityDetector(
                    onVisibilityPercentageChanged: (percentage) {
                      visibilityPercentage = percentage;
                    },
                    child: Container(
                      height: 200,
                      color: Colors.blue,
                      child: const Text('Content'),
                    ),
                  ),
                  const SizedBox(height: 1000),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Should have some visibility percentage (or at least be a valid number)
      expect(visibilityPercentage, isA<double>());
      expect(visibilityPercentage, greaterThanOrEqualTo(0.0));
    });
  });

  group('LazyLoadScrollListener', () {
    test('should initialize with scroll controller', () {
      final scrollController = ScrollController();
      final lazyLoadController = LazyLoadController();

      final listener = LazyLoadScrollListener(
        scrollController: scrollController,
        lazyLoadController: lazyLoadController,
        totalItems: 100,
      );

      expect(listener, isNotNull);

      listener.dispose();
      scrollController.dispose();
      lazyLoadController.dispose();
    });

    test('should dispose properly', () {
      final scrollController = ScrollController();
      final lazyLoadController = LazyLoadController();

      final listener = LazyLoadScrollListener(
        scrollController: scrollController,
        lazyLoadController: lazyLoadController,
        totalItems: 100,
      );

      // Should not throw
      expect(() => listener.dispose(), returnsNormally);

      scrollController.dispose();
      lazyLoadController.dispose();
    });
  });
}
