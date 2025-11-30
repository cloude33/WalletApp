import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/loan.dart';
import '../models/wallet.dart';
import '../services/data_service.dart';

class AddLoanScreen extends StatefulWidget {
  final List<Wallet> wallets;

  const AddLoanScreen({super.key, required this.wallets});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final DataService _dataService = DataService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _installmentCountController =
      TextEditingController();
  String? _selectedWalletId;
  DateTime _startDate = DateTime.now();
  final int _installmentPeriod = 30; // days between installments

  @override
  void initState() {
    super.initState();
    if (widget.wallets.isNotEmpty) {
      _selectedWalletId = widget.wallets.first.id;
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _saveLoan() async {
    if (_nameController.text.isEmpty ||
        _bankNameController.text.isEmpty ||
        _totalAmountController.text.isEmpty ||
        _installmentCountController.text.isEmpty ||
        _selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    final totalAmount =
        double.tryParse(
          _totalAmountController.text.replaceAll('.', '').replaceAll(',', '.'),
        ) ??
        0.0;
    final installmentCount =
        int.tryParse(_installmentCountController.text) ?? 1;

    if (totalAmount <= 0 || installmentCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçerli bir miktar ve taksit sayısı girin'),
        ),
      );
      return;
    }

    final installmentAmount = totalAmount / installmentCount;
    final endDate = _startDate.add(
      Duration(days: _installmentPeriod * (installmentCount - 1)),
    );

    // Create loan installments
    final List<LoanInstallment> installments = [];
    for (int i = 0; i < installmentCount; i++) {
      installments.add(
        LoanInstallment(
          installmentNumber: i + 1,
          amount: installmentAmount,
          dueDate: _startDate.add(Duration(days: _installmentPeriod * i)),
        ),
      );
    }

    final loan = Loan(
      id: const Uuid().v4(),
      name: _nameController.text,
      bankName: _bankNameController.text,
      totalAmount: totalAmount,
      remainingAmount: totalAmount,
      totalInstallments: installmentCount,
      remainingInstallments: installmentCount,
      currentInstallment: 0,
      installmentAmount: installmentAmount,
      startDate: _startDate,
      endDate: endDate,
      walletId: _selectedWalletId!,
      installments: installments,
    );

    await _dataService.addLoan(loan);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kredi Ekle'),
        backgroundColor: const Color(0xFF5E5CE6),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kredi Bilgileri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Kredi Adı',
                border: OutlineInputBorder(),
                hintText: 'Örn: Konut Kredisi, Taşıt Kredisi',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bankNameController,
              decoration: const InputDecoration(
                labelText: 'Banka Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _totalAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Toplam Kredi Tutarı',
                border: OutlineInputBorder(),
                prefixText: '₺ ',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _installmentCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Taksit Sayısı',
                border: OutlineInputBorder(),
                hintText: 'Örn: 36, 48, 60',
              ),
            ),
            const SizedBox(height: 16),
            _buildWalletSelector(),
            const SizedBox(height: 16),
            _buildDateSelector(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveLoan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5E5CE6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Krediyi Kaydet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cüzdan Seçin',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedWalletId,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              hint: const Text('Bir cüzdan seçin'),
              items: widget.wallets.map((wallet) {
                return DropdownMenuItem(
                  value: wallet.id,
                  child: Text(wallet.name),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedWalletId = value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Başlangıç Tarihi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectStartDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(_startDate),
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.calendar_today, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _totalAmountController.dispose();
    _installmentCountController.dispose();
    super.dispose();
  }
}
