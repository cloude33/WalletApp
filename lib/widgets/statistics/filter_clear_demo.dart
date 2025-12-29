import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../models/wallet.dart';
import '../../models/transaction.dart';
import '../../models/credit_card_transaction.dart';
import '../../services/transaction_filter_service.dart';
import 'filter_bar.dart';
class FilterClearDemo extends StatefulWidget {
  const FilterClearDemo({super.key});

  @override
  State<FilterClearDemo> createState() => _FilterClearDemoState();
}

class _FilterClearDemoState extends State<FilterClearDemo> {
  String _selectedTimeFilter = 'Aylık';
  List<String> _selectedCategories = [];
  List<String> _selectedWallets = [];
  String _selectedTransactionType = 'all';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  late List<Category> _categories;
  late List<Wallet> _wallets;
  late List<Transaction> _transactions;
  late List<CreditCardTransaction> _creditCardTransactions;

  @override
  void initState() {
    super.initState();
    _initializeDemoData();
  }

  void _initializeDemoData() {
    _categories = [
      Category(
        id: 'food',
        name: 'Yemek',
        icon: Icons.restaurant,
        color: const Color(0xFFFF5722),
        type: 'expense',
      ),
      Category(
        id: 'transport',
        name: 'Ulaşım',
        icon: Icons.directions_car,
        color: const Color(0xFF2196F3),
        type: 'expense',
      ),
      Category(
        id: 'shopping',
        name: 'Alışveriş',
        icon: Icons.shopping_cart,
        color: const Color(0xFF9C27B0),
        type: 'expense',
      ),
      Category(
        id: 'salary',
        name: 'Maaş',
        icon: Icons.attach_money,
        color: const Color(0xFF4CAF50),
        type: 'income',
      ),
    ];
    _wallets = [
      Wallet(
        id: 'cash',
        name: 'Nakit',
        balance: 1500.0,
        type: 'cash',
        color: '0xFF4CAF50',
        icon: 'money',
        creditLimit: 0.0,
      ),
      Wallet(
        id: 'bank',
        name: 'Banka Hesabı',
        balance: 5000.0,
        type: 'bank',
        color: '0xFF2196F3',
        icon: 'account_balance',
        creditLimit: 0.0,
      ),
      Wallet(
        id: 'credit',
        name: 'Kredi Kartı',
        balance: -2000.0,
        type: 'credit_card',
        color: '0xFFF44336',
        icon: 'credit_card',
        creditLimit: 10000.0,
      ),
    ];
    final now = DateTime.now();
    _transactions = [
      Transaction(
        id: '1',
        description: 'Market alışverişi',
        amount: 250.0,
        date: now.subtract(const Duration(days: 1)),
        category: 'food',
        type: 'expense',
        walletId: 'cash',
      ),
      Transaction(
        id: '2',
        description: 'Taksi',
        amount: 50.0,
        date: now.subtract(const Duration(days: 2)),
        category: 'transport',
        type: 'expense',
        walletId: 'cash',
      ),
      Transaction(
        id: '3',
        description: 'Maaş',
        amount: 10000.0,
        date: now.subtract(const Duration(days: 5)),
        category: 'salary',
        type: 'income',
        walletId: 'bank',
      ),
      Transaction(
        id: '4',
        description: 'Kıyafet',
        amount: 500.0,
        date: now.subtract(const Duration(days: 3)),
        category: 'shopping',
        type: 'expense',
        walletId: 'credit',
      ),
    ];

    _creditCardTransactions = [];
  }
  void _handleClearFilters() {
    setState(() {
      _selectedCategories = [];
      _selectedWallets = [];
      _selectedTransactionType = 'all';
      _customStartDate = null;
      _customEndDate = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Tüm filtreler temizlendi - Tüm veriler gösteriliyor'),
        duration: Duration(seconds: 3),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
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

  List<dynamic> get _filteredTransactions {
    return TransactionFilterService.applyFilters(
      transactions: _transactions,
      creditCardTransactions: _creditCardTransactions,
      timeFilter: _selectedTimeFilter,
      customStartDate: _customStartDate,
      customEndDate: _customEndDate,
      categories: _selectedCategories.isEmpty ? null : _selectedCategories,
      walletIds: _selectedWallets.isEmpty ? null : _selectedWallets,
      transactionType: _selectedTransactionType,
    );
  }

  bool get _hasActiveFilters {
    return _selectedCategories.isNotEmpty ||
        _selectedWallets.isNotEmpty ||
        _selectedTransactionType != 'all';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Clear Demo'),
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
      ),
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
              availableCategories: _categories,
              availableWallets: _wallets,
              onTimeFilterChanged: (filter) {
                setState(() => _selectedTimeFilter = filter);
              },
              onCategoriesChanged: (categories) {
                setState(() => _selectedCategories = categories);
              },
              onWalletsChanged: (wallets) {
                setState(() => _selectedWallets = wallets);
              },
              onTransactionTypeChanged: (type) {
                setState(() => _selectedTransactionType = type);
              },
              onClearFilters: _handleClearFilters,
              onCustomDateRange: _handleCustomDateRange,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              color: _hasActiveFilters
                  ? const Color(0xFFFF9800).withValues(alpha: 0.1)
                  : const Color(0xFF4CAF50).withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _hasActiveFilters
                              ? Icons.filter_alt
                              : Icons.check_circle,
                          color: _hasActiveFilters
                              ? const Color(0xFFFF9800)
                              : const Color(0xFF4CAF50),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _hasActiveFilters
                              ? 'Filtreler Aktif'
                              : 'Tüm Veriler Gösteriliyor',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _hasActiveFilters
                                ? const Color(0xFFFF9800)
                                : const Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toplam ${_transactions.length} işlem',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Gösterilen: ${_filteredTransactions.length} işlem',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (_hasActiveFilters) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Aktif Filtreler:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_selectedCategories.isNotEmpty)
                        Text('• ${_selectedCategories.length} kategori seçili'),
                      if (_selectedWallets.isNotEmpty)
                        Text('• ${_selectedWallets.length} cüzdan seçili'),
                      if (_selectedTransactionType != 'all')
                        Text('• İşlem tipi: $_selectedTransactionType'),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedCategories = ['food', 'transport'];
                        _selectedTransactionType = 'expense';
                      });
                    },
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: const Text('Örnek Filtre Uygula'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _hasActiveFilters ? _handleClearFilters : null,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Filtreleri Temizle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Expanded(
            child: _filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Filtre kriterlerine uygun işlem bulunamadı',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _handleClearFilters,
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Filtreleri Temizle'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction =
                          _filteredTransactions[index] as Transaction;
                      final category = _categories.firstWhere(
                        (c) => c.id == transaction.category,
                        orElse: () => _categories.first,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: category.color,
                            child: Icon(
                              category.icon,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(transaction.description),
                          subtitle: Text(
                            '${category.name} • ${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                          ),
                          trailing: Text(
                            '${transaction.type == 'income' ? '+' : '-'}₺${transaction.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: transaction.type == 'income'
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
