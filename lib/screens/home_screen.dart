// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:convert';

import '../models/wallet.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../models/loan.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../utils/currency_helper.dart';
import 'notification_history_screen.dart';
import 'add_transaction_screen.dart';
import 'add_wallet_screen.dart';
import 'edit_transaction_screen.dart';
import 'manage_goals_screen.dart';
import 'calendar_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import 'add_bill_screen.dart';
import '../services/credit_card_service.dart';
import '../services/transaction_filter_service.dart';
import '../models/credit_card_transaction.dart';
import '../models/credit_card.dart';
import 'edit_credit_card_transaction_screen.dart';
import 'credit_card_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();
  final CreditCardService _creditCardService = CreditCardService();
  final TransactionFilterService _filterService = TransactionFilterService();

  User? _currentUser;
  List<Wallet> wallets = [];
  List<Goal> goals = [];
  List<Transaction> transactions = [];
  List<Category> _categories = [];
  List<CreditCardTransaction> _creditCardTransactions = [];
  Map<String, CreditCard> _creditCards = {};
  List<Loan> _loans = [];
  bool _loading = true;
  int _unreadNotificationCount = 0;
  
  // Transaction filter state
  // ignore: prefer_final_fields
  List<String> _selectedCardIds = [];
  bool _isFilterActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Uygulama ön plana geldiğinde verileri yenile
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
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
    final loadedCategories = (await _dataService.getCategories()).cast<Category>();
    final loadedLoans = await _dataService.getLoans();
    final unreadCount = await _notificationService.getUnreadCount();

    // Load credit card transactions
    final cards = await _creditCardService.getAllCards();
    debugPrint('DEBUG _loadData: Found ${cards.length} credit cards');
    final Map<String, CreditCard> cardMap = {};
    final List<CreditCardTransaction> allCCTransactions = [];

    for (var card in cards) {
      cardMap[card.id] = card;
      final ccTransactions = await _creditCardService.getCardTransactions(
        card.id,
      );
      debugPrint(
        'DEBUG _loadData: Card ${card.bankName} has ${ccTransactions.length} transactions',
      );
      allCCTransactions.addAll(ccTransactions);
    }
    debugPrint(
      'DEBUG _loadData: Total CC transactions: ${allCCTransactions.length}',
    );

    setState(() {
      _currentUser = user;
      wallets = loadedWallets;
      goals = loadedGoals;
      transactions = loadedTransactions;
      _categories = loadedCategories;
      _loans = loadedLoans;
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
          ? const CreditCardListScreen()
          : _selectedIndex == 2
          ? CalendarScreen(transactions: transactions)
          : _selectedIndex == 3
          ? StatisticsScreen(
              transactions: transactions,
              wallets: wallets,
              creditCardTransactions: _creditCardTransactions,
            )
          : const SettingsScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                  icon: Icon(Icons.credit_card_outlined),
                  activeIcon: Icon(Icons.credit_card),
                  label: 'Kredi Kartları',
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
                    color: const Color(0xFF00BFA5).withValues(alpha: 0.4),
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
                                Icons.receipt_long,
                                color: Color(0xFFFDB32A),
                              ),
                              title: const Text('Fatura Ekle'),
                              onTap: () {
                                Navigator.pop(context, 'bill');
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
                        // Get wallets with credit cards for expense, only wallets for income
                        final allWallets = result == 'expense'
                            ? await _getWalletsWithCreditCards()
                            : await _dataService.getWallets();

                        if (!mounted) return;

                        // Quick add transaction
                        if (!mounted) return;
                        final transactionResult = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTransactionScreen(
                              wallets: allWallets,
                              categories: _categories,
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
                        if (!mounted) return;
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
                      case 'bill':
                        // Add bill with unified screen
                        if (!mounted) return;
                        final billResult = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddBillScreen(),
                          ),
                        );
                        if (billResult == true) {
                          _loadData();
                        }
                        break;

                      case 'detailed':
                        // Get wallets with credit cards
                        final allWallets = await _getWalletsWithCreditCards();

                        if (!mounted) return;

                        // Detailed add
                        final detailedResult = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTransactionScreen(
                              wallets: allWallets,
                              categories: _categories,
                            ),
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
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF00BFA5),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const SizedBox(height: 20),
              _buildSummaryCard(),
              const SizedBox(height: 20),
              _buildAllTransactions(), // Tüm işlemler (normal + kredi kartı)
              const SizedBox(height: 20),
              _buildGoalsSection(), // Hedeflerim
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllTransactions() {
    // Apply filter to credit card transactions if active
    List<CreditCardTransaction> filteredCCTransactions = _isFilterActive
        ? _filterService.filterByCards(_creditCardTransactions, _selectedCardIds)
        : _creditCardTransactions;

    // Tüm işlemleri birleştir (normal + kredi kartı)
    List<Map<String, dynamic>> allTransactions = [];

    // Normal işlemleri ekle (sadece filtre aktif değilse)
    if (!_isFilterActive) {
      for (var transaction in transactions) {
        allTransactions.add({
          'type': 'normal',
          'data': transaction,
          'date': transaction.date,
        });
      }
    }

    // Kredi kartı işlemlerini ekle (filtrelenmiş)
    for (var ccTransaction in filteredCCTransactions) {
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

    // Calculate filtered total if filter is active
    final filteredTotal = _isFilterActive
        ? _filterService.calculateFilteredTotal(filteredCCTransactions)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'İşlemler',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.displayLarge?.color,
                ),
              ),
              if (_creditCards.isNotEmpty)
                IconButton(
                  icon: Icon(
                    _isFilterActive ? Icons.filter_alt : Icons.filter_alt_outlined,
                    color: _isFilterActive ? const Color(0xFF00BFA5) : const Color(0xFF8E8E93),
                  ),
                  onPressed: _showFilterDialog,
                ),
            ],
          ),
          if (_isFilterActive) ...[
            const SizedBox(height: 8),
            _buildFilterChips(),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtrelenmiş Toplam:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    CurrencyHelper.formatAmount(filteredTotal, _currentUser),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00BFA5),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        // Get wallets with credit cards for editing
        final allWallets = await _getWalletsWithCreditCards();

        if (!mounted) return;
        
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditTransactionScreen(
              transaction: transaction,
              wallets: allWallets,
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                color: color.withValues(alpha: 0.1),
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
                if (transaction.images != null &&
                    transaction.images!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      _showImagePreview(context, transaction.images!);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                        image: DecorationImage(
                          image: MemoryImage(
                            base64Decode(transaction.images!.first),
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: transaction.images!.length > 1
                          ? Container(
                              alignment: Alignment.bottomRight,
                              padding: const EdgeInsets.all(2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+${transaction.images!.length - 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: card?.color ?? Colors.blue, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                color: (card?.color ?? Colors.blue).withValues(alpha: 0.1),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (card != null) ...[
                        Text(
                          '${card.bankName} •••• ${card.last4Digits}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        if (isInstallment) ...[
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                          ),
                          Text(
                            '${transaction.installmentsPaid}/${transaction.installmentCount} Taksit',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ] else ...[
                        Text(
                          transaction.category,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodySmall?.color,
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
                if (transaction.images.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      _showImagePreview(context, transaction.images);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                        image: DecorationImage(
                          image: MemoryImage(
                            base64Decode(transaction.images.first),
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: transaction.images.length > 1
                          ? Container(
                              alignment: Alignment.bottomRight,
                              padding: const EdgeInsets.all(2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+${transaction.images.length - 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final now = DateTime.now();

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

    // Calculate net balance
    final netBalance = monthlyIncome - monthlyExpense;

    // Calculate total debts
    // 1. Credit card debts (from wallets only, as they contain current balance)
    final creditCardDebts = wallets
        .where((w) => w.type == 'credit_card')
        .fold(0.0, (sum, w) => sum + w.balance.abs());

    // 2. KMH debts (negative balances in overdraft accounts)
    final kmhDebts = wallets
        .where((w) => w.type == 'overdraft' && w.creditLimit > 0 && w.balance < 0)
        .fold(0.0, (sum, w) => sum + w.balance.abs());

    // 3. Loan debts
    final loanDebts = _loans.fold(0.0, (sum, loan) => sum + loan.remainingAmount);

    // Total debts
    final totalDebts = creditCardDebts + kmhDebts + loanDebts;
    
    debugPrint('=== DEBT DEBUG ===');
    debugPrint('Total wallets: ${wallets.length}');
    debugPrint('Credit card debts: $creditCardDebts');
    debugPrint('KMH debts: $kmhDebts');
    debugPrint('Loan debts: $loanDebts');
    debugPrint('Total debts: $totalDebts');
    debugPrint('==================');

    // Get month name in Turkish
    final monthNames = [
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
    final monthName = monthNames[now.month - 1];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 200,
        child: PageView(
          padEnds: false,
          controller: PageController(viewportFraction: 1.0),
          children: [
          // Card 1: Net Balance
          _buildNetBalanceCard(
            monthName: monthName,
            year: now.year,
            netBalance: netBalance,
            monthlyIncome: monthlyIncome,
            monthlyExpense: monthlyExpense,
          ),
          // Card 2: Total Debts
          _buildTotalDebtsCard(
            totalDebts: totalDebts,
            creditCardDebts: creditCardDebts,
            kmhDebts: kmhDebts,
            loanDebts: loanDebts,
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetBalanceCard({
    required String monthName,
    required int year,
    required double netBalance,
    required double monthlyIncome,
    required double monthlyExpense,
  }) {
    return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Income/Expense Balance
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  color: netBalance >= 0
                      ? const Color(0xFF34C759).withValues(alpha: 0.1)
                      : const Color(0xFFFF3B30).withValues(alpha: 0.1),
                ),
                child: Row(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$monthName $year ${netBalance >= 0 ? 'Net Kazanç' : 'Net Kayıp'}',
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
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Section - Detailed Stats
            Padding(
              padding: const EdgeInsets.all(16),
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
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalDebtsCard({
    required double totalDebts,
    required double creditCardDebts,
    required double kmhDebts,
    required double loanDebts,
  }) {
    return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Total Debts Header
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFFFF3B30),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Toplam Borçlar',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8E8E93),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyHelper.formatAmount(totalDebts, _currentUser),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF3B30),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Section - Debt Breakdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (creditCardDebts > 0)
                    _buildDebtStat(
                      'Kredi Kartı',
                      creditCardDebts,
                      Icons.credit_card,
                    ),
                  if (kmhDebts > 0) ...[
                    if (creditCardDebts > 0)
                      Container(
                        width: 1,
                        height: 40,
                        color: const Color(0xFFE5E5EA),
                      ),
                    _buildDebtStat(
                      'KMH',
                      kmhDebts,
                      Icons.account_balance,
                    ),
                  ],
                  if (loanDebts > 0) ...[
                    if (creditCardDebts > 0 || kmhDebts > 0)
                      Container(
                        width: 1,
                        height: 40,
                        color: const Color(0xFFE5E5EA),
                      ),
                    _buildDebtStat(
                      'Krediler',
                      loanDebts,
                      Icons.payments,
                    ),
                  ],
                  if (totalDebts == 0)
                    const Expanded(
                      child: Text(
                        'Borç bulunmamaktadır',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 14,
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

  Widget _buildDebtStat(String label, double amount, IconData icon) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFF3B30), size: 18),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            CurrencyHelper.formatAmount(amount, _currentUser),
            style: const TextStyle(
              color: Color(0xFFFF3B30),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
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

  void _showImagePreview(BuildContext context, List<String> images) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 400,
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Image.memory(
                    base64Decode(images[index]),
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Wallet>> _getWalletsWithCreditCards() async {
    final freshWallets = await _dataService.getWallets();

    // Remove any existing credit card wallets (they might be outdated)
    final List<Wallet> allWallets = freshWallets
        .where((w) => !w.id.startsWith('cc_'))
        .toList();

    // Add credit cards as wallets
    final cards = await _creditCardService.getAllCards();
    for (var card in cards) {
      if (card.isActive) {
        allWallets.add(
          Wallet(
            id: 'cc_${card.id}',
            name: '${card.bankName} ${card.cardName} •••• ${card.last4Digits}',
            balance: 0,
            type: 'credit_card',
            color: card.cardColor.toString(),
            icon: 'credit_card',
            creditLimit: card.creditLimit,
          ),
        );
      }
    }

    return allWallets;
  }

  // Transaction filter methods
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kart Filtrele'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _creditCards.values.map((card) {
                  final isSelected = _selectedCardIds.contains(card.id);
                  return CheckboxListTile(
                    title: Text('${card.bankName} ${card.cardName}'),
                    subtitle: Text('•••• ${card.last4Digits}'),
                    value: isSelected,
                    activeColor: const Color(0xFF00BFA5),
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          _selectedCardIds.add(card.id);
                        } else {
                          _selectedCardIds.remove(card.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCardIds.clear();
                _isFilterActive = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Temizle'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isFilterActive = _selectedCardIds.isNotEmpty;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._selectedCardIds.map((cardId) {
          final card = _creditCards[cardId];
          if (card == null) return const SizedBox.shrink();
          
          return Chip(
            label: Text(
              '${card.bankName} •••• ${card.last4Digits}',
              style: const TextStyle(fontSize: 12),
            ),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () {
              setState(() {
                _selectedCardIds.remove(cardId);
                if (_selectedCardIds.isEmpty) {
                  _isFilterActive = false;
                }
              });
            },
            backgroundColor: const Color(0xFF00BFA5).withValues(alpha: 0.1),
            deleteIconColor: const Color(0xFF00BFA5),
            labelStyle: const TextStyle(color: Color(0xFF00BFA5)),
          );
        }),
        if (_selectedCardIds.isNotEmpty)
          ActionChip(
            label: const Text(
              'Tümünü Temizle',
              style: TextStyle(fontSize: 12),
            ),
            onPressed: () {
              setState(() {
                _selectedCardIds.clear();
                _isFilterActive = false;
              });
            },
            backgroundColor: Colors.red.withValues(alpha: 0.1),
            labelStyle: const TextStyle(color: Colors.red),
          ),
      ],
    );
  }
}

