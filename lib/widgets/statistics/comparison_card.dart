import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/comparison_data.dart';
import '../../models/cash_flow_data.dart';
class ComparisonCard extends StatefulWidget {
  final ComparisonData comparisonData;
  final VoidCallback? onPeriodChanged;
  final bool showPeriodSelector;

  const ComparisonCard({
    super.key,
    required this.comparisonData,
    this.onPeriodChanged,
    this.showPeriodSelector = true,
  });

  @override
  State<ComparisonCard> createState() => _ComparisonCardState();
}

class _ComparisonCardState extends State<ComparisonCard> {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dönem Karşılaştırması',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.showPeriodSelector && widget.onPeriodChanged != null)
                  IconButton(
                    icon: const Icon(Icons.calendar_today, size: 20),
                    onPressed: widget.onPeriodChanged,
                    tooltip: 'Dönem Seç',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPeriodLabel(
                    widget.comparisonData.period1Label,
                    Colors.grey[600]!,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPeriodLabel(
                    widget.comparisonData.period2Label,
                    theme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Divider(color: isDark ? Colors.white12 : Colors.black12),
            const SizedBox(height: 16),
            _buildMetricComparison(
              context,
              'Gelir',
              widget.comparisonData.income,
              Icons.trending_up,
              Colors.green,
              higherIsBetter: true,
            ),
            const SizedBox(height: 12),

            _buildMetricComparison(
              context,
              'Gider',
              widget.comparisonData.expense,
              Icons.trending_down,
              Colors.red,
              higherIsBetter: false,
            ),
            const SizedBox(height: 12),

            _buildMetricComparison(
              context,
              'Net Akış',
              widget.comparisonData.netCashFlow,
              Icons.account_balance_wallet,
              Colors.blue,
              higherIsBetter: true,
            ),

            if (widget.comparisonData.savingsRate != null) ...[
              const SizedBox(height: 12),
              _buildMetricComparison(
                context,
                'Tasarruf Oranı',
                widget.comparisonData.savingsRate!,
                Icons.savings,
                Colors.orange,
                higherIsBetter: true,
                isPercentage: true,
              ),
            ],
            if (widget.comparisonData.overallTrend != TrendDirection.stable) ...[
              const SizedBox(height: 16),
              Divider(color: isDark ? Colors.white12 : Colors.black12),
              const SizedBox(height: 16),
              _buildOverallTrend(context),
            ],
            if (widget.comparisonData.insights.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(color: isDark ? Colors.white12 : Colors.black12),
              const SizedBox(height: 16),
              _buildInsights(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodLabel(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMetricComparison(
    BuildContext context,
    String label,
    ComparisonMetric metric,
    IconData icon,
    Color color, {
    required bool higherIsBetter,
    bool isPercentage = false,
  }) {
    final theme = Theme.of(context);
    final isPositive = metric.absoluteChange > 0;
    final isImprovement = higherIsBetter ? isPositive : !isPositive;
    
    final changeColor = metric.absoluteChange == 0
        ? Colors.grey
        : isImprovement
            ? Colors.green
            : Colors.red;

    final trendIcon = _getTrendIcon(metric.trend);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Önceki',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPercentage
                        ? '${metric.period1Value.toStringAsFixed(1)}%'
                        : _formatCurrency(metric.period1Value),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.arrow_forward,
                size: 20,
                color: Colors.grey[400],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Şimdi',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPercentage
                        ? '${metric.period2Value.toStringAsFixed(1)}%'
                        : _formatCurrency(metric.period2Value),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: changeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  trendIcon,
                  size: 16,
                  color: changeColor,
                ),
                const SizedBox(width: 6),
                Text(
                  isPercentage
                      ? '${metric.absoluteChange >= 0 ? '+' : ''}${metric.absoluteChange.toStringAsFixed(1)}%'
                      : '${metric.absoluteChange >= 0 ? '+' : ''}${_formatCurrency(metric.absoluteChange)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: changeColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${metric.percentageChange >= 0 ? '+' : ''}${metric.percentageChange.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 12,
                    color: changeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallTrend(BuildContext context) {
    final theme = Theme.of(context);
    final trend = widget.comparisonData.overallTrend;
    final isPositive = trend == TrendDirection.up;
    
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    final text = isPositive ? 'Genel Durum İyileşiyor' : 'Genel Durum Kötüleşiyor';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsights(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber[700]),
            const SizedBox(width: 8),
            Text(
              'Önemli Noktalar',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...widget.comparisonData.insights.map((insight) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  IconData _getTrendIcon(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.up:
        return Icons.arrow_upward;
      case TrendDirection.down:
        return Icons.arrow_downward;
      case TrendDirection.stable:
        return Icons.trending_flat;
    }
  }

  String _formatCurrency(double value) {
    return '₺${NumberFormat('#,##0.00', 'tr_TR').format(value.abs())}';
  }
}
