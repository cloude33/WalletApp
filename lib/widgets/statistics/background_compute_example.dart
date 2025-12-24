import 'package:flutter/material.dart';
import '../../services/statistics_background_service.dart';
import '../../models/cash_flow_data.dart';
import '../../models/spending_analysis.dart';
import 'background_progress_indicator.dart';
class BackgroundComputeExample extends StatefulWidget {
  const BackgroundComputeExample({super.key});

  @override
  State<BackgroundComputeExample> createState() =>
      _BackgroundComputeExampleState();
}

class _BackgroundComputeExampleState extends State<BackgroundComputeExample>
    with BackgroundProgressMixin {
  final _service = StatisticsBackgroundService();

  CashFlowData? _cashFlow;
  SpendingAnalysis? _spending;
  bool _isLoading = false;
  double _progress = 0.0;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Computation Examples'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExampleCard(
            title: '1. Simple Background Computation',
            description:
                'Run a computation in background without progress tracking',
            onPressed: _example1SimpleComputation,
          ),

          const SizedBox(height: 16),
          _buildExampleCard(
            title: '2. Background Computation with Progress',
            description: 'Run a computation with progress tracking',
            onPressed: _example2WithProgress,
          ),

          const SizedBox(height: 16),
          _buildExampleCard(
            title: '3. Using BackgroundProgressMixin',
            description: 'Simplified API using mixin',
            onPressed: _example3UsingMixin,
          ),

          const SizedBox(height: 16),
          _buildExampleCard(
            title: '4. Batch Operations',
            description: 'Run multiple computations in parallel',
            onPressed: _example4BatchOperations,
          ),

          const SizedBox(height: 16),
          _buildExampleCard(
            title: '5. Error Handling',
            description: 'Demonstrate error handling',
            onPressed: _example5ErrorHandling,
          ),

          const SizedBox(height: 24),
          if (_isLoading)
            BackgroundProgressIndicator.inline(
              progress: _progress,
              message: 'Processing...',
            ),

          if (_error != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Error:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_error!),
                  ],
                ),
              ),
            ),

          if (_cashFlow != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cash Flow Results:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Total Income: ${_cashFlow!.totalIncome.toStringAsFixed(2)} TL'),
                    Text('Total Expense: ${_cashFlow!.totalExpense.toStringAsFixed(2)} TL'),
                    Text('Net Cash Flow: ${_cashFlow!.netCashFlow.toStringAsFixed(2)} TL'),
                    Text('Trend: ${_cashFlow!.trend}'),
                  ],
                ),
              ),
            ),

          if (_spending != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Spending Analysis Results:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Total Spending: ${_spending!.totalSpending.toStringAsFixed(2)} TL'),
                    Text('Top Category: ${_spending!.topCategory}'),
                    Text('Top Amount: ${_spending!.topCategoryAmount.toStringAsFixed(2)} TL'),
                    Text('Most Spending Day: ${_spending!.mostSpendingDay}'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExampleCard({
    required String title,
    required String description,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : onPressed,
              child: const Text('Run Example'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _example1SimpleComputation() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _cashFlow = null;
      _spending = null;
    });

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final cashFlow = await _service.calculateCashFlowInBackground(
        startDate: startOfMonth,
        endDate: now,
      );

      setState(() {
        _cashFlow = cashFlow;
        _isLoading = false;
      });

      _showSuccessSnackBar('Cash flow calculated successfully!');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _example2WithProgress() async {
    setState(() {
      _isLoading = true;
      _progress = 0.0;
      _error = null;
      _cashFlow = null;
      _spending = null;
    });

    try {
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);
      final cashFlow = await _service.calculateCashFlowInBackground(
        startDate: startOfYear,
        endDate: now,
        onProgress: (progress) {
          setState(() => _progress = progress);
        },
      );

      setState(() {
        _cashFlow = cashFlow;
        _isLoading = false;
        _progress = 1.0;
      });

      _showSuccessSnackBar('Cash flow calculated with progress tracking!');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _example3UsingMixin() async {
    setState(() {
      _error = null;
      _cashFlow = null;
      _spending = null;
    });

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final spending = await showBackgroundProgress(
        context,
        message: 'Analyzing spending...',
        computation: () => _service.analyzeSpendingInBackground(
          startDate: startOfMonth,
          endDate: now,
        ),
      );

      setState(() => _spending = spending);

      _showSuccessSnackBar('Spending analyzed using mixin!');
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _example4BatchOperations() async {
    setState(() {
      _isLoading = true;
      _progress = 0.0;
      _error = null;
      _cashFlow = null;
      _spending = null;
    });

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final result = await _service.runBatchOperations(
        operations: [
          StatisticsOperation.cashFlow(
            startOfMonth,
            now,
            key: 'cashFlow',
          ),
          StatisticsOperation.spending(
            startOfMonth,
            now,
            key: 'spending',
          ),
        ],
        onProgress: (progress) {
          setState(() => _progress = progress);
        },
      );

      setState(() {
        _cashFlow = result.getCashFlow('cashFlow');
        _spending = result.getSpending('spending');
        _isLoading = false;
        _progress = 1.0;
      });

      _showSuccessSnackBar('Batch operations completed!');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _example5ErrorHandling() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _cashFlow = null;
      _spending = null;
    });

    try {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 365));

      final cashFlow = await _service.calculateCashFlowInBackground(
        startDate: futureDate,
        endDate: now,
      );

      setState(() {
        _cashFlow = cashFlow;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error caught successfully: ${e.toString()}';
        _isLoading = false;
      });

      _showErrorSnackBar('Error handling demonstration');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
class BackgroundComputeContainerExample extends StatefulWidget {
  const BackgroundComputeContainerExample({super.key});

  @override
  State<BackgroundComputeContainerExample> createState() =>
      _BackgroundComputeContainerExampleState();
}

class _BackgroundComputeContainerExampleState
    extends State<BackgroundComputeContainerExample> {
  final _service = StatisticsBackgroundService();
  bool _isLoading = false;
  double _progress = 0.0;
  CashFlowData? _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _progress = 0.0;
    });

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final cashFlow = await _service.calculateCashFlowInBackground(
        startDate: startOfMonth,
        endDate: now,
        onProgress: (progress) {
          setState(() => _progress = progress);
        },
      );

      setState(() {
        _data = cashFlow;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Container Example'),
      ),
      body: BackgroundProgressContainer(
        isLoading: _isLoading,
        progress: _progress,
        message: 'Loading cash flow data...',
        child: _data != null
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cash Flow Data',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text('Total Income: ${_data!.totalIncome.toStringAsFixed(2)} TL'),
                    Text('Total Expense: ${_data!.totalExpense.toStringAsFixed(2)} TL'),
                    Text('Net Cash Flow: ${_data!.netCashFlow.toStringAsFixed(2)} TL'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Reload'),
                    ),
                  ],
                ),
              )
            : const Center(
                child: Text('No data available'),
              ),
      ),
    );
  }
}
