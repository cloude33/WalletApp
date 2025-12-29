// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/bill_template.dart';
import '../services/bill_template_service.dart';
import '../services/data_service.dart';
import '../constants/electricity_companies.dart';
import '../utils/format_helper.dart';

const List<String> phoneOperators = ['Turkcell', 'Vodafone', 'Türk Telekom'];
const List<String> turkishCities = [
  'Adana',
  'Adıyaman',
  'Afyonkarahisar',
  'Ağrı',
  'Aksaray',
  'Amasya',
  'Ankara',
  'Antalya',
  'Ardahan',
  'Artvin',
  'Aydın',
  'Balıkesir',
  'Bartın',
  'Batman',
  'Bayburt',
  'Bilecik',
  'Bingöl',
  'Bitlis',
  'Bolu',
  'Burdur',
  'Bursa',
  'Çanakkale',
  'Çankırı',
  'Çorum',
  'Denizli',
  'Diyarbakır',
  'Düzce',
  'Edirne',
  'Elazığ',
  'Erzincan',
  'Erzurum',
  'Eskişehir',
  'Gaziantep',
  'Giresun',
  'Gümüşhane',
  'Hakkari',
  'Hatay',
  'Iğdır',
  'Isparta',
  'İstanbul',
  'İzmir',
  'Kahramanmaraş',
  'Karabük',
  'Karaman',
  'Kars',
  'Kastamonu',
  'Kayseri',
  'Kilis',
  'Kırıkkale',
  'Kırklareli',
  'Kırşehir',
  'Kocaeli',
  'Konya',
  'Kütahya',
  'Malatya',
  'Manisa',
  'Mardin',
  'Mersin',
  'Muğla',
  'Muş',
  'Nevşehir',
  'Niğde',
  'Ordu',
  'Osmaniye',
  'Rize',
  'Sakarya',
  'Samsun',
  'Şanlıurfa',
  'Siirt',
  'Sinop',
  'Şırnak',
  'Sivas',
  'Tekirdağ',
  'Tokat',
  'Trabzon',
  'Tunceli',
  'Uşak',
  'Van',
  'Yalova',
  'Yozgat',
  'Zonguldak',
];

class AddBillTemplateScreen extends StatefulWidget {
  final BillTemplate? template;

  const AddBillTemplateScreen({super.key, this.template});

  @override
  State<AddBillTemplateScreen> createState() => _AddBillTemplateScreenState();
}

