import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/cash_flow_data.dart';
import '../../services/statistics_service.dart';
import 'summary_card.dart';
import 'metric_card.dart';
class CashFlowTab extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String? walletId;
  final String? category;

  const CashFlowTab({
    super.key,
    required this.startDate,
    required this.endDate,
    this.walletId,
    this.category,
  });

  @override
  State<CashFlowTab> createState() => _CashFlowTabState();
}

class _CashFlowTabState extends State<CashFlowTab> {
  final StatisticsService _statisticsService = StatisticsService();
  CashFlowData? _cashFlowData;
  bool _isLoading = true;
  String? _error;
  int? _selectedMonthIndex;

  @override
  void initState() {
    super.initState();
    _loadCashFlowData();
  }

  @override
  void didUpdateWidget(CashFlowTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate ||
        oldWidget.walletId != widget.walletId ||
        oldWidget.category != widget.category) {
      _loadCashFlowData();
    }
  }

  Future<void> _loadCashFlowData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _statisticsService.calculateCashFlow(
        startDate: widget.startDate,
        endDate: widget.endDate,
        walletId: widget.walletId,
        category: widget.category,
        includePreviousPeriod: true,
      );

      if (mounted) {
        setState(() {
          _cashFlowData = data;
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Hata: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCashFlowData,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_cashFlowData == null) {
      return const Center(child: Text('Veri bulunamadı'));
    }

    return RefreshIndicator(
      onRefresh: _loadCashFlowData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 16),
          _buildLineChartCard(),
          const SizedBox(height: 16),
          _buildDetailedTable(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final data = _cashFlowData!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Toplam Gelir',
                value: _formatCurrency(data.totalIncome),
                subtitle: _buildChangeText(
                  data.previousPeriodIncome,
                  data.totalIncome,
                ),
                icon: Icons.arrow_downward,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                title: 'Toplam Gider',
                value: _formatCurrency(data.totalExpense),
                subtitle: _buildChangeText(
                  data.previousPeriodExpense,
                  data.totalExpense,
                ),
                icon: Icons.arrow_upward,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Net Akış',
                value: _formatCurrency(data.netCashFlow),
                change: data.changePercentage != null
                    ? '${data.changePercentage! >= 0 ? '+' : ''}${data.changePercentage!.toStringAsFixed(1)}%'
                    : null,
                trend: data.trend,
                color: data.netCashFlow >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: 'Aylık Ortalama',
                value: _formatCurrency(data.averageMonthly),
                color: data.averageMonthly >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        if (data.predictedNetFlow != null) ...[
          const SizedBox(height: 12),
          _buildTrendAnalysisCard(),
        ],
      ],
    );
  }

  Widget _buildTrendAnalysisCard() {
    final data = _cashFlowData!;
    IconData trendIcon;
    Color trendColor;
    String trendText;

    switch (data.trend) {
      case TrendDirection.up:
        trendIcon = Icons.trending_up;
        trendColor = Colors.green;
        trendText = 'Yükseliş Trendi';
        break;
      case TrendDirection.down:
        trendIcon = Icons.trending_down;
        trendColor = Colors.red;
        trendText = 'Düşüş Trendi';
        break;
      case TrendDirection.stable:
        trendIcon = Icons.trending_flat;
        trendColor = Colors.orange;
        trendText = 'Stabil Trend';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(trendIcon, color: trendColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  trendText,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: trendColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Gelecek Dönem Tahmini',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPredictionItem(
                  'Gelir',
                  data.predictedIncome!,
                  Colors.green,
                ),
                _buildPredictionItem(
                  'Gider',
                  data.predictedExpense!,
                  Colors.red,
                ),
                _buildPredictionItem(
                  'Net',
                  data.predictedNetFlow!,
                  data.predictedNetFlow! >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionItem(String label, double value, Color color) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.auto_graph,
              size: 14,
              color: color.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              _formatCurrency(value),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLineChartCard() {
    final data = _cashFlowData!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (data.monthlyData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              'Bu dönem için veri bulunmamaktadır',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      );
    }
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];

    for (int i = 0; i < data.monthlyData.length; i++) {
      final monthData = data.monthlyData[i];
      incomeSpots.add(FlSpot(i.toDouble(), monthData.income));
      expenseSpots.add(FlSpot(i.toDouble(), monthData.expense));
    }
    double maxY = 0;
    for (var monthData in data.monthlyData) {
      if (monthData.income > maxY) maxY = monthData.income;
      if (monthData.expense > maxY) maxY = monthData.expense;
    }
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 1000;

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
                  'Gelir vs Gider',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedMonthIndex != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedMonthIndex = null;
                      });
                    },
                    child: const Text('Temizle'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLegendItem('Gelir', Colors.green),
                const SizedBox(width: 16),
                _buildLegendItem('Gider', Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: maxY / 5,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: (isDark ? Colors.white : Colors.grey).withValues(
                          alpha: 0.1,
                        ),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: (isDark ? Colors.white : Colors.grey).withValues(
                          alpha: 0.1,
                        ),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.monthlyData.length) {
                            final month = data.monthlyData[index].month;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MMM', 'tr_TR').format(month),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.white70 : Colors.grey,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: maxY / 5,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatCompactCurrency(value),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white70 : Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.grey).withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                  minX: 0,
                  maxX: (data.monthlyData.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: incomeSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: _selectedMonthIndex == index ? 6 : 4,
                            color: Colors.green,
                            strokeWidth: 2,
                            strokeColor: isDark ? Colors.black : Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withValues(alpha: 0.2),
                      ),
                    ),
                    LineChartBarData(
                      spots: expenseSpots,
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: _selectedMonthIndex == index ? 6 : 4,
                            color: Colors.red,
                            strokeWidth: 2,
                            strokeColor: isDark ? Colors.black : Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchCallback:
                        (FlTouchEvent event, LineTouchResponse? touchResponse) {
                          if (touchResponse == null ||
                              touchResponse.lineBarSpots == null ||
                              touchResponse.lineBarSpots!.isEmpty) {
                            return;
                          }

                          if (event is FlTapUpEvent) {
                            setState(() {
                              _selectedMonthIndex =
                                  touchResponse.lineBarSpots!.first.spotIndex;
                            });
                          }
                        },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          isDark ? Colors.grey[850]! : Colors.black87,
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final isIncome = barSpot.barIndex == 0;
                          final label = isIncome ? 'Gelir' : 'Gider';
                          return LineTooltipItem(
                            '$label\n${_formatCurrency(barSpot.y)}',
                            TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                  ),
                ),
              ),
            ),
            if (_selectedMonthIndex != null &&
                _selectedMonthIndex! < data.monthlyData.length) ...[
              const SizedBox(height: 16),
              _buildSelectedMonthDetails(
                data.monthlyData[_selectedMonthIndex!],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSelectedMonthDetails(MonthlyData monthData) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            DateFormat('MMMM yyyy', 'tr_TR').format(monthData.month),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem('Gelir', monthData.income, Colors.green),
              _buildDetailItem('Gider', monthData.expense, Colors.red),
              _buildDetailItem(
                'Net',
                monthData.netFlow,
                monthData.netFlow >= 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          _formatCurrency(value),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedTable() {
    final data = _cashFlowData!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (data.monthlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detaylı Aylık Dökümü',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Ay',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Gelir',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Gider',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Net',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...data.monthlyData.asMap().entries.map((entry) {
              final index = entry.key;
              final monthData = entry.value;
              final isSelected = _selectedMonthIndex == index;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedMonthIndex = isSelected ? null : index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                              ? Colors.blue.withValues(alpha: 0.2)
                              : Colors.blue.withValues(alpha: 0.1))
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          DateFormat(
                            'MMM yyyy',
                            'tr_TR',
                          ).format(monthData.month),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatCompactCurrency(monthData.income),
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.green,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatCompactCurrency(monthData.expense),
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatCompactCurrency(monthData.netFlow),
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: monthData.netFlow >= 0
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'TOPLAM',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatCompactCurrency(data.totalIncome),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatCompactCurrency(data.totalExpense),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatCompactCurrency(data.netCashFlow),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: data.netCashFlow >= 0
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return '₺${NumberFormat('#,##0.00', 'tr_TR').format(value.abs())}';
  }

  String _formatCompactCurrency(double value) {
    if (value.abs() >= 1000000) {
      return '₺${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '₺${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return '₺${value.toStringAsFixed(0)}';
    }
  }

  String? _buildChangeText(double? previousValue, double currentValue) {
    if (previousValue == null) return null;

    final change = currentValue - previousValue;
    final changePercent = previousValue != 0
        ? (change / previousValue.abs()) * 100
        : (currentValue != 0 ? 100.0 : 0.0);

    final sign = change >= 0 ? '+' : '';
    return '$sign${changePercent.toStringAsFixed(1)}% önceki döneme göre';
  }
}
