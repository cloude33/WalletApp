import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/credit_analysis.dart';
import '../../utils/currency_helper.dart';
import 'interactive_line_chart.dart';
class KmhTrendCharts extends StatelessWidget {
  final List<DebtTrendData> debtTrend;
  final double totalLimit;

  const KmhTrendCharts({
    super.key,
    required this.debtTrend,
    required this.totalLimit,
  });

  @override
  Widget build(BuildContext context) {
    if (debtTrend.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'KMH Trend Analizi (Son 6 Ay)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        _buildDebtChangeChart(context),
        
        const SizedBox(height: 24),
        _buildInterestAccrualChart(context),
        
        const SizedBox(height: 24),
        _buildUtilizationRateChart(context),
      ],
    );
  }
  Widget _buildDebtChangeChart(BuildContext context) {
    final theme = Theme.of(context);
    final spots = <FlSpot>[];
    for (int i = 0; i < debtTrend.length; i++) {
      spots.add(FlSpot(i.toDouble(), debtTrend[i].kmhDebt));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Borç Değişimi',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'KMH borç tutarının son 6 aydaki değişimi',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: InteractiveLineChart(
                spots: spots,
                color: Colors.red,
                showArea: true,
                showDots: true,
                isCurved: true,
                gradientColors: [
                  Colors.red.withValues(alpha: 0.3),
                  Colors.red.withValues(alpha: 0.0),
                ],
                bottomTitleBuilder: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < debtTrend.length) {
                    final date = debtTrend[index].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('MMM', 'tr_TR').format(date),
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                leftTitleBuilder: (value, meta) {
                  return Text(
                    CurrencyHelper.formatAmountShort(value),
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildTrendSummary(context),
          ],
        ),
      ),
    );
  }
  Widget _buildInterestAccrualChart(BuildContext context) {
    final theme = Theme.of(context);
    final interestSpots = <FlSpot>[];
    double cumulativeInterest = 0;
    
    for (int i = 0; i < debtTrend.length; i++) {
      final debt = debtTrend[i].kmhDebt;
      final monthlyInterest = debt * (0.24 / 12);
      cumulativeInterest += monthlyInterest;
      interestSpots.add(FlSpot(i.toDouble(), cumulativeInterest));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.percent,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Faiz Tahakkuku',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Kümülatif faiz tahakkuk trendi (tahmini)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: InteractiveLineChart(
                spots: interestSpots,
                color: Colors.orange,
                showArea: true,
                showDots: true,
                isCurved: true,
                gradientColors: [
                  Colors.orange.withValues(alpha: 0.3),
                  Colors.orange.withValues(alpha: 0.0),
                ],
                bottomTitleBuilder: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < debtTrend.length) {
                    final date = debtTrend[index].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('MMM', 'tr_TR').format(date),
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                leftTitleBuilder: (value, meta) {
                  return Text(
                    CurrencyHelper.formatAmountShort(value),
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildInterestInfo(context, cumulativeInterest),
          ],
        ),
      ),
    );
  }
  Widget _buildUtilizationRateChart(BuildContext context) {
    final theme = Theme.of(context);
    final utilizationSpots = <FlSpot>[];
    for (int i = 0; i < debtTrend.length; i++) {
      final debt = debtTrend[i].kmhDebt;
      final utilizationRate = totalLimit > 0 ? (debt / totalLimit) * 100 : 0.0;
      utilizationSpots.add(FlSpot(i.toDouble(), utilizationRate));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kullanım Oranı',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'KMH limit kullanım oranının değişimi',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: InteractiveLineChart(
                spots: utilizationSpots,
                color: Colors.blue,
                showArea: true,
                showDots: true,
                isCurved: true,
                minY: 0,
                maxY: 100,
                gradientColors: [
                  Colors.blue.withValues(alpha: 0.3),
                  Colors.blue.withValues(alpha: 0.0),
                ],
                bottomTitleBuilder: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < debtTrend.length) {
                    final date = debtTrend[index].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('MMM', 'tr_TR').format(date),
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                leftTitleBuilder: (value, meta) {
                  return Text(
                    '${value.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildUtilizationInfo(context, utilizationSpots),
          ],
        ),
      ),
    );
  }
  Widget _buildTrendSummary(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (debtTrend.length < 2) {
      return const SizedBox.shrink();
    }

    final firstDebt = debtTrend.first.kmhDebt;
    final lastDebt = debtTrend.last.kmhDebt;
    final change = lastDebt - firstDebt;
    final changePercentage = firstDebt > 0 ? (change / firstDebt) * 100 : 0.0;
    final isIncrease = change > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '6 Aylık Değişim',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isIncrease ? Colors.red : Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    CurrencyHelper.formatAmount(change.abs()),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isIncrease ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (isIncrease ? Colors.red : Colors.green).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isIncrease ? Colors.red : Colors.green).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '${isIncrease ? '+' : ''}${changePercentage.toStringAsFixed(1)}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isIncrease ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildInterestInfo(BuildContext context, double cumulativeInterest) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Toplam Faiz (6 Ay)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyHelper.formatAmount(cumulativeInterest),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          Icon(
            Icons.info_outline,
            color: Colors.grey[600],
            size: 20,
          ),
        ],
      ),
    );
  }
  Widget _buildUtilizationInfo(BuildContext context, List<FlSpot> utilizationSpots) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (utilizationSpots.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentUtilization = utilizationSpots.last.y;
    final averageUtilization = utilizationSpots.map((s) => s.y).reduce((a, b) => a + b) / utilizationSpots.length;

    Color getUtilizationColor(double rate) {
      if (rate >= 80) return Colors.red;
      if (rate >= 50) return Colors.orange;
      return Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mevcut Kullanım',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${currentUtilization.toStringAsFixed(1)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: getUtilizationColor(currentUtilization),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Ortalama',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${averageUtilization.toStringAsFixed(1)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: getUtilizationColor(averageUtilization),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildEmptyState(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Trend Verisi Bulunamadı',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Trend analizi için yeterli geçmiş veri bulunmamaktadır.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
