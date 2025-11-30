import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recurrence_frequency.dart';
import '../models/recurring_transaction.dart';
import '../services/recurring_transaction_service.dart';

class EditRecurringTransactionScreen extends StatefulWidget {
  final RecurringTransaction transaction;
  final RecurringTransactionService service;

  const EditRecurringTransactionScreen({
    super.key,
    required this.transaction,
    required this.service,
  });

  @override
  State<EditRecurringTransactionScreen> createState() =>
      _EditRecurringTransactionScreenState();
}

class _EditRecurringTransactionScreenState
    extends State<EditRecurringTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;

  late RecurrenceFrequency _frequency;
  late DateTime _startDate;
  DateTime? _endDate;
  int? _occurrenceCount;
  late bool _isIncome;
  late bool _notificationEnabled;
  int? _reminderDaysBefore;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _titleController = TextEditingController(text: t.title);
    _amountController = TextEditingController(text: t.amount.toString());
    _categoryController = TextEditingController(text: t.category);
    _descriptionController = TextEditingController(text: t.description ?? '');
    _frequency = t.frequency;
    _startDate = t.startDate;
    _endDate = t.endDate;
    _occurrenceCount = t.occurrenceCount;
    _isIncome = t.isIncome;
    _notificationEnabled = t.notificationEnabled;
    _reminderDaysBefore = t.reminderDaysBefore;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşlemi Düzenle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.orange[50],
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Değişiklikler sadece gelecekteki işlemleri etkiler. '
                          'Geçmiş işlemler değişmez.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildBasicInfo(),
              const SizedBox(height: 16),
              _buildFrequencySection(),
              const SizedBox(height: 16),
              _buildDateSection(),
              const SizedBox(height: 16),
              _buildNotificationSection(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Güncelle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Temel Bilgiler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Başlık',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Başlık gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Tutar',
                border: OutlineInputBorder(),
                suffixText: '₺',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tutar gerekli';
                }
                if (double.tryParse(value) == null) {
                  return 'Geçerli bir tutar girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kategori gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama (Opsiyonel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Gelir'),
              value: _isIncome,
              onChanged: (value) {
                setState(() {
                  _isIncome = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tekrar Sıklığı',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RecurrenceFrequency>(
              value: _frequency,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: RecurrenceFrequency.values.map((freq) {
                return DropdownMenuItem(
                  value: freq,
                  child: Text(freq.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _frequency = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    final dateFormat = DateFormat('dd MMMM yyyy', 'tr_TR');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tarih Ayarları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Başlangıç Tarihi'),
              subtitle: Text(dateFormat.format(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              enabled: false,
            ),
            ListTile(
              title: const Text('Bitiş Tarihi (Opsiyonel)'),
              subtitle: Text(_endDate != null
                  ? dateFormat.format(_endDate!)
                  : 'Belirsiz'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (date != null) {
                  setState(() {
                    _endDate = date;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bildirim Ayarları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SwitchListTile(
              title: const Text('Bildirimleri Etkinleştir'),
              value: _notificationEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationEnabled = value;
                });
              },
            ),
            if (_notificationEnabled) ...[
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _reminderDaysBefore?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Kaç gün önce hatırlat (Opsiyonel)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _reminderDaysBefore = int.tryParse(value);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      widget.transaction.title = _titleController.text;
      widget.transaction.amount = double.parse(_amountController.text);
      widget.transaction.category = _categoryController.text;
      widget.transaction.description = _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text;
      widget.transaction.frequency = _frequency;
      widget.transaction.endDate = _endDate;
      widget.transaction.isIncome = _isIncome;
      widget.transaction.notificationEnabled = _notificationEnabled;
      widget.transaction.reminderDaysBefore = _reminderDaysBefore;

      await widget.service.update(widget.transaction);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }
}
