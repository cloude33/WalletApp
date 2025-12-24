import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/wallet.dart';
import '../models/payment_scenario.dart';
import '../services/payment_planner_service.dart';
import '../services/kmh_interest_calculator.dart';

class KmhPaymentPlannerScreen extends StatefulWidget {
  final Wallet account;

  const KmhPaymentPlannerScreen({super.key, required this.account});

  @override
  State<KmhPaymentPlannerScreen> createState() =>
      _KmhPaymentPlannerScreenState();
}

class _KmhPaymentPlannerScreenState extends State<KmhPaymentPlannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final PaymentPlannerService _plannerService = PaymentPlannerService();
  final KmhInterestCalculator _calculator = KmhInterestCalculator();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  late TextEditingController _amountController;

  bool _isLoading = true;
  bool _isCalculating = false;
  double _currentDebt = 0;
  double _monthlyInterest = 0;
  double _annualRate = 24.0;
  List<PaymentScenario> _scenarios = [];
  PaymentScenario? _customScenario;
  PaymentScenario? _selectedScenario;
  String _reminderSchedule = 'monthly';

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _loadInitialData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      _currentDebt = widget.account.usedCredit;
      _annualRate = widget.account.interestRate ?? 24.0;
      _monthlyInterest = _calculator.estimateMonthlyInterest(
        balance: -_currentDebt,
        annualRate: _annualRate,
        days: 30,
      );
      _scenarios = _plannerService.generatePaymentScenarios(
        account: widget.account,
      );
      _selectedScenario = _scenarios.firstWhere(
        (s) => s.isRecommended,
        orElse: () => _scenarios.isNotEmpty ? _scenarios[0] : _scenarios.first,
      );

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _calculateCustomPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isCalculating = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));

      final plan = _plannerService.calculatePaymentPlan(
        account: widget.account,
        monthlyPayment: amount,
      );

      if (plan == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu ödeme tutarı ile borç kapatılamaz'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isCalculating = false);
        return;
      }

      setState(() {
        _customScenario = PaymentScenario(
          name: 'Özel Ödeme',
          monthlyPayment: plan.monthlyPayment,
          durationMonths: plan.durationMonths,
          totalInterest: plan.totalInterest,
          totalPayment: plan.totalPayment,
        );
        _selectedScenario = _customScenario;
        _isCalculating = false;
      });
    } catch (e) {
      setState(() => _isCalculating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _savePaymentPlan() async {
    if (_selectedScenario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir ödeme planı seçin')),
      );
      return;
    }

    try {
      final plan = _plannerService.createPaymentPlanWithReminder(
        account: widget.account,
        monthlyPayment: _selectedScenario!.monthlyPayment,
        reminderSchedule: _reminderSchedule,
      );

      if (plan == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ödeme planı oluşturulamadı'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      await _plannerService.savePaymentPlan(plan);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ödeme planı kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, plan);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Planı'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentDebt <= 0
              ? _buildNoDebtView()
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildAccountInfo(),
                      const SizedBox(height: 16),
                      _buildCurrentDebtCard(),
                      const SizedBox(height: 24),
                      _buildCustomPaymentSection(),
                      const SizedBox(height: 24),
                      _buildScenariosSection(),
                      const SizedBox(height: 24),
                      if (_selectedScenario != null) ...[
                        _buildSelectedScenarioDetails(),
                        const SizedBox(height: 24),
                        _buildReminderSection(),
                        const SizedBox(height: 24),
                        _buildSaveButton(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildNoDebtView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Borç Bulunmuyor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu hesap için borç bulunmamaktadır.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfo() {
    return Card(
      color: Colors.blue.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.account_balance, color: Colors.blue, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.account.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'KMH Hesabı',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentDebtCard() {
    return Card(
      color: Colors.red.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.red[700]),
                const SizedBox(width: 8),
                const Text(
                  'Mevcut Borç',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _currencyFormat.format(_currentDebt),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aylık Faiz: ${_currencyFormat.format(_monthlyInterest)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              'Yıllık Faiz Oranı: %${_annualRate.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomPaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Özel Ödeme Tutarı',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Aylık Ödeme Tutarı',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: '₺',
                border: const OutlineInputBorder(),
                helperText:
                    'Minimum: ${_currencyFormat.format(_monthlyInterest * 1.1)}',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ödeme tutarı gerekli';
                }
                final amount = double.tryParse(value.replaceAll(',', '.'));
                if (amount == null || amount <= 0) {
                  return 'Geçerli bir tutar giriniz';
                }
                if (amount <= _monthlyInterest) {
                  return 'Tutar aylık faizden fazla olmalı';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCalculating ? null : _calculateCustomPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isCalculating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Hesapla'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenariosSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ödeme Senaryoları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._scenarios.map((scenario) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildScenarioCard(scenario),
                )),
            if (_customScenario != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildScenarioCard(_customScenario!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioCard(PaymentScenario scenario) {
    final isSelected = _selectedScenario == scenario;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedScenario = scenario;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    scenario.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (scenario.isRecommended)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Önerilen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 8),
            _buildScenarioRow(
              'Aylık Ödeme',
              _currencyFormat.format(scenario.monthlyPayment),
            ),
            _buildScenarioRow(
              'Süre',
              '${scenario.durationMonths} ay',
            ),
            _buildScenarioRow(
              'Toplam Faiz',
              _currencyFormat.format(scenario.totalInterest),
            ),
            _buildScenarioRow(
              'Toplam Ödeme',
              _currencyFormat.format(scenario.totalPayment),
            ),
            if (scenario.warning != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        scenario.warning!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedScenarioDetails() {
    if (_selectedScenario == null) return const SizedBox.shrink();

    final scenario = _selectedScenario!;
    final minScenario = _scenarios.isNotEmpty ? _scenarios.first : null;
    final hasSavings = minScenario != null && scenario != minScenario;

    return Card(
      color: Colors.green.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'Seçili Plan Detayları',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              scenario.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.calendar_today,
              'Borç ${scenario.durationMonths} ayda kapanacak',
            ),
            _buildDetailRow(
              Icons.attach_money,
              'Toplam ${_currencyFormat.format(scenario.totalPayment)} ödenecek',
            ),
            _buildDetailRow(
              Icons.trending_up,
              'Toplam ${_currencyFormat.format(scenario.totalInterest)} faiz ödenecek',
            ),
            if (hasSavings) ...[
              const Divider(height: 24),
              Text(
                'Minimum ödemeye göre:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.savings,
                '${_currencyFormat.format(scenario.totalSavingsComparedTo(minScenario))} tasarruf',
                color: Colors.green,
              ),
              _buildDetailRow(
                Icons.schedule,
                '${minScenario.durationMonths - scenario.durationMonths} ay daha erken',
                color: Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: color ?? Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ödeme Hatırlatıcısı',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _reminderSchedule,
              decoration: const InputDecoration(
                labelText: 'Hatırlatıcı Sıklığı',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notifications),
              ),
              items: const [
                DropdownMenuItem(value: 'monthly', child: Text('Aylık')),
                DropdownMenuItem(value: 'biweekly', child: Text('İki Haftada Bir')),
                DropdownMenuItem(value: 'weekly', child: Text('Haftalık')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _reminderSchedule = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _savePaymentPlan,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        child: const Text(
          'Ödeme Planını Kaydet',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
