import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/bill_template.dart';
import '../services/bill_template_service.dart';

class AddBillTemplateScreen extends StatefulWidget {
  final BillTemplate? template; // null ise yeni, değilse düzenleme

  const AddBillTemplateScreen({super.key, this.template});

  @override
  State<AddBillTemplateScreen> createState() => _AddBillTemplateScreenState();
}

class _AddBillTemplateScreenState extends State<AddBillTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  final BillTemplateService _service = BillTemplateService();

  late TextEditingController _nameController;
  late TextEditingController _providerController;
  late TextEditingController _accountNumberController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _descriptionController;

  BillTemplateCategory _selectedCategory = BillTemplateCategory.electricity;
  bool _isActive = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final template = widget.template;
    
    _nameController = TextEditingController(text: template?.name ?? '');
    _providerController = TextEditingController(text: template?.provider ?? '');
    _accountNumberController = TextEditingController(text: template?.accountNumber ?? '');
    _phoneNumberController = TextEditingController(text: template?.phoneNumber ?? '');
    _descriptionController = TextEditingController(text: template?.description ?? '');
    
    if (template != null) {
      _selectedCategory = template.category;
      _isActive = template.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _providerController.dispose();
    _accountNumberController.dispose();
    _phoneNumberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.template != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Fatura Düzenle' : 'Fatura Ekle'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildNameField(),
                  const SizedBox(height: 16),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),
                  _buildProviderField(),
                  const SizedBox(height: 16),
                  _buildAccountNumberField(),
                  const SizedBox(height: 16),
                  if (_selectedCategory == BillTemplateCategory.phone)
                    _buildPhoneNumberField(),
                  if (_selectedCategory == BillTemplateCategory.phone)
                    const SizedBox(height: 16),
                  _buildDescriptionField(),
                  const SizedBox(height: 16),
                  _buildActiveSwitch(),
                  const SizedBox(height: 32),
                  _buildSaveButton(isEdit),
                  if (isEdit) ...[
                    const SizedBox(height: 16),
                    _buildDeleteButton(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Fatura Adı',
        hintText: 'Örn: Ev Elektriği',
        prefixIcon: Icon(Icons.label),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Fatura adı gerekli';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<BillTemplateCategory>(
      initialValue: _selectedCategory,
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
          });
        }
      },
    );
  }

  Widget _buildProviderField() {
    return TextFormField(
      controller: _providerController,
      decoration: InputDecoration(
        labelText: 'Sağlayıcı (Opsiyonel)',
        hintText: _getProviderHint(),
        prefixIcon: const Icon(Icons.business),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildAccountNumberField() {
    return TextFormField(
      controller: _accountNumberController,
      decoration: const InputDecoration(
        labelText: 'Abone/Hesap Numarası (Opsiyonel)',
        hintText: 'Fatura üzerindeki numara',
        prefixIcon: Icon(Icons.numbers),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return TextFormField(
      controller: _phoneNumberController,
      decoration: const InputDecoration(
        labelText: 'Telefon Numarası',
        hintText: '5XX XXX XX XX',
        prefixIcon: Icon(Icons.phone),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.phone,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Açıklama (Opsiyonel)',
        hintText: 'Ek notlar',
        prefixIcon: Icon(Icons.note),
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildActiveSwitch() {
    return SwitchListTile(
      title: const Text('Aktif'),
      subtitle: const Text('Pasif faturalar ana ekranda görünmez'),
      value: _isActive,
      activeTrackColor: const Color(0xFF00BFA5).withValues(alpha: 0.5),
      activeThumbColor: const Color(0xFF00BFA5),
      onChanged: (value) {
        setState(() {
          _isActive = value;
        });
      },
    );
  }

  Widget _buildSaveButton(bool isEdit) {
    return ElevatedButton(
      onPressed: _saveTemplate,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        isEdit ? 'Güncelle' : 'Kaydet',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return OutlinedButton(
      onPressed: _deleteTemplate,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'Sil',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    try {
      final now = DateTime.now();
      final template = BillTemplate(
        id: widget.template?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        provider: _providerController.text.trim().isEmpty 
            ? null 
            : _providerController.text.trim(),
        category: _selectedCategory,
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
        createdDate: widget.template?.createdDate ?? now,
        updatedDate: now,
      );

      if (widget.template == null) {
        await _service.createTemplate(template);
      } else {
        await _service.updateTemplate(template);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.template == null
                  ? 'Fatura şablonu oluşturuldu'
                  : 'Fatura şablonu güncellendi',
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
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteTemplate() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fatura Şablonunu Sil'),
        content: const Text(
          'Bu fatura şablonunu silmek istediğinizden emin misiniz?\n\n'
          'Not: Geçmiş fatura ödemeleri silinmeyecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || widget.template == null) return;

    setState(() => _loading = true);

    try {
      await _service.deleteTemplate(widget.template!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fatura şablonu silindi'),
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
        setState(() => _loading = false);
      }
    }
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

  String _getProviderHint() {
    switch (_selectedCategory) {
      case BillTemplateCategory.electricity:
        return 'Örn: TOROSLAR EDAŞ';
      case BillTemplateCategory.water:
        return 'Örn: ASKİ';
      case BillTemplateCategory.gas:
        return 'Örn: İGDAŞ';
      case BillTemplateCategory.internet:
        return 'Örn: Türk Telekom';
      case BillTemplateCategory.phone:
        return 'Örn: Turkcell, Vodafone';
      case BillTemplateCategory.rent:
        return 'Ev sahibinin adı';
      case BillTemplateCategory.insurance:
        return 'Örn: Anadolu Sigorta';
      case BillTemplateCategory.subscription:
        return 'Örn: Netflix, Spotify';
      default:
        return 'Sağlayıcı adı';
    }
  }
}
