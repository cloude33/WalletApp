import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:parion/models/cash_flow_data.dart';
import 'package:parion/widgets/statistics/statistics_widgets.dart';
import 'package:parion/widgets/statistics/interactive_line_chart.dart';
import 'package:parion/widgets/statistics/interactive_pie_chart.dart';
import 'package:parion/widgets/statistics/interactive_bar_chart.dart';
import 'package:parion/widgets/statistics/custom_tooltip.dart';
import 'package:parion/widgets/statistics/chart_legend.dart';
class StatisticsWidgetsExample extends StatelessWidget {
  const StatisticsWidgetsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics Widgets Example'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TimeFilterBar(
            selectedFilter: 'Monthly',
            filters: const ['Daily', 'Weekly', 'Monthly', 'Yearly'],
            onFilterChanged: (filter) {
              debugPrint('Filter changed to: $filter');
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'Total Income',
                  value: '₺10,000',
                  subtitle: 'This month',
                  icon: Icons.trending_up,
                  color: Colors.green,
                  onTap: () => debugPrint('Income tapped'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SummaryCard(
                  title: 'Total Expense',
                  value: '₺7,500',
                  subtitle: 'This month',
                  icon: Icons.trending_down,
                  color: Colors.red,
                  onTap: () => debugPrint('Expense tapped'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'Net Flow',
                  value: '₺2,500',
                  change: '+15%',
                  trend: TrendDirection.up,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricCard(
                  label: 'Average Daily',
                  value: '₺83',
                  change: '-5%',
                  trend: TrendDirection.down,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricCard(
                  label: 'Balance',
                  value: '₺5,000',
                  change: '0%',
                  trend: TrendDirection.stable,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ChartCard(
            title: 'Cash Flow Trend',
            subtitle: 'Last 6 months',
            chart: SizedBox(
              height: 250,
              child: InteractiveLineChart(
                spots: const [
                  FlSpot(0, 5000),
                  FlSpot(1, 6500),
                  FlSpot(2, 5800),
                  FlSpot(3, 7200),
                  FlSpot(4, 6800),
                  FlSpot(5, 8000),
                ],
                color: Colors.blue,
                onPointTap: (spot) {
                  debugPrint('Tapped on point: ${spot.x}, ${spot.y}');
                },
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => debugPrint('Export chart'),
                tooltip: 'Export',
              ),
            ],
          ),
          const SizedBox(height: 16),
          ChartCard(
            title: 'Spending by Category',
            subtitle: 'This month',
            chart: SizedBox(
              height: 250,
              child: InteractivePieChart(
                data: const {
                  'Market': 3500,
                  'Ulaşım': 1200,
                  'Eğlence': 800,
                  'Faturalar': 2500,
                  'Diğer': 1000,
                },
                onSectionTap: (category, value) {
                  debugPrint('Tapped on: $category - $value');
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          const ChartLegend(
            items: {
              'Market': Color(0xFF4CAF50),
              'Ulaşım': Color(0xFF2196F3),
              'Eğlence': Color(0xFFFF9800),
              'Faturalar': Color(0xFF9C27B0),
              'Diğer': Color(0xFFF44336),
            },
            values: {
              'Market': '₺3,500',
              'Ulaşım': '₺1,200',
              'Eğlence': '₺800',
              'Faturalar': '₺2,500',
              'Diğer': '₺1,000',
            },
          ),
          const SizedBox(height: 16),
          ChartCard(
            title: 'Monthly Income',
            subtitle: 'Last 5 months',
            chart: SizedBox(
              height: 250,
              child: InteractiveBarChart(
                data: const {
                  'Oca': 5000,
                  'Şub': 6500,
                  'Mar': 5800,
                  'Nis': 7200,
                  'May': 6800,
                },
                color: Colors.green,
                onBarTap: (label, value) {
                  debugPrint('Tapped on: $label - $value');
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Custom Tooltip Example',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const CustomTooltip(
            title: 'Toplam Harcama',
            value: '₺9,000',
            color: Colors.red,
            subtitle: 'Bu ay',
            icon: Icons.shopping_cart,
            additionalItems: [
              TooltipItem(
                label: 'Market',
                value: '₺3,500',
                color: Colors.green,
              ),
              TooltipItem(
                label: 'Ulaşım',
                value: '₺1,200',
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Interactive Legend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          InteractiveChartLegend(
            items: const {
              'Gelir': Colors.green,
              'Gider': Colors.red,
              'Net Akış': Colors.blue,
            },
            values: const {
              'Gelir': '₺10,000',
              'Gider': '₺7,500',
              'Net Akış': '₺2,500',
            },
            onSelectionChanged: (selected) {
              debugPrint('Selected items: $selected');
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatisticsFilterChip(
                label: 'All',
                selected: true,
                onTap: () => debugPrint('All selected'),
              ),
              StatisticsFilterChip(
                label: 'Food',
                selected: false,
                onTap: () => debugPrint('Food selected'),
              ),
              StatisticsFilterChip(
                label: 'Transport',
                selected: false,
                onTap: () => debugPrint('Transport selected'),
              ),
              StatisticsFilterChip(
                label: 'Shopping',
                selected: false,
                onTap: () => debugPrint('Shopping selected'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
