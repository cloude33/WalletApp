import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/debt.dart';
import '../services/debt_service.dart';

class AddDebtScreen extends StatefulWidget {
  const AddDebtScreen({super.key});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final DebtService _debtService = DebtService();

  final _personNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DebtType _selectedType = DebtType.lent;
  DebtCategory _selectedCategory = DebtCategory.friend;
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _personNameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('tr', 'TR'),
    );

    if (date != null) {
      setState(() => _selectedDueDate = date);
    }
  }

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));

      await _debtService.addDebt(
        personName: _personNameController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        amount: amount,
        type: _selectedType,
        category: _selectedCategory,
        dueDate: _selectedDueDate,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Borç/alacak kaydedildi')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Borç/Alacak'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 24),
            _buildPersonNameField(),
            const SizedBox(height: 16),
            _buildPhoneField(),
            const SizedBox(height: 16),
            _buildAmountField(),
            const SizedBox(height: 16),
            _buildCategorySelector(),
            const SizedBox(height: 16),
            _buildDueDateSelector(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Borç Tipi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTypeOption(
                    DebtType.lent,
                    'Borç Verdim',
                    'Alacak',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeOption(
                    DebtType.borrowed,
                    'Borç Aldım',
                    'Borç',
                    Icons.trending_down,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(
    DebtType type,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey[800],
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonNameField() {
    return TextFormField(
      controller: _personNameController,
      decoration: InputDecoration(
        labelText: 'Kişi Adı *',
        hintText: 'Örn: Ahmet Yılmaz',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Kişi adı gerekli';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      decoration: InputDecoration(
        labelText: 'Telefon',
        hintText: '0555 123 45 67',
        prefixIcon: const Icon(Icons.phone),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s\(\)]')),
      ],
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'Tutar *',
        hintText: '0.00',
        prefixIcon: const Icon(Icons.attach_money),
        suffixText: '₺',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Tutar gerekli';
        }
        final amount = double.tryParse(value.replaceAll(',', '.'));
        if (amount == null || amount <= 0) {
          return 'Geçerli bir tutar girin';
        }
        return null;
      },
    );
  }

  Widget _buildCategorySelector() {
    return DropdownButtonFormField<DebtCategory>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Kategori',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: DebtCategory.values.map((category) {
        String label;
        IconData icon;

        switch (category) {
          case DebtCategory.friend:
            label = 'Arkadaş';
            icon = Icons.people;
            break;
          case DebtCategory.family:
            label = 'Aile';
            icon = Icons.family_restroom;
            break;
          case DebtCategory.business:
            label = 'İş';
            icon = Icons.business;
            break;
          case DebtCategory.other:
            label = 'Diğer';
            icon = Icons.more_horiz;
            break;
        }

        return DropdownMenuItem(
          value: category,
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedCategory = value);
        }
      },
    );
  }

  Widget _buildDueDateSelector() {
    return InkWell(
      onTap: _selectDueDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Vade Tarihi',
          prefixIcon: const Icon(Icons.calendar_today),
          suffixIcon: _selectedDueDate != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _selectedDueDate = null),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _selectedDueDate != null
              ? DateFormat('dd.MM.yyyy').format(_selectedDueDate!)
              : 'Vade tarihi seçin (opsiyonel)',
          style: TextStyle(
            color: _selectedDueDate != null ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Açıklama',
        hintText: 'Ek bilgiler...',
        prefixIcon: const Icon(Icons.notes),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveDebt,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text(
              'Kaydet',
              style: TextStyle(fontSize: 16),
            ),
    );
  }
}
