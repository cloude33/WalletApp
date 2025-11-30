import 'package:flutter/material.dart';
import 'dart:convert';

import '../models/wallet.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../services/data_service.dart';
import '../services/budget_alert_service.dart';
import '../services/notification_service.dart';
import '../utils/currency_helper.dart';
import 'notification_history_screen.dart';
import 'add_transaction_screen.dart';
import 'add_wallet_screen.dart';
import 'add_budget_screen.dart';
import 'edit_transaction_screen.dart';
import 'edit_wallet_screen.dart';
import 'manage_wallets_screen.dart';
import 'manage_goals_screen.dart';
import 'manage_budgets_screen.dart';
import 'calendar_screen.dart';
import 'statistics_screen.dart';
import 'categories_screen.dart';
import 'settings_screen.dart';
import 'recurring_transaction_list_screen.dart';
import '../services/recurring_transaction_service.dart';
import '../repositories/recurring_transaction_repository.dart';
import 'credit_card_list_screen.dart';
import 'debt_list_screen.dart';
import '../services/credit_card_service.dart';
import '../models/credit_card_transaction.dart';
import '../models/credit_card.dart';
import 'edit_credit_card_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final DataService _dataService = DataService();
  final BudgetAlertService _budgetAlertService = BudgetAlertService();
  final NotificationService _notificationService = NotificationService();
  final CreditCardService _creditCardService = CreditCardService();

  User? _currentUser;
  List<Wallet> wallets = [];
  List<Goal> goals = [];
  List<Transaction> transactions = [];
  List<Budget> budgets = [];
  List<BudgetWarning> budgetWarnings = [];
  List<Category> _categories = [];
  List<CreditCardTransaction> _creditCardTransactions = [];
  Map<String, CreditCard> _creditCards = {};
  bool _loading = true;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    var user = await _dataService.getCurrentUser();

    // Eğer kullanıcı yoksa, default kullanıcı oluştur
    if (user == null) {
      user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Kullanıcı',
        email: null,
        avatar: null,
        currencyCode: 'TRY',
        currencySymbol: '₺',
      );
      await _dataService.saveUser(user);

      // Tüm kullanıcılar listesine de ekle
      final allUsers = await _dataService.getAllUsers();
      allUsers.add(user);
      await _dataService.saveAllUsers(allUsers);
    }

    final loadedWallets = await _dataService.getWallets();
    final loadedGoals = await _dataService.getGoals();
    final loadedTransactions = await _dataService.getTransactions();
    final loadedBudgets = await _dataService.getBudgets();
    final warnings = await _budgetAlertService.checkBudgets();
    final loadedCategories = await _dataService.getCategories();
    final unreadCount = await _notificationService.getUnreadCount();

    // Load credit card transactions
    final cards = await _creditCardService.getAllCards();
    final Map<String, CreditCard> cardMap = {};
    final List<CreditCardTransaction> allCCTransactions = [];

    for (var card in cards) {
      cardMap[card.id] = card;
      final ccTransactions = await _creditCardService.getCardTransactions(
        card.id,
      );
      allCCTransactions.addAll(ccTransactions);
    }

    setState(() {
      _currentUser = user;
      wallets = loadedWallets;
      goals = loadedGoals;
      transactions = loadedTransactions;
      budgets = loadedBudgets;
      budgetWarnings = warnings;
      _categories = loadedCategories;
      _unreadNotificationCount = unreadCount;
      _creditCardTransactions = allCCTransactions;
      _creditCards = cardMap;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              title: const Text('Ana Sayfa'),
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const NotificationHistoryScreen(),
                          ),
                        );
                        _loadData(); // Reload to update unread count
                      },
                    ),
                    if (_unreadNotificationCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            _unreadNotificationCount > 99
                                ? '99+'
                                : _unreadNotificationCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            )
          : null,
      body: _selectedIndex == 0
          ? _buildHomeContent()
          : _selectedIndex == 1
          ? CalendarScreen(transactions: transactions)
          : _selectedIndex == 2
          ? StatisticsScreen(
              transactions: transactions,
              wallets: wallets,
              budgets: budgets,
              creditCardTransactions: _creditCardTransactions,
            )
          : const SettingsScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: const Color(
                0xFF00BFA5,
              ), // İstatistik ile aynı yeşil
              unselectedItemColor: const Color(0xFF8E8E93),
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Ana Sayfa',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined),
                  activeIcon: Icon(Icons.calendar_today),
                  label: 'Takvim',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.pie_chart_outline),
                  activeIcon: Icon(Icons.pie_chart),
                  label: 'İstatistik',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Ayarlar',
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(
                  0xFF00BFA5,
                ), // İstatistik ile aynı yeşil renk
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00BFA5).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () async {
                  // Show quick add options
                  final result = await showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (context) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              margin: const EdgeInsets.all(16),
                              height: 4,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.add_shopping_cart,
                                color: Color(0xFFFDB32A),
                              ),
                              title: const Text('Hızlı Gider Ekle'),
                              onTap: () {
                                Navigator.pop(context, 'expense');
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.add_card,
                                color: Color(0xFFFDB32A),
                              ),
                              title: const Text('Hızlı Gelir Ekle'),
                              onTap: () {
                                Navigator.pop(context, 'income');
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.account_balance_wallet,
                                color: Color(0xFFFDB32A),
                              ),
                              title: const Text('Cüzdan Ekle'),
                              onTap: () {
                                Navigator.pop(context, 'wallet');
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.account_balance,
                                color: Color(0xFFFDB32A),
                              ),
                              title: const Text('Bütçe Ekle'),
                              onTap: () {
                                Navigator.pop(context, 'budget');
                              },
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(
                                Icons.add,
                                color: Color(0xFFFDB32A),
                              ),
                              title: const Text('Detaylı Ekle'),
                              onTap: () {
                                Navigator.pop(context, 'detailed');
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );

                  if (result != null) {
                    switch (result) {
                      case 'expense':
                      case 'income':
                        // Reload wallets before opening transaction screen
                        final freshWallets = await _dataService.getWallets();
                        if (!mounted) return;

                        // Quick add transaction
                        final transactionResult = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTransactionScreen(
                              wallets: freshWallets,
                              defaultType: result,
                            ),
                          ),
                        );
                        if (transactionResult == true) {
                          _loadData();
                        }
                        break;
                      case 'wallet':
                        // Add wallet
                        final walletResult = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddWalletScreen(),
                          ),
                        );
                        if (walletResult == true) {
                          _loadData();
                        }
                        break;
                      case 'budget':
                        // Add budget
                        final budgetResult = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddBudgetScreen(),
                          ),
                        );
                        if (budgetResult == true) {
                          _loadData();
                        }
                        break;
                      case 'detailed':
                        // Reload wallets before opening transaction screen
                        final freshWallets = await _dataService.getWallets();
                        if (!mounted) return;

                        // Detailed add
                        final detailedResult = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddTransactionScreen(wallets: freshWallets),
                          ),
                        );
                        if (detailedResult == true) {
                          _loadData();
                        }
                        break;
                    }
                  }
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.add, color: Colors.white, size: 32),
              ),
            )
          : null,
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // _buildHeader() removed
            const SizedBox(height: 20),
            _buildSummaryCard(),
            const SizedBox(height: 20),
            if (budgetWarnings.isNotEmpty) ...[
              _buildBudgetWarnings(),
              const SizedBox(height: 20),
            ],
            _buildBudgetsSection(), // Bütçeler
            const SizedBox(height: 20),
            _buildAllTransactions(), // Tüm işlemler (normal + kredi kartı)
            const SizedBox(height: 20),
            _buildGoalsSection(), // Hedeflerim
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAllTransactions() {
    // Tüm işlemleri birleştir (normal + kredi kartı)
    List<Map<String, dynamic>> allTransactions = [];

    // Normal işlemleri ekle
    for (var transaction in transactions) {
      allTransactions.add({
        'type': 'normal',
        'data': transaction,
        'date': transaction.date,
      });
    }

    // Kredi kartı işlemlerini ekle
    for (var ccTransaction in _creditCardTransactions) {
      allTransactions.add({
        'type': 'credit_card',
        'data': ccTransaction,
        'date': ccTransaction.transactionDate,
      });
    }

    // Tarihe göre sırala
    allTransactions.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );

    if (allTransactions.isEmpty) {
      return const SizedBox.shrink();
    }

    // İşlemleri tarihe göre grupla
    Map<String, List<Map<String, dynamic>>> groupedTransactions = {};
    for (var item in allTransactions) {
      final dateKey = _getDateKey(item['date'] as DateTime);
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(item);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İşlemler',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 12),
          ...groupedTransactions.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(
                    _getDateHeader(entry.key),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ),
                ...entry.value.map((item) {
                  if (item['type'] == 'normal') {
                    return _buildTransactionItem(item['data'] as Transaction);
                  } else {
                    return _buildCreditCardTransactionItem(
                      item['data'] as CreditCardTransaction,
                    );
                  }
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  String _getDateHeader(String dateKey) {
    final parts = dateKey.split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Bugün';
    } else if (date == yesterday) {
      return 'Dün';
    } else {
      final months = [
        'Ocak',
        'Şubat',
        'Mart',
        'Nisan',
        'Mayıs',
        'Haziran',
        'Temmuz',
        'Ağustos',
        'Eylül',
        'Ekim',
        'Kasım',
        'Aralık',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final wallet = wallets.firstWhere(
      (w) => w.id == transaction.walletId,
      orElse: () => wallets.isNotEmpty
          ? wallets.first
          : Wallet(
              id: '',
              name: 'Bilinmeyen',
              balance: 0,
              type: 'cash',
              color: '0xFF8E8E93',
              icon: 'cash',
              creditLimit: 0.0,
            ),
    );

    final category = _categories.firstWhere(
      (c) => c.name == transaction.category,
      orElse: () =>
          _categories.isNotEmpty ? _categories.first : defaultCategories.first,
    );

    final isIncome = transaction.type == 'income';
    final color = isIncome ? const Color(0xFF34C759) : const Color(0xFFFF3B30);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditTransactionScreen(
              transaction: transaction,
              wallets: wallets,
            ),
          ),
        );
        if (result == true) {
          _loadData();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(category.icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        wallet.name,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      if (transaction.installments != null) ...[
                        const Text(
                          ' • ',
                          style: TextStyle(color: Color(0xFF8E8E93)),
                        ),
                        Text(
                          '${transaction.currentInstallment}/${transaction.installments} Taksit',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${CurrencyHelper.formatAmount(transaction.amount, _currentUser)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCardTransactionItem(CreditCardTransaction transaction) {
    final card = _creditCards[transaction.cardId];
    final color = const Color(0xFFFF3B30); // Always expense (red)
    final isInstallment = transaction.installmentCount > 1;

    return GestureDetector(
      onTap: () async {
        if (card != null) {
          // Navigate to edit credit card transaction screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditCreditCardTransactionScreen(
                card: card,
                transaction: transaction,
              ),
            ),
          );
          if (result == true) {
            _loadData();
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: card?.color ?? Colors.blue, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (card?.color ?? Colors.blue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.credit_card,
                color: card?.color ?? Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (card != null) ...[
                        Text(
                          '${card.bankName} •••• ${card.last4Digits}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        if (isInstallment) ...[
                          const Text(
                            ' • ',
                            style: TextStyle(color: Color(0xFF8E8E93)),
                          ),
                          Text(
                            '${transaction.installmentsPaid}/${transaction.installmentCount} Taksit',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ] else ...[
                        Text(
                          transaction.category,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-${CurrencyHelper.formatAmount(transaction.amount, _currentUser)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate monthly income and expenses
    final monthlyTransactions = transactions.where(
      (t) => t.date.month == now.month && t.date.year == now.year,
    );

    final monthlyIncome = monthlyTransactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);

    // Calculate monthly expenses including both regular and credit card transactions
    final regularMonthlyExpense = monthlyTransactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    // Add credit card transactions for the current month
    final creditCardMonthlyExpense = _creditCardTransactions
        .where(
          (t) =>
              t.transactionDate.month == now.month &&
              t.transactionDate.year == now.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    final monthlyExpense = regularMonthlyExpense + creditCardMonthlyExpense;

    // Calculate net balance and savings
    final netBalance = monthlyIncome - monthlyExpense;
    final savingsRate = monthlyIncome > 0
        ? ((monthlyIncome - monthlyExpense) / monthlyIncome * 100)
        : 0.0;

    // Get active budgets with proper date checking
    final activeBudgets = budgets.where(
      (b) =>
          b.isActive &&
          b.startDate.isBefore(today.add(const Duration(days: 1))) &&
          b.endDate.isAfter(today.subtract(const Duration(days: 1))),
    );

    // Calculate category-based budget usage including both regular and credit card transactions
    double totalBudget = 0;
    double totalSpent = 0;
    int budgetsExceeded = 0;

    for (var budget in activeBudgets) {
      totalBudget += budget.amount;

      // Calculate spending for this budget's category from regular transactions
      final regularCategorySpent = monthlyTransactions
          .where((t) => t.type == 'expense' && t.category == budget.category)
          .fold(0.0, (sum, t) => sum + t.amount);

      // Calculate spending for this budget's category from credit card transactions
      final creditCardCategorySpent = _creditCardTransactions
          .where(
            (t) =>
                t.transactionDate.month == now.month &&
                t.transactionDate.year == now.year &&
                t.category == budget.category,
          )
          .fold(0.0, (sum, t) => sum + t.amount);

      final categorySpent = regularCategorySpent + creditCardCategorySpent;

      totalSpent += categorySpent;

      if (categorySpent > budget.amount) {
        budgetsExceeded++;
      }
    }

    // If no budgets, use total expense logic removed. Default is 0.

    final remainingBudget = totalBudget - totalSpent;
    final usagePercentage = totalBudget > 0 ? (totalSpent / totalBudget) : 0.0;
    final clampedPercentage = usagePercentage.clamp(0.0, 1.0);

    // Determine status color and message
    Color statusColor;
    String statusMessage;

    if (totalBudget == 0) {
      statusColor = const Color(0xFF8E8E93); // Grey
      statusMessage = 'Bütçe Tanımlanmadı';
    } else if (usagePercentage >= 1.0) {
      statusColor = const Color(0xFFFF3B30);
      statusMessage = 'Bütçe Aşıldı!';
    } else if (usagePercentage >= 0.9) {
      statusColor = const Color(0xFFFF9500);
      statusMessage = 'Dikkat: Bütçe Dolmak Üzere';
    } else if (usagePercentage >= 0.75) {
      statusColor = const Color(0xFFFDB32A);
      statusMessage = 'İyi Gidiyorsunuz';
    } else {
      statusColor = const Color(0xFF34C759);
      statusMessage = 'Harika! Bütçe Kontrolünde';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Colored Section - Budget Status
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bütçe Durumu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyHelper.formatAmount(
                          totalBudget == 0 ? totalSpent : remainingBudget.abs(),
                          _currentUser,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          totalBudget == 0
                              ? 'Toplam Harcama'
                              : (remainingBudget >= 0 ? 'Kalan' : 'Aşım'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(usagePercentage * 100).toStringAsFixed(1)}% Kullanıldı',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${CurrencyHelper.formatAmount(totalSpent, _currentUser)} / ${CurrencyHelper.formatAmount(totalBudget, _currentUser)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: clampedPercentage,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  if (budgetsExceeded > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$budgetsExceeded kategori bütçesi aşıldı',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Middle Section - Income/Expense Balance
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: netBalance >= 0
                    ? const Color(0xFF34C759).withOpacity(0.1)
                    : const Color(0xFFFF3B30).withOpacity(0.1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        netBalance >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: netBalance >= 0
                            ? const Color(0xFF34C759)
                            : const Color(0xFFFF3B30),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            netBalance >= 0 ? 'Net Kazanç' : 'Net Kayıp',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8E8E93),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyHelper.formatAmount(
                              netBalance.abs(),
                              _currentUser,
                            ),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: netBalance >= 0
                                  ? const Color(0xFF34C759)
                                  : const Color(0xFFFF3B30),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: savingsRate >= 20
                            ? const Color(0xFF34C759)
                            : const Color(0xFF8E8E93),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${savingsRate.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: savingsRate >= 20
                                ? const Color(0xFF34C759)
                                : const Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Tasarruf',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Section - Detailed Stats
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailedStat(
                    'Gelir',
                    monthlyIncome,
                    Icons.arrow_downward,
                    const Color(0xFF34C759),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFFE5E5EA),
                  ),
                  _buildDetailedStat(
                    'Gider',
                    monthlyExpense,
                    Icons.arrow_upward,
                    const Color(0xFFFF3B30),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFFE5E5EA),
                  ),
                  _buildDetailedStat(
                    'Bütçe',
                    totalBudget,
                    Icons.account_balance_wallet,
                    const Color(0xFF5E5CE6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStat(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyHelper.formatAmount(amount, _currentUser),
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsSection() {
    if (goals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hedeflerim',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageGoalsScreen(),
                    ),
                  ).then((value) => _loadData());
                },
                child: const Text('Tümünü Gör'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                final progress = goal.currentAmount / goal.targetAmount;
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${CurrencyHelper.formatAmount(goal.currentAmount, _currentUser)} / ${CurrencyHelper.formatAmount(goal.targetAmount, _currentUser)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            backgroundColor: const Color(0xFFE5E5EA),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFDB32A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetsSection() {
    return FutureBuilder<List<Budget>>(
      future: _dataService.getBudgets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final budgets = snapshot.data!;
        final now = DateTime.now();
        final activeBudgets = budgets.where((budget) {
          return budget.isActive &&
              budget.startDate.isBefore(now) &&
              budget.endDate.isAfter(now);
        }).toList();

        if (activeBudgets.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bütçelerim',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageBudgetsScreen(),
                        ),
                      ).then((value) => _loadData());
                    },
                    child: const Text('Tümünü Gör'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: activeBudgets.length,
                  itemBuilder: (context, index) {
                    final budget = activeBudgets[index];
                    final percentage = budget.percentage;
                    final remaining = budget.remaining;

                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    budget.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1C1C1E),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: percentage > 90
                                        ? Colors.red.withOpacity(0.2)
                                        : percentage > 75
                                        ? Colors.orange.withOpacity(0.2)
                                        : Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: percentage > 90
                                          ? Colors.red
                                          : percentage > 75
                                          ? Colors.orange
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              budget.category,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (percentage / 100).clamp(0.0, 1.0),
                                backgroundColor: const Color(0xFFE5E5EA),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  percentage > 90
                                      ? Colors.red
                                      : percentage > 75
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  CurrencyHelper.formatAmount(
                                    remaining,
                                    _currentUser,
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: remaining < 0
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                                Text(
                                  CurrencyHelper.formatAmount(
                                    budget.amount,
                                    _currentUser,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBudgetWarnings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bütçe Uyarıları',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 12),
          ...budgetWarnings.map((warning) {
            Color color;
            IconData icon;
            Color bgColor;

            switch (warning.severity) {
              case BudgetWarningSeverity.exceeded:
                color = const Color(0xFFFF3B30);
                icon = Icons.error;
                bgColor = const Color(0xFFFF3B30).withOpacity(0.1);
                break;
              case BudgetWarningSeverity.critical:
                color = const Color(0xFFFF9500);
                icon = Icons.warning;
                bgColor = const Color(0xFFFF9500).withOpacity(0.1);
                break;
              case BudgetWarningSeverity.warning:
                color = const Color(0xFFFFCC00);
                icon = Icons.info;
                bgColor = const Color(0xFFFFCC00).withOpacity(0.1);
                break;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          warning.message,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${warning.currentSpending.toStringAsFixed(0)} / ${warning.budgetAmount.toStringAsFixed(0)} ₺',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '%${warning.percentage.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecurringTransactionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tekrarlayan İşlemler',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              TextButton(
                onPressed: () => _navigateToRecurringTransactions(),
                child: const Text('Tümünü Gör'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _navigateToRecurringTransactions(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BFA5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.repeat,
                          color: Color(0xFF00BFA5),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Otomatik İşlemler',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1C1C1E),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Düzenli ödemelerinizi otomatikleştirin',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFF8E8E93),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToRecurringTransactions() async {
    final repository = RecurringTransactionRepository();
    await repository.init();

    final service = RecurringTransactionService(
      repository,
      _dataService,
      _notificationService,
    );

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecurringTransactionListScreen(service: service),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Widget _buildCreditCardsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kredi Kartları',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              TextButton(
                onPressed: () => _navigateToCreditCards(),
                child: const Text('Tümünü Gör'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _navigateToCreditCards(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667eea).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.credit_card,
                          color: Color(0xFF667eea),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kredi Kartı Takibi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1C1C1E),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Kartlarınızı ve borçlarınızı yönetin',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFF8E8E93),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToCreditCards() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreditCardListScreen()),
    );

    if (result == true) {
      _loadData();
    }
  }

  Widget _buildDebtTrackingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Borç/Alacak Takibi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              TextButton(
                onPressed: () => _navigateToDebtTracking(),
                child: const Text('Tümünü Gör'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _navigateToDebtTracking(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9500).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Color(0xFFFF9500),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Borç ve Alacak Yönetimi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1C1C1E),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Borçlarınızı ve alacaklarınızı takip edin',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFF8E8E93),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToDebtTracking() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DebtListScreen()),
    );

    if (result == true) {
      _loadData();
    }
  }
}
