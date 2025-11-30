import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recurring_transaction.dart';
import '../models/wallet.dart';
import '../models/category.dart';
import '../services/data_service.dart';
import 'add_recurring_transaction_screen.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() => _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState extends State<RecurringTransactionsScreen> {
  final DataService _dataService = DataService();
  List<RecurringTransaction> _transactions = [];
  List<Wallet> _wallets = [];
  List<Category> _categories = [];
  bool _loading = true;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final transactions = await _dataService.getRecurringTransactions();
    final wallets = await _dataService.getWallets();
    final categories = await _dataService.getCategories();
    
    setState(() {
      _transactions = transactions;
      _wallets = wallets;
      _categories = categories;
      _loading = false;
    });
  }

  Future<void> _toggleTransaction(RecurringTransaction transaction) async {
    await _dataService.toggleRecurringTransaction(transaction.id);
    _loadData();
  }

  Future<void> _deleteTransaction(RecurringTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tekrarlayan İşlemi Sil'),
        content: Text('${transaction.description} işlemini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dataService.deleteRecurringTransaction(transaction.id);
      _loadData();
    }
  }

  Future<void> _addTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecurringTransactionScreen(
          wallets: _wallets,
          categories: _categories,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('Tekrarlayan İşlemler'),
        actions: [
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _showInactive = !_showInactive),
            tooltip: _showInactive ? 'Pasif işlemleri gizle' : 'Pasif işlemleri göster',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addTransaction,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildTransactionList(),
    );
  }

  Widget _buildTransactionList() {
    var filteredTransactions = _showInactive
        ? _transactions
        : _transactions.where((t) => t.isActive).toList();

    if (filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.repeat,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _showInactive
                  ? 'Henüz tekrarlayan işlem yok'
                  : 'Aktif tekrarlayan işlem yok',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _addTransaction,
              icon: const Icon(Icons.add),
              label: const Text('Tekrarlayan İşlem Ekle'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = filteredTransactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(RecurringTransaction transaction) {
    final wallet = _wallets.firstWhere(
      (w) => w.id == transaction.walletId,
      orElse: () => _wallets.isNotEmpty ? _wallets.first : Wallet(
        id: '',
        name: 'Bilinmeyen',
        balance: 0,
        type: 'cash',
        color: Colors.grey,
        icon: Icons.account_balance_wallet,
      ),
    );

    final category = _categories.firstWhere(
      (c) => c.name == transaction.category,
      orElse: () => _categories.isNotEmpty ? _categories.first : Category(
        id: '',
        name: 'Diğer',
        icon: Icons.category,
        color: Colors.grey,
        type: 'expense',
      ),
    );

    final isIncome = transaction.type == 'income';
    final color = isIncome ? const Color(0xFF34C759) : const Color(0xFFFF3B30);
    final nextOccurrence = transaction.getNextOccurrence();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(category.icon, color: category.color, size: 24),
                ),
                const SizedBox(width: 12),
                
                // Transaction Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            transaction.getRecurrenceIcon(),
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            transaction.getRecurrenceDescription(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            wallet.icon,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            wallet.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      if (nextOccurrence != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Sonraki: ${DateFormat('dd MMM yyyy', 'tr_TR').format(nextOccurrence)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}₺${NumberFormat('#,##0.00', 'tr_TR').format(transaction.amount)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: transaction.isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        transaction.isActive ? 'Aktif' : 'Pasif',
                        style: TextStyle(
                          fontSize: 10,
                          color: transaction.isActive ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _toggleTransaction(transaction),
                    icon: Icon(
                      transaction.isActive ? Icons.pause : Icons.play_arrow,
                      size: 18,
                    ),
                    label: Text(transaction.isActive ? 'Duraklat' : 'Başlat'),
                    style: TextButton.styleFrom(
                      foregroundColor: transaction.isActive ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      // TODO: Edit transaction
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Düzenle'),
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _deleteTransaction(transaction),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Sil'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
