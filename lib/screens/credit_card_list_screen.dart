import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/credit_card.dart';
import '../services/credit_card_service.dart';
import 'add_credit_card_screen.dart';
import 'credit_card_detail_screen.dart';

class CreditCardListScreen extends StatefulWidget {
  const CreditCardListScreen({super.key});

  @override
  State<CreditCardListScreen> createState() => _CreditCardListScreenState();
}

class _CreditCardListScreenState extends State<CreditCardListScreen> {
  final CreditCardService _cardService = CreditCardService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  List<CreditCard> _cards = [];
  Map<String, Map<String, dynamic>> _cardDetails = {};
  bool _isLoading = true;

  double _totalDebt = 0;
  double _totalAvailableCredit = 0;
  double _totalDueThisMonth = 0;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);

    try {
      final cards = await _cardService.getActiveCards();
      final totalDebt = await _cardService.getTotalDebtAllCards();
      final totalAvailable = await _cardService.getTotalAvailableCredit();
      final totalDue = await _cardService.getTotalDueThisMonth();

      // Load details for each card
      final details = <String, Map<String, dynamic>>{};
      for (var card in cards) {
        details[card.id] = await _cardService.getCardWithDetails(card.id);
      }

      setState(() {
        _cards = cards;
        _cardDetails = details;
        _totalDebt = totalDebt;
        _totalAvailableCredit = totalAvailable;
        _totalDueThisMonth = totalDue;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _deleteCard(CreditCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kartı Sil'),
        content: Text(
          '${card.bankName} ${card.cardName} kartını silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _cardService.deleteCard(card.id);
        _loadCards();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Kart silindi')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kredi Kartlarım'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCards),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryCard(),
                Expanded(
                  child: _cards.isEmpty ? _buildEmptyState() : _buildCardList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddCard,
        icon: const Icon(Icons.add_card),
        label: const Text('Kart Ekle'),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Toplam Borç',
                  _currencyFormat.format(_totalDebt),
                  Colors.red,
                  Icons.credit_card,
                ),
                _buildSummaryItem(
                  'Kullanılabilir Limit',
                  _currencyFormat.format(_totalAvailableCredit),
                  Colors.green,
                  Icons.account_balance_wallet,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Bu Ay Ödenecek: ${_currencyFormat.format(_totalDueThisMonth)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Henüz kredi kartı eklenmemiş',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Kredi kartlarınızı takip etmeye başlamak için\n"Kart Ekle" butonuna tıklayın',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCardList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        final details = _cardDetails[card.id];
        return _buildCardItem(card, details);
      },
    );
  }

  Widget _buildCardItem(CreditCard card, Map<String, dynamic>? details) {
    if (details == null) {
      return const Card(child: ListTile(title: Text('Yükleniyor...')));
    }

    final currentDebt = details['currentDebt'] as double;
    final availableCredit = details['availableCredit'] as double;
    final utilization = details['utilization'] as double;
    final nextDueDate = details['nextDueDate'] as DateTime;
    final activeInstallmentCount = details['activeInstallmentCount'] as int;

    // Determine status color based on utilization
    Color statusColor;
    if (utilization >= 80) {
      statusColor = Colors.red;
    } else if (utilization >= 50) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToCardDetail(card),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: card.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.credit_card, color: card.color, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.bankName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${card.cardName} •••• ${card.last4Digits}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${utilization.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deleteCard(card);
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Sil',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Debt and credit info
              Row(
                children: [
                  Expanded(
                    child: _buildInfoColumn(
                      'Mevcut Borç',
                      _currencyFormat.format(currentDebt),
                      Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      'Kullanılabilir',
                      _currencyFormat.format(availableCredit),
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: utilization / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),

              // Additional info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Son Ödeme: ${DateFormat('dd MMM', 'tr_TR').format(nextDueDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (activeInstallmentCount > 0)
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '$activeInstallmentCount Taksit',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToAddCard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCreditCardScreen()),
    );

    if (result == true) {
      _loadCards();
    }
  }

  Future<void> _navigateToCardDetail(CreditCard card) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreditCardDetailScreen(card: card),
      ),
    );

    if (result == true) {
      _loadCards();
    }
  }
}
