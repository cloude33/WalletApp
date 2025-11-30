import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/credit_card.dart';
import '../models/credit_card_transaction.dart';
import '../services/credit_card_service.dart';

class AddCreditCardTransactionScreen extends StatefulWidget {
  final CreditCard card;

  const AddCreditCardTransactionScreen({super.key, required this.card});

  @override
  State<AddCreditCardTransactionScreen> createState() =>
      _AddCreditCardTransactionScreenState();
}

class _AddCreditCardTransactionScreenState
    extends State<AddCreditCardTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final CreditCardService _cardService = CreditCardService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  // Form controllers
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _installmentCountController;

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Market';
  bool _isLoading = false;
  double _availableCredit = 0;
  double _installmentAmount = 0;

  // Common categories
  final List<String> _categories = [
    'Market',
    'Restoran',
    'Giyim',
    'Elektronik',
    'Sağlık',
    'Ulaşım',
    'Eğlence',
    'Faturalar',
    'Yakıt',
    'Seyahat',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _installmentCountController = TextEditingController(text: '1');

    _amountController.addListener(_calculateInstallmentAmount);
    _installmentCountController.addListener(_calculateInstallmentAmount);

    _loadAvailableCredit();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _installmentCountController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableCredit() async {
    try {
      final available = await _cardService.getAvailableCredit(widget.card.id);
      setState(() {
        _availableCredit = available;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _calculateInstallmentAmount() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final installments = int.tryParse(_installmentCountController.text) ?? 1;

    if (amount > 0 && installments > 0) {
      setState(() {
        _installmentAmount = amount / installments;
      });
    } else {
      setState(() {
        _installmentAmount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşlem Ekle'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCardInfo(),
                  const SizedBox(height: 24),
                  _buildAmountField(),
                  const SizedBox(height: 16),
                  _buildDescriptionField(),
                  const SizedBox(height: 16),
                  _buildDateField(),
                  const SizedBox(height: 16),
                  _buildCategoryField(),
                  const SizedBox(height: 16),
                  _buildInstallmentCountField(),
                  if (_installmentAmount > 0) ...[
                    const SizedBox(height: 16),
                    _buildInstallmentInfo(),
                  ],
                  const SizedBox(height: 24),
                  _buildAvailableCreditWarning(),
                  const SizedBox(height: 16),
                  _buildSaveButton(),
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
                  const SizedBox(height: 4),
                  Text(
                    'Kullanılabilir: ${_currencyFormat.format(_availableCredit)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(
        labelText: 'Tutar',
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
          return 'Tutar gerekli';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Geçerli bir tutar giriniz';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Açıklama',
        hintText: 'Örn: Market alışverişi',
        prefixIcon: Icon(Icons.description),
        border: OutlineInputBorder(),
      ),
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Açıklama gerekli';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'İşlem Tarihi',
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

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Kategori',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCategory = value;
          });
        }
      },
    );
  }

  Widget _buildInstallmentCountField() {
    return TextFormField(
      controller: _installmentCountController,
      decoration: const InputDecoration(
        labelText: 'Taksit Sayısı',
        hintText: '1-36 arası',
        helperText: '1 = Peşin, 2+ = Taksitli',
        prefixIcon: Icon(Icons.schedule),
        suffixText: 'taksit',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Taksit sayısı gerekli';
        }
        final count = int.tryParse(value);
        if (count == null || count < 1 || count > 36) {
          return '1-36 arası bir değer giriniz';
        }
        return null;
      },
    );
  }

  Widget _buildInstallmentInfo() {
    final installmentCount = int.tryParse(_installmentCountController.text) ?? 1;
    final isInstallment = installmentCount > 1;

    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  isInstallment ? 'Taksit Bilgisi' : 'Peşin Ödeme',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isInstallment) ...[
              Text(
                'Aylık Taksit: ${_currencyFormat.format(_installmentAmount)}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                '$installmentCount ay boyunca her ekstre döneminde ${_currencyFormat.format(_installmentAmount)} ödenecek',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ] else ...[
              Text(
                'Bu işlem peşin olarak kaydedilecek',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableCreditWarning() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    
    if (amount > _availableCredit) {
      return Card(
        color: Colors.red.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Limit Aşımı Uyarısı',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bu işlem kullanılabilir limitinizi (${_currencyFormat.format(_availableCredit)}) aşıyor!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[700],
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

    return const SizedBox.shrink();
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveTransaction,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'Kaydet',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(_amountController.text);
    
    // Show confirmation if exceeding limit
    if (amount > _availableCredit) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Limit Aşımı'),
          content: Text(
            'Bu işlem kullanılabilir limitinizi aşıyor. Devam etmek istiyor musunuz?\n\nKullanılabilir: ${_currencyFormat.format(_availableCredit)}\nİşlem: ${_currencyFormat.format(amount)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Devam Et'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final transaction = CreditCardTransaction(
        id: const Uuid().v4(),
        cardId: widget.card.id,
        amount: amount,
        description: _descriptionController.text.trim(),
        transactionDate: _selectedDate,
        category: _selectedCategory,
        installmentCount: int.parse(_installmentCountController.text),
        installmentsPaid: 0,
        createdAt: DateTime.now(),
      );

      await _cardService.addTransaction(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İşlem başarıyla eklendi'),
            backgroundColor: Colors.green,
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
