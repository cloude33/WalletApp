import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/wallet.dart';
import '../models/kmh_transaction_type.dart';
import '../services/kmh_service.dart';
import '../utils/error_handler.dart';

class KmhTransactionScreen extends StatefulWidget {
  final Wallet account;
  final KmhTransactionType? defaultType;

  const KmhTransactionScreen({
    super.key,
    required this.account,
    this.defaultType,
  });

  @override
  State<KmhTransactionScreen> createState() => _KmhTransactionScreenState();
}

class _KmhTransactionScreenState extends State<KmhTransactionScreen> {
  final KmhService _kmhService = KmhService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  late KmhTransactionType _selectedType;
  bool _isLoading = false;
  bool _showConfirmation = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.defaultType ?? KmhTransactionType.withdrawal;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0.00', 'tr_TR').format(amount);
  }

  double? _parseAmount() {
    if (_amountController.text.isEmpty) return null;
    final cleanAmount = _amountController.text
        .replaceAll('.', '')
        .replaceAll(',', '.');
    
    return double.tryParse(cleanAmount);
  }

  bool _validateInputs() {
    final amount = _parseAmount();
    
    if (amount == null || amount <= 0) {
      ErrorHandler.showError(context, 'Lütfen geçerli bir tutar girin');
      return false;
    }
    
    if (_descriptionController.text.trim().isEmpty) {
      ErrorHandler.showError(context, 'Lütfen açıklama girin');
      return false;
    }
    
    return true;
  }

  Future<void> _showConfirmationDialog() async {
    if (!_validateInputs()) return;
    
    setState(() {
      _showConfirmation = true;
    });
  }

  Future<void> _saveTransaction() async {
    if (!_validateInputs()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final amount = _parseAmount()!;
      final description = _descriptionController.text.trim();

      if (_selectedType == KmhTransactionType.withdrawal) {
        await _kmhService.recordWithdrawal(
          widget.account.id,
          amount,
          description,
        );
      } else {
        await _kmhService.recordDeposit(
          widget.account.id,
          amount,
          description,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ErrorHandler.showSuccess(
          context,
          _selectedType == KmhTransactionType.withdrawal
              ? 'Para çekme işlemi başarıyla kaydedildi'
              : 'Para yatırma işlemi başarıyla kaydedildi',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showConfirmation = false;
        });
        ErrorHandler.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showConfirmation) {
      return _buildConfirmationScreen();
    }
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAccountInfo(),
                      const SizedBox(height: 24),
                      _buildTypeSelector(),
                      const SizedBox(height: 24),
                      _buildAmountField(),
                      const SizedBox(height: 20),
                      _buildDescriptionField(),
                      const SizedBox(height: 24),
                      _buildLimitIndicator(),
                      const SizedBox(height: 32),
                      _buildContinueButton(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'KMH İşlemi',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildAccountInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF5E5CE6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF5E5CE6).withValues(alpha: 0.3),
        ),
      ),
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mevcut Bakiye',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '₺${_formatCurrency(widget.account.balance)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.account.balance < 0
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Kullanılabilir Kredi',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '₺${_formatCurrency(widget.account.availableCredit)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5E5CE6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'İşlem Tipi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeButton(
                'Para Çek',
                KmhTransactionType.withdrawal,
                Icons.arrow_upward,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeButton(
                'Para Yatır',
                KmhTransactionType.deposit,
                Icons.arrow_downward,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeButton(
    String label,
    KmhTransactionType type,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tutar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: '₺ ',
            hintText: '0,00',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF5E5CE6),
                width: 2,
              ),
            ),
          ),
          onChanged: (value) {
            if (value.isEmpty) {
              setState(() {});
              return;
            }
            String cleanValue = value.replaceAll('.', '');
            cleanValue = cleanValue.replaceAll(RegExp(r'[^0-9,]'), '');
            int firstCommaIndex = cleanValue.indexOf(',');
            if (firstCommaIndex != -1) {
              String integerPart = cleanValue.substring(0, firstCommaIndex);
              String decimalPart = cleanValue
                  .substring(firstCommaIndex + 1)
                  .replaceAll(',', '');
              cleanValue = '$integerPart,$decimalPart';
            }
            final parts = cleanValue.split(',');
            String formattedValue;

            if (parts.length > 1) {
              final integerPart = parts[0];
              String decimalPart = parts[1];
              if (decimalPart.length > 2) {
                decimalPart = decimalPart.substring(0, 2);
              }
              final parsedInteger = integerPart.isEmpty
                  ? 0
                  : (int.tryParse(integerPart) ?? 0);
              final formattedInteger = NumberFormat(
                '#,##0',
                'tr_TR',
              ).format(parsedInteger);

              formattedValue = '$formattedInteger,$decimalPart';
            } else {
              final numericValue = int.tryParse(cleanValue) ?? 0;
              formattedValue = NumberFormat(
                '#,##0',
                'tr_TR',
              ).format(numericValue);
            }

            if (value != formattedValue) {
              _amountController.value = TextEditingValue(
                text: formattedValue,
                selection: TextSelection.collapsed(
                  offset: formattedValue.length,
                ),
              );
            }
            
            setState(() {});
          },
          onTap: () {
            if (_amountController.text == '0' ||
                _amountController.text == '0,00') {
              _amountController.clear();
            }
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Açıklama',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: 'Örn: Market alışverişi, Fatura ödemesi',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF5E5CE6),
                width: 2,
              ),
            ),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildLimitIndicator() {
    final amount = _parseAmount() ?? 0.0;
    final currentBalance = widget.account.balance;
    final creditLimit = widget.account.creditLimit;
    double newBalance;
    if (_selectedType == KmhTransactionType.withdrawal) {
      newBalance = currentBalance - amount;
    } else {
      newBalance = currentBalance + amount;
    }
    final newAvailableCredit = creditLimit + newBalance;
    final wouldExceedLimit = _selectedType == KmhTransactionType.withdrawal &&
        newBalance < -creditLimit;
    final usedCredit = newBalance < 0 ? newBalance.abs() : 0.0;
    final usagePercentage = creditLimit > 0 ? (usedCredit / creditLimit) * 100 : 0.0;
    
    Color indicatorColor;
    String statusText;
    
    if (wouldExceedLimit) {
      indicatorColor = Colors.red;
      statusText = 'Limit Aşımı!';
    } else if (usagePercentage >= 95) {
      indicatorColor = Colors.red;
      statusText = 'Kritik Seviye';
    } else if (usagePercentage >= 80) {
      indicatorColor = Colors.orange;
      statusText = 'Dikkat';
    } else {
      indicatorColor = Colors.green;
      statusText = 'Güvenli';
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: indicatorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Limit Durumu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: usagePercentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'İşlem Sonrası Bakiye',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '₺${_formatCurrency(newBalance)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: newBalance < 0 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Kalan Kredi',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '₺${_formatCurrency(newAvailableCredit)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: wouldExceedLimit ? Colors.red : indicatorColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (wouldExceedLimit) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bu işlem kredi limitinizi aşacaktır. Lütfen daha düşük bir tutar girin.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    final amount = _parseAmount() ?? 0.0;
    final wouldExceedLimit = _selectedType == KmhTransactionType.withdrawal &&
        (widget.account.balance - amount) < -widget.account.creditLimit;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: wouldExceedLimit ? null : _showConfirmationDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5E5CE6),
          disabledBackgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          'Devam Et',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: wouldExceedLimit ? Colors.grey.shade600 : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationScreen() {
    final amount = _parseAmount()!;
    final description = _descriptionController.text.trim();
    final currentBalance = widget.account.balance;
    
    double newBalance;
    if (_selectedType == KmhTransactionType.withdrawal) {
      newBalance = currentBalance - amount;
    } else {
      newBalance = currentBalance + amount;
    }
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _selectedType == KmhTransactionType.withdrawal
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _selectedType == KmhTransactionType.withdrawal
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 64,
                        color: _selectedType == KmhTransactionType.withdrawal
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _selectedType == KmhTransactionType.withdrawal
                          ? 'Para Çekme'
                          : 'Para Yatırma',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₺${_formatCurrency(amount)}',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _selectedType == KmhTransactionType.withdrawal
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Hesap', widget.account.name),
                          const Divider(height: 24),
                          _buildDetailRow('Açıklama', description),
                          const Divider(height: 24),
                          _buildDetailRow(
                            'Mevcut Bakiye',
                            '₺${_formatCurrency(currentBalance)}',
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            'Yeni Bakiye',
                            '₺${_formatCurrency(newBalance)}',
                            valueColor: newBalance < 0 ? Colors.red : Colors.green,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _showConfirmation = false;
                                    });
                                  },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(
                                color: Color(0xFF5E5CE6),
                                width: 2,
                              ),
                            ),
                            child: const Text(
                              'Geri',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5E5CE6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveTransaction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5E5CE6),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Onayla',
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
