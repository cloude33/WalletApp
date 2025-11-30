import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/recurring_transaction_service.dart';

class RecurringStatisticsScreen extends StatefulWidget {
  final RecurringTransactionService service;

  const RecurringStatisticsScreen({
    super.key,
    required this.service,
  });

  @override
  State<RecurringStatisticsScreen> createState() =>
      _RecurringStatisticsScreenState();
}

class _RecurringStatisticsScreenState
    extends State<RecurringStatisticsScreen> {
  @override
  Widget build(BuildContext context) {
    final stats = widget.service.getStatistics();
    final categoryBreakdown = widget.service.getCategoryBreakdown();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tekrarlayan İşlem İstatistikleri'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(stats),
            const SizedBox(height: 24),
            _buildCategoryChart(categoryBreakdown),
            const SizedBox(height: 24),
            _buildCategoryList(categoryBreakdown),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, double> stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Toplam Gelir',
                stats['totalIncome'] ?? 0,
                Colors.green,
                Icons.arrow_upward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Toplam Gider',
                stats['totalExpense'] ?? 0,
                Colors.red,
                Icons.arrow_downward,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Net',
          stats['net'] ?? 0,
          (stats['net'] ?? 0) >= 0 ? Colors.green : Colors.red,
          Icons.account_balance,
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    double amount,
    Color color,
    IconData icon, {
    bool isWide = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${amount.toStringAsFixed(2)} ₺',
              style: TextStyle(
                fontSize: isWide ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(Map<String, double> breakdown) {
    if (breakdown.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('Henüz veri yok'),
          ),
        ),
      );
    }

    final total = breakdown.values.fold(0.0, (sum, value) => sum + value);
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategori Dağılımı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: breakdown.entries.toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final category = entry.value.key;
                    final amount = entry.value.value;
                    final percentage = (amount / total * 100);

                    return PieChartSectionData(
                      value: amount,
                      title: '${percentage.toStringAsFixed(0)}%',
                      color: colors[index % colors.length],
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(Map<String, double> breakdown) {
    if (breakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = breakdown.values.fold(0.0, (sum, value) => sum + value);
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    final sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategori Detayları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value.key;
              final amount = entry.value.value;
              final percentage = (amount / total * 100);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[200],
                            color: colors[index % colors.length],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${amount.toStringAsFixed(2)} ₺',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
