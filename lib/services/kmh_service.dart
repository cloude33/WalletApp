import 'package:uuid/uuid.dart';
import '../models/wallet.dart';
import '../models/kmh_transaction.dart';
import '../models/kmh_transaction_type.dart';
import '../models/kmh_statement.dart';
import '../models/kmh_summary.dart';
import '../repositories/kmh_repository.dart';
import '../services/data_service.dart';
import '../services/kmh_interest_calculator.dart';
import '../services/kmh_alert_service.dart';
import '../services/kmh_interest_settings_service.dart';
import '../exceptions/error_codes.dart';
import '../exceptions/kmh_exception.dart';
import '../utils/kmh_validator.dart';
import '../utils/cache_manager.dart';
class KmhService {
  final KmhRepository _repository;
  final DataService _dataService;
  final KmhInterestCalculator _calculator;
  final KmhAlertService _alertService;
  final KmhInterestSettingsService _settingsService;
  final Uuid _uuid = const Uuid();
  final CacheManager _cache = CacheManager();
  static const Duration _summaryCacheDuration = Duration(minutes: 5);
  static const Duration _statementCacheDuration = Duration(minutes: 3);

  KmhService({
    KmhRepository? repository,
    DataService? dataService,
    KmhInterestCalculator? calculator,
    KmhAlertService? alertService,
    KmhInterestSettingsService? settingsService,
  })  : _repository = repository ?? KmhRepository(),
        _dataService = dataService ?? DataService(),
        _calculator = calculator ?? KmhInterestCalculator(),
        _alertService = alertService ?? KmhAlertService(),
        _settingsService = settingsService ?? KmhInterestSettingsService();
  Future<Wallet> createKmhAccount({
    required String bankName,
    required double creditLimit,
    required double interestRate,
    String? accountNumber,
    double initialBalance = 0.0,
    String color = '0xFF2196F3',
    String icon = 'account_balance',
  }) async {
    KmhValidator.validateBankName(bankName);
    KmhValidator.validateCreditLimit(creditLimit);
    KmhValidator.validateInterestRate(interestRate);
    final wallet = Wallet(
      id: _uuid.v4(),
      name: bankName,
      balance: initialBalance,
      type: 'bank',
      color: color,
      icon: icon,
      creditLimit: creditLimit,
      interestRate: interestRate,
      lastInterestDate: DateTime.now(),
      accruedInterest: 0.0,
      accountNumber: accountNumber,
    );
    await _dataService.addWallet(wallet);

    return wallet;
  }
  Future<void> updateKmhAccount(Wallet account) async {
    if (!account.isKmhAccount) {
      throw KmhException(
        ErrorCodes.INVALID_INPUT,
        'Hesap bir KMH hesabı değil',
      );
    }
    KmhValidator.validateCreditLimit(account.creditLimit);
    if (account.interestRate == null) {
      throw KmhException.invalidInterestRate('Faiz oranı belirtilmemiş');
    }
    KmhValidator.validateInterestRate(account.interestRate!);
    await _dataService.updateWallet(account);
  }
  Future<void> deleteKmhAccount(String walletId) async {
    await _repository.deleteTransactionsByWallet(walletId);
    await _dataService.deleteWallet(walletId);
  }
  Future<void> recordWithdrawal(
    String walletId,
    double amount,
    String description,
  ) async {
    KmhValidator.validateAmount(amount);
    KmhValidator.validateDescription(description);
    final wallets = await _dataService.getWallets();
    final wallet = wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => throw KmhException(
        ErrorCodes.CARD_NOT_FOUND,
        'KMH hesabı bulunamadı',
      ),
    );
    if (!wallet.isKmhAccount) {
      throw KmhException(
        ErrorCodes.INVALID_INPUT,
        'Hesap bir KMH hesabı değil',
      );
    }
    KmhValidator.validateWithdrawal(
      currentBalance: wallet.balance,
      withdrawalAmount: amount,
      creditLimit: wallet.creditLimit,
    );
    final newBalance = wallet.balance - amount;
    final transaction = KmhTransaction(
      id: _uuid.v4(),
      walletId: walletId,
      type: KmhTransactionType.withdrawal,
      amount: amount,
      date: DateTime.now(),
      description: description,
      balanceAfter: newBalance,
    );
    final validationError = transaction.validate();
    if (validationError != null) {
      throw Exception(validationError);
    }
    await _repository.addTransaction(transaction);
    final updatedWallet = wallet.copyWith(balance: newBalance);
    await _dataService.updateWallet(updatedWallet);
    CacheKeys.clearKmhCache(walletId);
    try {
      final utilizationRate = updatedWallet.utilizationRate;
      final settings = await _alertService.getAlertSettings();
      if (settings.limitAlertsEnabled && 
          utilizationRate >= settings.warningThreshold) {
        await _alertService.sendLimitWarning(updatedWallet, utilizationRate);
      }
    } catch (e) {
      print('Failed to send limit alert: $e');
    }
  }
  Future<void> recordDeposit(
    String walletId,
    double amount,
    String description,
  ) async {
    KmhValidator.validateAmount(amount);
    KmhValidator.validateDescription(description);
    final wallets = await _dataService.getWallets();
    final wallet = wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => throw KmhException(
        ErrorCodes.CARD_NOT_FOUND,
        'KMH hesabı bulunamadı',
      ),
    );
    if (!wallet.isKmhAccount) {
      throw KmhException(
        ErrorCodes.INVALID_INPUT,
        'Hesap bir KMH hesabı değil',
      );
    }
    final newBalance = wallet.balance + amount;
    final transaction = KmhTransaction(
      id: _uuid.v4(),
      walletId: walletId,
      type: KmhTransactionType.deposit,
      amount: amount,
      date: DateTime.now(),
      description: description,
      balanceAfter: newBalance,
    );
    final validationError = transaction.validate();
    if (validationError != null) {
      throw Exception(validationError);
    }
    await _repository.addTransaction(transaction);
    final updatedWallet = wallet.copyWith(balance: newBalance);
    await _dataService.updateWallet(updatedWallet);
    CacheKeys.clearKmhCache(walletId);
  }
  Future<bool> checkLimitAvailability(String walletId, double amount) async {
    final wallets = await _dataService.getWallets();
    final wallet = wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => throw KmhException(
        ErrorCodes.CARD_NOT_FOUND,
        'KMH hesabı bulunamadı',
      ),
    );
    if (!wallet.isKmhAccount) {
      throw KmhException(
        ErrorCodes.INVALID_INPUT,
        'Hesap bir KMH hesabı değil',
      );
    }
    return KmhValidator.checkLimitAvailability(
      currentBalance: wallet.balance,
      requestedAmount: amount,
      creditLimit: wallet.creditLimit,
    );
  }
  Future<double> getAvailableCredit(String walletId) async {
    final wallets = await _dataService.getWallets();
    final wallet = wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => throw KmhException(
        ErrorCodes.CARD_NOT_FOUND,
        'KMH hesabı bulunamadı',
      ),
    );
    if (!wallet.isKmhAccount) {
      throw KmhException(
        ErrorCodes.INVALID_INPUT,
        'Hesap bir KMH hesabı değil',
      );
    }
    return KmhValidator.calculateAvailableCredit(
      currentBalance: wallet.balance,
      creditLimit: wallet.creditLimit,
    );
  }
  Future<void> applyDailyInterest(String walletId) async {
    final wallets = await _dataService.getWallets();
    final wallet = wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => throw KmhException(
        ErrorCodes.CARD_NOT_FOUND,
        'KMH hesabı bulunamadı',
      ),
    );
    if (!wallet.isKmhAccount) {
      throw KmhException(
        ErrorCodes.INVALID_INPUT,
        'Hesap bir KMH hesabı değil',
      );
    }
    if (wallet.interestRate == null) {
      throw KmhException.invalidInterestRate('Faiz oranı belirtilmemiş');
    }
    if (wallet.balance >= 0) {
      return;
    }
    
    final settings = await _settingsService.getSettings();
    final interestAmount = _calculator.calculateDailyInterest(
      balance: wallet.balance,
      monthlyRate: wallet.interestRate!,
      kkdfRate: settings.kkdfRate / 100,
      bsmvRate: settings.bsmvRate / 100,
    );
    if (interestAmount < 0.01) {
      return;
    }
    final newBalance = wallet.balance - interestAmount;
    final transaction = KmhTransaction(
      id: _uuid.v4(),
      walletId: walletId,
      type: KmhTransactionType.interest,
      amount: interestAmount,
      date: DateTime.now(),
      description: 'Günlük faiz tahakkuku',
      balanceAfter: newBalance,
      interestAmount: interestAmount,
    );
    final validationError = transaction.validate();
    if (validationError != null) {
      throw Exception(validationError);
    }
    await _repository.addTransaction(transaction);
    final updatedWallet = wallet.copyWith(
      balance: newBalance,
      lastInterestDate: DateTime.now(),
      accruedInterest: (wallet.accruedInterest ?? 0.0) + interestAmount,
    );
    await _dataService.updateWallet(updatedWallet);
    CacheKeys.clearKmhCache(walletId);
    try {
      await _alertService.sendInterestNotification(updatedWallet, interestAmount);
    } catch (e) {
      print('Failed to send interest notification: $e');
    }
  }
  Future<int> applyInterestToAllAccounts() async {
    final wallets = await _dataService.getWallets();
    final kmhAccounts = wallets.where((w) => 
      w.isKmhAccount && 
      w.balance < 0 && 
      w.interestRate != null
    ).toList();

    int accountsProcessed = 0;
    for (final wallet in kmhAccounts) {
      try {
        await applyDailyInterest(wallet.id);
        accountsProcessed++;
      } catch (e) {
        print('Error applying interest to account ${wallet.id}: $e');
      }
    }

    return accountsProcessed;
  }
  Future<KmhStatement> generateStatement(
    String walletId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final dateRange = '${startDate.millisecondsSinceEpoch}_${endDate.millisecondsSinceEpoch}';
    final cacheKey = CacheKeys.kmhStatement(walletId, dateRange);
    final cached = _cache.get<KmhStatement>(cacheKey);
    if (cached != null) {
      return cached;
    }
    final wallets = await _dataService.getWallets();
    final wallet = wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => throw KmhException(
        ErrorCodes.CARD_NOT_FOUND,
        'KMH hesabı bulunamadı',
      ),
    );
    if (!wallet.isKmhAccount) {
      throw KmhException(
        ErrorCodes.INVALID_INPUT,
        'Hesap bir KMH hesabı değil',
      );
    }
    final transactions = await _repository.getTransactionsByDateRange(
      walletId,
      startDate,
      endDate,
    );
    final totalWithdrawals = await _repository.getTotalWithdrawals(
      walletId,
      startDate,
      endDate,
    );

    final totalDeposits = await _repository.getTotalDeposits(
      walletId,
      startDate,
      endDate,
    );

    final totalInterest = await _repository.getTotalInterest(
      walletId,
      startDate,
      endDate,
    );
    final netChange = totalDeposits - totalWithdrawals - totalInterest;
    final openingBalance = wallet.balance - netChange;
    final statement = KmhStatement(
      walletId: walletId,
      walletName: wallet.name,
      startDate: startDate,
      endDate: endDate,
      transactions: transactions,
      totalWithdrawals: totalWithdrawals,
      totalDeposits: totalDeposits,
      totalInterest: totalInterest,
      openingBalance: openingBalance,
      closingBalance: wallet.balance,
    );
    _cache.set(cacheKey, statement, duration: _statementCacheDuration);

    return statement;
  }
  Future<KmhSummary> getAccountSummary(String walletId) async {
    final cacheKey = CacheKeys.kmhSummary(walletId);
    final cached = _cache.get<KmhSummary>(cacheKey);
    if (cached != null) {
      return cached;
    }
    final wallets = await _dataService.getWallets();
    final wallet = wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => throw KmhException(
        ErrorCodes.CARD_NOT_FOUND,
        'KMH hesabı bulunamadı',
      ),
    );
    if (!wallet.isKmhAccount) {
      throw KmhException(
        ErrorCodes.INVALID_INPUT,
        'Hesap bir KMH hesabı değil',
      );
    }
    // If interest rate is missing, fallback to 0.0 to prevent crash and allow editing
    final interestRate = wallet.interestRate ?? 0.0;
    
    final settings = await _settingsService.getSettings();

    final totalTransactions = await _repository.countByWalletId(walletId);
    final dailyInterest = _calculator.calculateDailyInterest(
      balance: wallet.balance,
      monthlyRate: interestRate,
      kkdfRate: settings.kkdfRate / 100,
      bsmvRate: settings.bsmvRate / 100,
    );

    final monthlyInterest = _calculator.estimateMonthlyInterest(
      balance: wallet.balance,
      monthlyRate: interestRate,
      kkdfRate: settings.kkdfRate / 100,
      bsmvRate: settings.bsmvRate / 100,
    );

    final annualInterest = _calculator.estimateAnnualInterest(
      balance: wallet.balance,
      monthlyRate: interestRate,
      kkdfRate: settings.kkdfRate / 100,
      bsmvRate: settings.bsmvRate / 100,
    );
    final summary = KmhSummary(
      walletId: walletId,
      walletName: wallet.name,
      currentBalance: wallet.balance,
      creditLimit: wallet.creditLimit,
      interestRate: interestRate,
      usedCredit: wallet.usedCredit,
      availableCredit: wallet.availableCredit,
      utilizationRate: wallet.utilizationRate,
      accruedInterest: wallet.accruedInterest ?? 0.0,
      lastInterestDate: wallet.lastInterestDate,
      dailyInterestEstimate: dailyInterest,
      monthlyInterestEstimate: monthlyInterest,
      annualInterestEstimate: annualInterest,
      totalTransactions: totalTransactions,
    );
    _cache.set(cacheKey, summary, duration: _summaryCacheDuration);

    return summary;
  }
}
