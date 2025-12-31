import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
class InteractivePieChart extends StatefulWidget {
  final Map<String, double> data;
  final Map<String, Color>? colors;
  final double centerSpaceRadius;
  final double sectionsSpace;
  final bool showPercentage;
  final String? title;
  final Function(String category, double value)? onSectionTap;
  final bool enableTouch;
  final double radius;

  const InteractivePieChart({
    super.key,
    required this.data,
    this.colors,
    this.centerSpaceRadius = 40,
    this.sectionsSpace = 2,
    this.showPercentage = true,
    this.title,
    this.onSectionTap,
    this.enableTouch = true,
    this.radius = 100,
  });

  @override
  State<InteractivePieChart> createState() => _InteractivePieChartState();
}

class _InteractivePieChartState extends State<InteractivePieChart> {
  int? touchedIndex;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          child: widget.data.isEmpty || widget.data.values.every((v) => v == 0)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pie_chart,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Veri yok',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: PieChart(
                    _createPieChartData(isDark),
                    // Increased animation duration for smoother chart animations
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  ),
                ),
        ),
      ],
    );
  }

  PieChartData _createPieChartData(bool isDark) {
    final total = widget.data.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    if (total == 0 || widget.data.isEmpty) {
      return PieChartData(
        sections: [
          PieChartSectionData(
            color: Colors.grey.withValues(alpha: 0.3),
            value: 1,
            title: 'Veri Yok',
            radius: widget.radius,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.grey,
            ),
          ),
        ],
        centerSpaceRadius: widget.centerSpaceRadius,
        sectionsSpace: widget.sectionsSpace,
      );
    }

    final sections = <PieChartSectionData>[];
    int colorIndex = 0;
    int sectionIndex = 0;

    widget.data.forEach((category, value) {
      final percentage = (value / total) * 100;
      final color =
          widget.colors?[category] ??
          defaultColors[colorIndex % defaultColors.length];
      final isTouched = touchedIndex == sectionIndex;

      sections.add(
        PieChartSectionData(
          color: color,
          value: value,
          title: widget.showPercentage
              ? '${percentage.toStringAsFixed(1)}%'
              : '',
          radius: isTouched ? widget.radius + 10 : widget.radius,
          titleStyle: TextStyle(
            fontSize: isTouched ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 2),
            ],
          ),
          badgeWidget: isTouched
              ? _buildBadge(category, value, color, isDark)
              : null,
          badgePositionPercentageOffset: 1.3,
        ),
      );

      colorIndex++;
      sectionIndex++;
    });

    return PieChartData(
      sections: sections,
      centerSpaceRadius: widget.centerSpaceRadius,
      sectionsSpace: widget.sectionsSpace,
      pieTouchData: PieTouchData(
        enabled: widget.enableTouch,
        touchCallback: (FlTouchEvent event, pieTouchResponse) {
          setState(() {
            if (!widget.enableTouch ||
                pieTouchResponse == null ||
                pieTouchResponse.touchedSection == null) {
              touchedIndex = null;
              return;
            }

            final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
            touchedIndex = index;

            if (widget.onSectionTap != null && event is FlTapUpEvent) {
              final categories = widget.data.keys.toList();
              final values = widget.data.values.toList();
              if (index >= 0 && index < categories.length) {
                widget.onSectionTap!(categories[index], values[index]);
              }
            }
          });
        },
      ),
    );
  }

  Widget _buildBadge(String category, double value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            category,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatValue(value),
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M ₺';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K ₺';
    } else {
      return '${value.toStringAsFixed(0)} ₺';
    }
  }
}
