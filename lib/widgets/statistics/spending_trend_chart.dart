import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/spending_analysis.dart';
import '../../models/cash_flow_data.dart';
class SpendingTrendChart extends StatefulWidget {
  final List<CategoryTrend> categoryTrends;
  final Map<String, Color> categoryColors;
  final bool showLegend;
  final double height;

  const SpendingTrendChart({
    super.key,
    required this.categoryTrends,
    required this.categoryColors,
    this.showLegend = true,
    this.height = 300,
  });

  @override
  State<SpendingTrendChart> createState() => _SpendingTrendChartState();
}

class _SpendingTrendChartState extends State<SpendingTrendChart> {
  Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    final sortedTrends = List<CategoryTrend>.from(widget.categoryTrends)
      ..sort((a, b) {
        final aTotal = a.monthlySpending.fold<double>(0, (sum, m) => sum + m.amount);
        final bTotal = b.monthlySpending.fold<double>(0, (sum, m) => sum + m.amount);
        return bTotal.compareTo(aTotal);
      });
    
    _selectedCategories = sortedTrends
        .take(3)
        .map((t) => t.category)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.categoryTrends.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'Trend verisi bulunmamaktadır',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategorySelector(theme),
        const SizedBox(height: 16),
        SizedBox(
          height: widget.height,
          child: _buildLineChart(theme, isDark),
        ),

        if (widget.showLegend) ...[
          const SizedBox(height: 16),
          _buildLegend(theme),
        ],
      ],
    );
  }

  Widget _buildCategorySelector(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.categoryTrends.map((trend) {
        final isSelected = _selectedCategories.contains(trend.category);
        final color = widget.categoryColors[trend.category] ?? Colors.grey;

        return FilterChip(
          label: Text(trend.category),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedCategories.add(trend.category);
              } else {
                _selectedCategories.remove(trend.category);
              }
            });
          },
          selectedColor: color.withValues(alpha: 0.3),
          checkmarkColor: color,
          labelStyle: TextStyle(
            color: isSelected ? color : theme.textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLineChart(ThemeData theme, bool isDark) {
    if (_selectedCategories.isEmpty) {
      return Center(
        child: Text(
          'Görüntülemek için kategori seçin',
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
      );
    }
    final selectedTrends = widget.categoryTrends
        .where((t) => _selectedCategories.contains(t.category))
        .toList();
    double maxY = 0;
    for (var trend in selectedTrends) {
      for (var spending in trend.monthlySpending) {
        if (spending.amount > maxY) {
          maxY = spending.amount;
        }
      }
    }
    maxY = maxY * 1.1;
    final lineBarsData = selectedTrends.map((trend) {
      final color = widget.categoryColors[trend.category] ?? Colors.grey;
      final spots = <FlSpot>[];

      for (int i = 0; i < trend.monthlySpending.length; i++) {
        spots.add(FlSpot(
          i.toDouble(),
          trend.monthlySpending[i].amount,
        ));
      }

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 4,
              color: color,
              strokeWidth: 2,
              strokeColor: isDark ? Colors.black : Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          color: color.withValues(alpha: 0.1),
        ),
      );
    }).toList();

    return LineChart(
      LineChartData(
        lineBarsData: lineBarsData,
        minY: 0,
        maxY: maxY,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatCurrency(value),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || selectedTrends.isEmpty) return const Text('');
                
                final monthlyData = selectedTrends.first.monthlySpending;
                if (index >= monthlyData.length) return const Text('');

                final month = monthlyData[index].month;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('MMM', 'tr_TR').format(month),
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark ? Colors.white12 : Colors.black12,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white24 : Colors.black26,
              width: 1,
            ),
            left: BorderSide(
              color: isDark ? Colors.white24 : Colors.black26,
              width: 1,
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final trendIndex = spot.barIndex;
                if (trendIndex >= selectedTrends.length) return null;

                final trend = selectedTrends[trendIndex];
                final monthIndex = spot.x.toInt();
                if (monthIndex >= trend.monthlySpending.length) return null;

                final monthData = trend.monthlySpending[monthIndex];
                final month = DateFormat('MMM yyyy', 'tr_TR').format(monthData.month);

                return LineTooltipItem(
                  '${trend.category}\n$month\n${_formatCurrency(spot.y)}',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    final selectedTrends = widget.categoryTrends
        .where((t) => _selectedCategories.contains(t.category))
        .toList();

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: selectedTrends.map((trend) {
        final color = widget.categoryColors[trend.category] ?? Colors.grey;
        final trendIcon = trend.trend == TrendDirection.up
            ? Icons.trending_up
            : trend.trend == TrendDirection.down
                ? Icons.trending_down
                : Icons.trending_flat;
        final trendColor = trend.trend == TrendDirection.up
            ? Colors.red
            : trend.trend == TrendDirection.down
                ? Colors.green
                : Colors.grey;

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
            Text(
              trend.category,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 4),
            Icon(
              trendIcon,
              size: 16,
              color: trendColor,
            ),
            const SizedBox(width: 2),
            Text(
              '${trend.changePercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11,
                color: trendColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000) {
      return '₺${(value / 1000).toStringAsFixed(1)}K';
    }
    return '₺${value.toStringAsFixed(0)}';
  }
}
