import 'package:uuid/uuid.dart';
import '../models/credit_card.dart';
import '../models/credit_card_statement.dart';
import '../models/credit_card_transaction.dart';
import '../repositories/credit_card_repository.dart';
import '../repositories/credit_card_statement_repository.dart';
import '../repositories/credit_card_transaction_repository.dart';
import 'interest_calculator_service.dart';

class StatementGeneratorService {
  final CreditCardRepository _cardRepo = CreditCardRepository();
  final CreditCardStatementRepository _statementRepo = CreditCardStatementRepository();
  final CreditCardTransactionRepository _transactionRepo = CreditCardTransactionRepository();
  final InterestCalculatorService _interestCalc = InterestCalculatorService();

  // ==================== STATEMENT GENERATION ====================

  /// Check all cards and generate statements if needed
  Future<List<CreditCardStatement>> checkAndGenerateStatements() async {
    final cards = await _cardRepo.findActive();
    final generatedStatements = <CreditCardStatement>[];

    for (var card in cards) {
      final statement = await _checkAndGenerateForCard(card);
      if (statement != null) {
        generatedStatements.add(statement);
      }
    }

    return generatedStatements;
  }

  /// Check if a card needs statement generation and generate if needed
  Future<CreditCardStatement?> _checkAndGenerateForCard(CreditCard card) async {
    final now = DateTime.now();
    
    // Calculate this month's statement date
    var statementDate = DateTime(now.year, now.month, card.statementDay);
    
    // Handle months with fewer days
    if (card.statementDay > 28) {
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
      if (card.statementDay > lastDayOfMonth) {
        statementDate = DateTime(now.year, now.month, lastDayOfMonth);
      }
    }

    // Check if statement date has passed
    if (now.isBefore(statementDate)) {
      return null; // Not time yet
    }

    // Check if statement already exists for this period
    final existingStatement = await _statementRepo.findByPeriodEnd(
      card.id,
      statementDate,
    );
    
    if (existingStatement != null) {
      return null; // Already generated
    }

    // Generate new statement
    return await generateStatement(card);
  }

  /// Generate a statement for a card
  Future<CreditCardStatement> generateStatement(CreditCard card) async {
    final now = DateTime.now();
    
    // Calculate statement period
    var periodEnd = DateTime(now.year, now.month, card.statementDay);
    
    // Handle months with fewer days
    if (card.statementDay > 28) {
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
      if (card.statementDay > lastDayOfMonth) {
        periodEnd = DateTime(now.year, now.month, lastDayOfMonth);
      }
    }

    // Get previous statement to determine period start
    final previousStatement = await _statementRepo.findPreviousStatement(card.id);
    final periodStart = previousStatement != null
        ? previousStatement.periodEnd.add(const Duration(days: 1))
        : DateTime(now.year, now.month - 1, card.statementDay);

    // Calculate due date
    final dueDate = periodEnd.add(Duration(days: card.dueDateOffset));

    // Calculate new purchases and installment payments
    final newPurchases = await calculateNewPurchases(card.id, periodStart, periodEnd);
    final installmentPayments = await calculateInstallmentPayments(card.id, periodStart, periodEnd);

    // Get previous balance and calculate interest
    double previousBalance = 0;
    double interestCharged = 0;

    if (previousStatement != null && previousStatement.remainingDebt > 0) {
      previousBalance = previousStatement.remainingDebt;
      
      // Calculate interest on carry-over debt
      final isOverdue = previousStatement.isOverdue;
      final daysOverdue = previousStatement.daysOverdue;
      
      interestCharged = _interestCalc.calculateCarryOverInterest(
        previousBalance: previousBalance,
        monthlyRate: card.monthlyInterestRate,
        isOverdue: isOverdue,
        daysOverdue: daysOverdue,
        lateRate: card.lateInterestRate,
      );
    }

    // Calculate total debt before applying credit
    double totalDebt = previousBalance + interestCharged + newPurchases + installmentPayments;
    
    // Apply available credit from overpayments
    final availableCredit = await getAvailableCredit(card.id);
    if (availableCredit > 0) {
      totalDebt = totalDebt - availableCredit;
      if (totalDebt < 0) totalDebt = 0;
    }

    // Calculate minimum payment (typically 30-40% in Turkey)
    final minimumPayment = calculateMinimumPayment(totalDebt, 0.33);

    // Create statement
    final statement = CreditCardStatement(
      id: const Uuid().v4(),
      cardId: card.id,
      periodStart: periodStart,
      periodEnd: periodEnd,
      dueDate: dueDate,
      previousBalance: previousBalance,
      interestCharged: interestCharged,
      newPurchases: newPurchases,
      installmentPayments: installmentPayments,
      totalDebt: totalDebt,
      minimumPayment: minimumPayment,
      paidAmount: 0,
      remainingDebt: totalDebt,
      status: 'pending',
      createdAt: now,
    );

    // Validate
    final error = statement.validate();
    if (error != null) {
      throw Exception('Statement validation failed: $error');
    }

    // Save statement
    await _statementRepo.save(statement);

    // Update installment counters
    await updateInstallmentCounters(card.id, periodEnd);

    return statement;
  }

