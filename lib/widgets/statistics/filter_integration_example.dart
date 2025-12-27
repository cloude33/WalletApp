import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../models/wallet.dart';
import '../../models/transaction.dart';
import '../../models/credit_card_transaction.dart';
import '../../services/transaction_filter_service.dart';
import 'filter_bar.dart';

class FilterIntegrationExample extends StatefulWidget {
  final List<Transaction> transactions;
  final List<CreditCardTransaction> creditCardTransactions;
  final List<Category> categories;
  final List<Wallet> wallets;

  const FilterIntegrationExample({
    super.key,
    required this.transactions,
    required this.creditCardTransactions,
    required this.categories,
    required this.wallets,
  });

  @override
  State<FilterIntegrationExample> createState() =>
      _FilterIntegrationExampleState();
}

class _FilterIntegrationExampleState extends State<FilterIntegrationExample> {
  String _selectedTimeFilter = 'Aylık';
  List<String> _selectedCategories = [];
  List<String> _selectedWallets = [];
  String _selectedTransactionType = 'all';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  List<dynamic> get _filteredTransactions {
    return TransactionFilterService.applyFilters(
      transactions: widget.transactions,
      creditCardTransactions: widget.creditCardTransactions,
      timeFilter: _selectedTimeFilter,
      customStartDate: _customStartDate,
      customEndDate: _customEndDate,
      categories: _selectedCategories.isEmpty ? null : _selectedCategories,
      walletIds: _selectedWallets.isEmpty ? null : _selectedWallets,
      transactionType: _selectedTransactionType,
    );
  }
  void _handleClearFilters() {
    setState(() {
      _selectedCategories = [];
      _selectedWallets = [];
      _selectedTransactionType = 'all';
      _customStartDate = null;
      _customEndDate = null;
    });
  }

  Future<void> _handleCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00BFA5),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedTimeFilter = 'Özel';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Filter Integration Example')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilterBar(
              selectedTimeFilter: _selectedTimeFilter,
              selectedCategories: _selectedCategories,
              selectedWallets: _selectedWallets,
              selectedTransactionType: _selectedTransactionType,
              customStartDate: _customStartDate,
              customEndDate: _customEndDate,
              availableCategories: widget.categories,
              availableWallets: widget.wallets,
              onTimeFilterChanged: (filter) {
                setState(() {
                  _selectedTimeFilter = filter;
                });
              },
              onCategoriesChanged: (categories) {
                setState(() {
                  _selectedCategories = categories;
                });
              },
              onWalletsChanged: (wallets) {
                setState(() {
                  _selectedWallets = wallets;
                });
              },
              onTransactionTypeChanged: (type) {
                setState(() {
                  _selectedTransactionType = type;
                });
              },
              onClearFilters: _handleClearFilters,
              onCustomDateRange: _handleCustomDateRange,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Showing ${_filteredTransactions.length} transactions',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),

          const SizedBox(height: 16),
          Expanded(
            child: _filteredTransactions.isEmpty
                ? const Center(child: Text('No transactions found'))
                : ListView.builder(
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _filteredTransactions[index];

                      if (transaction is Transaction) {
                        return ListTile(
                          title: Text(transaction.description),
                          subtitle: Text(transaction.category),
                          trailing: Text(
                            '₺${transaction.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: transaction.type == 'income'
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      } else if (transaction is CreditCardTransaction) {
                        return ListTile(
                          title: Text(transaction.description),
                          subtitle: Text('${transaction.category} (CC)'),
                          trailing: Text(
                            '₺${transaction.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
class ManualFilterExample extends StatefulWidget {
  final List<Transaction> transactions;
  final List<CreditCardTransaction> creditCardTransactions;

  const ManualFilterExample({
    super.key,
    required this.transactions,
    required this.creditCardTransactions,
  });

  @override
  State<ManualFilterExample> createState() => _ManualFilterExampleState();
}

class _ManualFilterExampleState extends State<ManualFilterExample> {
  List<dynamic> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _applyFilters();
  }

  void _applyFilters() {
    final filtered = TransactionFilterService.applyFilters(
      transactions: widget.transactions,
      creditCardTransactions: widget.creditCardTransactions,
      timeFilter: 'Aylık',
      transactionType: 'expense',
    );

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Filter Example')),
      body: ListView.builder(
        itemCount: _filteredTransactions.length,
        itemBuilder: (context, index) {
          final transaction = _filteredTransactions[index];

          if (transaction is Transaction) {
            return ListTile(
              title: Text(transaction.description),
              trailing: Text('₺${transaction.amount.toStringAsFixed(2)}'),
            );
          } else if (transaction is CreditCardTransaction) {
            return ListTile(
              title: Text(transaction.description),
              trailing: Text('₺${transaction.amount.toStringAsFixed(2)}'),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
