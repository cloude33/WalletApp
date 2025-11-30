import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/wallet.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/loan.dart';
import '../models/category.dart';
import '../models/recurring_transaction.dart';
import 'cache_service.dart';
import 'credit_card_service.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  SharedPreferences? _prefs;
  final CacheService _cache = CacheService();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // User methods
  Future<User?> getCurrentUser() async {
    final userJson = _prefs?.getString('current_user');
    if (userJson == null) return null;
    return User.fromJson(json.decode(userJson));
  }

  Future<void> saveUser(User user) async {
    await _prefs?.setString('current_user', json.encode(user.toJson()));
  }

  Future<void> updateUser(User user) async {
    // Save as current user
    await saveUser(user);

    // Update in all users list
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

  // Wallet methods
  Future<List<Wallet>> getWallets() async {
    // Try cache first
    final cached = _cache.get<List<Wallet>>('wallets');
    if (cached != null) {
      return cached;
    }

    // Load from storage
    final walletsJson = _prefs?.getString('wallets') ?? '[]';
    final List<dynamic> walletsList = json.decode(walletsJson);
    final wallets = walletsList.map((w) => Wallet.fromJson(w)).toList();
    
    // Load credit cards and add them as wallets
    try {
      final creditCardService = CreditCardService();
      final creditCards = await creditCardService.getActiveCards();
      
      for (var card in creditCards) {
        // Get current debt for the card
        final currentDebt = await creditCardService.getCurrentDebt(card.id);
        
        // Create a wallet representation of the credit card
        final ccWallet = Wallet(
          id: 'cc_${card.id}', // Prefix to identify credit card wallets
          name: '${card.bankName} ${card.cardName} •••• ${card.last4Digits}',
          balance: -currentDebt, // Negative balance represents debt
          type: 'credit_card',
          color: card.cardColor.toString(),
          icon: 'credit_card',
          creditLimit: card.creditLimit,
        );
        
        wallets.add(ccWallet);
      }
    } catch (e) {
      // If credit card service fails, just continue with regular wallets
      print('Error loading credit cards as wallets: $e');
    }
    
    // Cache the result
    _cache.put('wallets', wallets);
    
    return wallets;
  }

  Future<void> saveWallets(List<Wallet> wallets) async {
    // Filter out credit card wallets (they are dynamically generated)
    final regularWallets = wallets.where((w) => !w.id.startsWith('cc_')).toList();
    
    final walletsJson = json.encode(regularWallets.map((w) => w.toJson()).toList());
    await _prefs?.setString('wallets', walletsJson);
    
    // Invalidate cache
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

  // Transaction methods
  Future<List<Transaction>> getTransactions() async {
    // Try cache first
    final cached = _cache.get<List<Transaction>>('transactions');
    if (cached != null) {
      return cached;
    }

    // Load from storage
    final transactionsJson = _prefs?.getString('transactions') ?? '[]';
    final List<dynamic> transactionsList = json.decode(transactionsJson);
    final transactions = transactionsList.map((t) => Transaction.fromJson(t)).toList();
    
    // Cache the result
    _cache.put('transactions', transactions);
    
    return transactions;
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    final transactionsJson = json.encode(
      transactions.map((t) => t.toJson()).toList(),
    );
    await _prefs?.setString('transactions', transactionsJson);
    
    // Invalidate cache
    _cache.invalidate('transactions');
  }

  Future<void> addTransaction(Transaction transaction) async {
    final transactions = await getTransactions();
    transactions.add(transaction);
    await saveTransactions(transactions);
  }

  Future<void> deleteTransaction(String id) async {
    final transactions = await getTransactions();
    final index = transactions.indexWhere((t) => t.id == id);
    if (index == -1) {
      return;
    }

    final tx = transactions[index];
    
    // Taksitli işlem kontrolü
    if (tx.parentTransactionId != null || 
        transactions.any((t) => t.parentTransactionId == tx.id)) {
      // Taksitli işlem ise, tüm taksitleri sil
      await deleteTransactionWithInstallments(id);
      return;
    }

    transactions.removeAt(index);
    await saveTransactions(transactions);

    // Silinen işlemin etkisini cüzdandan geri al
    await _revertTransactionEffect(tx);
  }

  Future<void> updateTransaction(Transaction oldTransaction, Transaction newTransaction) async {
    final transactions = await getTransactions();
    final index = transactions.indexWhere((t) => t.id == oldTransaction.id);
    if (index == -1) {
      throw Exception('Transaction not found');
    }

    // Eski işlemin etkisini geri al
    await _revertTransactionEffect(oldTransaction);

    // Yeni işlemi güncelle
    transactions[index] = newTransaction;
    await saveTransactions(transactions);

    // Yeni işlemin etkisini uygula
    await _applyTransactionEffect(newTransaction);
  }

  Future<void> _revertTransactionEffect(Transaction transaction) async {
    if (transaction.type == 'transfer') {
      // Transfer işlemleri için özel işlem gerekli
      return;
    }

    // Skip credit card wallets (they are managed by CreditCardService)
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
    
    wallets[walletIndex] = wallet.copyWith(balance: wallet.balance + adjustment);
    await saveWallets(wallets);
  }

  Future<void> _applyTransactionEffect(Transaction transaction) async {
    if (transaction.type == 'transfer') {
      // Transfer işlemleri için özel işlem gerekli
      return;
    }

    // Skip credit card wallets (they are managed by CreditCardService)
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
    
    wallets[walletIndex] = wallet.copyWith(balance: wallet.balance + adjustment);
    await saveWallets(wallets);
  }

  Future<void> deleteTransactionWithInstallments(String transactionId) async {
    final transactions = await getTransactions();
    final transaction = transactions.firstWhere(
      (t) => t.id == transactionId,
      orElse: () => throw Exception('Transaction not found'),
    );

    // Ana işlem veya taksit ise, tüm ilgili işlemleri bul
    String? parentId;
    if (transaction.parentTransactionId != null) {
      parentId = transaction.parentTransactionId;
    } else {
      parentId = transactionId;
    }

    // Tüm ilgili işlemleri bul ve sil
    final relatedTransactions = transactions.where((t) => 
      t.id == parentId || 
      t.parentTransactionId == parentId ||
      (t.parentTransactionId != null && t.parentTransactionId == transaction.id)
    ).toList();

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
    
    // Giden işlem
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

    // Gelen işlem
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

    // Wallet bakiyelerini güncelle
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

  // Goal methods
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

  // Budget methods
  Future<List<Budget>> getBudgets() async {
    final budgetsJson = _prefs?.getString('budgets') ?? '[]';
    final List<dynamic> budgetsList = json.decode(budgetsJson);
    return budgetsList.map((b) => Budget.fromJson(b)).toList();
  }

  Future<void> saveBudgets(List<Budget> budgets) async {
    final budgetsJson = json.encode(budgets.map((b) => b.toJson()).toList());
    await _prefs?.setString('budgets', budgetsJson);
  }

  Future<void> addBudget(Budget budget) async {
    final budgets = await getBudgets();
    budgets.add(budget);
    await saveBudgets(budgets);
  }

  Future<void> deleteBudget(String id) async {
    final budgets = await getBudgets();
    budgets.removeWhere((b) => b.id == id);
    await saveBudgets(budgets);
  }

  Future<void> updateBudget(Budget budget) async {
    final budgets = await getBudgets();
    final index = budgets.indexWhere((b) => b.id == budget.id);
    if (index != -1) {
      budgets[index] = budget;
      await saveBudgets(budgets);
    }
  }

  // Category methods
  Future<List<Category>> getCategories() async {
    final categoriesJson = _prefs?.getString('categories');
    if (categoriesJson == null) {
      // If no categories saved, return default and save them
      await saveCategories(defaultCategories);
      return defaultCategories;
    }
    final List<dynamic> categoriesList = json.decode(categoriesJson);
    return categoriesList.map((c) => Category.fromJson(c)).toList();
  }

  Future<void> saveCategories(List<Category> categories) async {
    final categoriesJson = json.encode(categories.map((c) => c.toJson()).toList());
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

  // Backup and Restore methods
  Future<List<User>> getUsers() async {
    return await getAllUsers();
  }

  Future<void> restoreBackup(Map<String, dynamic> backupData) async {
    try {
      // Kullanıcıları geri yükle
      if (backupData['users'] != null) {
        final users = (backupData['users'] as List)
            .map((u) => User.fromJson(u))
            .toList();
        await saveAllUsers(users);
        if (users.isNotEmpty) {
          await saveUser(users.first);
        }
      }

      // Cüzdanları geri yükle
      if (backupData['wallets'] != null) {
        final wallets = (backupData['wallets'] as List)
            .map((w) => Wallet.fromJson(w))
            .toList();
        await saveWallets(wallets);
      }

      // İşlemleri geri yükle
      if (backupData['transactions'] != null) {
        final transactions = (backupData['transactions'] as List)
            .map((t) => Transaction.fromJson(t))
            .toList();
        await saveTransactions(transactions);
      }

      // Hedefleri geri yükle
      if (backupData['goals'] != null) {
        final goals = (backupData['goals'] as List)
            .map((g) => Goal.fromJson(g))
            .toList();
        await saveGoals(goals);
      }

      // Kategorileri geri yükle
      if (backupData['categories'] != null) {
        final categories = (backupData['categories'] as List)
            .map((c) => Category.fromJson(c))
            .toList();
        await saveCategories(categories);
      }
    } catch (e) {
      print('Veri geri yükleme hatası: $e');
      rethrow;
    }
  }

  // Loan methods
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

  // Recurring Transaction methods
  Future<List<RecurringTransaction>> getRecurringTransactions() async {
    final json = _prefs?.getString('recurring_transactions') ?? '[]';
    final List<dynamic> list = jsonDecode(json);
    return list.map((item) => RecurringTransaction.fromJson(item)).toList();
  }

  Future<void> saveRecurringTransactions(List<RecurringTransaction> transactions) async {
    final json = jsonEncode(transactions.map((t) => t.toJson()).toList());
    await _prefs?.setString('recurring_transactions', json);
  }

  Future<void> addRecurringTransaction(RecurringTransaction transaction) async {
    final transactions = await getRecurringTransactions();
    transactions.add(transaction);
    await saveRecurringTransactions(transactions);
  }

  Future<void> updateRecurringTransaction(RecurringTransaction transaction) async {
    final transactions = await getRecurringTransactions();
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      transactions[index] = transaction;
      await saveRecurringTransactions(transactions);
    }
  }

  Future<void> deleteRecurringTransaction(String id) async {
    final transactions = await getRecurringTransactions();
    transactions.removeWhere((t) => t.id == id);
    await saveRecurringTransactions(transactions);
  }

  Future<void> toggleRecurringTransaction(String id) async {
    final transactions = await getRecurringTransactions();
    final index = transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      transactions[index] = transactions[index].copyWith(
        isActive: !transactions[index].isActive,
      );
      await saveRecurringTransactions(transactions);
    }
  }

  // Process recurring transactions that are due
  Future<List<Transaction>> processRecurringTransactions() async {
    final recurringTransactions = await getRecurringTransactions();
    final currentDate = DateTime.now();
    final processedTransactions = <Transaction>[];
    final wallets = await getWallets();

    for (var recurring in recurringTransactions) {
      if (recurring.shouldProcess(currentDate)) {
        // Create new transaction
        final transaction = Transaction(
          id: '${recurring.id}_${DateTime.now().millisecondsSinceEpoch}',
          type: recurring.isIncome ? 'income' : 'expense',
          amount: recurring.amount,
          description: recurring.description ?? recurring.title,
          category: recurring.category,
          walletId: wallets.isNotEmpty ? wallets.first.id : '',
          date: currentDate,
          memo: recurring.description,
          images: [],
        );

        await addTransaction(transaction);
        processedTransactions.add(transaction);

        // Update recurring transaction
        final updated = recurring.copyWith(
          lastCreatedDate: currentDate,
          createdCount: recurring.createdCount + 1,
        );
        await updateRecurringTransaction(updated);

        // Check if should deactivate
        if (updated.shouldDeactivate) {
          final deactivated = updated.copyWith(isActive: false);
          await updateRecurringTransaction(deactivated);
        }
      }
    }

    return processedTransactions;
  }

  Future<void> clearAllData() async {
    await _prefs?.clear();
  }

  // Backup/Restore methods
  Future<void> restoreFromBackup(Map<String, dynamic> backupData) async {
    try {
      // Clear existing data
      await _prefs?.clear();

      // Restore transactions
      if (backupData.containsKey('transactions')) {
        final transactions = (backupData['transactions'] as List)
            .map((t) => Transaction.fromJson(t))
            .toList();
        await saveTransactions(transactions);
      }

      // Restore budgets
      if (backupData.containsKey('budgets')) {
        final budgets = (backupData['budgets'] as List)
            .map((b) => Budget.fromJson(b))
            .toList();
        await saveBudgets(budgets);
      }

      // Restore wallets
      if (backupData.containsKey('wallets')) {
        final wallets = (backupData['wallets'] as List)
            .map((w) => Wallet.fromJson(w))
            .toList();
        await saveWallets(wallets);
      }

      // Restore recurring transactions
      if (backupData.containsKey('recurringTransactions')) {
        final recurringTransactions =
            (backupData['recurringTransactions'] as List)
                .map((rt) => RecurringTransaction.fromJson(rt))
                .toList();
        await saveRecurringTransactions(recurringTransactions);
      }

      // Restore categories
      if (backupData.containsKey('categories')) {
        final categoriesList = (backupData['categories'] as List)
            .map((c) => Category.fromJson(c))
            .toList();
        await saveCategories(categoriesList);
      }
    } catch (e) {
      print('Error in restoreFromBackup: $e');
      rethrow;
    }
  }
}
