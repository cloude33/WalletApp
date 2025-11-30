import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../services/data_service.dart';
import 'package:uuid/uuid.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _currentController = TextEditingController(text: '0');
  final DataService _dataService = DataService();
  DateTime? _selectedDate;

  Future<void> _saveGoal() async {
    if (_formKey.currentState!.validate()) {
      final uuid = Uuid();
      final goal = Goal(
        id: uuid.v4(),
        name: _nameController.text,
        targetAmount: double.parse(_targetController.text),
        currentAmount: double.parse(_currentController.text),
        deadline: _selectedDate,
      );

      await _dataService.addGoal(goal);

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
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
                      'Yeni Hedef',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
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
                      const Text('Hedef Adı', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Örn: Araba almak, Tatil',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen hedef adı girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text('Hedef Tutar', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _targetController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: '₺ ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen hedef tutar girin';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Geçerli bir sayı girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text('Mevcut Tutar', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _currentController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: '₺ ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen mevcut tutar girin';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Geçerli bir sayı girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text('Son Tarih (Opsiyonel)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDate == null
                                    ? 'Tarih seçin'
                                    : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                                style: TextStyle(
                                  color: _selectedDate == null ? Colors.grey : Colors.black,
                                ),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveGoal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5E5CE6),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Hedef Oluştur',
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

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    super.dispose();
  }
}
