import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:parion/services/chart_service.dart';
import 'package:parion/widgets/statistics/interactive_line_chart.dart';
import 'package:parion/widgets/statistics/interactive_pie_chart.dart';
import 'package:parion/widgets/statistics/interactive_bar_chart.dart';
import 'package:parion/widgets/statistics/summary_card.dart';
import 'package:parion/widgets/statistics/metric_card.dart';
import 'package:parion/widgets/statistics/chart_legend.dart';
import 'package:parion/widgets/statistics/custom_tooltip.dart';
import 'package:parion/models/cash_flow_data.dart';

/// Demo screen showcasing dark mode support in statistics widgets
class DarkModeDemo extends StatefulWidget {
  const DarkModeDemo({super.key});

  @override
  State<DarkModeDemo> createState() => _DarkModeDemoState();
}

class _DarkModeDemoState extends State<DarkModeDemo> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dark Mode Demo'),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
              tooltip: _isDarkMode ? 'Light Mode' : 'Dark Mode',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Summary Cards'),
            const SizedBox(height: 12),
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildSectionTitle('Metric Cards'),
            const SizedBox(height: 12),
            _buildMetricCards(),
            const SizedBox(height: 24),
            _buildSectionTitle('Line Chart'),
            const SizedBox(height: 12),
            _buildLineChart(),
            const SizedBox(height: 24),
            _buildSectionTitle('Pie Chart'),
            const SizedBox(height: 12),
            _buildPieChart(),
            const SizedBox(height: 24),
            _buildSectionTitle('Bar Chart'),
            const SizedBox(height: 12),
            _buildBarChart(),
            const SizedBox(height: 24),
            _buildSectionTitle('Chart Legend'),
            const SizedBox(height: 12),
            _buildChartLegend(),
            const SizedBox(height: 24),
            _buildSectionTitle('Custom Tooltip'),
            const SizedBox(height: 12),
            _buildCustomTooltip(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            title: 'Toplam Gelir',
            value: '₺15,450',
            subtitle: '+12% bu ay',
            icon: Icons.trending_up,
            color: ChartService.getIncomeColor(_isDarkMode),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SummaryCard(
            title: 'Toplam Gider',
            value: '₺8,230',
            subtitle: '-5% bu ay',
            icon: Icons.trending_down,
            color: ChartService.getExpenseColor(_isDarkMode),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCards() {
    return Row(
      children: [
        Expanded(
          child: MetricCard(
            label: 'Net Akış',
            value: '₺7,220',
            change: '+18%',
            trend: TrendDirection.up,
            color: ChartService.getPositiveColor(_isDarkMode),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricCard(
            label: 'Ortalama',
            value: '₺2,407',
            change: '-2%',
            trend: TrendDirection.down,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricCard(
            label: 'Hedef',
            value: '₺10,000',
            trend: TrendDirection.stable,
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    final spots = [
      const FlSpot(0, 3000),
      const FlSpot(1, 4500),
      const FlSpot(2, 3800),
      const FlSpot(3, 5200),
      const FlSpot(4, 4800),
      const FlSpot(5, 6100),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 250,
          child: InteractiveLineChart(
            spots: spots,
            color: ChartService.getIncomeColor(_isDarkMode),
            title: 'Aylık Gelir Trendi',
            showArea: true,
            showDots: true,
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final data = {
      'Market': 2500.0,
      'Ulaşım': 1200.0,
      'Eğlence': 800.0,
      'Faturalar': 1500.0,
      'Diğer': 600.0,
    };

    final colors = <String, Color>{};
    final colorPalette = ChartService.getDefaultColors(_isDarkMode);
    int index = 0;
    for (final key in data.keys) {
      colors[key] = colorPalette[index % colorPalette.length];
      index++;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 300,
          child: InteractivePieChart(
            data: data,
            colors: colors,
            title: 'Kategori Dağılımı',
            showPercentage: true,
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final data = {
      'Oca': 3000.0,
      'Şub': 4500.0,
      'Mar': 3800.0,
      'Nis': 5200.0,
      'May': 4800.0,
      'Haz': 6100.0,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 250,
          child: InteractiveBarChart(
            data: data,
            color: ChartService.getPositiveColor(_isDarkMode),
            title: 'Aylık Harcama',
            showValues: true,
          ),
        ),
      ),
    );
  }

  Widget _buildChartLegend() {
    final items = <String, Color>{};
    final colorPalette = ChartService.getDefaultColors(_isDarkMode);
    final categories = ['Market', 'Ulaşım', 'Eğlence', 'Faturalar', 'Diğer'];

    for (int i = 0; i < categories.length; i++) {
      items[categories[i]] = colorPalette[i % colorPalette.length];
    }

    final values = {
      'Market': '₺2,500',
      'Ulaşım': '₺1,200',
      'Eğlence': '₺800',
      'Faturalar': '₺1,500',
      'Diğer': '₺600',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Horizontal Legend',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            ChartLegend(
              items: items,
              values: values,
              direction: Axis.horizontal,
            ),
            const SizedBox(height: 24),
            Text(
              'Vertical Legend',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            ChartLegend(
              items: items,
              values: values,
              direction: Axis.vertical,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTooltip() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tooltip Examples',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            CustomTooltip(
              title: 'Gelir',
              value: '₺5,200',
              color: ChartService.getIncomeColor(_isDarkMode),
              subtitle: 'Mayıs 2024',
            ),
            const SizedBox(height: 12),
            CustomTooltip(
              title: 'Gider',
              value: '₺3,800',
              color: ChartService.getExpenseColor(_isDarkMode),
              subtitle: 'Mayıs 2024',
              icon: Icons.shopping_cart,
              additionalItems: [
                TooltipItem(
                  label: 'Market',
                  value: '₺1,200',
                  color: ChartService.getDefaultColors(_isDarkMode)[0],
                ),
                TooltipItem(
                  label: 'Ulaşım',
                  value: '₺800',
                  color: ChartService.getDefaultColors(_isDarkMode)[1],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
