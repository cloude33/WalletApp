import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill_payment.dart';
import '../models/bill_template.dart';
import '../services/bill_payment_service.dart';
import '../services/bill_template_service.dart';
import '../services/data_service.dart';

class EditBillPaymentScreen extends StatefulWidget {
  final BillPayment payment;

  const EditBillPaymentScreen({super.key, required this.payment});

  @override
  State<EditBillPaymentScreen> createState() => _EditBillPaymentScreenState();
}

class _EditBillPaymentScreenState extends State<EditBillPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final BillPaymentService _paymentService = BillPaymentService();
  final BillTemplateService _templateService = BillTemplateService();
  final DataService _dataService = DataService();

  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late DateTime _dueDate;
  BillTemplate? _template;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.payment.amount.toStringAsFixed(2),
    );
    _selectedDate = widget.payment.paidDate ?? DateTime.now();
    _dueDate = widget.payment.dueDate;
    _loadTemplate();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplate() async {
    final template = await _templateService.getTemplate(widget.payment.templateId);
    setState(() {
      _template = template;
    });
  }

  Future<void> _updatePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedPayment = BillPayment(
        id: widget.payment.id,
        templateId: widget.payment.templateId,
        amount: double.parse(_amountController.text),
        dueDate: _dueDate,
        periodStart: widget.payment.periodStart,
        periodEnd: widget.payment.periodEnd,
        status: widget.payment.status,
        paidDate: _selectedDate,
        paidWithWalletId: widget.payment.paidWithWalletId,
        transactionId: widget.payment.transactionId,
        notes: widget.payment.notes,
        createdDate: widget.payment.createdDate,
        updatedDate: DateTime.now(),
      );

      await _paymentService.updatePayment(updatedPayment);

      if (mounted) {
        Navigator.pop(context, true); // true = updated
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fatura başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Güncelleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePayment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Faturayı Sil'),
        content: const Text('Bu fatura kaydını silmek istediğinizden emin misiniz?'),
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

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        await _paymentService.deletePayment(widget.payment.id);

        if (mounted) {
          Navigator.pop(context, true); // true = deleted
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fatura başarıyla silindi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Silme hatası: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faturayı Düzenle'),
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _deletePayment,
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Template Info
                    if (_template != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getCategoryIcon(_template!.category),
                                  color: const Color(0xFF00BFA5),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _template!.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_template!.provider != null)
                                      Text(
                                        _template!.provider!,
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
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Amount
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Tutar',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tutar gerekli';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Geçerli bir tutar girin';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Tutar 0\'dan büyük olmalı';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Due Date
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Vade Tarihi'),
                      subtitle: Text(DateFormat('dd MMM yyyy', 'tr_TR').format(_dueDate)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dueDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() => _dueDate = date);
                        }
                      },
                    ),
                    const Divider(),

                    // Payment Date
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.payment),
                      title: const Text('Ödeme Tarihi'),
                      subtitle: Text(DateFormat('dd MMM yyyy', 'tr_TR').format(_selectedDate)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                    ),
                    const Divider(),

                    const SizedBox(height: 32),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updatePayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BFA5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Güncelle'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
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
        return Icons.security;
      case BillTemplateCategory.subscription:
        return Icons.subscriptions;
      case BillTemplateCategory.other:
        return Icons.receipt;
    }
  }
}