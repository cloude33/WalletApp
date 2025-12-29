import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/spending_analysis.dart';
import '../../services/statistics_service.dart';
import 'summary_card.dart';
import 'metric_card.dart';
import 'interactive_pie_chart.dart';
import 'spending_trend_chart.dart';
import 'period_comparison_card.dart';
import 'budget_tracker_card.dart';
import 'spending_habits_card.dart';
class SpendingTab extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final List<String>? categories;
  final Map<String, double>? budgets;

  const SpendingTab({
    super.key,
    required this.startDate,
    required this.endDate,
    this.categories,
    this.budgets,
  });

  @override
  State<SpendingTab> createState() => _SpendingTabState();
}

class _SpendingTabState extends State<SpendingTab> {
  final StatisticsService _statisticsService = StatisticsService();
  SpendingAnalysis? _spendingData;
  SpendingAnalysis? _previousPeriodData;
  bool _isLoading = true;
  String? _error;
  String? _selectedCategory;
  bool _showComparison = false;
  static const Map<String, Color> categoryColors = {
    'Market': Color(0xFF4CAF50),
    'Restoran': Color(0xFFFF9800),
    'Ulaşım': Color(0xFF2196F3),
    'Eğlence': Color(0xFF9C27B0),
    'Sağlık': Color(0xFFF44336),
    'Giyim': Color(0xFFE91E63),
    'Faturalar': Color(0xFF00BCD4),
    'Eğitim': Color(0xFFFFEB3B),
    'Diğer': Color(0xFF607D8B),
  };

  @override
  void initState() {
    super.initState();
    _loadSpendingData();
  }

