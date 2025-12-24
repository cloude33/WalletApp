import 'package:flutter/material.dart';
import 'paginated_list_view.dart';

class PaginationExampleScreen extends StatelessWidget {
  const PaginationExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagination Examples'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPaginatedListExample(),
          
          const SizedBox(height: 24),
          _buildPaginatedTableExample(),
        ],
      ),
    );
  }

  Widget _buildPaginatedListExample() {
    final items = List.generate(
      100,
      (index) => {
        'id': index + 1,
        'title': 'İşlem ${index + 1}',
        'amount': (index + 1) * 100.0,
        'date': DateTime.now().subtract(Duration(days: index)),
      },
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paginated List View Example',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            PaginatedListView<Map<String, dynamic>>(
              items: items,
              itemsPerPage: 10,
              itemBuilder: (context, item, index) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${item['id']}'),
                  ),
                  title: Text(item['title'] as String),
                  subtitle: Text(
                    'Tarih: ${(item['date'] as DateTime).toString().split(' ')[0]}',
                  ),
                  trailing: Text(
                    '₺${(item['amount'] as double).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
              header: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.blue.withValues(alpha: 0.1),
                child: const Text(
                  'İşlem Listesi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              emptyWidget: const Center(
                child: Text('Hiç işlem bulunamadı'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginatedTableExample() {
    final headers = ['Ay', 'Gelir', 'Gider', 'Net'];
    final rows = List.generate(
      24,
      (index) => [
        'Ay ${index + 1}',
        '₺${((index + 1) * 5000).toStringAsFixed(2)}',
        '₺${((index + 1) * 3000).toStringAsFixed(2)}',
        '₺${((index + 1) * 2000).toStringAsFixed(2)}',
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics Paginated Table Example',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StatisticsPaginatedTable(
              headers: headers,
              rows: rows,
              rowsPerPage: 6,
              columnFlex: [2, 1, 1, 1],
            ),
          ],
        ),
      ),
    );
  }
}
class CashFlowPaginationExample extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyData;

  const CashFlowPaginationExample({
    super.key,
    required this.monthlyData,
  });

  @override
  Widget build(BuildContext context) {
    return PaginatedListView<Map<String, dynamic>>(
      items: monthlyData,
      itemsPerPage: 6,
      showItemCount: true,
      loadMoreText: 'Daha Fazla Ay Göster',
      itemBuilder: (context, item, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(item['month'] as String),
            subtitle: Row(
              children: [
                Text('Gelir: ${item['income']}'),
                const SizedBox(width: 16),
                Text('Gider: ${item['expense']}'),
              ],
            ),
            trailing: Text(
              item['netFlow'] as String,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: (item['netFlow'] as String).startsWith('-')
                    ? Colors.red
                    : Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }
}
class SpendingCategoryPaginationExample extends StatelessWidget {
  final List<Map<String, dynamic>> categories;

  const SpendingCategoryPaginationExample({
    super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return PaginatedListView<Map<String, dynamic>>(
      items: categories,
      itemsPerPage: 8,
      showItemCount: true,
      loadMoreText: 'Daha Fazla Kategori Göster',
      itemBuilder: (context, category, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: category['color'] as Color,
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(category['name'] as String),
            subtitle: Text('${category['percentage']}% of total'),
            trailing: Text(
              category['amount'] as String,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}
class ReportTransactionsPaginationExample extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const ReportTransactionsPaginationExample({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final headers = ['Tarih', 'Açıklama', 'Kategori', 'Tutar'];
    final rows = transactions.map((tx) {
      return [
        tx['date'],
        tx['description'],
        tx['category'],
        tx['amount'],
      ];
    }).toList();

    return StatisticsPaginatedTable(
      headers: headers,
      rows: rows,
      rowsPerPage: 15,
      columnFlex: [2, 3, 2, 2],
      showPageNavigation: true,
    );
  }
}
