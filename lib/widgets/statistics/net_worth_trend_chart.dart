import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/asset_analysis.dart';
class NetWorthTrendChart extends StatefulWidget {
  final List<NetWorthTrendData> trendData;
  final double? targetNetWorth;

  const NetWorthTrendChart({
    super.key,
    required this.trendData,
    this.targetNetWorth,
  });

  @override
  State<NetWorthTrendChart> createState() => _NetWorthTrendChartState();
}

class _NetWorthTrendChartState extends State<NetWorthTrendChart> {
  int? _selectedIndex;
  bool _showAssets = true;
  bool _showLiabilities = true;
  bool _showNetWorth = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.trendData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Trend verisi bulunmamaktadır',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 16),
            _buildLegendToggles(theme),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(_buildLineChartData(theme, isDark)),
            ),
            if (_selectedIndex != null) ...[
              const SizedBox(height: 16),
              _buildSelectedPointDetails(theme, isDark),
            ],
            if (widget.targetNetWorth != null) ...[
              const SizedBox(height: 16),
              _buildTargetComparison(theme, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final firstValue = widget.trendData.first.netWorth;
    final lastValue = widget.trendData.last.netWorth;
    final change = lastValue - firstValue;
    final changePercentage = firstValue != 0
        ? (change / firstValue.abs()) * 100
        : 0;
    final isPositive = change >= 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Net Varlık Trendi',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Son 12 ay',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: (isPositive ? Colors.green : Colors.red).withValues(
              alpha: 0.1,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isPositive ? Colors.green : Colors.red).withValues(
                alpha: 0.3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${isPositive ? '+' : ''}${changePercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendToggles(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildLegendToggle(
          'Net Varlık',
          Colors.blue,
          _showNetWorth,
          () => setState(() => _showNetWorth = !_showNetWorth),
          theme,
        ),
        _buildLegendToggle(
          'Varlıklar',
          Colors.green,
          _showAssets,
          () => setState(() => _showAssets = !_showAssets),
          theme,
        ),
        _buildLegendToggle(
          'Borçlar',
          Colors.red,
          _showLiabilities,
          () => setState(() => _showLiabilities = !_showLiabilities),
          theme,
        ),
      ],
    );
  }

  Widget _buildLegendToggle(
    String label,
    Color color,
    bool isActive,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : Colors.grey.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isActive ? color : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildLineChartData(ThemeData theme, bool isDark) {
    final spots = <LineChartBarData>[];
    if (_showNetWorth) {
      spots.add(
        LineChartBarData(
          spots: widget.trendData.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.netWorth);
          }).toList(),
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: _selectedIndex == index ? 6 : 4,
                color: Colors.blue,
                strokeWidth: _selectedIndex == index ? 2 : 0,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withValues(alpha: 0.1),
          ),
        ),
      );
    }
    if (_showAssets) {
      spots.add(
        LineChartBarData(
          spots: widget.trendData.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.assets);
          }).toList(),
          isCurved: true,
          color: Colors.green,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: _selectedIndex == index ? 5 : 3,
                color: Colors.green,
                strokeWidth: _selectedIndex == index ? 2 : 0,
                strokeColor: Colors.white,
              );
            },
          ),
        ),
      );
    }
    if (_showLiabilities) {
      spots.add(
        LineChartBarData(
          spots: widget.trendData.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.liabilities);
          }).toList(),
          isCurved: true,
          color: Colors.red,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: _selectedIndex == index ? 5 : 3,
                color: Colors.red,
                strokeWidth: _selectedIndex == index ? 2 : 0,
                strokeColor: Colors.white,
              );
            },
          ),
        ),
      );
    }
    double minY = 0;
    double maxY = 0;

    for (var data in widget.trendData) {
      if (_showNetWorth) {
        minY = minY < data.netWorth ? minY : data.netWorth;
        maxY = maxY > data.netWorth ? maxY : data.netWorth;
      }
      if (_showAssets) {
        maxY = maxY > data.assets ? maxY : data.assets;
      }
      if (_showLiabilities) {
        maxY = maxY > data.liabilities ? maxY : data.liabilities;
      }
    }
    final range = maxY - minY;
    final padding = range > 0
        ? range * 0.1
        : 1000.0;
    minY -= padding;
    maxY += padding;
    final yRange = maxY - minY;
    final horizontalInterval = yRange > 0 ? yRange / 5.0 : 1000.0;

    return LineChartData(
      lineBarsData: spots,
      minY: minY,
      maxY: maxY,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              return Text(
                _formatCompactCurrency(value),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= widget.trendData.length) {
                return const SizedBox.shrink();
              }

              final date = widget.trendData[index].date;
              final monthName = DateFormat('MMM', 'tr_TR').format(date);

              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  monthName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: horizontalInterval,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            strokeWidth: 1,
          );
        },
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
          left: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        enabled: true,
        touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
          if (event is FlTapUpEvent &&
              response != null &&
              response.lineBarSpots != null) {
            setState(() {
              if (response.lineBarSpots!.isNotEmpty) {
                _selectedIndex = response.lineBarSpots!.first.x.toInt();
              }
            });
          }
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.x.toInt();
              if (index < 0 || index >= widget.trendData.length) {
                return null;
              }

              final data = widget.trendData[index];
              final date = DateFormat('MMM yyyy', 'tr_TR').format(data.date);

              String label;
              Color color;
              if (spot.barIndex == 0 && _showNetWorth) {
                label = 'Net Varlık';
                color = Colors.blue;
              } else if ((_showNetWorth && spot.barIndex == 1) ||
                  (!_showNetWorth && spot.barIndex == 0)) {
                label = 'Varlıklar';
                color = Colors.green;
              } else {
                label = 'Borçlar';
                color = Colors.red;
              }

              return LineTooltipItem(
                '$label\n${_formatCurrency(spot.y)}\n$date',
                TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildSelectedPointDetails(ThemeData theme, bool isDark) {
    if (_selectedIndex == null ||
        _selectedIndex! < 0 ||
        _selectedIndex! >= widget.trendData.length) {
      return const SizedBox.shrink();
    }

    final data = widget.trendData[_selectedIndex!];
    final date = DateFormat('MMMM yyyy', 'tr_TR').format(data.date);
    String? changeText;
    Color? changeColor;
    IconData? changeIcon;

    if (_selectedIndex! > 0) {
      final prevData = widget.trendData[_selectedIndex! - 1];
      final change = data.netWorth - prevData.netWorth;
      final changePercentage = prevData.netWorth != 0
          ? (change / prevData.netWorth.abs()) * 100
          : 0;

      final isPositive = change >= 0;
      changeText =
          '${isPositive ? '+' : ''}${_formatCurrency(change)} (${isPositive ? '+' : ''}${changePercentage.toStringAsFixed(1)}%)';
      changeColor = isPositive ? Colors.green : Colors.red;
      changeIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (changeText != null &&
                  changeColor != null &&
                  changeIcon != null)
                Row(
                  children: [
                    Icon(changeIcon, size: 16, color: changeColor),
                    const SizedBox(width: 4),
                    Text(
                      changeText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: changeColor,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem('Net Varlık', data.netWorth, Colors.blue, theme),
              _buildDetailItem('Varlıklar', data.assets, Colors.green, theme),
              _buildDetailItem('Borçlar', data.liabilities, Colors.red, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    double value,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatCurrency(value),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTargetComparison(ThemeData theme, bool isDark) {
    final currentNetWorth = widget.trendData.last.netWorth;
    final target = widget.targetNetWorth!;
    final difference = currentNetWorth - target;
    final progress = target != 0
        ? (currentNetWorth / target).clamp(0.0, 1.0)
        : 0.0;
    final isAchieved = currentNetWorth >= target;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isAchieved ? Colors.green : Colors.orange).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isAchieved ? Colors.green : Colors.orange).withValues(
            alpha: 0.3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isAchieved ? Icons.check_circle : Icons.flag,
                    color: isAchieved ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hedef Net Varlık',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                _formatCurrency(target),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isAchieved ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isAchieved ? Colors.green : Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAchieved
                    ? 'Hedef başarıldı! 🎉'
                    : 'Hedefe ${_formatCurrency(difference.abs())} kaldı',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isAchieved ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isAchieved ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
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
      return '₺${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return '₺${value.toStringAsFixed(0)}';
    }
  }
}
