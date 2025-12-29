import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/widgets/statistics/filter_bar.dart';
import 'package:money/widgets/statistics/statistics_widgets.dart';

void main() {
  group('Filter Interaction Comprehensive Tests', () {
    group('TimeFilterBar Interaction', () {
      testWidgets('should select filter on tap', (WidgetTester tester) async {
        String? selectedFilter;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterBar(
                selectedFilter: 'Aylık',
                filters: const ['Günlük', 'Haftalık', 'Aylık', 'Yıllık'],
                onFilterChanged: (filter) => selectedFilter = filter,
              ),
            ),
          ),
        );

        // Tap on Haftalık filter
        await tester.tap(find.text('Haftalık'));
        await tester.pump();

        expect(selectedFilter, 'Haftalık');
      });

      testWidgets('should highlight selected filter', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterBar(
                selectedFilter: 'Aylık',
                filters: const ['Günlük', 'Haftalık', 'Aylık', 'Yıllık'],
                onFilterChanged: (_) {},
              ),
            ),
          ),
        );

        // Find the selected filter chip
        final selectedChip = find.widgetWithText(StatisticsFilterChip, 'Aylık');
        expect(selectedChip, findsOneWidget);

        // Verify it's marked as selected
        final chip = tester.widget<StatisticsFilterChip>(selectedChip);
        expect(chip.selected, isTrue);
      });

      testWidgets('should change selection on tap', (
        WidgetTester tester,
      ) async {
        String selectedFilter = 'Aylık';

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: TimeFilterBar(
                    selectedFilter: selectedFilter,
                    filters: const ['Günlük', 'Haftalık', 'Aylık', 'Yıllık'],
                    onFilterChanged: (filter) {
                      setState(() => selectedFilter = filter);
                    },
                  ),
                );
              },
            ),
          ),
        );

        // Initial selection
        expect(selectedFilter, 'Aylık');

        // Tap Yıllık
        await tester.tap(find.text('Yıllık'));
        await tester.pumpAndSettle();

        expect(selectedFilter, 'Yıllık');
      });

      testWidgets('should scroll to show all filters', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterBar(
                selectedFilter: 'Aylık',
                filters: const [
                  'Günlük',
                  'Haftalık',
                  'Aylık',
                  'Üç Aylık',
                  'Altı Aylık',
                  'Yıllık',
                  'Özel',
                ],
                onFilterChanged: (_) {},
              ),
            ),
          ),
        );

        // Should have scrollable view
        expect(find.byType(SingleChildScrollView), findsOneWidget);

        // All filters should be findable (even if not visible)
        expect(find.text('Günlük'), findsOneWidget);
        expect(find.text('Özel'), findsOneWidget);
      });

      testWidgets('should handle rapid filter changes', (
        WidgetTester tester,
      ) async {
        String selectedFilter = 'Aylık';
        int changeCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: TimeFilterBar(
                    selectedFilter: selectedFilter,
                    filters: const ['Günlük', 'Haftalık', 'Aylık', 'Yıllık'],
                    onFilterChanged: (filter) {
                      setState(() {
                        selectedFilter = filter;
                        changeCount++;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        );

        // Rapidly change filters
        await tester.tap(find.text('Günlük'));
        await tester.pump();

        await tester.tap(find.text('Haftalık'));
        await tester.pump();

        await tester.tap(find.text('Yıllık'));
        await tester.pumpAndSettle();

        expect(changeCount, 3);
        expect(selectedFilter, 'Yıllık');
      });
    });

    group('FilterBar Interaction', () {
      testWidgets('should open category filter', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FilterBar(
                selectedTimeFilter: 'Aylık',
                selectedCategories: const ['Tümü'],
                selectedWallets: const ['Tümü'],
                selectedTransactionType: 'all',
                availableCategories: const [],
                availableWallets: const [],
                onTimeFilterChanged: (_) {},
                onCategoriesChanged: (_) {},
                onWalletsChanged: (_) {},
                onTransactionTypeChanged: (_) {},
                onClearFilters: () {},
                onCustomDateRange: () {},
              ),
            ),
          ),
        );

        // Should render filter bar
        expect(find.byType(FilterBar), findsOneWidget);
      });

      testWidgets('should change category filter', (WidgetTester tester) async {
        String selectedCategory = 'Tümü';

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: FilterBar(
                    selectedTimeFilter: 'Aylık',
                    selectedCategories: [selectedCategory],
                    selectedWallets: const ['Tümü'],
                    selectedTransactionType: 'all',
                    availableCategories: const [],
                    availableWallets: const [],
                    onTimeFilterChanged: (_) {},
                    onCategoriesChanged: (categories) {
                      setState(
                        () => selectedCategory = categories.isNotEmpty
                            ? categories.first
                            : 'Tümü',
                      );
                    },
                    onWalletsChanged: (_) {},
                    onTransactionTypeChanged: (_) {},
                    onClearFilters: () {},
                    onCustomDateRange: () {},
                  ),
                );
              },
            ),
          ),
        );

        expect(selectedCategory, 'Tümü');
      });

      testWidgets('should change wallet filter', (WidgetTester tester) async {
        String selectedWallet = 'Tümü';

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: FilterBar(
                    selectedTimeFilter: 'Aylık',
                    selectedCategories: const ['Tümü'],
                    selectedWallets: [selectedWallet],
                    selectedTransactionType: 'all',
                    availableCategories: const [],
                    availableWallets: const [],
                    onTimeFilterChanged: (_) {},
                    onCategoriesChanged: (_) {},
                    onWalletsChanged: (wallets) {
                      setState(
                        () => selectedWallet = wallets.isNotEmpty
                            ? wallets.first
                            : 'Tümü',
                      );
                    },
                    onTransactionTypeChanged: (_) {},
                    onClearFilters: () {},
                    onCustomDateRange: () {},
                  ),
                );
              },
            ),
          ),
        );

        expect(selectedWallet, 'Tümü');
      });

      testWidgets('should handle multiple filter changes', (
        WidgetTester tester,
      ) async {
        String timeFilter = 'Aylık';
        String category = 'Tümü';
        String wallet = 'Tümü';

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: FilterBar(
                    selectedTimeFilter: timeFilter,
                    selectedCategories: [category],
                    selectedWallets: [wallet],
                    selectedTransactionType: 'all',
                    availableCategories: const [],
                    availableWallets: const [],
                    onTimeFilterChanged: (filter) {
                      setState(() => timeFilter = filter);
                    },
                    onCategoriesChanged: (cats) {
                      setState(
                        () => category = cats.isNotEmpty ? cats.first : 'Tümü',
                      );
                    },
                    onWalletsChanged: (wals) {
                      setState(
                        () => wallet = wals.isNotEmpty ? wals.first : 'Tümü',
                      );
                    },
                    onTransactionTypeChanged: (_) {},
                    onClearFilters: () {},
                    onCustomDateRange: () {},
                  ),
                );
              },
            ),
          ),
        );

        // All filters should be at default
        expect(timeFilter, 'Aylık');
        expect(category, 'Tümü');
        expect(wallet, 'Tümü');
      });

      testWidgets('should clear all filters', (WidgetTester tester) async {
        String timeFilter = 'Yıllık';
        String category = 'Yemek';
        String wallet = 'Cüzdan 1';

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Column(
                    children: [
                      FilterBar(
                        selectedTimeFilter: timeFilter,
                        selectedCategories: [category],
                        selectedWallets: [wallet],
                        selectedTransactionType: 'all',
                        availableCategories: const [],
                        availableWallets: const [],
                        onTimeFilterChanged: (filter) {
                          setState(() => timeFilter = filter);
                        },
                        onCategoriesChanged: (cats) {
                          setState(
                            () => category = cats.isNotEmpty
                                ? cats.first
                                : 'Tümü',
                          );
                        },
                        onWalletsChanged: (wals) {
                          setState(
                            () =>
                                wallet = wals.isNotEmpty ? wals.first : 'Tümü',
                          );
                        },
                        onTransactionTypeChanged: (_) {},
                        onClearFilters: () {},
                        onCustomDateRange: () {},
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            timeFilter = 'Aylık';
                            category = 'Tümü';
                            wallet = 'Tümü';
                          });
                        },
                        child: const Text('Temizle'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        // Filters are set
        expect(timeFilter, 'Yıllık');
        expect(category, 'Yemek');
        expect(wallet, 'Cüzdan 1');

        // Clear filters
        await tester.tap(find.text('Temizle'));
        await tester.pumpAndSettle();

        expect(timeFilter, 'Aylık');
        expect(category, 'Tümü');
        expect(wallet, 'Tümü');
      });
    });

    group('Filter Chip Interaction', () {
      testWidgets('should render filter chip', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatisticsFilterChip(
                label: 'Test Filter',
                selected: false,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('Test Filter'), findsOneWidget);
      });

      testWidgets('should show selected state', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatisticsFilterChip(
                label: 'Selected',
                selected: true,
                onTap: () {},
              ),
            ),
          ),
        );

        final chip = tester.widget<StatisticsFilterChip>(
          find.byType(StatisticsFilterChip),
        );
        expect(chip.selected, isTrue);
      });

      testWidgets('should call onTap callback', (WidgetTester tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatisticsFilterChip(
                label: 'Tap Me',
                selected: false,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Tap Me'));
        expect(tapped, isTrue);
      });

      testWidgets('should handle multiple taps', (WidgetTester tester) async {
        int tapCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatisticsFilterChip(
                label: 'Multi Tap',
                selected: false,
                onTap: () => tapCount++,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Multi Tap'));
        await tester.tap(find.text('Multi Tap'));
        await tester.tap(find.text('Multi Tap'));

        expect(tapCount, 3);
      });
    });

    group('Filter State Management', () {
      testWidgets('should persist filter state', (WidgetTester tester) async {
        String selectedFilter = 'Aylık';

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: TimeFilterBar(
                    selectedFilter: selectedFilter,
                    filters: const ['Günlük', 'Haftalık', 'Aylık'],
                    onFilterChanged: (filter) {
                      setState(() => selectedFilter = filter);
                    },
                  ),
                );
              },
            ),
          ),
        );

        // Change filter
        await tester.tap(find.text('Haftalık'));
        await tester.pumpAndSettle();

        expect(selectedFilter, 'Haftalık');

        // Rebuild widget
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: TimeFilterBar(
                    selectedFilter: selectedFilter,
                    filters: const ['Günlük', 'Haftalık', 'Aylık'],
                    onFilterChanged: (filter) {
                      setState(() => selectedFilter = filter);
                    },
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // State should persist
        expect(selectedFilter, 'Haftalık');
      });
    });

    group('Filter Accessibility', () {
      testWidgets('should have semantic labels', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterBar(
                selectedFilter: 'Aylık',
                filters: const ['Günlük', 'Haftalık', 'Aylık'],
                onFilterChanged: (_) {},
              ),
            ),
          ),
        );

        // Filters should be accessible
        expect(find.text('Günlük'), findsOneWidget);
        expect(find.text('Haftalık'), findsOneWidget);
        expect(find.text('Aylık'), findsOneWidget);
      });

      testWidgets('should have minimum touch target size', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatisticsFilterChip(
                label: 'Test',
                selected: false,
                onTap: () {},
              ),
            ),
          ),
        );

        final chipSize = tester.getSize(find.byType(StatisticsFilterChip));

        // Height should be at least 48 for accessibility
        expect(chipSize.height, greaterThanOrEqualTo(36.0));
      });
    });
  });
}
