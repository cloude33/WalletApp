import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/wallet.dart';
import '../services/data_service.dart';

class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    String text = newValue.text.replaceAll(RegExp(r'[^0-9,.]'), '');

    if (text.isEmpty) {
      return const TextEditingValue();
    }
    text = text.replaceAll('.', '');
    List<String> parts = text.split(',');
    if (parts.length > 2) {
      text = '${parts[0]},${parts.sublist(1).join('')}';
      parts = text.split(',');
    }
    String integerPart = parts[0];
    String decimalPart = '';
    if (parts.length > 1) {
      decimalPart = parts[1];
      if (decimalPart.length > 2) {
        decimalPart = decimalPart.substring(0, 2);
      }
    }
    String formattedInteger = '';
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count == 3) {
        formattedInteger = '.$formattedInteger';
        count = 0;
      }
      formattedInteger = integerPart[i] + formattedInteger;
      count++;
    }
    String formattedText = formattedInteger;
    if (parts.length > 1) {
      formattedText += ',$decimalPart';
    }
    int selectionIndex = formattedText.length;

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

class AddWalletScreen extends StatefulWidget {
  final Function(Wallet)? onWalletAdded;
  final String? initialType; // 'cash', 'bank', 'overdraft'

  const AddWalletScreen({super.key, this.onWalletAdded, this.initialType});

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late TextEditingController _limitController;
  late TextEditingController _interestRateController; // Yeni eklendi
  final _nameFocusNode = FocusNode();

  late String _selectedType;
  late String _selectedColor;
  bool _showBankOptions = false;
  String _selectedBank = '';

  // Genişletilmiş Renk Paleti (30 Renk)
  final List<String> _colors = [
    '#007AFF', '#34C759', '#FF9500', '#FF3B30', '#AF52DE', 
    '#5856D6', '#FF2D55', '#5AC8FA', '#FFCC00', '#8E8E93',
    '#1ABC9C', '#2ECC71', '#3498DB', '#9B59B6', '#F1C40F',
    '#E67E22', '#E74C3C', '#95A5A6', '#34495E', '#16A085',
    '#27AE60', '#2980B9', '#8E44AD', '#F39C12', '#D35400',
    '#C0392B', '#7F8C8D', '#2C3E50', '#000000', '#5D4037',
  ];

