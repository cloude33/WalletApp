import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/wallet.dart';
import '../services/data_service.dart';

class EditKmhAccountScreen extends StatefulWidget {
  final Wallet account;

  const EditKmhAccountScreen({super.key, required this.account});

  @override
  State<EditKmhAccountScreen> createState() => _EditKmhAccountScreenState();
}

class _EditKmhAccountScreenState extends State<EditKmhAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final DataService _dataService = DataService();
  
  late TextEditingController _nameController;
  late TextEditingController _creditLimitController;
  late TextEditingController _interestRateController;
  late TextEditingController _accountNumberController;
  late TextEditingController _bankNameController;
  late TextEditingController _ibanController;
  
  bool _isLoading = false;
  String _selectedColor = '';

  final List<Map<String, dynamic>> _colors = [
    {'name': 'Mavi', 'value': '0xFF2196F3'},
    {'name': 'Yeşil', 'value': '0xFF4CAF50'},
    {'name': 'Turuncu', 'value': '0xFFFF9800'},
    {'name': 'Mor', 'value': '0xFF9C27B0'},
    {'name': 'Kırmızı', 'value': '0xFFF44336'},
    {'name': 'Pembe', 'value': '0xFFE91E63'},
    {'name': 'Lacivert', 'value': '0xFF3F51B5'},
    {'name': 'Turkuaz', 'value': '0xFF00BCD4'},
    {'name': 'Teal', 'value': '0xFF009688'},
    // Cyan already exists as Turkuaz
    {'name': 'Deep Orange', 'value': '0xFFFF5722'},
    {'name': 'Brown', 'value': '0xFF795548'},
    {'name': 'Blue Grey', 'value': '0xFF607D8B'},
    {'name': 'Deep Purple Accent', 'value': '0xFFE040FB'},
    {'name': 'Amber Accent', 'value': '0xFFFFD740'},
    {'name': 'Lime', 'value': '0xFFCDDC39'},
    {'name': 'Indigo Dark', 'value': '0xFF1A237E'},
    {'name': 'Black', 'value': '0xFF000000'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _creditLimitController = TextEditingController(
      text: widget.account.creditLimit.toString(),
    );
    _interestRateController = TextEditingController(
      text: widget.account.interestRate?.toString().replaceAll('.', ',') ?? '',
    );
    _accountNumberController = TextEditingController(
      text: widget.account.accountNumber ?? '',
    );
    _bankNameController = TextEditingController(
      text: widget.account.bankName ?? '',
    );
    _ibanController = TextEditingController(
      text: widget.account.iban ?? '',
    );
    _selectedColor = widget.account.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _creditLimitController.dispose();
    _interestRateController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Faiz oranı kontrolü
    final interestRateText = _interestRateController.text.trim();
    if (interestRateText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen faiz oranını giriniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Virgülü noktaya çevir (Türkçe klavye desteği için)
      final normalizedInterestRate = interestRateText.replaceAll(',', '.');
      final parsedInterestRate = double.tryParse(normalizedInterestRate);
      
      final updatedAccount = widget.account.copyWith(
        name: _nameController.text.trim(),
        creditLimit: double.tryParse(_creditLimitController.text) ?? 0,
        interestRate: parsedInterestRate,
        updateInterestRate: true,
        accountNumber: _accountNumberController.text.trim().isEmpty
            ? null
            : _accountNumberController.text.trim(),
        updateAccountNumber: true,
        bankName: _bankNameController.text.trim().isEmpty
            ? null
            : _bankNameController.text.trim(),
        updateBankName: true,
        iban: _ibanController.text.trim().isEmpty
            ? null
            : _ibanController.text.trim(),
        updateIban: true,
        color: _selectedColor,
      );

      await _dataService.updateWallet(updatedAccount);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KMH hesabı güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KMH Hesabını Düzenle'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildBasicInfoSection(),
            const SizedBox(height: 16),
            _buildKmhSettingsSection(),
            const SizedBox(height: 16),
            _buildBankInfoSection(),
            const SizedBox(height: 16),
            _buildColorSection(),
            const SizedBox(height: 24),
            _buildSaveButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'KMH faizi günlük olarak hesaplanır ve genellikle her ayın son günü hesaba yansır.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Temel Bilgiler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Hesap Adı',
                hintText: 'Örn: Garanti BBVA KMH',
                prefixIcon: Icon(Icons.account_balance),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Hesap adı gerekli';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKmhSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KMH Ayarları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _creditLimitController,
              decoration: const InputDecoration(
                labelText: 'Kredi Limiti',
                hintText: '0.00',
                prefixIcon: Icon(Icons.credit_card),
                prefixText: '₺ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kredi limiti gerekli';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Geçerli bir tutar girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _interestRateController,
              decoration: InputDecoration(
                labelText: 'Yıllık Faiz Oranı',
                hintText: 'Örn: 45.5',
                prefixIcon: const Icon(Icons.percent),
                suffixText: '%',
                border: const OutlineInputBorder(),
                helperText: 'Bankanızın KMH faiz oranını girin',
                helperMaxLines: 2,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                // Hem virgül hem nokta kabul et (Türkçe klavye desteği)
                FilteringTextInputFormatter.allow(RegExp(r'^\d+[.,]?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Faiz oranı gerekli';
                }
                // Virgülü noktaya çevir ve parse et
                final normalizedValue = value.replaceAll(',', '.');
                final rate = double.tryParse(normalizedValue);
                if (rate == null || rate < 0 || rate > 100) {
                  return 'Geçerli bir oran girin (0-100)';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Banka Bilgileri (Opsiyonel)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankNameController,
              decoration: const InputDecoration(
                labelText: 'Banka Adı',
                hintText: 'Örn: Garanti BBVA',
                prefixIcon: Icon(Icons.account_balance),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accountNumberController,
              decoration: const InputDecoration(
                labelText: 'Hesap Numarası',
                hintText: 'Örn: 1234567890',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ibanController,
              decoration: const InputDecoration(
                labelText: 'IBAN',
                hintText: 'TR00 0000 0000 0000 0000 0000 00',
                prefixIcon: Icon(Icons.account_balance_wallet),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9\s]')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Renk Seçimi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colors.map((colorData) {
                final isSelected = _selectedColor == colorData['value'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = colorData['value'] as String;
                    });
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Color(int.parse(colorData['value'] as String)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 30,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveChanges,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isLoading ? 'Kaydediliyor...' : 'Değişiklikleri Kaydet'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BFA5),
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
