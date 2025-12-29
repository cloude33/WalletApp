import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/wallet.dart';
import '../services/data_service.dart';
import '../services/sensitive_data_handler.dart';
import 'add_wallet_screen.dart';
import 'kmh_account_detail_screen.dart';
import 'kmh_comparison_screen.dart';
class KmhListScreen extends StatefulWidget {
  const KmhListScreen({super.key});

  @override
  State<KmhListScreen> createState() => _KmhListScreenState();
}

class _KmhListScreenState extends State<KmhListScreen> {
  final DataService _dataService = DataService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  List<Wallet> _allKmhAccounts = [];
  List<Wallet> _filteredKmhAccounts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  double _totalDebt = 0;
  double _totalAvailableCredit = 0;
  double _totalCreditLimit = 0;
  double _averageUtilization = 0;

  @override
  void initState() {
    super.initState();
    _loadKmhAccounts();
  }

  Future<void> _loadKmhAccounts() async {
    setState(() => _isLoading = true);

    try {
      final wallets = await _dataService.getWallets();
      final kmhAccounts = wallets.where((w) => w.isKmhAccount).toList();
      double totalDebt = 0;
      double totalAvailableCredit = 0;
      double totalCreditLimit = 0;
      double totalUtilization = 0;

      for (var account in kmhAccounts) {
        totalDebt += account.usedCredit;
        totalAvailableCredit += account.availableCredit;
        totalCreditLimit += account.creditLimit;
        totalUtilization += account.utilizationRate;
      }

      final averageUtilization = kmhAccounts.isNotEmpty
          ? totalUtilization / kmhAccounts.length
          : 0.0;

      setState(() {
        _allKmhAccounts = kmhAccounts;
        _filteredKmhAccounts = kmhAccounts;
        _totalDebt = totalDebt;
        _totalAvailableCredit = totalAvailableCredit;
        _totalCreditLimit = totalCreditLimit;
        _averageUtilization = averageUtilization;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  void _filterAccounts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredKmhAccounts = _allKmhAccounts;
      } else {
        _filteredKmhAccounts = _allKmhAccounts.where((account) {
          final nameLower = account.name.toLowerCase();
          final queryLower = query.toLowerCase();
          final accountNumber = account.accountNumber ?? '';
          return nameLower.contains(queryLower) ||
              accountNumber.contains(queryLower);
        }).toList();
      }
    });
  }

  Future<void> _navigateToAddAccount() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddWalletScreen()),
    );

    if (result == true) {
      _loadKmhAccounts();
    }
  }

  Future<void> _navigateToAccountDetail(Wallet account) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KmhAccountDetailScreen(account: account),
      ),
    );

    if (result == true) {
      _loadKmhAccounts();
    }
  }

  Future<void> _navigateToComparison() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KmhComparisonScreen(),
      ),
    );

    if (result == true) {
      _loadKmhAccounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KMH Hesaplarım'),
        actions: [
          if (_allKmhAccounts.length > 1)
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              onPressed: _navigateToComparison,
              tooltip: 'Hesapları Karşılaştır',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadKmhAccounts,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryCard(),
                if (_allKmhAccounts.isNotEmpty) _buildSearchBar(),
                Expanded(
                  child: _filteredKmhAccounts.isEmpty
                      ? _buildEmptyState()
                      : _buildAccountList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddAccount,
        icon: const Icon(Icons.add),
        label: const Text('KMH Hesabı Ekle'),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Toplam KMH Durumu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Toplam Borç',
                    _currencyFormat.format(_totalDebt),
                    Colors.red,
                    Icons.trending_down,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Kullanılabilir',
                    _currencyFormat.format(_totalAvailableCredit),
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Toplam Limit',
                    _currencyFormat.format(_totalCreditLimit),
                    Colors.blue,
                    Icons.account_balance_wallet,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Ort. Kullanım',
                    '${_averageUtilization.toStringAsFixed(1)}%',
                    _getUtilizationColor(_averageUtilization),
                    Icons.pie_chart,
                  ),
                ),
              ],
            ),
            if (_allKmhAccounts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_allKmhAccounts.length} KMH Hesabı',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Hesap ara...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _filterAccounts('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: _filterAccounts,
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Sonuç bulunamadı',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Arama kriterlerinizi değiştirip tekrar deneyin',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Henüz KMH hesabı eklenmemiş',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'KMH hesaplarınızı takip etmeye başlamak için\n"KMH Hesabı Ekle" butonuna tıklayın',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredKmhAccounts.length,
      itemBuilder: (context, index) {
        final account = _filteredKmhAccounts[index];
        return _buildAccountCard(account);
      },
    );
  }

  Widget _buildAccountCard(Wallet account) {
    final utilizationColor = _getUtilizationColor(account.utilizationRate);
    final maskedAccountNumber = _maskAccountNumber(account.accountNumber);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToAccountDetail(account),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(int.parse(account.color))
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_balance,
                      color: Color(int.parse(account.color)),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (maskedAccountNumber != null)
                          Text(
                            maskedAccountNumber,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: utilizationColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${account.utilizationRate.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: utilizationColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoColumn(
                      'Mevcut Bakiye',
                      _currencyFormat.format(account.balance),
                      account.balance < 0 ? Colors.red : Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      'Kullanılan Kredi',
                      _currencyFormat.format(account.usedCredit),
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: account.utilizationRate / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(utilizationColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Kullanılabilir: ${_currencyFormat.format(account.availableCredit)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (account.interestRate != null)
                    Row(
                      children: [
                        Icon(Icons.percent, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Faiz: %${account.interestRate!.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getUtilizationColor(double utilization) {
    if (utilization >= 80) {
      return Colors.red;
    } else if (utilization >= 50) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String? _maskAccountNumber(String? accountNumber) {
    if (accountNumber == null || accountNumber.isEmpty) {
      return null;
    }
    
    final masked = SensitiveDataHandler.maskAccountNumber(accountNumber);
    return masked != null ? SensitiveDataHandler.formatMaskedNumber(masked) : null;
  }
}