class _AddBillTemplateScreenState extends State<AddBillTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  final BillTemplateService _service = BillTemplateService();

  late TextEditingController _accountNumberController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _descriptionController;

  BillTemplateCategory _selectedCategory = BillTemplateCategory.electricity;
  String? _selectedCity;
  String? _selectedProvider;
  String? _selectedWalletId;
  bool _isActive = true;
  bool _loading = false;

  List<String> _availableProviders = [];
  List<dynamic> _wallets = [];

  @override
  void initState() {
    super.initState();
    final template = widget.template;

    _accountNumberController = TextEditingController(
      text: template?.accountNumber ?? '',
    );
    _phoneNumberController = TextEditingController(
      text: template?.phoneNumber ?? '',
    );
    _descriptionController = TextEditingController(
      text: template?.description ?? '',
    );

    if (template != null) {
      _selectedCategory = template.category;
      _selectedProvider = template.provider;
      _selectedWalletId = template.walletId;
      _isActive = template.isActive;
    }

    _updateProviderList();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    final dataService = DataService();
    final wallets = await dataService.getWallets();
    setState(() {
      _wallets = wallets;
      if (_selectedWalletId == null && _wallets.isNotEmpty) {
        _selectedWalletId = _wallets.first.id;
      }
    });
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _phoneNumberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateProviderList() {
    setState(() {
      _availableProviders = [];
      _selectedProvider = null;

      switch (_selectedCategory) {
        case BillTemplateCategory.phone:
          _availableProviders = phoneOperators;
          break;
        case BillTemplateCategory.internet:
          _availableProviders = internetProviders
              .map((p) => p.shortName)
              .toList();
          break;
        case BillTemplateCategory.electricity:
          if (_selectedCity != null) {
            final company = getCompanyByCity(_selectedCity!);
            if (company != null) {
              _availableProviders = [company.shortName];
              _selectedProvider = company.shortName;
            }
          }
          break;
        case BillTemplateCategory.water:
          if (_selectedCity != null) {
            final utility = getWaterUtilityByCity(_selectedCity!);
            if (utility != null) {
              _availableProviders = [utility.shortName];
              _selectedProvider = utility.shortName;
            }
          }
          break;
        case BillTemplateCategory.gas:
          if (_selectedCity != null) {
            final company = getNaturalGasCompanyByCity(_selectedCity!);
            if (company != null) {
              _availableProviders = [company.shortName];
              _selectedProvider = company.shortName;
            }
          }
          break;
        default:
          break;
      }
    });
  }

  String _getGeneratedName() {
    if (_selectedCategory == BillTemplateCategory.phone &&
        _phoneNumberController.text.trim().isNotEmpty) {
      String formattedPhone = FormatHelper.formatPhoneNumber(_phoneNumberController.text.trim());

      return _selectedProvider != null
          ? '$_selectedProvider - $formattedPhone'
          : 'Telefon - $formattedPhone';
    }

    if (_selectedProvider != null) {
      return _selectedProvider!;
    }
    return _getCategoryName(_selectedCategory);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_requiresCitySelection() && _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen il seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_requiresProviderSelection() && _selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen sağlayıcı seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final generatedName = _getGeneratedName();

      if (widget.template == null) {
        await _service.addTemplate(
          name: generatedName,
          provider: _selectedProvider,
          category: _selectedCategory,
          walletId: _selectedWalletId,
          accountNumber: _accountNumberController.text.trim().isEmpty
              ? null
              : _accountNumberController.text.trim(),
          phoneNumber: _phoneNumberController.text.trim().isEmpty
              ? null
              : _phoneNumberController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      } else {
        final updated = widget.template!.copyWith(
          name: generatedName,
          provider: _selectedProvider,
          category: _selectedCategory,
          walletId: _selectedWalletId,
          accountNumber: _accountNumberController.text.trim().isEmpty
              ? null
              : _accountNumberController.text.trim(),
          phoneNumber: _phoneNumberController.text.trim().isEmpty
              ? null
              : _phoneNumberController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          isActive: _isActive,
        );
        await _service.updateTemplate(updated);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.template == null
                  ? 'Fatura şablonu eklendi'
                  : 'Fatura şablonu güncellendi',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fatura Şablonunu Sil'),
        content: const Text(
          'Bu fatura şablonunu silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);

    try {
      await _service.deleteTemplate(widget.template!.id);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fatura şablonu silindi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  bool _requiresCitySelection() {
    return _selectedCategory == BillTemplateCategory.electricity ||
        _selectedCategory == BillTemplateCategory.water ||
        _selectedCategory == BillTemplateCategory.gas;
  }

  bool _requiresProviderSelection() {
    return _selectedCategory == BillTemplateCategory.phone ||
        _selectedCategory == BillTemplateCategory.internet;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.template != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Fatura Düzenle' : 'Fatura Ekle'),
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<BillTemplateCategory>(
                    initialValue: _selectedCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: BillTemplateCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(_getCategoryIcon(category), size: 20),
                            const SizedBox(width: 12),
                            Text(_getCategoryName(category)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                          _selectedCity = null;
                          _updateProviderList();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_requiresCitySelection()) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCity,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'İl *',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                      items: turkishCities.map((city) {
                        return DropdownMenuItem(value: city, child: Text(city));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCity = value;
                          _updateProviderList();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_availableProviders.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProvider,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: _requiresProviderSelection()
                            ? 'Sağlayıcı *'
                            : 'Sağlayıcı',
                        prefixIcon: const Icon(Icons.business),
                        border: const OutlineInputBorder(),
                      ),
                      items: _availableProviders.map((provider) {
                        return DropdownMenuItem(
                          value: provider,
                          child: Text(provider),
                        );
                      }).toList(),
                      onChanged: _requiresCitySelection()
                          ? null
                          : (value) {
                              setState(() => _selectedProvider = value);
                            },
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_wallets.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedWalletId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Ödeme Aracı',
                        prefixIcon: Icon(Icons.account_balance_wallet),
                        border: OutlineInputBorder(),
                      ),
                      items: _wallets.map<DropdownMenuItem<String>>((wallet) {
                        return DropdownMenuItem<String>(
                          value: wallet.id as String,
                          child: Row(
                            children: [
                              Icon(
                                wallet.type == 'cash'
                                    ? Icons.money
                                    : wallet.type == 'bank'
                                    ? Icons.account_balance
                                    : Icons.credit_card,
                                size: 20,
                                color: Color(int.parse(wallet.color as String)),
                              ),
                              const SizedBox(width: 8),
                              Text(wallet.name as String),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedWalletId = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen ödeme aracı seçin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _accountNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Abone/Hesap Numarası (Opsiyonel)',
                      hintText: 'Örn: 123456789',
                      prefixIcon: Icon(Icons.numbers),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedCategory == BillTemplateCategory.phone) ...[
                    TextFormField(
                      controller: _phoneNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon Numarası',
                        hintText: '5XX XXX XX XX',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama (Opsiyonel)',
                      hintText: 'Örn: Ev adresi için',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Aktif'),
                    subtitle: const Text(
                      'Pasif faturalar ana ekranda görünmez',
                    ),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() => _isActive = value);
                    },
                    activeTrackColor: const Color(0xFF00BFA5),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF00BFA5),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        isEdit ? 'Güncelle' : 'Kaydet',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (isEdit) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _delete,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text(
                          'Sil',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  IconData _getCategoryIcon(BillTemplateCategory category) {
    switch (category) {
      case BillTemplateCategory.electricity:
        return Icons.bolt;
      case BillTemplateCategory.water:
        return Icons.water_drop;
      case BillTemplateCategory.gas:
        return Icons.local_fire_department;
      case BillTemplateCategory.internet:
        return Icons.wifi;
      case BillTemplateCategory.phone:
        return Icons.phone;
      case BillTemplateCategory.rent:
        return Icons.home;
      case BillTemplateCategory.insurance:
        return Icons.shield;
      case BillTemplateCategory.subscription:
        return Icons.subscriptions;
      case BillTemplateCategory.other:
        return Icons.receipt;
    }
  }

  String _getCategoryName(BillTemplateCategory category) {
    switch (category) {
      case BillTemplateCategory.electricity:
        return 'Elektrik';
      case BillTemplateCategory.water:
        return 'Su';
      case BillTemplateCategory.gas:
        return 'Doğalgaz';
      case BillTemplateCategory.internet:
        return 'İnternet';
      case BillTemplateCategory.phone:
        return 'Telefon';
      case BillTemplateCategory.rent:
        return 'Kira';
      case BillTemplateCategory.insurance:
        return 'Sigorta';
      case BillTemplateCategory.subscription:
        return 'Abonelik';
      case BillTemplateCategory.other:
        return 'Diğer';
    }
  }
}
