import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/recurrence_frequency.dart';
import '../models/recurring_template.dart';
import '../services/recurring_transaction_service.dart';
import '../services/recurring_template_service.dart';

class AddRecurringTransactionScreen extends StatefulWidget {
  final RecurringTransactionService service;
  final RecurringTemplateService? templateService;

  const AddRecurringTransactionScreen({
    super.key,
    required this.service,
    this.templateService,
  });

  @override
  State<AddRecurringTransactionScreen> createState() =>
      _AddRecurringTransactionScreenState();
}

class _AddRecurringTransactionScreenState
    extends State<AddRecurringTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int? _occurrenceCount;
  bool _isIncome = false;
  bool _notificationEnabled = true;
  int? _reminderDaysBefore;
  bool _showTemplates = true;

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
      appBar: AppBar(title: const Text('Yeni Tekrarlayan İşlem')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showTemplates && widget.templateService != null)
                _buildTemplateSection(),
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
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateSection() {
    final templates = RecurringTemplate.getDefaultTemplates();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Şablonlar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _showTemplates = false;
                });
              },
              child: const Text('Manuel Giriş'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return InkWell(
              onTap: () => _applyTemplate(template),
              borderRadius: BorderRadius.circular(12),
              child: Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      template.icon ?? '📝',
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.name,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
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
              initialValue: _frequency,
              decoration: const InputDecoration(border: OutlineInputBorder()),
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
              title: const Text('Başlangıç Tarihi ve Saati'),
              subtitle: Text(_formatDateWithTime(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                await _selectDateTime(context, true);
              },
            ),
            ListTile(
              title: const Text('Bitiş Tarihi (Opsiyonel)'),
              subtitle: Text(
                _endDate != null ? dateFormat.format(_endDate!) : 'Belirsiz',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      _endDate ?? _startDate.add(const Duration(days: 365)),
                  firstDate: _startDate,
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (date != null) {
                  setState(() {
                    _endDate = date;
                    _occurrenceCount = null;
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

  void _applyTemplate(RecurringTemplate template) {
    setState(() {
      _titleController.text = template.name;
      _categoryController.text = template.category;
      _frequency = template.defaultFrequency;
      _isIncome = template.isIncome;
      _showTemplates = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await widget.service.create(
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        category: _categoryController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        frequency: _frequency,
        startDate: _startDate,
        endDate: _endDate,
        occurrenceCount: _occurrenceCount,
        isIncome: _isIncome,
        notificationEnabled: _notificationEnabled,
        reminderDaysBefore: _reminderDaysBefore,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  String _formatDateWithTime(DateTime date) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');

    return '${date.day} ${months[date.month - 1]} ${date.year} $hours:$minutes';
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartDate) async {
    DateTime initialDate = isStartDate ? _startDate : (_endDate ?? _startDate);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 400,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'İptal',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const Text(
                      'Tarih ve Saat Seç',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Tamam',
                        style: TextStyle(
                          color: Color(0xFF5E5CE6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime:
                            initialDate.isBefore(
                              isStartDate ? DateTime.now() : _startDate,
                            )
                            ? (isStartDate ? DateTime.now() : _startDate)
                            : initialDate,
                        minimumDate: isStartDate ? DateTime.now() : _startDate,
                        maximumDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                        onDateTimeChanged: (DateTime newDate) {
                          setState(() {
                            if (isStartDate) {
                              _startDate = DateTime(
                                newDate.year,
                                newDate.month,
                                newDate.day,
                                _startDate.hour,
                                _startDate.minute,
                              );
                            } else {
                              _endDate = DateTime(
                                newDate.year,
                                newDate.month,
                                newDate.day,
                                _endDate?.hour ?? _startDate.hour,
                                _endDate?.minute ?? _startDate.minute,
                              );
                            }
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      height: 100,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime:
                            initialDate.isBefore(
                              isStartDate ? DateTime.now() : _startDate,
                            )
                            ? (isStartDate ? DateTime.now() : _startDate)
                            : initialDate,
                        use24hFormat: true,
                        onDateTimeChanged: (DateTime newTime) {
                          setState(() {
                            if (isStartDate) {
                              _startDate = DateTime(
                                _startDate.year,
                                _startDate.month,
                                _startDate.day,
                                newTime.hour,
                                newTime.minute,
                              );
                            } else if (_endDate != null) {
                              _endDate = DateTime(
                                _endDate!.year,
                                _endDate!.month,
                                _endDate!.day,
                                newTime.hour,
                                newTime.minute,
                              );
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
