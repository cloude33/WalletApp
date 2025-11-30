import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/wallet.dart';
import '../models/budget.dart';
import '../models/loan.dart';
import '../models/credit_card_transaction.dart';
import '../services/data_service.dart';

class StatisticsScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final List<Wallet> wallets;
  final List<Budget> budgets;
  final List<Loan> loans;
  final List<CreditCardTransaction> creditCardTransactions;

  const StatisticsScreen({
    super.key,
    required this.transactions,
    required this.wallets,
    required this.budgets,
    this.loans = const [],
    this.creditCardTransactions = const [],
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeFilter = 'Aylık'; // Günlük, Haftalık, Aylık, Yıllık, Özel
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String _selectedWalletId = 'all';
  String _selectedCategory = 'all';
  String _selectedTransactionType = 'all'; // income, expense, all

  final DataService _dataService = DataService();
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    // Set initial index to 3 (Raporlar) as shown in screenshots
    _tabController.index = 3;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _dataService.getCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> get _filteredTransactions {
    final now = DateTime.now();
    DateTime startDate;
    DateTime? endDate;

    print('Filter: $_selectedTimeFilter');

    switch (_selectedTimeFilter) {
      case 'Günlük':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        print('Günlük: $startDate - $endDate');
        break;
      case 'Haftalık':
        startDate = now.subtract(const Duration(days: 7));
        print('Haftalık: $startDate - $now');
        break;
      case 'Aylık':
        startDate = DateTime(now.year, now.month, 1);
        print('Aylık: $startDate - $now');
        break;
      case 'Yıllık':
        startDate = DateTime(now.year, 1, 1);
        print('Yıllık: $startDate - $now');
        break;
      case 'Özel':
        if (_customStartDate != null && _customEndDate != null) {
          print('Özel: $_customStartDate - $_customEndDate');
          // Filter both regular and credit card transactions
          final regularFiltered = widget.transactions
              .where(
                (t) =>
                    t.date.isAfter(
                      _customStartDate!.subtract(const Duration(seconds: 1)),
                    ) &&
                    t.date.isBefore(
                      _customEndDate!.add(const Duration(days: 1)),
                    ) &&
                    (_selectedWalletId == 'all' ||
                        t.walletId == _selectedWalletId) &&
                    (_selectedCategory == 'all' ||
                        t.category == _selectedCategory) &&
                    (_selectedTransactionType == 'all' ||
                        t.type == _selectedTransactionType),
              )
              .toList();

          final creditCardFiltered = widget.creditCardTransactions
              .where(
                (t) =>
                    t.transactionDate.isAfter(
                      _customStartDate!.subtract(const Duration(seconds: 1)),
                    ) &&
                    t.transactionDate.isBefore(
                      _customEndDate!.add(const Duration(days: 1)),
                    ) &&
                    (_selectedCategory == 'all' ||
                        t.category == _selectedCategory),
              )
              .toList();

          // Combine both lists
          return [...regularFiltered, ...creditCardFiltered];
        }
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    // Filter regular transactions
    final regularFiltered = widget.transactions
        .where(
          (t) =>
              (endDate != null
                  ? (t.date.isAfter(
                          startDate.subtract(const Duration(seconds: 1)),
                        ) &&
                        t.date.isBefore(
                          endDate.add(const Duration(seconds: 1)),
                        ))
                  : t.date.isAfter(
                      startDate.subtract(const Duration(seconds: 1)),
                    )) &&
              (_selectedWalletId == 'all' || t.walletId == _selectedWalletId) &&
              (_selectedCategory == 'all' || t.category == _selectedCategory) &&
              (_selectedTransactionType == 'all' ||
                  t.type == _selectedTransactionType),
        )
        .toList();

    // Filter credit card transactions
    final creditCardFiltered = widget.creditCardTransactions
        .where(
          (t) =>
              (endDate != null
                  ? (t.transactionDate.isAfter(
                          startDate.subtract(const Duration(seconds: 1)),
                        ) &&
                        t.transactionDate.isBefore(
                          endDate.add(const Duration(seconds: 1)),
                        ))
                  : t.transactionDate.isAfter(
                      startDate.subtract(const Duration(seconds: 1)),
                    )) &&
              (_selectedCategory == 'all' || t.category == _selectedCategory),
        )
        .toList();

    print('Filtered regular transactions: ${regularFiltered.length}');
    print('Filtered credit card transactions: ${creditCardFiltered.length}');

    // Combine both lists
    return [...regularFiltered, ...creditCardFiltered];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.menu,
                            color: Color(0xFF1C1C1E),
                          ),
                          onPressed: () {},
                        ),
                        const Expanded(
                          child: Text(
                            'İstatistikler',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF1C1C1E),
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Balance for menu icon
                      ],
                    ),
                  ),
                  TabBar(
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
                      Tab(text: 'Nakit akışı'),
                      Tab(text: 'Harcama'),
                      Tab(text: 'Kredi'),
                      Tab(text: 'Raporlar'),
                      Tab(text: 'Varlıklar'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCashFlowTab(),
                      _buildSpendingTab(),
                      _buildCreditTab(),
                      _buildReportsView(),
                      _buildAssetsTab(),
                    ],
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: _buildTimeFilter(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashFlowTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gelir vs Gider',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildLineChart()),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCashFlowTableCard(),
      ],
    );
  }

  Widget _buildLineChart() {
    // Group transactions by month for the last 12 months
    final Map<DateTime, double> incomeMap = {};
    final Map<DateTime, double> expenseMap = {};

    final now = DateTime.now();
    final twelveMonthsAgo = DateTime(now.year - 1, now.month, 1);

    // Initialize maps for all months
    for (int i = 0; i < 12; i++) {
      final month = DateTime(
        twelveMonthsAgo.year,
        twelveMonthsAgo.month + i,
        1,
      );
      incomeMap[month] = 0.0;
      expenseMap[month] = 0.0;
    }

    // Fill with actual data
    for (var t in _filteredTransactions) {
      DateTime date;
      String type;
      double amount;

      // Handle both Transaction and CreditCardTransaction objects
      if (t is Transaction) {
        date = t.date;
        type = t.type;
        amount = t.amount;
      } else if (t is CreditCardTransaction) {
        date = t.transactionDate;
        type = 'expense'; // Credit card transactions are always expenses
        amount = t.amount;
      } else {
        continue; // Skip unknown transaction types
      }

      final monthKey = DateTime(date.year, date.month, 1);
      if (incomeMap.containsKey(monthKey) || expenseMap.containsKey(monthKey)) {
        if (type == 'income') {
          incomeMap[monthKey] = (incomeMap[monthKey] ?? 0) + amount;
        } else if (type == 'expense') {
          expenseMap[monthKey] = (expenseMap[monthKey] ?? 0) + amount;
        }
      }
    }

    final sortedMonths = incomeMap.keys.toList()..sort();
    if (sortedMonths.isEmpty) {
      return const Center(child: Text('Veri yok'));
    }

    // Prepare data for line chart
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];

    for (int i = 0; i < sortedMonths.length; i++) {
      final month = sortedMonths[i];
      incomeSpots.add(FlSpot(i.toDouble(), incomeMap[month] ?? 0));
      expenseSpots.add(FlSpot(i.toDouble(), expenseMap[month] ?? 0));
    }

    // Find max value for Y axis
    double maxY = 0;
    for (var value in [...incomeMap.values, ...expenseMap.values]) {
      if (value > maxY) maxY = value;
    }

    // Add some padding to the top
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 1000;

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedMonths.length) {
                  final month = sortedMonths[value.toInt()];
                  final monthNames = [
                    'Oca',
                    'Şub',
                    'Mar',
                    'Nis',
                    'May',
                    'Haz',
                    'Tem',
                    'Ağu',
                    'Eyl',
                    'Eki',
                    'Kas',
                    'Ara',
                  ];
                  return Text(
                    monthNames[month.month - 1],
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
              reservedSize: 22,
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
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (sortedMonths.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.2),
            ),
          ),
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingTab() {
    final expenseCategories = <String, double>{};
    final paymentMethods = <String, double>{};
    double totalExpense = 0;

    for (var item in _filteredTransactions) {
      // Handle regular transactions
      if (item is Transaction && item.type == 'expense') {
        expenseCategories[item.category] =
            (expenseCategories[item.category] ?? 0) + item.amount;
        totalExpense += item.amount;
        
        // Track payment method
        final wallet = widget.wallets.firstWhere(
          (w) => w.id == item.walletId,
          orElse: () => widget.wallets.isNotEmpty ? widget.wallets.first : Wallet(
            id: '',
            name: 'Nakit',
            balance: 0,
            type: 'cash',
            color: '0xFF8E8E93',
            icon: 'cash',
            creditLimit: 0.0,
          ),
        );
        
        final paymentType = wallet.type == 'credit_card' ? 'Kredi Kartı' : 'Nakit';
        paymentMethods[paymentType] = (paymentMethods[paymentType] ?? 0) + item.amount;
      }
      // Handle credit card transactions (always expenses)
      else if (item is CreditCardTransaction) {
        expenseCategories[item.category] =
            (expenseCategories[item.category] ?? 0) + item.amount;
        totalExpense += item.amount;
        
        // Credit card transactions are always credit card payments
        paymentMethods['Kredi Kartı'] = (paymentMethods['Kredi Kartı'] ?? 0) + item.amount;
      }
    }

    final sortedEntries = expenseCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Category Pie Chart
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: totalExpense > 0
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kategori Bazlı Harcama Dağılımı',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    if (event is FlTapUpEvent && pieTouchResponse != null) {
                                      final sectionIndex = pieTouchResponse.touchedSection?.touchedSectionIndex;
                                      if (sectionIndex != null && sectionIndex < sortedEntries.length) {
                                        _showCategoryDetails(sortedEntries[sectionIndex].key);
                                      }
                                    }
                                  },
                                ),
                                sections: sortedEntries.map((e) {
                                  final percentage =
                                      (e.value / totalExpense) * 100;
                                  final color =
                                      Colors.primaries[e.key.hashCode %
                                          Colors.primaries.length];
                                  return PieChartSectionData(
                                    color: color,
                                    value: percentage,
                                    title: '${percentage.toStringAsFixed(0)}%',
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: sortedEntries.take(5).map((e) {
                                final percentage =
                                    (e.value / totalExpense) * 100;
                                final color =
                                    Colors.primaries[e.key.hashCode %
                                        Colors.primaries.length];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
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
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          e.key,
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${percentage.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : const Center(child: Text('Harcama yok')),
        ),
        const SizedBox(height: 16),
        
        // Payment Method Distribution
        if (paymentMethods.isNotEmpty) ...[
          _buildPaymentMethodDistribution(paymentMethods, totalExpense),
          const SizedBox(height: 16),
        ],
        
        _buildDetailedSpendingCard(),
        const SizedBox(height: 16),
        ...sortedEntries.map((e) {
          final percentage = (e.value / totalExpense) * 100;
          final color =
              Colors.primaries[e.key.hashCode % Colors.primaries.length];

          // Find budget for this category
          final budget = widget.budgets
              .where((b) => b.category == e.key && b.isActive)
              .firstOrNull;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => _showCategoryDetails(e.key),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color,
                        child: Icon(
                          _getCategoryIcon(e.key),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(e.key),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₺${NumberFormat('#,##0', 'tr_TR').format(e.value)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (budget != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Bütçe: ₺${budget.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '%${((e.value / budget.amount) * 100).toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: e.value > budget.amount
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: (e.value / budget.amount).clamp(0.0, 1.0),
                              backgroundColor: Colors.grey[200],
                              color: e.value > budget.amount
                                  ? Colors.red
                                  : (e.value > budget.amount * 0.8
                                        ? Colors.orange
                                        : Colors.green),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDetailedSpendingCard() {
    final expenseCategories = <String, double>{};
    double totalExpense = 0;

    for (var item in _filteredTransactions) {
      // Handle regular transactions
      if (item is Transaction && item.type == 'expense') {
        expenseCategories[item.category] =
            (expenseCategories[item.category] ?? 0) + item.amount;
        totalExpense += item.amount;
      }
      // Handle credit card transactions (always expenses)
      else if (item is CreditCardTransaction) {
        expenseCategories[item.category] =
            (expenseCategories[item.category] ?? 0) + item.amount;
        totalExpense += item.amount;
      }
    }

    final sortedEntries = expenseCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildCard(
      title: 'Detaylı Harcama Analizi',
      subtitle: 'Kategori bazlı harcama dökümü',
      content: Column(
        children: [
          if (sortedEntries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Bu dönemde harcama bulunmamaktadır.'),
            )
          else
            ...sortedEntries.map((e) {
              final percentage = (e.value / totalExpense) * 100;
              final color =
                  Colors.primaries[e.key.hashCode % Colors.primaries.length];

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          e.key,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '₺${NumberFormat('#,##0', 'tr_TR').format(e.value)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[200],
                            color: color,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCreditTab() {
    final creditWallets = widget.wallets
        .where((w) => w.type == 'credit_card')
        .toList();
    final totalDebt = creditWallets.fold(
      0.0,
      (sum, w) => sum + w.balance,
    ); // Assuming balance is debt

    // Find transactions with installments
    final installmentTransactions = widget.transactions
        .where((t) => t.installments != null)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _buildCard(
          title: 'Kredi Kartları',
          subtitle: 'Toplam Borç',
          content: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '₺${NumberFormat('#,##0', 'tr_TR').format(totalDebt)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                ...creditWallets.map(
                  (w) => ListTile(
                    leading: const Icon(Icons.credit_card, color: Colors.blue),
                    title: Text(w.name),
                    trailing: Text(
                      '₺${NumberFormat('#,##0', 'tr_TR').format(w.balance.abs())}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLoanTrackingCard(),
        const SizedBox(height: 16),
        if (installmentTransactions.isNotEmpty)
          _buildCard(
            title: 'Taksitli İşlemler',
            subtitle: 'Devam eden taksitler',
            content: Column(
              children: installmentTransactions
                  .map(
                    (t) => ListTile(
                      title: Text(t.description),
                      subtitle: Text(
                        '${t.currentInstallment}/${t.installments} Taksit',
                      ),
                      trailing: Text(
                        '₺${NumberFormat('#,##0', 'tr_TR').format(t.amount)}',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLoanTrackingCard() {
    if (widget.loans.isEmpty) {
      return _buildCard(
        title: 'Kredi Takibi',
        subtitle: 'Aktif kredi bulunmamaktadır',
        content: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Henüz hiç kredi eklenmemiş. Kredi eklemek için "Krediler" sekmesine gidin.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final activeLoans = widget.loans
        .where((loan) => loan.remainingAmount > 0)
        .toList();

    if (activeLoans.isEmpty) {
      return _buildCard(
        title: 'Kredi Takibi',
        subtitle: 'Tüm krediler ödendi',
        content: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Tüm kredileriniz ödendi. Tebrikler!',
            style: TextStyle(color: Colors.green),
          ),
        ),
      );
    }

    return _buildCard(
      title: 'Kredi Takibi',
      subtitle: 'Devam eden krediler',
      content: Column(
        children: activeLoans.map((loan) {
          final progress = loan.totalAmount > 0
              ? (loan.totalAmount - loan.remainingAmount) / loan.totalAmount
              : 0.0;

          final nextInstallment =
              loan.installments
                  .where((installment) => !installment.isPaid)
                  .toList()
                ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

          final upcomingInstallment = nextInstallment.isNotEmpty
              ? nextInstallment.first
              : null;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loan.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${((progress) * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${loan.bankName} - ${loan.totalInstallments} Taksit',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress.toDouble(),
                  backgroundColor: Colors.grey[200],
                  color: progress > 0.7
                      ? Colors.green
                      : (progress > 0.4 ? Colors.orange : Colors.red),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ödenen: ₺${NumberFormat('#,##0', 'tr_TR').format(loan.totalAmount - loan.remainingAmount)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Kalan: ₺${NumberFormat('#,##0', 'tr_TR').format(loan.remainingAmount)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (upcomingInstallment != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sonraki taksit: ${DateFormat('dd.MM.yyyy', 'tr_TR').format(upcomingInstallment.dueDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAssetsTab() {
    final assetWallets = widget.wallets
        .where((w) => w.type != 'credit_card' && w.balance > 0)
        .toList();
    final totalAssets = assetWallets.fold(0.0, (sum, w) => sum + w.balance);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: totalAssets > 0
              ? PieChart(
                  PieChartData(
                    sections: assetWallets.map((w) {
                      final percentage = (w.balance / totalAssets) * 100;
                      final color = Color(int.parse(w.color));
                      return PieChartSectionData(
                        color: color,
                        value: percentage,
                        title: '${percentage.toStringAsFixed(0)}%',
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                )
              : const Center(child: Text('Varlık yok')),
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'Varlık Listesi',
          subtitle:
              'Toplam: ₺${NumberFormat('#,##0', 'tr_TR').format(totalAssets)}',
          content: Column(
            children: assetWallets
                .map(
                  (w) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(int.parse(w.color)),
                      child: Icon(
                        w.type == 'cash' ? Icons.money : Icons.account_balance,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(w.name),
                    trailing: Text(
                      '₺${NumberFormat('#,##0', 'tr_TR').format(w.balance)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildReportsView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        100,
      ), // Bottom padding for filter
      children: [
        _buildOverviewSummaryCards(),
        const SizedBox(height: 16),
        _buildDebtReceivablePanel(),
        const SizedBox(height: 16),
        _buildBudgetGoalComparisonCard(),
        const SizedBox(height: 16),
        _buildPaymentMethodDistributionCard(),
        const SizedBox(height: 16),
        _buildCashFlowTableCard(),
        const SizedBox(height: 16),
        _buildIncomeExpenseLedgerCard(),
        const SizedBox(height: 16),
        _buildIncomeDebtRatioCard(),
        const SizedBox(height: 16),
        _buildRecurringEventsCard(),
        const SizedBox(height: 16),
        _buildFinancialAssetsCard(),
        const SizedBox(height: 16),
        _buildTopSpendingCategoriesCard(),
      ],
    );
  }

  Widget _buildBudgetGoalComparisonCard() {
    // Filter active budgets that are relevant to the current time filter
    final activeBudgets = widget.budgets
        .where((budget) => budget.isActive)
        .toList();

    if (activeBudgets.isEmpty) {
      return _buildCard(
        title: 'Bütçe Hedefleri',
        subtitle: 'Tanımlı bütçe bulunmamaktadır',
        content: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Henüz hiç bütçe hedefi eklenmemiş. Bütçe oluşturmak için "Bütçeler" sekmesine gidin.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Calculate spent amounts for each budget category in the filtered period
    final budgetSpentMap = <String, double>{};

    for (var item in _filteredTransactions) {
      // Handle both Transaction and CreditCardTransaction objects
      if (item is Transaction && item.type == 'expense') {
        budgetSpentMap[item.category] =
            (budgetSpentMap[item.category] ?? 0) + item.amount;
      } else if (item is CreditCardTransaction) {
        // Credit card transactions are always expenses
        budgetSpentMap[item.category] =
            (budgetSpentMap[item.category] ?? 0) + item.amount;
      }
    }

    // Filter budgets that have transactions in the current period
    final relevantBudgets = activeBudgets.where((budget) {
      return budgetSpentMap.containsKey(budget.category) &&
          budgetSpentMap[budget.category]! > 0;
    }).toList();

    if (relevantBudgets.isEmpty) {
      return _buildCard(
        title: 'Bütçe Hedefleri',
        subtitle: 'Bu dönemde harcama yapılan bütçe kategorisi bulunmamaktadır',
        content: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Bu dönemde bütçelendirilen kategorilerde harcama yapılmamış.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return _buildCard(
      title: 'Bütçe Hedef Karşılaştırması',
      subtitle: 'Gerçekleşen harcamalar vs. bütçe hedefleri',
      content: Column(
        children: [
          ...relevantBudgets.map((budget) {
            final spent = budgetSpentMap[budget.category] ?? 0;
            final percentage = budget.amount > 0
                ? (spent / budget.amount) * 100
                : 0;
            final remaining = budget.amount - spent;
            final isOverBudget = spent > budget.amount;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        budget.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isOverBudget
                              ? Colors.red
                              : (percentage > 80
                                    ? Colors.orange
                                    : Colors.green),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${budget.category} - ₺${NumberFormat('#,##0', 'tr_TR').format(budget.amount)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = percentage > 100
                              ? constraints.maxWidth
                              : (constraints.maxWidth * percentage / 100);
                          return Container(
                            height: 8,
                            width: width,
                            decoration: BoxDecoration(
                              color: isOverBudget
                                  ? Colors.red
                                  : (percentage > 80
                                        ? Colors.orange
                                        : Colors.green),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Harcanan: ₺${NumberFormat('#,##0', 'tr_TR').format(spent)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        isOverBudget
                            ? 'Bütçeyi aşan: ₺${NumberFormat('#,##0', 'tr_TR').format(spent - budget.amount)}'
                            : 'Kalan: ₺${NumberFormat('#,##0', 'tr_TR').format(remaining)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isOverBudget ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          // Summary statistics
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  'Bütçe Özeti',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBudgetSummaryItem(
                      title: 'Toplam Bütçe',
                      amount: relevantBudgets.fold(
                        0.0,
                        (sum, b) => sum + b.amount,
                      ),
                      color: Colors.blue,
                    ),
                    _buildBudgetSummaryItem(
                      title: 'Toplam Harcama',
                      amount: relevantBudgets.fold(
                        0.0,
                        (sum, b) => sum + (budgetSpentMap[b.category] ?? 0),
                      ),
                      color: Colors.purple,
                    ),
                    _buildBudgetSummaryItem(
                      title: 'Ortalama Kullanım',
                      amount: relevantBudgets.isNotEmpty
                          ? relevantBudgets.fold(
                                  0.0,
                                  (sum, b) =>
                                      sum +
                                      ((budgetSpentMap[b.category] ?? 0) /
                                          b.amount *
                                          100),
                                ) /
                                relevantBudgets.length
                          : 0,
                      color: Colors.orange,
                      isPercentage: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSummaryItem({
    required String title,
    required double amount,
    required Color color,
    bool isPercentage = false,
  }) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: color)),
        Text(
          isPercentage
              ? '${amount.toStringAsFixed(1)}%'
              : '₺${NumberFormat('#,##0', 'tr_TR').format(amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDebtReceivablePanel() {
    // Calculate total debt from loans
    final totalLoanDebt = widget.loans.fold(
      0.0,
      (sum, loan) => sum + loan.remainingAmount,
    );

    // Calculate credit card debts (balance is negative for debts)
    final creditCardDebts = widget.wallets
        .where((w) => w.type == 'credit_card')
        .fold(0.0, (sum, w) => sum + w.balance.abs());

    // Total debt
    final totalDebt = totalLoanDebt + creditCardDebts;

    // For receivables, we'll look for "receivable" category transactions
    // or transactions marked in a special way
    final receivableTransactions = widget.transactions
        .where(
          (t) =>
              t.category.toLowerCase().contains('alacak') ||
              t.description.toLowerCase().contains('alacak') ||
              t.category.toLowerCase().contains('receivable'),
        )
        .toList();

    final totalReceivables = receivableTransactions.fold(
      0.0,
      (sum, t) => sum + t.amount,
    );

    // Get upcoming payments (next 30 days)
    final upcomingPayments = _getUpcomingPayments();

    // Get upcoming receivables (next 30 days)
    final upcomingReceivables = _getUpcomingReceivables();

    return _buildCard(
      title: 'Borç ve Alacak Durumu',
      subtitle: 'Finansal yükümlülükleriniz ve alacaklarınız',
      content: Column(
        children: [
          // Summary row
          Row(
            children: [
              Expanded(
                child: _buildDebtReceivableSummaryItem(
                  title: 'Toplam Borç',
                  amount: totalDebt,
                  isDebt: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDebtReceivableSummaryItem(
                  title: 'Toplam Alacak',
                  amount: totalReceivables,
                  isDebt: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Debt breakdown
          if (totalDebt > 0) ...[
            const Text(
              'Borç Detayları',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (creditCardDebts > 0)
              _buildDebtReceivableDetailItem(
                title: 'Kredi Kartı Borçları',
                amount: creditCardDebts,
                color: Colors.red,
                icon: Icons.credit_card,
              ),
            if (totalLoanDebt > 0)
              _buildDebtReceivableDetailItem(
                title: 'Kredi Borçları',
                amount: totalLoanDebt,
                color: Colors.orange,
                icon: Icons.account_balance,
              ),
            const SizedBox(height: 16),
          ],
          // Upcoming payments
          if (upcomingPayments.isNotEmpty) ...[
            const Text(
              'Yaklaşan Ödemeler (30 gün)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...upcomingPayments
                .take(3)
                .map(
                  (payment) => _buildUpcomingItem(
                    title: payment['title'],
                    amount: payment['amount'],
                    date: payment['date'],
                    isDebt: true,
                  ),
                ),
            const SizedBox(height: 16),
          ],
          // Upcoming receivables
          if (upcomingReceivables.isNotEmpty) ...[
            const Text(
              'Yaklaşan Alacaklar (30 gün)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...upcomingReceivables
                .take(3)
                .map(
                  (receivable) => _buildUpcomingItem(
                    title: receivable['title'],
                    amount: receivable['amount'],
                    date: receivable['date'],
                    isDebt: false,
                  ),
                ),
          ],
          if (totalDebt == 0 &&
              totalReceivables == 0 &&
              upcomingPayments.isEmpty &&
              upcomingReceivables.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Şu anda bekleyen borç veya alacak bulunmamaktadır.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDebtReceivableSummaryItem({
    required String title,
    required double amount,
    required bool isDebt,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDebt
            ? Colors.red.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDebt
              ? Colors.red.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDebt ? Colors.red : Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₺${NumberFormat('#,##0', 'tr_TR').format(amount.abs())}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDebt ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtReceivableDetailItem({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
          Text(
            '₺${NumberFormat('#,##0', 'tr_TR').format(amount)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingItem({
    required String title,
    required double amount,
    required DateTime date,
    required bool isDebt,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isDebt ? Colors.red : Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('dd.MM.yyyy', 'tr_TR').format(date),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            '₺${NumberFormat('#,##0', 'tr_TR').format(amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDebt ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getUpcomingPayments() {
    final List<Map<String, dynamic>> upcomingPayments = [];
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));

    // Add loan installments due in the next 30 days
    for (var loan in widget.loans) {
      for (var installment in loan.installments) {
        if (!installment.isPaid &&
            installment.dueDate.isAfter(now) &&
            installment.dueDate.isBefore(thirtyDaysFromNow)) {
          upcomingPayments.add({
            'title': '${loan.name} Taksiti',
            'amount': installment.amount,
            'date': installment.dueDate,
          });
        }
      }
    }

    // Add credit card payments (simplified - using cutoff day)
    for (var wallet in widget.wallets.where((w) => w.type == 'credit_card')) {
      // Simplified approach - assume payment is due next month
      final cutoffDay = wallet.cutOffDay;
      final paymentDay = wallet.paymentDay;

      if (cutoffDay > 0 && paymentDay > 0) {
        final nextPaymentDate = DateTime(now.year, now.month + 1, paymentDay);
        if (nextPaymentDate.isAfter(now) &&
            nextPaymentDate.isBefore(thirtyDaysFromNow)) {
          upcomingPayments.add({
            'title': '${wallet.name} Ödemesi',
            'amount': wallet.balance, // This is the debt amount
            'date': nextPaymentDate,
          });
        }
      }
    }

    // Sort by date
    upcomingPayments.sort((a, b) => a['date'].compareTo(b['date']));
    return upcomingPayments;
  }

  List<Map<String, dynamic>> _getUpcomingReceivables() {
    final List<Map<String, dynamic>> upcomingReceivables = [];
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));

    // Look for receivable transactions due in the next 30 days
    // Check regular transactions
    final receivableTransactions = widget.transactions
        .where(
          (t) =>
              t.category.toLowerCase().contains('alacak') ||
              t.description.toLowerCase().contains('alacak') ||
              t.category.toLowerCase().contains('receivable'),
        )
        .toList();

    for (var transaction in receivableTransactions) {
      if (transaction.date.isAfter(now) &&
          transaction.date.isBefore(thirtyDaysFromNow)) {
        upcomingReceivables.add({
          'title': transaction.description,
          'amount': transaction.amount,
          'date': transaction.date,
        });
      }
    }

    // Check credit card transactions for receivables (though this is less common)
    final receivableCCTransactions = widget.creditCardTransactions
        .where(
          (t) =>
              t.category.toLowerCase().contains('alacak') ||
              t.description.toLowerCase().contains('alacak') ||
              t.category.toLowerCase().contains('receivable'),
        )
        .toList();

    for (var transaction in receivableCCTransactions) {
      if (transaction.transactionDate.isAfter(now) &&
          transaction.transactionDate.isBefore(thirtyDaysFromNow)) {
        upcomingReceivables.add({
          'title': transaction.description,
          'amount': transaction.amount,
          'date': transaction.transactionDate,
        });
      }
    }

    // Sort by date
    upcomingReceivables.sort((a, b) => a['date'].compareTo(b['date']));
    return upcomingReceivables;
  }

  Widget _buildOverviewSummaryCards() {
    double income = 0;
    double expense = 0;

    // Process both regular and credit card transactions
    for (var item in _filteredTransactions) {
      // Handle regular transactions
      if (item is Transaction) {
        if (item.type == 'income') {
          income += item.amount;
        } else if (item.type == 'expense') {
          expense += item.amount;
        }
      }
      // Handle credit card transactions (always expenses)
      else if (item is CreditCardTransaction) {
        expense += item.amount;
      }
    }

    final cashFlow = income - expense;

    // Find top spending category
    final expenseCategories = <String, double>{};
    for (var item in _filteredTransactions) {
      // Handle regular transactions
      if (item is Transaction && item.type == 'expense') {
        expenseCategories[item.category] =
            (expenseCategories[item.category] ?? 0) + item.amount;
      }
      // Handle credit card transactions (always expenses)
      else if (item is CreditCardTransaction) {
        expenseCategories[item.category] =
            (expenseCategories[item.category] ?? 0) + item.amount;
      }
    }

    final sortedCategories = expenseCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategory = sortedCategories.isNotEmpty
        ? sortedCategories.first
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Genel Bakış',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Seçili dönem özeti',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Summary cards in a row
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Toplam Gelir',
                        amount: income,
                        color: Colors.green,
                        icon: Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Toplam Gider',
                        amount: expense,
                        color: Colors.red,
                        icon: Icons.trending_down,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Net Bakiye',
                        amount: cashFlow,
                        color: cashFlow >= 0 ? Colors.green : Colors.red,
                        icon: cashFlow >= 0 ? Icons.add : Icons.remove,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'En Çok Harcama',
                        amount: topCategory?.value ?? 0,
                        subtitle: topCategory?.key ?? 'Yok',
                        color: Colors.blue,
                        icon: Icons.category,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    Color color = Colors.blue,
    IconData icon = Icons.info,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₺${NumberFormat('#,##0', 'tr_TR').format(amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildTopSpendingCategoriesCard() {
    final expenseCategories = <String, double>{};

    // Process expense categories for both transaction types
    for (var item in _filteredTransactions) {
      // Handle regular transactions
      if (item is Transaction && item.type == 'expense') {
        expenseCategories[item.category] =
            (expenseCategories[item.category] ?? 0) + item.amount;
      }
      // Handle credit card transactions (always expenses)
      else if (item is CreditCardTransaction) {
        expenseCategories[item.category] =
            (expenseCategories[item.category] ?? 0) + item.amount;
      }
    }

    final sortedCategories = expenseCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalExpense = expenseCategories.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );

    return _buildCard(
      title: 'En Çok Harcanan Kategoriler',
      subtitle: 'Kategori bazlı harcama dağılımı',
      content: Column(
        children: [
          if (sortedCategories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Bu dönemde harcama bulunmamaktadır.'),
            )
          else
            ...sortedCategories.take(5).map((entry) {
              final percentage = totalExpense > 0
                  ? (entry.value / totalExpense) * 100
                  : 0;
              final color = Colors
                  .primaries[entry.key.hashCode % Colors.primaries.length];

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '₺${NumberFormat('#,##0', 'tr_TR').format(entry.value)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[200],
                            color: color,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required Widget content,
    Widget? headerAction,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (headerAction != null) headerAction,
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                const Text(
                  'SON 12 AY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          content,
        ],
      ),
    );
  }

  Widget _buildCashFlowTableCard() {
    double income = 0;
    double expense = 0;

    // Process both regular and credit card transactions
    for (var item in _filteredTransactions) {
      // Handle regular transactions
      if (item is Transaction) {
        if (item.type == 'income') {
          income += item.amount;
        } else if (item.type == 'expense') {
          expense += item.amount;
        }
      }
      // Handle credit card transactions (always expenses)
      else if (item is CreditCardTransaction) {
        expense += item.amount;
      }
    }

    final cashFlow = income - expense;

    return _buildCard(
      title: 'Nakit Akışı Tablosu',
      subtitle: 'Çok mu fazla harcıyorum?',
      headerAction: const Icon(Icons.share, color: Colors.grey),
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Hızlı genel bakış',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Gelir',
                    textAlign: TextAlign.end,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Gider',
                    textAlign: TextAlign.end,
                    style: TextStyle(color: Colors.red[300]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTableRow(
              'Sayım',
              // Count income transactions
              _filteredTransactions
                  .where((t) => t is Transaction && t.type == 'income')
                  .length
                  .toString(),
              // Count expense transactions (including credit card transactions)
              _filteredTransactions
                  .where(
                    (t) =>
                        (t is Transaction && t.type == 'expense') ||
                        t is CreditCardTransaction,
                  )
                  .length
                  .toString(),
            ),
            _buildTableRow(
              'Günlük Ort.',
              '₺${(income / 30).toStringAsFixed(0)}',
              '₺${(expense / 30).toStringAsFixed(0)}',
            ),
            _buildTableRow(
              'Genel Ort.',
              '₺${(income / 1).toStringAsFixed(0)}',
              '₺${(expense / 1).toStringAsFixed(0)}',
            ),
            _buildTableRow(
              'Toplam',
              '₺${income.toStringAsFixed(0)}',
              '₺${expense.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Nakit akışı', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  '₺${cashFlow.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(String label, String col1, String col2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: Colors.grey[700])),
          ),
          Expanded(
            child: Text(
              col1,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              col2,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseLedgerCard() {
    double income = 0;
    double expense = 0;

    // Process both regular and credit card transactions
    for (var item in _filteredTransactions) {
      // Handle regular transactions
      if (item is Transaction) {
        if (item.type == 'income') {
          income += item.amount;
        } else if (item.type == 'expense') {
          expense += item.amount;
        }
      }
      // Handle credit card transactions (always expenses)
      else if (item is CreditCardTransaction) {
        expense += item.amount;
      }
    }

    final expenseCategories = <String, double>{};

    // Process expense categories for both transaction types
    for (var item in _filteredTransactions) {
      // Handle regular transactions
      if (item is Transaction && item.type == 'expense') {
        expenseCategories[item.category] =
            (expenseCategories[item.category] ?? 0) + item.amount;
      }
      // Handle credit card transactions (always expenses)
      else if (item is CreditCardTransaction) {
        expenseCategories[item.category] =
            (expenseCategories[item.category] ?? 0) + item.amount;
      }
    }

    return _buildCard(
      title: 'Gelir ve Gider Defteri (TRY)',
      subtitle: 'Paranızın nereye gittiğini görmek ister misiniz?',
      headerAction: const Icon(Icons.share, color: Colors.grey),
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '₺${(income - expense).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _buildLedgerSection('Gelir', income, [
            _buildLedgerItem(
              'Gelir',
              income,
              Icons.monetization_on,
              Colors.amber,
            ),
            _buildLedgerItem(
              'Bilinmeyen Gelir',
              0,
              Icons.help_outline,
              Colors.grey,
            ),
          ]),
          _buildLedgerSection('Gider', expense, [
            ...expenseCategories.entries.map(
              (e) => _buildLedgerItem(
                e.key,
                e.value,
                _getCategoryIcon(e.key),
                Colors.primaries[e.key.hashCode % Colors.primaries.length],
              ),
            ),
            if (expenseCategories.isEmpty)
              _buildLedgerItem(
                'Henüz gider yok',
                0,
                Icons.money_off,
                Colors.grey,
              ),
          ]),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    if (_categories.isEmpty) {
      // Fallback if categories are not loaded yet
      final cat = defaultCategories.firstWhere(
        (c) => c.name == categoryName,
        orElse: () => defaultCategories.first,
      );
      return cat.icon;
    }

    final cat = _categories.firstWhere(
      (c) => c.name == categoryName,
      orElse: () =>
          _categories.isNotEmpty ? _categories.first : defaultCategories.first,
    );
    return cat.icon;
  }

  Widget _buildLedgerSection(String title, double total, List<Widget> items) {
    return Column(
      children: [
        Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                total.toStringAsFixed(0),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('---', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildLedgerItem(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 16,
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text(amount.toStringAsFixed(0), style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 16),
          const Text('---', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildIncomeDebtRatioCard() {
    // Calculate total income from both regular and credit card transactions
    double totalIncome = 0;

    // Add income from regular transactions
    totalIncome += widget.transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);

    final creditWallets = widget.wallets.where((w) => w.type == 'credit_card');
    final totalDebt = creditWallets.fold(0.0, (sum, w) => sum + w.balance);

    final ratio = totalIncome > 0 ? (totalDebt / totalIncome) * 100 : 0.0;

    return _buildCard(
      title: 'Gelir / Borç Oranı',
      subtitle: 'Toplam gelirimin yüzde kaçı borç?',
      headerAction: const Icon(Icons.share, color: Colors.grey),
      content: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: ratio > 100 ? 100 : ratio,
                          color: Colors.red,
                          radius: 15,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: (100 - ratio) < 0 ? 0 : (100 - ratio),
                          color: Colors.grey[200],
                          radius: 15,
                          showTitle: false,
                        ),
                      ],
                      centerSpaceRadius: 35,
                      sectionsSpace: 0,
                    ),
                  ),
                  Center(
                    child: Text(
                      '${ratio.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Toplam borçlar',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    '₺${totalDebt.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Toplam Gelir (Tümü)',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    '₺${totalIncome.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

  Widget _buildRecurringEventsCard() {
    final installmentTransactions = widget.transactions
        .where((t) => t.installments != null)
        .toList();

    return _buildCard(
      title: 'Taksitli İşlemler',
      subtitle: 'Aktif taksit ödemeleri',
      headerAction: const Icon(Icons.share, color: Colors.grey),
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (installmentTransactions.isEmpty)
              const Text(
                'Aktif taksitli işlem yok',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...installmentTransactions.map(
                (t) => _buildRecurringItem(
                  '${t.description} (${t.currentInstallment}/${t.installments})',
                  t.amount,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringItem(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 16)),
              Text(
                '₺${amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialAssetsCard() {
    final assetWallets = widget.wallets
        .where((w) => w.type != 'credit_card')
        .toList();
    final totalAssets = assetWallets.fold(0.0, (sum, w) => sum + w.balance);

    // Calculate percentages
    final cashAssets = assetWallets
        .where((w) => w.type == 'cash')
        .fold(0.0, (sum, w) => sum + w.balance);
    final bankAssets = assetWallets
        .where((w) => w.type == 'bank')
        .fold(0.0, (sum, w) => sum + w.balance);

    final cashPercentage = totalAssets > 0
        ? (cashAssets / totalAssets) * 100
        : 0.0;
    final bankPercentage = totalAssets > 0
        ? (bankAssets / totalAssets) * 100
        : 0.0;

    return _buildCard(
      title: 'Finansal Varlıklar',
      subtitle: 'Varlık dağılımı',
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    children: [
                      PieChart(
                        PieChartData(
                          sections: [
                            if (cashPercentage > 0)
                              PieChartSectionData(
                                value: cashPercentage,
                                color: Colors.green,
                                radius: 15,
                                showTitle: false,
                              ),
                            if (bankPercentage > 0)
                              PieChartSectionData(
                                value: bankPercentage,
                                color: Colors.blue,
                                radius: 15,
                                showTitle: false,
                              ),
                            if (totalAssets == 0)
                              PieChartSectionData(
                                value: 100,
                                color: Colors.grey[200],
                                radius: 15,
                                showTitle: false,
                              ),
                          ],
                          centerSpaceRadius: 35,
                          sectionsSpace: 0,
                        ),
                      ),
                      Center(
                        child: Text(
                          '₺${NumberFormat.compact().format(totalAssets)}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Toplam finansal varlık',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '₺${NumberFormat('#,##0', 'tr_TR').format(totalAssets)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildAssetRow(
            'Nakit Varlıklar',
            '₺${NumberFormat('#,##0', 'tr_TR').format(cashAssets)}',
            '${cashPercentage.toStringAsFixed(1)}%',
          ),
          _buildAssetRow(
            'Banka Hesapları',
            '₺${NumberFormat('#,##0', 'tr_TR').format(bankAssets)}',
            '${bankPercentage.toStringAsFixed(1)}%',
          ),
        ],
      ),
    );
  }

  Widget _buildAssetRow(
    String label,
    String amount,
    String percentage, {
    bool isSubItem = false,
  }) {
    return Container(
      color: isSubItem ? Colors.white : Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSubItem ? FontWeight.normal : FontWeight.bold,
                fontSize: isSubItem ? 16 : 14,
              ),
            ),
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(percentage),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFilterOption('Günlük'),
              const SizedBox(width: 8),
              _buildFilterOption('Haftalık'),
              const SizedBox(width: 8),
              _buildFilterOption('Aylık'),
              const SizedBox(width: 8),
              _buildFilterOption('Yıllık'),
              const SizedBox(width: 8),
              _buildFilterOption('Özel'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label) {
    final isSelected = _selectedTimeFilter == label;
    return GestureDetector(
      onTap: () {
        if (label == 'Özel') {
          _selectDateRange();
        } else {
          setState(() {
            _selectedTimeFilter = label;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00BFA5) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF00BFA5),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00BFA5),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedTimeFilter = 'Özel';
      });
    }
  }

  // Enhanced filter bar with additional filters
  Widget _buildAdvancedFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Hesap',
                    value: _selectedWalletId == 'all'
                        ? 'Tümü'
                        : _getWalletName(_selectedWalletId),
                    onTap: _showWalletFilterDialog,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Kategori',
                    value: _selectedCategory == 'all'
                        ? 'Tümü'
                        : _selectedCategory,
                    onTap: _showCategoryFilterDialog,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Tür',
                    value: _selectedTransactionType == 'all'
                        ? 'Tümü'
                        : _getTransactionTypeLabel(_selectedTransactionType),
                    onTap: _showTypeFilterDialog,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF007AFF)),
            onPressed: _showAdvancedFilterDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey[300]!,
          ), // Fix the nullability issue
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _getWalletName(String walletId) {
    final wallet = widget.wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => Wallet(
        id: '',
        name: 'Bilinmeyen',
        balance: 0,
        type: 'unknown',
        color: '0xFF000000',
        icon: 'money',
        creditLimit: 0.0,
      ),
    );
    return wallet.name;
  }

  String _getTransactionTypeLabel(String type) {
    switch (type) {
      case 'income':
        return 'Gelir';
      case 'expense':
        return 'Gider';
      case 'transfer':
        return 'Transfer';
      default:
        return 'Tümü';
    }
  }

  String _getWalletTypeName(String type) {
    switch (type) {
      case 'cash':
        return 'Nakit';
      case 'credit_card':
        return 'Kredi Kartı';
      case 'bank':
        return 'Banka Hesabı';
      default:
        return 'Diğer';
    }
  }

  String _getShortWalletTypeName(String type) {
    switch (type) {
      case 'Nakit':
        return 'Nkt';
      case 'Kredi Kartı':
        return 'KK';
      case 'Banka Hesabı':
        return 'BH';
      default:
        return 'Dğr';
    }
  }

  Color _getWalletTypeColor(String type) {
    switch (type) {
      case 'Nakit':
        return Colors.green;
      case 'Kredi Kartı':
        return Colors.red;
      case 'Banka Hesabı':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showWalletFilterDialog() async {
    final selectedWalletId = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hesap Seçin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Tüm Hesaplar'),
                  value: 'all',
                  groupValue: _selectedWalletId,
                  onChanged: (value) {
                    Navigator.of(context).pop(value);
                  },
                ),
                ...widget.wallets.map((wallet) {
                  return RadioListTile<String>(
                    title: Text(wallet.name),
                    value: wallet.id,
                    groupValue: _selectedWalletId,
                    onChanged: (value) {
                      Navigator.of(context).pop(value);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selectedWalletId != null) {
      setState(() {
        _selectedWalletId = selectedWalletId;
      });
    }
  }

  Future<void> _showCategoryFilterDialog() async {
    // Get all unique categories from transactions
    final categories = <String>{};

    // Add categories from regular transactions
    for (var transaction in widget.transactions) {
      categories.add(transaction.category);
    }

    // Add categories from credit card transactions
    for (var transaction in widget.creditCardTransactions) {
      categories.add(transaction.category);
    }

    final sortedCategories = categories.toList()..sort();

    final selectedCategory = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kategori Seçin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Tüm Kategoriler'),
                  value: 'all',
                  groupValue: _selectedCategory,
                  onChanged: (value) {
                    Navigator.of(context).pop(value);
                  },
                ),
                ...sortedCategories.map((category) {
                  return RadioListTile<String>(
                    title: Text(category),
                    value: category,
                    groupValue: _selectedCategory,
                    onChanged: (value) {
                      Navigator.of(context).pop(value);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selectedCategory != null) {
      setState(() {
        _selectedCategory = selectedCategory;
      });
    }
  }

  Future<void> _showTypeFilterDialog() async {
    final selectedType = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('İşlem Türü Seçin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Tüm Türler'),
                  value: 'all',
                  groupValue: _selectedTransactionType,
                  onChanged: (value) {
                    Navigator.of(context).pop(value);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Gelir'),
                  value: 'income',
                  groupValue: _selectedTransactionType,
                  onChanged: (value) {
                    Navigator.of(context).pop(value);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Gider'),
                  value: 'expense',
                  groupValue: _selectedTransactionType,
                  onChanged: (value) {
                    Navigator.of(context).pop(value);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Transfer'),
                  value: 'transfer',
                  groupValue: _selectedTransactionType,
                  onChanged: (value) {
                    Navigator.of(context).pop(value);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedType != null) {
      setState(() {
        _selectedTransactionType = selectedType;
      });
    }
  }

  Future<void> _showAdvancedFilterDialog() async {
    // For now, we can reset all filters
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filtre Seçenekleri'),
          content: const Text('Gelişmiş filtreleme seçenekleri burada olacak.'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedWalletId = 'all';
                  _selectedCategory = 'all';
                  _selectedTransactionType = 'all';
                });
                Navigator.of(context).pop();
              },
              child: const Text('Filtreleri Sıfırla'),
            ),
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  // The filtered transactions getter is already updated with all filters

  Widget _buildPaymentMethodDistributionCard() {
    // Group expenses by wallet type (payment method)
    final paymentMethodExpenses = <String, double>{};
    double totalExpense = 0;

    for (var item in _filteredTransactions) {
      // Handle regular transactions
      if (item is Transaction && item.type == 'expense') {
        final wallet = widget.wallets.firstWhere(
          (w) => w.id == item.walletId,
          orElse: () => Wallet(
            id: '',
            name: 'Bilinmeyen',
            balance: 0,
            type: 'unknown',
            color: '0xFF000000',
            icon: 'money',
            creditLimit: 0.0,
          ),
        );

        final walletType = _getWalletTypeName(wallet.type);
        paymentMethodExpenses[walletType] =
            (paymentMethodExpenses[walletType] ?? 0) + item.amount;
        totalExpense += item.amount;
      }
      // Handle credit card transactions (always expenses)
      else if (item is CreditCardTransaction) {
        // For credit card transactions, we'll categorize them as "Kredi Kartı"
        paymentMethodExpenses['Kredi Kartı'] =
            (paymentMethodExpenses['Kredi Kartı'] ?? 0) + item.amount;
        totalExpense += item.amount;
      }
    }

    final sortedMethods = paymentMethodExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildCard(
      title: 'Ödeme Yöntemi Dağılımı',
      subtitle: 'Harcamaların ödeme yöntemine göre dağılımı',
      content: Column(
        children: [
          if (sortedMethods.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Bu dönemde harcama bulunmamaktadır.'),
            )
          else
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      sortedMethods
                          .map((e) => e.value)
                          .reduce((a, b) => a > b ? a : b) *
                      1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final method = sortedMethods[group.x.toInt()].key;
                        final amount = rod.toY;
                        final percentage = totalExpense > 0
                            ? (amount / totalExpense) * 100
                            : 0;
                        return BarTooltipItem(
                          '$method\n${NumberFormat('#,##0', 'tr_TR').format(amount)} ₺\n${percentage.toStringAsFixed(1)}%',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < sortedMethods.length) {
                            return Text(
                              _getShortWalletTypeName(
                                sortedMethods[value.toInt()].key,
                              ),
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
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
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: sortedMethods.asMap().entries.map((entry) {
                    final index = entry.key;
                    final methodData = entry.value;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: methodData.value,
                          color: _getWalletTypeColor(methodData.key),
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Add summary text
          if (totalExpense > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: sortedMethods.map((methodData) {
                  final percentage = (methodData.value / totalExpense) * 100;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          methodData.key,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}% (₺${NumberFormat('#,##0', 'tr_TR').format(methodData.value)})',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodDistribution(Map<String, double> paymentMethods, double totalExpense) {
    final sortedMethods = paymentMethods.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ödeme Yöntemi Dağılımı',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: sortedMethods.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final method = sortedMethods[group.x.toInt()].key;
                      final amount = rod.toY;
                      final percentage = totalExpense > 0 ? (amount / totalExpense) * 100 : 0;
                      return BarTooltipItem(
                        '$method\n${NumberFormat('#,##0', 'tr_TR').format(amount)} ₺\n${percentage.toStringAsFixed(1)}%',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < sortedMethods.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              sortedMethods[value.toInt()].key,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
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
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                barGroups: sortedMethods.asMap().entries.map((entry) {
                  final index = entry.key;
                  final methodData = entry.value;
                  
                  // Determine color based on payment method
                  Color barColor;
                  if (methodData.key.contains('Kredi')) {
                    barColor = const Color(0xFFFF3B30); // Red for credit card
                  } else {
                    barColor = const Color(0xFF34C759); // Green for cash
                  }

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: methodData.value,
                        color: barColor,
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Summary text
          if (totalExpense > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: sortedMethods.map((methodData) {
                  final percentage = (methodData.value / totalExpense) * 100;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: methodData.key.contains('Kredi')
                                    ? const Color(0xFFFF3B30)
                                    : const Color(0xFF34C759),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              methodData.key,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}% (₺${NumberFormat('#,##0', 'tr_TR').format(methodData.value)})',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          if (totalExpense > 0 && paymentMethods.containsKey('Kredi Kartı'))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFF3B30).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFFFF3B30),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Harcamalarınızın %${((paymentMethods['Kredi Kartı']! / totalExpense) * 100).toStringAsFixed(0)}\'ini kredi kartı ile yapıyorsunuz.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFFF3B30),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCategoryDetails(String category) {
    // Get all transactions for this category
    final categoryTransactions = <Map<String, dynamic>>[];
    
    for (var item in _filteredTransactions) {
      if (item is Transaction && item.category == category && item.type == 'expense') {
        categoryTransactions.add({
          'type': 'normal',
          'description': item.description,
          'amount': item.amount,
          'date': item.date,
          'wallet': widget.wallets.firstWhere(
            (w) => w.id == item.walletId,
            orElse: () => widget.wallets.isNotEmpty ? widget.wallets.first : Wallet(
              id: '',
              name: 'Bilinmeyen',
              balance: 0,
              type: 'cash',
              color: '0xFF8E8E93',
              icon: 'cash',
              creditLimit: 0.0,
            ),
          ).name,
        });
      } else if (item is CreditCardTransaction && item.category == category) {
        categoryTransactions.add({
          'type': 'credit_card',
          'description': item.description,
          'amount': item.amount,
          'date': item.transactionDate,
          'wallet': 'Kredi Kartı',
        });
      }
    }

    // Sort by amount (descending)
    categoryTransactions.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

    // Calculate total
    final total = categoryTransactions.fold<double>(
      0,
      (sum, item) => sum + (item['amount'] as double),
    );

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.primaries[category.hashCode % Colors.primaries.length],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Toplam: ₺${NumberFormat('#,##0', 'tr_TR').format(total)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Transaction list
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: categoryTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = categoryTransactions[index];
                      final percentage = ((transaction['amount'] as double) / total) * 100;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.primaries[category.hashCode % Colors.primaries.length].withOpacity(0.2),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Colors.primaries[category.hashCode % Colors.primaries.length],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          transaction['description'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '${transaction['wallet']} • ${DateFormat('dd MMM yyyy', 'tr_TR').format(transaction['date'] as DateTime)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₺${NumberFormat('#,##0', 'tr_TR').format(transaction['amount'])}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
