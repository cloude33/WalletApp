import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import '../models/wallet.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/data_service.dart';
import '../services/smart_category_service.dart';
import '../utils/image_helper.dart';
import '../utils/error_handler.dart';
import '../utils/transaction_form_validator.dart';

class EditTransactionScreen extends StatefulWidget {
  final Transaction transaction;
  final List<Wallet> wallets;

  const EditTransactionScreen({
    super.key,
    required this.transaction,
    required this.wallets,
  });

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final DataService _dataService = DataService();
  final SmartCategoryService _smartService = SmartCategoryService();
  late String _selectedType;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  late String? _selectedCategory;
  late String? _selectedWalletId;
  final List<String> _images = [];
  bool _isInstallment = false;
  late int _installmentCount;
  late DateTime _selectedDate;
  CategorySuggestion? _suggestion;

  // Türkçe tarih formatı
  String _formatDateTurkish(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Wallet name'den kesim ve ödeme tarihi bilgilerini temizle
  String _cleanWalletName(String name) {
    String cleaned = name;

    // Kesim tarihi bilgisini kaldır
    if (cleaned.contains('(Kesim: ')) {
      final start = cleaned.indexOf('(Kesim: ');
      final end = cleaned.indexOf(')', start);
      if (end > start) {
        cleaned =
            cleaned.substring(0, start).trim() +
            cleaned.substring(end + 1).trim();
      }
    }

    // Son ödeme tarihi bilgisini kaldır
    if (cleaned.contains('(Son Ödeme: ')) {
      final start = cleaned.indexOf('(Son Ödeme: ');
      final end = cleaned.indexOf(')', start);
      if (end > start) {
        cleaned =
            cleaned.substring(0, start).trim() +
            cleaned.substring(end + 1).trim();
      }
    }

    return cleaned.trim();
  }

  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.transaction.type;
    _amountController.text = NumberFormat(
      '#,##0.00',
      'tr_TR',
    ).format(widget.transaction.amount);
    _descriptionController.text = widget.transaction.description;
    _selectedCategory = widget.transaction.category;
    _selectedWalletId = widget.transaction.walletId;
    _selectedDate = widget.transaction.date;

    if (widget.transaction.memo != null) {
      _memoController.text = widget.transaction.memo!;
    }

    if (widget.transaction.images != null) {
      _images.addAll(widget.transaction.images!);
    }

    _isInstallment =
        widget.transaction.installments != null &&
        widget.transaction.installments! > 1;
    _installmentCount = widget.transaction.installments ?? 1;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _dataService.getCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        _updateCategoryForType();
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _updateCategoryForType() {
    final categories = _categories
        .where((c) => c.type == _selectedType)
        .toList();
    if (categories.isNotEmpty &&
        !categories.any((c) => c.name == _selectedCategory)) {
      _selectedCategory = categories.first.name;
    }
  }

  Future<void> _updateTransaction() async {
    // Determine if selected wallet is a credit card
    bool isCreditCardWallet = false;
    if (_selectedWalletId != null) {
      final wallet = widget.wallets.firstWhere(
        (w) => w.id == _selectedWalletId,
        orElse: () => widget.wallets.isNotEmpty ? widget.wallets.first : Wallet(id: '', name: '', balance: 0, type: 'cash', color: '0xFF5E5CE6', icon: 'wallet'),
      );
      isCreditCardWallet = wallet.type == 'credit_card';
    }

    final error = TransactionFormValidator.validate(
      amountText: _amountController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      walletId: _selectedWalletId,
      selectedType: _selectedType,
      isInstallment: _isInstallment,
      installmentCount: _installmentCount,
      isCreditCardWallet: isCreditCardWallet,
    );
    if (error != null) {
      ErrorHandler.showError(context, error);
      return;
    }

    try {
      // Parse the amount by removing formatting characters
      final cleanAmountText = _amountController.text
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final totalAmount = double.parse(cleanAmountText);

      // Create updated transaction
      final updatedTransaction = Transaction(
        id: widget.transaction.id,
        type: _selectedType,
        amount: totalAmount,
        description: _descriptionController.text,
        category: _selectedCategory ?? '',
        walletId: _selectedWalletId ?? '',
        date: _selectedDate,
        memo: _memoController.text.isEmpty ? null : _memoController.text,
        images: _images.isEmpty ? null : _images,
        installments: _isInstallment ? _installmentCount : null,
        currentInstallment: _isInstallment
            ? (widget.transaction.currentInstallment ?? 1)
            : null,
        parentTransactionId: widget.transaction.parentTransactionId,
      );

      // Get original transaction for balance adjustment
      final transactions = await _dataService.getTransactions();
      final originalTransaction = transactions.firstWhere(
        (t) => t.id == widget.transaction.id,
        orElse: () => widget.transaction,
      );

      await _dataService.updateTransaction(
        originalTransaction,
        updatedTransaction,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ErrorHandler.showSuccess(context, 'İşlem başarıyla güncellendi');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'İşlem güncellenirken hata oluştu: $e');
      }
    }
  }

