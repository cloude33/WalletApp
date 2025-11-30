import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:convert';
import '../models/wallet.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/credit_card.dart';
import '../models/credit_card_transaction.dart';
import '../services/data_service.dart';
import '../services/smart_category_service.dart';
import '../services/credit_card_service.dart';
import '../utils/image_helper.dart';
import '../utils/error_handler.dart';
import '../utils/transaction_form_validator.dart';

class AddTransactionScreen extends StatefulWidget {
  final List<Wallet> wallets;
  final String? defaultType;

  const AddTransactionScreen({super.key, required this.wallets, this.defaultType});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final DataService _dataService = DataService();
  final SmartCategoryService _smartService = SmartCategoryService();
  final CreditCardService _creditCardService = CreditCardService();
  String _selectedType = 'expense';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  String? _selectedCategory;
  String? _selectedWalletId;
  final List<String> _images = [];
  bool _isInstallment = false;
  int _installmentCount = 2; // Default to 2 as 1 is single payment
  DateTime _selectedDate = DateTime.now();
  CategorySuggestion? _suggestion;

  // Türkçe tarih formatı
  String _formatDateTurkish(DateTime date) {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
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
        cleaned = cleaned.substring(0, start).trim() + cleaned.substring(end + 1).trim();
      }
    }
    
    // Son ödeme tarihi bilgisini kaldır
    if (cleaned.contains('(Son Ödeme: ')) {
      final start = cleaned.indexOf('(Son Ödeme: ');
      final end = cleaned.indexOf(')', start);
      if (end > start) {
        cleaned = cleaned.substring(0, start).trim() + cleaned.substring(end + 1).trim();
      }
    }
    
    return cleaned.trim();
  }


  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    if (widget.wallets.isNotEmpty) {
      _selectedWalletId = widget.wallets.first.id;
    }
    if (widget.defaultType != null) {
      _selectedType = widget.defaultType!;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _dataService.getCategories();
    setState(() {
      _categories = categories;
      _updateCategoryForType();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _updateCategoryForType() {
    final categories = _categories.where((c) => c.type == _selectedType).toList();
    if (categories.isNotEmpty) {
      _selectedCategory = categories.first.name;
    } else {
      _selectedCategory = null;
    }
  }

  void _showInstallmentPicker(BuildContext context) {
    final installmentOptions = List.generate(11, (index) => index + 2); // 2 to 12
    int tempInstallmentCount = _installmentCount;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
                      'Taksit Sayısı',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _installmentCount = tempInstallmentCount;
                        });
                        Navigator.pop(context);
                      },
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
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: _installmentCount - 2,
                  ),
                  itemExtent: 50,
                  onSelectedItemChanged: (int index) {
                    tempInstallmentCount = installmentOptions[index];
                  },
                  children: installmentOptions.map((count) {
                    final cleanAmountText = _amountController.text.replaceAll('.', '').replaceAll(',', '.');
                    final monthlyAmount = _amountController.text.isEmpty
                        ? 0.0
                        : (double.tryParse(cleanAmountText) ?? 0.0) / count;
                    
                    return Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$count Taksit',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '• ₺${NumberFormat('#,##0.00', 'tr_TR').format(monthlyAmount)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool get _isSelectedWalletCreditCard {
    if (_selectedWalletId == null) return false;
    final wallet = widget.wallets.firstWhere(
      (w) => w.id == _selectedWalletId,
      orElse: () => widget.wallets.first,
    );
    return wallet.type == 'credit_card';
  }

  Future<void> _saveTransaction() async {
    final error = TransactionFormValidator.validate(
      amountText: _amountController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      walletId: _selectedWalletId,
      selectedType: _selectedType,
      isInstallment: _isInstallment,
      installmentCount: _installmentCount,
      isCreditCardWallet: _isSelectedWalletCreditCard,
    );
    if (error != null) {
      ErrorHandler.showError(context, error);
      return;
    }

    try {
      // Parse the amount by removing formatting characters
      final cleanAmountText = _amountController.text.replaceAll('.', '').replaceAll(',', '.');
      final totalAmount = double.parse(cleanAmountText);

      // Kredi kartı işlemi kontrolü
      if (_isSelectedWalletCreditCard && _selectedType == 'expense') {
        // Wallet ID'sinden kredi kartı ID'sini çıkar (wallet ID formatı: "cc_<cardId>")
        final cardId = _selectedWalletId!.replaceFirst('cc_', '');
        
        // Kredi kartı işlemi oluştur
        final ccTransaction = CreditCardTransaction(
          id: const Uuid().v4(),
          cardId: cardId,
          amount: totalAmount,
          description: _descriptionController.text,
          transactionDate: _selectedDate,
          category: _selectedCategory ?? 'Diğer',
          installmentCount: _isInstallment ? _installmentCount : 1,
          installmentsPaid: 0,
          createdAt: DateTime.now(),
        );

        await _creditCardService.addTransaction(ccTransaction);

        if (mounted) {
          Navigator.pop(context, true);
          ErrorHandler.showSuccess(context, 'Kredi kartı işlemi başarıyla eklendi');
        }
        return;
      }

      // Taksitli işlem kontrolü (normal cüzdan için)
      if (_isInstallment && _installmentCount > 1) {
      final parentId = DateTime.now().millisecondsSinceEpoch.toString();
      final installmentAmount = totalAmount / _installmentCount;
      
      // Her taksit için işlem oluştur
      for (int i = 0; i < _installmentCount; i++) {
        final installmentDate = _selectedDate.add(Duration(days: 30 * i));
        final transaction = Transaction(
          id: '${parentId}_$i',
          type: _selectedType,
          amount: installmentAmount,
          description: '${_descriptionController.text} (${i + 1}/$_installmentCount)',
          category: _selectedCategory ?? '',
          walletId: _selectedWalletId ?? '',
          date: installmentDate,
          memo: _memoController.text.isEmpty ? null : _memoController.text,
          images: _images.isEmpty ? null : _images,
          installments: _installmentCount,
          currentInstallment: i + 1,
          parentTransactionId: parentId,
        );
        
        await _dataService.addTransaction(transaction);
        
        // İlk taksit için bakiyeyi güncelle
        if (i == 0) {
          final wallets = await _dataService.getWallets();
          final walletIndex = wallets.indexWhere((w) => w.id == _selectedWalletId);
          if (walletIndex != -1) {
            final wallet = wallets[walletIndex];
            final newBalance = wallet.balance - installmentAmount;
            
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
        }
      }
    } else {
      // Normal işlem
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: _selectedType,
        amount: totalAmount,
        description: _descriptionController.text,
        category: _selectedCategory ?? '',
        walletId: _selectedWalletId ?? '',
        date: _selectedDate,
        memo: _memoController.text.isEmpty ? null : _memoController.text,
        images: _images.isEmpty ? null : _images,
      );

      await _dataService.addTransaction(transaction);

      // Update wallet balance
      final wallets = await _dataService.getWallets();
      final walletIndex = wallets.indexWhere((w) => w.id == _selectedWalletId);
      if (walletIndex != -1) {
        final wallet = wallets[walletIndex];
        final newBalance = _selectedType == 'income'
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
    }

      if (mounted) {
        Navigator.pop(context, true);
        ErrorHandler.showSuccess(context, 'İşlem başarıyla eklendi');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cüzdan kontrolü
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
                            color: const Color(0xFF5E5CE6).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
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
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Ana Sayfaya Dön'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                      if (_selectedType == 'expense' && _isSelectedWalletCreditCard)
                        _buildInstallmentSection(),
                      if (_selectedType == 'expense' && _isSelectedWalletCreditCard)
                        const SizedBox(height: 20),
                      _buildMemoField(),
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
                _selectedType == 'income' ? 'Gelir' : _selectedType == 'expense' ? 'Gider' : 'Transfer',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _saveTransaction,
                child: const Text(
                  'KAYDET',
                  style: TextStyle(color: Color(0xFF5E5CE6), fontWeight: FontWeight.bold),
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
               String decimalPart = cleanValue.substring(firstCommaIndex + 1).replaceAll(',', '');
               cleanValue = '$integerPart,$decimalPart';
            }
            
            // Handle decimal separator
            final parts = cleanValue.split(',');
            String formattedValue;
            
            if (parts.length > 1) {
              final integerPart = parts[0];
              // Değişiklik: Ondalık kısmı olduğu gibi bırak, yuvarlama
              final decimalPart = parts[1];
              
              // Handle empty integer part (e.g. ",50")
              final parsedInteger = integerPart.isEmpty ? 0 : (int.tryParse(integerPart) ?? 0);
              final formattedInteger = NumberFormat('#,##0', 'tr_TR').format(parsedInteger);
              
              formattedValue = '$formattedInteger,$decimalPart';
            } else {
              final numericValue = int.tryParse(cleanValue) ?? 0;
              formattedValue = NumberFormat('#,##0', 'tr_TR').format(numericValue);
            }
            
            if (value != formattedValue) {
              _amountController.value = TextEditingValue(
                text: formattedValue,
                selection: TextSelection.collapsed(offset: formattedValue.length),
              );
            }
          },
          onTap: () {
            // Clear the field when tapped if it contains only "0" or "0,00"
            if (_amountController.text == '0' || _amountController.text == '0,00') {
              _amountController.clear();

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
            hintText: 'Örn: Market alışverişi',
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
    final filteredCategories = defaultCategories
        .where((c) => c.type == _selectedType)
        .toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
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
                  .map((cat) => DropdownMenuItem(
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
                      ))
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
          initialValue: _selectedWalletId,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: widget.wallets
              .map((wallet) => DropdownMenuItem(
                    value: wallet.id,
                    child: Text('${_cleanWalletName(wallet.name)} • ${NumberFormat('#,##0', 'tr_TR').format(wallet.balance)}'),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedWalletId = value;
              // Kredi kartı değilse taksit seçeneğini kapat
              if (!_isSelectedWalletCreditCard) {
                _isInstallment = false;
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildInstallmentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF5E5CE6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF5E5CE6).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.credit_card,
                color: const Color(0xFF5E5CE6),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Taksit Seçenekleri',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Taksitli Ödeme'),
            subtitle: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _amountController,
              builder: (context, value, child) {
                final amount = value.text.isEmpty 
                    ? 0.0 
                    : (double.tryParse(value.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0);
                final monthlyAmount = amount / _installmentCount;
                
                return Text(
                  _isInstallment
                      ? '$_installmentCount taksit • Aylık ₺${NumberFormat('#,##0.00', 'tr_TR').format(monthlyAmount)}'
                      : 'Tek çekim',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                );
              },
            ),
            value: _isInstallment,
            activeThumbColor: const Color(0xFF5E5CE6),
            onChanged: (value) {
              setState(() => _isInstallment = value);
            },
          ),
          if (_isInstallment) ...[
            const Divider(),
            const Text(
              'Taksit Özeti',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _installmentCount,
                itemBuilder: (context, index) {
                  final month = DateTime.now().add(Duration(days: 30 * index));
                  final amount = _amountController.text.isEmpty 
                      ? 0.0 
                      : (double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0) / _installmentCount;
                  
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5E5CE6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Color(0xFF5E5CE6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      DateFormat('MMMM yyyy', 'tr_TR').format(month),
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: Text(
                      '₺${NumberFormat('#,##0.00', 'tr_TR').format(amount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Taksit Sayısı',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showInstallmentPicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF5E5CE6), width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5E5CE6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_installmentCount',
                            style: const TextStyle(
                              color: Color(0xFF5E5CE6),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_installmentCount Taksit',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _amountController,
                                builder: (context, value, child) {
                                  final amount = value.text.isEmpty 
                                      ? 0.0 
                                      : (double.tryParse(value.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0);
                                  final monthlyAmount = amount / _installmentCount;
                                  
                                  return Text(
                                    'Aylık ₺${NumberFormat('#,##0.00', 'tr_TR').format(monthlyAmount)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF5E5CE6),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Taksitler her ay aynı gün otomatik olarak eklenecektir',
                      style: TextStyle(fontSize: 11, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
              final imagePath = await ImageHelper.showImageSourceDialog(context);
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
                border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey.shade400),
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
                    final imagePath = await ImageHelper.showImageSourceDialog(context);
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
                  child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
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

  Widget _buildImagePlaceholder(String path) {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.image, size: 50, color: Colors.grey),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
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
}
