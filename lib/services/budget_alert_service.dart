import 'data_service.dart';
import '../services/credit_card_service.dart';
import '../models/credit_card_transaction.dart';

class BudgetAlertService {
  final DataService _dataService = DataService();
  final CreditCardService _creditCardService = CreditCardService();

  /// Check all budgets and return warnings
  Future<List<BudgetWarning>> checkBudgets() async {
    final budgets = await _dataService.getBudgets();
    final transactions = await _dataService.getTransactions();
    final warnings = <BudgetWarning>[];

    // Load credit card transactions
    final cards = await _creditCardService.getAllCards();
    final List<CreditCardTransaction> allCCTransactions = [];
    for (var card in cards) {
      final ccTransactions = await _creditCardService.getCardTransactions(
        card.id,
      );
      allCCTransactions.addAll(ccTransactions);
    }

    for (final budget in budgets) {
      // Calculate total spending for this budget's category this month
      // Including both regular and credit card transactions
      final now = DateTime.now();

      // Regular transactions
      final regularMonthlySpending = transactions
          .where(
            (t) =>
                t.type == 'expense' &&
                t.category == budget.category &&
                t.date.month == now.month &&
                t.date.year == now.year,
          )
          .fold(0.0, (sum, t) => sum + t.amount);

      // Credit card transactions
      final creditCardMonthlySpending = allCCTransactions
          .where(
            (t) =>
                t.category == budget.category &&
                t.transactionDate.month == now.month &&
                t.transactionDate.year == now.year,
          )
          .fold(0.0, (sum, t) => sum + t.amount);

      final monthlySpending =
          regularMonthlySpending + creditCardMonthlySpending;
      final percentage = (monthlySpending / budget.amount) * 100;

      // Create warnings based on spending percentage
      if (percentage >= 100) {
        warnings.add(
          BudgetWarning(
            budgetId: budget.id,
            category: budget.category,
            budgetAmount: budget.amount,
            currentSpending: monthlySpending,
            percentage: percentage,
            severity: BudgetWarningSeverity.exceeded,
            message: '${budget.category} bütçesi aşıldı!',
          ),
        );
      } else if (percentage >= 90) {
        warnings.add(
          BudgetWarning(
            budgetId: budget.id,
            category: budget.category,
            budgetAmount: budget.amount,
            currentSpending: monthlySpending,
            percentage: percentage,
            severity: BudgetWarningSeverity.critical,
            message:
                '${budget.category} bütçesinin %${percentage.toStringAsFixed(0)}\'ine ulaştınız',
          ),
        );
      } else if (percentage >= 80) {
        warnings.add(
          BudgetWarning(
            budgetId: budget.id,
            category: budget.category,
            budgetAmount: budget.amount,
            currentSpending: monthlySpending,
            percentage: percentage,
            severity: BudgetWarningSeverity.warning,
            message:
                '${budget.category} bütçesinin %${percentage.toStringAsFixed(0)}\'ini kullandınız',
          ),
        );
      }
    }

    return warnings;
  }

  /// Check if a new transaction would exceed budget
  Future<BudgetWarning?> checkTransactionAgainstBudget(
    String category,
    double amount,
  ) async {
    final budgets = await _dataService.getBudgets();
    final budget = budgets.where((b) => b.category == category).firstOrNull;

    if (budget == null) return null;

    final transactions = await _dataService.getTransactions();
    final now = DateTime.now();

    // Load credit card transactions
    final cards = await _creditCardService.getAllCards();
    final List<CreditCardTransaction> allCCTransactions = [];
    for (var card in cards) {
      final ccTransactions = await _creditCardService.getCardTransactions(
        card.id,
      );
      allCCTransactions.addAll(ccTransactions);
    }

    // Regular transactions
    final regularMonthlySpending = transactions
        .where(
          (t) =>
              t.type == 'expense' &&
              t.category == category &&
              t.date.month == now.month &&
              t.date.year == now.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    // Credit card transactions
    final creditCardMonthlySpending = allCCTransactions
        .where(
          (t) =>
              t.category == category &&
              t.transactionDate.month == now.month &&
              t.transactionDate.year == now.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    final monthlySpending = regularMonthlySpending + creditCardMonthlySpending;
    final newTotal = monthlySpending + amount;
    final percentage = (newTotal / budget.amount) * 100;

    if (percentage >= 100) {
      return BudgetWarning(
        budgetId: budget.id,
        category: category,
        budgetAmount: budget.amount,
        currentSpending: newTotal,
        percentage: percentage,
        severity: BudgetWarningSeverity.exceeded,
        message: 'Bu işlem $category bütçesini aşacak!',
      );
    } else if (percentage >= 80) {
      return BudgetWarning(
        budgetId: budget.id,
        category: category,
        budgetAmount: budget.amount,
        currentSpending: newTotal,
        percentage: percentage,
        severity: BudgetWarningSeverity.warning,
        message:
            'Bu işlem sonrası $category bütçesinin %${percentage.toStringAsFixed(0)}\'ini kullanmış olacaksınız',
      );
    }

    return null;
  }
}

enum BudgetWarningSeverity {
  warning, // 80-89%
  critical, // 90-99%
  exceeded, // 100%+
}

class BudgetWarning {
  final String budgetId;
  final String category;
  final double budgetAmount;
  final double currentSpending;
  final double percentage;
  final BudgetWarningSeverity severity;
  final String message;

  BudgetWarning({
    required this.budgetId,
    required this.category,
    required this.budgetAmount,
    required this.currentSpending,
    required this.percentage,
    required this.severity,
    required this.message,
  });

  double get remaining => budgetAmount - currentSpending;
  bool get isExceeded => percentage >= 100;
  bool get isCritical => percentage >= 90;
  bool get isWarning => percentage >= 80;
}
