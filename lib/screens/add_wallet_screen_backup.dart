import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/wallet.dart';
import '../services/data_service.dart';
import 'package:uuid/uuid.dart';

// Custom formatter for thousand separators
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) {
      return const TextEditingValue();
    }

    // Add thousand separators
    String formatted = '';
    int count = 0;
    for (int i = newText.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        formatted = '.$formatted';
      }
      formatted = newText[i] + formatted;
      count++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AddWalletScreen extends StatefulWidget {
  const AddWalletScreen({super.key});

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final _balanceController = TextEditingController();
  final _limitController = TextEditingController();
  final DataService _dataService = DataService();

  String _selectedType = 'cash';
  Color _selectedColor = const Color(0xFF42A5F5);
  bool _showBankOptions = false;
  String _selectedBank = '';
  String _selectedCreditCardBank = '';
  String _selectedOverdraftBank = '';
  final bool _showInstallmentOptions = false;
  final int _selectedInstallment = 1;

  final List<Color> _colors = [
    const Color(0xFF42A5F5), // Blue
    const Color(0xFFEF5350), // Red
    const Color(0xFFEC407A), // Pink
    const Color(0xFF66BB6A), // Green
    const Color(0xFF78909C), // Grey
    const Color(0xFFFFCA28), // Yellow
    const Color(0xFFAB47BC), // Purple
    const Color(0xFFFF7043), // Orange
  ];

  // Turkish Banks (Alphabetically sorted)
  final List<String> _turkishBanks = [
    'Akbank T.A.Ş.',
    'Aktif Yatırım Bankası A.Ş.',
    'Alternatifbank A.Ş.',
    'Anadolubank A.Ş.',
    'Burgan Bank A.Ş.',
    'Citibank A.Ş.',
    'Denizbank A.Ş.',
    'Enpara Bank A.Ş.',
    'Fibabanka A.Ş.',
    'HSBC Bank A.Ş.',
    'ICBC Turkey Bank A.Ş.',
    'ING Bank A.Ş.',
    'Odea Bank A.Ş.',
    'QNB Bank A.Ş.',
    'Şekerbank T.A.Ş.',
    'Turkish Bank A.Ş.',
    'Türk Ekonomi Bankası A.Ş.',
    'Türkiye Garanti Bankası A.Ş.',
    'Türkiye Halk Bankası A.Ş.',
    'Türkiye İş Bankası A.Ş.',
    'Türkiye Vakıflar Bankası T.A.O.',
    'Yapı ve Kredi Bankası A.Ş.',
    'Ziraat Dinamik Banka A.Ş.',
    'Ziraat Bankası A.Ş.',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with a default name based on type
    _nameController.text = _selectedType == 'cash'
        ? 'Nakit'
        : _selectedType == 'overdraft'
        ? 'KMH Hesabı'
        : 'Banka Hesabı';
    // Listener to clear placeholder when focused
    _nameFocusNode.addListener(() {
      if (_nameFocusNode.hasFocus &&
          (_nameController.text == 'KMH Hesabı' ||
              _nameController.text == 'Banka Hesabı')) {
        _nameController.clear();
      }
    });
  }

  Future<void> _saveWallet() async {
    // Prevent credit card creation
    if (_selectedType == 'credit_card') return;

    if (_formKey.currentState!.validate()) {
      String walletName;

      // Determine wallet name based on type and selection
      if (_selectedType == 'bank' &&
          _showBankOptions &&
          _selectedBank.isNotEmpty) {
        walletName = _selectedBank;
      } else if (_selectedType == 'overdraft') {
        // For overdraft (KMH), use bank name if selected, otherwise use custom name
        if (_selectedOverdraftBank.isNotEmpty) {
          walletName = _selectedOverdraftBank;
        } else {
          walletName = _nameController.text.isEmpty
              ? 'KMH Hesabı'
              : _nameController.text;
        }
      } else {
        walletName = _nameController.text;
      }

      // Remove thousand separators from balance before parsing
      String balanceText = _balanceController.text.replaceAll('.', '');
      String limitText = _limitController.text.replaceAll('.', '');

      final wallet = Wallet(
        id: Uuid().v4(),
        name: walletName,
        balance: balanceText.isEmpty
            ? 0.0
            : (_selectedType == 'overdraft')
            ? -double.parse(balanceText).abs()
            : double.parse(balanceText),
        type: _selectedType,
        color: '0x${_selectedColor.value.toRadixString(16).toUpperCase()}',
        icon: _selectedType,
        creditLimit: limitText.isEmpty ? 0.0 : double.parse(limitText),
      );

      await _dataService.addWallet(wallet);

      if (mounted) {
        Navigator.pop(context, true);
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
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wallet Name Section
                      const Text(
                        'Cüzdan Adı',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedType == 'bank' && _showBankOptions)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedBank.isEmpty
                                      ? null
                                      : _selectedBank,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey,
                                  ),
                                  hint: const Text('Bir banka seçin'),
                                  items: _turkishBanks
                                      .map(
                                        (bank) => DropdownMenuItem(
                                          value: bank,
                                          child: Text(
                                            bank,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) => setState(
                                    () => _selectedBank = value ?? '',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => setState(() {
                                _showBankOptions = false;
                                _selectedBank = '';
                              }),
                              child: const Text(
                                'Özel isim kullanmak istiyorum',
                                style: TextStyle(
                                  color: Color(0xFF5E5CE6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (_selectedType == 'overdraft')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bank selection for overdraft (KMH)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedOverdraftBank.isEmpty
                                      ? null
                                      : _selectedOverdraftBank,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey,
                                  ),
                                  hint: const Text('Bir banka seçin'),
                                  items: _turkishBanks
                                      .map(
                                        (bank) => DropdownMenuItem(
                                          value: bank,
                                          child: Text(
                                            bank,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) => setState(
                                    () => _selectedOverdraftBank = value ?? '',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => setState(() {
                                _selectedOverdraftBank = '';
                                _nameController.text = 'KMH Hesabı';
                              }),
                              child: const Text(
                                'Özel isim kullanmak istiyorum',
                                style: TextStyle(
                                  color: Color(0xFF5E5CE6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (_selectedType == 'overdraft')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bank selection for overdraft (KMH)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedOverdraftBank.isEmpty
                                      ? null
                                      : _selectedOverdraftBank,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey,
                                  ),
                                  hint: const Text('Bir banka seçin'),
                                  items: _turkishBanks
                                      .map(
                                        (bank) => DropdownMenuItem(
                                          value: bank,
                                          child: Text(
                                            bank,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) => setState(
                                    () => _selectedOverdraftBank = value ?? '',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => setState(() {
                                _selectedOverdraftBank = '';
                                _nameController.text = 'KMH Hesabı';
                              }),
                              child: const Text(
                                'Özel isim kullanmak istiyorum',
                                style: TextStyle(
                                  color: Color(0xFF5E5CE6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        TextFormField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          decoration: InputDecoration(
                            hintText: 'Örn: Nakit, Ziraat Bankası',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                              borderSide: BorderSide(
                                color: Color(0xFF5E5CE6),
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (_selectedType == 'bank' && !_showBankOptions) {
                              if (value == null || value.isEmpty) {
                                return 'Lütfen cüzdan adı girin';
                              }
                            } else if (_selectedType == 'overdraft' &&
                                _selectedOverdraftBank.isEmpty) {
                              if (value == null || value.isEmpty) {
                                return 'Lütfen cüzdan adı girin veya banka seçin';
                              }
                            } else if (_selectedType == 'cash') {
                              if (value == null || value.isEmpty) {
                                return 'Lütfen cüzdan adı girin';
                              }
                            }
                            return null;
                          },
                        );
                      }
                    else
                      TextFormField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          decoration: InputDecoration(
                            hintText: 'Örn: Nakit, Ziraat Bankası',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                              borderSide: BorderSide(
                                color: Color(0xFF5E5CE6),
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (_selectedType == 'bank' && !_showBankOptions) {
                              if (value == null || value.isEmpty) {
                                return 'Lütfen cüzdan adı girin';
                              }
                            } else if (_selectedType == 'overdraft' &&
                                _selectedOverdraftBank.isEmpty) {
                              if (value == null || value.isEmpty) {
                                return 'Lütfen cüzdan adı girin veya banka seçin';
                              }
                            } else if (_selectedType == 'cash') {
                              if (value == null || value.isEmpty) {
                                return 'Lütfen cüzdan adı girin';
                              }
                            }
                            return null;
                          },
                        ),
                      if (_selectedType == 'bank' && !_showBankOptions)
                        Column(
                          children: [
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _showBankOptions = true),
                              child: const Text(
                                'Türk bankalarından seçmek istiyorum',
                                style: TextStyle(
                                  color: Color(0xFF5E5CE6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),

                      // Initial Balance Section
                      Text(
                        (_selectedType == 'overdraft')
                            ? 'Mevcut Borç'
                            : 'Başlangıç Bakiyesi',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _balanceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          ThousandsSeparatorInputFormatter(),
                        ],
                        decoration: InputDecoration(
                          prefixText: '₺ ',
                          hintText: '0',
                          helperText:
                              (_selectedType == 'overdraft')
                              ? 'Borcunuzu pozitif girin, otomatik olarak eksiye çevrilecektir.'
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(
                              color: Color(0xFF5E5CE6),
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            // Remove dots for validation
                            String cleanValue = value.replaceAll('.', '');
                            if (double.tryParse(cleanValue) == null) {
                              return 'Geçerli bir sayı girin';
                            }
                          }
                          return null;
                        },
                        onTap: () {
                          // Clear the field when tapped if it contains only "0"
                          if (_balanceController.text == '0') {
                            _balanceController.clear();
                          }
                        },
                      ),

                      if (_selectedType == 'overdraft') ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Limit',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _limitController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            ThousandsSeparatorInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            prefixText: '₺ ',
                            hintText: '0',
                            helperText: 'Toplam limitinizi girin',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                              borderSide: BorderSide(
                                color: Color(0xFF5E5CE6),
                                width: 2,
                              ),
                            ),
                          ),
                          onTap: () {
                            if (_limitController.text == '0') {
                              _limitController.clear();
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Wallet Type Section
                      const Text(
                        'Cüzdan Tipi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildModernTypeButton(
                            'Nakit',
                            'cash',
                            Icons.account_balance_wallet,
                          ),
                          const SizedBox(width: 12),
                          _buildModernTypeButton(
                            'Banka',
                            'bank',
                            Icons.account_balance,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: SizedBox()), // Boşluk doldurucu
                        ],
                      ),

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildModernTypeButton(
                            'KMH Hesabı',
                            'overdraft',
                            Icons.account_balance,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: SizedBox()), // Boşluk doldurucu
                          const SizedBox(width: 12),
                          const Expanded(child: SizedBox()), // Boşluk doldurucu
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Color Selection Section
                      const Text(
                        'Renk Seçin',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _colors.map((color) {
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedColor == color
                                      ? Colors.black
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _selectedColor == color
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 28,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // Create Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveWallet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5E5CE6),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Cüzdan Oluştur',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Color(0xFF5E5CE6)),
          ),
          const Expanded(
            child: Text(
              'Yeni Cüzdan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ),
          const SizedBox(width: 24), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildModernTypeButton(String label, String type, IconData icon) {
    bool isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            // Update the name controller based on the selected type
            if (type == 'cash') {
              _nameController.text = 'Nakit';
              _showBankOptions = false;
              _selectedBank = '';
            } else if (type == 'bank') {
              _nameController.text = 'Banka Hesabı';
              _showBankOptions = true;
              _selectedBank = '';
            } else if (type == 'overdraft') {
              _nameController.text = 'KMH Hesabı';
              _selectedOverdraftBank = '';
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5E5CE6) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF5E5CE6)
                  : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF5E5CE6),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _limitController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }
}
