import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/credit_card.dart';
import '../services/payment_simulator_service.dart';

class PaymentPlannerScreen extends StatefulWidget {
  final CreditCard card;

  const PaymentPlannerScreen({super.key, required this.card});

  @override
  State<PaymentPlannerScreen> createState() => _PaymentPlannerScreenState();
}

class _PaymentPlannerScreenState extends State<PaymentPlannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final PaymentSimulatorService _simulatorService = PaymentSimulatorService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  late TextEditingController _amountController;

  bool _isLoading = true;
  bool _isSimulating = false;
  double _currentDebt = 0;
  Map<String, dynamic>? _customSimulation;
  Map<String, dynamic>? _minimumSimulation;
  Map<String, dynamic>? _fullPaymentSimulation;
  Map<String, dynamic>? _earlyPayoffSimulation;
  String _selectedPaymentType = 'custom';

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
      final minimumSim = await _simulatorService.simulateMinimumPayment(
        widget.card.id,
      );
      final fullSim = await _simulatorService.simulateFullPayment(
        widget.card.id,
      );
      final earlyPayoffSim = await _simulatorService.simulateEarlyPayoff(
        widget.card.id,
      );

      setState(() {
        _currentDebt = minimumSim['currentDebt'] as double;
        _minimumSimulation = minimumSim;
        _fullPaymentSimulation = fullSim;
        _earlyPayoffSimulation = earlyPayoffSim;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _simulateCustomPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSimulating = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      
      final simulation = await _simulatorService.simulatePayment(
        cardId: widget.card.id,
        paymentAmount: amount,
      );

      final interestSavings = await _simulatorService.calculateInterestSavings(
        cardId: widget.card.id,
        proposedPayment: amount,
      );

      setState(() {
        _customSimulation = {
          'paymentAmount': amount,
          'remainingDebt': simulation.remainingDebt,
          'interestCharged': simulation.interestCharged,
          'monthsToPayoff': simulation.monthsToPayoff,
          'totalCost': simulation.totalCost,
          'interestSavings': interestSavings,
        };
        _selectedPaymentType = 'custom';
        _isSimulating = false;
      });
    } catch (e) {
      setState(() => _isSimulating = false);
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
        title: const Text('Ödeme Planlayıcı'),
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
                      _buildCardInfo(),
                      const SizedBox(height: 16),
                      _buildCurrentDebtCard(),
                      const SizedBox(height: 24),
                      _buildPaymentInputSection(),
                      const SizedBox(height: 24),
                      _buildQuickOptionsSection(),
                      const SizedBox(height: 24),
                      _buildComparisonSection(),
                      const SizedBox(height: 24),
                      _buildEarlyPayoffSection(),
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
              'Bu kart için borç bulunmamaktadır.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardInfo() {
    return Card(
      color: widget.card.color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.credit_card, color: widget.card.color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.card.bankName} ${widget.card.cardName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '•••• ${widget.card.last4Digits}',
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
              'Aylık Faiz Oranı: %${widget.card.monthlyInterestRate.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInputSection() {
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
              decoration: const InputDecoration(
                labelText: 'Ödeme Tutarı',
                hintText: '0.00',
                prefixIcon: Icon(Icons.attach_money),
                suffixText: '₺',
                border: OutlineInputBorder(),
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
                if (amount > _currentDebt) {
                  return 'Tutar mevcut borçtan fazla olamaz';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSimulating ? null : _simulateCustomPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSimulating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simüle Et'),
              ),
            ),
            if (_customSimulation != null) ...[
              const SizedBox(height: 16),
              _buildSimulationResult(_customSimulation!, 'Özel Ödeme'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hızlı Seçenekler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildQuickOption(
              title: 'Asgari Ödeme',
              subtitle: _minimumSimulation != null
                  ? _currencyFormat.format(
                      _minimumSimulation!['minimumPayment'] as double,
                    )
                  : '...',
              icon: Icons.trending_down,
              color: Colors.orange,
              onTap: () {
                setState(() {
                  _selectedPaymentType = 'minimum';
                });
              },
              isSelected: _selectedPaymentType == 'minimum',
            ),
            const SizedBox(height: 12),
            _buildQuickOption(
              title: 'Tam Ödeme',
              subtitle: _fullPaymentSimulation != null
                  ? _currencyFormat.format(
                      _fullPaymentSimulation!['fullPayment'] as double,
                    )
                  : '...',
              icon: Icons.check_circle,
              color: Colors.green,
              onTap: () {
                setState(() {
                  _selectedPaymentType = 'full';
                });
              },
              isSelected: _selectedPaymentType == 'full',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonSection() {
    if (_selectedPaymentType == 'custom' && _customSimulation == null) {
      return const SizedBox.shrink();
    }

    Map<String, dynamic>? selectedSimulation;
    String title = '';

    switch (_selectedPaymentType) {
      case 'minimum':
        selectedSimulation = _minimumSimulation;
        title = 'Asgari Ödeme Simülasyonu';
        break;
      case 'full':
        selectedSimulation = _fullPaymentSimulation;
        title = 'Tam Ödeme Simülasyonu';
        break;
      case 'custom':
        selectedSimulation = _customSimulation;
        title = 'Özel Ödeme Simülasyonu';
        break;
    }

    if (selectedSimulation == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSimulationResult(selectedSimulation, title),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationResult(
    Map<String, dynamic> simulation,
    String title,
  ) {
    final remainingDebt = simulation['remainingDebt'] as double? ?? 0.0;
    final interestCharged = simulation['interestCharged'] as double? ?? 0.0;
    final monthsToPayoff = simulation['monthsToPayoff'] as int? ?? 0;
    final totalCost = simulation['totalCost'] as double? ?? 0.0;
    final interestSavings = simulation['interestSavings'] as double? ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _buildResultRow(
            'Kalan Borç',
            _currencyFormat.format(remainingDebt),
            remainingDebt > 0 ? Colors.orange : Colors.green,
          ),
          const Divider(height: 24),
          _buildResultRow(
            'Aylık Faiz',
            _currencyFormat.format(interestCharged),
            Colors.red,
          ),
          const Divider(height: 24),
          _buildResultRow(
            'Kapanış Süresi',
            monthsToPayoff == -1
                ? 'Kapatılamaz'
                : monthsToPayoff == 0
                    ? 'Hemen'
                    : '$monthsToPayoff ay',
            monthsToPayoff > 12 ? Colors.red : Colors.green,
          ),
          const Divider(height: 24),
          _buildResultRow(
            'Toplam Maliyet',
            _currencyFormat.format(totalCost),
            Colors.blue,
          ),
          if (interestSavings > 0) ...[
            const Divider(height: 24),
            _buildResultRow(
              'Faiz Tasarrufu',
              _currencyFormat.format(interestSavings),
              Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEarlyPayoffSection() {
    if (_earlyPayoffSimulation == null) {
      return const SizedBox.shrink();
    }

    final interestSaved = _earlyPayoffSimulation!['interestSaved'] as double;
    final monthsSaved = _earlyPayoffSimulation!['monthsSaved'] as int;

    if (interestSaved <= 0) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.green.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'Erken Kapatma Önerisi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Borcunuzu şimdi kapatarak:',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.savings, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_currencyFormat.format(interestSaved)} faiz tasarrufu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$monthsSaved ay zaman tasarrufu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildResultRow(
                    'Asgari Ödeme ile Toplam',
                    _currencyFormat.format(
                      _earlyPayoffSimulation!['minimumPaymentTotalCost'],
                    ),
                    Colors.red,
                  ),
                  const Divider(height: 16),
                  _buildResultRow(
                    'Erken Kapatma ile Toplam',
                    _currencyFormat.format(
                      _earlyPayoffSimulation!['fullPaymentTotalCost'],
                    ),
                    Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
