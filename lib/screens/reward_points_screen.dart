import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/credit_card.dart';
import '../models/reward_points.dart';
import '../models/reward_transaction.dart';
import '../services/reward_points_service.dart';

class RewardPointsScreen extends StatefulWidget {
  final CreditCard card;

  const RewardPointsScreen({super.key, required this.card});

  @override
  State<RewardPointsScreen> createState() => _RewardPointsScreenState();
}

class _RewardPointsScreenState extends State<RewardPointsScreen> {
  final RewardPointsService _rewardService = RewardPointsService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );
  final _formKey = GlobalKey<FormState>();
  final _pointsController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = true;
  RewardPoints? _rewardPoints;
  Map<String, dynamic>? _summary;
  List<RewardTransaction> _recentTransactions = [];
  bool _showSpendForm = false;

  @override
  void initState() {
    super.initState();
    _loadRewardPoints();
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadRewardPoints() async {
    setState(() => _isLoading = true);

    try {
      final rewardPoints = await _rewardService.getRewardPoints(widget.card.id);
      final summary = await _rewardService.getPointsSummary(widget.card.id);
      final transactions = await _rewardService.getPointsHistory(widget.card.id);
      transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      final recentTransactions = transactions.take(10).toList();

      setState(() {
        _rewardPoints = rewardPoints;
        _summary = summary;
        _recentTransactions = recentTransactions;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puan Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRewardPoints,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rewardPoints == null
              ? _buildNoRewardsView()
              : RefreshIndicator(
                  onRefresh: _loadRewardPoints,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildBalanceCard(),
                      const SizedBox(height: 16),
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                      const SizedBox(height: 16),
                      if (_showSpendForm) ...[
                        _buildSpendForm(),
                        const SizedBox(height: 16),
                      ],
                      _buildRecentTransactionsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNoRewardsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Puan Sistemi Bulunamadı',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu kart için henüz puan sistemi tanımlanmamış.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Geri Dön'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    if (_rewardPoints == null || _summary == null) {
      return const SizedBox.shrink();
    }

    final balance = _summary!['balance'] as double;
    final valueInCurrency = _summary!['valueInCurrency'] as double;
    final rewardType = _summary!['rewardType'] as String;

    String rewardTypeName;
    IconData rewardIcon;
    Color rewardColor;
    
    switch (rewardType) {
      case 'bonus':
        rewardTypeName = 'Bonus Puan';
        rewardIcon = Icons.star;
        rewardColor = Colors.amber;
        break;
      case 'worldpuan':
        rewardTypeName = 'WorldPuan';
        rewardIcon = Icons.public;
        rewardColor = Colors.blue;
        break;
      case 'miles':
        rewardTypeName = 'Mil';
        rewardIcon = Icons.flight;
        rewardColor = Colors.indigo;
        break;
      case 'cashback':
        rewardTypeName = 'Cashback';
        rewardIcon = Icons.money;
        rewardColor = Colors.green;
        break;
      default:
        rewardTypeName = 'Puan';
        rewardIcon = Icons.card_giftcard;
        rewardColor = widget.card.color;
    }

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              rewardColor.withValues(alpha: 0.8),
              rewardColor.withValues(alpha: 0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(rewardIcon, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Text(
                  rewardTypeName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Toplam Bakiye',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              balance.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'TL Karşılığı: ${_currencyFormat.format(valueInCurrency)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (_summary == null) {
      return const SizedBox.shrink();
    }

    final totalEarned = _summary!['totalEarned'] as double;
    final totalSpent = _summary!['totalSpent'] as double;
    final transactionCount = _summary!['transactionCount'] as int;
    final conversionRate = _summary!['conversionRate'] as double;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Puan Özeti',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Toplam Kazanılan',
                    totalEarned.toStringAsFixed(0),
                    Icons.add_circle_outline,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Toplam Harcanan',
                    totalSpent.toStringAsFixed(0),
                    Icons.remove_circle_outline,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'İşlem Sayısı',
                    transactionCount.toString(),
                    Icons.receipt_long,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Dönüşüm Oranı',
                    '1 puan = ${_currencyFormat.format(conversionRate)}',
                    Icons.swap_horiz,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _showSpendForm = !_showSpendForm;
                if (!_showSpendForm) {
                  _pointsController.clear();
                  _descriptionController.clear();
                }
              });
            },
            icon: Icon(_showSpendForm ? Icons.close : Icons.shopping_cart),
            label: Text(_showSpendForm ? 'İptal' : 'Puan Kullan'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _navigateToFullHistory,
            icon: const Icon(Icons.history),
            label: const Text('Tüm Geçmiş'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpendForm() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_cart, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Puan Kullan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pointsController,
                decoration: const InputDecoration(
                  labelText: 'Kullanılacak Puan',
                  hintText: 'Örn: 1000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.stars),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen puan miktarı girin';
                  }
                  final points = double.tryParse(value);
                  if (points == null || points <= 0) {
                    return 'Geçerli bir puan miktarı girin';
                  }
                  if (_rewardPoints != null && points > _rewardPoints!.pointsBalance) {
                    return 'Yetersiz puan bakiyesi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Örn: Alışveriş indirimi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen açıklama girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_pointsController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TL Karşılığı:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _currencyFormat.format(
                          (double.tryParse(_pointsController.text) ?? 0) *
                              (_rewardPoints?.conversionRate ?? 0),
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _spendPoints,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Puanları Kullan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Son İşlemler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_recentTransactions.length >= 10)
              TextButton(
                onPressed: _navigateToFullHistory,
                child: const Text('Tümünü Gör'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _recentTransactions.isEmpty
            ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Henüz işlem yok',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentTransactions.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final transaction = _recentTransactions[index];
                    return _buildTransactionItem(transaction);
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildTransactionItem(RewardTransaction transaction) {
    final isEarning = transaction.isEarning;
    final points = isEarning ? transaction.pointsEarned : transaction.pointsSpent;
    final color = isEarning ? Colors.green : Colors.red;
    final icon = isEarning ? Icons.add_circle : Icons.remove_circle;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.2),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        transaction.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        DateFormat('dd MMM yyyy HH:mm', 'tr_TR').format(transaction.transactionDate),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isEarning ? '+' : '-'}${points.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            _currencyFormat.format(points * (_rewardPoints?.conversionRate ?? 0)),
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _spendPoints() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final points = double.parse(_pointsController.text);
    final description = _descriptionController.text;

    try {
      await _rewardService.spendPoints(widget.card.id, points, description);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Puan başarıyla kullanıldı')),
        );
      }

      _pointsController.clear();
      _descriptionController.clear();
      setState(() => _showSpendForm = false);
      await _loadRewardPoints();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  void _navigateToFullHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RewardPointsHistoryScreen(
          card: widget.card,
          rewardPoints: _rewardPoints!,
        ),
      ),
    );
  }
}

class RewardPointsHistoryScreen extends StatefulWidget {
  final CreditCard card;
  final RewardPoints rewardPoints;

  const RewardPointsHistoryScreen({
    super.key,
    required this.card,
    required this.rewardPoints,
  });

  @override
  State<RewardPointsHistoryScreen> createState() =>
      _RewardPointsHistoryScreenState();
}

class _RewardPointsHistoryScreenState extends State<RewardPointsHistoryScreen> {
  final RewardPointsService _rewardService = RewardPointsService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  bool _isLoading = true;
  List<RewardTransaction> _allTransactions = [];
  List<RewardTransaction> _filteredTransactions = [];
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _loadAllTransactions();
  }

  Future<void> _loadAllTransactions() async {
    setState(() => _isLoading = true);

    try {
      final transactions = await _rewardService.getPointsHistory(widget.card.id);
      transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      setState(() {
        _allTransactions = transactions;
        _filteredTransactions = transactions;
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

  void _applyFilter(String filterType) {
    setState(() {
      _filterType = filterType;
      switch (filterType) {
        case 'earning':
          _filteredTransactions = _allTransactions.where((t) => t.isEarning).toList();
          break;
        case 'spending':
          _filteredTransactions = _allTransactions.where((t) => t.isSpending).toList();
          break;
        default:
          _filteredTransactions = _allTransactions;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puan Geçmişi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? _buildEmptyView()
                    : RefreshIndicator(
                        onRefresh: _loadAllTransactions,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTransactions.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final transaction = _filteredTransactions[index];
                            return _buildTransactionCard(transaction);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          _buildFilterChip('Tümü', 'all', _allTransactions.length),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Kazanılan',
            'earning',
            _allTransactions.where((t) => t.isEarning).length,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Harcanan',
            'spending',
            _allTransactions.where((t) => t.isSpending).length,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _applyFilter(value);
        }
      },
      selectedColor: widget.card.color.withValues(alpha: 0.3),
      checkmarkColor: widget.card.color,
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'İşlem Bulunamadı',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seçili filtreye uygun işlem bulunmuyor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(RewardTransaction transaction) {
    final isEarning = transaction.isEarning;
    final points = isEarning ? transaction.pointsEarned : transaction.pointsSpent;
    final color = isEarning ? Colors.green : Colors.red;
    final icon = isEarning ? Icons.add_circle : Icons.remove_circle;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR')
                  .format(transaction.transactionDate),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'TL Karşılığı: ${_currencyFormat.format(points * widget.rewardPoints.conversionRate)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isEarning ? '+' : '-'}${points.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: color,
              ),
            ),
            Text(
              isEarning ? 'Kazanılan' : 'Harcanan',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
