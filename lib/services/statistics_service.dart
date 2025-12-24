/// İstatistik Servisi
///
/// Money uygulamasının tüm istatistiksel hesaplamalarını ve analizlerini gerçekleştiren ana servis.
/// Bu servis, nakit akışı, harcama analizi, kredi/KMH analizi, varlık analizi ve
/// karşılaştırma işlemlerini yönetir.
///
/// ## Özellikler
///
/// - **Nakit Akışı Analizi**: Gelir ve gider akışlarının zaman içindeki değişimini hesaplar
/// - **Harcama Analizi**: Kategori bazlı harcama dağılımı ve trendleri
/// - **Kredi ve KMH Analizi**: Kredi kartı ve KMH hesaplarının detaylı analizi
/// - **Varlık Analizi**: Net varlık, likidite ve finansal sağlık skoru hesaplama
/// - **Karşılaştırma**: Dönemsel ve ortalama karşılaştırmaları
/// - **Önbellekleme**: Performans için akıllı cache yönetimi
///
/// ## Kullanım
///
/// ```dart
/// final service = StatisticsService();
///
/// // Nakit akışı hesaplama
/// final cashFlow = await service.calculateCashFlow(
///   startDate: DateTime(2024, 1, 1),
///   endDate: DateTime(2024, 12, 31),
/// );
///
/// // Harcama analizi
/// final spending = await service.analyzeSpending(
///   startDate: DateTime.now().subtract(Duration(days: 30)),
///   endDate: DateTime.now(),
/// );
/// ```
///
/// ## Performans
///
/// - Hesaplanan veriler 5 dakika boyunca önbelleklenir
/// - Ağır hesaplamalar background isolate'te çalışır
/// - Lazy loading ile sadece gerekli veriler yüklenir
///
/// ## Hata Yönetimi
///
/// Tüm metodlar [StatisticsException] fırlatabilir. Hata kodları:
/// - [StatisticsErrorCode.noData]: Veri bulunamadı
/// - [StatisticsErrorCode.invalidDateRange]: Geçersiz tarih aralığı
/// - [StatisticsErrorCode.calculationError]: Hesaplama hatası
///
/// @see [CashFlowData] Nakit akışı veri modeli
/// @see [SpendingAnalysis] Harcama analizi veri modeli
/// @see [CreditAnalysis] Kredi analizi veri modeli
/// @see [AssetAnalysis] Varlık analizi veri modeli
import 'package:flutter/foundation.dart';
import '../models/credit_card_transaction.dart';
import '../models/cash_flow_data.dart';
import '../models/spending_analysis.dart';
import '../models/credit_analysis.dart';
import '../models/asset_analysis.dart';
import '../models/comparison_data.dart';
import '../models/goal_comparison.dart';

import '../repositories/credit_card_transaction_repository.dart';
import '../repositories/credit_card_statement_repository.dart';
import '../repositories/kmh_repository.dart';
import '../services/data_service.dart';
import '../services/credit_card_service.dart';
import '../exceptions/error_codes.dart';
import '../utils/cache_manager.dart';
export '../models/asset_analysis.dart' show AssetType, FinancialHealthScore;
export '../models/spending_analysis.dart' show DayOfWeek;
export '../models/comparison_data.dart'
    show ComparisonMetric, CategoryComparison;
export '../models/goal_comparison.dart'
    show GoalComparison, GoalComparisonSummary, GoalStatus;

