// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'dart:convert';
import 'dart:async';

import '../models/wallet.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../models/loan.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../utils/currency_helper.dart';
import '../utils/app_icons.dart';
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
import 'kmh_list_screen.dart';

import '../services/kmh_alert_service.dart';
import '../models/kmh_alert.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
  final KmhAlertService _kmhAlertService = KmhAlertService();

  User? _currentUser;
  List<Wallet> wallets = [];
  List<Goal> goals = [];
  List<Transaction> transactions = [];
  List<Category> _categories = [];
  List<CreditCardTransaction> _creditCardTransactions = [];
  Map<String, CreditCard> _creditCards = {};
  List<Loan> _loans = [];
  bool _loading = true;
  bool _showFabMenu = false;
  Timer? _fabMenuTimer;
  int _unreadNotificationCount = 0;
  List<KmhAlert> _kmhAlerts = [];
  final List<String> _selectedCardIds = [];
  bool _isFilterActive = false;
  double _totalCreditCardDebt = 0.0;

  late PageController _pageController;
  int _currentPage = 0;
  int _homeViewMode = 0; // 0: List, 1: Calendar

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
        });
      }
    });
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabMenuTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      // Ensure preferences are initialized (web can be lax)
      await _dataService.init();

      var user = await _dataService.getCurrentUser();
      if (user == null) {
        user = User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Kullanıcı',
          email: null,
          avatar: null,
          currencyCode: 'TRY',
          currencySymbol: '₺',
        );
        try {
          await _dataService.saveUser(user);
          final allUsers = await _dataService.getAllUsers();
          allUsers.add(user);
          await _dataService.saveAllUsers(allUsers);
        } catch (e) {
          debugPrint('WARN _loadData: Failed to persist initial user: $e');
        }
      }

      List<Wallet> loadedWallets = const [];
      List<Goal> loadedGoals = const [];
      List<Transaction> loadedTransactions = const [];
      List<Category> loadedCategories = const [];
      List<Loan> loadedLoans = const [];
      int unreadCount = 0;
      List<KmhAlert> kmhAlerts = const [];
      List<CreditCard> cards = const [];

      try {
        loadedWallets = await _dataService.getWallets();
      } catch (e) {
        debugPrint('WARN _loadData: wallets $e');
      }
      try {
        loadedGoals = await _dataService.getGoals();
      } catch (e) {
        debugPrint('WARN _loadData: goals $e');
      }
      try {
        loadedTransactions = await _dataService.getTransactions();
      } catch (e) {
        debugPrint('WARN _loadData: transactions $e');
      }
      try {
        final cats = await _dataService.getCategories();
        loadedCategories = List<Category>.from(cats);
      } catch (e) {
        debugPrint('WARN _loadData: categories $e');
      }
      try {
        loadedLoans = await _dataService.getLoans();
      } catch (e) {
        debugPrint('WARN _loadData: loans $e');
      }
      try {
        unreadCount = await _notificationService.getUnreadCount();
      } catch (e) {
        debugPrint('WARN _loadData: notifications $e');
      }
      try {
        kmhAlerts = await _kmhAlertService.checkAllAccountsForAlerts();
      } catch (e) {
        debugPrint('WARN _loadData: kmh alerts $e');
      }
      try {
        cards = await _creditCardService.getAllCards();
      } catch (e) {
        debugPrint('WARN _loadData: cards $e');
      }
      debugPrint('Found ${cards.length} credit cards');

      final Map<String, CreditCard> cardMap = {};
      final List<CreditCardTransaction> allCCTransactions = [];

      for (var card in cards) {
        cardMap[card.id] = card;
        try {
          final ccTransactions = await _creditCardService.getCardTransactions(
            card.id,
          );
          debugPrint(
            'Card ${card.bankName} has ${ccTransactions.length} transactions',
          );
          allCCTransactions.addAll(ccTransactions);
        } catch (e) {
          debugPrint('WARN _loadData: card tx for ${card.id} $e');
        }
      }
      debugPrint('Total CC transactions: ${allCCTransactions.length}');

      double totalCCDebt = 0.0;
      for (var card in cards) {
        try {
          final debt = await _creditCardService.getCurrentDebt(card.id);
          totalCCDebt += debt;
        } catch (e) {
          // Silently handle error
        }
      }

      if (mounted) {
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
          _kmhAlerts = kmhAlerts;
          _totalCreditCardDebt = totalCCDebt;
          _loading = false;
        });
      }
    } catch (e, st) {
      debugPrint('ERROR _loadData: $e\n$st');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: !_showFabMenu,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (_showFabMenu) {
          setState(() => _showFabMenu = false);
        }
      },
      child: GestureDetector(
        onTap: () {
          if (_showFabMenu) {
            setState(() => _showFabMenu = false);
          }
        },
        child: Scaffold(
          appBar: _selectedIndex == 0
              ? AppBar(
                  automaticallyImplyLeading: false,
                  title: _buildHomeToggle(),
                  centerTitle: true,
                  actions: [
                    Stack(
                      children: [
                        IconButton(
                          icon: FaIcon(AppIcons.notification, size: 20),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationHistoryScreen(),
                              ),
                            );
                            _loadData();
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
                  selectedItemColor: const Color(0xFF00BFA5),
                  unselectedItemColor: const Color(0xFF8E8E93),
                  selectedFontSize: 11,
                  unselectedFontSize: 11,
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                  elevation: 0,
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(
                        LucideIcons.home,
                        size: 20,
                        color: const Color(0xFF8E8E93),
                      ),
                      activeIcon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.home,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      label: 'Ana Sayfa',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        LucideIcons.creditCard,
                        size: 20,
                        color: const Color(0xFF8E8E93),
                      ),
                      activeIcon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.creditCard,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      label: 'Kredi Kartları',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        LucideIcons.pieChart,
                        size: 20,
                        color: const Color(0xFF8E8E93),
                      ),
                      activeIcon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.pieChart,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      label: 'İstatistik',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        LucideIcons.settings,
                        size: 20,
                        color: const Color(0xFF8E8E93),
                      ),
                      activeIcon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.settings,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      label: 'Ayarlar',
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: _selectedIndex == 0 ? _buildFabMenu() : null,
        ),
      ),
    );
  }

  Widget _buildHomeToggle() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.withAlpha(50),
        ), // using withAlpha for cleaner look options
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption('Liste', 0),
          _buildToggleOption('Takvim', 1),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String text, int mode) {
    final isSelected = _homeViewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _homeViewMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00BFA5) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    if (_homeViewMode == 1) {
      return CalendarScreen(transactions: transactions, isEmbedded: true);
    }

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
              if (_kmhAlerts.isNotEmpty) ...[
                _buildKmhAlertsSection(),
                const SizedBox(height: 20),
              ],
              _buildAllTransactions(),
              const SizedBox(height: 20),
              _buildGoalsSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllTransactions() {
    List<CreditCardTransaction> filteredCCTransactions = _isFilterActive
        ? TransactionFilterService.filterByCards(
            _creditCardTransactions,
            _selectedCardIds,
          )
        : _creditCardTransactions;
    List<Map<String, dynamic>> allTransactions = [];
    if (!_isFilterActive) {
      for (var transaction in transactions) {
        allTransactions.add({
          'type': 'normal',
          'data': transaction,
          'date': transaction.date,
        });
      }
    }
    for (var ccTransaction in filteredCCTransactions) {
      allTransactions.add({
        'type': 'credit_card',
        'data': ccTransaction,
        'date': ccTransaction.transactionDate,
      });
    }
    allTransactions.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );

    if (allTransactions.isEmpty) {
      return const SizedBox.shrink();
    }
    Map<String, List<Map<String, dynamic>>> groupedTransactions = {};
    for (var item in allTransactions) {
      final dateKey = _getDateKey(item['date'] as DateTime);
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(item);
    }
    final filteredTotal = _isFilterActive
        ? TransactionFilterService.calculateFilteredTotal(
            filteredCCTransactions,
          )
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
                  icon: FaIcon(
                    AppIcons.filter,
                    color: _isFilterActive
                        ? const Color(0xFF00BFA5)
                        : const Color(0xFF8E8E93),
                    size: 20,
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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

    final isIncome = transaction.type == 'income';
    final incomeExpenseColor = isIncome
        ? const Color(0xFF34C759)
        : const Color(0xFFFF3B30);

    Color categoryColor = AppIcons.getCategoryColor(transaction.category);
    Widget iconWidget;

    if (categoryColor == Colors.grey) {
      categoryColor = incomeExpenseColor;
      iconWidget = AppIcons.getCategoryIcon(
        transaction.category,
        size: 24,
        color: categoryColor,
      );
    } else {
      iconWidget = AppIcons.getCategoryIcon(transaction.category, size: 24);
    }

    return GestureDetector(
      onTap: () async {
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
          border: Border.all(
            color: incomeExpenseColor.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: iconWidget,
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
                      Flexible(
                        child: Text(
                          wallet.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8E8E93),
                          ),
                          overflow: TextOverflow.ellipsis,
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
                    color: incomeExpenseColor,
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
    final color = const Color(0xFFFF3B30);
    final isInstallment = transaction.installmentCount > 1;

    return GestureDetector(
      onTap: () async {
        if (card != null) {
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
              child: FaIcon(
                AppIcons.creditCard,
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
                        Flexible(
                          child: Text(
                            '${card.bankName} •••• ${card.last4Digits}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                        Flexible(
                          child: Text(
                            transaction.category,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                            overflow: TextOverflow.ellipsis,
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
    final monthlyTransactions = transactions.where(
      (t) => t.date.month == now.month && t.date.year == now.year,
    );

    final monthlyIncome = monthlyTransactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final regularMonthlyExpense = monthlyTransactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final creditCardMonthlyExpense = _creditCardTransactions
        .where(
          (t) =>
              t.transactionDate.month == now.month &&
              t.transactionDate.year == now.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    final monthlyExpense = regularMonthlyExpense + creditCardMonthlyExpense;
    final netBalance = monthlyIncome - monthlyExpense;

    // Use pre-calculated credit card debt from state
    final creditCardDebts = _totalCreditCardDebt;

    final kmhDebts = wallets
        .where((w) => w.isKmhAccount && w.balance < 0)
        .fold(0.0, (sum, w) => sum + w.balance.abs());
    final loanDebts = _loans.fold(
      0.0,
      (sum, loan) => sum + loan.remainingAmount,
    );
    final totalDebts = creditCardDebts + kmhDebts + loanDebts;
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
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PageView(
              padEnds: false,
              controller: _pageController,
              children: [
                _buildNetBalanceCard(
                  monthName: monthName,
                  year: now.year,
                  netBalance: netBalance,
                  monthlyIncome: monthlyIncome,
                  monthlyExpense: monthlyExpense,
                ),
                _buildTotalDebtsCard(
                  totalDebts: totalDebts,
                  creditCardDebts: creditCardDebts,
                  kmhDebts: kmhDebts,
                  loanDebts: loanDebts,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              2,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? const Color(0xFF00BFA5)
                      : const Color(0xFF00BFA5).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
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
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                color: netBalance >= 0
                    ? const Color(0xFF34C759).withValues(alpha: 0.1)
                    : const Color(0xFFFF3B30).withValues(alpha: 0.1),
              ),
              child: Row(
                children: [
                  FaIcon(
                    AppIcons.income,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailedStat(
                  'Gelir',
                  monthlyIncome,
                  AppIcons.income,
                  const Color(0xFF34C759),
                ),
                Container(width: 1, height: 40, color: const Color(0xFFE5E5EA)),
                _buildDetailedStat(
                  'Gider',
                  monthlyExpense,
                  AppIcons.expense,
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
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
              ),
              child: Row(
                children: [
                  FaIcon(AppIcons.wallet, color: Color(0xFFFF3B30), size: 24),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (creditCardDebts > 0)
                  _buildDebtStat(
                    'Kredi Kartı',
                    creditCardDebts,
                    AppIcons.creditCard,
                  ),
                if (kmhDebts > 0) ...[
                  if (creditCardDebts > 0)
                    Container(
                      width: 1,
                      height: 40,
                      color: const Color(0xFFE5E5EA),
                    ),
                  _buildDebtStat('KMH', kmhDebts, AppIcons.bank),
                ],
                if (loanDebts > 0) ...[
                  if (creditCardDebts > 0 || kmhDebts > 0)
                    Container(
                      width: 1,
                      height: 40,
                      color: const Color(0xFFE5E5EA),
                    ),
                  _buildDebtStat('Krediler', loanDebts, AppIcons.money),
                ],
                if (totalDebts == 0)
                  const Expanded(
                    child: Text(
                      'Borç bulunmamaktadır',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
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
          FaIcon(icon, color: const Color(0xFFFF3B30), size: 18),
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
        FaIcon(icon, color: color, size: 20),
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
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.memory(
                      base64Decode(images[index]),
                      fit: BoxFit.contain,
                    ),
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
    final List<Wallet> allWallets = freshWallets
        .where((w) => !w.id.startsWith('cc_'))
        .toList();
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
            deleteIcon: FaIcon(FontAwesomeIcons.xmark, size: 14),
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
            label: const Text('Tümünü Temizle', style: TextStyle(fontSize: 12)),
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

  Widget _buildKmhAlertsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KMH Uyarıları',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 12),
          ..._kmhAlerts.map((alert) => _buildKmhAlertCard(alert)),
        ],
      ),
    );
  }

  Widget _buildKmhAlertCard(KmhAlert alert) {
    final isCritical = alert.type == KmhAlertType.limitCritical;
    final color = isCritical
        ? const Color(0xFFFF3B30)
        : const Color(0xFFFDB32A);
    final icon = isCritical ? AppIcons.error : AppIcons.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        children: [
          FaIcon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.walletName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: FaIcon(FontAwesomeIcons.chevronRight, size: 14),
            color: color,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const KmhListScreen()),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFabMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_showFabMenu) ...[
          _buildFabMenuItem(
            label: 'Gider Ekle',
            icon: AppIcons.expense,
            color: const Color(0xFFFF5252),
            onTap: () async {
              setState(() => _showFabMenu = false);
              final allWallets = await _getWalletsWithCreditCards();
              if (!mounted) return;
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTransactionScreen(
                    wallets: allWallets,
                    categories: _categories,
                    defaultType: 'expense',
                  ),
                ),
              );
              if (result == true) _loadData();
            },
          ),
          const SizedBox(height: 12),
          _buildFabMenuItem(
            label: 'Gelir Ekle',
            icon: AppIcons.income,
            color: const Color(0xFF4CAF50),
            onTap: () async {
              setState(() => _showFabMenu = false);
              final allWallets = await _dataService.getWallets();
              if (!mounted) return;
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTransactionScreen(
                    wallets: allWallets,
                    categories: _categories,
                    defaultType: 'income',
                  ),
                ),
              );
              if (result == true) _loadData();
            },
          ),
          const SizedBox(height: 12),
          _buildFabMenuItem(
            label: 'Fatura Ekle',
            icon: AppIcons.receipt,
            color: const Color(0xFFFF9800),
            onTap: () async {
              setState(() => _showFabMenu = false);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddBillScreen()),
              );
              if (result == true) _loadData();
            },
          ),
          const SizedBox(height: 12),
          _buildFabMenuItem(
            label: 'Cüzdan Ekle',
            icon: AppIcons.wallet,
            color: const Color(0xFF2196F3),
            onTap: () async {
              setState(() => _showFabMenu = false);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddWalletScreen(),
                ),
              );
              if (result == true) _loadData();
            },
          ),
          const SizedBox(height: 16),
        ],
        FloatingActionButton(
          onPressed: () {
            setState(() {
              _showFabMenu = !_showFabMenu;
              _fabMenuTimer?.cancel();

              if (_showFabMenu) {
                // 5 saniye sonra otomatik kapat
                _fabMenuTimer = Timer(const Duration(seconds: 5), () {
                  if (mounted && _showFabMenu) {
                    setState(() => _showFabMenu = false);
                  }
                });
              }
            });
          },
          backgroundColor: const Color(0xFF00BFA5),
          child: AnimatedRotation(
            turns: _showFabMenu ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: FaIcon(
              _showFabMenu ? AppIcons.delete : AppIcons.add,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFabMenuItem({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton(
          heroTag: label,
          onPressed: onTap,
          backgroundColor: color,
          mini: false,
          child: FaIcon(icon, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}
