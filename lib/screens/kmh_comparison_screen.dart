import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/wallet.dart';
import '../services/data_service.dart';
import '../services/kmh_interest_calculator.dart';
import 'kmh_account_detail_screen.dart';
class KmhComparisonScreen extends StatefulWidget {
  const KmhComparisonScreen({super.key});

  @override
  State<KmhComparisonScreen> createState() => _KmhComparisonScreenState();
}

class _KmhComparisonScreenState extends State<KmhComparisonScreen> {
  final DataService _dataService = DataService();
  final KmhInterestCalculator _calculator = KmhInterestCalculator();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  List<Wallet> _kmhAccounts = [];
  bool _isLoading = true;
  Wallet? _recommendedAccount;
  double _totalDebt = 0;
  double _totalInterest = 0;
  double _totalCreditLimit = 0;
  double _totalAvailableCredit = 0;

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
      kmhAccounts.sort((a, b) {
        final rateA = a.interestRate ?? 0;
        final rateB = b.interestRate ?? 0;
        return rateA.compareTo(rateB);
      });
      final recommended = _findRecommendedAccount(kmhAccounts);
      double totalDebt = 0;
      double totalInterest = 0;
      double totalCreditLimit = 0;
      double totalAvailableCredit = 0;

      for (var account in kmhAccounts) {
        totalDebt += account.usedCredit;
        totalCreditLimit += account.creditLimit;
        totalAvailableCredit += account.availableCredit;
        if (account.interestRate != null) {
          final monthlyInterest = _calculator.estimateMonthlyInterest(
            balance: account.balance,
            annualRate: account.interestRate!,
          );
          totalInterest += monthlyInterest;
        }
      }

