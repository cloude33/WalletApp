import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/bill_template.dart';
import '../services/bill_template_service.dart';
import '../services/bill_payment_service.dart';
import '../constants/electricity_companies.dart';

/// Fatura ekleme ekranı - Tek ekranda hem şablon hem tutar girişi
/// Arka planda BillTemplate + BillPayment kullanır ama kullanıcı tek ekran görür
class AddBillScreen extends StatefulWidget {
  const AddBillScreen({super.key});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final BillTemplateService _templateService = BillTemplateService();
  final BillPaymentService _paymentService = BillPaymentService();

  final _nameController = TextEditingController();
  final _accountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  // Akış adımları
  int _currentStep = 0; // 0: İl, 1: Kategori, 2: Şirket, 3: Detaylar

  // Seçimler
  String? _selectedCity;
  BillTemplateCategory? _selectedCategory;
  String? _selectedProvider;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  bool _isLoading = false;

  // Türkiye illeri
  final List<String> _cities = [
    'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray', 'Amasya',
    'Ankara', 'Antalya', 'Ardahan', 'Artvin', 'Aydın', 'Balıkesir',
    'Bartın', 'Batman', 'Bayburt', 'Bilecik', 'Bingöl', 'Bitlis',
    'Bolu', 'Burdur', 'Bursa', 'Çanakkale', 'Çankırı', 'Çorum',
    'Denizli', 'Diyarbakır', 'Düzce', 'Edirne', 'Elazığ', 'Erzincan',
    'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane', 'Hakkari',
    'Hatay', 'Iğdır', 'Isparta', 'İstanbul', 'İzmir', 'Kahramanmaraş',
    'Karabük', 'Karaman', 'Kars', 'Kastamonu', 'Kayseri', 'Kilis',
    'Kırıkkale', 'Kırklareli', 'Kırşehir', 'Kocaeli', 'Konya', 'Kütahya',
    'Malatya', 'Manisa', 'Mardin', 'Mersin', 'Muğla', 'Muş',
    'Nevşehir', 'Niğde', 'Ordu', 'Osmaniye', 'Rize', 'Sakarya',
    'Samsun', 'Şanlıurfa', 'Siirt', 'Sinop', 'Şırnak', 'Sivas',
    'Tekirdağ', 'Tokat', 'Trabzon', 'Tunceli', 'Uşak', 'Van',
    'Yalova', 'Yozgat', 'Zonguldak',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  List<String> _getProvidersByCategory() {
    if (_selectedCity == null || _selectedCategory == null) return [];

    switch (_selectedCategory!) {
      case BillTemplateCategory.electricity:
        final company = getCompanyByCity(_selectedCity!);
        return company != null ? [company.shortName] : [];
      case BillTemplateCategory.water:
        final utility = getWaterUtilityByCity(_selectedCity!);
        return utility != null ? [utility.shortName] : [];
      case BillTemplateCategory.gas:
        final gasCompany = getNaturalGasCompanyByCity(_selectedCity!);
        return gasCompany != null ? [gasCompany.shortName] : [];
      case BillTemplateCategory.internet:
        return internetProviders.map((p) => p.shortName).toList();
      case BillTemplateCategory.phone:
        return ['Türk Telekom', 'Vodafone', 'Turkcell'];
      default:
        return [];
    }
  }

  Future<void> _saveBill() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm gerekli alanları doldurun'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);

      // 1. Önce template var mı kontrol et
      final templates = await _templateService.getTemplates();
      final existingTemplate = templates.where((t) =>
          t.name == _nameController.text &&
          t.provider == _selectedProvider &&
          t.category == _selectedCategory).firstOrNull;

      String templateId;
      if (existingTemplate != null) {
        // Varolan template'i kullan
        templateId = existingTemplate.id;
      } else {
        // Yeni template oluştur
        final template = await _templateService.addTemplate(
          name: _nameController.text,
          provider: _selectedProvider,
          category: _selectedCategory!,
          accountNumber: _accountController.text.isEmpty ? null : _accountController.text,
          phoneNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        );
        templateId = template.id;
      }

      // 2. Payment oluştur
      final now = DateTime.now();
      final periodStart = DateTime(now.year, now.month, 1);
      final periodEnd = DateTime(now.year, now.month + 1, 0);

      await _paymentService.addPayment(
        templateId: templateId,
        amount: amount,
        dueDate: _dueDate,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fatura başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fatura eklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fatura Ekle'),
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
      ),
      body: _buildStepContent(),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildCitySelection();
      case 1:
        return _buildCategorySelection();
      case 2:
        return _buildProviderSelection();
      case 3:
        return _buildDetailsForm();
      default:
        return const SizedBox();
    }
  }

  Widget _buildCitySelection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'İl Seçimi',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Faturanızın hangi ile ait olduğunu seçin',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _cities.length,
            itemBuilder: (context, index) {
              final city = _cities[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(city),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    setState(() {
                      _selectedCity = city;
                      _currentStep = 1;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _currentStep = 0),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kategori Seçimi',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _selectedCity ?? '',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: BillTemplateCategory.values.map((category) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(_getCategoryIcon(category), size: 32),
                  title: Text(_getCategoryText(category)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                      final providers = _getProvidersByCategory();
                      if (providers.isEmpty) {
                        _currentStep = 3;
                      } else {
                        _currentStep = 2;
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProviderSelection() {
    final providers = _getProvidersByCategory();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _currentStep = 1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Şirket Seçimi',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$_selectedCity - ${_getCategoryText(_selectedCategory!)}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: providers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Bu il için ${_getCategoryText(_selectedCategory!)} sağlayıcısı bulunamadı',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() => _currentStep = 3),
                        child: const Text('Manuel Devam Et'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(provider),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          setState(() {
                            _selectedProvider = provider;
                            _nameController.text =
                                '${_getCategoryText(_selectedCategory!)} - $provider';
                            _currentStep = 3;
                          });
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDetailsForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  final providers = _getProvidersByCategory();
                  setState(() => _currentStep = providers.isEmpty ? 1 : 2);
                },
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Fatura Detayları',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Fatura Adı *',
              hintText: 'Örn: Elektrik Faturası',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Fatura adı gerekli';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Fatura Tutarı *',
              hintText: '0.00',
              border: OutlineInputBorder(),
              prefixText: '₺ ',
              prefixIcon: Icon(Icons.payments),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Tutar gerekli';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Geçerli bir tutar girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                locale: const Locale('tr', 'TR'),
              );
              if (picked != null) {
                setState(() => _dueDate = picked);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Son Ödeme Tarihi *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd MMMM yyyy', 'tr_TR').format(_dueDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _accountController,
            decoration: const InputDecoration(
              labelText: 'Hesap/Abone Numarası',
              hintText: 'Opsiyonel',
              border: OutlineInputBorder(),
            ),
          ),
          if (_selectedCategory == BillTemplateCategory.phone) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'GSM Numarası',
                hintText: '5XX XXX XX XX',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Açıklama',
              hintText: 'Opsiyonel',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveBill,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Fatura Ekle',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
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

  String _getCategoryText(BillTemplateCategory category) {
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
