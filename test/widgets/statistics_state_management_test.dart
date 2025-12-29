import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/widgets/statistics/statistics_loading_state.dart';
import 'package:money/widgets/statistics/statistics_skeleton_loader.dart';
import 'package:money/widgets/statistics/statistics_error_state.dart';
import 'package:money/widgets/statistics/statistics_empty_state.dart';
import 'package:money/widgets/statistics/statistics_state_builder.dart';

void main() {
  group('StatisticsLoadingState', () {
    testWidgets('displays loading indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatisticsLoadingState(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays message when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatisticsLoadingState(
              message: 'Loading data...',
            ),
          ),
        ),
      );

      expect(find.text('Loading data...'), findsOneWidget);
    });

    testWidgets('displays logo when showLogo is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatisticsLoadingState(
              showLogo: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
    });
  });

  group('InlineLoadingIndicator', () {
    testWidgets('displays small loading indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InlineLoadingIndicator(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays message when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InlineLoadingIndicator(
              message: 'Processing...',
            ),
          ),
        ),
      );

      expect(find.text('Processing...'), findsOneWidget);
    });
  });

  group('LoadingOverlay', () {
    testWidgets('shows child when not loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              isLoading: false,
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows overlay when loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              isLoading: true,
              message: 'Please wait...',
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Please wait...'), findsOneWidget);
    });
  });

  group('StatisticsSkeletonLoader', () {
    testWidgets('displays skeleton loader', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatisticsSkeletonLoader(
              itemCount: 3,
              type: SkeletonType.card,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(StatisticsSkeletonLoader), findsOneWidget);
    });

    testWidgets('animates skeleton items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatisticsSkeletonLoader(
              itemCount: 1,
              type: SkeletonType.card,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Animation should be running
      expect(find.byType(StatisticsSkeletonLoader), findsOneWidget);
    });
  });

  group('ChartSkeletonLoader', () {
    testWidgets('displays line chart skeleton', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChartSkeletonLoader(
              type: ChartSkeletonType.line,
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('displays pie chart skeleton', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChartSkeletonLoader(
              type: ChartSkeletonType.pie,
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('StatisticsErrorState', () {
    testWidgets('displays error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatisticsErrorState(
              message: 'Error occurred',
            ),
          ),
        ),
      );

      expect(find.text('Error occurred'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays details when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatisticsErrorState(
              message: 'Error occurred',
              details: 'Detailed error message',
            ),
          ),
        ),
      );

      expect(find.text('Error occurred'), findsOneWidget);
      expect(find.text('Detailed error message'), findsOneWidget);
    });

    testWidgets('calls onRetry when retry button pressed', (tester) async {
      var retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsErrorState(
              message: 'Error occurred',
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tekrar Dene'));
      expect(retryPressed, true);
    });
  });

  group('InlineErrorWidget', () {
    testWidgets('displays error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InlineErrorWidget(
              message: 'Error message',
            ),
          ),
        ),
      );

      expect(find.text('Error message'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (tester) async {
      var retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineErrorWidget(
              message: 'Error message',
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      await tester.tap(find.byIcon(Icons.refresh));
      expect(retryPressed, true);
    });
  });

  group('StatisticsEmptyState', () {
    testWidgets('displays empty state message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatisticsEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No Data',
              message: 'No data available',
            ),
          ),
        ),
      );

      expect(find.text('No Data'), findsOneWidget);
      expect(find.text('No data available'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('shows action button when provided', (tester) async {
      var actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No Data',
              message: 'No data available',
              actionLabel: 'Add Data',
              onAction: () => actionPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Add Data'), findsOneWidget);
      await tester.tap(find.text('Add Data'));
      expect(actionPressed, true);
    });
  });

  group('StatisticsManualStateBuilder', () {
    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsManualStateBuilder<String>(
              state: DataState.loading,
              builder: (context, data) => Text(data),
            ),
          ),
        ),
      );

      expect(find.byType(StatisticsSkeletonLoader), findsOneWidget);
    });

    testWidgets('shows error state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsManualStateBuilder<String>(
              state: DataState.error,
              error: 'Test error',
              builder: (context, data) => Text(data),
            ),
          ),
        ),
      );

      expect(find.byType(StatisticsErrorState), findsOneWidget);
    });

    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsManualStateBuilder<String>(
              state: DataState.empty,
              builder: (context, data) => Text(data),
            ),
          ),
        ),
      );

      expect(find.byType(StatisticsEmptyState), findsOneWidget);
    });

    testWidgets('shows success state with data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsManualStateBuilder<String>(
              state: DataState.success,
              data: 'Test Data',
              builder: (context, data) => Text(data),
            ),
          ),
        ),
      );

      expect(find.text('Test Data'), findsOneWidget);
    });

    testWidgets('calls onRetry in error state', (tester) async {
      var retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsManualStateBuilder<String>(
              state: DataState.error,
              error: 'Test error',
              builder: (context, data) => Text(data),
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tekrar Dene'));
      expect(retryPressed, true);
    });
  });

  group('StatisticsFutureBuilder', () {
    testWidgets('shows loading then success', (tester) async {
      final future = Future.delayed(
        const Duration(milliseconds: 100),
        () => 'Success Data',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsFutureBuilder<String>(
              future: future,
              builder: (context, data) => Text(data),
            ),
          ),
        ),
      );

      // Should show loading
      expect(find.byType(StatisticsSkeletonLoader), findsOneWidget);

      // Wait for future to complete
      await tester.pumpAndSettle();

      // Should show success
      expect(find.text('Success Data'), findsOneWidget);
    });

    testWidgets('shows error on future error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsFutureBuilder<String>(
              future: Future<String>.error(Exception('Test error')),
              builder: (context, data) => Text(data),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(StatisticsErrorState), findsOneWidget);
    });

    testWidgets('uses custom loading builder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsFutureBuilder<String>(
              future: Future.delayed(
                const Duration(milliseconds: 100),
                () => 'Success Data',
              ),
              builder: (context, data) => Text(data),
              loadingBuilder: (context) => const Text('Custom Loading'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Loading'), findsOneWidget);
      
      await tester.pumpAndSettle();
    });

    testWidgets('uses custom error builder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsFutureBuilder<String>(
              future: Future<String>.error(Exception('Test error')),
              builder: (context, data) => Text(data),
              errorBuilder: (context, error) => Text('Custom Error: $error'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Custom Error'), findsOneWidget);
    });

    testWidgets('uses custom empty builder', (tester) async {
      final future = Future.value(<String>[]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsFutureBuilder<List<String>>(
              future: future,
              builder: (context, data) => Text('Data: ${data.length}'),
              emptyBuilder: (context) => const Text('Custom Empty'),
              isEmpty: (data) => data.isEmpty,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Custom Empty'), findsOneWidget);
    });
  });

  group('Predefined Empty States', () {
    testWidgets('noTransactions displays correct message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsEmptyStates.noTransactions(),
          ),
        ),
      );

      expect(find.text('Henüz İşlem Yok'), findsOneWidget);
    });

    testWidgets('noCashFlowData displays correct message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsEmptyStates.noCashFlowData(),
          ),
        ),
      );

      expect(find.text('Nakit Akışı Verisi Yok'), findsOneWidget);
    });

    testWidgets('noSpendingData displays correct message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsEmptyStates.noSpendingData(),
          ),
        ),
      );

      expect(find.text('Harcama Verisi Yok'), findsOneWidget);
    });
  });

  group('Predefined Error States', () {
    testWidgets('noData displays correct message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsErrorStates.noData(),
          ),
        ),
      );

      expect(find.text('Veri Bulunamadı'), findsOneWidget);
    });

    testWidgets('calculationError displays correct message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsErrorStates.calculationError(),
          ),
        ),
      );

      expect(find.text('Hesaplama Hatası'), findsOneWidget);
    });

    testWidgets('networkError displays correct message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsErrorStates.networkError(),
          ),
        ),
      );

      expect(find.text('Bağlantı Hatası'), findsOneWidget);
    });
  });
}
