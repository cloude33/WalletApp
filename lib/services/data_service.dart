import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/wallet.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/loan.dart';
import '../models/category.dart';
import '../models/recurring_transaction.dart';
import '../models/kmh_transaction.dart';
import '../models/bill_template.dart';
import '../models/bill_payment.dart';
import 'cache_service.dart';
import 'credit_card_service.dart';
import 'kmh_box_service.dart';
import 'secure_storage_service.dart';
import 'bill_template_service.dart';
import 'bill_payment_service.dart';
import '../repositories/recurring_transaction_repository.dart';
import '../repositories/scheduled_notification_repository.dart';
import '../repositories/kmh_repository.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  @visibleForTesting
  DataService.forTesting();

  SharedPreferences? _prefs;
  final CacheService _cache = CacheService();

  // In-memory data for synchronous access
  List<Wallet> _wallets = [];
  List<Transaction> _transactions = [];
  List<Category> _categories = [];

  List<Wallet> get wallets => _wallets;
  List<Transaction> get transactions => _transactions;
  List<Category> get categories => _categories;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> getPrefs() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }
  Future<User?> getCurrentUser() async {
    final userJson = _prefs?.getString('current_user');
    if (userJson == null) return null;
    return User.fromJson(json.decode(userJson));
  }

  Future<void> saveUser(User user) async {
    await _prefs?.setString('current_user', json.encode(user.toJson()));
  }

  Future<void> updateUser(User user) async {
    await saveUser(user);
    final allUsers = await getAllUsers();
    final index = allUsers.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      allUsers[index] = user;
      await saveAllUsers(allUsers);
    }
  }

  Future<List<User>> getAllUsers() async {
    final usersJson = _prefs?.getString('users') ?? '[]';
    final List<dynamic> usersList = json.decode(usersJson);
    return usersList.map((u) => User.fromJson(u)).toList();
  }

  Future<void> saveAllUsers(List<User> users) async {
    final usersJson = json.encode(users.map((u) => u.toJson()).toList());
    await _prefs?.setString('users', usersJson);
  }
  Future<List<Wallet>> getWallets() async {
    final cached = _cache.get<List<Wallet>>('wallets');
    if (cached != null) {
      _wallets = cached;
      return cached;
    }
    final walletsJson = _prefs?.getString('wallets') ?? '[]';
    final List<dynamic> walletsList = json.decode(walletsJson);
    final wallets = walletsList.map((w) => Wallet.fromJson(w)).toList();
    try {
      final creditCardService = CreditCardService();
      final creditCards = await creditCardService.getActiveCards();

      for (var card in creditCards) {
        final currentDebt = await creditCardService.getCurrentDebt(card.id);
        final ccWallet = Wallet(
          id: 'cc_${card.id}',
          name: '${card.bankName} ${card.cardName} •••• ${card.last4Digits}',
          balance: -currentDebt,
          type: 'credit_card',
          color: card.cardColor.toString(),
          icon: 'credit_card',
          creditLimit: card.creditLimit,
        );

        wallets.add(ccWallet);
      }
    } catch (e) {
      debugPrint('Error loading credit cards as wallets: $e');
    }
    _wallets = wallets;
    _cache.put('wallets', wallets);

    return wallets;
  }

  Future<void> saveWallets(List<Wallet> wallets) async {
    final regularWallets = wallets
        .where((w) => !w.id.startsWith('cc_'))
        .toList();

    final walletsJson = json.encode(
      regularWallets.map((w) => w.toJson()).toList(),
    );
    await _prefs?.setString('wallets', walletsJson);
    _cache.invalidate('wallets');
  }

  Future<void> addWallet(Wallet wallet) async {
    final wallets = await getWallets();
    wallets.add(wallet);
    await saveWallets(wallets);
  }

  Future<void> updateWallet(Wallet wallet) async {
    final wallets = await getWallets();
    final index = wallets.indexWhere((w) => w.id == wallet.id);
    if (index != -1) {
      wallets[index] = wallet;
      await saveWallets(wallets);
    }
  }

  Future<void> deleteWallet(String id) async {
    final wallets = await getWallets();
    wallets.removeWhere((w) => w.id == id);
    await saveWallets(wallets);
  }
  Future<List<Transaction>> getTransactions() async {
    final cached = _cache.get<List<Transaction>>('transactions');
    if (cached != null) {
      _transactions = cached;
      return cached;
    }
    final transactionsJson = _prefs?.getString('transactions') ?? '[]';
    final List<dynamic> transactionsList = json.decode(transactionsJson);
    final transactions = transactionsList
        .map((t) => Transaction.fromJson(t))
        .toList();
    _transactions = transactions;
    _cache.put('transactions', transactions);

    return transactions;
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    final transactionsJson = json.encode(
      transactions.map((t) => t.toJson()).toList(),
    );
    await _prefs?.setString('transactions', transactionsJson);
    _cache.invalidate('transactions');
  }

  Future<void> addTransaction(Transaction transaction) async {
    final transactions = await getTransactions();
    transactions.add(transaction);
    await saveTransactions(transactions);

    await _applyTransactionEffect(transaction);
  }

  Future<void> deleteTransaction(String id) async {
    final transactions = await getTransactions();
    final index = transactions.indexWhere((t) => t.id == id);
    if (index == -1) {
      return;
    }

    final tx = transactions[index];

    if (tx.parentTransactionId != null ||
        transactions.any((t) => t.parentTransactionId == tx.id)) {
      await deleteTransactionWithInstallments(id);
      return;
    }

    transactions.removeAt(index);
    await saveTransactions(transactions);

    await _revertTransactionEffect(tx);
  }

  Future<void> updateTransaction(
    Transaction oldTransaction,
    Transaction newTransaction,
  ) async {
    final transactions = await getTransactions();
    final index = transactions.indexWhere((t) => t.id == oldTransaction.id);
    if (index == -1) {
      throw Exception('Transaction not found');
    }

    await _revertTransactionEffect(oldTransaction);

    transactions[index] = newTransaction;
    await saveTransactions(transactions);

    await _applyTransactionEffect(newTransaction);
  }

  Future<void> _revertTransactionEffect(Transaction transaction) async {
    if (transaction.type == 'transfer') {
      return;
    }
    if (transaction.walletId.startsWith('cc_')) {
      return;
    }

    final wallets = await getWallets();
    final walletIndex = wallets.indexWhere((w) => w.id == transaction.walletId);
    if (walletIndex == -1) return;

    final wallet = wallets[walletIndex];
    final adjustment = transaction.type == 'income'
        ? -transaction.amount
        : transaction.amount;

    wallets[walletIndex] = wallet.copyWith(
      balance: wallet.balance + adjustment,
    );
    await saveWallets(wallets);
  }

  Future<void> _applyTransactionEffect(Transaction transaction) async {
    if (transaction.type == 'transfer') {
      return;
    }
    if (transaction.walletId.startsWith('cc_')) {
      return;
    }

    final wallets = await getWallets();
    final walletIndex = wallets.indexWhere((w) => w.id == transaction.walletId);
    if (walletIndex == -1) return;

    final wallet = wallets[walletIndex];
    final adjustment = transaction.type == 'income'
        ? transaction.amount
        : -transaction.amount;

    wallets[walletIndex] = wallet.copyWith(
      balance: wallet.balance + adjustment,
    );
    await saveWallets(wallets);
  }

  Future<void> deleteTransactionWithInstallments(String transactionId) async {
    final transactions = await getTransactions();
    final transaction = transactions.firstWhere(
      (t) => t.id == transactionId,
      orElse: () => throw Exception('Transaction not found'),
    );

    String? parentId;
    if (transaction.parentTransactionId != null) {
      parentId = transaction.parentTransactionId;
    } else {
      parentId = transactionId;
    }

    final relatedTransactions = transactions
        .where(
          (t) =>
              t.id == parentId ||
              t.parentTransactionId == parentId ||
              (t.parentTransactionId != null &&
                  t.parentTransactionId == transaction.id),
        )
        .toList();

    for (final tx in relatedTransactions) {
      await _revertTransactionEffect(tx);
      transactions.removeWhere((t) => t.id == tx.id);
    }

    await saveTransactions(transactions);
  }

  Future<void> addTransferTransaction({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    required String description,
    String? memo,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    final fromTransaction = Transaction(
      id: timestamp,
      type: 'transfer',
      amount: amount,
      description: 'Transfer: $description',
      category: 'Transfer',
      walletId: fromWalletId,
      date: DateTime.now(),
      memo: memo,
    );

    final toTransaction = Transaction(
      id: '${timestamp}_to',
      type: 'transfer',
      amount: amount,
      description: 'Transfer: $description',
      category: 'Transfer',
      walletId: toWalletId,
      date: DateTime.now(),
      memo: memo,
    );

    await addTransaction(fromTransaction);
    await addTransaction(toTransaction);

    final wallets = await getWallets();

    final fromIndex = wallets.indexWhere((w) => w.id == fromWalletId);
    if (fromIndex != -1) {
      wallets[fromIndex] = wallets[fromIndex].copyWith(
        balance: wallets[fromIndex].balance - amount,
      );
    }

    final toIndex = wallets.indexWhere((w) => w.id == toWalletId);
    if (toIndex != -1) {
      wallets[toIndex] = wallets[toIndex].copyWith(
        balance: wallets[toIndex].balance + amount,
      );
    }

    await saveWallets(wallets);
  }
  Future<List<Goal>> getGoals() async {
    final goalsJson = _prefs?.getString('goals') ?? '[]';
    final List<dynamic> goalsList = json.decode(goalsJson);
    return goalsList.map((g) => Goal.fromJson(g)).toList();
  }

  Future<void> saveGoals(List<Goal> goals) async {
    final goalsJson = json.encode(goals.map((g) => g.toJson()).toList());
    await _prefs?.setString('goals', goalsJson);
  }

  Future<void> addGoal(Goal goal) async {
    final goals = await getGoals();
    goals.add(goal);
    await saveGoals(goals);
  }

  Future<void> deleteGoal(String id) async {
    final goals = await getGoals();
    goals.removeWhere((g) => g.id == id);
    await saveGoals(goals);
  }

  Future<void> updateGoal(Goal goal) async {
    final goals = await getGoals();
    final index = goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      goals[index] = goal;
      await saveGoals(goals);
    }
  }
  Future<List<Category>> getCategories() async {
    final categoriesJson = _prefs?.getString('categories');
    if (categoriesJson == null) {
      await saveCategories(defaultCategories);
      _categories = defaultCategories;
      return defaultCategories;
    }
    final List<dynamic> categoriesList = json.decode(categoriesJson);
    final categories = categoriesList.map((c) => Category.fromJson(c)).toList();
    _categories = categories;
    return categories;
  }

  Future<void> saveCategories(List<Category> categories) async {
    final categoriesJson = json.encode(
      categories.map((c) => c.toJson()).toList(),
    );
    await _prefs?.setString('categories', categoriesJson);
  }

  Future<void> addCategory(Category category) async {
    final categories = await getCategories();
    categories.add(category);
    await saveCategories(categories);
  }

  Future<void> deleteCategory(String id) async {
    final categories = await getCategories();
    categories.removeWhere((c) => c.id == id);
    await saveCategories(categories);
  }

  Future<void> updateCategory(Category category) async {
    final categories = await getCategories();
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      categories[index] = category;
      await saveCategories(categories);
    }
  }
  Future<List<User>> getUsers() async {
    return await getAllUsers();
  }
  Future<List<Loan>> getLoans() async {
    final loansJson = _prefs?.getString('loans') ?? '[]';
    final List<dynamic> loansList = json.decode(loansJson);
    return loansList.map((l) => Loan.fromJson(l)).toList();
  }

  Future<void> saveLoans(List<Loan> loans) async {
    final loansJson = json.encode(loans.map((l) => l.toJson()).toList());
    await _prefs?.setString('loans', loansJson);
  }

  Future<void> addLoan(Loan loan) async {
    final loans = await getLoans();
    loans.add(loan);
    await saveLoans(loans);
  }

  Future<void> deleteLoan(String id) async {
    final loans = await getLoans();
    loans.removeWhere((l) => l.id == id);
    await saveLoans(loans);
  }

  Future<void> updateLoan(Loan loan) async {
    final loans = await getLoans();
    final index = loans.indexWhere((l) => l.id == loan.id);
    if (index != -1) {
      loans[index] = loan;
      await saveLoans(loans);
    }
  }

  Future<void> clearAllData() async {
    await _prefs?.clear();
    _cache.clear();
    try {
      final creditCardService = CreditCardService();
      await creditCardService.clearAllData();
    } catch (e) {
      debugPrint('Error clearing credit card data: $e');
    }
    try {
      final recurringRepo = RecurringTransactionRepository();
      await recurringRepo.init();
      await recurringRepo.clear();
    } catch (e) {
      debugPrint('Error clearing recurring transactions: $e');
    }
    try {
      final notificationRepo = ScheduledNotificationRepository();
      await notificationRepo.clearAll();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
    try {
      await KmhBoxService.clearAll();
    } catch (e) {
      debugPrint('Error clearing KMH data: $e');
    }
    try {
      await SecureStorageService().deleteAllKeys();
    } catch (e) {
      debugPrint('Error clearing encryption keys: $e');
    }
  }
  Future<void> restoreFromBackup(Map<String, dynamic> backupData) async {
    try {
      await _prefs?.clear();
      if (backupData.containsKey('transactions')) {
        final transactions = (backupData['transactions'] as List)
            .map((t) => Transaction.fromJson(t))
            .toList();
        await saveTransactions(transactions);
      }
      if (backupData.containsKey('wallets')) {
        final wallets = (backupData['wallets'] as List)
            .map((w) => Wallet.fromJson(w))
            .toList();
        await saveWallets(wallets);
      }
      if (backupData.containsKey('recurringTransactions')) {
        final recurringTransactions =
            (backupData['recurringTransactions'] as List)
                .map((rt) => RecurringTransaction.fromJson(rt))
                .toList();
        final repo = RecurringTransactionRepository();
        await repo.init();
        for (var transaction in recurringTransactions) {
          await repo.add(transaction);
        }
      }
      if (backupData.containsKey('categories')) {
        final categoriesList = (backupData['categories'] as List)
            .map((c) => Category.fromJson(c))
            .toList();
        await saveCategories(categoriesList);
      }
      if (backupData.containsKey('kmhTransactions')) {
        final kmhTransactions = (backupData['kmhTransactions'] as List)
            .map((kt) => KmhTransaction.fromJson(kt))
            .toList();
        final kmhRepo = KmhRepository();
        for (var transaction in kmhTransactions) {
          await kmhRepo.addTransaction(transaction);
        }
      }
      if (backupData.containsKey('billTemplates')) {
        final billTemplates = (backupData['billTemplates'] as List)
            .map((bt) => BillTemplate.fromJson(bt))
            .toList();
        final billTemplateService = BillTemplateService();
        for (var template in billTemplates) {
          await billTemplateService.addTemplateDirect(template);
        }
      }
      if (backupData.containsKey('billPayments')) {
        final billPayments = (backupData['billPayments'] as List)
            .map((bp) => BillPayment.fromJson(bp))
            .toList();
        final billPaymentService = BillPaymentService();
        for (var payment in billPayments) {
          await billPaymentService.addPaymentDirect(payment);
        }
      }
    } catch (e) {
      debugPrint('Error in restoreFromBackup: $e');
      rethrow;
    }
  }
}
