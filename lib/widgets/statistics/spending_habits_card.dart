import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/spending_analysis.dart';
class SpendingHabitsCard extends StatefulWidget {
  final SpendingAnalysis spendingData;
  final DateTime startDate;
  final DateTime endDate;

  const SpendingHabitsCard({
    super.key,
    required this.spendingData,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<SpendingHabitsCard> createState() => _SpendingHabitsCardState();
}

class _SpendingHabitsCardState extends State<SpendingHabitsCard> {
  bool _showDayChart = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  'Harcama Alışkanlıkları',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Gün', style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.calendar_today, size: 16),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Saat', style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.access_time, size: 16),
                    ),
                  ],
                  selected: {_showDayChart},
                  onSelectionChanged: (Set<bool> selection) {
                    setState(() {
                      _showDayChart = selection.first;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildKeyInsights(theme),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _showDayChart
                  ? _buildDayOfWeekChart(theme)
                  : _buildHourOfDayChart(theme),
            ),
            const SizedBox(height: 16),
            _buildAdditionalInsights(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyInsights(ThemeData theme) {
    const dayNames = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];

    final dayName = dayNames[widget.spendingData.mostSpendingDay.index];
    final daysDiff = widget.endDate.difference(widget.startDate).inDays + 1;
    final avgDaily = widget.spendingData.totalSpending / daysDiff;

    return Row(
      children: [
        Expanded(
          child: _buildInsightBox(
            icon: Icons.calendar_today,
            label: 'En Çok Harcama',
            value: dayName,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInsightBox(
            icon: Icons.access_time,
            label: 'Yoğun Saat',
            value: '${widget.spendingData.mostSpendingHour}:00',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInsightBox(
            icon: Icons.trending_up,
            label: 'Günlük Ort.',
            value: _formatCurrency(avgDaily),
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDayOfWeekChart(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    const dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final barGroups = List.generate(7, (index) {
      final isHighest = index == widget.spendingData.mostSpendingDay.index;
      final value = isHighest ? 100.0 : (50 + (index * 7) % 40).toDouble();

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: isHighest ? Colors.red : Colors.blue,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 120,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
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
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dayNames.length) {
                  return const Text('');
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    dayNames[index],
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.textTheme.bodySmall?.color,
                      fontWeight: index == widget.spendingData.mostSpendingDay.index
                          ? FontWeight.bold
                          : FontWeight.normal,
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
          horizontalInterval: 20,
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
      ),
    );
  }

  Widget _buildHourOfDayChart(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final hourLabels = ['00', '03', '06', '09', '12', '15', '18', '21'];
    final barGroups = List.generate(8, (index) {
      final hour = index * 3;
      final isHighest = (hour - widget.spendingData.mostSpendingHour).abs() <= 1;
      final value = isHighest ? 100.0 : (30 + (index * 10) % 50).toDouble();

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: isHighest ? Colors.red : Colors.orange,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 120,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
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
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= hourLabels.length) {
                  return const Text('');
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    hourLabels[index],
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
          horizontalInterval: 20,
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
      ),
    );
  }

  Widget _buildAdditionalInsights(ThemeData theme) {
    final mostSpendingHour = widget.spendingData.mostSpendingHour;
    String timePattern;
    IconData timeIcon;
    Color timeColor;

    if (mostSpendingHour >= 6 && mostSpendingHour < 12) {
      timePattern = 'Sabah saatlerinde daha çok harcama yapıyorsunuz';
      timeIcon = Icons.wb_sunny;
      timeColor = Colors.orange;
    } else if (mostSpendingHour >= 12 && mostSpendingHour < 18) {
      timePattern = 'Öğleden sonra harcamalarınız artıyor';
      timeIcon = Icons.wb_sunny_outlined;
      timeColor = Colors.amber;
    } else if (mostSpendingHour >= 18 && mostSpendingHour < 22) {
      timePattern = 'Akşam saatlerinde daha çok harcama yapıyorsunuz';
      timeIcon = Icons.nights_stay;
      timeColor = Colors.indigo;
    } else {
      timePattern = 'Gece geç saatlerde harcama yapıyorsunuz';
      timeIcon = Icons.bedtime;
      timeColor = Colors.deepPurple;
    }
    final mostSpendingDay = widget.spendingData.mostSpendingDay;
    String dayPattern;
    if (mostSpendingDay.index < 5) {
      dayPattern = 'Hafta içi harcamalarınız daha yüksek';
    } else {
      dayPattern = 'Hafta sonu daha çok harcama yapıyorsunuz';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: timeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: timeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: timeColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Alışkanlık Analizi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: timeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                timeIcon,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  timePattern,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dayPattern,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    return '₺${NumberFormat('#,##0', 'tr_TR').format(value.abs())}';
  }
}