  /// Calculate new purchases for a statement period
  Future<double> calculateNewPurchases(
    String cardId,
    DateTime start,
    DateTime end,
  ) async {
    final transactions = await _transactionRepo.findByDateRange(cardId, start, end);
    
    // Sum all cash purchases (installmentCount == 1)
    final cashPurchases = transactions
        .where((t) => t.installmentCount == 1)
        .fold<double>(0, (sum, t) => sum + t.amount);

    return cashPurchases;
  }

  /// Calculate installment payments for a statement period
  Future<double> calculateInstallmentPayments(
    String cardId,
    DateTime start,
    DateTime end,
  ) async {
    // Get all installment transactions (not just in this period)
    final allTransactions = await _transactionRepo.findByCardId(cardId);
    
    // Filter for installment transactions that have payments due in this period
    final installmentTransactions = allTransactions.where((t) =>
      t.installmentCount > 1 &&
      !t.isCompleted &&
      t.transactionDate.isBefore(end.add(const Duration(days: 1)))
    );

    double totalInstallmentPayments = 0;

    for (var transaction in installmentTransactions) {
      // Each statement period, one installment is due
      totalInstallmentPayments += transaction.installmentAmount;
    }

    return totalInstallmentPayments;
  }

  /// Calculate minimum payment
  double calculateMinimumPayment(double totalDebt, double minimumRate) {
    if (totalDebt <= 0) {
      return 0;
    }
    
    // Minimum payment is typically 30-40% of total debt in Turkey
    final minimum = totalDebt * minimumRate;
    
    // Some banks have a minimum floor (e.g., 50 TL)
    const minimumFloor = 50.0;
    
    return minimum < minimumFloor ? minimumFloor : minimum;
  }

  /// Update installment counters after statement generation
  Future<void> updateInstallmentCounters(String cardId, DateTime statementDate) async {
    final allTransactions = await _transactionRepo.findByCardId(cardId);
    
    // Find installment transactions that need counter update
    final installmentTransactions = allTransactions.where((t) =>
      t.installmentCount > 1 &&
      !t.isCompleted &&
      t.transactionDate.isBefore(statementDate.add(const Duration(days: 1)))
    );

    for (var transaction in installmentTransactions) {
      // Increment the paid counter
      final updatedTransaction = transaction.copyWith(
        installmentsPaid: transaction.installmentsPaid + 1,
      );
      
      await _transactionRepo.update(updatedTransaction);
    }
  }

  // ==================== STATEMENT QUERIES ====================

  /// Get all statements for a card
  Future<List<CreditCardStatement>> getCardStatements(String cardId) async {
    return await _statementRepo.findByCardId(cardId);
  }

  /// Get current statement for a card
  Future<CreditCardStatement?> getCurrentStatement(String cardId) async {
    return await _statementRepo.findCurrentStatement(cardId);
  }

  /// Get previous statement for a card
  Future<CreditCardStatement?> getPreviousStatement(String cardId) async {
    return await _statementRepo.findPreviousStatement(cardId);
  }

  /// Get available credit from overpayments
  /// Returns the total overpayment amount that can be applied to next statement
  Future<double> getAvailableCredit(String cardId) async {
    final statements = await _statementRepo.findByCardId(cardId);
    
    // Sum all overpayments (where paidAmount > totalDebt)
    double totalCredit = 0;
    for (var statement in statements) {
      if (statement.paidAmount > statement.totalDebt) {
        totalCredit += (statement.paidAmount - statement.totalDebt);
      }
    }
    
    return totalCredit;
  }

  // ==================== PAYMENT PROCESSING ====================

  /// Apply payment to a statement
  /// Returns overpayment amount if payment exceeds total debt
  Future<double> applyPaymentToStatement(String statementId, double amount) async {
    final statement = await _statementRepo.findById(statementId);
    if (statement == null) {
      throw Exception('Ekstre bulunamadı');
    }

    if (amount <= 0) {
      throw Exception('Ödeme tutarı sıfırdan büyük olmalı');
    }

    // Calculate new paid amount and remaining debt
    final newPaidAmount = statement.paidAmount + amount;
    final newRemainingDebt = statement.totalDebt - newPaidAmount;
    
    // Calculate overpayment (if any)
    final overpayment = newRemainingDebt < 0 ? -newRemainingDebt : 0.0;

    // Update statement
    final updatedStatement = statement.copyWith(
      paidAmount: newPaidAmount,
      remainingDebt: newRemainingDebt > 0 ? newRemainingDebt : 0,
      paymentDate: DateTime.now(),
    );

    await _statementRepo.update(updatedStatement);
    
    // Update status after saving
    await updateStatementStatus(updatedStatement.id);
    
    return overpayment;
  }