      setState(() {
        _kmhAccounts = kmhAccounts;
        _recommendedAccount = recommended;
        _totalDebt = totalDebt;
        _totalInterest = totalInterest;
        _totalCreditLimit = totalCreditLimit;
        _totalAvailableCredit = totalAvailableCredit;
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
  Wallet? _findRecommendedAccount(List<Wallet> accounts) {
    if (accounts.isEmpty) return null;
    final accountsWithCredit = accounts.where((a) => a.availableCredit > 0).toList();
    
    if (accountsWithCredit.isEmpty) return null;
    accountsWithCredit.sort((a, b) {
      final rateA = a.interestRate ?? double.infinity;
      final rateB = b.interestRate ?? double.infinity;
      final rateComparison = rateA.compareTo(rateB);
      if (rateComparison != 0) return rateComparison;
      return b.availableCredit.compareTo(a.availableCredit);
    });

    return accountsWithCredit.first;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KMH Hesap Karşılaştırma'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadKmhAccounts,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _kmhAccounts.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTotalStatusCard(),
                      if (_recommendedAccount != null)
                        _buildRecommendationCard(),
                      _buildComparisonTable(),
                      if (_kmhAccounts.length > 1)
                        _buildTransferSuggestion(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.compare_arrows, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Karşılaştırılacak hesap yok',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'En az 2 KMH hesabı olmalıdır',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalStatusCard() {
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
                  Icons.assessment,
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
            _buildStatusRow(
              'Toplam Borç',
              _currencyFormat.format(_totalDebt),
              Colors.red,
              Icons.trending_down,
            ),
            const Divider(height: 24),
            _buildStatusRow(
              'Aylık Toplam Faiz',
              _currencyFormat.format(_totalInterest),
              Colors.orange,
              Icons.percent,
            ),
            const Divider(height: 24),
            _buildStatusRow(
              'Toplam Limit',
              _currencyFormat.format(_totalCreditLimit),
              Colors.blue,
              Icons.account_balance_wallet,
            ),
            const Divider(height: 24),
            _buildStatusRow(
              'Kullanılabilir Kredi',
              _currencyFormat.format(_totalAvailableCredit),
              Colors.green,
              Icons.trending_up,
            ),
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
                    '${_kmhAccounts.length} KMH Hesabı Karşılaştırılıyor',
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
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
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

  Widget _buildRecommendationCard() {
    final account = _recommendedAccount!;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      color: Colors.green.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.recommend,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Önerilen Hesap',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              account.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu hesap en düşük faiz oranına (%${account.interestRate?.toStringAsFixed(1)}) '
              'sahip ve ${_currencyFormat.format(account.availableCredit)} '
              'kullanılabilir kredisi var.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _navigateToAccountDetail(account),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Hesap Detayına Git'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hesap Karşılaştırma Tablosu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  Colors.grey[200],
                ),
                columns: const [
                  DataColumn(label: Text('Hesap', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Faiz Oranı', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Kullanım', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Aylık Faiz', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Kullanılabilir', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _kmhAccounts.map((account) {
                  final monthlyInterest = account.interestRate != null
                      ? _calculator.estimateMonthlyInterest(
                          balance: account.balance,
                          annualRate: account.interestRate!,
                        )
                      : 0.0;

                  final isRecommended = account.id == _recommendedAccount?.id;

                  return DataRow(
                    color: WidgetStateProperty.all(
                      isRecommended
                          ? Colors.green.withValues(alpha: 0.1)
                          : null,
                    ),
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            if (isRecommended)
                              const Icon(
                                Icons.star,
                                color: Colors.green,
                                size: 16,
                              ),
                            if (isRecommended) const SizedBox(width: 4),
                            Text(
                              account.name.length > 15
                                  ? '${account.name.substring(0, 15)}...'
                                  : account.name,
                            ),
                          ],
                        ),
                        onTap: () => _navigateToAccountDetail(account),
                      ),
                      DataCell(
                        Text(
                          account.interestRate != null
                              ? '%${account.interestRate!.toStringAsFixed(1)}'
                              : 'N/A',
                          style: TextStyle(
                            color: _getInterestRateColor(account.interestRate),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            Text(
                              '${account.utilizationRate.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: _getUtilizationColor(account.utilizationRate),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          _currencyFormat.format(monthlyInterest),
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          _currencyFormat.format(account.availableCredit),
                          style: TextStyle(
                            color: account.availableCredit > 0
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferSuggestion() {
    final accountsWithDebt = _kmhAccounts
        .where((a) => a.balance < 0)
        .toList()
      ..sort((a, b) {
        final rateA = a.interestRate ?? 0;
        final rateB = b.interestRate ?? 0;
        return rateB.compareTo(rateA);
      });

    final accountsWithCredit = _kmhAccounts
        .where((a) => a.availableCredit > 0)
        .toList()
      ..sort((a, b) {
        final rateA = a.interestRate ?? double.infinity;
        final rateB = b.interestRate ?? double.infinity;
        return rateA.compareTo(rateB);
      });

    if (accountsWithDebt.isEmpty || accountsWithCredit.isEmpty) {
      return const SizedBox.shrink();
    }

    final highestRateAccount = accountsWithDebt.first;
    final lowestRateAccount = accountsWithCredit.first;
    final rateDifference = (highestRateAccount.interestRate ?? 0) -
        (lowestRateAccount.interestRate ?? 0);

    if (rateDifference <= 0 || highestRateAccount.id == lowestRateAccount.id) {
      return const SizedBox.shrink();
    }
    final transferAmount = highestRateAccount.usedCredit < lowestRateAccount.availableCredit
        ? highestRateAccount.usedCredit
        : lowestRateAccount.availableCredit;

    final currentMonthlyInterest = _calculator.estimateMonthlyInterest(
      balance: -transferAmount,
      annualRate: highestRateAccount.interestRate!,
    );

    final newMonthlyInterest = _calculator.estimateMonthlyInterest(
      balance: -transferAmount,
      annualRate: lowestRateAccount.interestRate!,
    );

    final monthlySavings = currentMonthlyInterest - newMonthlyInterest;
    final annualSavings = monthlySavings * 12;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      color: Colors.blue.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Transfer Önerisi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Faiz tasarrufu için hesaplar arası transfer önerisi:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${highestRateAccount.name} (%${highestRateAccount.interestRate?.toStringAsFixed(1)})',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      SizedBox(width: 28),
                      Icon(Icons.arrow_downward, color: Colors.grey, size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.arrow_downward, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${lowestRateAccount.name} (%${lowestRateAccount.interestRate?.toStringAsFixed(1)})',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transfer Tutarı: ${_currencyFormat.format(transferAmount)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aylık Tasarruf: ${_currencyFormat.format(monthlySavings)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Yıllık Tasarruf: ${_currencyFormat.format(annualSavings)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Not: Bu öneri sadece bilgilendirme amaçlıdır. '
              'Transfer işlemini bankanız üzerinden gerçekleştirebilirsiniz.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
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

  Color _getInterestRateColor(double? rate) {
    if (rate == null) return Colors.grey;
    
    if (rate >= 30) {
      return Colors.red;
    } else if (rate >= 20) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
