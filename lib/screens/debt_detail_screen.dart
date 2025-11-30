import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/debt.dart';
import '../models/debt_payment.dart';
import '../services/debt_service.dart';
import 'edit_debt_screen.dart';

class DebtDetailScreen extends StatefulWidget {
  final String debtId;

  const DebtDetailScreen({super.key, required this.debtId});

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  final DebtService _debtService = DebtService();

  Debt? _debt;
  List<DebtPayment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDebt();
  }

  Future<void> _loadDebt() async {
    setState(() => _isLoading = true);

    try {
      final debt = await _debtService.getDebtById(widget.debtId);
      if (debt == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Borç/alacak bulunamadı')),
          );
        }
        return;
      }

      final payments = await _debtService.getPayments(widget.debtId);

      setState(() {
        _debt = debt;
        _payments = payments;
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

  Future<void> _showAddPaymentDialog() async {
    if (_debt == null) return;

    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ödeme Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Tutar',
                    suffixText: '₺',
                    hintText: 'Kalan: ₺${_debt!.remainingAmount.toStringAsFixed(2)}',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Tarih'),
                  subtitle: Text(DateFormat('dd.MM.yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Not (opsiyonel)',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(
                    amountController.text.replaceAll(',', '.'));

                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Geçerli bir tutar girin')),
                  );
                  return;
                }

                if (amount > _debt!.remainingAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Tutar kalan tutardan fazla olamaz')),
                  );
                  return;
                }

                try {
                  await _debtService.addPayment(
                    debtId: widget.debtId,
                    amount: amount,
                    date: selectedDate,
                    type: amount >= _debt!.remainingAmount
                        ? PaymentType.full
                        : PaymentType.partial,
                    note: noteController.text.isEmpty
                        ? null
                        : noteController.text,
                  );

                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hata: $e')),
                    );
                  }
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _loadDebt();
    }
  }

  Future<void> _deleteDebt() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borç/Alacak Sil'),
        content: const Text('Bu borç/alacağı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _debtService.deleteDebt(widget.debtId);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Borç/alacak silindi')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }

  Future<void> _markAsPaid() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödendi Olarak İşaretle'),
        content: const Text('Bu borç/alacağı tamamen ödendi olarak işaretlemek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ödendi'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _debtService.markAsPaid(widget.debtId);
        _loadDebt();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ödendi olarak işaretlendi')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }

  Future<void> _makePhoneCall() async {
    if (_debt?.phone == null) return;

    final uri = Uri(scheme: 'tel', path: _debt!.phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telefon araması yapılamadı')),
        );
      }
    }
  }

  Future<void> _sendSMS() async {
    if (_debt?.phone == null) return;

    final uri = Uri(scheme: 'sms', path: _debt!.phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS gönderilemedi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detaylar')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_debt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detaylar')),
        body: const Center(child: Text('Borç/alacak bulunamadı')),
      );
    }

    final formatter = NumberFormat('#,##0.00', 'tr_TR');
    final isLent = _debt!.type == DebtType.lent;
    final color = isLent ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(_debt!.personName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditDebtScreen(debt: _debt!),
                ),
              );
              if (result == true) {
                _loadDebt();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteDebt,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDebt,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummaryCard(formatter, color),
            const SizedBox(height: 16),
            if (_debt!.phone != null) _buildContactCard(),
            if (_debt!.phone != null) const SizedBox(height: 16),
            _buildPaymentHistoryCard(formatter),
          ],
        ),
      ),
      floatingActionButton: _debt!.status != DebtStatus.paid
          ? FloatingActionButton.extended(
              onPressed: _showAddPaymentDialog,
              icon: const Icon(Icons.payment),
              label: const Text('Ödeme Ekle'),
            )
          : null,
    );
  }

  Widget _buildSummaryCard(NumberFormat formatter, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  radius: 30,
                  child: Icon(
                    _debt!.type == DebtType.lent
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _debt!.type == DebtType.lent
                            ? 'Borç Verdim'
                            : 'Borç Aldım',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₺${formatter.format(_debt!.remainingAmount)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (_debt!.originalAmount != _debt!.remainingAmount)
                        Text(
                          'Toplam: ₺${formatter.format(_debt!.originalAmount)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_debt!.paymentPercentage > 0) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _debt!.paymentPercentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                '%${_debt!.paymentPercentage.toStringAsFixed(0)} ödendi',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const Divider(height: 32),
            _buildInfoRow(Icons.category, 'Kategori', _debt!.categoryText),
            if (_debt!.dueDate != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                _debt!.isOverdue ? Icons.warning : Icons.calendar_today,
                'Vade Tarihi',
                _debt!.dueDateStatus,
                color: _debt!.isOverdue ? Colors.orange : null,
              ),
            ],
            if (_debt!.description != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.notes, 'Açıklama', _debt!.description!),
            ],
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.access_time,
              'Oluşturulma',
              DateFormat('dd.MM.yyyy').format(_debt!.createdDate),
            ),
            if (_debt!.status == DebtStatus.paid) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Ödendi',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _markAsPaid,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Tamamen Ödendi Olarak İşaretle'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey[600]),
        const SizedBox(width: 12),
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'İletişim',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _makePhoneCall,
                    icon: const Icon(Icons.phone),
                    label: const Text('Ara'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sendSMS,
                    icon: const Icon(Icons.message),
                    label: const Text('Mesaj'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryCard(NumberFormat formatter) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ödeme Geçmişi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_payments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Henüz ödeme kaydı yok',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ..._payments.map((payment) => _buildPaymentItem(payment, formatter)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(DebtPayment payment, NumberFormat formatter) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.green.withOpacity(0.1),
        child: const Icon(Icons.payment, color: Colors.green),
      ),
      title: Text(
        '₺${formatter.format(payment.amount)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('dd.MM.yyyy').format(payment.date)),
          if (payment.note != null) Text(payment.note!),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Ödeme Sil'),
              content: const Text('Bu ödemeyi silmek istediğinizden emin misiniz?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Sil'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            try {
              await _debtService.deletePayment(widget.debtId, payment.id);
              _loadDebt();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ödeme silindi')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e')),
                );
              }
            }
          }
        },
      ),
    );
  }
}
