import 'package:flutter/material.dart';
import 'statistics_state_builder.dart';
import 'statistics_loading_state.dart';
import 'statistics_error_state.dart';
import 'statistics_empty_state.dart';
import 'statistics_skeleton_loader.dart';
import '../../models/cash_flow_data.dart';

/// Example demonstrating various state management patterns
class StateManagementExample extends StatefulWidget {
  const StateManagementExample({super.key});

  @override
  State<StateManagementExample> createState() => _StateManagementExampleState();
}

class _StateManagementExampleState extends State<StateManagementExample> {
  DataState _manualState = DataState.loading;
  CashFlowData? _data;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _manualState = DataState.loading;
      _error = null;
    });

    try {
      // Simulate data loading
      await Future.delayed(const Duration(seconds: 2));

      // Simulate success or error randomly
      if (DateTime.now().second % 2 == 0) {
        setState(() {
          _data = CashFlowData(
            totalIncome: 5000,
            totalExpense: 3000,
            netCashFlow: 2000,
            averageDaily: 66.67,
            averageMonthly: 2000,
            monthlyData: [],
            trend: TrendDirection.up,
          );
          _manualState = DataState.success;
        });
      } else {
        throw Exception('Simulated error');
      }
    } catch (e) {
      setState(() {
        _error = e;
        _manualState = DataState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('State Management Examples'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFutureBuilderExample(),
          const SizedBox(height: 24),
          _buildManualStateExample(),
          const SizedBox(height: 24),
          _buildLoadingStatesExample(),
          const SizedBox(height: 24),
          _buildErrorStatesExample(),
          const SizedBox(height: 24),
          _buildEmptyStatesExample(),
          const SizedBox(height: 24),
          _buildSkeletonLoadersExample(),
        ],
      ),
    );
  }

  Widget _buildFutureBuilderExample() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Future Builder Example',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: StatisticsFutureBuilder<CashFlowData>(
                future: _simulateDataFetch(),
                builder: (context, data) {
                  return Center(
                    child: Text(
                      'Net Cash Flow: ${data.netCashFlow}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                },
                emptyBuilder: (context) {
                  return StatisticsEmptyStates.noCashFlowData();
                },
                onRetry: () {
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualStateExample() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manual State Example',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: StatisticsManualStateBuilder<CashFlowData>(
                state: _manualState,
                data: _data,
                error: _error,
                builder: (context, data) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Net Cash Flow: ${data.netCashFlow}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Reload'),
                        ),
                      ],
                    ),
                  );
                },
                onRetry: _loadData,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingStatesExample() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loading States',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              height: 100,
              child: StatisticsLoadingState(
                message: 'İstatistikler yükleniyor...',
              ),
            ),
            const Divider(height: 32),
            const InlineLoadingIndicator(
              message: 'Veriler işleniyor...',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorStatesExample() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Error States',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            InlineErrorWidget(
              message: 'Veriler yüklenirken bir hata oluştu',
              onRetry: () {
                StatisticsErrorSnackbar.show(
                  context,
                  'Tekrar deneniyor...',
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                StatisticsSuccessSnackbar.show(
                  context,
                  'İşlem başarıyla tamamlandı',
                );
              },
              child: const Text('Show Success'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                StatisticsWarningSnackbar.show(
                  context,
                  'Dikkat: Bazı veriler eksik olabilir',
                );
              },
              child: const Text('Show Warning'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStatesExample() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Empty States',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: StatisticsEmptyStates.noTransactions(
                onAddTransaction: () {
                  StatisticsSuccessSnackbar.show(
                    context,
                    'İşlem ekleme ekranına yönlendiriliyorsunuz',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoadersExample() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Skeleton Loaders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const StatisticsSkeletonLoader(
              itemCount: 2,
              type: SkeletonType.card,
            ),
            const SizedBox(height: 16),
            const ChartSkeletonLoader(
              type: ChartSkeletonType.line,
            ),
          ],
        ),
      ),
    );
  }

  Future<CashFlowData> _simulateDataFetch() async {
    await Future.delayed(const Duration(seconds: 2));
    return CashFlowData(
      totalIncome: 5000,
      totalExpense: 3000,
      netCashFlow: 2000,
      averageDaily: 66.67,
      averageMonthly: 2000,
      monthlyData: [],
      trend: TrendDirection.up,
    );
  }
}
