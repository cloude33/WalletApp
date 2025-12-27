import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/credit_card.dart';
import '../services/card_reporting_service.dart';
import '../services/credit_card_service.dart';
import '../utils/currency_helper.dart';
class CardReportingScreen extends StatefulWidget {
  const CardReportingScreen({super.key});

  @override
  State<CardReportingScreen> createState() => _CardReportingScreenState();
}

class _CardReportingScreenState extends State<CardReportingScreen>
    with SingleTickerProviderStateMixin {
  final CardReportingService _reportingService = CardReportingService();
  final CreditCardService _cardService = CreditCardService();

  late TabController _tabController;
  List<CreditCard> _cards = [];
  bool _isLoading = true;
  String? _selectedCardId;
  int _selectedMonths = 6;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final cards = await _cardService.getAllCards();
      setState(() {
        _cards = cards;
        if (_cards.isNotEmpty && _selectedCardId == null) {
          _selectedCardId = _cards.first.id;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri yüklenirken hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('Kart Raporları'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF00BFA5),
          indicatorWeight: 3,
          labelColor: const Color(0xFF00BFA5),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Genel Bakış'),
            Tab(text: 'Harcama Trendi'),
            Tab(text: 'Kategori Analizi'),
            Tab(text: 'Faiz Raporu'),
            Tab(text: 'Kart Karşılaştırma'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? _buildEmptyState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildSpendingTrendTab(),
                    _buildCategoryAnalysisTab(),
                    _buildInterestReportTab(),
                    _buildCardComparisonTab(),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Henüz kredi kartı eklenmemiş',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Raporları görmek için kredi kartı ekleyin',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _reportingService.getMostUsedCard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final data = snapshot.data ?? {};

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCard(
              title: 'En Çok Kullanılan Kart',
              child: data['hasCard'] == true
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.credit_card,
                                  color: Color(0xFF00BFA5),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['cardName'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${data['transactionCount']} işlem',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Toplam Harcama:',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                CurrencyHelper.formatAmount(
                                  data['totalSpending'] ?? 0,
                                ),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00BFA5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Henüz işlem yapılmamış'),
                    ),
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'Kart Kullanım Özeti',
              child: FutureBuilder<Map<String, dynamic>>(
                future: _reportingService.compareCardUsage(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final usageData = snapshot.data ?? {};
                  final cards = usageData['cards'] as Map<String, dynamic>? ?? {};

                  if (cards.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Veri yok'),
                    );
                  }

                  return Column(
                    children: cards.entries.map((entry) {
                      final cardData = entry.value as Map<String, dynamic>;
                      return ListTile(
                        leading: const Icon(Icons.credit_card, color: Color(0xFF00BFA5)),
                        title: Text(cardData['cardName'] ?? ''),
                        subtitle: Text(
                          '${cardData['transactionCount']} işlem',
                        ),
                        trailing: Text(
                          CurrencyHelper.formatAmount(
                            cardData['totalSpending'] ?? 0,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpendingTrendTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).cardColor,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedCardId,
                decoration: const InputDecoration(
                  labelText: 'Kart Seçin',
                  border: OutlineInputBorder(),
                ),
                items: _cards.map((card) {
                  return DropdownMenuItem(
                    value: card.id,
                    child: Text('${card.bankName} ${card.cardName}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCardId = value);
                },
              ),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 3, label: Text('3 Ay')),
                  ButtonSegment(value: 6, label: Text('6 Ay')),
                  ButtonSegment(value: 12, label: Text('12 Ay')),
                ],
                selected: {_selectedMonths},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() => _selectedMonths = newSelection.first);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _selectedCardId == null
              ? const Center(child: Text('Lütfen bir kart seçin'))
              : FutureBuilder<Map<String, dynamic>>(
                  future: _reportingService.getMonthlySpendingTrend(
                    _selectedCardId!,
                    _selectedMonths,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Hata: ${snapshot.error}'));
                    }

                    final data = snapshot.data ?? {};
                    final trendData = data['trendData'] as Map<DateTime, double>? ?? {};

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildCard(
                          title: 'Aylık Harcama Trendi',
                          child: Container(
                            height: 300,
                            padding: const EdgeInsets.all(16),
                            child: _buildTrendChart(trendData),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCard(
                          title: 'Aylık Detaylar',
                          child: Column(
                            children: trendData.entries.map((entry) {
                              final month = entry.key;
                              final amount = entry.value;
                              return ListTile(
                                leading: Icon(
                                  Icons.calendar_month,
                                  color: Colors.grey[600],
                                ),
                                title: Text(
                                  DateFormat('MMMM yyyy', 'tr_TR').format(month),
                                ),
                                trailing: Text(
                                  CurrencyHelper.formatAmount(amount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTrendChart(Map<DateTime, double> trendData) {
    if (trendData.isEmpty) {
      return const Center(child: Text('Veri yok'));
    }

    final sortedEntries = trendData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = <FlSpot>[];
    for (int i = 0; i < sortedEntries.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedEntries[i].value));
    }

    final maxY = sortedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedEntries.length) {
                  final month = sortedEntries[value.toInt()].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MMM', 'tr_TR').format(month),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₺${NumberFormat.compact().format(value)}',
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 50,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (sortedEntries.length - 1).toDouble(),
        minY: 0,
        maxY: maxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF00BFA5),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF00BFA5).withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAnalysisTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _reportingService.getSpendingTrendAllCards(_selectedMonths),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCard(
              title: 'Kategori Bazlı Kart Kullanımı',
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Her kategoride hangi kartın ne kadar kullanıldığını gösterir',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'Kart Bazlı Harcama Dağılımı',
              child: Column(
                children: _cards.map((card) {
                  return ExpansionTile(
                    leading: const Icon(Icons.credit_card),
                    title: Text('${card.bankName} ${card.cardName}'),
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Kategori detayları burada gösterilecek',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInterestReportTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).cardColor,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                initialValue: _selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Yıl Seçin',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(5, (index) {
                  final year = DateTime.now().year - index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedYear = value);
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCard(
                title: 'Yıllık Faiz Raporu',
                child: Column(
                  children: _cards.map((card) {
                    return FutureBuilder<double>(
                      future: _reportingService.getTotalInterestPaidYearly(
                        card.id,
                        _selectedYear,
                      ),
                      builder: (context, snapshot) {
                        final interest = snapshot.data ?? 0;
                        return ListTile(
                          leading: const Icon(Icons.credit_card, color: Colors.red),
                          title: Text('${card.bankName} ${card.cardName}'),
                          subtitle: Text('$_selectedYear yılı toplam faiz'),
                          trailing: Text(
                            CurrencyHelper.formatAmount(interest),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<double>(
                future: _calculateTotalInterestAllCards(),
                builder: (context, snapshot) {
                  final totalInterest = snapshot.data ?? 0;
                  return _buildCard(
                    title: 'Toplam Faiz Ödemesi',
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            CurrencyHelper.formatAmount(totalInterest),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_selectedYear yılında ödenen toplam faiz',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<double> _calculateTotalInterestAllCards() async {
    double total = 0;
    for (var card in _cards) {
      final interest = await _reportingService.getTotalInterestPaidYearly(
        card.id,
        _selectedYear,
      );
      total += interest;
    }
    return total;
  }

  Widget _buildCardComparisonTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _reportingService.getCardsSortedBySpending(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final sortedCards = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCard(
              title: 'Harcama Sıralaması',
              child: Column(
                children: sortedCards.asMap().entries.map((entry) {
                  final index = entry.key;
                  final cardData = entry.value;
                  final isTop = index == 0;

                  return Container(
                    decoration: BoxDecoration(
                      color: isTop
                          ? const Color(0xFF00BFA5).withValues(alpha: 0.1)
                          : null,
                      border: isTop
                          ? Border.all(color: const Color(0xFF00BFA5), width: 2)
                          : null,
                      borderRadius: isTop ? BorderRadius.circular(8) : null,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isTop
                            ? const Color(0xFF00BFA5)
                            : Colors.grey[400],
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        cardData['cardName'] ?? '',
                        style: TextStyle(
                          fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${cardData['transactionCount']} işlem',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyHelper.formatAmount(
                              cardData['totalSpending'] ?? 0,
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isTop ? const Color(0xFF00BFA5) : null,
                            ),
                          ),
                          if (isTop)
                            const Text(
                              'En Çok Kullanılan',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF00BFA5),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: _reportingService.getCardUtilizationComparison(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data ?? {};
                final cards = data['cards'] as Map<String, dynamic>? ?? {};

                return _buildCard(
                  title: 'Limit Kullanım Oranları',
                  child: Column(
                    children: cards.entries.map((entry) {
                      final cardData = entry.value as Map<String, dynamic>;
                      final utilization = cardData['utilizationPercentage'] ?? 0.0;
                      final color = utilization > 80
                          ? Colors.red
                          : (utilization > 50 ? Colors.orange : Colors.green);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    cardData['cardName'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${utilization.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: utilization / 100,
                              backgroundColor: Colors.grey[200],
                              color: color,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Borç: ${CurrencyHelper.formatAmount(cardData['currentDebt'] ?? 0)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  'Limit: ${CurrencyHelper.formatAmount(cardData['creditLimit'] ?? 0)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}
