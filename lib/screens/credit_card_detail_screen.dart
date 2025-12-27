import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/credit_card.dart';
import '../models/credit_card_transaction.dart';
import '../services/credit_card_service.dart';
import '../services/reward_points_service.dart';
import '../services/cash_advance_service.dart';
import '../services/deferred_installment_service.dart';
import 'add_credit_card_screen.dart';
import 'add_credit_card_transaction_screen.dart';
import 'make_credit_card_payment_screen.dart';
import 'edit_credit_card_transaction_screen.dart';
import 'payment_planner_screen.dart';
import 'payment_history_screen.dart';
import 'reward_points_screen.dart';
import 'installment_detail_screen.dart';

class CreditCardDetailScreen extends StatefulWidget {
  final CreditCard card;

  const CreditCardDetailScreen({super.key, required this.card});

  @override
  State<CreditCardDetailScreen> createState() => _CreditCardDetailScreenState();
}

class _CreditCardDetailScreenState extends State<CreditCardDetailScreen> {
  final CreditCardService _cardService = CreditCardService();
  final RewardPointsService _rewardService = RewardPointsService();
  final CashAdvanceService _cashAdvanceService = CashAdvanceService();
  final DeferredInstallmentService _deferredService = DeferredInstallmentService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  bool _isLoading = true;
  double _availableCredit = 0;
  double _utilization = 0;
  DateTime? _nextStatementDate;
  DateTime? _nextDueDate;
  List<CreditCardTransaction> _recentTransactions = [];
  List<CreditCardTransaction> _activeInstallments = [];
  Map<String, dynamic>? _rewardSummary;
  Map<String, dynamic>? _cashAdvanceSummary;
  double _periodDebt = 0;
  double _totalDebt = 0;
  List<CreditCardTransaction> _deferredInstallments = [];

  @override
  void initState() {
    super.initState();
    _loadCardDetails();
  }