  final List<String> _turkishBanks = [
    'Akbank',
    'Albaraka Türk',
    'Alternatifbank',
    'Anadolubank',
    'Burgan Bank',
    'Denizbank',
    'Fibabanka',
    'Finansbank',
    'Garanti BBVA',
    'Halkbank',
    'ING Bank',
    'İş Bankası',
    'Kuveyt Türk',
    'Odeabank',
    'QNB Finansbank',
    'Şekerbank',
    'TEB',
    'Türkiye Finans',
    'Vakıfbank',
    'Yapı ve Kredi Bankası',
    'Ziraat Bankası',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? 'cash';
    
    // Başlangıç adını tipe göre ayarla
    String initialName = 'Nakit';
    if (_selectedType == 'bank') {
      initialName = 'Banka Hesabı';
    } else if (_selectedType == 'overdraft') {
      initialName = 'KMH Hesabı';
    }
    
    _nameController = TextEditingController(text: initialName);
    _balanceController = TextEditingController();
    _limitController = TextEditingController();
    _interestRateController = TextEditingController(); // Yeni eklendi
    _selectedColor = _colors[0]; // Varsayılan renk
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _limitController.dispose();
    _interestRateController.dispose(); // Yeni eklendi
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveWallet() async {
    if (_formKey.currentState!.validate()) {
      String walletName = _nameController.text.trim();
      if ((_selectedType == 'bank' || _selectedType == 'overdraft') && _showBankOptions && _selectedBank.isNotEmpty) {
        walletName = _selectedBank;
      }
      
      double initialBalance = 0.0;
      if (_balanceController.text.isNotEmpty) {
        String cleanBalance = _balanceController.text
            .replaceAll('.', '')
            .replaceAll(',', '.');
        initialBalance = double.tryParse(cleanBalance) ?? 0.0;
        if (_selectedType == 'overdraft') {
          initialBalance = -initialBalance.abs();
        }
      }
      
      double limit = 0.0;
      if (_selectedType == 'overdraft' && _limitController.text.isNotEmpty) {
        String cleanLimit = _limitController.text
            .replaceAll('.', '')
            .replaceAll(',', '.');
        limit = double.tryParse(cleanLimit) ?? 0.0;
      }

      double? interestRate;
      if (_selectedType == 'overdraft' && _interestRateController.text.isNotEmpty) {
         String cleanRate = _interestRateController.text.replaceAll(',', '.');
         interestRate = double.tryParse(cleanRate);
      }

      final wallet = Wallet(
        id: const Uuid().v4(),
        name: walletName,
        balance: initialBalance,
        type: _selectedType,
        color: '0xFF${_selectedColor.substring(1)}',
        icon: _selectedType,
        creditLimit: _selectedType == 'overdraft' ? limit : 0.0,
        interestRate: interestRate, // Yeni eklendi
        bankName: (_selectedType == 'bank' || _selectedType == 'overdraft') && _showBankOptions ? _selectedBank : null, // Bank name kaydet
      );

      final dataService = DataService();
      await dataService.addWallet(wallet);

      if (widget.onWalletAdded != null) {
        widget.onWalletAdded!(wallet);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS Grouped Background
      appBar: AppBar(
        title: const Text('Yeni Cüzdan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF007AFF)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveWallet,
            child: const Text(
              'Ekle',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Color(0xFF007AFF),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              _buildSectionHeader('TÜR'),
              _buildTypeSelector(),
              const SizedBox(height: 24),
              _buildSectionHeader('KİMLİK'),
              _buildInfoSection(),
              const SizedBox(height: 24),
              _buildSectionHeader('BAKİYE'),
              _buildBalanceSection(),
              if (_selectedType == 'overdraft') ...[
                 const SizedBox(height: 24),
                _buildSectionHeader('KMH DETAYLARI'), // Limit ve Faiz
                _buildKmhDetailsSection(),
              ],
              const SizedBox(height: 24),
              _buildSectionHeader('GÖRÜNÜM'),
              _buildColorPicker(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    // Banka veya KMH seçili ise banka listesi seçeneği göster
    bool supportsBankSelection = _selectedType == 'bank' || _selectedType == 'overdraft';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          if (supportsBankSelection && _showBankOptions) ...[
            _buildListTile(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBank.isEmpty ? null : _selectedBank,
                  isExpanded: true,
                  hint: const Text('Banka Seçin'),
                  items: _turkishBanks.map((bank) => DropdownMenuItem(
                    value: bank,
                    child: Text(bank),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedBank = value ?? ''),
                ),
              ),
            ),
            const Divider(height: 1, indent: 16),
            GestureDetector(
              onTap: () => setState(() {
                _selectedBank = '';
                _nameController.text = _selectedType == 'overdraft' ? 'KMH Hesabı' : 'Banka Hesabı';
                _showBankOptions = false;
              }),
              child: Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: const Text('Özel isim kullanmak istiyorum', style: TextStyle(color: Color(0xFF007AFF))),
              ),
            ),
          ],
          
          if (!supportsBankSelection || !_showBankOptions)
            _buildInputRow(
              label: 'Cüzdan Adı',
              controller: _nameController,
              placeholder: 'Örn: Nakit',
              validator: (value) => value == null || value.isEmpty ? 'İsim gerekli' : null,
            ),

           if (supportsBankSelection && !_showBankOptions) ...[
              const Divider(height: 1, indent: 16),
              GestureDetector(
                onTap: () => setState(() => _showBankOptions = true),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  child: const Text('Listeden banka seç', style: TextStyle(color: Color(0xFF007AFF))),
                ),
              ),
           ],
        ],
      ),
    );
  }
  
  Widget _buildBalanceSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: _buildInputRow(
        label: _selectedType == 'overdraft' ? 'Mevcut Borç' : 'Bakiye',
        controller: _balanceController,
        placeholder: '0,00',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [DecimalInputFormatter()],
        prefix: '₺ ',
      ),
    );
  }

  // Yeni metod: KMH Detayları (Limit ve Faiz)
  Widget _buildKmhDetailsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _buildInputRow(
            label: 'KMH Limiti',
            controller: _limitController,
            placeholder: '0,00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [DecimalInputFormatter()],
            prefix: '₺ ',
          ),
          const Divider(height: 1, indent: 16),
          _buildInputRow(
            label: 'Faiz Oranı (Aylık)',
            controller: _interestRateController,
            placeholder: '0,00', // Örn: 5.66
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefix: '% ',
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? prefix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130, // Biraz daha geniş
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: placeholder,
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixText: prefix,
              ),
              textAlign: TextAlign.right,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              validator: validator,
              style: const TextStyle(fontSize: 16, color: Color(0xFF007AFF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: child,
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(8.91),
      ),
      child: Row(
        children: [
          _buildTypeSegment('Nakit', 'cash'),
          _buildTypeSegment('Banka', 'bank'),
          _buildTypeSegment('KMH', 'overdraft'),
        ],
      ),
    );
  }

  Widget _buildTypeSegment(String title, String type) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _showBankOptions = false; // Tip değişince banka seçimini sıfırla
            if (type == 'cash') {
              _nameController.text = 'Nakit';
            } else if (type == 'bank') {
              _nameController.text = 'Banka Hesabı';
              // Banka için varsayılan olarak banka listesini açalım mı? Hayır, kullanıcı seçsin.
            } else if (type == 'overdraft') {
              _nameController.text = 'KMH Hesabı';
              // KMH için de banka listesini açmaya gerek yok
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6.93),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _colors.length,
        itemBuilder: (context, index) {
          final colorCode = _colors[index];
          final color = Color(int.parse('0xFF${colorCode.substring(1)}'));
          final isSelected = _selectedColor == colorCode;

          return GestureDetector(
            onTap: () => setState(() => _selectedColor = colorCode),
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 24)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