/// İstatistik Servisi - Ana istatistik hesaplama ve analiz servisi
///
/// Singleton pattern kullanır. Tüm istatistiksel hesaplamalar bu servis üzerinden yapılır.
class StatisticsService {
  final CreditCardTransactionRepository _transactionRepo =
      CreditCardTransactionRepository();
  final CreditCardStatementRepository _statementRepo =
      CreditCardStatementRepository();
  final KmhRepository _kmhRepo = KmhRepository();
  final DataService _dataService = DataService();
  final CreditCardService _creditCardService = CreditCardService();
  final CacheManager _cache = CacheManager();
  static const Duration _cacheDuration = Duration(minutes: 5);
  TrendDirection _calculateTrendDirection(List<double> values) {
    if (values.length < 2) {
      return TrendDirection.stable;
    }
    final n = values.length;
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumX2 = 0;

    for (int i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = values[i];
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final average = sumY / n;
    final threshold = average * 0.05;

    if (slope > threshold) {
      return TrendDirection.up;
    } else if (slope < -threshold) {
      return TrendDirection.down;
    } else {
      return TrendDirection.stable;
    }
  }
  double _predictNextValue(List<double> values) {
    if (values.isEmpty) {
      return 0.0;
    }

    if (values.length == 1) {
      return values[0];
    }
    final n = values.length;
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumX2 = 0;

    for (int i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = values[i];
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;
    final prediction = slope * n + intercept;
    return prediction < 0 ? 0.0 : prediction;
  }
  Future<CashFlowData> calculateCashFlow({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
    String? category,
    bool includePreviousPeriod = false,
  }) async {
    try {
      if (endDate.isBefore(startDate)) {
        throw Exception(ErrorCodes.INVALID_DATE);
      }
      final cacheKey = CacheKeys.cashFlow(
        startDate: startDate,
        endDate: endDate,
        walletId: walletId,
        category: category,
      );
      final cached = _cache.get<CashFlowData>(cacheKey);
      if (cached != null) {
        return cached;
      }
      final wallets = await _dataService.getWallets();

      double totalIncome = 0;
      double totalExpense = 0;
      final monthlyData = <MonthlyData>[];
      DateTime currentMonth = DateTime(startDate.year, startDate.month, 1);
      final endMonth = DateTime(endDate.year, endDate.month, 1);

      while (currentMonth.isBefore(endMonth) ||
          currentMonth.isAtSameMomentAs(endMonth)) {
        final monthStart = currentMonth;
        final monthEnd = DateTime(
          currentMonth.year,
          currentMonth.month + 1,
          0,
          23,
          59,
          59,
        );

        double monthIncome = 0;
        double monthExpense = 0;
        final allTransactions = <CreditCardTransaction>[];
        final creditCards = await _creditCardService.getActiveCards();
        for (var card in creditCards) {
          if (walletId != null && card.id != walletId) continue;
          final cardTransactions = await _transactionRepo.findByDateRange(
            card.id,
            monthStart,
            monthEnd,
          );
          allTransactions.addAll(cardTransactions);
        }

        final filteredCCTransactions = allTransactions.where((t) {
          final matchesCategory = category == null || t.category == category;
          return matchesCategory;
        }).toList();
        for (var transaction in filteredCCTransactions) {
          monthExpense += transaction.amount;
        }
        for (var wallet in wallets) {
          if (wallet.isKmhAccount) {
            if (walletId != null && wallet.id != walletId) continue;

            final kmhTransactions = await _kmhRepo.getTransactionsByDateRange(
              wallet.id,
              monthStart,
              monthEnd,
            );

            for (var transaction in kmhTransactions) {
              if (transaction.type.toString().contains('withdrawal')) {
                monthExpense += transaction.amount;
              } else if (transaction.type.toString().contains('deposit')) {
                monthIncome += transaction.amount;
              }
            }
          }
        }

        totalIncome += monthIncome;
        totalExpense += monthExpense;

        monthlyData.add(
          MonthlyData(
            month: currentMonth,
            income: monthIncome,
            expense: monthExpense,
            netFlow: monthIncome - monthExpense,
          ),
        );

        currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
      }

      final netCashFlow = totalIncome - totalExpense;
      final daysDiff = endDate.difference(startDate).inDays + 1;
      final averageDaily = daysDiff > 0 ? netCashFlow / daysDiff : 0.0;
      final monthsCount = monthlyData.length;
      final averageMonthly = monthsCount > 0 ? netCashFlow / monthsCount : 0.0;
      final netFlowValues = monthlyData.map((m) => m.netFlow).toList();
      final trend = _calculateTrendDirection(netFlowValues);
      final incomeValues = monthlyData.map((m) => m.income).toList();
      final expenseValues = monthlyData.map((m) => m.expense).toList();
      final predictedIncome = _predictNextValue(incomeValues);
      final predictedExpense = _predictNextValue(expenseValues);
      final predictedNetFlow = predictedIncome - predictedExpense;
      double? previousPeriodIncome;
      double? previousPeriodExpense;
      double? changePercentage;

      if (includePreviousPeriod) {
        final periodDuration = endDate.difference(startDate);
        final previousStartDate = startDate.subtract(periodDuration);
        final previousEndDate = startDate.subtract(const Duration(days: 1));
        final previousPeriodData = await calculateCashFlow(
          startDate: previousStartDate,
          endDate: previousEndDate,
          walletId: walletId,
          category: category,
          includePreviousPeriod: false,
        );

        previousPeriodIncome = previousPeriodData.totalIncome;
        previousPeriodExpense = previousPeriodData.totalExpense;
        final previousNetFlow = previousPeriodIncome - previousPeriodExpense;
        if (previousNetFlow != 0) {
          changePercentage =
              ((netCashFlow - previousNetFlow) / previousNetFlow.abs()) * 100;
        } else if (netCashFlow != 0) {
          changePercentage = netCashFlow > 0 ? 100.0 : -100.0;
        } else {
          changePercentage = 0.0;
        }
      }

      final result = CashFlowData(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netCashFlow: netCashFlow,
        averageDaily: averageDaily,
        averageMonthly: averageMonthly,
        monthlyData: monthlyData,
        trend: trend,
        previousPeriodIncome: previousPeriodIncome,
        previousPeriodExpense: previousPeriodExpense,
        changePercentage: changePercentage,
        predictedIncome: monthlyData.isNotEmpty ? predictedIncome : null,
        predictedExpense: monthlyData.isNotEmpty ? predictedExpense : null,
        predictedNetFlow: monthlyData.isNotEmpty ? predictedNetFlow : null,
      );
      _cache.set(cacheKey, result, duration: _cacheDuration);

      return result;
    } catch (e) {
      if (e.toString().contains(ErrorCodes.INVALID_DATE)) {
        rethrow;
      }
      throw Exception('${ErrorCodes.CALCULATION_ERROR}: ${e.toString()}');
    }
  }
  Future<SpendingAnalysis> analyzeSpending({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? categories,
    Map<String, double>? budgets,
  }) async {
    try {
      if (endDate.isBefore(startDate)) {
        throw Exception(ErrorCodes.INVALID_DATE);
      }
      final cacheKey = CacheKeys.spendingAnalysis(
        startDate: startDate,
        endDate: endDate,
        categories: categories,
      );
      final cached = _cache.get<SpendingAnalysis>(cacheKey);
      if (cached != null) {
        return cached;
      }

      double totalSpending = 0;
      final categoryBreakdown = <String, double>{};
      final paymentMethodBreakdown = <String, double>{};
      final dayOfWeekSpending = <int, double>{};
      final hourOfDaySpending = <int, double>{};
      final allTransactions = <CreditCardTransaction>[];
      final creditCards = await _creditCardService.getActiveCards();
      for (var card in creditCards) {
        final cardTransactions = await _transactionRepo.findByDateRange(
          card.id,
          startDate,
          endDate,
        );
        allTransactions.addAll(cardTransactions);
      }

      final filteredTransactions = allTransactions.where((t) {
        final matchesCategory =
            categories == null || categories.contains(t.category);
        return matchesCategory;
      }).toList();
      for (var transaction in filteredTransactions) {
        totalSpending += transaction.amount;
        categoryBreakdown[transaction.category] =
            (categoryBreakdown[transaction.category] ?? 0) + transaction.amount;
        paymentMethodBreakdown['Kredi Kartı'] =
            (paymentMethodBreakdown['Kredi Kartı'] ?? 0) + transaction.amount;
        final dayOfWeek =
            transaction.transactionDate.weekday;
        dayOfWeekSpending[dayOfWeek] =
            (dayOfWeekSpending[dayOfWeek] ?? 0) + transaction.amount;
        final hour = transaction.transactionDate.hour;
        hourOfDaySpending[hour] =
            (hourOfDaySpending[hour] ?? 0) + transaction.amount;
      }
      final wallets = await _dataService.getWallets();
      for (var wallet in wallets) {
        if (wallet.isKmhAccount) {
          final kmhTransactions = await _kmhRepo.getTransactionsByDateRange(
            wallet.id,
            startDate,
            endDate,
          );

          for (var transaction in kmhTransactions) {
            if (transaction.type.toString().contains('withdrawal')) {
              totalSpending += transaction.amount;
              paymentMethodBreakdown['KMH'] =
                  (paymentMethodBreakdown['KMH'] ?? 0) + transaction.amount;
              final dayOfWeek = transaction.date.weekday;
              dayOfWeekSpending[dayOfWeek] =
                  (dayOfWeekSpending[dayOfWeek] ?? 0) + transaction.amount;
              final hour = transaction.date.hour;
              hourOfDaySpending[hour] =
                  (hourOfDaySpending[hour] ?? 0) + transaction.amount;
            }
          }
        }
      }
      String topCategory = '';
      double topCategoryAmount = 0;
      categoryBreakdown.forEach((category, amount) {
        if (amount > topCategoryAmount) {
          topCategory = category;
          topCategoryAmount = amount;
        }
      });
      int mostSpendingDayNum = 1;
      double maxDaySpending = 0;
      dayOfWeekSpending.forEach((day, amount) {
        if (amount > maxDaySpending) {
          mostSpendingDayNum = day;
          maxDaySpending = amount;
        }
      });
      final mostSpendingDay = DayOfWeek.values[mostSpendingDayNum - 1];
      int mostSpendingHour = 12;
      double maxHourSpending = 0;
      hourOfDaySpending.forEach((hour, amount) {
        if (amount > maxHourSpending) {
          mostSpendingHour = hour;
          maxHourSpending = amount;
        }
      });
      final categoryTrends = await _calculateCategoryTrends(
        startDate: startDate,
        endDate: endDate,
        categories: categoryBreakdown.keys.toList(),
      );
      final budgetComparisons = _calculateBudgetComparisons(
        categoryBreakdown: categoryBreakdown,
        budgets: budgets,
      );

      final result = SpendingAnalysis(
        totalSpending: totalSpending,
        categoryBreakdown: categoryBreakdown,
        paymentMethodBreakdown: paymentMethodBreakdown,
        categoryTrends: categoryTrends,
        budgetComparisons: budgetComparisons,
        topCategory: topCategory,
        topCategoryAmount: topCategoryAmount,
        mostSpendingDay: mostSpendingDay,
        mostSpendingHour: mostSpendingHour,
      );
      _cache.set(cacheKey, result, duration: _cacheDuration);

      return result;
    } catch (e) {
      if (e.toString().contains(ErrorCodes.INVALID_DATE)) {
        rethrow;
      }
      throw Exception('${ErrorCodes.CALCULATION_ERROR}: ${e.toString()}');
    }
  }
  Future<List<CategoryTrend>> _calculateCategoryTrends({
    required DateTime startDate,
    required DateTime endDate,
    required List<String> categories,
  }) async {
    final trends = <CategoryTrend>[];

    for (var category in categories) {
      final monthlySpending = <MonthlySpending>[];
      DateTime currentMonth = DateTime(startDate.year, startDate.month, 1);
      final endMonth = DateTime(endDate.year, endDate.month, 1);

      while (currentMonth.isBefore(endMonth) ||
          currentMonth.isAtSameMomentAs(endMonth)) {
        final monthStart = currentMonth;
        final monthEnd = DateTime(
          currentMonth.year,
          currentMonth.month + 1,
          0,
          23,
          59,
          59,
        );

        double monthAmount = 0;
        final creditCards = await _creditCardService.getActiveCards();
        for (var card in creditCards) {
          final cardTransactions = await _transactionRepo.findByDateRange(
            card.id,
            monthStart,
            monthEnd,
          );

          for (var transaction in cardTransactions) {
            if (transaction.category == category) {
              monthAmount += transaction.amount;
            }
          }
        }
        final wallets = await _dataService.getWallets();
        for (var wallet in wallets) {
          if (wallet.isKmhAccount) {
            final kmhTransactions = await _kmhRepo.getTransactionsByDateRange(
              wallet.id,
              monthStart,
              monthEnd,
            );

            for (var transaction in kmhTransactions) {
              if (transaction.type.toString().contains('withdrawal')) {
              }
            }
          }
        }

        monthlySpending.add(
          MonthlySpending(month: currentMonth, amount: monthAmount),
        );

        currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
      }
      final values = monthlySpending.map((m) => m.amount).toList();
      final trend = _calculateTrendDirection(values);
      double changePercentage = 0.0;
      if (monthlySpending.length >= 2) {
        final firstAmount = monthlySpending.first.amount;
        final lastAmount = monthlySpending.last.amount;

        if (firstAmount != 0) {
          changePercentage = ((lastAmount - firstAmount) / firstAmount) * 100;
        } else if (lastAmount != 0) {
          changePercentage = 100.0;
        }
      }

      trends.add(
        CategoryTrend(
          category: category,
          monthlySpending: monthlySpending,
          trend: trend,
          changePercentage: changePercentage,
        ),
      );
    }

    return trends;
  }
  Map<String, BudgetComparison> _calculateBudgetComparisons({
    required Map<String, double> categoryBreakdown,
    Map<String, double>? budgets,
  }) {
    if (budgets == null || budgets.isEmpty) {
      return {};
    }

    final comparisons = <String, BudgetComparison>{};

    budgets.forEach((category, budget) {
      final actual = categoryBreakdown[category] ?? 0.0;
      final remaining = budget - actual;
      final usagePercentage = budget > 0 ? (actual / budget) * 100 : 0.0;
      final exceeded = actual > budget;

      comparisons[category] = BudgetComparison(
        category: category,
        budget: budget,
        actual: actual,
        remaining: remaining,
        usagePercentage: usagePercentage,
        exceeded: exceeded,
      );
    });

    return comparisons;
  }
  Future<CreditAnalysis> analyzeCreditAndKmh() async {
    try {
      const cacheKey = CacheKeys.creditAnalysis;
      final cached = _cache.get<CreditAnalysis>(cacheKey);
      if (cached != null) {
        return cached;
      }

      final creditCards = await _creditCardService.getActiveCards();
      double totalCreditCardDebt = 0;
      double totalCreditLimit = 0;
      final creditCardSummaries = <CreditCardSummary>[];

      for (var card in creditCards) {
        final debt = await _creditCardService.getCurrentDebt(card.id);
        totalCreditCardDebt += debt;
        totalCreditLimit += card.creditLimit;
        final utilizationRate = card.creditLimit > 0
            ? (debt / card.creditLimit) * 100.0
            : 0.0;
        double? minimumPayment;
        DateTime? dueDate;

        try {
          final statements = await _statementRepo.findByCardId(card.id);
          if (statements.isNotEmpty) {
            statements.sort((a, b) => b.periodEnd.compareTo(a.periodEnd));
            final latestStatement = statements.first;
            minimumPayment = latestStatement.minimumPayment;
            dueDate = latestStatement.dueDate;
          }
        } catch (e) {
          debugPrint('Error: $e');
        }
        creditCardSummaries.add(
          CreditCardSummary(
            cardId: card.id,
            cardName: '${card.bankName} ${card.cardName}',
            debt: debt,
            limit: card.creditLimit,
            utilizationRate: utilizationRate,
            minimumPayment: minimumPayment,
            dueDate: dueDate,
          ),
        );
      }
      final creditUtilization = totalCreditLimit > 0
          ? (totalCreditCardDebt / totalCreditLimit) * 100.0
          : 0.0;

      final wallets = await _dataService.getWallets();
      final kmhAccounts = wallets.where((w) => w.isKmhAccount).toList();

      double totalKmhDebt = 0;
      double totalKmhLimit = 0;
      double dailyInterest = 0;
      final kmhSummaries = <KmhSummary>[];

      for (var wallet in kmhAccounts) {
        final debt = wallet.balance < 0 ? wallet.balance.abs() : 0.0;
        totalKmhDebt += debt;
        totalKmhLimit += wallet.creditLimit;
        final utilizationRate = wallet.creditLimit > 0
            ? (debt / wallet.creditLimit) * 100.0
            : 0.0;
        double accountDailyInterest = 0.0;
        final interestRate =
            wallet.interestRate ?? 24.0;

        if (debt > 0) {
          final annualRate = interestRate / 100;
          accountDailyInterest = (debt * annualRate) / 365;
          dailyInterest += accountDailyInterest;
        }
        kmhSummaries.add(
          KmhSummary(
            accountId: wallet.id,
            bankName: wallet.name,
            balance: wallet.balance,
            limit: wallet.creditLimit,
            utilizationRate: utilizationRate,
            interestRate: interestRate,
            dailyInterest: accountDailyInterest,
          ),
        );
      }
      final kmhUtilization = totalKmhLimit > 0
          ? (totalKmhDebt / totalKmhLimit) * 100.0
          : 0.0;
      final monthlyInterest = dailyInterest * 30;
      final annualInterest = dailyInterest * 365;
      final totalDebt = totalCreditCardDebt + totalKmhDebt;

      final debtTrend = await _calculateDebtTrend(
        creditCards: creditCards,
        kmhAccounts: kmhAccounts,
      );
      final result = CreditAnalysis(
        totalCreditCardDebt: totalCreditCardDebt,
        totalCreditLimit: totalCreditLimit,
        creditUtilization: creditUtilization,
        creditCards: creditCardSummaries,
        totalKmhDebt: totalKmhDebt,
        totalKmhLimit: totalKmhLimit,
        kmhUtilization: kmhUtilization,
        kmhAccounts: kmhSummaries,
        dailyInterest: dailyInterest,
        monthlyInterest: monthlyInterest,
        annualInterest: annualInterest,
        totalDebt: totalDebt,
        debtTrend: debtTrend,
      );
      _cache.set(cacheKey, result, duration: _cacheDuration);

      return result;
    } catch (e) {
      throw Exception('${ErrorCodes.DEBT_CALCULATION_ERROR}: ${e.toString()}');
    }
  }
  Future<List<DebtTrendData>> _calculateDebtTrend({
    required List<dynamic> creditCards,
    required List<dynamic> kmhAccounts,
  }) async {
    final trendData = <DebtTrendData>[];
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(
        targetDate.year,
        targetDate.month + 1,
        0,
        23,
        59,
        59,
      );

      double creditCardDebt = 0;
      double kmhDebt = 0;
      for (var card in creditCards) {
        try {
          final transactions = await _transactionRepo.findByDateRange(
            card.id,
            DateTime(2000, 1, 1),
            monthEnd,
          );
          double monthDebt = 0;
          for (var transaction in transactions) {
            monthDebt += transaction.amount;
          }
          final statements = await _statementRepo.findByCardId(card.id);
          double totalPayments = 0;
          for (var statement in statements) {
            if (statement.periodEnd.isBefore(monthEnd) ||
                statement.periodEnd.isAtSameMomentAs(monthEnd)) {
              totalPayments += statement.paidAmount;
            }
          }
          final netDebt = monthDebt - totalPayments;
          creditCardDebt += netDebt > 0 ? netDebt : 0;
        } catch (e) {
          continue;
        }
      }
      for (var wallet in kmhAccounts) {
        try {
          final transactions = await _kmhRepo.getTransactionsByDateRange(
            wallet.id,
            DateTime(2000, 1, 1),
            monthEnd,
          );
          double balance = 0;
          for (var transaction in transactions) {
            if (transaction.type.toString().contains('deposit')) {
              balance += transaction.amount;
            } else if (transaction.type.toString().contains('withdrawal')) {
              balance -= transaction.amount;
            }
          }
          if (balance < 0) {
            kmhDebt += balance.abs();
          }
        } catch (e) {
          if (wallet.balance < 0) {
            kmhDebt += wallet.balance.abs();
          }
        }
      }

      final totalDebt = creditCardDebt + kmhDebt;

      trendData.add(
        DebtTrendData(
          date: targetDate,
          creditCardDebt: creditCardDebt,
          kmhDebt: kmhDebt,
          totalDebt: totalDebt,
        ),
      );
    }

    return trendData;
  }
  Future<AssetAnalysis> analyzeAssets() async {
    try {
      const cacheKey = CacheKeys.assetAnalysis;
      final cached = _cache.get<AssetAnalysis>(cacheKey);
      if (cached != null) {
        return cached;
      }

      final wallets = await _dataService.getWallets();

      double totalAssets = 0;
      double totalLiabilities = 0;
      double cashAndEquivalents = 0;
      double bankAccounts = 0;
      double positiveKmhBalances = 0;
      double investments = 0;
      double otherAssets = 0;
      for (var wallet in wallets) {
        if (wallet.balance > 0) {
          totalAssets += wallet.balance;
          if (wallet.type == 'cash') {
            cashAndEquivalents += wallet.balance;
          } else if (wallet.type == 'bank') {
            if (wallet.isKmhAccount) {
              positiveKmhBalances += wallet.balance;
            } else {
              bankAccounts += wallet.balance;
            }
          } else if (wallet.type == 'investment') {
            investments += wallet.balance;
          } else {
            otherAssets += wallet.balance;
          }
        } else if (wallet.balance < 0) {
          totalLiabilities += wallet.balance.abs();
        }
      }
      final creditAnalysis = await analyzeCreditAndKmh();
      totalLiabilities += creditAnalysis.totalCreditCardDebt;
      final netWorth = totalAssets - totalLiabilities;
      final liquidAssets =
          cashAndEquivalents + bankAccounts + positiveKmhBalances;
      final liquidityRatio = totalLiabilities > 0
          ? liquidAssets / totalLiabilities
          : liquidAssets > 0
          ? 999.99
          : 0.0;
      final assetBreakdown = <AssetType, double>{
        AssetType.cash: cashAndEquivalents,
        AssetType.bankAccount: bankAccounts,
        AssetType.kmhPositive: positiveKmhBalances,
        AssetType.investment: investments,
        AssetType.other: otherAssets,
      };
      final netWorthTrend = await _calculateNetWorthTrend();
      final healthScore = await _calculateFinancialHealthScore(
        totalAssets: totalAssets,
        totalLiabilities: totalLiabilities,
        netWorth: netWorth,
        liquidAssets: liquidAssets,
        liquidityRatio: liquidityRatio,
        investments: investments,
        netWorthTrend: netWorthTrend,
        creditAnalysis: creditAnalysis,
      );
      final result = AssetAnalysis(
        totalAssets: totalAssets,
        totalLiabilities: totalLiabilities,
        netWorth: netWorth,
        liquidityRatio: liquidityRatio,
        assetBreakdown: assetBreakdown,
        cashAndEquivalents: cashAndEquivalents,
        bankAccounts: bankAccounts,
        positiveKmhBalances: positiveKmhBalances,
        investments: investments,
        netWorthTrend: netWorthTrend,
        healthScore: healthScore,
      );
      _cache.set(cacheKey, result, duration: _cacheDuration);

      return result;
    } catch (e) {
      throw Exception('${ErrorCodes.CALCULATION_ERROR}: ${e.toString()}');
    }
  }
  Future<List<NetWorthTrendData>> _calculateNetWorthTrend() async {
    final trendData = <NetWorthTrendData>[];
    final now = DateTime.now();
    for (int i = 11; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(
        targetDate.year,
        targetDate.month + 1,
        0,
        23,
        59,
        59,
      );

      double assets = 0;
      double liabilities = 0;
      final wallets = await _dataService.getWallets();
      for (var wallet in wallets) {
        if (wallet.balance > 0) {
          assets += wallet.balance;
        } else if (wallet.balance < 0) {
          liabilities += wallet.balance.abs();
        }
      }
      try {
        final creditCards = await _creditCardService.getActiveCards();
        for (var card in creditCards) {
          final transactions = await _transactionRepo.findByDateRange(
            card.id,
            DateTime(2000, 1, 1),
            monthEnd,
          );

          double monthDebt = 0;
          for (var transaction in transactions) {
            monthDebt += transaction.amount;
          }

          final statements = await _statementRepo.findByCardId(card.id);
          double totalPayments = 0;
          for (var statement in statements) {
            if (statement.periodEnd.isBefore(monthEnd) ||
                statement.periodEnd.isAtSameMomentAs(monthEnd)) {
              totalPayments += statement.paidAmount;
            }
          }

          final netDebt = monthDebt - totalPayments;
          liabilities += netDebt > 0 ? netDebt : 0;
        }
      } catch (e) {
        debugPrint('Error: $e');
      }

      final netWorth = assets - liabilities;

      trendData.add(
        NetWorthTrendData(
          date: targetDate,
          assets: assets,
          liabilities: liabilities,
          netWorth: netWorth,
        ),
      );
    }

    return trendData;
  }
  Future<FinancialHealthScore> _calculateFinancialHealthScore({
    required double totalAssets,
    required double totalLiabilities,
    required double netWorth,
    required double liquidAssets,
    required double liquidityRatio,
    required double investments,
    required List<NetWorthTrendData> netWorthTrend,
    required CreditAnalysis creditAnalysis,
  }) async {

    double liquidityScore = 0.0;
    if (liquidityRatio >= 2.0) {
      liquidityScore += 60.0;
    } else if (liquidityRatio >= 1.5) {
      liquidityScore += 50.0;
    } else if (liquidityRatio >= 1.0) {
      liquidityScore += 40.0;
    } else if (liquidityRatio >= 0.5) {
      liquidityScore += 25.0;
    } else if (liquidityRatio > 0) {
      liquidityScore += 10.0;
    }
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);

    try {
      final spendingAnalysis = await analyzeSpending(
        startDate: threeMonthsAgo,
        endDate: now,
      );

      final monthlyExpenses = spendingAnalysis.totalSpending / 3;
      final emergencyFundMonths = monthlyExpenses > 0
          ? liquidAssets / monthlyExpenses
          : 0.0;

      if (emergencyFundMonths >= 6.0) {
        liquidityScore += 40.0;
      } else if (emergencyFundMonths >= 3.0) {
        liquidityScore += 30.0;
      } else if (emergencyFundMonths >= 1.0) {
        liquidityScore += 15.0;
      } else if (emergencyFundMonths > 0) {
        liquidityScore += 5.0;
      }
    } catch (e) {
      if (liquidAssets > 0) {
        liquidityScore += 20.0;
      }
    }
    liquidityScore = liquidityScore > 100 ? 100 : liquidityScore;

    double debtManagementScore = 0.0;
    final debtToAssetRatio = totalAssets > 0
        ? totalLiabilities / totalAssets
        : totalLiabilities > 0
        ? 1.0
        : 0.0;

    if (debtToAssetRatio == 0) {
      debtManagementScore += 50.0;
    } else if (debtToAssetRatio <= 0.2) {
      debtManagementScore += 45.0;
    } else if (debtToAssetRatio <= 0.4) {
      debtManagementScore += 35.0;
    } else if (debtToAssetRatio <= 0.6) {
      debtManagementScore += 20.0;
    } else if (debtToAssetRatio <= 0.8) {
      debtManagementScore += 10.0;
    } else {
      debtManagementScore += 0.0;
    }
    final avgUtilization =
        (creditAnalysis.creditUtilization + creditAnalysis.kmhUtilization) / 2;

    if (avgUtilization == 0) {
      debtManagementScore += 30.0;
    } else if (avgUtilization <= 30.0) {
      debtManagementScore += 25.0;
    } else if (avgUtilization <= 50.0) {
      debtManagementScore += 15.0;
    } else if (avgUtilization <= 70.0) {
      debtManagementScore += 8.0;
    } else {
      debtManagementScore += 0.0;
    }
    final monthlyInterestBurden = totalAssets > 0
        ? (creditAnalysis.monthlyInterest / totalAssets) * 100
        : creditAnalysis.monthlyInterest > 0
        ? 100.0
        : 0.0;

    if (monthlyInterestBurden == 0) {
      debtManagementScore += 20.0;
    } else if (monthlyInterestBurden <= 1.0) {
      debtManagementScore += 15.0;
    } else if (monthlyInterestBurden <= 3.0) {
      debtManagementScore += 10.0;
    } else if (monthlyInterestBurden <= 5.0) {
      debtManagementScore += 5.0;
    } else {
      debtManagementScore += 0.0;
    }
    debtManagementScore = debtManagementScore > 100 ? 100 : debtManagementScore;

    double savingsScore = 0.0;
    if (netWorth > 0) {
      final netWorthRatio = totalAssets > 0 ? netWorth / totalAssets : 0.0;

      if (netWorthRatio >= 0.8) {
        savingsScore += 40.0;
      } else if (netWorthRatio >= 0.6) {
        savingsScore += 35.0;
      } else if (netWorthRatio >= 0.4) {
        savingsScore += 25.0;
      } else if (netWorthRatio >= 0.2) {
        savingsScore += 15.0;
      } else {
        savingsScore += 5.0;
      }
    }
    if (netWorthTrend.length >= 2) {
      final oldestNetWorth = netWorthTrend.first.netWorth;
      final newestNetWorth = netWorthTrend.last.netWorth;

      if (oldestNetWorth != 0) {
        final growthRate =
            ((newestNetWorth - oldestNetWorth) / oldestNetWorth.abs()) * 100;

        if (growthRate >= 20.0) {
          savingsScore += 60.0;
        } else if (growthRate >= 10.0) {
          savingsScore += 50.0;
        } else if (growthRate >= 5.0) {
          savingsScore += 40.0;
        } else if (growthRate >= 0) {
          savingsScore += 25.0;
        } else if (growthRate >= -5.0) {
          savingsScore += 10.0;
        } else {
          savingsScore += 0.0;
        }
      } else if (newestNetWorth > 0) {
        savingsScore += 50.0;
      }
    } else if (netWorth > 0) {
      savingsScore += 30.0;
    }
    savingsScore = savingsScore > 100 ? 100 : savingsScore;

    double investmentScore = 0.0;
    final investmentRatio = totalAssets > 0
        ? (investments / totalAssets) * 100
        : 0.0;

    if (investmentRatio >= 10.0 && investmentRatio <= 30.0) {
      investmentScore = 100.0;
    } else if (investmentRatio >= 5.0 && investmentRatio < 10.0) {
      investmentScore = 70.0;
    } else if (investmentRatio > 30.0 && investmentRatio <= 50.0) {
      investmentScore = 80.0;
    } else if (investmentRatio > 50.0) {
      investmentScore = 60.0;
    } else if (investmentRatio > 0) {
      investmentScore = 40.0;
    } else {
      investmentScore = 0.0;
    }

    final overallScore =
        (liquidityScore * 0.30 +
        debtManagementScore * 0.35 +
        savingsScore * 0.25 +
        investmentScore * 0.10);

    final recommendations = <String>[];
    if (liquidityScore < 50) {
      if (liquidityRatio < 1.0) {
        recommendations.add(
          'Likidite oranınızı artırın. Acil durum fonu oluşturmaya öncelik verin.',
        );
      }
      recommendations.add(
        'En az 3-6 aylık harcamanızı karşılayacak acil durum fonu oluşturun.',
      );
    } else if (liquidityScore < 75) {
      recommendations.add('Acil durum fonunuzu 6 aya çıkarmayı hedefleyin.');
    }
    if (debtManagementScore < 50) {
      if (debtToAssetRatio > 0.6) {
        recommendations.add(
          'Borç seviyeniz yüksek. Borç ödeme planı oluşturun ve harcamalarınızı azaltın.',
        );
      }
      if (avgUtilization > 70) {
        recommendations.add(
          'Kredi kullanım oranınız çok yüksek (%${avgUtilization.toStringAsFixed(0)}). %30\'un altına indirmeyi hedefleyin.',
        );
      }
      if (creditAnalysis.monthlyInterest > 0) {
        recommendations.add(
          'Aylık ${creditAnalysis.monthlyInterest.toStringAsFixed(2)} TL faiz ödüyorsunuz. Yüksek faizli borçları öncelikle ödeyin.',
        );
      }
    } else if (debtManagementScore < 75) {
      if (avgUtilization > 30) {
        recommendations.add(
          'Kredi kullanım oranınızı %30\'un altına indirmeye çalışın.',
        );
      }
    }
    if (savingsScore < 50) {
      if (netWorth <= 0) {
        recommendations.add(
          'Net varlığınız negatif. Gelir artırma ve harcama azaltma stratejileri geliştirin.',
        );
      }
      recommendations.add(
        'Düzenli tasarruf alışkanlığı edinin. Gelirin en az %10-20\'sini tasarruf edin.',
      );
    } else if (savingsScore < 75) {
      recommendations.add('Tasarruf oranınızı artırmaya devam edin.');
    }
    if (investmentScore < 50) {
      if (investments == 0) {
        recommendations.add(
          'Yatırım yapmayı düşünün. Uzun vadeli finansal hedefleriniz için yatırım portföyü oluşturun.',
        );
      } else {
        recommendations.add(
          'Yatırım miktarınızı artırın. Varlıklarınızın %10-30\'unu yatırıma ayırmayı hedefleyin.',
        );
      }
    } else if (investmentScore < 75) {
      if (investmentRatio > 50) {
        recommendations.add(
          'Yatırım oranınız yüksek. Risk dengesini gözden geçirin.',
        );
      }
    }
    if (overallScore >= 80) {
      recommendations.add(
        'Finansal sağlığınız mükemmel! Mevcut stratejinizi sürdürün.',
      );
    } else if (overallScore >= 60) {
      recommendations.add(
        'Finansal sağlığınız iyi durumda. Küçük iyileştirmelerle daha da güçlendirebilirsiniz.',
      );
    } else if (overallScore >= 40) {
      recommendations.add(
        'Finansal sağlığınızı iyileştirmek için yukarıdaki önerilere öncelik verin.',
      );
    } else {
      recommendations.add(
        'Finansal sağlığınız dikkat gerektiriyor. Acil eylem planı oluşturun.',
      );
    }

    return FinancialHealthScore(
      liquidityScore: liquidityScore,
      debtManagementScore: debtManagementScore,
      savingsScore: savingsScore,
      investmentScore: investmentScore,
      overallScore: overallScore,
      recommendations: recommendations,
    );
  }
  Future<ComparisonData> comparePeriods({
    required DateTime period1Start,
    required DateTime period1End,
    required DateTime period2Start,
    required DateTime period2End,
    String? period1Label,
    String? period2Label,
    String? walletId,
    String? category,
  }) async {
    try {
      if (period1End.isBefore(period1Start)) {
        throw Exception(ErrorCodes.INVALID_DATE);
      }
      if (period2End.isBefore(period2Start)) {
        throw Exception(ErrorCodes.INVALID_DATE);
      }
      final cacheKey = CacheKeys.comparison(
        period1Start: period1Start,
        period1End: period1End,
        period2Start: period2Start,
        period2End: period2End,
      );
      final cached = _cache.get<ComparisonData>(cacheKey);
      if (cached != null) {
        return cached;
      }
      final defaultPeriod1Label =
          period1Label ?? _generatePeriodLabel(period1Start, period1End);
      final defaultPeriod2Label =
          period2Label ?? _generatePeriodLabel(period2Start, period2End);

      final period1CashFlow = await calculateCashFlow(
        startDate: period1Start,
        endDate: period1End,
        walletId: walletId,
        category: category,
        includePreviousPeriod: false,
      );

      final period2CashFlow = await calculateCashFlow(
        startDate: period2Start,
        endDate: period2End,
        walletId: walletId,
        category: category,
        includePreviousPeriod: false,
      );

      final incomeComparison = _createComparisonMetric(
        label: 'Gelir',
        period1Value: period1CashFlow.totalIncome,
        period2Value: period2CashFlow.totalIncome,
      );

      final expenseComparison = _createComparisonMetric(
        label: 'Gider',
        period1Value: period1CashFlow.totalExpense,
        period2Value: period2CashFlow.totalExpense,
      );

      final netCashFlowComparison = _createComparisonMetric(
        label: 'Net Nakit Akışı',
        period1Value: period1CashFlow.netCashFlow,
        period2Value: period2CashFlow.netCashFlow,
      );

      ComparisonMetric? savingsRateComparison;
      if (period1CashFlow.totalIncome > 0 && period2CashFlow.totalIncome > 0) {
        final period1SavingsRate =
            (period1CashFlow.netCashFlow / period1CashFlow.totalIncome) * 100;
        final period2SavingsRate =
            (period2CashFlow.netCashFlow / period2CashFlow.totalIncome) * 100;

        savingsRateComparison = _createComparisonMetric(
          label: 'Tasarruf Oranı',
          period1Value: period1SavingsRate,
          period2Value: period2SavingsRate,
        );
      }

      final period1Spending = await analyzeSpending(
        startDate: period1Start,
        endDate: period1End,
        categories: category != null ? [category] : null,
      );

      final period2Spending = await analyzeSpending(
        startDate: period2Start,
        endDate: period2End,
        categories: category != null ? [category] : null,
      );

      final categoryComparisons = _calculateCategoryComparisons(
        period1Breakdown: period1Spending.categoryBreakdown,
        period2Breakdown: period2Spending.categoryBreakdown,
      );

      final overallTrend = netCashFlowComparison.trend;

      final insights = _generateComparisonInsights(
        income: incomeComparison,
        expense: expenseComparison,
        netCashFlow: netCashFlowComparison,
        savingsRate: savingsRateComparison,
        categoryComparisons: categoryComparisons,
        period1Label: defaultPeriod1Label,
        period2Label: defaultPeriod2Label,
      );

      final result = ComparisonData(
        period1Start: period1Start,
        period1End: period1End,
        period2Start: period2Start,
        period2End: period2End,
        period1Label: defaultPeriod1Label,
        period2Label: defaultPeriod2Label,
        income: incomeComparison,
        expense: expenseComparison,
        netCashFlow: netCashFlowComparison,
        savingsRate: savingsRateComparison,
        categoryComparisons: categoryComparisons,
        overallTrend: overallTrend,
        insights: insights,
      );
      _cache.set(cacheKey, result, duration: _cacheDuration);

      return result;
    } catch (e) {
      if (e.toString().contains(ErrorCodes.INVALID_DATE)) {
        rethrow;
      }
      throw Exception('${ErrorCodes.CALCULATION_ERROR}: ${e.toString()}');
    }
  }
  ComparisonMetric _createComparisonMetric({
    required String label,
    required double period1Value,
    required double period2Value,
  }) {
    final absoluteChange = period2Value - period1Value;
    double percentageChange = 0.0;

    if (period1Value != 0) {
      percentageChange = (absoluteChange / period1Value.abs()) * 100;
    } else if (period2Value != 0) {
      percentageChange = period2Value > 0 ? 100.0 : -100.0;
    }
    TrendDirection trend;
    final threshold = period1Value.abs() * 0.05;

    if (absoluteChange > threshold) {
      trend = TrendDirection.up;
    } else if (absoluteChange < -threshold) {
      trend = TrendDirection.down;
    } else {
      trend = TrendDirection.stable;
    }

    return ComparisonMetric(
      label: label,
      period1Value: period1Value,
      period2Value: period2Value,
      absoluteChange: absoluteChange,
      percentageChange: percentageChange,
      trend: trend,
    );
  }
  List<CategoryComparison> _calculateCategoryComparisons({
    required Map<String, double> period1Breakdown,
    required Map<String, double> period2Breakdown,
  }) {
    final comparisons = <CategoryComparison>[];
    final allCategories = <String>{
      ...period1Breakdown.keys,
      ...period2Breakdown.keys,
    };

    for (var category in allCategories) {
      final period1Amount = period1Breakdown[category] ?? 0.0;
      final period2Amount = period2Breakdown[category] ?? 0.0;
      final absoluteChange = period2Amount - period1Amount;
      double percentageChange = 0.0;
      if (period1Amount != 0) {
        percentageChange = (absoluteChange / period1Amount) * 100;
      } else if (period2Amount != 0) {
        percentageChange = 100.0;
      }
      TrendDirection trend;
      final threshold = period1Amount * 0.05;

      if (absoluteChange > threshold) {
        trend = TrendDirection.up;
      } else if (absoluteChange < -threshold) {
        trend = TrendDirection.down;
      } else {
        trend = TrendDirection.stable;
      }

      comparisons.add(
        CategoryComparison(
          category: category,
          period1Amount: period1Amount,
          period2Amount: period2Amount,
          absoluteChange: absoluteChange,
          percentageChange: percentageChange,
          trend: trend,
        ),
      );
    }
    comparisons.sort(
      (a, b) => b.absoluteChange.abs().compareTo(a.absoluteChange.abs()),
    );

    return comparisons;
  }
  String _generatePeriodLabel(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
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
      return '${monthNames[start.month - 1]} ${start.year}';
    }
    if (start.month == 1 &&
        start.day == 1 &&
        end.month == 12 &&
        end.day == 31 &&
        start.year == end.year) {
      return '${start.year}';
    }
    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }
  List<String> _generateComparisonInsights({
    required ComparisonMetric income,
    required ComparisonMetric expense,
    required ComparisonMetric netCashFlow,
    ComparisonMetric? savingsRate,
    required List<CategoryComparison> categoryComparisons,
    required String period1Label,
    required String period2Label,
  }) {
    final insights = <String>[];
    if (income.trend == TrendDirection.up) {
      insights.add(
        'Geliriniz $period1Label dönemine göre %${income.percentageChange.abs().toStringAsFixed(1)} arttı.',
      );
    } else if (income.trend == TrendDirection.down) {
      insights.add(
        'Geliriniz $period1Label dönemine göre %${income.percentageChange.abs().toStringAsFixed(1)} azaldı.',
      );
    }
    if (expense.trend == TrendDirection.up) {
      insights.add(
        'Giderleriniz $period1Label dönemine göre %${expense.percentageChange.abs().toStringAsFixed(1)} arttı.',
      );
    } else if (expense.trend == TrendDirection.down) {
      insights.add(
        'Giderleriniz $period1Label dönemine göre %${expense.percentageChange.abs().toStringAsFixed(1)} azaldı. Harika iş!',
      );
    }
    if (netCashFlow.trend == TrendDirection.up) {
      insights.add('Net nakit akışınız olumlu yönde gelişiyor.');
    } else if (netCashFlow.trend == TrendDirection.down) {
      insights.add(
        'Net nakit akışınız olumsuz yönde değişti. Harcamalarınızı gözden geçirin.',
      );
    }
    if (savingsRate != null) {
      if (savingsRate.trend == TrendDirection.up) {
        insights.add(
          'Tasarruf oranınız %${savingsRate.period1Value.toStringAsFixed(1)}\'den %${savingsRate.period2Value.toStringAsFixed(1)}\'e yükseldi.',
        );
      } else if (savingsRate.trend == TrendDirection.down) {
        insights.add(
          'Tasarruf oranınız %${savingsRate.period1Value.toStringAsFixed(1)}\'den %${savingsRate.period2Value.toStringAsFixed(1)}\'e düştü.',
        );
      }
    }
    if (categoryComparisons.isNotEmpty) {
      final biggestIncrease = categoryComparisons
          .where((c) => c.absoluteChange > 0)
          .fold<CategoryComparison?>(
            null,
            (prev, curr) =>
                prev == null || curr.absoluteChange > prev.absoluteChange
                ? curr
                : prev,
          );

      if (biggestIncrease != null && biggestIncrease.absoluteChange > 0) {
        insights.add(
          'En çok artış "${biggestIncrease.category}" kategorisinde (%${biggestIncrease.percentageChange.toStringAsFixed(1)}).',
        );
      }
      final biggestDecrease = categoryComparisons
          .where((c) => c.absoluteChange < 0)
          .fold<CategoryComparison?>(
            null,
            (prev, curr) =>
                prev == null ||
                    curr.absoluteChange.abs() > prev.absoluteChange.abs()
                ? curr
                : prev,
          );

      if (biggestDecrease != null && biggestDecrease.absoluteChange < 0) {
        insights.add(
          'En çok azalış "${biggestDecrease.category}" kategorisinde (%${biggestDecrease.percentageChange.abs().toStringAsFixed(1)}).',
        );
      }
    }
    if (netCashFlow.period2Value > 0 &&
        netCashFlow.trend == TrendDirection.up) {
      insights.add('Finansal durumunuz güçleniyor. Bu trendi sürdürün!');
    } else if (netCashFlow.period2Value < 0) {
      insights.add(
        'Giderleriniz gelirinizi aşıyor. Bütçe planlaması yapmanızı öneririz.',
      );
    }

    return insights;
  }
  Future<AverageComparisonData> compareWithAverages({
    required DateTime currentPeriodStart,
    required DateTime currentPeriodEnd,
    String? walletId,
    String? category,
  }) async {
    try {
      if (currentPeriodEnd.isBefore(currentPeriodStart)) {
        throw Exception(ErrorCodes.INVALID_DATE);
      }
      final periodDuration = currentPeriodEnd.difference(currentPeriodStart);
      final months = (periodDuration.inDays / 30).round();
      final cacheKey = CacheKeys.averageComparison(
        currentStart: currentPeriodStart,
        currentEnd: currentPeriodEnd,
        months: months,
      );
      final cached = _cache.get<AverageComparisonData>(cacheKey);
      if (cached != null) {
        return cached;
      }

      final currentPeriod = await calculateCashFlow(
        startDate: currentPeriodStart,
        endDate: currentPeriodEnd,
        walletId: walletId,
        category: category,
        includePreviousPeriod: false,
      );

      final threeMonthAverage = await _calculatePeriodAverage(
        endDate: currentPeriodStart.subtract(const Duration(days: 1)),
        monthsBack: 3,
        walletId: walletId,
        category: category,
      );

      final sixMonthAverage = await _calculatePeriodAverage(
        endDate: currentPeriodStart.subtract(const Duration(days: 1)),
        monthsBack: 6,
        walletId: walletId,
        category: category,
      );

      final twelveMonthAverage = await _calculatePeriodAverage(
        endDate: currentPeriodStart.subtract(const Duration(days: 1)),
        monthsBack: 12,
        walletId: walletId,
        category: category,
      );
      final threeMonthComparison = AverageBenchmark(
        periodLabel: '3 Aylık Ortalama',
        averageIncome: threeMonthAverage.averageIncome,
        averageExpense: threeMonthAverage.averageExpense,
        averageNetFlow: threeMonthAverage.averageNetFlow,
        currentIncome: currentPeriod.totalIncome,
        currentExpense: currentPeriod.totalExpense,
        currentNetFlow: currentPeriod.netCashFlow,
        incomeDeviation: _calculateDeviation(
          currentPeriod.totalIncome,
          threeMonthAverage.averageIncome,
        ),
        expenseDeviation: _calculateDeviation(
          currentPeriod.totalExpense,
          threeMonthAverage.averageExpense,
        ),
        netFlowDeviation: _calculateDeviation(
          currentPeriod.netCashFlow,
          threeMonthAverage.averageNetFlow,
        ),
        performanceRating: _calculatePerformanceRating(
          currentNetFlow: currentPeriod.netCashFlow,
          averageNetFlow: threeMonthAverage.averageNetFlow,
        ),
      );
      final sixMonthComparison = AverageBenchmark(
        periodLabel: '6 Aylık Ortalama',
        averageIncome: sixMonthAverage.averageIncome,
        averageExpense: sixMonthAverage.averageExpense,
        averageNetFlow: sixMonthAverage.averageNetFlow,
        currentIncome: currentPeriod.totalIncome,
        currentExpense: currentPeriod.totalExpense,
        currentNetFlow: currentPeriod.netCashFlow,
        incomeDeviation: _calculateDeviation(
          currentPeriod.totalIncome,
          sixMonthAverage.averageIncome,
        ),
        expenseDeviation: _calculateDeviation(
          currentPeriod.totalExpense,
          sixMonthAverage.averageExpense,
        ),
        netFlowDeviation: _calculateDeviation(
          currentPeriod.netCashFlow,
          sixMonthAverage.averageNetFlow,
        ),
        performanceRating: _calculatePerformanceRating(
          currentNetFlow: currentPeriod.netCashFlow,
          averageNetFlow: sixMonthAverage.averageNetFlow,
        ),
      );
      final twelveMonthComparison = AverageBenchmark(
        periodLabel: '12 Aylık Ortalama',
        averageIncome: twelveMonthAverage.averageIncome,
        averageExpense: twelveMonthAverage.averageExpense,
        averageNetFlow: twelveMonthAverage.averageNetFlow,
        currentIncome: currentPeriod.totalIncome,
        currentExpense: currentPeriod.totalExpense,
        currentNetFlow: currentPeriod.netCashFlow,
        incomeDeviation: _calculateDeviation(
          currentPeriod.totalIncome,
          twelveMonthAverage.averageIncome,
        ),
        expenseDeviation: _calculateDeviation(
          currentPeriod.totalExpense,
          twelveMonthAverage.averageExpense,
        ),
        netFlowDeviation: _calculateDeviation(
          currentPeriod.netCashFlow,
          twelveMonthAverage.averageNetFlow,
        ),
        performanceRating: _calculatePerformanceRating(
          currentNetFlow: currentPeriod.netCashFlow,
          averageNetFlow: twelveMonthAverage.averageNetFlow,
        ),
      );

      final insights = _generateAverageComparisonInsights(
        threeMonth: threeMonthComparison,
        sixMonth: sixMonthComparison,
        twelveMonth: twelveMonthComparison,
      );

      final result = AverageComparisonData(
        currentPeriodStart: currentPeriodStart,
        currentPeriodEnd: currentPeriodEnd,
        currentIncome: currentPeriod.totalIncome,
        currentExpense: currentPeriod.totalExpense,
        currentNetFlow: currentPeriod.netCashFlow,
        threeMonthBenchmark: threeMonthComparison,
        sixMonthBenchmark: sixMonthComparison,
        twelveMonthBenchmark: twelveMonthComparison,
        insights: insights,
      );
      _cache.set(cacheKey, result, duration: _cacheDuration);

      return result;
    } catch (e) {
      if (e.toString().contains(ErrorCodes.INVALID_DATE)) {
        rethrow;
      }
      throw Exception('${ErrorCodes.CALCULATION_ERROR}: ${e.toString()}');
    }
  }
  Future<PeriodAverage> _calculatePeriodAverage({
    required DateTime endDate,
    required int monthsBack,
    String? walletId,
    String? category,
  }) async {
    double totalIncome = 0;
    double totalExpense = 0;
    int validMonths = 0;
    for (int i = 1; i <= monthsBack; i++) {
      final monthEnd = DateTime(
        endDate.year,
        endDate.month - i + 1,
        0,
        23,
        59,
        59,
      );
      final monthStart = DateTime(endDate.year, endDate.month - i, 1);
      if (monthStart.isAfter(DateTime.now())) {
        continue;
      }

      try {
        final monthData = await calculateCashFlow(
          startDate: monthStart,
          endDate: monthEnd,
          walletId: walletId,
          category: category,
          includePreviousPeriod: false,
        );

        totalIncome += monthData.totalIncome;
        totalExpense += monthData.totalExpense;
        validMonths++;
      } catch (e) {
        continue;
      }
    }
    final averageIncome = validMonths > 0 ? totalIncome / validMonths : 0.0;
    final averageExpense = validMonths > 0 ? totalExpense / validMonths : 0.0;
    final averageNetFlow = averageIncome - averageExpense;

    return PeriodAverage(
      averageIncome: averageIncome,
      averageExpense: averageExpense,
      averageNetFlow: averageNetFlow,
      monthsIncluded: validMonths,
    );
  }
  Future<GoalComparisonSummary> compareGoals() async {
    try {
      final cacheCheckTime = DateTime.now();
      final cacheKey = CacheKeys.goalComparison(
        startDate: DateTime(cacheCheckTime.year, cacheCheckTime.month, 1),
        endDate: cacheCheckTime,
      );
      final cached = _cache.get<GoalComparisonSummary>(cacheKey);
      if (cached != null) {
        return cached;
      }
      final goals = await _dataService.getGoals();

      if (goals.isEmpty) {
        return GoalComparisonSummary(
          goals: [],
          totalGoals: 0,
          achievedGoals: 0,
          inProgressGoals: 0,
          overdueGoals: 0,
          overallAchievementRate: 0.0,
          totalTargetAmount: 0.0,
          totalActualAmount: 0.0,
          totalRemainingAmount: 0.0,
          insights: ['Henüz hedef belirlenmemiş'],
        );
      }

      final now = DateTime.now();
      final goalComparisons = <GoalComparison>[];

      int achievedCount = 0;
      int inProgressCount = 0;
      int overdueCount = 0;
      double totalTarget = 0.0;
      double totalActual = 0.0;
      for (final goal in goals) {
        final remaining = goal.targetAmount - goal.currentAmount;
        final achievementPercentage =
            (goal.currentAmount / goal.targetAmount * 100).clamp(0.0, 100.0);
        final isAchieved = goal.currentAmount >= goal.targetAmount;

        int? daysRemaining;
        bool? isOverdue;
        GoalStatus status;

        if (goal.deadline != null) {
          daysRemaining = goal.deadline!.difference(now).inDays;
          isOverdue = daysRemaining < 0;

          if (isAchieved) {
            status = GoalStatus.achieved;
          } else if (isOverdue) {
            status = GoalStatus.overdue;
          } else if (daysRemaining < 30 && achievementPercentage < 80) {
            status = GoalStatus.atRisk;
          } else if (achievementPercentage < 50 && daysRemaining < 90) {
            status = GoalStatus.behindSchedule;
          } else {
            status = GoalStatus.inProgress;
          }
        } else {
          if (isAchieved) {
            status = GoalStatus.achieved;
          } else {
            status = GoalStatus.inProgress;
          }
        }

        goalComparisons.add(
          GoalComparison(
            goalId: goal.id,
            goalName: goal.name,
            targetAmount: goal.targetAmount,
            actualAmount: goal.currentAmount,
            remainingAmount: remaining,
            achievementPercentage: achievementPercentage,
            isAchieved: isAchieved,
            deadline: goal.deadline,
            daysRemaining: daysRemaining,
            isOverdue: isOverdue,
            status: status,
          ),
        );
        totalTarget += goal.targetAmount;
        totalActual += goal.currentAmount;

        if (isAchieved) {
          achievedCount++;
        } else if (status == GoalStatus.overdue) {
          overdueCount++;
        } else {
          inProgressCount++;
        }
      }

      final totalRemaining = totalTarget - totalActual;
      final overallRate = totalTarget > 0
          ? (totalActual / totalTarget * 100).clamp(0.0, 100.0)
          : 0.0;
      final insights = _generateGoalInsights(
        goalComparisons: goalComparisons,
        achievedCount: achievedCount,
        overdueCount: overdueCount,
        overallRate: overallRate,
      );

      final result = GoalComparisonSummary(
        goals: goalComparisons,
        totalGoals: goals.length,
        achievedGoals: achievedCount,
        inProgressGoals: inProgressCount,
        overdueGoals: overdueCount,
        overallAchievementRate: overallRate,
        totalTargetAmount: totalTarget,
        totalActualAmount: totalActual,
        totalRemainingAmount: totalRemaining,
        insights: insights,
      );
      _cache.set(cacheKey, result, duration: _cacheDuration);

      return result;
    } catch (e) {
      throw Exception('Hedef karşılaştırması hesaplanamadı: $e');
    }
  }
  List<String> _generateGoalInsights({
    required List<GoalComparison> goalComparisons,
    required int achievedCount,
    required int overdueCount,
    required double overallRate,
  }) {
    final insights = <String>[];

    if (goalComparisons.isEmpty) {
      return ['Henüz hedef belirlenmemiş'];
    }
    if (overallRate >= 90) {
      insights.add(
        'Harika! Hedeflerinizin %${overallRate.toStringAsFixed(0)}\'ine ulaştınız.',
      );
    } else if (overallRate >= 70) {
      insights.add(
        'İyi gidiyorsunuz! Hedeflerinizin %${overallRate.toStringAsFixed(0)}\'ini tamamladınız.',
      );
    } else if (overallRate >= 50) {
      insights.add('Hedeflerinizin yarısını tamamladınız. Devam edin!');
    } else {
      insights.add('Hedeflerinize ulaşmak için daha fazla çaba gerekiyor.');
    }
    if (achievedCount > 0) {
      insights.add('$achievedCount hedef başarıyla tamamlandı! 🎉');
    }
    if (overdueCount > 0) {
      insights.add(
        '⚠️ $overdueCount hedefin süresi doldu. Gözden geçirmeniz önerilir.',
      );
    }
    final atRiskGoals = goalComparisons
        .where((g) => g.status == GoalStatus.atRisk)
        .length;
    if (atRiskGoals > 0) {
      insights.add(
        '$atRiskGoals hedef risk altında. Hızlı aksiyon gerekebilir.',
      );
    }
    final sortedByPerformance = List<GoalComparison>.from(goalComparisons)
      ..sort(
        (a, b) => b.achievementPercentage.compareTo(a.achievementPercentage),
      );

    if (sortedByPerformance.isNotEmpty &&
        sortedByPerformance.first.achievementPercentage > 0) {
      final best = sortedByPerformance.first;
      if (!best.isAchieved) {
        insights.add(
          'En iyi performans: ${best.goalName} (%${best.achievementPercentage.toStringAsFixed(0)})',
        );
      }
    }

    return insights;
  }
  double _calculateDeviation(double currentValue, double averageValue) {
    if (averageValue == 0) {
      if (currentValue == 0) {
        return 0.0;
      }
      return currentValue > 0 ? 100.0 : -100.0;
    }

    return ((currentValue - averageValue) / averageValue.abs()) * 100;
  }
  PerformanceRating _calculatePerformanceRating({
    required double currentNetFlow,
    required double averageNetFlow,
  }) {
    final deviation = _calculateDeviation(currentNetFlow, averageNetFlow);

    if (deviation > 20) {
      return PerformanceRating.excellent;
    } else if (deviation > 10) {
      return PerformanceRating.good;
    } else if (deviation >= -10) {
      return PerformanceRating.average;
    } else if (deviation >= -20) {
      return PerformanceRating.below;
    } else {
      return PerformanceRating.poor;
    }
  }
  List<String> _generateAverageComparisonInsights({
    required AverageBenchmark threeMonth,
    required AverageBenchmark sixMonth,
    required AverageBenchmark twelveMonth,
  }) {
    final insights = <String>[];
    if (threeMonth.performanceRating == PerformanceRating.excellent) {
      insights.add(
        'Mükemmel! Son 3 aylık ortalamanızın %${threeMonth.netFlowDeviation.abs().toStringAsFixed(1)} üzerinde performans gösteriyorsunuz.',
      );
    } else if (threeMonth.performanceRating == PerformanceRating.good) {
      insights.add(
        'İyi gidiyorsunuz! Son 3 aylık ortalamanızın üzerinde performans gösteriyorsunuz.',
      );
    } else if (threeMonth.performanceRating == PerformanceRating.below) {
      insights.add(
        'Son 3 aylık ortalamanızın altında performans gösteriyorsunuz. Harcamalarınızı gözden geçirin.',
      );
    } else if (threeMonth.performanceRating == PerformanceRating.poor) {
      insights.add(
        'Dikkat! Son 3 aylık ortalamanızın %${threeMonth.netFlowDeviation.abs().toStringAsFixed(1)} altında performans gösteriyorsunuz.',
      );
    }
    if (threeMonth.incomeDeviation > 10) {
      insights.add(
        'Geliriniz 3 aylık ortalamanızın %${threeMonth.incomeDeviation.toStringAsFixed(1)} üzerinde.',
      );
    } else if (threeMonth.incomeDeviation < -10) {
      insights.add(
        'Geliriniz 3 aylık ortalamanızın %${threeMonth.incomeDeviation.abs().toStringAsFixed(1)} altında.',
      );
    }
    if (threeMonth.expenseDeviation > 20) {
      insights.add(
        'Giderleriniz 3 aylık ortalamanızın %${threeMonth.expenseDeviation.toStringAsFixed(1)} üzerinde. Bütçenizi kontrol edin.',
      );
    } else if (threeMonth.expenseDeviation < -10) {
      insights.add(
        'Giderlerinizi 3 aylık ortalamanızın %${threeMonth.expenseDeviation.abs().toStringAsFixed(1)} altına çektiniz. Harika!',
      );
    }
    if (twelveMonth.performanceRating == PerformanceRating.excellent ||
        twelveMonth.performanceRating == PerformanceRating.good) {
      insights.add(
        'Uzun vadeli performansınız (12 ay) olumlu. Bu trendi sürdürün!',
      );
    } else if (twelveMonth.performanceRating == PerformanceRating.below ||
        twelveMonth.performanceRating == PerformanceRating.poor) {
      insights.add(
        'Uzun vadeli performansınız (12 ay) ortalamanın altında. Finansal planlamanızı gözden geçirmenizi öneririz.',
      );
    }
    final allGood =
        threeMonth.performanceRating == PerformanceRating.excellent ||
        threeMonth.performanceRating == PerformanceRating.good;
    final allBad =
        threeMonth.performanceRating == PerformanceRating.below ||
        threeMonth.performanceRating == PerformanceRating.poor;

    if (allGood && sixMonth.performanceRating == PerformanceRating.excellent) {
      insights.add(
        'Tutarlı bir şekilde ortalamanın üzerinde performans gösteriyorsunuz!',
      );
    } else if (allBad && sixMonth.performanceRating == PerformanceRating.poor) {
      insights.add(
        'Sürekli ortalamanın altında performans gösteriyorsunuz. Acil eylem gerekiyor.',
      );
    }

    return insights;
  }
  void clearCache() {
    _cache.clear();
  }
  void clearCacheEntry(String key) {
    _cache.remove(key);
  }
}
class PeriodAverage {
  final double averageIncome;
  final double averageExpense;
  final double averageNetFlow;
  final int monthsIncluded;