  /// Update statement status based on payment
  Future<void> updateStatementStatus(String statementId) async {
    final statement = await _statementRepo.findById(statementId);
    if (statement == null) {
      throw Exception('Ekstre bulunamadı');
    }

    String newStatus;
    
    if (statement.isPaidFully) {
      newStatus = 'paid';
    } else if (statement.isOverdue) {
      newStatus = 'overdue';
    } else if (statement.isPartiallyPaid) {
      newStatus = 'partial';
    } else {
      newStatus = 'pending';
    }

    if (newStatus != statement.status) {
      final updatedStatement = statement.copyWith(status: newStatus);
      await _statementRepo.update(updatedStatement);
    }
  }

  /// Process installments for a statement period
  Future<void> processInstallmentsForStatement(
    String cardId,
    DateTime statementDate,
  ) async {
    await updateInstallmentCounters(cardId, statementDate);
  }

  // ==================== STATEMENT ANALYSIS ====================

  /// Get statement summary for a card
  Future<Map<String, dynamic>> getStatementSummary(String cardId) async {
    final statements = await _statementRepo.findByCardId(cardId);
    
    if (statements.isEmpty) {
      return {
        'totalStatements': 0,
        'paidStatements': 0,
        'unpaidStatements': 0,
        'overdueStatements': 0,
        'totalDebt': 0.0,
        'totalPaid': 0.0,
        'totalInterest': 0.0,
      };
    }

    final paidStatements = statements.where((s) => s.isPaidFully).length;
    final unpaidStatements = statements.where((s) => !s.isPaidFully).length;
    final overdueStatements = statements.where((s) => s.isOverdue).length;
    
    final totalDebt = statements
        .where((s) => !s.isPaidFully)
        .fold<double>(0, (sum, s) => sum + s.remainingDebt);
    
    final totalPaid = statements.fold<double>(0, (sum, s) => sum + s.paidAmount);
    final totalInterest = statements.fold<double>(0, (sum, s) => sum + s.interestCharged);

    return {
      'totalStatements': statements.length,
      'paidStatements': paidStatements,
      'unpaidStatements': unpaidStatements,
      'overdueStatements': overdueStatements,
      'totalDebt': totalDebt,
      'totalPaid': totalPaid,
      'totalInterest': totalInterest,
    };
  }

  /// Get payment history for a statement
  Future<List<Map<String, dynamic>>> getStatementPaymentHistory(
    String statementId,
  ) async {
    // This would integrate with payment repository
    // For now, return empty list
    return [];
  }

  /// Calculate next statement preview
  Future<Map<String, dynamic>> calculateNextStatementPreview(String cardId) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    final now = DateTime.now();
    
    // Calculate next statement date
    var nextStatementDate = DateTime(now.year, now.month + 1, card.statementDay);
    
    // Handle months with fewer days
    if (card.statementDay > 28) {
      final lastDayOfMonth = DateTime(now.year, now.month + 2, 0).day;
      if (card.statementDay > lastDayOfMonth) {
        nextStatementDate = DateTime(now.year, now.month + 1, lastDayOfMonth);
      }
    }

    // Get current statement
    final currentStatement = await getCurrentStatement(cardId);
    final periodStart = currentStatement != null
        ? currentStatement.periodEnd.add(const Duration(days: 1))
        : DateTime(now.year, now.month, card.statementDay);

    // Calculate projected values
    final projectedNewPurchases = await calculateNewPurchases(
      cardId,
      periodStart,
      nextStatementDate,
    );
    
    final projectedInstallments = await calculateInstallmentPayments(
      cardId,
      periodStart,
      nextStatementDate,
    );

    double projectedPreviousBalance = 0;
    double projectedInterest = 0;

    if (currentStatement != null && currentStatement.remainingDebt > 0) {
      projectedPreviousBalance = currentStatement.remainingDebt;
      projectedInterest = _interestCalc.calculateMonthlyInterest(
        projectedPreviousBalance,
        card.monthlyInterestRate,
      );
    }

    final projectedTotalDebt = projectedPreviousBalance +
        projectedInterest +
        projectedNewPurchases +
        projectedInstallments;

    final projectedMinimumPayment = calculateMinimumPayment(projectedTotalDebt, 0.33);

    return {
      'nextStatementDate': nextStatementDate,
      'periodStart': periodStart,
      'periodEnd': nextStatementDate,
      'previousBalance': projectedPreviousBalance,
      'projectedInterest': projectedInterest,
      'projectedNewPurchases': projectedNewPurchases,
      'projectedInstallments': projectedInstallments,
      'projectedTotalDebt': projectedTotalDebt,
      'projectedMinimumPayment': projectedMinimumPayment,
    };
  }
}