  @override
  void didUpdateWidget(SpendingTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate ||
        oldWidget.categories != widget.categories ||
        oldWidget.budgets != widget.budgets) {
      _loadSpendingData();
    }
  }

  Future<void> _loadSpendingData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _statisticsService.analyzeSpending(
        startDate: widget.startDate,
        endDate: widget.endDate,
        categories: widget.categories,
        budgets: widget.budgets,
      );
      SpendingAnalysis? previousData;
      if (_showComparison) {
        final periodDuration = widget.endDate.difference(widget.startDate);
        final previousStartDate = widget.startDate.subtract(periodDuration);
        final previousEndDate = widget.startDate.subtract(const Duration(days: 1));

        try {
          previousData = await _statisticsService.analyzeSpending(
            startDate: previousStartDate,
            endDate: previousEndDate,
            categories: widget.categories,
            budgets: widget.budgets,
          );
        } catch (e) {
          previousData = null;
        }
      }

      if (mounted) {
        setState(() {
          _spendingData = data;
          _previousPeriodData = previousData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Hata: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSpendingData,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_spendingData == null) {
      return const Center(
        child: Text('Veri bulunamadı'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSpendingData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _buildComparisonToggle(),
          const SizedBox(height: 16),
          _buildSummaryCards(),
          const SizedBox(height: 16),
          if (_showComparison && _previousPeriodData != null) ...[
            _buildPeriodComparison(),
            const SizedBox(height: 16),
          ],
          if (_spendingData!.budgetComparisons.isNotEmpty) ...[
            BudgetSummaryCard(
              budgetComparisons: _spendingData!.budgetComparisons,
            ),
            const SizedBox(height: 16),
          ],
          _buildPieChartCard(),
          const SizedBox(height: 16),
          if (_spendingData!.categoryTrends.isNotEmpty) ...[
            _buildCategoryTrendCard(),
            const SizedBox(height: 16),
          ],
          if (_spendingData!.budgetComparisons.isNotEmpty) ...[
            BudgetTrackerCard(
              budgetComparisons: _spendingData!.budgetComparisons,
              categoryColors: categoryColors,
            ),
            const SizedBox(height: 16),
          ],
          _buildPaymentMethodCard(),
          const SizedBox(height: 16),
          _buildCategoryList(),
          const SizedBox(height: 16),
          SpendingHabitsCard(
            spendingData: _spendingData!,
            startDate: widget.startDate,
            endDate: widget.endDate,
          ),
          const SizedBox(height: 16),
          _buildSpendingInsights(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final data = _spendingData!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Toplam Harcama',
                value: _formatCurrency(data.totalSpending),
                icon: Icons.shopping_cart,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                title: 'En Çok Harcanan',
                value: data.topCategory.isNotEmpty ? data.topCategory : 'Yok',
                subtitle: data.topCategory.isNotEmpty
                    ? _formatCurrency(data.topCategoryAmount)
                    : null,
                icon: Icons.star,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Kategori Sayısı',
                value: data.categoryBreakdown.length.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: 'Kategori Başına Ort.',
                value: data.categoryBreakdown.isNotEmpty
                    ? _formatCurrency(
                        data.totalSpending / data.categoryBreakdown.length)
                    : '₺0',
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPieChartCard() {
    final data = _spendingData!;
    final theme = Theme.of(context);

    if (data.categoryBreakdown.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              'Bu dönem için harcama bulunmamaktadır',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      );
    }
    final colors = <String, Color>{};
    int colorIndex = 0;
    final defaultColors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFF44336),
      const Color(0xFF00BCD4),
      const Color(0xFFFFEB3B),
      const Color(0xFF795548),
      const Color(0xFF607D8B),
      const Color(0xFFE91E63),
    ];

    data.categoryBreakdown.forEach((category, value) {
      colors[category] = categoryColors[category] ??
          defaultColors[colorIndex % defaultColors.length];
      colorIndex++;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kategori Dağılımı',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedCategory != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = null;
                      });
                    },
                    child: const Text('Temizle'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: InteractivePieChart(
                data: data.categoryBreakdown,
                colors: colors,
                centerSpaceRadius: 50,
                radius: 100,
                showPercentage: true,
                enableTouch: true,
                onSectionTap: (category, value) {
                  setState(() {
                    _selectedCategory =
                        _selectedCategory == category ? null : category;
                  });
                },
              ),
            ),
            if (_selectedCategory != null) ...[
              const SizedBox(height: 16),
              _buildSelectedCategoryDetails(_selectedCategory!),
            ],

            const SizedBox(height: 16),
            _buildLegend(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Map<String, Color> colors) {
    final data = _spendingData!;
    final total = data.totalSpending;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: data.categoryBreakdown.entries.map((entry) {
        final category = entry.key;
        final value = entry.value;
        final percentage = total > 0 ? (value / total) * 100 : 0.0;
        final color = colors[category] ?? Colors.grey;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$category (${percentage.toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSelectedCategoryDetails(String category) {
    final data = _spendingData!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final amount = data.categoryBreakdown[category] ?? 0.0;
    final percentage = data.totalSpending > 0
        ? (amount / data.totalSpending) * 100
        : 0.0;
    final budgetComparison = data.budgetComparisons[category];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem('Tutar', amount, Colors.red),
              _buildDetailItem('Oran', percentage, Colors.blue, suffix: '%'),
              if (budgetComparison != null)
                _buildDetailItem(
                  'Bütçe',
                  budgetComparison.usagePercentage,
                  budgetComparison.exceeded ? Colors.red : Colors.green,
                  suffix: '%',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, double value, Color color,
      {String? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          suffix != null
              ? '${value.toStringAsFixed(1)}$suffix'
              : _formatCurrency(value),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard() {
    final data = _spendingData!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (data.paymentMethodBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ödeme Yöntemi Dağılımı',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ...data.paymentMethodBreakdown.entries.map((entry) {
              final method = entry.key;
              final amount = entry.value;
              final percentage = data.totalSpending > 0
                  ? (amount / data.totalSpending) * 100
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              method == 'Kredi Kartı'
                                  ? Icons.credit_card
                                  : Icons.account_balance,
                              size: 20,
                              color: method == 'Kredi Kartı'
                                  ? Colors.blue
                                  : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              method,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatCurrency(amount),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              minHeight: 8,
                              backgroundColor: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                method == 'Kredi Kartı'
                                    ? Colors.blue
                                    : Colors.green,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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

  Widget _buildCategoryList() {
    final data = _spendingData!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (data.categoryBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }
    final sortedCategories = data.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kategori Detayları',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ...sortedCategories.asMap().entries.map((entry) {
              final index = entry.key;
              final categoryEntry = entry.value;
              final category = categoryEntry.key;
              final amount = categoryEntry.value;
              final percentage = data.totalSpending > 0
                  ? (amount / data.totalSpending) * 100
                  : 0.0;

              final color = categoryColors[category] ??
                  Colors.primaries[index % Colors.primaries.length];
              final budgetComparison = data.budgetComparisons[category];

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory =
                        _selectedCategory == category ? null : category;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedCategory == category
                        ? (isDark
                            ? color.withValues(alpha: 0.2)
                            : color.withValues(alpha: 0.1))
                        : (isDark ? Colors.grey[850] : Colors.grey[50]),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedCategory == category
                          ? color
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${percentage.toStringAsFixed(1)}% toplam harcamadan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatCurrency(amount),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              if (budgetComparison != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  budgetComparison.exceeded
                                      ? 'Bütçe aşıldı!'
                                      : '${budgetComparison.remaining.toStringAsFixed(0)} ₺ kaldı',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: budgetComparison.exceeded
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      if (budgetComparison != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (budgetComparison.usagePercentage / 100)
                                .clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor:
                                isDark ? Colors.grey[800] : Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              budgetComparison.exceeded
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingInsights() {
    final data = _spendingData!;
    final theme = Theme.of(context);
    const dayNames = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];

    final dayName = dayNames[data.mostSpendingDay.index];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Harcama Alışkanlıkları',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInsightRow(
              icon: Icons.calendar_today,
              label: 'En Çok Harcama Yapılan Gün',
              value: dayName,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInsightRow(
              icon: Icons.access_time,
              label: 'En Çok Harcama Yapılan Saat',
              value: '${data.mostSpendingHour}:00',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildInsightRow(
              icon: Icons.trending_up,
              label: 'Günlük Ortalama Harcama',
              value: _formatCurrency(
                data.totalSpending /
                    (widget.endDate.difference(widget.startDate).inDays + 1),
              ),
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
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
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.compare_arrows,
                  size: 20,
                  color: _showComparison ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Dönemsel Karşılaştırma',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _showComparison ? Colors.blue : null,
                  ),
                ),
              ],
            ),
            Switch(
              value: _showComparison,
              onChanged: (value) {
                setState(() {
                  _showComparison = value;
                });
                _loadSpendingData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodComparison() {
    if (_previousPeriodData == null) {
      return const SizedBox.shrink();
    }

    final comparisons = [
      PeriodComparisonData(
        label: 'Toplam Harcama',
        currentValue: _spendingData!.totalSpending,
        previousValue: _previousPeriodData!.totalSpending,
        icon: Icons.shopping_cart,
        color: Colors.red,
        higherIsBetter: false,
      ),
      PeriodComparisonData(
        label: 'En Çok Harcanan Kategori',
        currentValue: _spendingData!.topCategoryAmount,
        previousValue: _previousPeriodData!.topCategoryAmount,
        icon: Icons.star,
        color: Colors.orange,
        higherIsBetter: false,
      ),
      PeriodComparisonData(
        label: 'Kategori Sayısı',
        currentValue: _spendingData!.categoryBreakdown.length.toDouble(),
        previousValue: _previousPeriodData!.categoryBreakdown.length.toDouble(),
        icon: Icons.category,
        color: Colors.blue,
        higherIsBetter: false,
      ),
    ];

    return PeriodComparisonList(comparisons: comparisons);
  }

  Widget _buildCategoryTrendCard() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kategori Trendleri',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.trending_up,
                  size: 20,
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Kategorilerin zaman içindeki harcama değişimini görün',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SpendingTrendChart(
              categoryTrends: _spendingData!.categoryTrends,
              categoryColors: categoryColors,
              showLegend: true,
              height: 300,
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return '₺${NumberFormat('#,##0.00', 'tr_TR').format(value.abs())}';
  }
}
