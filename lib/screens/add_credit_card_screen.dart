import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/credit_card.dart';
import '../services/credit_card_service.dart';

class AddCreditCardScreen extends StatefulWidget {
  final CreditCard? card; // null for add, non-null for edit

  const AddCreditCardScreen({super.key, this.card});

  @override
  State<AddCreditCardScreen> createState() => _AddCreditCardScreenState();
}

class _AddCreditCardScreenState extends State<AddCreditCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final CreditCardService _cardService = CreditCardService();

  // Form controllers
  late TextEditingController _bankNameController;
  late TextEditingController _cardNameController;
  late TextEditingController _last4DigitsController;
  late TextEditingController _creditLimitController;
  late TextEditingController _statementDayController;
  late TextEditingController _dueDateOffsetController;
  late TextEditingController _monthlyInterestRateController;
  late TextEditingController _lateInterestRateController;
  late TextEditingController _initialDebtController;

  Color _selectedColor = Colors.blue;
  bool _isLoading = false;

  // Turkish bank suggestions
  final List<String> _turkishBanks = [
    'Garanti BBVA',
    'İş Bankası',
    'Yapı Kredi',
    'Akbank',
    'Ziraat Bankası',
    'Halkbank',
    'Vakıfbank',
    'QNB Finansbank',
    'TEB',
    'Denizbank',
    'ING',
    'HSBC',
    'Kuveyt Türk',
    'Albaraka Türk',
  ];

  // Common card types
  final List<String> _cardTypes = [
    'Bonus',
    'Axess',
    'World',
    'Maximum',
    'Paraf',
    'CardFinans',
    'Bankkart Combo',
    'Miles&Smiles',
    'Advantage',
  ];

  // Predefined colors
  final List<Color> _cardColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing card data or empty
    final card = widget.card;
    _bankNameController = TextEditingController(text: card?.bankName ?? '');
    _cardNameController = TextEditingController(text: card?.cardName ?? '');
    _last4DigitsController = TextEditingController(text: card?.last4Digits ?? '');
    _creditLimitController = TextEditingController(
      text: card != null ? _formatNumber(card.creditLimit) : '',
    );
    _statementDayController = TextEditingController(
      text: card?.statementDay.toString() ?? '',
    );
    _dueDateOffsetController = TextEditingController(
      text: card?.dueDateOffset.toString() ?? '10',
    );
    _monthlyInterestRateController = TextEditingController(
      text: card?.monthlyInterestRate.toString() ?? '3.5',
    );
    _lateInterestRateController = TextEditingController(
      text: card?.lateInterestRate.toString() ?? '4.5',
    );
    _initialDebtController = TextEditingController(
      text: card != null && card.initialDebt > 0 ? _formatNumber(card.initialDebt) : '',
    );

    if (card != null) {
      _selectedColor = card.color;
    }
  }

  // Binlik ayırıcı ile sayı formatlama
  String _formatNumber(double number) {
    return NumberFormat('#,##0.##', 'tr_TR').format(number);
  }

  // Binlik ayırıcıyı kaldırıp sayıya çevirme
  double _parseNumber(String text) {
    return double.tryParse(text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _cardNameController.dispose();
    _last4DigitsController.dispose();
    _creditLimitController.dispose();
    _statementDayController.dispose();
    _dueDateOffsetController.dispose();
    _monthlyInterestRateController.dispose();
    _lateInterestRateController.dispose();
    _initialDebtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.card != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Kredi Kartı Düzenle' : 'Kredi Kartı Ekle'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildBankNameField(),
                  const SizedBox(height: 16),
                  _buildCardNameField(),
                  const SizedBox(height: 16),
                  _buildLast4DigitsField(),
                  const SizedBox(height: 16),
                  _buildCreditLimitField(),
                  const SizedBox(height: 16),
                  _buildInitialDebtField(),
                  const SizedBox(height: 24),
                  const Text(
                    'Ekstre ve Ödeme Bilgileri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatementDayField(),
                  const SizedBox(height: 16),
                  _buildDueDateOffsetField(),
                  const SizedBox(height: 24),
                  const Text(
                    'Faiz Oranları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMonthlyInterestRateField(),
                  const SizedBox(height: 16),
                  _buildLateInterestRateField(),
                  const SizedBox(height: 24),
                  const Text(
                    'Kart Rengi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildColorPicker(),
                  const SizedBox(height: 32),
                  _buildSaveButton(isEdit),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildBankNameField() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _bankNameController.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _turkishBanks;
        }
        return _turkishBanks.where((String bank) {
          return bank.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        _bankNameController.text = selection;
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _bankNameController = controller;
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Banka Adı',
            hintText: 'Örn: Garanti BBVA',
            prefixIcon: Icon(Icons.account_balance),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Banka adı gerekli';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildCardNameField() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _cardNameController.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _cardTypes;
        }
        return _cardTypes.where((String type) {
          return type.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        _cardNameController.text = selection;
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _cardNameController = controller;
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Kart Adı',
            hintText: 'Örn: Bonus, Axess, World',
            prefixIcon: Icon(Icons.credit_card),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Kart adı gerekli';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildLast4DigitsField() {
    return TextFormField(
      controller: _last4DigitsController,
      decoration: const InputDecoration(
        labelText: 'Son 4 Hane',
        hintText: '1234',
        prefixIcon: Icon(Icons.pin),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Son 4 hane gerekli';
        }
        if (value.length != 4) {
          return 'Tam 4 hane girilmeli';
        }
        return null;
      },
    );
  }

  Widget _buildCreditLimitField() {
    return TextFormField(
      controller: _creditLimitController,
      decoration: const InputDecoration(
        labelText: 'Kredi Limiti',
        hintText: '50.000,00',
        helperText: 'Ondalık sayı için virgül (,) kullanın',
        prefixIcon: Icon(Icons.account_balance_wallet),
        suffixText: '₺',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
        _DecimalThousandsSeparatorInputFormatter(),
      ],
      onChanged: (value) {
        // Cursor pozisyonunu koru
        final cursorPos = _creditLimitController.selection.base.offset;
        final formatted = _formatNumberInput(value);
        if (formatted != value) {
          _creditLimitController.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(
              offset: cursorPos + (formatted.length - value.length),
            ),
          );
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Kredi limiti gerekli';
        }
        final limit = _parseNumber(value);
        if (limit <= 0) {
          return 'Geçerli bir limit giriniz';
        }
        return null;
      },
    );
  }

  String _formatNumberInput(String value) {
    if (value.isEmpty) return value;
    final number = int.tryParse(value.replaceAll('.', ''));
    if (number == null) return value;
    return NumberFormat('#,##0', 'tr_TR').format(number).replaceAll(',', '.');
  }

  Widget _buildInitialDebtField() {
    return TextFormField(
      controller: _initialDebtController,
      decoration: const InputDecoration(
        labelText: 'Mevcut Borç (Opsiyonel)',
        hintText: 'Boş bırakabilirsiniz',
        helperText: 'Önceki dönemden kalan borç varsa giriniz. Binlik ayırıcı otomatik eklenir.',
        prefixIcon: Icon(Icons.credit_card_outlined),
        suffixText: '₺',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _ThousandsSeparatorInputFormatter(),
      ],
      onChanged: (value) {
        // Cursor pozisyonunu koru
        final cursorPos = _initialDebtController.selection.base.offset;
        final formatted = _formatNumberInput(value);
        if (formatted != value) {
          _initialDebtController.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(
              offset: cursorPos + (formatted.length - value.length),
            ),
          );
        }
      },
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final debt = _parseNumber(value);
          if (debt < 0) {
            return 'Geçerli bir tutar giriniz';
          }
        }
        return null;
      },
    );
  }


  Widget _buildStatementDayField() {
    return TextFormField(
      controller: _statementDayController,
      decoration: const InputDecoration(
        labelText: 'Ekstre Kesim Günü',
        hintText: '1-31 arası',
        helperText: 'Her ayın kaçında ekstre kesilir',
        prefixIcon: Icon(Icons.calendar_today),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ekstre kesim günü gerekli';
        }
        final day = int.tryParse(value);
        if (day == null || day < 1 || day > 31) {
          return '1-31 arası bir değer giriniz';
        }
        return null;
      },
    );
  }

  Widget _buildDueDateOffsetField() {
    return TextFormField(
      controller: _dueDateOffsetController,
      decoration: const InputDecoration(
        labelText: 'Son Ödeme Günü (Gün Sayısı)',
        hintText: '10',
        helperText: 'Ekstre kesiminden kaç gün sonra son ödeme',
        prefixIcon: Icon(Icons.event),
        suffixText: 'gün',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Son ödeme günü gerekli';
        }
        final offset = int.tryParse(value);
        if (offset == null || offset < 0) {
          return 'Geçerli bir değer giriniz';
        }
        return null;
      },
    );
  }

  Widget _buildMonthlyInterestRateField() {
    return TextFormField(
      controller: _monthlyInterestRateController,
      decoration: const InputDecoration(
        labelText: 'Aylık Faiz Oranı',
        hintText: '3.5',
        helperText: 'Normal faiz oranı (aylık %)',
        prefixIcon: Icon(Icons.percent),
        suffixText: '%',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Faiz oranı gerekli';
        }
        final rate = double.tryParse(value);
        if (rate == null || rate < 0) {
          return 'Geçerli bir oran giriniz';
        }
        return null;
      },
    );
  }

  Widget _buildLateInterestRateField() {
    return TextFormField(
      controller: _lateInterestRateController,
      decoration: const InputDecoration(
        labelText: 'Gecikme Faiz Oranı',
        hintText: '4.5',
        helperText: 'Gecikme durumunda uygulanan faiz (aylık %)',
        prefixIcon: Icon(Icons.warning),
        suffixText: '%',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Gecikme faiz oranı gerekli';
        }
        final rate = double.tryParse(value);
        if (rate == null || rate < 0) {
          return 'Geçerli bir oran giriniz';
        }
        return null;
      },
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _cardColors.map((color) {
        final isSelected = color.toARGB32() == _selectedColor.toARGB32();
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColor = color;
            });
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey[300]!,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton(bool isEdit) {
    return ElevatedButton(
      onPressed: _saveCard,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        isEdit ? 'Güncelle' : 'Kaydet',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final initialDebt = _initialDebtController.text.isEmpty 
          ? 0.0 
          : _parseNumber(_initialDebtController.text);
      
      final card = CreditCard(
        id: widget.card?.id ?? const Uuid().v4(),
        bankName: _bankNameController.text.trim(),
        cardName: _cardNameController.text.trim(),
        last4Digits: _last4DigitsController.text.trim(),
        creditLimit: _parseNumber(_creditLimitController.text),
        statementDay: int.parse(_statementDayController.text),
        dueDateOffset: int.parse(_dueDateOffsetController.text),
        monthlyInterestRate: double.parse(_monthlyInterestRateController.text),
        lateInterestRate: double.parse(_lateInterestRateController.text),
        cardColor: _selectedColor.toARGB32(),
        createdAt: widget.card?.createdAt ?? DateTime.now(),
        isActive: widget.card?.isActive ?? true,
        initialDebt: initialDebt,
      );

      if (widget.card == null) {
        // Create new card
        await _cardService.createCard(card);
      } else {
        // Update existing card
        await _cardService.updateCard(card);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.card == null
                  ? 'Kredi kartı başarıyla eklendi'
                  : 'Kredi kartı başarıyla güncellendi',
            ),
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

// Binlik ayırıcı input formatter
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Sadece rakamları al
    final number = int.tryParse(newValue.text.replaceAll('.', ''));
    if (number == null) {
      return oldValue;
    }

    // Binlik ayırıcı ile formatla
    final formatted = NumberFormat('#,##0', 'tr_TR')
        .format(number)
        .replaceAll(',', '.');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Ondalık sayı ve binlik ayırıcı destekli formatter
class _DecimalThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String text = newValue.text;
    
    // Tüm noktaları kaldır (binlik ayırıcı)
    text = text.replaceAll('.', '');
    
    // Virgülü noktaya çevir (ondalık ayırıcı)
    text = text.replaceAll(',', '.');
    
    // Sadece bir ondalık nokta olsun
    final parts = text.split('.');
    if (parts.length > 2) {
      text = '${parts[0]}.${parts.sublist(1).join('')}';
    }
    
    // Ondalık kısmı maksimum 2 basamak
    if (parts.length == 2 && parts[1].length > 2) {
      text = '${parts[0]}.${parts[1].substring(0, 2)}';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

