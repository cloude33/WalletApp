import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/wallet.dart';
import '../models/kmh_transaction.dart';
import '../models/kmh_transaction_type.dart';
import '../models/kmh_statement.dart';
import '../services/kmh_service.dart';
import '../utils/lazy_load_helper.dart';
class KmhStatementScreen extends StatefulWidget {
  final Wallet account;

  const KmhStatementScreen({super.key, required this.account});

  @override
  State<KmhStatementScreen> createState() => _KmhStatementScreenState();
}

class _KmhStatementScreenState extends State<KmhStatementScreen> {
  final KmhService _kmhService = KmhService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  KmhStatement? _statement;
  LazyLoadController? _lazyLoadController;
  static const int _initialLoadCount = 20;
  static const int _loadMoreCount = 10;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  final List<Map<String, dynamic>> _dateRangePresets = [
    {'label': 'Son 7 Gün', 'days': 7},
    {'label': 'Son 30 Gün', 'days': 30},
    {'label': 'Son 3 Ay', 'days': 90},
    {'label': 'Son 6 Ay', 'days': 180},
    {'label': 'Son 1 Yıl', 'days': 365},
  ];

  @override
  void initState() {
    super.initState();
    _loadStatement();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreTransactions();
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore || _lazyLoadController == null || _statement == null) {
      return;
    }

    final currentlyLoadedCount = _lazyLoadController!.loadedIndices.length;
    final totalTransactions = _statement!.transactions.length;
    if (currentlyLoadedCount >= totalTransactions) {
      return;
    }

    setState(() => _isLoadingMore = true);

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final remainingCount = totalTransactions - currentlyLoadedCount;
      final batchSize = _loadMoreCount.clamp(0, remainingCount);

      if (batchSize > 0) {
        final startIndex = currentlyLoadedCount;
        final endIndex = (startIndex + batchSize).clamp(0, totalTransactions);
        final indicesToLoad = List.generate(
          endIndex - startIndex,
          (index) => startIndex + index,
        );
        _lazyLoadController!.loadItems(indicesToLoad);
      }

