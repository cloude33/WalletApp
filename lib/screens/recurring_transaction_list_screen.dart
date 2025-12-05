import 'package:flutter/material.dart';
import '../services/recurring_transaction_service.dart';
import '../widgets/recurring_transaction_card.dart';
import 'add_recurring_transaction_screen.dart';
import 'recurring_transaction_detail_screen.dart';
import 'recurring_statistics_screen.dart';

class RecurringTransactionListScreen extends StatefulWidget {
  final RecurringTransactionService service;

  const RecurringTransactionListScreen({super.key, required this.service});

  @override
  State<RecurringTransactionListScreen> createState() =>
      _RecurringTransactionListScreenState();
}

class _RecurringTransactionListScreenState
    extends State<RecurringTransactionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tekrarlayan İşlemler'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Aktif'),
            Tab(text: 'Pasif'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RecurringStatisticsScreen(service: widget.service),
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildActiveList(), _buildInactiveList()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddRecurringTransactionScreen(service: widget.service),
            ),
          );
          if (result == true) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildActiveList() {
    final transactions = widget.service.getActive();

    if (transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.repeat, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Henüz tekrarlayan işlem yok',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return RecurringTransactionCard(
          transaction: transaction,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecurringTransactionDetailScreen(
                  transaction: transaction,
                  service: widget.service,
                ),
              ),
            );
            if (result == true) {
              setState(() {});
            }
          },
        );
      },
    );
  }

  Widget _buildInactiveList() {
    final transactions = widget.service.getInactive();

    if (transactions.isEmpty) {
      return const Center(
        child: Text(
          'Pasif işlem yok',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return RecurringTransactionCard(
          transaction: transaction,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecurringTransactionDetailScreen(
                  transaction: transaction,
                  service: widget.service,
                ),
              ),
            );
            if (result == true) {
              setState(() {});
            }
          },
        );
      },
    );
  }
}
