import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/report_data.dart';
import '../../models/cash_flow_data.dart';
import 'summary_card.dart';
import 'metric_card.dart';
class IncomeReportWidget extends StatelessWidget {
  final IncomeReport report;

  const IncomeReportWidget({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(context),
          
          const SizedBox(height: 16),
          if (report.changePercentage != null)
            _buildPeriodComparison(context),
          
          const SizedBox(height: 16),
          _buildIncomeSourceDistribution(context),
          
          const SizedBox(height: 16),
          _buildTrendAnalysis(context),
          
          const SizedBox(height: 16),
          _buildDetailedTable(context),
        ],
      ),
    );
  }
  Widget _buildSummaryCards(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Toplam Gelir',
                value: '₺${NumberFormat('#,##0.00', 'tr_TR').format(report.totalIncome)}',
                icon: Icons.trending_up,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SummaryCard(
                title: 'Aylık Ortalama',
                value: '₺${NumberFormat('#,##0.00', 'tr_TR').format(report.averageMonthly)}',
                icon: Icons.calendar_today,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        
        if (report.highestIncomeMonth != null && report.highestIncomeAmount != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'En Yüksek Gelir',
                  value: '₺${NumberFormat('#,##0.00', 'tr_TR').format(report.highestIncomeAmount)}',
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricCard(
                  label: 'En Yüksek Ay',
                  value: DateFormat('MMM yyyy', 'tr_TR').format(report.highestIncomeMonth!),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  Widget _buildPeriodComparison(BuildContext context) {
    final isPositive = report.changePercentage! >= 0;
    
    return Card(
      color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Dönemsel Karşılaştırma',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green.shade900 : Colors.red.shade900,
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
                      'Önceki Dönem',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₺${NumberFormat('#,##0.00', 'tr_TR').format(report.previousPeriodIncome ?? 0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                Icon(
                  Icons.arrow_forward,
                  color: Colors.grey.shade400,
                ),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Bu Dönem',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₺${NumberFormat('#,##0.00', 'tr_TR').format(report.totalIncome)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isPositive ? '+' : ''}${report.changePercentage!.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPositive ? 'artış' : 'azalış',
                    style: TextStyle(
                      fontSize: 12,
                      color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildIncomeSourceDistribution(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gelir Kaynakları Dağılımı',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (report.incomeSources.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Bu dönemde gelir kaynağı bulunamadı'),
                ),
              )
            else ...[
              SizedBox(
                height: 250,
                child: _buildIncomeSourcePieChart(),
              ),
              
              const SizedBox(height: 16),
              ...report.incomeSources.map((source) => _buildIncomeSourceItem(
                context,
                source,
              )),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildIncomeSourcePieChart() {
    final sections = report.incomeSources.asMap().entries.map((entry) {
      final index = entry.key;
      final source = entry.value;
      final colors = [
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.teal,
        Colors.pink,
        Colors.amber,
        Colors.indigo,
      ];
      
      final color = colors[index % colors.length];
      
      return PieChartSectionData(
        value: source.amount,
        title: '${source.percentage.toStringAsFixed(0)}%',
        color: color,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {},
        ),
      ),
    );
  }
  Widget _buildIncomeSourceItem(BuildContext context, IncomeSource source) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.grey.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Text(
            '${source.percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          source.source,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${source.transactionCount} işlem',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Text(
          '₺${NumberFormat('#,##0.00', 'tr_TR').format(source.amount)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
  Widget _buildTrendAnalysis(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Trend Analizi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                _buildTrendIndicator(),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (report.monthlyIncome.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Trend verisi bulunamadı'),
                ),
              )
            else
              SizedBox(
                height: 250,
                child: _buildTrendLineChart(),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildTrendIndicator() {
    IconData icon;
    Color color;
    String text;
    
    switch (report.trend) {
      case TrendDirection.up:
        icon = Icons.trending_up;
        color = Colors.green;
        text = 'Yükseliş';
        break;
      case TrendDirection.down:
        icon = Icons.trending_down;
        color = Colors.red;
        text = 'Düşüş';
        break;
      case TrendDirection.stable:
        icon = Icons.trending_flat;
        color = Colors.grey;
        text = 'Sabit';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTrendLineChart() {
    final spots = report.monthlyIncome.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.income);
    }).toList();

    // Calculate horizontal interval, ensuring it's never zero
    final maxIncome = report.monthlyIncome.isNotEmpty 
        ? report.monthlyIncome.map((e) => e.income).reduce((a, b) => a > b ? a : b)
        : 1000.0;
    final horizontalInterval = maxIncome > 0 ? maxIncome / 5 : 200.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: horizontalInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
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
                if (value.toInt() >= 0 && value.toInt() < report.monthlyIncome.length) {
                  final month = report.monthlyIncome[value.toInt()].month;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MMM', 'tr_TR').format(month),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
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
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₺${NumberFormat.compact(locale: 'tr_TR').format(value)}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: (report.monthlyIncome.length - 1).toDouble(),
        minY: 0,
        maxY: report.monthlyIncome.map((m) => m.income).reduce((a, b) => a > b ? a : b) * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final month = report.monthlyIncome[spot.x.toInt()].month;
                return LineTooltipItem(
                  '${DateFormat('MMM yyyy', 'tr_TR').format(month)}\n'
                  '₺${NumberFormat('#,##0.00', 'tr_TR').format(spot.y)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
  Widget _buildDetailedTable(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detaylı Tablo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (report.monthlyIncome.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Veri bulunamadı'),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Ay',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Gelir',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Ortalamadan Fark',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Durum',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: report.monthlyIncome.map((monthData) {
                    final difference = monthData.income - report.averageMonthly;
                    final isAboveAverage = difference >= 0;
                    
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            DateFormat('MMM yyyy', 'tr_TR').format(monthData.month),
                          ),
                        ),
                        DataCell(
                          Text(
                            '₺${NumberFormat('#,##0.00', 'tr_TR').format(monthData.income)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${isAboveAverage ? '+' : ''}₺${NumberFormat('#,##0.00', 'tr_TR').format(difference)}',
                            style: TextStyle(
                              color: isAboveAverage ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        DataCell(
                          Icon(
                            isAboveAverage ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 16,
                            color: isAboveAverage ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
