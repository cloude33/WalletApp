import 'package:flutter/material.dart';
import '../../models/transaction.dart';
import '../../models/credit_card_transaction.dart';
import '../../models/category.dart';
import '../../models/wallet.dart';
import '../../services/transaction_filter_service.dart';
import 'search_bar.dart';
import 'search_results.dart';
import 'filter_bar.dart';
class SearchIntegrationExample extends StatefulWidget {
  final List<Transaction> transactions;
  final List<CreditCardTransaction> creditCardTransactions;
  final List<Category> categories;
  final List<Wallet> wallets;

  const SearchIntegrationExample({
    super.key,
    required this.transactions,
    required this.creditCardTransactions,
    required this.categories,
    required this.wallets,
  });

  @override
  State<SearchIntegrationExample> createState() =>
      _SearchIntegrationExampleState();
}

class _SearchIntegrationExampleState extends State<SearchIntegrationExample> {
  String _searchQuery = '';
  String _selectedTimeFilter = 'Aylık';
  List<String> _selectedCategories = [];
  List<String> _selectedWallets = [];
  String _selectedTransactionType = 'all';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  List<dynamic> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _applyFiltersAndSearch();
  }

  void _applyFiltersAndSearch() {
    var filtered = TransactionFilterService.applyFilters(
      transactions: widget.transactions,
      creditCardTransactions: widget.creditCardTransactions,
      timeFilter: _selectedTimeFilter,
      customStartDate: _customStartDate,
      customEndDate: _customEndDate,
      categories: _selectedCategories.isEmpty ? null : _selectedCategories,
      walletIds: _selectedWallets.isEmpty ? null : _selectedWallets,
      transactionType: _selectedTransactionType,
    );
    if (_searchQuery.isNotEmpty) {
      filtered = TransactionFilterService.searchTransactions(
        transactions: filtered,
        query: _searchQuery,
      );
    }

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategories = [];
      _selectedWallets = [];
      _selectedTransactionType = 'all';
      _searchQuery = '';
    });
    _applyFiltersAndSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arama ve Filtre Örneği'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatisticsSearchBar(
              searchQuery: _searchQuery,
              onSearchChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
                _applyFiltersAndSearch();
              },
              onClear: () {
                setState(() {
                  _searchQuery = '';
                });
                _applyFiltersAndSearch();
              },
            ),
            
            const SizedBox(height: 16),
            FilterBar(
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
                _applyFiltersAndSearch();
              },
              onCategoriesChanged: (categories) {
                setState(() {
                  _selectedCategories = categories;
                });
                _applyFiltersAndSearch();
              },
              onWalletsChanged: (wallets) {
                setState(() {
                  _selectedWallets = wallets;
                });
                _applyFiltersAndSearch();
              },
              onTransactionTypeChanged: (type) {
                setState(() {
                  _selectedTransactionType = type;
                });
                _applyFiltersAndSearch();
              },
              onClearFilters: _clearAllFilters,
              onCustomDateRange: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _customStartDate = picked.start;
                    _customEndDate = picked.end;
                    _selectedTimeFilter = 'Özel';
                  });
                  _applyFiltersAndSearch();
                }
              },
            ),
            
            const SizedBox(height: 16),
            if (_searchQuery.isNotEmpty)
              SearchResults(
                results: _filteredTransactions,
                searchQuery: _searchQuery,
                onResultTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('İşlem detayları gösteriliyor...'),
                    ),
                  );
                },
              )
            else
              _buildFilteredResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredResults() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtrelenmiş İşlemler',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_filteredTransactions.length} işlem bulundu',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          if (_filteredTransactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox,
                      size: 64,
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'İşlem bulunamadı',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
