import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/wallet.dart';
import '../services/data_service.dart';
import 'add_wallet_screen.dart'; // DecimalInputFormatter için

class EditWalletScreen extends StatefulWidget {
  final Wallet wallet;

  const EditWalletScreen({super.key, required this.wallet});

  @override
  State<EditWalletScreen> createState() => _EditWalletScreenState();
}

class _EditWalletScreenState extends State<EditWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late TextEditingController _limitController;
  late TextEditingController _cutOffDayController;
  late TextEditingController _paymentDayController;
  late TextEditingController _interestRateController; // Yeni eklendi
  final DataService _dataService = DataService();

  late String _selectedType;
  late String _selectedColor;
  bool _showBankOptions = false;
  String _selectedBank = '';
  
  // Genişletilmiş ve AddWalletScreen ile uyumlu renk paleti
  final List<String> _colors = [
    '#007AFF', '#34C759', '#FF9500', '#FF3B30', '#AF52DE', 
    '#5856D6', '#FF2D55', '#5AC8FA', '#FFCC00', '#8E8E93',
    '#1ABC9C', '#2ECC71', '#3498DB', '#9B59B6', '#F1C40F',
    '#E67E22', '#E74C3C', '#95A5A6', '#34495E', '#16A085',
    '#27AE60', '#2980B9', '#8E44AD', '#F39C12', '#D35400',
    '#C0392B', '#7F8C8D', '#2C3E50', '#000000', '#5D4037',
  ];

  final List<String> _turkishBanks = [
    'Türkiye Vakıflar Bankası T.A.O.',
    'Türkiye İş Bankası A.Ş.',
    'Türkiye Halk Bankası A.Ş.',
    'Türkiye Garanti Bankası A.Ş.',
    'Akbank T.A.Ş.',
    'Yapı ve Kredi Bankası A.Ş.',
    'QNB Bank A.Ş.',
    'Denizbank A.Ş.',
    'Türk Ekonomi Bankası A.Ş.',
    'HSBC Bank A.Ş.',
    'ING Bank A.Ş.',
    'Şekerbank T.A.Ş.',
    'Fibabanka A.Ş.',
    'Burgan Bank A.Ş.',
    'Anadolubank A.Ş.',
    'Aktif Yatırım Bankası A.Ş.',
    'Alternatifbank A.Ş.',
    'Citibank A.Ş.',
    'ICBC Turkey Bank A.Ş.',
    'Odea Bank A.Ş.',
    'Enpara Bank A.Ş.',
    'Turkish Bank A.Ş.',
    'Ziraat Dinamik Banka A.Ş.',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.wallet.name);
    _balanceController = TextEditingController(text: widget.wallet.balance.toString().replaceAll('.', ','));
    _limitController = TextEditingController(text: widget.wallet.creditLimit.toString().replaceAll('.', ','));
    _cutOffDayController = TextEditingController(text: widget.wallet.cutOffDay.toString());
    _paymentDayController = TextEditingController(text: widget.wallet.paymentDay.toString());
    _interestRateController = TextEditingController(
      text: widget.wallet.interestRate?.toString().replaceAll('.', ',') ?? '',
    );
    
    _selectedType = widget.wallet.type;
    
    // Hex string formatından kontrol et
    String walletColor = widget.wallet.color;
    if (walletColor.startsWith('0x')) {
      walletColor = '#${walletColor.substring(2)}';
    } else if (!walletColor.startsWith('#')) {
       // Integer color değeri gelirse çevir (eski veri uyumluluğu)
       try {
         final intColor = int.parse(walletColor);
         walletColor = '#${intColor.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
       } catch (e) {
         walletColor = _colors[0];
       }
    }
    _selectedColor = _colors.contains(walletColor) ? walletColor : _colors[0];

    // Banka veya KMH türü için banka adı kontrolü
    if ((_selectedType == 'bank' || _selectedType == 'overdraft') && _turkishBanks.contains(widget.wallet.name)) {
      _selectedBank = widget.wallet.name;
      _showBankOptions = true;
    } else if (widget.wallet.bankName != null && widget.wallet.bankName!.isNotEmpty) {
      // bankName alanı varsa ve doluysa kullan
      if (_turkishBanks.contains(widget.wallet.bankName)) {
         _selectedBank = widget.wallet.bankName!;
         _showBankOptions = true;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _limitController.dispose();
    _cutOffDayController.dispose();
    _paymentDayController.dispose();
    _interestRateController.dispose();
    super.dispose();
  }

  Future<void> _updateWallet() async {
    if (_formKey.currentState!.validate()) {
      String walletName = _nameController.text.trim();
      if ((_selectedType == 'bank' || _selectedType == 'overdraft') && _showBankOptions && _selectedBank.isNotEmpty) {
        walletName = _selectedBank;
      }

      double balance = 0.0;
       if (_balanceController.text.isNotEmpty) {
        String cleanBalance = _balanceController.text
            .replaceAll('.', '')
            .replaceAll(',', '.');
        balance = double.tryParse(cleanBalance) ?? 0.0;
      }

      double limit = 0.0;
       if (_limitController.text.isNotEmpty) {
        String cleanLimit = _limitController.text
            .replaceAll('.', '')
            .replaceAll(',', '.');
        limit = double.tryParse(cleanLimit) ?? 0.0;
      }

      double? interestRate;
      if (_interestRateController.text.isNotEmpty) {
         String cleanRate = _interestRateController.text.replaceAll(',', '.');
         interestRate = double.tryParse(cleanRate);
      }
      
      // Renk formatını düzelt: #RRGGBB -> 0xFFRRGGBB
      String colorToSave = _selectedColor;
      if (colorToSave.startsWith('#')) {
        colorToSave = '0xFF${colorToSave.substring(1)}';
      }

      final updatedWallet = widget.wallet.copyWith(
        name: walletName,
        balance: balance,
        type: _selectedType,
        color: colorToSave,
        icon: _selectedType,
        cutOffDay: int.tryParse(_cutOffDayController.text) ?? 0,
        paymentDay: int.tryParse(_paymentDayController.text) ?? 0,
        creditLimit: limit,
        interestRate: interestRate, // Kaydet
        bankName: (_selectedType == 'bank' || _selectedType == 'overdraft') && _showBankOptions ? _selectedBank : null, // Kaydet
      );

      final wallets = await _dataService.getWallets();
      final index = wallets.indexWhere((w) => w.id == widget.wallet.id);
      if (index != -1) {
        wallets[index] = updatedWallet;
        await _dataService.saveWallets(wallets);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('Cüzdanı Düzenle'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF007AFF)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
             onPressed: _updateWallet,
            child: const Text(
              'Kaydet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF007AFF)),
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
              _buildSectionHeader('KİMLİK'),
              _buildInfoSection(),
              const SizedBox(height: 24),
              _buildSectionHeader('BAKİYE'),
              _buildBalanceSection(),
              if (_selectedType == 'credit_card' || _selectedType == 'overdraft') ...[
                 const SizedBox(height: 24),
                 _buildSectionHeader(_selectedType == 'credit_card' ? 'KREDİ KARTI DETAYLARI' : 'KMH DETAYLARI'),
                 _buildLimitSection(),
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
                  onChanged: (value) => setState(() {
                    _selectedBank = value ?? '';
                    _nameController.text = _selectedBank;
                  }),
                ),
              ),
            ),
            const Divider(height: 1, indent: 16),
            GestureDetector(
              onTap: () => setState(() {
                _selectedBank = '';
                if (_turkishBanks.contains(widget.wallet.name)) {
                   // _nameController.text = widget.wallet.name; // Gerek yok, kullanıcı girmeli
                   _nameController.text = _selectedType == 'overdraft' ? 'KMH Hesabı' : 'Banka Hesabı';
                }
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

  Widget _buildLimitSection() {
    bool isCreditCard = _selectedType == 'credit_card';
    String limitLabel = isCreditCard ? 'Kart Limiti' : 'KMH Limiti';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _buildInputRow(
            label: limitLabel,
            controller: _limitController,
            placeholder: '0,00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [DecimalInputFormatter()],
            prefix: '₺ ',
          ),
          
          if (_selectedType == 'overdraft') ...[
             const Divider(height: 1, indent: 16),
             _buildInputRow(
              label: 'Faiz Oranı (Aylık)',
              controller: _interestRateController,
              placeholder: '0,00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefix: '% ',
            ),
          ],

          if (isCreditCard) ...[
            const Divider(height: 1, indent: 16),
            _buildInputRow(
              label: 'Hesap Kesim Günü',
              controller: _cutOffDayController,
              placeholder: '1-31',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
            ),
             const Divider(height: 1, indent: 16),
             _buildInputRow(
              label: 'Son Ödeme Günü',
              controller: _paymentDayController,
              placeholder: '1-31',
              keyboardType: TextInputType.number,
                 inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],

            ),
          ],
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
            width: 140, // Biraz daha geniş, KMH detayları için
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
          const SizedBox(width: 10),
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

  Widget _buildColorPicker() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _colors.length,
        itemBuilder: (context, index) {
          final colorCode = _colors[index];
          // Hex string to Color
          Color color;
          try {
             color = Color(int.parse('0xFF${colorCode.substring(1)}'));
          } catch(e) {
             color = Colors.blue; 
          }
          
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