  Future<void> _deleteTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İşlemi Sil'),
        content: const Text('Bu işlemi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dataService.deleteTransaction(widget.transaction.id);
        if (mounted) {
          Navigator.pop(context, true);
          ErrorHandler.showSuccess(context, 'İşlem başarıyla silindi');
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showError(context, 'İşlem silinirken hata oluştu: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAmountField(),
                      const SizedBox(height: 20),
                      _buildDescriptionField(),
                      const SizedBox(height: 20),
                      _buildCategoryField(),
                      const SizedBox(height: 20),
                      _buildWalletField(),
                      const SizedBox(height: 20),
                      _buildDateField(),
                      const SizedBox(height: 20),
                      _buildMemoField(),
                      const SizedBox(height: 20),
                      _buildImageSection(),
                      const SizedBox(height: 20),
                      _buildDeleteButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                _selectedType == 'income'
                    ? 'Gelir Düzenle'
                    : _selectedType == 'expense'
                    ? 'Gider Düzenle'
                    : 'Transfer Düzenle',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _updateTransaction,
                child: const Text(
                  'KAYDET',
                  style: TextStyle(
                    color: Color(0xFF5E5CE6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildTypeButton('Gelir', 'income'),
              _buildTypeButton('Gider', 'expense'),
              _buildTypeButton('Transfer', 'transfer'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, String type) {
    bool isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _updateCategoryForType();
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.red : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tutar', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '0,00',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: (value) {
            if (value.isEmpty) return;

            // Remove all dots (thousands separators) first
            String cleanValue = value.replaceAll('.', '');
            // Keep only digits and comma
            cleanValue = cleanValue.replaceAll(RegExp(r'[^0-9,]'), '');

            // Prevent multiple commas
            int firstCommaIndex = cleanValue.indexOf(',');
            if (firstCommaIndex != -1) {
              String integerPart = cleanValue.substring(0, firstCommaIndex);
              String decimalPart = cleanValue
                  .substring(firstCommaIndex + 1)
                  .replaceAll(',', '');
              cleanValue = '$integerPart,$decimalPart';
            }

            // Handle decimal separator
            final parts = cleanValue.split(',');
            String formattedValue;

            if (parts.length > 1) {
              final integerPart = parts[0];
              // Değişiklik: Ondalık kısmı olduğu gibi bırak
              final decimalPart = parts[1];

              // Handle empty integer part (e.g. ",50")
              final parsedInteger = integerPart.isEmpty
                  ? 0
                  : (int.tryParse(integerPart) ?? 0);
              final formattedInteger = NumberFormat(
                '#,##0',
                'tr_TR',
              ).format(parsedInteger);

              formattedValue = '$formattedInteger,$decimalPart';
            } else {
              final numericValue = int.tryParse(cleanValue) ?? 0;
              formattedValue = NumberFormat(
                '#,##0',
                'tr_TR',
              ).format(numericValue);
            }

            if (value != formattedValue) {
              _amountController.value = TextEditingValue(
                text: formattedValue,
                selection: TextSelection.collapsed(
                  offset: formattedValue.length,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Future<void> _onDescriptionChanged(String value) async {
    if (value.length > 3) {
      final suggestion = await _smartService.suggestCategory(value, _selectedType);
      if (mounted) {
        setState(() {
          _suggestion = suggestion;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _suggestion = null;
        });
      }
    }
  }

  void _applySuggestion() {
    if (_suggestion != null) {
      setState(() {
        _selectedCategory = _suggestion!.category;
        _suggestion = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kategori önerisi uygulandı: ${_suggestion!.category}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Açıklama', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          onChanged: _onDescriptionChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixIcon: _suggestion != null
                ? IconButton(
                    icon: const Icon(Icons.lightbulb, color: Colors.amber),
                    onPressed: _applySuggestion,
                    tooltip: 'Öneriyi uygula',
                  )
                : null,
          ),
        ),
        if (_suggestion != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Önerilen: ${_suggestion!.category}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${_suggestion!.reason} • %${(_suggestion!.confidence * 100).toInt()} güven',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _applySuggestion,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.amber[800],
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Uygula'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryField() {
    final filteredCategories = _categories
        .where((c) => c.type == _selectedType)
        .toList();

    // Make sure selected category is valid for current type
    if (_selectedCategory != null &&
        !filteredCategories.any((c) => c.name == _selectedCategory)) {
      if (filteredCategories.isNotEmpty) {
        _selectedCategory = filteredCategories.first.name;
      } else {
        _selectedCategory = null;
      }
    }

    if (filteredCategories.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // Updated to use a more iOS-like selection interface
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              items: filteredCategories
                  .map(
                    (cat) => DropdownMenuItem(
                      value: cat.name,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cat.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(cat.icon, color: cat.color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(cat.name, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
              selectedItemBuilder: (context) {
                return filteredCategories.map<Widget>((cat) {
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cat.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(cat.icon, color: cat.color, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(cat.name, style: const TextStyle(fontSize: 16)),
                    ],
                  );
                }).toList();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cüzdan', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedWalletId,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: widget.wallets
              .map(
                (wallet) => DropdownMenuItem(
                  value: wallet.id,
                  child: Text(
                    '${_cleanWalletName(wallet.name)} • ${NumberFormat('#,##0', 'tr_TR').format(wallet.balance)}',
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedWalletId = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMemoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Not', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _memoController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fotoğraflar',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        if (_images.isEmpty)
          GestureDetector(
            onTap: () async {
              final imagePath = await ImageHelper.showImageSourceDialog(
                context,
              );
              if (imagePath != null) {
                setState(() {
                  _images.add(imagePath);
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Fiş fotoğrafı ekle',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return _buildImagePreview(_images[index], index);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final imagePath = await ImageHelper.showImageSourceDialog(
                      context,
                    );
                    if (imagePath != null) {
                      setState(() {
                        _images.add(imagePath);
                      });
                    }
                  },
                  icon: const Icon(Icons.camera_alt, size: 20),
                  label: const Text('Ekle'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF5E5CE6),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildImagePreview(String imagePath, int index) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              base64Decode(imagePath),
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey.shade300,
                  child: const Icon(
                    Icons.broken_image,
                    size: 40,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _images.removeAt(index);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tarih',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return Container(
                  height: 300,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
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
                              'Tarih Seç',
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
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.date,
                          initialDateTime: _selectedDate,
                          minimumDate: DateTime(2020),
                          maximumDate: DateTime.now(),
                          onDateTimeChanged: (DateTime newDate) {
                            setState(() {
                              _selectedDate = newDate;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDateTurkish(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.calendar_today, color: Color(0xFF5E5CE6)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _deleteTransaction,
        icon: const Icon(Icons.delete_outline),
        label: const Text('İşlemi Sil'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFF3B30),
          side: const BorderSide(color: Color(0xFFFF3B30)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
