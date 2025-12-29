import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/credit_card.dart';
import '../models/credit_card_transaction.dart';
import 'edit_credit_card_transaction_screen.dart';

class InstallmentDetailScreen extends StatefulWidget {
  final CreditCard card;
  final CreditCardTransaction transaction;

  const InstallmentDetailScreen({
    super.key,
    required this.card,
    required this.transaction,
  });

  @override
  State<InstallmentDetailScreen> createState() =>
      _InstallmentDetailScreenState();
}

class _InstallmentDetailScreenState extends State<InstallmentDetailScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final isDeferred = transaction.isDeferred;
    final startDate = transaction.effectiveStartDate;
    final now = DateTime.now();
    final remainingMonths = transaction.remainingInstallments;
    final isEndingSoon = remainingMonths <= 2 && remainingMonths > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taksit Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEdit,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(transaction),
          const SizedBox(height: 16),
          if (isEndingSoon) _buildEndingSoonWarning(remainingMonths),
          if (isEndingSoon) const SizedBox(height: 16),
          if (isDeferred) _buildDeferredInfoCard(transaction, startDate, now),
          if (isDeferred) const SizedBox(height: 16),
          _buildProgressCard(transaction),
          const SizedBox(height: 16),
          _buildPaymentSchedule(transaction, startDate),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(CreditCardTransaction transaction) {
    return Card(
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
                    color: widget.card.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    transaction.isDeferred
                        ? Icons.schedule_outlined
                        : Icons.credit_card,
                    color: widget.card.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.category,
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
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Toplam Tutar',
                    _currencyFormat.format(transaction.amount),
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Aylık Taksit',
                    _currencyFormat.format(transaction.installmentAmount),
                    Icons.calendar_month,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Kalan Tutar',
                    _currencyFormat.format(transaction.remainingAmount),
                    Icons.account_balance_wallet,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'İşlem Tarihi',
                    DateFormat('dd MMM yyyy', 'tr_TR')
                        .format(transaction.transactionDate),
                    Icons.event,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEndingSoonWarning(int remainingMonths) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Taksit Bitiyor',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    remainingMonths == 1
                        ? 'Bu taksit son ödemeye ulaştı'
                        : 'Bu taksitin bitmesine $remainingMonths ay kaldı',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade900,
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

  Widget _buildDeferredInfoCard(
    CreditCardTransaction transaction,
    DateTime startDate,
    DateTime now,
  ) {
    final monthsUntilStart =
        (startDate.year - now.year) * 12 + (startDate.month - now.month);
    final hasStarted = monthsUntilStart <= 0;

    return Card(
      color: hasStarted ? Colors.green.shade50 : Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasStarted ? Icons.check_circle : Icons.schedule,
                  color: hasStarted ? Colors.green.shade700 : Colors.blue.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ertelenmiş Taksit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: hasStarted ? Colors.green.shade700 : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Başlangıç Tarihi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMMM yyyy', 'tr_TR').format(startDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Durum',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasStarted
                            ? 'Başladı'
                            : '$monthsUntilStart ay sonra başlayacak',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: hasStarted
                              ? Colors.green.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(CreditCardTransaction transaction) {
    final progress = transaction.installmentsPaid / transaction.installmentCount;
    final progressPercentage = (progress * 100).toStringAsFixed(0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Taksit Durumu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ödenen Taksit',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${transaction.installmentsPaid}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'İlerleme',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$progressPercentage%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: widget.card.color,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Kalan Taksit',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${transaction.remainingInstallments}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(widget.card.color),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${transaction.installmentsPaid} / ${transaction.installmentCount} taksit ödendi',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSchedule(
    CreditCardTransaction transaction,
    DateTime startDate,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ödeme Takvimi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transaction.installmentCount,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _buildPaymentScheduleItem(
                  transaction,
                  startDate,
                  index + 1,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentScheduleItem(
    CreditCardTransaction transaction,
    DateTime startDate,
    int installmentNumber,
  ) {
    final paymentDate = DateTime(
      startDate.year,
      startDate.month + installmentNumber - 1,
      startDate.day,
    );

    final isPaid = installmentNumber <= transaction.installmentsPaid;
    final isCurrent = installmentNumber == transaction.installmentsPaid + 1;
    final now = DateTime.now();
    final isPast = paymentDate.isBefore(now) && !isPaid;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isPaid) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Ödendi';
    } else if (isCurrent) {
      statusColor = widget.card.color;
      statusIcon = Icons.schedule;
      statusText = 'Mevcut';
    } else if (isPast) {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
      statusText = 'Gecikmiş';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.circle_outlined;
      statusText = 'Bekliyor';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isCurrent
            ? widget.card.color.withValues(alpha: 0.05)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$installmentNumber',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(paymentDate),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currencyFormat.format(transaction.installmentAmount),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCreditCardTransactionScreen(
          card: widget.card,
          transaction: widget.transaction,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }
}
