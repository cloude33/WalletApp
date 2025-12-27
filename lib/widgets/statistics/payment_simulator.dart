import 'package:flutter/material.dart';
import '../../models/wallet.dart';
import '../../services/payment_simulator_service.dart';
import '../../utils/currency_helper.dart';

class PaymentSimulator extends StatefulWidget {
  final List<Wallet> creditCards;

  final List<Wallet> kmhAccounts;

  const PaymentSimulator({
    super.key,
    required this.creditCards,
    required this.kmhAccounts,
  });

  @override
  State<PaymentSimulator> createState() => _PaymentSimulatorState();
}

class _PaymentSimulatorState extends State<PaymentSimulator> {
  final PaymentSimulatorService _simulatorService = PaymentSimulatorService();
  final TextEditingController _customAmountController = TextEditingController();

  String? _selectedCardId;
  Map<String, dynamic>? _minimumPaymentResult;
  Map<String, dynamic>? _fullPaymentResult;
  Map<String, dynamic>? _customPaymentResult;
  Map<String, dynamic>? _recommendationResult;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.creditCards.isNotEmpty) {
      _selectedCardId = widget.creditCards.first.id;
      _loadSimulations();
    }
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadSimulations() async {
    if (_selectedCardId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _simulatorService.simulateMinimumPayment(_selectedCardId!),
        _simulatorService.simulateFullPayment(_selectedCardId!),
        _simulatorService.getPaymentRecommendation(_selectedCardId!),
      ]);

      setState(() {
        _minimumPaymentResult = results[0];
        _fullPaymentResult = results[1];
        _recommendationResult = results[2];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Simülasyon yüklenirken hata: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _simulateCustomPayment() async {
    if (_selectedCardId == null) return;

    final customAmount = double.tryParse(_customAmountController.text);
    if (customAmount == null || customAmount <= 0) {
      setState(() {
        _errorMessage = 'Geçerli bir tutar girin';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final simulation = await _simulatorService.simulatePayment(
        cardId: _selectedCardId!,
        paymentAmount: customAmount,
      );

      setState(() {
        _customPaymentResult = {
          'paymentAmount': customAmount,
          'remainingDebt': simulation.remainingDebt,
          'interestCharged': simulation.interestCharged,
          'monthsToPayoff': simulation.monthsToPayoff,
          'totalCost': simulation.totalCost,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Simülasyon hatası: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildCardSelector() {
    if (widget.creditCards.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Kredi kartı bulunamadı',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kart Seçin',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCardId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: widget.creditCards.map((card) {
                return DropdownMenuItem(value: card.id, child: Text(card.name));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCardId = value;
                  _customPaymentResult = null;
                  _customAmountController.clear();
                });
                _loadSimulations();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioCard({
    required String title,
    required Color color,
    required Map<String, dynamic>? data,
    required IconData icon,
  }) {
    if (data == null) {
      return const SizedBox.shrink();
    }

    final paymentAmount =
        (data['minimumPayment'] ??
                data['fullPayment'] ??
                data['recommendedPayment'] ??
                data['paymentAmount'])
            as double? ??
        0.0;
    final monthsToPayoff = data['monthsToPayoff'] as int? ?? 0;
    final totalCost = data['totalCost'] as double? ?? 0.0;
    final message = data['message'] as String? ?? '';

    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                'Ödeme Tutarı',
                CurrencyHelper.formatAmount(paymentAmount),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Toplam Maliyet',
                CurrencyHelper.formatAmount(totalCost),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Süre',
                monthsToPayoff == -1
                    ? 'Kapatılamaz'
                    : monthsToPayoff == 0
                    ? 'Hemen'
                    : '$monthsToPayoff ay',
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildCustomPaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Özel Tutar Simülasyonu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ödeme Tutarı',
                      border: OutlineInputBorder(),
                      prefixText: '₺ ',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _simulateCustomPayment,
                  child: const Text('Hesapla'),
                ),
              ],
            ),
            if (_customPaymentResult != null) ...[
              const SizedBox(height: 16),
              _buildScenarioCard(
                title: 'Özel Tutar',
                color: Colors.purple,
                data: _customPaymentResult,
                icon: Icons.calculate,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    if (_minimumPaymentResult == null ||
        _fullPaymentResult == null ||
        _recommendationResult == null) {
      return const SizedBox.shrink();
    }

    final scenarios = [
      {
        'name': 'Asgari Ödeme',
        'data': _minimumPaymentResult,
        'color': Colors.orange,
      },
      {'name': 'Önerilen', 'data': _recommendationResult, 'color': Colors.blue},
      {'name': 'Tam Ödeme', 'data': _fullPaymentResult, 'color': Colors.green},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Karşılaştırma Tablosu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Senaryo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Ödeme',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Süre',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Toplam',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ...scenarios.map((scenario) {
                  final data = scenario['data'] as Map<String, dynamic>;
                  final payment =
                      (data['minimumPayment'] ??
                              data['fullPayment'] ??
                              data['recommendedPayment'])
                          as double? ??
                      0.0;
                  final months = data['monthsToPayoff'] as int? ?? 0;
                  final total = data['totalCost'] as double? ?? 0.0;
                  final color = scenario['color'] as Color;

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(scenario['name'] as String),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(CurrencyHelper.formatAmount(payment)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          months == -1
                              ? '∞'
                              : months == 0
                              ? '0'
                              : '$months',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(CurrencyHelper.formatAmount(total)),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.creditCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Kredi kartı bulunamadı',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSimulations,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCardSelector(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              _buildScenarioCard(
                title: 'Asgari Ödeme',
                color: Colors.orange,
                data: _minimumPaymentResult,
                icon: Icons.warning_amber,
              ),
              const SizedBox(height: 12),
              _buildScenarioCard(
                title: 'Önerilen Ödeme',
                color: Colors.blue,
                data: _recommendationResult,
                icon: Icons.recommend,
              ),
              const SizedBox(height: 12),
              _buildScenarioCard(
                title: 'Tam Ödeme',
                color: Colors.green,
                data: _fullPaymentResult,
                icon: Icons.check_circle,
              ),
              const SizedBox(height: 16),
              _buildCustomPaymentSection(),
              const SizedBox(height: 16),
              _buildComparisonTable(),
            ],
          ],
        ),
      ),
    );
  }
}
