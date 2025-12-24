import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money/widgets/statistics/accessibility_helpers.dart';

class InteractiveLineChart extends StatefulWidget {
  final List<FlSpot> spots;
  final Color color;
  final bool showArea;
  final bool showDots;
  final double lineWidth;
  final bool isCurved;
  final List<Color>? gradientColors;
  final double? minY;
  final double? maxY;
  final String? title;
  final Function(FlSpot)? onPointTap;
  final Widget Function(double value, TitleMeta meta)? leftTitleBuilder;
  final Widget Function(double value, TitleMeta meta)? bottomTitleBuilder;
  final bool showGrid;
  final bool enableTouch;

  const InteractiveLineChart({
    super.key,
    required this.spots,
    required this.color,
    this.showArea = true,
    this.showDots = true,
    this.lineWidth = 3.0,
    this.isCurved = true,
    this.gradientColors,
    this.minY,
    this.maxY,
    this.title,
    this.onPointTap,
    this.leftTitleBuilder,
    this.bottomTitleBuilder,
    this.showGrid = true,
    this.enableTouch = true,
  });

  @override
  State<InteractiveLineChart> createState() => _InteractiveLineChartState();
}

class _InteractiveLineChartState extends State<InteractiveLineChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    double minY = widget.minY ?? 0;
    double maxY = widget.maxY ?? 100;

    if (widget.spots.isNotEmpty) {
      if (widget.minY == null || widget.maxY == null) {
        final yValues = widget.spots.map((spot) => spot.y).toList();
        minY = widget.minY ?? yValues.reduce((a, b) => a < b ? a : b);
        maxY = widget.maxY ?? yValues.reduce((a, b) => a > b ? a : b);
        final range = maxY - minY;
        if (range > 0) {
          minY = minY - (range * 0.1);
          maxY = maxY + (range * 0.1);
        } else {
          minY = minY - 10;
          maxY = maxY + 10;
        }
      }
    }
    
    // Create semantic label for chart
    final semanticLabel = StatisticsAccessibility.chartLabel(
      title: widget.title ?? 'Çizgi grafik',
      dataPointCount: widget.spots.length,
      description: widget.spots.isNotEmpty
          ? 'Minimum değer ${_formatValue(minY)}, maksimum değer ${_formatValue(maxY)}'
          : 'Veri yok',
    );

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Column(
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
              child: LineChart(
                _createLineChartData(minY, maxY, isDark),
                // Increased animation duration for smoother chart animations
                duration: const Duration(milliseconds: 500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _createLineChartData(double minY, double maxY, bool isDark) {
    return LineChartData(
      gridData: FlGridData(
        show: widget.showGrid,
        drawVerticalLine: true,
        horizontalInterval: (maxY - minY) > 0 ? (maxY - minY) / 5 : 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.1),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
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
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: widget.bottomTitleBuilder ??
                (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white70 : Colors.grey,
                    ),
                  );
                },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (maxY - minY) > 0 ? (maxY - minY) / 5 : 1,
            reservedSize: 42,
            getTitlesWidget: widget.leftTitleBuilder ??
                (value, meta) {
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
      minX: widget.spots.isEmpty ? 0 : widget.spots.first.x,
      maxX: widget.spots.isEmpty ? 10 : widget.spots.last.x,
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: widget.spots,
          isCurved: widget.isCurved,
          color: widget.color,
          barWidth: widget.lineWidth,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: widget.showDots,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: touchedIndex == index ? 6 : 4,
                color: widget.color,
                strokeWidth: 2,
                strokeColor: isDark ? Colors.black : Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: widget.showArea,
            gradient: LinearGradient(
              colors: widget.gradientColors ??
                  [
                    widget.color.withValues(alpha: 0.3),
                    widget.color.withValues(alpha: 0.0),
                  ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: widget.enableTouch,
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
          setState(() {
            if (touchResponse == null ||
                touchResponse.lineBarSpots == null ||
                touchResponse.lineBarSpots!.isEmpty) {
              touchedIndex = null;
              return;
            }
            touchedIndex = touchResponse.lineBarSpots!.first.spotIndex;

            if (widget.onPointTap != null && event is FlTapUpEvent) {
              final spot = widget.spots[touchedIndex!];
              widget.onPointTap!(spot);
            }
          });
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) =>
              isDark ? Colors.grey[850]! : Colors.black87,
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              return LineTooltipItem(
                _formatValue(barSpot.y),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
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
