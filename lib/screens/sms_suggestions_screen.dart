import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/sms_parser_service.dart';
import '../services/credit_card_service.dart';
import '../models/credit_card.dart';
import '../models/credit_card_transaction.dart';
import '../utils/currency_helper.dart';

/// Screen for displaying SMS transaction suggestions
/// Requirements: 12.1, 12.3, 12.4
class SMSSuggestionsScreen extends StatefulWidget {
  const SMSSuggestionsScreen({super.key});

  @override
  State<SMSSuggestionsScreen> createState() => _SMSSuggestionsScreenState();
}

class _SMSSuggestionsScreenState extends State<SMSSuggestionsScreen> {
  final SMSParserService _smsParserService = SMSParserService();
  final CreditCardService _creditCardService = CreditCardService();
  
  List<Map<String, dynamic>> _suggestions = [];
  List<CreditCard> _creditCards = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkPermission();
    await _loadCreditCards();
    await _loadSuggestions();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _smsParserService.requestSMSPermission();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  Future<void> _loadCreditCards() async {
    final cards = await _creditCardService.getAllCards();
    setState(() {
      _creditCards = cards;
    });
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
    });

    final suggestions = await _smsParserService.getSuggestedTransactions();
    
    setState(() {
      _suggestions = suggestions;
      _isLoading = false;
    });
  }

  Future<void> _scanSMS() async {
    if (!_hasPermission) {
      await _requestPermission();
      return;
    }

    setState(() {
      _isScanning = true;
    });

    try {
      // Read SMS messages
      final messages = await _smsParserService.readBankSMS();
      
      // Parse each message and create suggestions
      for (final message in messages) {
        await _smsParserService.createTransactionFromSMS(message);
      }

      // Reload suggestions
      await _loadSuggestions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${messages.length} SMS tarandı'),
            backgroundColor: const Color(0xFF00BFA5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SMS tarama hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SMS İzni Gerekli'),
        content: const Text(
          'Banka SMS\'lerini okuyabilmek için SMS izni vermeniz gerekiyor. '
          'Bu izin sadece banka SMS\'lerini otomatik olarak işlem önerisi '
          'oluşturmak için kullanılacaktır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
            ),
            child: const Text('İzin Ver'),
          ),
        ],
      ),
    );

    if (result == true) {
      final granted = await _smsParserService.requestSMSPermission();
      setState(() {
        _hasPermission = granted;
      });

      if (granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS izni verildi'),
            backgroundColor: Color(0xFF00BFA5),
          ),
        );
      }
    }
  }

  Future<void> _confirmSuggestion(Map<String, dynamic> suggestion) async {
    final transaction = suggestion['transaction'] as CreditCardTransaction;
    
    // Show card selection dialog
    final selectedCard = await showDialog<CreditCard>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kart Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _creditCards.map((card) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: card.color.withValues(alpha: 0.2),
                child: Icon(
                  Icons.credit_card,
                  color: card.color,
                ),
              ),
              title: Text(card.bankName),
              subtitle: Text('${card.cardName} - **** ${card.last4Digits}'),
              onTap: () => Navigator.pop(context, card),
            );
          }).toList(),
        ),
      ),
    );

    if (selectedCard == null) return;

    try {
      // Confirm the suggestion with selected card
      final confirmedTransaction = await _smsParserService.confirmSuggestion(
        transaction.id,
        selectedCard.id,
      );

      if (confirmedTransaction != null) {
        // Add transaction to credit card
        await _creditCardService.addTransaction(confirmedTransaction);

        // Reload suggestions
        await _loadSuggestions();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İşlem eklendi'),
              backgroundColor: Color(0xFF00BFA5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectSuggestion(Map<String, dynamic> suggestion) async {
    final transaction = suggestion['transaction'] as CreditCardTransaction;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öneriyi Reddet'),
        content: const Text('Bu işlem önerisini reddetmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _smsParserService.removeSuggestion(transaction.id);
      await _loadSuggestions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Öneri reddedildi'),
          ),
        );
      }
    }
  }

  Future<void> _clearAllSuggestions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Önerileri Temizle'),
        content: const Text(
          'Tüm işlem önerilerini silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _smsParserService.clearSuggestions();
      await _loadSuggestions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tüm öneriler temizlendi'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS İşlem Önerileri'),
        actions: [
          if (_suggestions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearAllSuggestions,
              tooltip: 'Tümünü temizle',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasPermission
          ? _buildPermissionRequired()
          : _suggestions.isEmpty
          ? _buildEmptyState()
          : _buildSuggestionsList(),
      floatingActionButton: _hasPermission
          ? FloatingActionButton.extended(
              onPressed: _isScanning ? null : _scanSMS,
              backgroundColor: const Color(0xFF00BFA5),
              icon: _isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.sms),
              label: Text(_isScanning ? 'Taranıyor...' : 'SMS Tara'),
            )
          : null,
    );
  }

  Widget _buildPermissionRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sms_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'SMS İzni Gerekli',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Banka SMS\'lerini okuyabilmek ve otomatik işlem önerileri '
              'oluşturabilmek için SMS izni vermeniz gerekiyor.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _requestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              icon: const Icon(Icons.security),
              label: const Text(
                'İzin Ver',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Henüz Öneri Yok',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'SMS tarama yaparak banka SMS\'lerinizden otomatik işlem '
              'önerileri oluşturabilirsiniz.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _scanSMS,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              icon: const Icon(Icons.sms),
              label: const Text(
                'SMS Tara',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    // Filter unconfirmed suggestions
    final unconfirmedSuggestions = _suggestions
        .where((s) => s['isConfirmed'] == false)
        .toList();

    if (unconfirmedSuggestions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: unconfirmedSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = unconfirmedSuggestions[index];
        return _buildSuggestionCard(suggestion);
      },
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    final transaction = suggestion['transaction'] as CreditCardTransaction;
    final bank = suggestion['bank'] as String;
    final rawSMS = suggestion['rawSMS'] as String;
    final dateFormatter = DateFormat('d MMMM yyyy', 'tr_TR');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with bank info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sms,
                    color: Color(0xFF00BFA5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bank.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFormatter.format(transaction.transactionDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Transaction details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tutar:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      Text(
                        CurrencyHelper.formatAmount(transaction.amount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF3B30),
                        ),
                      ),
                    ],
                  ),
                  if (transaction.installmentCount > 1) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Taksit:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        Text(
                          '${transaction.installmentCount} Taksit',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Açıklama:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          transaction.description,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // SMS preview
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text(
                'SMS İçeriği',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 8),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rawSMS,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectSuggestion(suggestion),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('Reddet'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmSuggestion(suggestion),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('Onayla'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