      setState(() => _isLoadingMore = false);
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadStatement() async {
    setState(() => _isLoading = true);

    try {
      final statement = await _kmhService.generateStatement(
        widget.account.id,
        _startDate,
        _endDate,
      );
      final lazyController = LazyLoadController(
        preloadThreshold: _loadMoreCount,
        maxLoadedItems: statement.transactions.length,
      );
      final initialIndices = List.generate(
        _initialLoadCount.clamp(0, statement.transactions.length),
        (index) => index,
      );
      lazyController.loadItems(initialIndices);

      setState(() {
        _statement = statement;
        _lazyLoadController = lazyController;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KMH Ekstresi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _statement != null ? _showExportOptions : null,
            tooltip: 'Dışa Aktar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateRangeSelector(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _statement == null
                ? _buildEmptyState()
                : _buildStatementContent(),
          ),
        ],
      ),
    );
  }
  Widget _buildDateRangeSelector() {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tarih Aralığı',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dateRangePresets.map((preset) {
              final isSelected = _isPresetSelected(preset['days'] as int);
              return ChoiceChip(
                label: Text(preset['label'] as String),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _selectPresetDateRange(preset['days'] as int);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: 'Başlangıç',
                  date: _startDate,
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateButton(
                  label: 'Bitiş',
                  date: _endDate,
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadStatement,
              icon: const Icon(Icons.search),
              label: const Text('Ekstreyi Göster'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy', 'tr_TR').format(date),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  bool _isPresetSelected(int days) {
    final now = DateTime.now();
    final presetStart = now.subtract(Duration(days: days));
    final startDiff = _startDate.difference(presetStart).inDays.abs();
    final endDiff = _endDate.difference(now).inDays.abs();

    return startDiff <= 1 && endDiff <= 1;
  }

  void _selectPresetDateRange(int days) {
    setState(() {
      _endDate = DateTime.now();
      _startDate = _endDate.subtract(Duration(days: days));
    });
    _loadStatement();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Ekstre bulunamadı',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tarih aralığını değiştirip tekrar deneyin',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
  Widget _buildStatementContent() {
    if (_statement == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _loadStatement,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatementHeader(),
          const SizedBox(height: 16),
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildInterestCalculations(),
          const SizedBox(height: 24),
          _buildTransactionsList(),
        ],
      ),
    );
  }

  Widget _buildStatementHeader() {
    if (_statement == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(widget.account.color),
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: Color(int.parse(widget.account.color)),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statement!.walletName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ekstre Dönemi',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat(
                    'dd MMM yyyy',
                    'tr_TR',
                  ).format(_statement!.startDate),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 16),
                Text(
                  DateFormat(
                    'dd MMM yyyy',
                    'tr_TR',
                  ).format(_statement!.endDate),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSummaryCard() {
    if (_statement == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Özet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              'Dönem Başı Bakiye',
              _statement!.openingBalance,
              _statement!.openingBalance < 0 ? Colors.red : Colors.green,
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              'Toplam Para Yatırma',
              _statement!.totalDeposits,
              Colors.green,
              prefix: '+',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Toplam Para Çekme',
              _statement!.totalWithdrawals,
              Colors.red,
              prefix: '-',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Toplam Faiz',
              _statement!.totalInterest,
              Colors.orange,
              prefix: '-',
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              'Net Değişim',
              _statement!.netChange,
              _statement!.netChange < 0 ? Colors.red : Colors.green,
              prefix: _statement!.netChange >= 0 ? '+' : '',
              isBold: true,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Dönem Sonu Bakiye',
              _statement!.closingBalance,
              _statement!.closingBalance < 0 ? Colors.red : Colors.green,
              isBold: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_statement!.transactionCount} işlem',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
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

  Widget _buildSummaryRow(
    String label,
    double amount,
    Color color, {
    String prefix = '',
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey[700],
          ),
        ),
        Text(
          '$prefix${_currencyFormat.format(amount)}',
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
  Widget _buildInterestCalculations() {
    if (_statement == null || _statement!.totalInterest == 0) {
      return const SizedBox.shrink();
    }

    final daysDiff =
        _statement!.endDate.difference(_statement!.startDate).inDays + 1;
    final avgDailyInterest = _statement!.totalInterest / daysDiff;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, size: 20, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text(
                  'Faiz Hesaplamaları',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInterestRow('Dönem Toplam Faiz', _statement!.totalInterest),
            const SizedBox(height: 8),
            _buildInterestRow('Ortalama Günlük Faiz', avgDailyInterest),
            const SizedBox(height: 8),
            _buildInterestRow(
              'Dönem Süresi',
              daysDiff.toDouble(),
              suffix: ' gün',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Faiz hesaplamaları günlük borç tutarına göre yapılmıştır.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                      ),
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

  Widget _buildInterestRow(String label, double value, {String suffix = ''}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        Text(
          suffix.isEmpty
              ? _currencyFormat.format(value)
              : '${value.toStringAsFixed(0)}$suffix',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.orange[700],
          ),
        ),
      ],
    );
  }
  Widget _buildTransactionsList() {
    if (_statement == null || _lazyLoadController == null) {
      return const SizedBox.shrink();
    }
    if (_statement!.transactions.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Bu dönemde işlem yok',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final loadedIndices = _lazyLoadController!.loadedIndices;
    final totalTransactions = _statement!.transactions.length;
    final hasMore = loadedIndices.length < totalTransactions;
    final loadedTransactions =
        loadedIndices.map((index) => _statement!.transactions[index]).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'İşlem Detayları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${loadedTransactions.length} / ${_statement!.transactions.length} işlem',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListView.separated(
                controller: _scrollController,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: loadedTransactions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final transaction = loadedTransactions[index];
                  return _buildTransactionItem(transaction);
                },
              ),
              if (hasMore)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isLoadingMore
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : TextButton.icon(
                          onPressed: _loadMoreTransactions,
                          icon: const Icon(Icons.expand_more),
                          label: Text(
                            'Daha Fazla Yükle (${_statement!.transactions.length - loadedTransactions.length} kaldı)',
                          ),
                        ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildTransactionItem(KmhTransaction transaction) {
    IconData icon;
    Color iconColor;
    String prefix;
    String typeLabel;

    switch (transaction.type) {
      case KmhTransactionType.withdrawal:
        icon = Icons.remove_circle_outline;
        iconColor = Colors.red;
        prefix = '-';
        typeLabel = 'Para Çekme';
        break;
      case KmhTransactionType.deposit:
        icon = Icons.add_circle_outline;
        iconColor = Colors.green;
        prefix = '+';
        typeLabel = 'Para Yatırma';
        break;
      case KmhTransactionType.interest:
        icon = Icons.percent;
        iconColor = Colors.orange;
        prefix = '-';
        typeLabel = 'Faiz';
        break;
      case KmhTransactionType.fee:
        icon = Icons.money_off;
        iconColor = Colors.purple;
        prefix = '-';
        typeLabel = 'Masraf';
        break;
      case KmhTransactionType.transfer:
        icon = Icons.swap_horiz;
        iconColor = Colors.blue;
        prefix = '';
        typeLabel = 'Transfer';
        break;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.2),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        transaction.description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            typeLabel,
            style: TextStyle(
              fontSize: 12,
              color: iconColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('dd MMM yyyy HH:mm', 'tr_TR').format(transaction.date),
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$prefix${_currencyFormat.format(transaction.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _currencyFormat.format(transaction.balanceAfter),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('PDF olarak dışa aktar'),
                subtitle: const Text('Ekstreyi PDF formatında kaydet'),
                onTap: () {
                  Navigator.pop(context);
                  _exportToPdf();
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text('Excel olarak dışa aktar'),
                subtitle: const Text('Ekstreyi Excel formatında kaydet'),
                onTap: () {
                  Navigator.pop(context);
                  _exportToExcel();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.blue),
                title: const Text('Paylaş'),
                subtitle: const Text('Ekstreyi paylaş'),
                onTap: () {
                  Navigator.pop(context);
                  _shareStatement();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _exportToPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF dışa aktarma özelliği yakında eklenecek'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportToExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Excel dışa aktarma özelliği yakında eklenecek'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareStatement() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paylaşma özelliği yakında eklenecek'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
