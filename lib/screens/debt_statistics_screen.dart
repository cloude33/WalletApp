import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/debt.dart';
import '../services/debt_service.dart';

class DebtStatisticsScreen extends StatefulWidget {
  const DebtStatisticsScreen({super.key});

  @override
  State<DebtStatisticsScreen> createState() => _DebtStatisticsScreenState();
}

class _DebtStatisticsScreenState extends State<DebtStatisticsScreen> {
  final DebtService _debtService = DebtService();

  bool _isLoading = true;
  double _totalLent = 0;
  double _totalBorrowed = 0;
  double _netBalance = 0;
  int _activeCount = 0;
  int _overdueCount = 0;

  List<Debt> _allDebts = [];
  Map<DebtCategory, double> _categoryBreakdown = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final lent = await _debtService.getTotalLent();
      final borrowed = await _debtService.getTotalBorrowed();
      final net = await _debtService.getNetBalance();
      final activeCount = await _debtService.getActiveCount();
      final overdueCount = await _debtService.getOverdueCount();
      final debts = await _debtService.getDebts();
      final categoryBreakdown = <DebtCategory, double>{};
      for (final debt in debts) {
        if (debt.status != DebtStatus.paid) {
          categoryBreakdown[debt.category] =
              (categoryBreakdown[debt.category] ?? 0) + debt.remainingAmount;
        }
      }

      setState(() {
        _totalLent = lent;
        _totalBorrowed = borrowed;
        _netBalance = net;
        _activeCount = activeCount;
        _overdueCount = overdueCount;
        _allDebts = debts;
        _categoryBreakdown = categoryBreakdown;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İstatistikler')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 16),
                  _buildCategoryChart(),
                  const SizedBox(height: 16),
                  _buildTopDebts(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    final formatter = NumberFormat('#,##0.00', 'tr_TR');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Toplam Alacak',
                '₺${formatter.format(_totalLent)}',
                Icons.trending_up,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Toplam Borç',
                '₺${formatter.format(_totalBorrowed)}',
                Icons.trending_down,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Net Durum',
                '₺${formatter.format(_netBalance)}',
                _netBalance >= 0 ? Icons.add_circle : Icons.remove_circle,
                _netBalance >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Aktif',
                '$_activeCount',
                Icons.account_balance_wallet,
                Colors.blue,
              ),
            ),
          ],
        ),
        if (_overdueCount > 0) ...[
          const SizedBox(height: 12),
          _buildStatCard(
            'Vadesi Geçmiş',
            '$_overdueCount',
            Icons.warning,
            Colors.orange,
            fullWidth: true,
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: fullWidth ? 24 : 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart() {
    if (_categoryBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategori Dağılımı',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final total = _categoryBreakdown.values.fold<double>(
      0,
      (sum, v) => sum + v,
    );
    final colors = {
      DebtCategory.friend: Colors.blue,
      DebtCategory.family: Colors.green,
      DebtCategory.business: Colors.orange,
      DebtCategory.other: Colors.purple,
    };

    return _categoryBreakdown.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        color: colors[entry.key],
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    final colors = {
      DebtCategory.friend: Colors.blue,
      DebtCategory.family: Colors.green,
      DebtCategory.business: Colors.orange,
      DebtCategory.other: Colors.purple,
    };

    final labels = {
      DebtCategory.friend: 'Arkadaş',
      DebtCategory.family: 'Aile',
      DebtCategory.business: 'İş',
      DebtCategory.other: 'Diğer',
    };

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: _categoryBreakdown.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: colors[entry.key],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(labels[entry.key]!, style: const TextStyle(fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTopDebts() {
    final sortedDebts = List<Debt>.from(_allDebts)
      ..sort((a, b) => b.remainingAmount.compareTo(a.remainingAmount));
    final topDebts = sortedDebts.take(5).toList();

    if (topDebts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'En Yüksek Tutarlar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...topDebts.map((debt) => _buildDebtItem(debt)),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtItem(Debt debt) {
    final formatter = NumberFormat('#,##0.00', 'tr_TR');
    final isLent = debt.type == DebtType.lent;
    final color = isLent ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            radius: 20,
            child: Icon(
              isLent ? Icons.trending_up : Icons.trending_down,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.personName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  debt.categoryText,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '₺${formatter.format(debt.remainingAmount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
