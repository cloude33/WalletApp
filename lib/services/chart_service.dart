import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartService {
  // Light mode colors
  static const List<Color> defaultColors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFFF44336),
    Color(0xFF00BCD4),
    Color(0xFFFFEB3B),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFFE91E63),
  ];
  
  // Dark mode colors - slightly brighter for better visibility
  static const List<Color> defaultColorsDark = [
    Color(0xFF66BB6A), // Lighter green
    Color(0xFF42A5F5), // Lighter blue
    Color(0xFFFFB74D), // Lighter orange
    Color(0xFFAB47BC), // Lighter purple
    Color(0xFFEF5350), // Lighter red
    Color(0xFF26C6DA), // Lighter cyan
    Color(0xFFFFEE58), // Lighter yellow
    Color(0xFFA1887F), // Lighter brown
    Color(0xFF78909C), // Lighter blue grey
    Color(0xFFEC407A), // Lighter pink
  ];
  
  static const Color incomeColor = Color(0xFF4CAF50);
  static const Color incomeColorDark = Color(0xFF66BB6A);
  
  static const Color expenseColor = Color(0xFFF44336);
  static const Color expenseColorDark = Color(0xFFEF5350);
  
  static const Color neutralColor = Color(0xFF9E9E9E);
  static const Color neutralColorDark = Color(0xFFBDBDBD);
  
  static const Color positiveColor = Color(0xFF2196F3);
  static const Color positiveColorDark = Color(0xFF42A5F5);
  
  static const Color warningColor = Color(0xFFFF9800);
  static const Color warningColorDark = Color(0xFFFFB74D);
  
  static const Color dangerColor = Color(0xFFF44336);
  static const Color dangerColorDark = Color(0xFFEF5350);
  
  // Helper methods to get theme-aware colors
  static List<Color> getDefaultColors(bool isDark) {
    return isDark ? defaultColorsDark : defaultColors;
  }
  
  static Color getIncomeColor(bool isDark) {
    return isDark ? incomeColorDark : incomeColor;
  }
  
  static Color getExpenseColor(bool isDark) {
    return isDark ? expenseColorDark : expenseColor;
  }
  
  static Color getNeutralColor(bool isDark) {
    return isDark ? neutralColorDark : neutralColor;
  }
  
  static Color getPositiveColor(bool isDark) {
    return isDark ? positiveColorDark : positiveColor;
  }
  
  static Color getWarningColor(bool isDark) {
    return isDark ? warningColorDark : warningColor;
  }
  
  static Color getDangerColor(bool isDark) {
    return isDark ? dangerColorDark : dangerColor;
  }

  LineChartData createLineChart({
    required List<FlSpot> spots,
    required Color color,
    bool showArea = true,
    bool showDots = true,
    double lineWidth = 3.0,
    double dotSize = 5.0,
    bool isCurved = true,
    List<Color>? gradientColors,
    double? minY,
    double? maxY,
    bool isDark = false,
  }) {
    if (spots.isEmpty) {
      minY ??= 0;
      maxY ??= 100;
    } else {
      if (minY == null || maxY == null) {
        final yValues = spots.map((spot) => spot.y).toList();
        minY ??= yValues.reduce((a, b) => a < b ? a : b);
        maxY ??= yValues.reduce((a, b) => a > b ? a : b);
        final range = maxY - minY;
        minY = minY - (range * 0.1);
        maxY = maxY + (range * 0.1);
      }
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
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
            getTitlesWidget: (value, meta) {
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
            getTitlesWidget: (value, meta) {
              return Text(
                _formatCurrency(value),
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
      minX: spots.isEmpty ? 0 : spots.first.x,
      maxX: spots.isEmpty ? 10 : spots.last.x,
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: isCurved,
          color: color,
          barWidth: lineWidth,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: showDots,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: dotSize,
                color: color,
                strokeWidth: 2,
                strokeColor: isDark ? Colors.black : Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: showArea,
            gradient: LinearGradient(
              colors: gradientColors ??
                  [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.0),
                  ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) =>
              isDark ? Colors.grey[850]! : Colors.black87,
          tooltipRoundedRadius: 8,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              return LineTooltipItem(
                _formatCurrency(barSpot.y),
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

  PieChartData createPieChart({
    required Map<String, double> data,
    Map<String, Color>? colors,
    double centerSpaceRadius = 40,
    double sectionsSpace = 2,
    bool showPercentage = true,
    bool isDark = false,
  }) {
    final total = data.values.fold<double>(0, (sum, value) => sum + value);
    
    if (total == 0) {
      return PieChartData(
        sections: [
          PieChartSectionData(
            color: Colors.grey.withValues(alpha: 0.3),
            value: 1,
            title: 'Veri Yok',
            radius: 50,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.grey,
            ),
          ),
        ],
        centerSpaceRadius: centerSpaceRadius,
        sectionsSpace: sectionsSpace,
      );
    }

    final sections = <PieChartSectionData>[];
    int colorIndex = 0;
    final colorPalette = getDefaultColors(isDark);

    data.forEach((category, value) {
      final percentage = (value / total) * 100;
      final color = colors?[category] ?? colorPalette[colorIndex % colorPalette.length];
      
      sections.add(
        PieChartSectionData(
          color: color,
          value: value,
          title: showPercentage ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      
      colorIndex++;
    });

    return PieChartData(
      sections: sections,
      centerSpaceRadius: centerSpaceRadius,
      sectionsSpace: sectionsSpace,
      pieTouchData: PieTouchData(
        touchCallback: (FlTouchEvent event, pieTouchResponse) {
        },
      ),
    );
  }

  BarChartData createBarChart({
    required Map<String, double> data,
    required Color color,
    double barWidth = 22,
    bool showValues = true,
    double? minY,
    double? maxY,
    bool isDark = false,
  }) {
    if (data.isEmpty) {
      minY ??= 0;
      maxY ??= 100;
    } else {
      final values = data.values.toList();
      minY ??= values.reduce((a, b) => a < b ? a : b);
      maxY ??= values.reduce((a, b) => a > b ? a : b);
      final range = maxY - minY;
      minY = minY - (range * 0.1);
      if (minY < 0 && values.every((v) => v >= 0)) {
        minY = 0;
      }
      maxY = maxY + (range * 0.1);
    }

    final barGroups = <BarChartGroupData>[];
    int index = 0;

    data.forEach((label, value) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value,
              color: color,
              width: barWidth,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY,
                color: (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.1),
              ),
            ),
          ],
          showingTooltipIndicators: showValues ? [0] : [],
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
        show: true,
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
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final labels = data.keys.toList();
              if (value.toInt() >= 0 && value.toInt() < labels.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    labels[value.toInt()],
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
            interval: (maxY - minY) > 0 ? (maxY - minY) / 5 : 1,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              return Text(
                _formatCurrency(value),
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
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) =>
              isDark ? Colors.grey[850]! : Colors.black87,
          tooltipRoundedRadius: 8,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              _formatCurrency(rod.toY),
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget createTooltip({
    required String title,
    required String value,
    Color? color,
    String? subtitle,
    bool isDark = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.black87,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  Color getColorForIndex(int index, {bool isDark = false}) {
    final colorPalette = getDefaultColors(isDark);
    return colorPalette[index % colorPalette.length];
  }

  Color getColorForValue(double value, {bool isDark = false}) {
    if (value > 0) {
      return getIncomeColor(isDark);
    } else if (value < 0) {
      return getExpenseColor(isDark);
    } else {
      return getNeutralColor(isDark);
    }
  }

  Widget createLegendItem({
    required String label,
    required Color color,
    String? value,
    bool isDark = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.grey,
          ),
        ),
        if (value != null) ...[
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ],
    );
  }

  Widget createChartLegend({
    required Map<String, Color> items,
    Map<String, String>? values,
    Axis direction = Axis.horizontal,
    bool isDark = false,
  }) {
    final legendItems = items.entries.map((entry) {
      return createLegendItem(
        label: entry.key,
        color: entry.value,
        value: values?[entry.key],
        isDark: isDark,
      );
    }).toList();

    if (direction == Axis.horizontal) {
      return Wrap(
        spacing: 16,
        runSpacing: 8,
        children: legendItems,
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: legendItems
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: item,
                ))
            .toList(),
      );
    }
  }
}
