import 'package:flutter/material.dart';
import '../models/bill_template.dart';
import '../models/bill_payment.dart';
import '../services/bill_payment_service.dart';
import 'add_bill_template_screen.dart';
import 'package:intl/intl.dart';
import '../utils/format_helper.dart';

class BillTemplateDetailScreen extends StatefulWidget {
  final BillTemplate template;

  const BillTemplateDetailScreen({super.key, required this.template});

@override
  State<BillTemplateDetailScreen> createState() =>
      _BillTemplateDetailScreenState();
}

class _BillTemplateDetailScreenState extends State<BillTemplateDetailScreen> {
  final BillPaymentService _paymentService = BillPaymentService();
  List<BillPayment> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _loading = true);
    final payments = await _paymentService.getPaymentsByTemplate(
      widget.template.id,
    );
    payments.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    setState(() {
      _payments = payments;
      _loading = false;
    });
  }

  IconData _getCategoryIcon(BillTemplateCategory category) {
    switch (category) {
      case BillTemplateCategory.electricity:
        return Icons.bolt;
      case BillTemplateCategory.water:
        return Icons.water_drop;
      case BillTemplateCategory.gas:
        return Icons.local_fire_department;
      case BillTemplateCategory.internet:
        return Icons.wifi;
      case BillTemplateCategory.phone:
        return Icons.phone;
      case BillTemplateCategory.rent:
        return Icons.home;
      case BillTemplateCategory.insurance:
        return Icons.shield;
      case BillTemplateCategory.subscription:
        return Icons.subscriptions;
      case BillTemplateCategory.other:
        return Icons.receipt;
    }
  }

  Color _getStatusColor(BillPaymentStatus status) {
    switch (status) {
      case BillPaymentStatus.paid:
        return Colors.green;
      case BillPaymentStatus.pending:
        return Colors.orange;
      case BillPaymentStatus.overdue:
        return Colors.red;
    }
  }

  String _getStatusText(BillPaymentStatus status) {
    switch (status) {
      case BillPaymentStatus.paid:
        return 'Ödendi';
      case BillPaymentStatus.pending:
        return 'Bekliyor';
      case BillPaymentStatus.overdue:
        return 'Gecikmiş';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.displayTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              if (!context.mounted) return;
              final navigator = Navigator.of(context);
              final result = await navigator.push(
                MaterialPageRoute(
                  builder: (context) =>
                      AddBillTemplateScreen(template: widget.template),
                ),
              );
              if (result == true) {
                navigator.pop(true);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTemplateInfo(),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _payments.isEmpty
                ? _buildEmptyPayments()
                : _buildPaymentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(widget.template.category),
                  color: const Color(0xFF00BFA5),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.template.displayTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.template.categoryDisplayName,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (!widget.template.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Pasif',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          if (widget.template.provider != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.business,
              'Sağlayıcı',
              widget.template.provider!,
            ),
          ],
          if (widget.template.accountNumber != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.numbers,
              'Abone No',
              widget.template.accountNumber!,
            ),
          ],
          if (widget.template.phoneNumber != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.phone,
              'Telefon',
              FormatHelper.formatPhoneNumber(widget.template.phoneNumber!),
            ),
          ],
          if (widget.template.description != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.note, 'Açıklama', widget.template.description!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  Widget _buildEmptyPayments() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Henüz ödeme kaydı yok',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu fatura için ödeme yaptığınızda\nburada görünecektir',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        return _buildPaymentCard(payment);
      },
    );
  }

  Widget _buildPaymentCard(BillPayment payment) {
    final dateFormat = DateFormat('dd MMM yyyy', 'tr_TR');
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currencyFormat.format(payment.amount),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      payment.status,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusText(payment.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(payment.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPaymentInfoRow(
              Icons.calendar_today,
              'Son Ödeme',
              dateFormat.format(payment.dueDate),
            ),
            if (payment.paidDate != null) ...[
              const SizedBox(height: 8),
              _buildPaymentInfoRow(
                Icons.check_circle,
                'Ödeme Tarihi',
                dateFormat.format(payment.paidDate!),
              ),
            ],
            const SizedBox(height: 8),
            _buildPaymentInfoRow(
              Icons.date_range,
              'Dönem',
              '${dateFormat.format(payment.periodStart)} - ${dateFormat.format(payment.periodEnd)}',
            ),
            if (payment.notes != null) ...[
              const SizedBox(height: 8),
              _buildPaymentInfoRow(Icons.note, 'Not', payment.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
