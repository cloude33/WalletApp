library;

import '../models/report_data.dart';
import '../models/cash_flow_data.dart';
import '../repositories/credit_card_transaction_repository.dart';
import '../repositories/kmh_repository.dart';
import '../services/data_service.dart';
import '../services/credit_card_service.dart';
import '../exceptions/error_codes.dart';
import '../utils/cache_manager.dart';
class ReportService {
  final CreditCardTransactionRepository _transactionRepo = CreditCardTransactionRepository();
  final KmhRepository _kmhRepo = KmhRepository();
  final DataService _dataService = DataService();
  final CreditCardService _creditCardService = CreditCardService();
  final CacheManager _cache = CacheManager();
  static const Duration _cacheDuration = Duration(minutes: 10);
  static const List<String> _fixedExpenseCategories = [
    'Kira',
    'Elektrik',
    'Su',
    'Doğalgaz',
    'İnternet',
    'Telefon',
    'Sigorta',
    'Abonelik',
  ];
  Future<IncomeReport> generateIncomeReport({
    required DateTime startDate,
    required DateTime endDate,
    bool includePreviousPeriod = false,
  }) async {
    try {
      if (endDate.isBefore(startDate)) {
        throw Exception(ErrorCodes.INVALID_DATE);
      }
      final cacheKey = 'income_report_${startDate.millisecondsSinceEpoch}_${endDate.millisecondsSinceEpoch}_$includePreviousPeriod';
      final cached = _cache.get<IncomeReport>(cacheKey);
      if (cached != null) {
        return cached;
      }

      double totalIncome = 0;
      final incomeSourceMap = <String, double>{};
      final incomeSourceCount = <String, int>{};
      final monthlyIncomeData = <MonthlyData>[];
      final wallets = await _dataService.getWallets();
      DateTime currentMonth = DateTime(startDate.year, startDate.month, 1);
      final endMonth = DateTime(endDate.year, endDate.month, 1);

      while (currentMonth.isBefore(endMonth) || currentMonth.isAtSameMomentAs(endMonth)) {
        final monthStart = currentMonth;
        final monthEnd = DateTime(currentMonth.year, currentMonth.month + 1, 0, 23, 59, 59);

        double monthIncome = 0;
        for (var wallet in wallets) {
          if (wallet.isKmhAccount) {
            final kmhTransactions = await _kmhRepo.getTransactionsByDateRange(
              wallet.id,
              monthStart,
              monthEnd,
            );

            for (var transaction in kmhTransactions) {
              if (transaction.type.toString().contains('deposit')) {
                monthIncome += transaction.amount;
                totalIncome += transaction.amount;
                final source = transaction.description.isNotEmpty 
                    ? transaction.description 
                    : 'Diğer Gelir';
                incomeSourceMap[source] = (incomeSourceMap[source] ?? 0) + transaction.amount;
                incomeSourceCount[source] = (incomeSourceCount[source] ?? 0) + 1;
              }
            }
          }
        }

        monthlyIncomeData.add(MonthlyData(
          month: currentMonth,
          income: monthIncome,
          expense: 0,
          netFlow: monthIncome,
        ));

        currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
      }
      final incomeSources = <IncomeSource>[];
      incomeSourceMap.forEach((source, amount) {
        final percentage = totalIncome > 0 ? (amount / totalIncome) * 100 : 0.0;
        incomeSources.add(IncomeSource(
          source: source,
          amount: amount,
          percentage: percentage,
          transactionCount: incomeSourceCount[source] ?? 0,
        ));
      });
      incomeSources.sort((a, b) => b.amount.compareTo(a.amount));
      final incomeValues = monthlyIncomeData.map((m) => m.income).toList();
      final trend = _calculateTrendDirection(incomeValues);
      final averageMonthly = monthlyIncomeData.isNotEmpty 
          ? totalIncome / monthlyIncomeData.length 
          : 0.0;
      DateTime? highestIncomeMonth;
      double? highestIncomeAmount;
      if (monthlyIncomeData.isNotEmpty) {
        final highest = monthlyIncomeData.reduce(
          (a, b) => a.income > b.income ? a : b
        );
        highestIncomeMonth = highest.month;
        highestIncomeAmount = highest.income;
      }
      double? previousPeriodIncome;
      double? changePercentage;

      if (includePreviousPeriod) {
        final periodDuration = endDate.difference(startDate);
        final previousStartDate = startDate.subtract(periodDuration);
        final previousEndDate = startDate.subtract(const Duration(days: 1));
        final previousReport = await generateIncomeReport(
          startDate: previousStartDate,
          endDate: previousEndDate,
          includePreviousPeriod: false,
        );

        previousPeriodIncome = previousReport.totalIncome;
        if (previousPeriodIncome != 0) {
          changePercentage = ((totalIncome - previousPeriodIncome) / previousPeriodIncome.abs()) * 100;
        } else if (totalIncome != 0) {
          changePercentage = 100.0;
        } else {
          changePercentage = 0.0;
        }
      }

      final result = IncomeReport(
        title: 'Gelir Raporu',
        startDate: startDate,
        endDate: endDate,
        generatedAt: DateTime.now(),
        totalIncome: totalIncome,
        incomeSources: incomeSources,
        monthlyIncome: monthlyIncomeData,
        trend: trend,
        averageMonthly: averageMonthly,
        previousPeriodIncome: previousPeriodIncome,
        changePercentage: changePercentage,
        highestIncomeMonth: highestIncomeMonth,
        highestIncomeAmount: highestIncomeAmount,
      );
      _cache.set(cacheKey, result, duration: _cacheDuration);

      return result;
    } catch (e) {
      if (e.toString().contains(ErrorCodes.INVALID_DATE)) {
        rethrow;
      }
      throw Exception('${ErrorCodes.REPORT_GENERATION_ERROR}: ${e.toString()}');
    }
  }
  Future<ExpenseReport> generateExpenseReport({
    required DateTime startDate,
    required DateTime endDate,
    bool includePreviousPeriod = false,
  }) async {
    try {
      if (endDate.isBefore(startDate)) {
        throw Exception(ErrorCodes.INVALID_DATE);
      }
      final cacheKey = 'expense_report_${startDate.millisecondsSinceEpoch}_${endDate.millisecondsSinceEpoch}_$includePreviousPeriod';
      final cached = _cache.get<ExpenseReport>(cacheKey);
      if (cached != null) {
        return cached;
      }

      double totalExpense = 0;
      double totalFixedExpense = 0;
      double totalVariableExpense = 0;
      final categoryMap = <String, double>{};
      final categoryCount = <String, int>{};
      final monthlyExpenseData = <MonthlyData>[];
      final wallets = await _dataService.getWallets();
      DateTime currentMonth = DateTime(startDate.year, startDate.month, 1);
      final endMonth = DateTime(endDate.year, endDate.month, 1);

      while (currentMonth.isBefore(endMonth) || currentMonth.isAtSameMomentAs(endMonth)) {
        final monthStart = currentMonth;
        final monthEnd = DateTime(currentMonth.year, currentMonth.month + 1, 0, 23, 59, 59);

        double monthExpense = 0;
        final creditCards = await _creditCardService.getActiveCards();
        for (var card in creditCards) {
          final cardTransactions = await _transactionRepo.findByDateRange(
            card.id,
            monthStart,
            monthEnd,
          );

          for (var transaction in cardTransactions) {
            monthExpense += transaction.amount;
            totalExpense += transaction.amount;
            categoryMap[transaction.category] = 
                (categoryMap[transaction.category] ?? 0) + transaction.amount;
            categoryCount[transaction.category] = 
                (categoryCount[transaction.category] ?? 0) + 1;
            if (_fixedExpenseCategories.contains(transaction.category)) {
              totalFixedExpense += transaction.amount;
            } else {
              totalVariableExpense += transaction.amount;
            }
          }
        }
        for (var wallet in wallets) {
          if (wallet.isKmhAccount) {
            final kmhTransactions = await _kmhRepo.getTransactionsByDateRange(
              wallet.id,
              monthStart,
              monthEnd,
            );

            for (var transaction in kmhTransactions) {
              if (transaction.type.toString().contains('withdrawal')) {
                monthExpense += transaction.amount;
                totalExpense += transaction.amount;
                totalVariableExpense += transaction.amount;
              }
            }
          }
        }

        monthlyExpenseData.add(MonthlyData(
          month: currentMonth,
          income: 0,
          expense: monthExpense,
          netFlow: -monthExpense,
        ));

        currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
      }
      final expenseCategories = <ExpenseCategory>[];
      categoryMap.forEach((category, amount) {
        final percentage = totalExpense > 0 ? (amount / totalExpense) * 100 : 0.0;
        final isFixed = _fixedExpenseCategories.contains(category);
        expenseCategories.add(ExpenseCategory(
          category: category,
          amount: amount,
          percentage: percentage,
          transactionCount: categoryCount[category] ?? 0,
          isFixed: isFixed,
        ));
      });
      expenseCategories.sort((a, b) => b.amount.compareTo(a.amount));
      final expenseValues = monthlyExpenseData.map((m) => m.expense).toList();
      final trend = _calculateTrendDirection(expenseValues);
      final averageMonthly = monthlyExpenseData.isNotEmpty 
          ? totalExpense / monthlyExpenseData.length 
          : 0.0;
      double? previousPeriodExpense;
      double? changePercentage;

      if (includePreviousPeriod) {
        final periodDuration = endDate.difference(startDate);
        final previousStartDate = startDate.subtract(periodDuration);
        final previousEndDate = startDate.subtract(const Duration(days: 1));
        final previousReport = await generateExpenseReport(
          startDate: previousStartDate,
          endDate: previousEndDate,
          includePreviousPeriod: false,
        );

        previousPeriodExpense = previousReport.totalExpense;
        if (previousPeriodExpense != 0) {
          changePercentage = ((totalExpense - previousPeriodExpense) / previousPeriodExpense.abs()) * 100;
        } else if (totalExpense != 0) {
          changePercentage = 100.0;
        } else {
          changePercentage = 0.0;
        }
      }
      final optimizationSuggestions = _generateOptimizationSuggestions(
        expenseCategories: expenseCategories,
        totalExpense: totalExpense,
        averageMonthly: averageMonthly,
      );

      final result = ExpenseReport(
        title: 'Gider Raporu',
        startDate: startDate,
        endDate: endDate,
        generatedAt: DateTime.now(),
        totalExpense: totalExpense,
        expenseCategories: expenseCategories,
        monthlyExpense: monthlyExpenseData,
        trend: trend,
        averageMonthly: averageMonthly,
        totalFixedExpense: totalFixedExpense,
        totalVariableExpense: totalVariableExpense,
        previousPeriodExpense: previousPeriodExpense,
        changePercentage: changePercentage,
        optimizationSuggestions: optimizationSuggestions,
      );
      _cache.set(cacheKey, result, duration: _cacheDuration);

      return result;
    } catch (e) {
      if (e.toString().contains(ErrorCodes.INVALID_DATE)) {
        rethrow;
      }
      throw Exception('${ErrorCodes.REPORT_GENERATION_ERROR}: ${e.toString()}');
    }
  }
  Future<BillReport> generateBillReport({
    required DateTime startDate,
    required DateTime endDate,
    bool includeUpcoming = true,
  }) async {
    try {
      if (endDate.isBefore(startDate)) {
        throw Exception(ErrorCodes.INVALID_DATE);
      }
      final cacheKey = 'bill_report_${startDate.millisecondsSinceEpoch}_${endDate.millisecondsSinceEpoch}_$includeUpcoming';
      final cached = _cache.get<BillReport>(cacheKey);
      if (cached != null) {
        return cached;
      }

      double totalPaid = 0;
      int billCount = 0;
      int onTimeCount = 0;
      int lateCount = 0;
      final billPayments = <BillPaymentData>[];
      final categoryBreakdown = <String, double>{};
      final creditCards = await _creditCardService.getActiveCards();
      for (var card in creditCards) {
        final cardTransactions = await _transactionRepo.findByDateRange(
          card.id,
          startDate,
          endDate,
        );

        for (var transaction in cardTransactions) {
          if (_fixedExpenseCategories.contains(transaction.category)) {
            totalPaid += transaction.amount;
            billCount++;
            onTimeCount++;
            categoryBreakdown[transaction.category] = 
                (categoryBreakdown[transaction.category] ?? 0) + transaction.amount;
            
            billPayments.add(BillPaymentData(
              billName: transaction.description.isNotEmpty 
                  ? transaction.description 
                  : transaction.category,
              amount: transaction.amount,
              paymentDate: transaction.transactionDate,
              dueDate: transaction.transactionDate,
              onTime: true,
              category: transaction.category,
              paymentMethod: 'Kredi Kartı',
            ));
          }
        }
      }
      final onTimePercentage = billCount > 0 
          ? (onTimeCount / billCount) * 100 
          : 0.0;
      final averageBillAmount = billCount > 0 
          ? totalPaid / billCount 
          : 0.0;
      final upcomingBills = <BillPaymentData>[];
      if (includeUpcoming) {
      }

      final result = BillReport(
        title: 'Fatura Raporu',
        startDate: startDate,
        endDate: endDate,
        generatedAt: DateTime.now(),
        totalPaid: totalPaid,
        billCount: billCount,
        onTimeCount: onTimeCount,
        lateCount: lateCount,
        onTimePercentage: onTimePercentage,
        billPayments: billPayments,
        categoryBreakdown: categoryBreakdown,
        averageBillAmount: averageBillAmount,
        upcomingBills: upcomingBills,
      );
      _cache.set(cacheKey, result, duration: _cacheDuration);

      return result;
    } catch (e) {
      if (e.toString().contains(ErrorCodes.INVALID_DATE)) {
        rethrow;
      }
      throw Exception('${ErrorCodes.REPORT_GENERATION_ERROR}: ${e.toString()}');
    }
  }
  Future<CustomReport> generateCustomReport({
    required CustomReportFilters filters,
  }) async {
    try {
      if (filters.endDate.isBefore(filters.startDate)) {
        throw Exception(ErrorCodes.INVALID_DATE);
      }
      final cacheKey = 'custom_report_${filters.startDate.millisecondsSinceEpoch}_${filters.endDate.millisecondsSinceEpoch}_${filters.categories?.join('_') ?? 'all'}_${filters.walletIds?.join('_') ?? 'all'}';
      final cached = _cache.get<CustomReport>(cacheKey);
      if (cached != null) {
        return cached;
      }

      double totalIncome = 0;
      double totalExpense = 0;
      double totalBills = 0;
      int transactionCount = 0;
      final categoryBreakdown = <String, double>{};
      final walletBreakdown = <String, double>{};
      final monthlyData = <MonthlyData>[];
      final wallets = await _dataService.getWallets();
      final filteredWallets = filters.walletIds != null
          ? wallets.where((w) => filters.walletIds!.contains(w.id)).toList()
          : wallets;
      DateTime currentMonth = DateTime(filters.startDate.year, filters.startDate.month, 1);
      final endMonth = DateTime(filters.endDate.year, filters.endDate.month, 1);

      while (currentMonth.isBefore(endMonth) || currentMonth.isAtSameMomentAs(endMonth)) {
        final monthStart = currentMonth;
        final monthEnd = DateTime(currentMonth.year, currentMonth.month + 1, 0, 23, 59, 59);

        double monthIncome = 0;
        double monthExpense = 0;
        if (filters.includeExpenses || filters.includeBills) {
          final creditCards = await _creditCardService.getActiveCards();
          for (var card in creditCards) {
            if (filters.walletIds != null && !filters.walletIds!.contains(card.id)) {
              continue;
            }

            final cardTransactions = await _transactionRepo.findByDateRange(
              card.id,
              monthStart,
              monthEnd,
            );

            for (var transaction in cardTransactions) {
              if (filters.categories != null && 
                  !filters.categories!.contains(transaction.category)) {
                continue;
              }
              if (filters.minAmount != null && transaction.amount < filters.minAmount!) {
                continue;
              }
              if (filters.maxAmount != null && transaction.amount > filters.maxAmount!) {
                continue;
              }

              final isBill = _fixedExpenseCategories.contains(transaction.category);
              if ((filters.includeExpenses && !isBill) || 
                  (filters.includeBills && isBill)) {
                monthExpense += transaction.amount;
                totalExpense += transaction.amount;
                
                if (isBill) {
                  totalBills += transaction.amount;
                }
                
                transactionCount++;
                categoryBreakdown[transaction.category] = 
                    (categoryBreakdown[transaction.category] ?? 0) + transaction.amount;
                final walletName = '${card.bankName} ${card.cardName}';
                walletBreakdown[walletName] = 
                    (walletBreakdown[walletName] ?? 0) + transaction.amount;
              }
            }
          }
        }
        if (filters.includeIncome || filters.includeExpenses) {
          for (var wallet in filteredWallets) {
            if (wallet.isKmhAccount) {
              final kmhTransactions = await _kmhRepo.getTransactionsByDateRange(
                wallet.id,
                monthStart,
                monthEnd,
              );

              for (var transaction in kmhTransactions) {
                if (filters.minAmount != null && transaction.amount < filters.minAmount!) {
                  continue;
                }
                if (filters.maxAmount != null && transaction.amount > filters.maxAmount!) {
                  continue;
                }

                if (transaction.type.toString().contains('deposit') && filters.includeIncome) {
                  monthIncome += transaction.amount;
                  totalIncome += transaction.amount;
                  transactionCount++;
                  walletBreakdown[wallet.name] = 
                      (walletBreakdown[wallet.name] ?? 0) + transaction.amount;
                } else if (transaction.type.toString().contains('withdrawal') && filters.includeExpenses) {
                  monthExpense += transaction.amount;
                  totalExpense += transaction.amount;
                  transactionCount++;
                  walletBreakdown[wallet.name] = 
                      (walletBreakdown[wallet.name] ?? 0) + transaction.amount;
                }
              }
            }
          }
        }

        monthlyData.add(MonthlyData(
          month: currentMonth,
          income: monthIncome,
          expense: monthExpense,
          netFlow: monthIncome - monthExpense,
        ));

        currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
      }

      final netAmount = totalIncome - totalExpense;

      final result = CustomReport(
        title: 'Özel Rapor',
        startDate: filters.startDate,
        endDate: filters.endDate,
        generatedAt: DateTime.now(),
        filters: filters,
        totalIncome: filters.includeIncome ? totalIncome : null,
        totalExpense: filters.includeExpenses ? totalExpense : null,
        totalBills: filters.includeBills ? totalBills : null,
        netAmount: netAmount,
        transactionCount: transactionCount,
        categoryBreakdown: categoryBreakdown,
        walletBreakdown: walletBreakdown,
        monthlyData: monthlyData,
      );
      _cache.set(cacheKey, result, duration: _cacheDuration);

      return result;
    } catch (e) {
      if (e.toString().contains(ErrorCodes.INVALID_DATE)) {
        rethrow;
      }
      throw Exception('${ErrorCodes.REPORT_GENERATION_ERROR}: ${e.toString()}');
    }
  }
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
  List<OptimizationSuggestion> _generateOptimizationSuggestions({
    required List<ExpenseCategory> expenseCategories,
    required double totalExpense,
    required double averageMonthly,
  }) {
    final suggestions = <OptimizationSuggestion>[];
    final sortedCategories = List<ExpenseCategory>.from(expenseCategories)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    for (int i = 0; i < sortedCategories.length && i < 3; i++) {
      final category = sortedCategories[i];
      if (category.percentage > 20) {
        suggestions.add(OptimizationSuggestion(
          category: category.category,
          suggestion: '${category.category} kategorisinde harcamalarınız toplam harcamanızın %${category.percentage.toStringAsFixed(1)}\'ini oluşturuyor. Bu kategoride tasarruf fırsatları araştırabilirsiniz.',
          potentialSavings: category.amount * 0.1,
          priority: 5,
        ));
      }
    }
    final variableExpenses = expenseCategories.where((c) => !c.isFixed).toList();
    if (variableExpenses.isNotEmpty) {
      final totalVariable = variableExpenses.fold<double>(
        0, 
        (sum, c) => sum + c.amount
      );
      if (totalVariable > totalExpense * 0.5) {
        suggestions.add(OptimizationSuggestion(
          category: 'Değişken Giderler',
          suggestion: 'Değişken giderleriniz toplam harcamanızın %${(totalVariable / totalExpense * 100).toStringAsFixed(1)}\'ini oluşturuyor. Bütçe belirleme ve takip ile bu giderleri azaltabilirsiniz.',
          potentialSavings: totalVariable * 0.15,
          priority: 4,
        ));
      }
    }
    final fixedExpenses = expenseCategories.where((c) => c.isFixed).toList();
    if (fixedExpenses.isNotEmpty) {
      final totalFixed = fixedExpenses.fold<double>(
        0, 
        (sum, c) => sum + c.amount
      );
      suggestions.add(OptimizationSuggestion(
        category: 'Sabit Giderler',
        suggestion: 'Sabit giderlerinizi gözden geçirin. Abonelikler, sigorta ve fatura ödemelerinde daha uygun alternatifler bulabilirsiniz.',
        potentialSavings: totalFixed * 0.05,
        priority: 3,
      ));
    }
    suggestions.sort((a, b) => b.priority.compareTo(a.priority));

    return suggestions;
  }
  void clearCache() {
    _cache.clear();
  }
  void clearCacheEntry(String key) {
    _cache.remove(key);
  }
}
