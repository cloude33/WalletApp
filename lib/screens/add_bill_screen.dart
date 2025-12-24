import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/bill_template.dart';
import '../services/bill_template_service.dart';
import '../services/bill_payment_service.dart';
import 'bill_templates_screen.dart';

class AddBillScreen extends StatefulWidget {
  const AddBillScreen({super.key});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final BillTemplateService _templateService = BillTemplateService();
  final BillPaymentService _paymentService = BillPaymentService();

  final _amountController = TextEditingController();

  List<BillTemplate> _templates = [];
  BillTemplate? _selectedTemplate;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  DateTime? _periodStart;
  DateTime? _periodEnd;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _calculatePeriod();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _calculatePeriod() {
    final dueMonth = _dueDate.month;
    final dueYear = _dueDate.year;
    final previousMonth = dueMonth == 1 ? 12 : dueMonth - 1;
    final previousYear = dueMonth == 1 ? dueYear - 1 : dueYear;

    _periodStart = DateTime(previousYear, previousMonth, 1);
    _periodEnd = DateTime(dueYear, dueMonth, 0);
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await _templateService.getActiveTemplates();
      debugPrint('DEBUG AddBillScreen: Loaded ${templates.length} templates');
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('DEBUG AddBillScreen: Error loading templates: $e');
      setState(() {
        _templates = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fatura şablonları yüklenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF00BFA5)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
        _calculatePeriod();
      });
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir fatura seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_periodStart == null || _periodEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fatura dönemi hesaplanamadı'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final amount = double.parse(_amountController.text);

      await _paymentService.addPayment(
        templateId: _selectedTemplate!.id,
        amount: amount,
        dueDate: _dueDate,
        periodStart: _periodStart!,
        periodEnd: _periodEnd!,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fatura ödeme bilgisi eklendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fatura Ekle'),
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
          ? _buildEmptyState()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: Colors.blue.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ayarlarda tanımladığınız faturalar için bu ayın tutarını ve son ödeme tarihini girin.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF0D47A1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<BillTemplate>(
                    initialValue: _selectedTemplate,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Fatura *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.receipt_long),
                    ),
                    items: _templates.map((template) {
                      return DropdownMenuItem<BillTemplate>(
                        value: template,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              template.provider ?? template.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (template.category ==
                                    BillTemplateCategory.phone &&
                                template.phoneNumber != null)
                              Text(
                                template.phoneNumber!.startsWith('0')
                                    ? template.phoneNumber!
                                    : '0${template.phoneNumber!}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF757575),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedTemplate = value);
                    },
                    validator: (value) {
                      if (value == null) return 'Fatura seçimi gerekli';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Fatura Tutarı *',
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                      prefixText: '₺ ',
                      prefixIcon: Icon(Icons.payments),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Tutar gerekli';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Geçerli bir tutar girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _selectDueDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Son Ödeme Tarihi *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat(
                              'dd MMMM yyyy',
                              'tr_TR',
                            ).format(_dueDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.date_range,
                          size: 20,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _periodStart != null && _periodEnd != null
                                ? 'Fatura Dönemi: ${DateFormat('dd MMM', 'tr_TR').format(_periodStart!)} - ${DateFormat('dd MMM yyyy', 'tr_TR').format(_periodEnd!)}'
                                : 'Fatura Dönemi: -',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePayment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF00BFA5),
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Fatura Ekle',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
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
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz fatura tanımlamadınız',
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF757575),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Önce Ayarlar > Faturalarım bölümünden\nfatura tanımlamanız gerekiyor',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BillTemplatesScreen(),
                ),
              );
              if (result == true && mounted) {
                _loadTemplates();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Fatura Tanımla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Geri Dön'),
          ),
        ],
      ),
    );
  }
}
