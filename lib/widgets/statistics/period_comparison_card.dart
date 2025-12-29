import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class PeriodComparisonCard extends StatelessWidget {
  final String title;
  final double currentValue;
  final double previousValue;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool higherIsBetter;

  const PeriodComparisonCard({
    super.key,
    required this.title,
    required this.currentValue,
    required this.previousValue,
    this.subtitle,
    required this.icon,
    required this.color,
    this.higherIsBetter = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final change = currentValue - previousValue;
    final changePercentage = previousValue != 0
        ? (change / previousValue.abs()) * 100
        : (currentValue != 0 ? 100.0 : 0.0);
    final isPositive = change > 0;
    final isImprovement = higherIsBetter ? isPositive : !isPositive;
    final changeColor = change == 0
        ? Colors.grey
        : isImprovement
            ? Colors.green
            : Colors.red;
    final trendIcon = change == 0
        ? Icons.trending_flat
        : isPositive
            ? Icons.trending_up
            : Icons.trending_down;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bu Dönem',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _formatCurrency(currentValue),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Önceki Dönem',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _formatCurrency(previousValue),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              color: isDark ? Colors.white12 : Colors.black12,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      trendIcon,
                      size: 20,
                      color: changeColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Değişim',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${change >= 0 ? '+' : ''}${_formatCurrency(change)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: changeColor,
                      ),
                    ),
                    Text(
                      '${changePercentage >= 0 ? '+' : ''}${changePercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: changeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (change != 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isImprovement ? Icons.check_circle : Icons.warning,
                      size: 14,
                      color: changeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isImprovement ? 'İyileşme' : 'Dikkat',
                      style: TextStyle(
                        fontSize: 11,
                        color: changeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return '₺${NumberFormat('#,##0.00', 'tr_TR').format(value.abs())}';
  }
}
class PeriodComparisonList extends StatelessWidget {
  final List<PeriodComparisonData> comparisons;

  const PeriodComparisonList({
    super.key,
    required this.comparisons,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dönemsel Karşılaştırma',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ...comparisons.map((comparison) {
              final change = comparison.currentValue - comparison.previousValue;
              final changePercentage = comparison.previousValue != 0
                  ? (change / comparison.previousValue.abs()) * 100
                  : (comparison.currentValue != 0 ? 100.0 : 0.0);

              final isPositive = change > 0;
              final isImprovement = comparison.higherIsBetter ? isPositive : !isPositive;
              final changeColor = change == 0
                  ? Colors.grey
                  : isImprovement
                      ? Colors.green
                      : Colors.red;

              final trendIcon = change == 0
                  ? Icons.trending_flat
                  : isPositive
                      ? Icons.trending_up
                      : Icons.trending_down;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          comparison.icon,
                          size: 20,
                          color: comparison.color,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comparison.label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatCurrency(comparison.currentValue),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  trendIcon,
                                  size: 16,
                                  color: changeColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${changePercentage >= 0 ? '+' : ''}${changePercentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: changeColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${change >= 0 ? '+' : ''}${_formatCurrency(change)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: changeColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (comparison != comparisons.last) ...[
                      const SizedBox(height: 12),
                      Divider(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return '₺${NumberFormat('#,##0.00', 'tr_TR').format(value.abs())}';
  }
}
class PeriodComparisonData {
  final String label;
  final double currentValue;
  final double previousValue;
  final IconData icon;
  final Color color;
  final bool higherIsBetter;

  PeriodComparisonData({
    required this.label,
    required this.currentValue,
    required this.previousValue,
    required this.icon,
    required this.color,
    this.higherIsBetter = true,
  });
}
