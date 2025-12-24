import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill_payment.dart';
import '../models/bill_template.dart';
import '../services/bill_payment_service.dart';
import '../services/bill_template_service.dart';
import '../utils/currency_helper.dart';
import '../services/data_service.dart';
class BillHistoryScreen extends StatefulWidget {
  const BillHistoryScreen({super.key});

  @override
  State<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends State<BillHistoryScreen> {
  final BillPaymentService _paymentService = BillPaymentService();
  final BillTemplateService _templateService = BillTemplateService();
  final DataService _dataService = DataService();

  List<BillPayment> _paidPayments = [];
  Map<String, BillTemplate> _templates = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final payments = await _paymentService.getPaidPayments();
      payments.sort((a, b) => b.paidDate!.compareTo(a.paidDate!));
      final Map<String, BillTemplate> templates = {};
      for (var payment in payments) {
        if (!templates.containsKey(payment.templateId)) {
          final template = await _templateService.getTemplate(
            payment.templateId,
          );
          if (template != null) {
            templates[payment.templateId] = template;
          }
        }
      }

      setState(() {
        _paidPayments = payments;
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _dataService.getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fatura Geçmişi'),
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _paidPayments.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _paidPayments.length,
                itemBuilder: (context, index) {
                  final payment = _paidPayments[index];
                  final template = _templates[payment.templateId];
                  return _buildPaymentCard(payment, template, user);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Henüz ödeme geçmişi yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ödediğiniz faturalar burada görünecek',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(
    BillPayment payment,
    BillTemplate? template,
    Future<dynamic> user,
  ) {
    final templateName = template?.name ?? 'Bilinmeyen Fatura';
    final provider = template?.provider;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(template?.category),
            color: Colors.green,
          ),
        ),
        title: Text(
          templateName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider != null)
              Text(provider, style: const TextStyle(fontSize: 12)),
            Text(
              'Ödeme: ${DateFormat('dd MMM yyyy', 'tr_TR').format(payment.paidDate!)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              payment.periodDisplayName,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: FutureBuilder(
          future: user,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            return Text(
              CurrencyHelper.formatAmount(payment.amount, snapshot.data),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getCategoryIcon(BillTemplateCategory? category) {
    if (category == null) return Icons.receipt;

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
}
