import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/credit_card.dart';
import '../models/credit_card_transaction.dart';
import '../services/credit_card_service.dart';
import 'add_credit_card_screen.dart';
import 'add_credit_card_transaction_screen.dart';
import 'make_credit_card_payment_screen.dart';
import 'edit_credit_card_transaction_screen.dart';

class CreditCardDetailScreen extends StatefulWidget {
  final CreditCard card;

  const CreditCardDetailScreen({super.key, required this.card});

  @override
  State<CreditCardDetailScreen> createState() => _CreditCardDetailScreenState();
}

class _CreditCardDetailScreenState extends State<CreditCardDetailScreen> {
  final CreditCardService _cardService = CreditCardService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  bool _isLoading = true;
  double _currentDebt = 0;
  double _availableCredit = 0;
  double _utilization = 0;
  DateTime? _nextStatementDate;
  DateTime? _nextDueDate;
  List<CreditCardTransaction> _recentTransactions = [];
  List<CreditCardTransaction> _activeInstallments = [];

  @override
  void initState() {
    super.initState();
    _loadCardDetails();
  }

  Future<void> _loadCardDetails() async {
    setState(() => _isLoading = true);

    try {
      final details = await _cardService.getCardWithDetails(widget.card.id);
      final transactions = await _cardService.getCardTransactions(widget.card.id);
      final installments = await _cardService.getActiveInstallments(widget.card.id);

      // Sort transactions by date (newest first) and take last 10
      transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      final recentTransactions = transactions.take(10).toList();

      setState(() {
        _currentDebt = details['currentDebt'] as double;
        _availableCredit = details['availableCredit'] as double;
        _utilization = details['utilization'] as double;
        _nextStatementDate = details['nextStatementDate'] as DateTime;
        _nextDueDate = details['nextDueDate'] as DateTime;
        _recentTransactions = recentTransactions;
        _activeInstallments = installments;
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
        title: Text('${widget.card.bankName} ${widget.card.cardName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEdit,
          ),
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
                  _buildDatesCard(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  _buildActiveInstallmentsSection(),
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
                color: widget.card.color.withOpacity(0.2),
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
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Limit: ${_currencyFormat.format(widget.card.creditLimit)}',
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Mevcut Borç',
                    _currencyFormat.format(_currentDebt),
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Kullanılabilir',
                    _currencyFormat.format(_availableCredit),
                    Colors.green,
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
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

  Widget _buildDatesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Önemli Tarihler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDateItem(
                    'Sonraki Ekstre',
                    _nextStatementDate != null
                        ? DateFormat('dd MMM yyyy', 'tr_TR').format(_nextStatementDate!)
                        : '-',
                    Icons.receipt_long,
                  ),
                ),
                Expanded(
                  child: _buildDateItem(
                    'Son Ödeme',
                    _nextDueDate != null
                        ? DateFormat('dd MMM yyyy', 'tr_TR').format(_nextDueDate!)
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              date,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _navigateToInstallments,
              child: const Text('Tümünü Gör'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activeInstallments.length > 3 ? 3 : _activeInstallments.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = _activeInstallments[index];
              return _buildInstallmentItem(transaction);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInstallmentItem(CreditCardTransaction transaction) {
    final progress = transaction.installmentsPaid / transaction.installmentCount;

    return ListTile(
      onTap: () => _navigateToEditTransaction(transaction),
      leading: CircleAvatar(
        backgroundColor: widget.card.color.withOpacity(0.2),
        child: Icon(
          Icons.schedule,
          color: widget.card.color,
          size: 20,
        ),
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
            '${transaction.installmentsPaid}/${transaction.installmentCount} taksit - ${_currencyFormat.format(transaction.installmentAmount)}/ay',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(widget.card.color),
              minHeight: 4,
            ),
          ),
        ],
      ),
      trailing: Text(
        _currencyFormat.format(transaction.remainingAmount),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
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
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
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
                  separatorBuilder: (context, index) => const Divider(height: 1),
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
        backgroundColor: widget.card.color.withOpacity(0.2),
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (isInstallment)
            Text(
              '${transaction.installmentCount}x',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
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
      _loadCardDetails();
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

  void _navigateToInstallments() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Taksit takip ekranı yakında eklenecek')),
    );
  }

  void _navigateToAllTransactions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tüm işlemler ekranı yakında eklenecek')),
    );
  }

  Future<void> _navigateToEditTransaction(CreditCardTransaction transaction) async {
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
}
