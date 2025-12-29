import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
class InteractiveBarChart extends StatefulWidget {
  final Map<String, double> data;
  final Color color;
  final double barWidth;
  final bool showValues;
  final double? minY;
  final double? maxY;
  final String? title;
  final Function(String label, double value)? onBarTap;
  final bool showGrid;
  final bool enableTouch;
  final Widget Function(String label)? labelBuilder;

  const InteractiveBarChart({
    super.key,
    required this.data,
    required this.color,
    this.barWidth = 22,
    this.showValues = true,
    this.minY,
    this.maxY,
    this.title,
    this.onBarTap,
    this.showGrid = true,
    this.enableTouch = true,
    this.labelBuilder,
  });

  @override
  State<InteractiveBarChart> createState() => _InteractiveBarChartState();
}

class _InteractiveBarChartState extends State<InteractiveBarChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    double minY = widget.minY ?? 0;
    double maxY = widget.maxY ?? 100;

    if (widget.data.isNotEmpty) {
      final values = widget.data.values.toList();
      minY = widget.minY ?? values.reduce((a, b) => a < b ? a : b);
      maxY = widget.maxY ?? values.reduce((a, b) => a > b ? a : b);
      final range = maxY - minY;
      if (range > 0) {
        minY = minY - (range * 0.1);
        if (minY < 0 && values.every((v) => v >= 0)) {
          minY = 0;
        }
        maxY = maxY + (range * 0.1);
      } else {
        minY = minY - 10;
        maxY = maxY + 10;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              widget.title!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: BarChart(
              _createBarChartData(minY, maxY, isDark),
              // Increased animation duration for smoother chart animations
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            ),
          ),
        ),
      ],
    );
  }

  BarChartData _createBarChartData(double minY, double maxY, bool isDark) {
    final barGroups = <BarChartGroupData>[];
    int index = 0;

    widget.data.forEach((label, value) {
      final isTouched = touchedIndex == index;

      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value,
              color: widget.color,
              width: isTouched ? widget.barWidth + 4 : widget.barWidth,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY,
                color: (isDark ? Colors.white : Colors.grey).withValues(
                  alpha: 0.1,
                ),
              ),
            ),
          ],
          showingTooltipIndicators: widget.showValues && isTouched ? [0] : [],
        ),
      );
      index++;
    });

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      minY: minY,
      barGroups: barGroups,
      gridData: FlGridData(
        show: widget.showGrid,
        drawVerticalLine: false,
        horizontalInterval: (maxY - minY) > 0 ? (maxY - minY) / 5 : 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.1),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              final labels = widget.data.keys.toList();
              if (value.toInt() >= 0 && value.toInt() < labels.length) {
                final label = labels[value.toInt()];
                if (widget.labelBuilder != null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: widget.labelBuilder!(label),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white70 : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
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
            interval: (maxY - minY) > 0 ? (maxY - minY) / 5 : 1,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              return Text(
                _formatValue(value),
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
          color: (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.2),
        ),
      ),
      barTouchData: BarTouchData(
        enabled: widget.enableTouch,
        touchCallback: (FlTouchEvent event, barTouchResponse) {
          setState(() {
            if (!widget.enableTouch ||
                barTouchResponse == null ||
                barTouchResponse.spot == null) {
              touchedIndex = null;
              return;
            }

            final index = barTouchResponse.spot!.touchedBarGroupIndex;
            touchedIndex = index;

            if (widget.onBarTap != null && event is FlTapUpEvent) {
              final labels = widget.data.keys.toList();
              final values = widget.data.values.toList();
              if (index >= 0 && index < labels.length) {
                widget.onBarTap!(labels[index], values[index]);
              }
            }
          });
        },
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) =>
              isDark ? Colors.grey[850]! : Colors.black87,
          tooltipBorderRadius: BorderRadius.circular(8),
          tooltipPadding: const EdgeInsets.all(8),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final labels = widget.data.keys.toList();
            final label = groupIndex < labels.length ? labels[groupIndex] : '';

            return BarTooltipItem(
              '$label\n${_formatValue(rod.toY)}',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatValue(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}
