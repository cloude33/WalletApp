import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../models/credit_card.dart';
import '../models/credit_card_transaction.dart';
import '../services/credit_card_service.dart';
import '../utils/image_helper.dart';

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
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _installmentCountController;

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Market';
  bool _isLoading = false;
  double _availableCredit = 0;
  double _installmentAmount = 0;
  final List<String> _images = [];
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
      debugPrint('Error loading available credit: $e');
    }
  }

  void _calculateInstallmentAmount() {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
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
      appBar: AppBar(title: const Text('İşlem Ekle')),
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
                  _buildImageSection(),
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
      color: widget.card.color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.credit_card, color: widget.card.color, size: 32),
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
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        TextInputFormatter.withFunction((oldValue, newValue) {
          // Sadece bir nokta olmasını sağla
          if (newValue.text.split('.').length > 2) {
            return oldValue;
          }
          // Noktadan sonra en fazla 2 basamak olmasını sağla
          if (newValue.text.contains('.')) {
            final parts = newValue.text.split('.');
            if (parts.length == 2 && parts[1].length > 2) {
              return TextEditingValue(
                text: '${parts[0]}.${parts[1].substring(0, 2)}',
                selection: TextSelection.collapsed(
                  offset: '${parts[0]}.${parts[1].substring(0, 2)}'.length,
                ),
              );
            }
          }
          return newValue;
        }),
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
          labelText: 'İşlem Tarihi ve Saati',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        child: Text(
          _formatDateWithTime(_selectedDate),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Kategori',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem(value: category, child: Text(category));
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
    final installmentCount =
        int.tryParse(_installmentCountController.text) ?? 1;
    final isInstallment = installmentCount > 1;

    return Card(
      color: Colors.blue.withValues(alpha: 0.1),
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
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ] else ...[
              Text(
                'Bu işlem peşin olarak kaydedilecek',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableCreditWarning() {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;

    if (amount > _availableCredit) {
      return Card(
        color: Colors.red.withValues(alpha: 0.1),
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
                      style: TextStyle(fontSize: 14, color: Colors.red[700]),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('Kaydet', style: TextStyle(fontSize: 16)),
    );
  }

  String _formatDateWithTime(DateTime date) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');

    return '${date.day} ${months[date.month - 1]} ${date.year} $hours:$minutes';
  }

  Future<void> _selectDate() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 400,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'İptal',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const Text(
                      'Tarih ve Saat Seç',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Tamam',
                        style: TextStyle(
                          color: Color(0xFF5E5CE6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: _selectedDate.isAfter(DateTime.now())
                            ? DateTime.now()
                            : _selectedDate,
                        minimumDate: DateTime(2020),
                        maximumDate: DateTime.now(),
                        onDateTimeChanged: (DateTime newDate) {
                          setState(() {
                            _selectedDate = DateTime(
                              newDate.year,
                              newDate.month,
                              newDate.day,
                              _selectedDate.hour,
                              _selectedDate.minute,
                            );
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      height: 100,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: _selectedDate.isAfter(DateTime.now())
                            ? DateTime.now()
                            : _selectedDate,
                        use24hFormat: true,
                        onDateTimeChanged: (DateTime newTime) {
                          setState(() {
                            _selectedDate = DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              _selectedDate.day,
                              newTime.hour,
                              newTime.minute,
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(_amountController.text.replaceAll(',', '.'));
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
        images: _images,
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
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fiş/Fatura Ekle (Opsiyonel)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_images.isEmpty)
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Fiş Ekle'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          )
        else
          Column(
            children: [
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _images.length) {
                      return GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate,
                            size: 40,
                          ),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: MemoryImage(base64Decode(_images[index])),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final base64Image = await ImageHelper.pickImage(
        source: ImageSource.gallery,
      );
      if (base64Image != null) {
        setState(() {
          _images.add(base64Image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resim eklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }
}
