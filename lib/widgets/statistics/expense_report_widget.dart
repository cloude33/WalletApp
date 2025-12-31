import 'package:flutter/material.dart';

import 'summary_card.dart';
import '../../models/report_data.dart';
import '../../models/cash_flow_data.dart';

class ExpenseReportWidget extends StatelessWidget {
  final ExpenseReport report;

  const ExpenseReportWidget({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total expense and average
          SummaryCard(
            title: 'Toplam Gider',
            value: '₺${report.totalExpense.toStringAsFixed(2)}',
            icon: Icons.trending_down,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          
          // Monthly average
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aylık Ortalama',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₺${(report.totalExpense / 12).toStringAsFixed(2)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Fixed vs Variable expense breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sabit / Değişken Gider Dağılımı',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Sabit Giderler',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₺${(report.totalExpense * 0.4).toStringAsFixed(2)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '40.0%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Değişken Giderler',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₺${(report.totalExpense * 0.6).toStringAsFixed(2)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '60.0%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Category distribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kategori Bazlı Dağılım',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryItem('Market', report.totalExpense * 0.3),
                  _buildCategoryItem('Ulaşım', report.totalExpense * 0.2),
                  _buildCategoryItem('Eğlence', report.totalExpense * 0.15),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Period comparison - only show if previous period data is available
          if (report.previousPeriodExpense != null && report.changePercentage != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Önceki Dönem',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₺${report.previousPeriodExpense!.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.grey[400],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Bu Dönem',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₺${report.totalExpense.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: report.changePercentage! >= 0 ? Colors.red : Colors.green,
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
                        color: report.changePercentage! >= 0 ? Colors.red.shade100 : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            report.changePercentage! >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 16,
                            color: report.changePercentage! >= 0 ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${report.changePercentage! >= 0 ? '+' : ''}${report.changePercentage!.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: report.changePercentage! >= 0 ? Colors.red.shade700 : Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            report.changePercentage! >= 0 ? 'artış' : 'azalış',
                            style: TextStyle(
                              fontSize: 12,
                              color: report.changePercentage! >= 0 ? Colors.red.shade700 : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (report.previousPeriodExpense != null && report.changePercentage != null)
            const SizedBox(height: 16),
          
          // Trend analysis
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Gider Trendi',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTrendIndicator(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getTrendDescription(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Optimization suggestions - only show if there are suggestions
          if (report.optimizationSuggestions.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Optimizasyon Önerileri',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...report.optimizationSuggestions.map((suggestion) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              suggestion.suggestion,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          if (report.optimizationSuggestions.isNotEmpty)
            const SizedBox(height: 16),
          
          // Detailed category table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detaylı Kategori Analizi',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrendIndicator() {
    IconData icon;
    Color color;
    String text;
    
    if (report.trend == TrendDirection.up) {
      icon = Icons.trending_up;
      color = Colors.red;
      text = 'Artış';
    } else if (report.trend == TrendDirection.down) {
      icon = Icons.trending_down;
      color = Colors.green;
      text = 'Azalış';
    } else {
      icon = Icons.trending_flat;
      color = Colors.grey;
      text = 'Sabit';
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

  String _getTrendDescription() {
    if (report.trend == TrendDirection.up) {
      return 'Giderleriniz artış eğiliminde. Bütçe kontrolü yapmanız önerilir.';
    } else if (report.trend == TrendDirection.down) {
      return 'Giderleriniz azalış eğiliminde. Tasarruf hedeflerinize yaklaşıyorsunuz.';
    } else {
      return 'Giderleriniz stabil seyrediyor. Mevcut harcama alışkanlıklarınızı sürdürün.';
    }
  }

  Widget _buildCategoryItem(String category, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(category),
          Text('₺${amount.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
  
  Widget _buildCategoryTable() {
    if (report.expenseCategories.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Kategori verisi bulunamadı'),
        ),
      );
    }

    return DataTable(
      headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
      columns: const [
        DataColumn(
          label: Text(
            'Kategori',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Tutar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text(
            'Oran',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text(
            'İşlem',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          numeric: true,
        ),
      ],
      rows: report.expenseCategories.map((category) {
        return DataRow(
          cells: [
            DataCell(Text(category.category)),
            DataCell(
              Text(
                '₺${category.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            DataCell(
              Text(
                '${category.percentage.toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            DataCell(
              Text(
                '${category.transactionCount}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
