import 'package:flutter/material.dart';
import '../models/wallet.dart';
import '../services/data_service.dart';

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
  final DataService _dataService = DataService();
  
  late String _selectedType;
  late Color _selectedColor;
  bool _showBankOptions = false;
  String _selectedBank = '';
  String _selectedCreditCardBank = '';
  String _selectedOverdraftBank = '';
  bool _showInstallmentOptions = false;
  final int _selectedInstallment = 1;

  final List<Color> _colors = [
    const Color(0xFF42A5F5),
    const Color(0xFFEF5350),
    const Color(0xFFEC407A),
    const Color(0xFF66BB6A),
    const Color(0xFF78909C),
    const Color(0xFFFFCA28),
    const Color(0xFFAB47BC),
    const Color(0xFFFF7043),
  ];

  // Turkish Banks
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

  @override
  void initState() {
    super.initState();
    // Wallet name'den kesim ve ödeme tarihi bilgilerini temizle
    final cleanedName = _cleanWalletName(widget.wallet.name);
    _nameController = TextEditingController(text: cleanedName);
    _balanceController = TextEditingController(text: widget.wallet.balance.toString());
    _limitController = TextEditingController(text: widget.wallet.creditLimit.toString());
    _cutOffDayController = TextEditingController(text: widget.wallet.cutOffDay.toString());
    _paymentDayController = TextEditingController(text: widget.wallet.paymentDay.toString());
    _selectedType = widget.wallet.type;
    _selectedColor = Color(int.parse(widget.wallet.color));
    
    // Check if the wallet name matches any Turkish bank
    if (_selectedType == 'bank' && _turkishBanks.contains(cleanedName)) {
      _showBankOptions = true;
      _selectedBank = cleanedName;
    } else if (_selectedType == 'overdraft' && _turkishBanks.contains(cleanedName)) {
      _selectedOverdraftBank = cleanedName;
      _nameController.text = ''; // Clear name controller if bank is selected
    } else if (_selectedType == 'credit_card') {
      // For credit cards, check if the name contains a bank name
      for (final bank in _turkishBanks) {
        if (cleanedName.startsWith(bank)) {
          _selectedCreditCardBank = bank;
          // If there's a custom name after the bank name, set it in the controller
          if (cleanedName.contains(' - ')) {
            final parts = cleanedName.split(' - ');
            if (parts.length > 1) {
              _nameController.text = parts.sublist(1).join(' - ');
            }
          }
          break;
        }
      }
      // Kesim ve ödeme tarihleri artık wallet modelinde saklanıyor, name'den okumaya gerek yok
      // cutOffDay ve paymentDay zaten widget.wallet'ten alınıyor
    }
  }

  Future<void> _updateWallet() async {
    if (_formKey.currentState!.validate()) {
      String walletName;
      
      // Determine wallet name based on type and selection
      if (_selectedType == 'bank' && _showBankOptions && _selectedBank.isNotEmpty) {
        walletName = _selectedBank;
      } else if (_selectedType == 'credit_card' && _selectedCreditCardBank.isNotEmpty) {
        // For credit cards, combine bank name with custom name if provided
        if (_nameController.text.isNotEmpty && _nameController.text != widget.wallet.name) {
          walletName = '$_selectedCreditCardBank - ${_nameController.text}';
        } else {
          walletName = _selectedCreditCardBank;
        }
      } else if (_selectedType == 'overdraft') {
        // For overdraft (KMH), use bank name if selected, otherwise use custom name
        if (_selectedOverdraftBank.isNotEmpty) {
          walletName = _selectedOverdraftBank;
        } else {
          walletName = _nameController.text;
        }
      } else {
        walletName = _nameController.text;
      }

      // Kesim ve ödeme tarihlerini wallet name'e ekleme (artık gösterilmeyecek)
      // Bu bilgiler sadece cutOffDay ve paymentDay alanlarında saklanacak

      final updatedWallet = Wallet(
        id: widget.wallet.id,
        name: walletName,
        balance: _balanceController.text.isEmpty ? 0.0 : double.parse(_balanceController.text),
        type: _selectedType,
        color: '0x${_selectedColor.value.toRadixString(16).toUpperCase()}',
        icon: _selectedType,
        cutOffDay: _cutOffDayController.text.isEmpty ? 0 : int.parse(_cutOffDayController.text),
        paymentDay: _paymentDayController.text.isEmpty ? 0 : int.parse(_paymentDayController.text),
        installment: _selectedInstallment,
        creditLimit: _limitController.text.isEmpty ? 0.0 : double.parse(_limitController.text),
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
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF5E5CE6),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Cüzdanı Düzenle',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _updateWallet,
                    child: const Text(
                      'Kaydet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cüzdan Adı', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_selectedType == 'bank' && _showBankOptions)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Türk Bankaları', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedBank.isEmpty ? null : _selectedBank,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                  hint: const Text('Bir banka seçin'),
                                  items: _turkishBanks
                                      .map((bank) => DropdownMenuItem(
                                            value: bank,
                                            child: Text(bank, style: const TextStyle(fontSize: 16)),
                                          ))
                                      .toList(),
                                  onChanged: (value) => setState(() => _selectedBank = value ?? ''),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => setState(() {
                                _showBankOptions = false;
                                _selectedBank = '';
                                // Reset name controller to original name if it was a bank
                                if (_turkishBanks.contains(_nameController.text)) {
                                  _nameController.text = widget.wallet.name;
                                }
                              }),
                              child: const Text(
                                'Özel isim kullanmak istiyorum',
                                style: TextStyle(color: Color(0xFF5E5CE6), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        )
                      else if (_selectedType == 'overdraft')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('KMH Hesabı Bankası', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedOverdraftBank.isEmpty ? null : _selectedOverdraftBank,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                  hint: const Text('Bir banka seçin'),
                                  items: _turkishBanks
                                      .map((bank) => DropdownMenuItem(
                                            value: bank,
                                            child: Text(bank, style: const TextStyle(fontSize: 16)),
                                          ))
                                      .toList(),
                                  onChanged: (value) => setState(() => _selectedOverdraftBank = value ?? ''),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => setState(() {
                                _selectedOverdraftBank = '';
                                _nameController.text = widget.wallet.name;
                              }),
                              child: const Text(
                                'Özel isim kullanmak istiyorum',
                                style: TextStyle(color: Color(0xFF5E5CE6), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        )
                      else if (_selectedType == 'credit_card')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bank selection for credit card
                            const Text('Kredi Kartı Bankası', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCreditCardBank.isEmpty ? null : _selectedCreditCardBank,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                  hint: const Text('Bir banka seçin'),
                                  items: _turkishBanks
                                      .map((bank) => DropdownMenuItem(
                                            value: bank,
                                            child: Text(bank, style: const TextStyle(fontSize: 16)),
                                          ))
                                      .toList(),
                                  onChanged: (value) => setState(() => _selectedCreditCardBank = value ?? ''),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Custom name field for credit card
                            const Text('Kart Adı', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: 'Örn: Maximum Kart, World Kart',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen kart adı girin';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            // Cut-off date field
                            const Text('Hesap Kesim Tarihi', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _cutOffDayController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Örn: 1, 15, 30',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                suffixText: 'gün',
                              ),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final day = int.tryParse(value);
                                  if (day == null || day < 1 || day > 31) {
                                    return 'Geçerli bir gün girin (1-31)';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            // Payment date field
                            const Text('Son Ödeme Tarihi', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _paymentDayController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Örn: 1, 15, 30',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                suffixText: 'gün',
                              ),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final day = int.tryParse(value);
                                  if (day == null || day < 1 || day > 31) {
                                    return 'Geçerli bir gün girin (1-31)';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        )
                      else if (_selectedType == 'credit_card' && _showInstallmentOptions)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Kredi Kartı Bankaları', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                  value: _selectedCreditCardBank.isEmpty ? null : _selectedCreditCardBank,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                  hint: const Text('Bir banka seçin'),
                                  items: _turkishBanks
                                      .map((bank) => DropdownMenuItem(
                                            value: bank,
                                            child: Text(bank, style: const TextStyle(fontSize: 16)),
                                          ))
                                      .toList(),
                                  onChanged: (value) => setState(() => _selectedCreditCardBank = value ?? ''),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => setState(() {
                                _showInstallmentOptions = false;
                                _selectedCreditCardBank = '';
                                // Reset name controller to original name if it was a bank
                                if (_turkishBanks.contains(_nameController.text)) {
                                  _nameController.text = widget.wallet.name;
                                }
                              }),
                              child: const Text(
                                'Özel isim kullanmak istiyorum',
                                style: TextStyle(color: Color(0xFF5E5CE6), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        )
                      else
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Örn: Nakit, Ziraat Bankası',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (value) {
                            if ((_selectedType == 'bank' && !_showBankOptions) || 
                                (_selectedType == 'credit_card' && !_showInstallmentOptions) ||
                                _selectedType == 'cash' || _selectedType == 'overdraft') {
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
                              onTap: () => setState(() => _showBankOptions = true),
                              child: const Text(
                                'Türk bankalarından seçmek istiyorum',
                                style: TextStyle(color: Color(0xFF5E5CE6), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        )
                      else if (_selectedType == 'credit_card' && !_showInstallmentOptions)
                        Column(
                          children: [
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => setState(() => _showInstallmentOptions = true),
                              child: const Text(
                                'Kredi kartı bankasını seçmek istiyorum',
                                style: TextStyle(color: Color(0xFF5E5CE6), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      const Text('Başlangıç Bakiyesi', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _balanceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: '₺ ',
                          hintText: '0,00',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (double.tryParse(value) == null) {
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
                      if (_selectedType == 'credit_card' || _selectedType == 'overdraft')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Text(_selectedType == 'credit_card' ? 'Kredi Limiti' : 'KMH Limiti',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _limitController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixText: '₺ ',
                                hintText: '0,00',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (double.tryParse(value) == null) {
                                    return 'Geçerli bir sayı girin';
                                  }
                                }
                                return null;
                              },
                              onTap: () {
                                if (_limitController.text == '0') {
                                  _limitController.clear();
                                }
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      const Text('Cüzdan Tipi', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildTypeButton('Nakit', 'cash', Icons.account_balance_wallet),
                          const SizedBox(width: 10),
                          _buildTypeButton('Kredi Kartı', 'credit_card', Icons.credit_card),
                          const SizedBox(width: 10),
                          _buildTypeButton('Banka', 'bank', Icons.account_balance),
                          const SizedBox(width: 10),
                          _buildTypeButton('KMH', 'overdraft', Icons.account_balance),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Renk Seçin', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
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
                                  color: _selectedColor == color ? Colors.black : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: _selectedColor == color
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updateWallet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5E5CE6),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Güncelle',
                            style: TextStyle(
                              fontSize: 18,
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

  Widget _buildTypeButton(String label, String type, IconData icon) {
    bool isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5E5CE6) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    super.dispose();
  }
}