import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../models/credit_card_transaction.dart';
import '../models/credit_card.dart';
import '../services/data_service.dart';
import '../services/credit_card_service.dart';
import '../utils/currency_helper.dart';

class CalendarScreen extends StatefulWidget {
  final List<Transaction> transactions;

  const CalendarScreen({super.key, required this.transactions});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DataService _dataService = DataService();
  final CreditCardService _creditCardService = CreditCardService();
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  User? _currentUser;
  List<Category> _categories = [];
  List<CreditCardTransaction> _creditCardTransactions = [];
  Map<String, CreditCard> _creditCards = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _dataService.getCurrentUser();
    final categories = await _dataService.getCategories();
    
    // Load credit card transactions
    final cards = await _creditCardService.getAllCards();
    final Map<String, CreditCard> cardMap = {};
    final List<CreditCardTransaction> allCCTransactions = [];
    
    for (var card in cards) {
      cardMap[card.id] = card;
      final transactions = await _creditCardService.getCardTransactions(card.id);
      allCCTransactions.addAll(transactions);
    }
    
    setState(() {
      _currentUser = user;
      _categories = categories;
      _creditCardTransactions = allCCTransactions;
      _creditCards = cardMap;
    });
  }

  List<dynamic> _getTransactionsForDay(DateTime date) {
    // Normal transactions
    final normalTransactions = widget.transactions.where((t) {
      // Taksitli işlemler için kontrol
      if (t.installments != null) {
        // Taksitli işlemin tarihi bu gün mü?
        return t.date.year == date.year &&
            t.date.month == date.month &&
            t.date.day == date.day;
      }
      // Normal işlemler için tarih eşleşmesi
      return t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day;
    }).toList();
    
    // Credit card transactions
    final ccTransactions = _creditCardTransactions.where((t) {
      return t.transactionDate.year == date.year &&
          t.transactionDate.month == date.month &&
          t.transactionDate.day == date.day;
    }).toList();
    
    // Combine both lists
    return [...normalTransactions, ...ccTransactions];
  }

  double _getDayTotal(DateTime date) {
    final dayTransactions = _getTransactionsForDay(date);
    double total = 0;
    for (var t in dayTransactions) {
      if (t is Transaction) {
        if (t.type == 'income') {
          total += t.amount;
        } else {
          total -= t.amount;
        }
      } else if (t is CreditCardTransaction) {
        // Credit card transactions are always expenses
        total -= t.amount;
      }
    }
    return total;
  }

  double _getDayIncome(DateTime date) {
    final dayTransactions = _getTransactionsForDay(date);
    return dayTransactions
        .where((t) => t is Transaction && t.type == 'income')
        .fold(0.0, (sum, t) => sum + (t as Transaction).amount);
  }

  double _getDayExpense(DateTime date) {
    final dayTransactions = _getTransactionsForDay(date);
    double expense = 0;
    
    // Normal expenses
    expense += dayTransactions
        .where((t) => t is Transaction && t.type == 'expense')
        .fold(0.0, (sum, t) => sum + (t as Transaction).amount);
    
    // Credit card expenses
    expense += dayTransactions
        .where((t) => t is CreditCardTransaction)
        .fold(0.0, (sum, t) => sum + (t as CreditCardTransaction).amount);
    
    return expense;
  }

  double get _monthIncome {
    return widget.transactions
        .where(
          (t) =>
              t.type == 'income' &&
              t.date.month == _selectedMonth.month &&
              t.date.year == _selectedMonth.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _monthExpense {
    // Normal expenses
    double normalExpense = widget.transactions
        .where(
          (t) =>
              t.type == 'expense' &&
              t.date.month == _selectedMonth.month &&
              t.date.year == _selectedMonth.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
    
    // Credit card expenses
    double ccExpense = _creditCardTransactions
        .where(
          (t) =>
              t.transactionDate.month == _selectedMonth.month &&
              t.transactionDate.year == _selectedMonth.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
    
    return normalExpense + ccExpense;
  }

  double get _monthTotal {
    return _monthIncome - _monthExpense;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
        children: [
          _buildHeader(), // Sabit header
          _buildSummary(), // Sabit özet
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCalendarHeader(),
                  _buildCalendarGrid(),
                  Container(height: 1, color: const Color(0xFFE5E5EA)),
                  SizedBox(
                    height: screenHeight * 0.4, // Ekran yüksekliğinin %40'ı
                    child: _buildDayTransactions(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildDayTransactions() {
    final dayTransactions = _getTransactionsForDay(_selectedDate);
    final dayIncome = _getDayIncome(_selectedDate);
    final dayExpense = _getDayExpense(_selectedDate);
    final dayTotal = _getDayTotal(_selectedDate);

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF5E5CE6).withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: const Color(0xFFE5E5EA)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF5E5CE6),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_selectedDate.day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE', 'tr_TR').format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gelir',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                          Text(
                            CurrencyHelper.formatAmountCompact(
                              dayIncome,
                              _currentUser,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF34C759),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gider',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                          Text(
                            CurrencyHelper.formatAmountCompact(
                              dayExpense,
                              _currentUser,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF3B30),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: dayTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'İşlem yok',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: dayTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = dayTransactions[index];
                      if (transaction is Transaction) {
                        return _buildTransactionItem(transaction);
                      } else if (transaction is CreditCardTransaction) {
                        return _buildCreditCardTransactionItem(transaction);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final category = _categories.firstWhere(
      (c) => c.name == transaction.category,
      orElse: () => _categories.isNotEmpty ? _categories.first : defaultCategories.first,
    );

    final isIncome = transaction.type == 'income';
    final color = isIncome ? const Color(0xFF34C759) : const Color(0xFFFF3B30);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(category.icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (transaction.installments != null)
                  Text(
                    '${transaction.currentInstallment}/${transaction.installments} Taksit',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${CurrencyHelper.formatAmountCompact(transaction.amount, _currentUser)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardTransactionItem(CreditCardTransaction transaction) {
    final card = _creditCards[transaction.cardId];
    final color = const Color(0xFFFF3B30); // Always expense (red)
    final isInstallment = transaction.installmentCount > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: card?.color ?? Colors.blue,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (card?.color ?? Colors.blue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.credit_card,
              color: card?.color ?? Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    if (card != null) ...[
                      Text(
                        '${card.bankName} •••• ${card.last4Digits}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      if (isInstallment) ...[
                        const Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        Text(
                          '${transaction.installmentsPaid}/${transaction.installmentCount} Taksit',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ] else ...[
                      Text(
                        transaction.category,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '-${CurrencyHelper.formatAmountCompact(transaction.amount, _currentUser)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF1C1C1E),
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
            },
          ),
          Text(
            DateFormat('MMMM yyyy', 'tr_TR').format(_selectedMonth),
            style: const TextStyle(
              color: Color(0xFF1C1C1E),
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF1C1C1E),
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(
                child: _buildSummaryItem('Gelir', _monthIncome, const Color(0xFF34C759)),
              ),
              Flexible(
                child: _buildSummaryItem('Gider', _monthExpense, const Color(0xFFFF3B30)),
              ),
              Flexible(
                child: _buildSummaryItem('Toplam', _monthTotal, const Color(0xFF1C1C1E)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8E8E93),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            CurrencyHelper.formatAmount(amount, _currentUser),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    final days = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cuma', 'Cmt'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((day) {
          final isSunday = day == 'Paz';
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSunday ? Colors.red : Colors.grey.shade700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
    final firstDayOfWeek =
        DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday % 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: List.generate((daysInMonth + firstDayOfWeek) ~/ 7 + 1, (
          weekIndex,
        ) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final cellIndex = weekIndex * 7 + dayIndex;
              if (cellIndex < firstDayOfWeek ||
                  cellIndex >= daysInMonth + firstDayOfWeek) {
                return Expanded(child: Container());
              }

              final day = cellIndex - firstDayOfWeek + 1;
              return Expanded(child: _buildDayCell(day));
            }),
          );
        }),
      ),
    );
  }

  Widget _buildDayCell(int day) {
    final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
    final isSelected = date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final income = _getDayIncome(date);
    final expense = _getDayExpense(date);
    final total = _getDayTotal(date);
    final hasTransactions = income > 0 || expense > 0;

    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date),
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5E5CE6).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: const Color(0xFF5E5CE6), width: 2)
              : null,
        ),
        constraints: const BoxConstraints(minHeight: 70),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected || isToday
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: day % 7 == 0
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFF1C1C1E),
                  ),
                ),
                if (hasTransactions) ...[
                  const SizedBox(height: 2),
                  if (income > 0)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        NumberFormat('#,##0', 'tr_TR').format(income),
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF34C759),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (expense > 0)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '-${NumberFormat('#,##0', 'tr_TR').format(expense)}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFFFF3B30),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (income > 0 || expense > 0)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        NumberFormat('#,##0', 'tr_TR').format(total),
                        style: TextStyle(
                          fontSize: 9,
                          color: total >= 0
                              ? const Color(0xFF34C759)
                              : const Color(0xFFFF3B30),
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
