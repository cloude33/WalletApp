import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/statistics_service.dart';
class AverageComparisonCard extends StatelessWidget {
  final AverageComparisonData comparisonData;

  const AverageComparisonCard({
    super.key,
    required this.comparisonData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ortalama Karşılaştırması',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Geçmiş dönem ortalamalarıyla karşılaştırma',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCurrentPeriodSummary(context),
              const SizedBox(height: 16),

              Divider(color: isDark ? Colors.white12 : Colors.black12),
              const SizedBox(height: 16),
              _buildBenchmarkSection(
                context,
                '3 Aylık Ortalama',
                comparisonData.threeMonthBenchmark,
                Colors.blue,
              ),
              const SizedBox(height: 12),

              _buildBenchmarkSection(
                context,
                '6 Aylık Ortalama',
                comparisonData.sixMonthBenchmark,
                Colors.purple,
              ),
              const SizedBox(height: 12),

              _buildBenchmarkSection(
                context,
                '12 Aylık Ortalama',
                comparisonData.twelveMonthBenchmark,
                Colors.orange,
              ),
              if (comparisonData.insights.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(color: isDark ? Colors.white12 : Colors.black12),
                const SizedBox(height: 16),
                _buildInsights(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPeriodSummary(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mevcut Dönem',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricColumn(
                context,
                'Gelir',
                comparisonData.currentIncome,
                Icons.arrow_upward,
                Colors.green,
              ),
              _buildMetricColumn(
                context,
                'Gider',
                comparisonData.currentExpense,
                Icons.arrow_downward,
                Colors.red,
              ),
              _buildMetricColumn(
                context,
                'Net Akış',
                comparisonData.currentNetFlow,
                Icons.account_balance_wallet,
                comparisonData.currentNetFlow >= 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(
    BuildContext context,
    String label,
    double value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatCurrency(value),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildBenchmarkSection(
    BuildContext context,
    String title,
    AverageBenchmark benchmark,
    Color accentColor,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1,
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
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              _buildPerformanceBadge(context, benchmark.performanceRating),
            ],
          ),
          const SizedBox(height: 14),
          _buildMetricComparison(
            context,
            'Gelir',
            benchmark.currentIncome,
            benchmark.averageIncome,
            benchmark.incomeDeviation,
            Icons.trending_up,
            Colors.green,
          ),
          const SizedBox(height: 10),

          _buildMetricComparison(
            context,
            'Gider',
            benchmark.currentExpense,
            benchmark.averageExpense,
            benchmark.expenseDeviation,
            Icons.trending_down,
            Colors.red,
          ),
          const SizedBox(height: 10),

          _buildMetricComparison(
            context,
            'Net Akış',
            benchmark.currentNetFlow,
            benchmark.averageNetFlow,
            benchmark.netFlowDeviation,
            Icons.account_balance_wallet,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBadge(
    BuildContext context,
    PerformanceRating rating,
  ) {
    Color color;
    String label;
    IconData icon;

    switch (rating) {
      case PerformanceRating.excellent:
        color = Colors.green;
        label = 'Mükemmel';
        icon = Icons.star;
        break;
      case PerformanceRating.good:
        color = Colors.lightGreen;
        label = 'İyi';
        icon = Icons.thumb_up;
        break;
      case PerformanceRating.average:
        color = Colors.orange;
        label = 'Ortalama';
        icon = Icons.remove;
        break;
      case PerformanceRating.below:
        color = Colors.deepOrange;
        label = 'Altında';
        icon = Icons.trending_down;
        break;
      case PerformanceRating.poor:
        color = Colors.red;
        label = 'Zayıf';
        icon = Icons.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricComparison(
    BuildContext context,
    String label,
    double currentValue,
    double averageValue,
    double deviation,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isAboveAverage = deviation > 0;
    final deviationColor = deviation.abs() < 5
        ? Colors.grey
        : isAboveAverage
            ? Colors.green
            : Colors.red;

    return Row(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            _formatCurrency(currentValue),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            textAlign: TextAlign.right,
          ),
        ),

        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: deviationColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAboveAverage ? Icons.arrow_upward : Icons.arrow_downward,
                size: 10,
                color: deviationColor,
              ),
              const SizedBox(width: 3),
              Text(
                '${deviation.abs().toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: deviationColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            _formatCurrency(averageValue),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
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
        ...comparisonData.insights.map((insight) {
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

  String _formatCurrency(double value) {
    final absValue = value.abs();
    if (absValue >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (absValue >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return '₺${NumberFormat('#,##0', 'tr_TR').format(value.abs())}';
  }
}
