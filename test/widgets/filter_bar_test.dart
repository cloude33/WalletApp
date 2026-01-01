import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/category.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/widgets/statistics/filter_bar.dart';

void main() {
  group('FilterBar Widget', () {
    late List<Category> testCategories;
    late List<Wallet> testWallets;

    setUp(() {
      testCategories = [
        Category(
          id: 'cat1',
          name: 'Food',
          icon: Icons.restaurant,
          color: const Color(0xFFFF5722),
          type: 'expense',
        ),
        Category(
          id: 'cat2',
          name: 'Shopping',
          icon: Icons.shopping_cart,
          color: const Color(0xFF2196F3),
          type: 'expense',
        ),
        Category(
          id: 'cat3',
          name: 'Transport',
          icon: Icons.directions_car,
          color: const Color(0xFF4CAF50),
          type: 'expense',
        ),
      ];

      testWallets = [
        Wallet(
          id: 'wallet1',
          name: 'Cash',
          balance: 1000.0,
          type: 'cash',
          color: '0xFF4CAF50',
          icon: 'money',
          creditLimit: 0.0,
        ),
        Wallet(
          id: 'wallet2',
          name: 'Bank Account',
          balance: 5000.0,
          type: 'bank',
          color: '0xFF2196F3',
          icon: 'account_balance',
          creditLimit: 0.0,
        ),
      ];
    });

    testWidgets('displays time filter chips', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              selectedTimeFilter: 'Aylık',
              selectedCategories: const [],
              selectedWallets: const [],
              selectedTransactionType: 'all',
              availableCategories: testCategories,
              availableWallets: testWallets,
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

      // Verify time filter chips are displayed
      expect(find.text('Günlük'), findsOneWidget);
      expect(find.text('Haftalık'), findsOneWidget);
      expect(find.text('Aylık'), findsOneWidget);
      expect(find.text('Yıllık'), findsOneWidget);
      expect(find.text('Özel'), findsOneWidget);
    });

    testWidgets('highlights selected time filter', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              selectedTimeFilter: 'Haftalık',
              selectedCategories: const [],
              selectedWallets: const [],
              selectedTransactionType: 'all',
              availableCategories: testCategories,
              availableWallets: testWallets,
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

      // Find the selected chip container
      final weeklyChip = find.ancestor(
        of: find.text('Haftalık'),
        matching: find.byType(Container),
      );

      expect(weeklyChip, findsWidgets);
    });

    testWidgets('calls onTimeFilterChanged when chip is tapped',
        (WidgetTester tester) async {
      String? selectedFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              selectedTimeFilter: 'Aylık',
              selectedCategories: const [],
              selectedWallets: const [],
              selectedTransactionType: 'all',
              availableCategories: testCategories,
              availableWallets: testWallets,
              onTimeFilterChanged: (filter) {
                selectedFilter = filter;
              },
              onCategoriesChanged: (_) {},
              onWalletsChanged: (_) {},
              onTransactionTypeChanged: (_) {},
              onClearFilters: () {},
              onCustomDateRange: () {},
            ),
          ),
        ),
      );

      // Tap on weekly filter
      await tester.tap(find.text('Haftalık'));
      await tester.pumpAndSettle();

      expect(selectedFilter, 'Haftalık');
    });

    testWidgets('shows additional filter buttons when filters are active',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              selectedTimeFilter: 'Aylık',
              selectedCategories: const ['cat1'],
              selectedWallets: const [],
              selectedTransactionType: 'all',
              availableCategories: testCategories,
              availableWallets: testWallets,
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

      // Should show filter buttons
      expect(find.text('1 Kategori'), findsOneWidget);
    });

    testWidgets('displays removable chips for selected categories',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              selectedTimeFilter: 'Aylık',
              selectedCategories: const ['cat1', 'cat2'],
              selectedWallets: const [],
              selectedTransactionType: 'all',
              availableCategories: testCategories,
              availableWallets: testWallets,
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

      // Should show category chips
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Shopping'), findsOneWidget);
    });

    testWidgets('calls onClearFilters when clear button is tapped',
        (WidgetTester tester) async {
      bool clearCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              selectedTimeFilter: 'Aylık',
              selectedCategories: const ['cat1'],
              selectedWallets: const [],
              selectedTransactionType: 'expense',
              availableCategories: testCategories,
              availableWallets: testWallets,
              onTimeFilterChanged: (_) {},
              onCategoriesChanged: (_) {},
              onWalletsChanged: (_) {},
              onTransactionTypeChanged: (_) {},
              onClearFilters: () {
                clearCalled = true;
              },
              onCustomDateRange: () {},
            ),
          ),
        ),
      );

      // Find and tap clear button
      final clearButton = find.byIcon(Icons.clear_all);
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(clearCalled, true);
    });

    testWidgets('shows custom date range when selected',
        (WidgetTester tester) async {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              selectedTimeFilter: 'Özel',
              selectedCategories: const [],
              selectedWallets: const [],
              selectedTransactionType: 'all',
              customStartDate: startDate,
              customEndDate: endDate,
              availableCategories: testCategories,
              availableWallets: testWallets,
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

      // Should show custom date range
      expect(find.text('01/01 - 31/01'), findsOneWidget);
    });

    testWidgets('calls onCustomDateRange when custom chip is tapped',
        (WidgetTester tester) async {
      bool customDateCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              selectedTimeFilter: 'Aylık',
              selectedCategories: const [],
              selectedWallets: const [],
              selectedTransactionType: 'all',
              availableCategories: testCategories,
              availableWallets: testWallets,
              onTimeFilterChanged: (_) {},
              onCategoriesChanged: (_) {},
              onWalletsChanged: (_) {},
              onTransactionTypeChanged: (_) {},
              onClearFilters: () {},
              onCustomDateRange: () {
                customDateCalled = true;
              },
            ),
          ),
        ),
      );

      // Tap on custom date chip
      await tester.tap(find.text('Özel'));
      await tester.pumpAndSettle();

      expect(customDateCalled, true);
    });

    testWidgets('displays wallet filter button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              selectedTimeFilter: 'Aylık',
              selectedCategories: const ['cat1'],
              selectedWallets: const [],
              selectedTransactionType: 'all',
              availableCategories: testCategories,
              availableWallets: testWallets,
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

      // Should show wallet filter button
      expect(find.text('Cüzdan'), findsOneWidget);
    });

    testWidgets('displays transaction type filter button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              selectedTimeFilter: 'Aylık',
              selectedCategories: const ['cat1'],
              selectedWallets: const [],
              selectedTransactionType: 'all',
              availableCategories: testCategories,
              availableWallets: testWallets,
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

      // Should show transaction type filter button
      expect(find.text('Tümü'), findsOneWidget);
    });

    testWidgets('removes category chip when close icon is tapped',
        (WidgetTester tester) async {
      List<String> selectedCategories = ['cat1', 'cat2'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FilterBar(
                  selectedTimeFilter: 'Aylık',
                  selectedCategories: selectedCategories,
                  selectedWallets: const [],
                  selectedTransactionType: 'all',
                  availableCategories: testCategories,
                  availableWallets: testWallets,
                  onTimeFilterChanged: (_) {},
                  onCategoriesChanged: (categories) {
                    setState(() {
                      selectedCategories = categories;
                    });
                  },
                  onWalletsChanged: (_) {},
                  onTransactionTypeChanged: (_) {},
                  onClearFilters: () {},
                  onCustomDateRange: () {},
                );
              },
            ),
          ),
        ),
      );

      // Verify both chips are present
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Shopping'), findsOneWidget);

      // Find close icon for Food chip and tap it
      final foodChipCloseIcon = find.descendant(
        of: find.ancestor(
          of: find.text('Food'),
          matching: find.byType(Container),
        ),
        matching: find.byIcon(Icons.close),
      );

      await tester.tap(foodChipCloseIcon.first);
      await tester.pumpAndSettle();

      // Verify the category was removed
      expect(selectedCategories.contains('cat1'), false);
      expect(selectedCategories.contains('cat2'), true);
    });

    testWidgets('clear filters button resets all filters - Requirement 7.5',
        (WidgetTester tester) async {
      bool clearCalled = false;
      List<String> selectedCategories = ['cat1', 'cat2'];
      List<String> selectedWallets = ['wallet1'];
      String selectedTransactionType = 'expense';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FilterBar(
                  selectedTimeFilter: 'Aylık',
                  selectedCategories: selectedCategories,
                  selectedWallets: selectedWallets,
                  selectedTransactionType: selectedTransactionType,
                  availableCategories: testCategories,
                  availableWallets: testWallets,
                  onTimeFilterChanged: (_) {},
                  onCategoriesChanged: (categories) {
                    setState(() {
                      selectedCategories = categories;
                    });
                  },
                  onWalletsChanged: (wallets) {
                    setState(() {
                      selectedWallets = wallets;
                    });
                  },
                  onTransactionTypeChanged: (type) {
                    setState(() {
                      selectedTransactionType = type;
                    });
                  },
                  onClearFilters: () {
                    setState(() {
                      clearCalled = true;
                      selectedCategories = [];
                      selectedWallets = [];
                      selectedTransactionType = 'all';
                    });
                  },
                  onCustomDateRange: () {},
                );
              },
            ),
          ),
        ),
      );

      // Verify filters are active
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Shopping'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('2 Kategori'), findsOneWidget);
      expect(find.text('1 Cüzdan'), findsOneWidget);
      expect(find.text('Gider'), findsOneWidget);

      // Find and tap clear button
      final clearButton = find.byIcon(Icons.clear_all);
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Verify clear was called
      expect(clearCalled, true);

      // Verify all filters are reset
      expect(selectedCategories, isEmpty);
      expect(selectedWallets, isEmpty);
      expect(selectedTransactionType, 'all');
    });

    testWidgets('clear button shows snackbar confirmation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              selectedTimeFilter: 'Aylık',
              selectedCategories: const ['cat1'],
              selectedWallets: const [],
              selectedTransactionType: 'expense',
              availableCategories: testCategories,
              availableWallets: testWallets,
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

      // Find and tap clear button
      final clearButton = find.byIcon(Icons.clear_all);
      await tester.tap(clearButton);
      await tester.pump();

      // Verify snackbar is shown
      expect(find.text('Filtreler temizlendi'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('clear button is not visible when no filters are active',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              selectedTimeFilter: 'Aylık',
              selectedCategories: const [],
              selectedWallets: const [],
              selectedTransactionType: 'all',
              availableCategories: testCategories,
              availableWallets: testWallets,
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

      // Clear button should not be visible
      expect(find.byIcon(Icons.clear_all), findsNothing);
    });

    testWidgets('clear button is visible when any filter is active',
        (WidgetTester tester) async {
      // Test with only category filter
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              selectedTimeFilter: 'Aylık',
              selectedCategories: const ['cat1'],
              selectedWallets: const [],
              selectedTransactionType: 'all',
              availableCategories: testCategories,
              availableWallets: testWallets,
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

      expect(find.byIcon(Icons.clear_all), findsOneWidget);
    });
  });
}
