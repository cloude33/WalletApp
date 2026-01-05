import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/wallet.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/credit_card_transaction.dart';
import '../services/data_service.dart';
import '../services/smart_category_service.dart';
import '../services/credit_card_service.dart';
import '../utils/image_helper.dart';
import '../utils/error_handler.dart';
import '../utils/transaction_form_validator.dart';
import '../utils/app_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AddTransactionScreen extends StatefulWidget {
  final List<Wallet> wallets;
  final List<Category>? categories;
  final String? defaultType;

  const AddTransactionScreen({
    super.key,
    required this.wallets,
    this.categories,
    this.defaultType,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final DataService _dataService = DataService();
  final SmartCategoryService _smartService = SmartCategoryService();
  final CreditCardService _creditCardService = CreditCardService();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  late String _selectedWalletId;
  String? _selectedImage;
  bool _isIncome = false;
  CategorySuggestion? _suggestion;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedDate = DateTime.now();
    if (widget.defaultType == 'income') {
      _isIncome = true;
    } else if (widget.defaultType == 'expense') {
      _isIncome = false;
    }
    if (widget.categories != null && widget.categories!.isNotEmpty) {
      final incomeCategories = widget.categories!
          .where((c) => c.type == 'income')
          .toList();
      final expenseCategories = widget.categories!
          .where((c) => c.type == 'expense')
          .toList();
      final uniqueIncomeCategories = <String, Category>{};
      for (final cat in incomeCategories) {
        uniqueIncomeCategories[cat.name] = cat;
      }
      final uniqueExpenseCategories = <String, Category>{};
      for (final cat in expenseCategories) {
        uniqueExpenseCategories[cat.name] = cat;
      }

      final deduplicatedIncomeCategories = uniqueIncomeCategories.values
          .toList();
      final deduplicatedExpenseCategories = uniqueExpenseCategories.values
          .toList();

      if (_isIncome && deduplicatedIncomeCategories.isNotEmpty) {
        _selectedCategory = deduplicatedIncomeCategories.first.name;
      } else if (!_isIncome && deduplicatedExpenseCategories.isNotEmpty) {
        _selectedCategory = deduplicatedExpenseCategories.first.name;
      } else {
        final uniqueAllCategories = <String, Category>{};
        for (final cat in widget.categories!) {
          uniqueAllCategories[cat.name] = cat;
        }
        final deduplicatedAllCategories = uniqueAllCategories.values.toList();
        _selectedCategory = deduplicatedAllCategories.isNotEmpty
            ? deduplicatedAllCategories.first.name
            : '';
      }
    } else {
      _selectedCategory = '';
    }
    _selectedWalletId = widget.wallets.isNotEmpty
        ? widget.wallets.first.id
        : '';
    if (widget.categories == null) {
      _loadCategories();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = (await _dataService.getCategories()).cast<Category>();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _cleanWalletName(String name) {
    String cleaned = name;
    if (cleaned.contains('(Kesim: ')) {
      final start = cleaned.indexOf('(Kesim: ');
      final end = cleaned.indexOf(')', start);
      if (end > start) {
        cleaned =
            cleaned.substring(0, start).trim() +
            cleaned.substring(end + 1).trim();
      }
    }
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

    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');

    return '${date.day} ${months[date.month - 1]} ${date.year} $hours:$minutes';
  }

  Future<void> _saveTransaction() async {
    final error = TransactionFormValidator.validate(
      amountText: _amountController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      walletId: _selectedWalletId,
      selectedType: _isIncome ? 'income' : 'expense',
      isInstallment: false,
      installmentCount: 1,
      isCreditCardWallet: false,
    );
    if (error != null) {
      ErrorHandler.showError(context, error);
      return;
    }

    try {
      final cleanAmountText = _amountController.text
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final totalAmount = double.parse(cleanAmountText);

      // Check if this is a credit card transaction
      if (_selectedWalletId.startsWith('cc_')) {
        // This is a credit card transaction
        final cardId = _selectedWalletId.substring(3); // Remove 'cc_' prefix

        final creditCardTransaction = CreditCardTransaction(
          id: const Uuid().v4(),
          cardId: cardId,
          amount: totalAmount,
          description: _descriptionController.text,
          transactionDate: _selectedDate,
          category: _selectedCategory,
          installmentCount: 1,
          installmentsPaid: 0,
          createdAt: DateTime.now(),
          images: _selectedImage != null ? [_selectedImage!] : null,
        );

        await _creditCardService.addTransaction(creditCardTransaction);

        if (mounted) {
          Navigator.pop(context, true);
          ErrorHandler.showSuccess(
            context,
            'Kredi kartı işlemi başarıyla eklendi',
          );
        }
      } else {
        // Regular wallet transaction
        final transaction = Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: _isIncome ? 'income' : 'expense',
          amount: totalAmount,
          description: _descriptionController.text,
          category: _selectedCategory,
          walletId: _selectedWalletId,
          date: _selectedDate,
          memo: null,
          images: _selectedImage != null ? [_selectedImage!] : null,
        );

        await _dataService.addTransaction(transaction);
        final wallets = await _dataService.getWallets();
        final walletIndex = wallets.indexWhere(
          (w) => w.id == _selectedWalletId,
        );
        if (walletIndex != -1) {
          final wallet = wallets[walletIndex];
          final newBalance = _isIncome
              ? wallet.balance + transaction.amount
              : wallet.balance - transaction.amount;

          wallets[walletIndex] = Wallet(
            id: wallet.id,
            name: wallet.name,
            balance: newBalance,
            type: wallet.type,
            color: wallet.color,
            icon: wallet.icon,
            cutOffDay: wallet.cutOffDay,
            paymentDay: wallet.paymentDay,
            installment: wallet.installment,
            creditLimit: wallet.creditLimit,
          );
          await _dataService.saveWallets(wallets);
        }

        if (mounted) {
          Navigator.pop(context, true);
          ErrorHandler.showSuccess(context, 'İşlem başarıyla eklendi');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.wallets.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF5E5CE6,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: FaIcon(
                            AppIcons.wallet,
                            size: 64,
                            color: Color(0xFF5E5CE6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Cüzdan Bulunamadı',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'İşlem eklemek için önce bir cüzdan oluşturmalısınız',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: FaIcon(FontAwesomeIcons.arrowLeft, size: 16),
                          label: const Text('Ana Sayfaya Dön'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                      _buildImageSection(),
                      const SizedBox(height: 20),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          ),
          Text(
            _isIncome ? 'Gelir' : 'Gider',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: _saveTransaction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'KAYDET',
              style: TextStyle(
                color: Color(0xFF5E5CE6),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
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
            border: OutlineInputBorder(borderRadius: BorderRadius.zero),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF5E5CE6))),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (value) {
            if (value.isEmpty) return;
            String cleanValue = value.replaceAll('.', '');
            cleanValue = cleanValue.replaceAll(RegExp(r'[^0-9,]'), '');
            int firstCommaIndex = cleanValue.indexOf(',');
            if (firstCommaIndex != -1) {
              String integerPart = cleanValue.substring(0, firstCommaIndex);
              String decimalPart = cleanValue
                  .substring(firstCommaIndex + 1)
                  .replaceAll(',', '');
              cleanValue = '$integerPart,$decimalPart';
            }
            final parts = cleanValue.split(',');
            String formattedValue;

            if (parts.length > 1) {
              final integerPart = parts[0];
              String decimalPart = parts[1];
              if (decimalPart.length > 2) {
                decimalPart = decimalPart.substring(0, 2);
              }
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
          onTap: () {
            if (_amountController.text == '0' ||
                _amountController.text == '0,00') {
              _amountController.clear();
            }
          },
        ),
      ],
    );
  }

  Future<void> _onDescriptionChanged(String value) async {
    if (value.length > 3) {
      final suggestion = await _smartService.suggestCategory(
        value,
        _isIncome ? 'income' : 'expense',
      );
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
            hintText: 'Örn: Market alışverişi',
            border: OutlineInputBorder(borderRadius: BorderRadius.zero),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF5E5CE6))),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: _suggestion != null
                ? IconButton(
                    icon: FaIcon(FontAwesomeIcons.lightbulb, color: Colors.amber, size: 16),
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
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber, width: 1.5),
            ),
            child: Row(
              children: [
                FaIcon(FontAwesomeIcons.lightbulb, color: Colors.amber, size: 20),
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
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _applySuggestion,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.amber[800],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
    final allCategories = widget.categories ?? _categories;
    final filteredCategories = allCategories
        .where((c) => c.type == (_isIncome ? 'income' : 'expense'))
        .toList();
    final uniqueCategories = <String, Category>{};
    for (final cat in filteredCategories) {
      uniqueCategories[cat.name] = cat;
    }
    final deduplicatedCategories = uniqueCategories.values.toList();
    if (deduplicatedCategories.isNotEmpty &&
        (widget.categories != null || _categories.isNotEmpty) &&
        !_isValidCategory(_selectedCategory, deduplicatedCategories)) {
      _selectedCategory = deduplicatedCategories.first.name;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.zero,
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: deduplicatedCategories.isNotEmpty
                  ? _selectedCategory
                  : null,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              items: deduplicatedCategories
                  .map(
                    (cat) => DropdownMenuItem(
                      value: cat!.name,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cat!.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(cat!.icon, color: cat!.color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(cat!.name, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
              selectedItemBuilder: (context) {
                return deduplicatedCategories.map<Widget>((cat) {
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cat!.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(cat!.icon, color: cat!.color, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(cat!.name, style: const TextStyle(fontSize: 16)),
                    ],
                  );
                }).toList();
              },
              hint: const Text('Bir kategori seçin'),
            ),
          ),
        ),
      ],
    );
  }

  bool _isValidCategory(String categoryName, List<Category> categories) {
    if (categoryName.isEmpty) return false;
    return categories.any((category) => category.name == categoryName);
  }

  Widget _buildWalletField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cüzdan', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedWalletId,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.zero),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF5E5CE6))),
            filled: true,
            fillColor: Colors.white,
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
              _selectedWalletId = value ?? '';
            });
          },
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
        if (_selectedImage == null)
          GestureDetector(
            onTap: () async {
              final imagePath = await ImageHelper.showImageSourceDialog(
                context,
              );
              if (imagePath != null) {
                setState(() {
                  _selectedImage = imagePath;
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.zero,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  FaIcon(
                    AppIcons.camera,
                    size: 48,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Fiş fotoğrafı ekle',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontSize: 14,
                    ),
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
                  itemCount: 1,
                  itemBuilder: (context, index) {
                    return _buildImagePreview(_selectedImage!, index);
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
                        _selectedImage = imagePath;
                      });
                    }
                  },
                  icon: FaIcon(AppIcons.camera, size: 16),
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
            borderRadius: BorderRadius.zero,
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
                  _selectedImage = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(FontAwesomeIcons.xmark, color: Colors.white, size: 14),
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
                                initialDateTime:
                                    _selectedDate.isAfter(DateTime.now())
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
                                initialDateTime:
                                    _selectedDate.isAfter(DateTime.now())
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
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.zero,
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDateTurkish(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
                FaIcon(AppIcons.calendar, color: Color(0xFF5E5CE6), size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
