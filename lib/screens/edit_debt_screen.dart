import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/debt.dart';
import '../services/debt_service.dart';

class EditDebtScreen extends StatefulWidget {
  final Debt debt;

  const EditDebtScreen({super.key, required this.debt});

  @override
  State<EditDebtScreen> createState() => _EditDebtScreenState();
}

class _EditDebtScreenState extends State<EditDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final DebtService _debtService = DebtService();

  late TextEditingController _personNameController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;

  late DebtCategory _selectedCategory;
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _personNameController = TextEditingController(text: widget.debt.personName);
    _phoneController = TextEditingController(text: widget.debt.phone ?? '');
    _descriptionController = TextEditingController(
      text: widget.debt.description ?? '',
    );
    _selectedCategory = widget.debt.category;
    _selectedDueDate = widget.debt.dueDate;
  }

  @override
  void dispose() {
    _personNameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedDueDate ?? DateTime.now().add(const Duration(days: 30)),
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
      final updatedDebt = widget.debt.copyWith(
        personName: _personNameController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        category: _selectedCategory,
        dueDate: _selectedDueDate,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );

      await _debtService.updateDebt(updatedDebt);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Borç/alacak güncellendi')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borç/Alacak Düzenle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPersonNameField(),
            const SizedBox(height: 16),
            _buildPhoneField(),
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

  Widget _buildPersonNameField() {
    return TextFormField(
      controller: _personNameController,
      decoration: InputDecoration(
        labelText: 'Kişi Adı *',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
        prefixIcon: const Icon(Icons.phone),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s\(\)]')),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return DropdownButtonFormField<DebtCategory>(
      initialValue: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Kategori',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
        prefixIcon: const Icon(Icons.notes),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Güncelle', style: TextStyle(fontSize: 16)),
    );
  }
}
