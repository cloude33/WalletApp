import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/credit_card.dart';
import '../models/credit_card_statement.dart';
import '../models/credit_card_payment.dart';
import '../services/credit_card_service.dart';
import '../repositories/credit_card_statement_repository.dart';

class MakeCreditCardPaymentScreen extends StatefulWidget {
  final CreditCard card;

  const MakeCreditCardPaymentScreen({super.key, required this.card});

  @override
  State<MakeCreditCardPaymentScreen> createState() =>
      _MakeCreditCardPaymentScreenState();
}

class _MakeCreditCardPaymentScreenState
    extends State<MakeCreditCardPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final CreditCardService _cardService = CreditCardService();
  final CreditCardStatementRepository _statementRepo =
      CreditCardStatementRepository();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  late TextEditingController _amountController;
  late TextEditingController _noteController;

  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentMethod = 'bank_transfer';
  bool _isLoading = true;
  CreditCardStatement? _currentStatement;
  double _remainingDebtAfterPayment = 0;

  final Map<String, String> _paymentMethods = {
    'bank_transfer': 'Banka Havalesi',
    'atm': 'ATM',
    'auto_payment': 'Otomatik Ödeme',
    'other': 'Diğer',
  };

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _amountController.addListener(_calculateRemainingDebt);
    _loadCurrentStatement();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentStatement() async {
    setState(() => _isLoading = true);

    try {
      final statement = await _statementRepo.findCurrentStatement(widget.card.id);
      
      setState(() {
        _currentStatement = statement;
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

  void _calculateRemainingDebt() {
    if (_currentStatement == null) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    final remaining = _currentStatement!.remainingDebt - amount;

    setState(() {
      _remainingDebtAfterPayment = remaining > 0 ? remaining : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Yap'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentStatement == null
              ? _buildNoStatementView()
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildCardInfo(),
                      const SizedBox(height: 16),
                      _buildStatementInfo(),
                      const SizedBox(height: 24),
                      _buildAmountField(),
                      const SizedBox(height: 16),
                      _buildQuickAmountButtons(),
                      const SizedBox(height: 16),
                      _buildDateField(),
                      const SizedBox(height: 16),
                      _buildPaymentMethodField(),
                      const SizedBox(height: 16),
                      _buildNoteField(),
                      const SizedBox(height: 24),
                      _buildPaymentSummary(),
                      const SizedBox(height: 16),
                      _buildSaveButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNoStatementView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Ödeme Yapılacak Ekstre Yok',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu kart için henüz ödeme yapılacak bir ekstre bulunmuyor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardInfo() {
    return Card(
      color: widget.card.color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.credit_card,
              color: widget.card.color,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.card.bankName} ${widget.card.cardName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '•••• ${widget.card.last4Digits}',
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

  Widget _buildStatementInfo() {
    if (_currentStatement == null) return const SizedBox.shrink();

    final statement = _currentStatement!;
    final daysUntilDue = statement.daysUntilDue;
    final isOverdue = statement.isOverdue;

    Color statusColor = Colors.orange;
    String statusText = 'Bekliyor';
    
    if (isOverdue) {
      statusColor = Colors.red;
      statusText = 'Gecikmiş (${statement.daysOverdue} gün)';
    } else if (daysUntilDue <= 3) {
      statusColor = Colors.red;
      statusText = '$daysUntilDue gün kaldı';
    } else if (daysUntilDue <= 7) {
      statusColor = Colors.orange;
      statusText = '$daysUntilDue gün kaldı';
    } else {
      statusColor = Colors.green;
      statusText = '$daysUntilDue gün kaldı';
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
                  'Ekstre Bilgileri',
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
                    color: statusColor.withOpacity(0.1),
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
            _buildInfoRow(
              'Toplam Borç',
              _currencyFormat.format(statement.totalDebt),
              Colors.red,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Asgari Ödeme',
              _currencyFormat.format(statement.minimumPayment),
              Colors.orange,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Kalan Borç',
              _currencyFormat.format(statement.remainingDebt),
              Colors.blue,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Son Ödeme Tarihi',
              DateFormat('dd MMMM yyyy', 'tr_TR').format(statement.dueDate),
              Colors.grey[700]!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(
        labelText: 'Ödeme Tutarı',
        hintText: '0.00',
        prefixIcon: Icon(Icons.attach_money),
        suffixText: '₺',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ödeme tutarı gerekli';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Geçerli bir tutar giriniz';
        }
        return null;
      },
    );
  }

  Widget _buildQuickAmountButtons() {
    if (_currentStatement == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _amountController.text =
                  _currentStatement!.minimumPayment.toStringAsFixed(2);
              _calculateRemainingDebt();
            },
            child: const Text('Asgari'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _amountController.text =
                  _currentStatement!.remainingDebt.toStringAsFixed(2);
              _calculateRemainingDebt();
            },
            child: const Text('Tam Ödeme'),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Ödeme Tarihi',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        child: Text(
          DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodField() {
    return DropdownButtonFormField<String>(
      value: _selectedPaymentMethod,
      decoration: const InputDecoration(
        labelText: 'Ödeme Yöntemi',
        prefixIcon: Icon(Icons.payment),
        border: OutlineInputBorder(),
      ),
      items: _paymentMethods.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedPaymentMethod = value;
          });
        }
      },
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      decoration: const InputDecoration(
        labelText: 'Not (Opsiyonel)',
        hintText: 'Ödeme ile ilgili not',
        prefixIcon: Icon(Icons.note),
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildPaymentSummary() {
    if (_currentStatement == null) return const SizedBox.shrink();

    final amount = double.tryParse(_amountController.text) ?? 0;
    final isOverpayment = amount > _currentStatement!.remainingDebt;

    return Card(
      color: isOverpayment
          ? Colors.orange.withOpacity(0.1)
          : Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOverpayment ? Icons.warning : Icons.info_outline,
                  color: isOverpayment ? Colors.orange : Colors.blue,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ödeme Özeti',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (amount > 0) ...[
              _buildInfoRow(
                'Ödeme Sonrası Kalan',
                _currencyFormat.format(_remainingDebtAfterPayment),
                _remainingDebtAfterPayment > 0 ? Colors.orange : Colors.green,
              ),
              if (isOverpayment) ...[
                const SizedBox(height: 8),
                Text(
                  'Fazla ödeme bir sonraki ekstreye avans olarak aktarılacak',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _savePayment,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'Ödemeyi Kaydet',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('tr', 'TR'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentStatement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ekstre bulunamadı')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payment = CreditCardPayment(
        id: const Uuid().v4(),
        cardId: widget.card.id,
        statementId: _currentStatement!.id,
        amount: double.parse(_amountController.text),
        paymentDate: _selectedDate,
        paymentMethod: _selectedPaymentMethod,
        note: _noteController.text.trim(),
        createdAt: DateTime.now(),
      );

      final result = await _cardService.recordPayment(payment);
      final hasOverpayment = result['hasOverpayment'] as bool;

      if (mounted) {
        String message = 'Ödeme başarıyla kaydedildi';
        if (hasOverpayment) {
          final overpayment = result['overpayment'] as double;
          message += '\n\nFazla ödeme: ${_currencyFormat.format(overpayment)}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