  PeriodAverage({
    required this.averageIncome,
    required this.averageExpense,
    required this.averageNetFlow,
    required this.monthsIncluded,
  });
}
class AverageComparisonData {
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final double currentIncome;
  final double currentExpense;
  final double currentNetFlow;
  final AverageBenchmark threeMonthBenchmark;
  final AverageBenchmark sixMonthBenchmark;
  final AverageBenchmark twelveMonthBenchmark;
  final List<String> insights;

  AverageComparisonData({
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.currentIncome,
    required this.currentExpense,
    required this.currentNetFlow,
    required this.threeMonthBenchmark,
    required this.sixMonthBenchmark,
    required this.twelveMonthBenchmark,
    required this.insights,
  });
}
class AverageBenchmark {
  final String periodLabel;
  final double averageIncome;
  final double averageExpense;
  final double averageNetFlow;
  final double currentIncome;
  final double currentExpense;
  final double currentNetFlow;
  final double incomeDeviation;
  final double expenseDeviation;
  final double netFlowDeviation;
  final PerformanceRating performanceRating;

  AverageBenchmark({
    required this.periodLabel,
    required this.averageIncome,
    required this.averageExpense,
    required this.averageNetFlow,
    required this.currentIncome,
    required this.currentExpense,
    required this.currentNetFlow,
    required this.incomeDeviation,
    required this.expenseDeviation,
    required this.netFlowDeviation,
    required this.performanceRating,
  });
}
enum PerformanceRating { excellent, good, average, below, poor }
