import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/wallet.dart';
import '../models/kmh_transaction.dart';
import '../models/kmh_transaction_type.dart';
import '../models/kmh_summary.dart';
import '../services/kmh_service.dart';
import '../services/sensitive_data_handler.dart';
import 'kmh_statement_screen.dart';
import 'edit_kmh_account_screen.dart';

class KmhAccountDetailScreen extends StatefulWidget {
  final Wallet account;

  const KmhAccountDetailScreen({super.key, required this.account});

  @override
  State<KmhAccountDetailScreen> createState() => _KmhAccountDetailScreenState();
}

class _KmhAccountDetailScreenState extends State<KmhAccountDetailScreen> {
  final KmhService _kmhService = KmhService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  bool _isLoading = true;
  KmhSummary? _summary;
  List<KmhTransaction> _recentTransactions = [];
  static const int _maxRecentTransactions = 10;

  @override
  void initState() {
    super.initState();
    _loadAccountDetails();
  }

  Future<void> _loadAccountDetails() async {
    setState(() => _isLoading = true);

    try {
      final summary = await _kmhService.getAccountSummary(widget.account.id);
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));
      final statement = await _kmhService.generateStatement(
        widget.account.id,
        startDate,
        endDate,
      );

      setState(() {
        _summary = summary;
        _recentTransactions = statement.transactions
            .take(_maxRecentTransactions)
            .toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEdit,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAccountDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAccountDetails,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildAccountSummaryCard(),
                  const SizedBox(height: 16),
                  _buildCreditLimitIndicator(),
                  const SizedBox(height: 16),
                  _buildInterestInfo(),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildUsageChart(),
                  const SizedBox(height: 24),
                  _buildTransactionHistory(),
                ],
              ),
            ),
    );
  }

  Widget _buildAccountSummaryCard() {
    if (_summary == null) return const SizedBox.shrink();

    final isNegative = _summary!.currentBalance < 0;
    final balanceColor = isNegative ? Colors.red : Colors.green;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(int.parse(widget.account.color))
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: Color(int.parse(widget.account.color)),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.account.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (widget.account.accountNumber != null)
                        Text(
                          _maskAccountNumber(widget.account.accountNumber!),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    'Mevcut Bakiye',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currencyFormat.format(_summary!.currentBalance),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: balanceColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Kullanılan Kredi',
                    _currencyFormat.format(_summary!.usedCredit),
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Kullanılabilir',
                    _currencyFormat.format(_summary!.availableCredit),
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Kredi Limiti',
                    _currencyFormat.format(_summary!.creditLimit),
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Faiz Oranı',
                    '%${_summary!.interestRate.toStringAsFixed(2)}',
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditLimitIndicator() {
    if (_summary == null) return const SizedBox.shrink();

    Color statusColor;
    String statusText;
    
    if (_summary!.utilizationRate >= 95) {
      statusColor = Colors.red;
      statusText = 'Kritik Seviye';
    } else if (_summary!.utilizationRate >= 80) {
      statusColor = Colors.orange;
      statusText = 'Dikkat';
    } else if (_summary!.utilizationRate >= 50) {
      statusColor = Colors.yellow.shade700;
      statusText = 'Normal';
    } else {
      statusColor = Colors.green;
      statusText = 'İyi';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Limit Kullanımı',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currencyFormat.format(_summary!.usedCredit)} / ${_currencyFormat.format(_summary!.creditLimit)}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  '${_summary!.utilizationRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _summary!.utilizationRate / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 12,
              ),
            ),
            if (_summary!.utilizationRate >= 80)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _summary!.utilizationRate >= 95
                            ? 'Limitiniz dolmak üzere! Lütfen ödeme yapın.'
                            : 'Limitinizin %80\'ini aştınız.',
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                        ),
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

  Widget _buildInterestInfo() {
    if (_summary == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Faiz Bilgileri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInterestItem(
                    'Günlük Faiz',
                    _currencyFormat.format(_summary!.dailyInterestEstimate),
                    Icons.today,
                  ),
                ),
                Expanded(
                  child: _buildInterestItem(
                    'Aylık Tahmini',
                    _currencyFormat.format(_summary!.monthlyInterestEstimate),
                    Icons.calendar_month,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInterestItem(
                    'Yıllık Tahmini',
                    _currencyFormat.format(_summary!.annualInterestEstimate),
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildInterestItem(
                    'Toplam Tahakkuk',
                    _currencyFormat.format(_summary!.accruedInterest),
                    Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
            if (_summary!.lastInterestDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Son faiz: ${DateFormat('dd MMM yyyy HH:mm', 'tr_TR').format(_summary!.lastInterestDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            if (_summary!.isInDebt)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Faiz tahminleri mevcut borç tutarına göre hesaplanmıştır.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _navigateToWithdraw,
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('Para Çek'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _navigateToDeposit,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Para Yatır'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.green.shade400,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _navigateToStatement,
                icon: const Icon(Icons.receipt_long),
                label: const Text('Ekstre'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _navigateToPaymentPlan,
                icon: const Icon(Icons.calculate),
                label: const Text('Ödeme Planı'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUsageChart() {
    if (_summary == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Limit Kullanım Dağılımı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 50,
                        sections: _buildPieChartSections(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem(
                          'Kullanılan',
                          _summary!.usedCredit,
                          Colors.red,
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          'Kullanılabilir',
                          _summary!.availableCredit,
                          Colors.green,
                        ),
                      ],
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

  List<PieChartSectionData> _buildPieChartSections() {
    if (_summary == null) return [];

    final usedPercentage = _summary!.utilizationRate;
    final availablePercentage = 100 - usedPercentage;

    return [
      PieChartSectionData(
        value: usedPercentage,
        title: '${usedPercentage.toStringAsFixed(1)}%',
        color: Colors.red,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: availablePercentage,
        title: '${availablePercentage.toStringAsFixed(1)}%',
        color: Colors.green,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  Widget _buildLegendItem(String label, double value, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                _currencyFormat.format(value),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Son İşlemler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _navigateToAllTransactions,
              child: const Text('Tümünü Gör'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _recentTransactions.isEmpty
            ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Henüz işlem yok',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentTransactions.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final transaction = _recentTransactions[index];
                    return _buildTransactionItem(transaction);
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildTransactionItem(KmhTransaction transaction) {
    IconData icon;
    Color iconColor;
    String prefix;

    switch (transaction.type) {
      case KmhTransactionType.withdrawal:
        icon = Icons.remove_circle_outline;
        iconColor = Colors.red;
        prefix = '-';
        break;
      case KmhTransactionType.deposit:
        icon = Icons.add_circle_outline;
        iconColor = Colors.green;
        prefix = '+';
        break;
      case KmhTransactionType.interest:
        icon = Icons.percent;
        iconColor = Colors.orange;
        prefix = '-';
        break;
      case KmhTransactionType.fee:
        icon = Icons.money_off;
        iconColor = Colors.purple;
        prefix = '-';
        break;
      case KmhTransactionType.transfer:
        icon = Icons.swap_horiz;
        iconColor = Colors.blue;
        prefix = '';
        break;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.2),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        transaction.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        DateFormat('dd MMM yyyy HH:mm', 'tr_TR').format(transaction.date),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$prefix${_currencyFormat.format(transaction.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: iconColor,
            ),
          ),
          Text(
            'Bakiye: ${_currencyFormat.format(transaction.balanceAfter)}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _maskAccountNumber(String accountNumber) {
    final masked = SensitiveDataHandler.maskAccountNumber(accountNumber);
    return SensitiveDataHandler.formatMaskedNumber(masked!);
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditKmhAccountScreen(account: widget.account),
      ),
    );

    if (result == true) {
      _loadAccountDetails();
    }
  }

  void _navigateToWithdraw() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Para çekme ekranı yakında eklenecek')),
    );
  }

  void _navigateToDeposit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Para yatırma ekranı yakında eklenecek')),
    );
  }

  void _navigateToStatement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KmhStatementScreen(account: widget.account),
      ),
    );
  }

  void _navigateToPaymentPlan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ödeme planı ekranı yakında eklenecek')),
    );
  }

  void _navigateToAllTransactions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tüm işlemler ekranı yakında eklenecek')),
    );
  }
}