  Future<void> _loadCardDetails() async {
    setState(() => _isLoading = true);

    try {
      final details = await _cardService.getCardWithDetails(widget.card.id);
      final transactions = await _cardService.getCardTransactions(
        widget.card.id,
      );
      final installments = await _cardService.getActiveInstallments(
        widget.card.id,
      );
      transactions.sort(
        (a, b) => b.transactionDate.compareTo(a.transactionDate),
      );
      final recentTransactions = transactions.take(10).toList();
      Map<String, dynamic>? rewardSummary;
      try {
        rewardSummary = await _rewardService.getPointsSummary(widget.card.id);
      } catch (e) {
        rewardSummary = null;
      }
      Map<String, dynamic>? cashAdvanceSummary;
      try {
        cashAdvanceSummary = await _cashAdvanceService.getCashAdvanceSummary(widget.card.id);
      } catch (e) {
        cashAdvanceSummary = null;
      }
      List<CreditCardTransaction> deferredInstallments = [];
      try {
        deferredInstallments = await _deferredService.getDeferredInstallments(widget.card.id);
      } catch (e) {
        deferredInstallments = [];
      }
      final periodDebt = details['currentDebt'] as double;
      final totalDebt = details['currentDebt'] as double;

      setState(() {
        _availableCredit = details['availableCredit'] as double;
        _utilization = details['utilization'] as double;
        _nextStatementDate = details['nextStatementDate'] as DateTime;
        _nextDueDate = details['nextDueDate'] as DateTime;
        _recentTransactions = recentTransactions;
        _activeInstallments = installments;
        _rewardSummary = rewardSummary;
        _cashAdvanceSummary = cashAdvanceSummary;
        _periodDebt = periodDebt;
        _totalDebt = totalDebt;
        _deferredInstallments = deferredInstallments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.card.bankName} ${widget.card.cardName}'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _navigateToEdit),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCardDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCardDetails,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCardHeader(),
                  const SizedBox(height: 16),
                  _buildDebtSummary(),
                  const SizedBox(height: 16),
                  if (_rewardSummary != null && _rewardSummary!['exists'] == true)
                    _buildRewardPointsSection(),
                  if (_rewardSummary != null && _rewardSummary!['exists'] == true)
                    const SizedBox(height: 16),
                  if (_cashAdvanceSummary != null && _cashAdvanceSummary!['totalDebt'] > 0)
                    _buildCashAdvanceSection(),
                  if (_cashAdvanceSummary != null && _cashAdvanceSummary!['totalDebt'] > 0)
                    const SizedBox(height: 16),
                  _buildDatesCard(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  _buildActiveInstallmentsSection(),
                  const SizedBox(height: 24),
                  if (_deferredInstallments.isNotEmpty)
                    _buildDeferredInstallmentsSection(),
                  if (_deferredInstallments.isNotEmpty)
                    const SizedBox(height: 24),
                  _buildRecentTransactionsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildCardHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: widget.card.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.credit_card,
                color: widget.card.color,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.card.bankName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.card.cardName} •••• ${widget.card.last4Digits}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Limit: ${_currencyFormat.format(widget.card.creditLimit)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtSummary() {
    Color statusColor;
    if (_utilization >= 80) {
      statusColor = Colors.red;
    } else if (_utilization >= 50) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.green;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Borç Durumu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Dönem Borcu',
                    _currencyFormat.format(_periodDebt),
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Toplam Borç',
                    _currencyFormat.format(_totalDebt),
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Kullanılabilir Limit',
                    _currencyFormat.format(_availableCredit),
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Toplam Limit',
                    _currencyFormat.format(widget.card.creditLimit),
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Limit Kullanımı',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  '${_utilization.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _utilization / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardPointsSection() {
    if (_rewardSummary == null || _rewardSummary!['exists'] != true) {
      return const SizedBox.shrink();
    }

    final balance = _rewardSummary!['balance'] as double;
    final valueInCurrency = _rewardSummary!['valueInCurrency'] as double;
    final rewardType = _rewardSummary!['rewardType'] as String;
    
    String rewardTypeName;
    IconData rewardIcon;
    switch (rewardType) {
      case 'bonus':
        rewardTypeName = 'Bonus Puan';
        rewardIcon = Icons.star;
        break;
      case 'worldpuan':
        rewardTypeName = 'WorldPuan';
        rewardIcon = Icons.public;
        break;
      case 'miles':
        rewardTypeName = 'Mil';
        rewardIcon = Icons.flight;
        break;
      case 'cashback':
        rewardTypeName = 'Cashback';
        rewardIcon = Icons.money;
        break;
      default:
        rewardTypeName = 'Puan';
        rewardIcon = Icons.card_giftcard;
    }

    return Card(
      child: InkWell(
        onTap: _navigateToRewardPoints,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(rewardIcon, color: widget.card.color),
                      const SizedBox(width: 8),
                      Text(
                        rewardTypeName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Puan Bakiyesi',
                      balance.toStringAsFixed(0),
                      widget.card.color,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'TL Karşılığı',
                      _currencyFormat.format(valueInCurrency),
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashAdvanceSection() {
    if (_cashAdvanceSummary == null || _cashAdvanceSummary!['totalDebt'] <= 0) {
      return const SizedBox.shrink();
    }

    final totalDebt = _cashAdvanceSummary!['totalDebt'] as double;
    final totalInterest = _cashAdvanceSummary!['totalInterest'] as double;
    final totalWithInterest = _cashAdvanceSummary!['totalWithInterest'] as double;
    final unpaidCount = _cashAdvanceSummary!['unpaidCount'] as int;

    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Nakit Avans Borcu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Ana Para',
                    _currencyFormat.format(totalDebt),
                    Colors.red.shade700,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Faiz',
                    _currencyFormat.format(totalInterest),
                    Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Toplam Borç (Faiz Dahil)',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                Text(
                  _currencyFormat.format(totalWithInterest),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$unpaidCount adet ödenmemiş nakit avans işlemi',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeferredInstallmentsSection() {
    if (_deferredInstallments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ertelenmiş Taksitler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_deferredInstallments.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _deferredInstallments.length > 3
                ? 3
                : _deferredInstallments.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = _deferredInstallments[index];
              return _buildDeferredInstallmentItem(transaction);
            },
          ),
        ),
        if (_deferredInstallments.length > 3)
          TextButton(
            onPressed: _navigateToInstallments,
            child: const Text('Tümünü Gör'),
          ),
      ],
    );
  }

  Widget _buildDeferredInstallmentItem(CreditCardTransaction transaction) {
    final startDate = transaction.installmentStartDate ?? transaction.transactionDate;
    final now = DateTime.now();
    final monthsUntilStart = (startDate.year - now.year) * 12 + (startDate.month - now.month);

    return ListTile(
      onTap: () => _navigateToInstallmentDetail(transaction),
      leading: CircleAvatar(
        backgroundColor: Colors.orange.shade100,
        child: Icon(Icons.schedule_outlined, color: Colors.orange.shade700, size: 20),
      ),
      title: Text(
        transaction.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            '${transaction.installmentCount}x ${_currencyFormat.format(transaction.installmentAmount)}/ay',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            monthsUntilStart > 0
                ? 'Başlangıç: $monthsUntilStart ay sonra'
                : 'Bu ay başlıyor',
            style: TextStyle(
              fontSize: 11,
              color: monthsUntilStart > 0 ? Colors.orange.shade700 : Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      trailing: Text(
        _currencyFormat.format(transaction.amount),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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

  Widget _buildDatesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Önemli Tarihler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDateItem(
                    'Sonraki Ekstre',
                    _nextStatementDate != null
                        ? DateFormat(
                            'dd MMM yyyy',
                            'tr_TR',
                          ).format(_nextStatementDate!)
                        : '-',
                    Icons.receipt_long,
                  ),
                ),
                Expanded(
                  child: _buildDateItem(
                    'Son Ödeme',
                    _nextDueDate != null
                        ? DateFormat(
                            'dd MMM yyyy',
                            'tr_TR',
                          ).format(_nextDueDate!)
                        : '-',
                    Icons.payment,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateItem(String label, String date, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              date,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _navigateToAddTransaction,
                icon: const Icon(Icons.add),
                label: const Text('İşlem Ekle'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _navigateToMakePayment,
                icon: const Icon(Icons.payment),
                label: const Text('Ödeme Yap'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                onPressed: _navigateToPaymentPlanner,
                icon: const Icon(Icons.calculate),
                label: const Text('Ödeme Planlayıcı'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _navigateToPaymentHistory,
                icon: const Icon(Icons.history),
                label: const Text('Ödeme Geçmişi'),
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

  Widget _buildActiveInstallmentsSection() {
    if (_activeInstallments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Aktif Taksitler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.card.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_activeInstallments.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.card.color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 3,
                      child: Text(
                        'Açıklama',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Durum',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Aylık',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activeInstallments.length > 5
                    ? 5
                    : _activeInstallments.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final transaction = _activeInstallments[index];
                  return _buildInstallmentTableRow(transaction);
                },
              ),
            ],
          ),
        ),
        if (_activeInstallments.length > 5)
          TextButton(
            onPressed: _navigateToInstallments,
            child: const Text('Tümünü Gör'),
          ),
      ],
    );
  }

  Widget _buildInstallmentTableRow(CreditCardTransaction transaction) {
    final progress = transaction.installmentsPaid / transaction.installmentCount;

    return InkWell(
      onTap: () => _navigateToInstallmentDetail(transaction),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kalan: ${_currencyFormat.format(transaction.remainingAmount)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    '${transaction.installmentsPaid}/${transaction.installmentCount}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(widget.card.color),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _currencyFormat.format(transaction.installmentAmount),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildRecentTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Son İşlemler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _buildTransactionItem(CreditCardTransaction transaction) {
    final isInstallment = transaction.installmentCount > 1;

    return ListTile(
      onTap: () => _navigateToEditTransaction(transaction),
      leading: CircleAvatar(
        backgroundColor: widget.card.color.withValues(alpha: 0.2),
        child: Icon(
          isInstallment ? Icons.schedule : Icons.shopping_bag,
          color: widget.card.color,
          size: 20,
        ),
      ),
      title: Text(
        transaction.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${DateFormat('dd MMM yyyy', 'tr_TR').format(transaction.transactionDate)} • ${transaction.category}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _currencyFormat.format(transaction.amount),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (isInstallment)
            Text(
              '${transaction.installmentCount}x',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCreditCardScreen(card: widget.card),
      ),
    );

    if (result == true) {
      await _loadCardDetails();
      if (mounted) {
        Navigator.pop(context, true);
        final updatedCard = await _cardService.getCard(widget.card.id);
        if (updatedCard != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreditCardDetailScreen(card: updatedCard),
            ),
          );
        }
      }
    }
  }

  Future<void> _navigateToAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCreditCardTransactionScreen(card: widget.card),
      ),
    );

    if (result == true) {
      _loadCardDetails();
    }
  }

  Future<void> _navigateToMakePayment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MakeCreditCardPaymentScreen(card: widget.card),
      ),
    );

    if (result == true) {
      _loadCardDetails();
    }
  }

  Future<void> _navigateToPaymentPlanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPlannerScreen(card: widget.card),
      ),
    );
  }

  Future<void> _navigateToPaymentHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentHistoryScreen(card: widget.card),
      ),
    );
  }

  void _navigateToInstallments() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Taksit detayını görmek için taksitlere tıklayın')),
    );
  }

  Future<void> _navigateToInstallmentDetail(
    CreditCardTransaction transaction,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstallmentDetailScreen(
          card: widget.card,
          transaction: transaction,
        ),
      ),
    );

    if (result == true) {
      _loadCardDetails();
    }
  }

  void _navigateToAllTransactions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tüm işlemler ekranı yakında eklenecek')),
    );
  }

  Future<void> _navigateToEditTransaction(
    CreditCardTransaction transaction,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCreditCardTransactionScreen(
          card: widget.card,
          transaction: transaction,
        ),
      ),
    );

    if (result == true) {
      _loadCardDetails();
    }
  }

  Future<void> _navigateToRewardPoints() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RewardPointsScreen(card: widget.card),
      ),
    );
    _loadCardDetails();
  }
}
