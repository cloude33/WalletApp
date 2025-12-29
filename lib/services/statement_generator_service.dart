import 'package:uuid/uuid.dart';
import '../models/credit_card.dart';
import '../models/credit_card_statement.dart';
import '../repositories/credit_card_repository.dart';
import '../repositories/credit_card_statement_repository.dart';
import '../repositories/credit_card_transaction_repository.dart';
import 'interest_calculator_service.dart';

class StatementGeneratorService {
  final CreditCardRepository _cardRepo = CreditCardRepository();
  final CreditCardStatementRepository _statementRepo =
      CreditCardStatementRepository();
  final CreditCardTransactionRepository _transactionRepo =
      CreditCardTransactionRepository();
  final InterestCalculatorService _interestCalc = InterestCalculatorService();
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
  Future<CreditCardStatement?> _checkAndGenerateForCard(CreditCard card) async {
    final now = DateTime.now();
    var statementDate = DateTime(now.year, now.month, card.statementDay);
    if (card.statementDay > 28) {
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
      if (card.statementDay > lastDayOfMonth) {
        statementDate = DateTime(now.year, now.month, lastDayOfMonth);
      }
    }
    if (now.isBefore(statementDate)) {
      return null;
    }
    final existingStatement = await _statementRepo.findByPeriodEnd(
      card.id,
      statementDate,
    );

    if (existingStatement != null) {
      return null;
    }
    return await generateStatement(card);
  }
  Future<CreditCardStatement> generateStatement(CreditCard card) async {
    final now = DateTime.now();
    var periodEnd = DateTime(now.year, now.month, card.statementDay);
    if (card.statementDay > 28) {
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
      if (card.statementDay > lastDayOfMonth) {
        periodEnd = DateTime(now.year, now.month, lastDayOfMonth);
      }
    }
    final previousStatement = await _statementRepo.findPreviousStatement(
      card.id,
    );
    final periodStart = previousStatement != null
        ? previousStatement.periodEnd.add(const Duration(days: 1))
        : DateTime(now.year, now.month - 1, card.statementDay);
    final dueDate = periodEnd.add(Duration(days: card.dueDateOffset));
    final newPurchases = await calculateNewPurchases(
      card.id,
      periodStart,
      periodEnd,
    );
    final installmentPayments = await calculateInstallmentPayments(
      card.id,
      periodStart,
      periodEnd,
    );
    double previousBalance = 0;
    double interestCharged = 0;

    if (previousStatement != null && previousStatement.remainingDebt > 0) {
      previousBalance = previousStatement.remainingDebt;
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
    double totalDebt =
        previousBalance + interestCharged + newPurchases + installmentPayments;
    final availableCredit = await getAvailableCredit(card.id);
    if (availableCredit > 0) {
      totalDebt = totalDebt - availableCredit;
      if (totalDebt < 0) totalDebt = 0;
    }
    final minimumPayment = calculateMinimumPayment(totalDebt, 0.33);
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
    final error = statement.validate();
    if (error != null) {
      throw Exception('Statement validation failed: $error');
    }
    await _statementRepo.save(statement);
    await updateInstallmentCounters(card.id, periodEnd);

    return statement;
  }
  Future<double> calculateNewPurchases(
    String cardId,
    DateTime start,
    DateTime end,
  ) async {
    final transactions = await _transactionRepo.findByDateRange(
      cardId,
      start,
      end,
    );
    final cashPurchases = transactions
        .where((t) => t.installmentCount == 1)
        .fold<double>(0, (sum, t) => sum + t.amount);

    return cashPurchases;
  }
  Future<double> calculateInstallmentPayments(
    String cardId,
    DateTime start,
    DateTime end,
  ) async {
    final allTransactions = await _transactionRepo.findByCardId(cardId);
    final installmentTransactions = allTransactions.where(
      (t) =>
          t.installmentCount > 1 &&
          !t.isCompleted &&
          t.transactionDate.isBefore(end.add(const Duration(days: 1))),
    );

    double totalInstallmentPayments = 0;

    for (var transaction in installmentTransactions) {
      totalInstallmentPayments += transaction.installmentAmount;
    }

    return totalInstallmentPayments;
  }
  double calculateMinimumPayment(double totalDebt, double minimumRate) {
    if (totalDebt <= 0) {
      return 0;
    }
    final minimum = totalDebt * minimumRate;
    const minimumFloor = 50.0;

    return minimum < minimumFloor ? minimumFloor : minimum;
  }
  Future<void> updateInstallmentCounters(
    String cardId,
    DateTime statementDate,
  ) async {
    final allTransactions = await _transactionRepo.findByCardId(cardId);
    final installmentTransactions = allTransactions.where(
      (t) =>
          t.installmentCount > 1 &&
          !t.isCompleted &&
          t.transactionDate.isBefore(
            statementDate.add(const Duration(days: 1)),
          ),
    );

    for (var transaction in installmentTransactions) {
      final updatedTransaction = transaction.copyWith(
        installmentsPaid: transaction.installmentsPaid + 1,
      );

      await _transactionRepo.update(updatedTransaction);
    }
  }
  Future<List<CreditCardStatement>> getCardStatements(String cardId) async {
    return await _statementRepo.findByCardId(cardId);
  }
  Future<CreditCardStatement?> getCurrentStatement(String cardId) async {
    return await _statementRepo.findCurrentStatement(cardId);
  }
  Future<CreditCardStatement?> getPreviousStatement(String cardId) async {
    return await _statementRepo.findPreviousStatement(cardId);
  }
  Future<double> getAvailableCredit(String cardId) async {
    final statements = await _statementRepo.findByCardId(cardId);
    double totalCredit = 0;
    for (var statement in statements) {
      if (statement.paidAmount > statement.totalDebt) {
        totalCredit += (statement.paidAmount - statement.totalDebt);
      }
    }

    return totalCredit;
  }
  Future<double> applyPaymentToStatement(
    String statementId,
    double amount,
  ) async {
    final statement = await _statementRepo.findById(statementId);
    if (statement == null) {
      throw Exception('Ekstre bulunamadı');
    }

    if (amount <= 0) {
      throw Exception('Ödeme tutarı sıfırdan büyük olmalı');
    }
    final newPaidAmount = statement.paidAmount + amount;
    final newRemainingDebt = statement.totalDebt - newPaidAmount;
    final overpayment = newRemainingDebt < 0 ? -newRemainingDebt : 0.0;
    final updatedStatement = statement.copyWith(
      paidAmount: newPaidAmount,
      remainingDebt: newRemainingDebt > 0 ? newRemainingDebt : 0,
      paymentDate: DateTime.now(),
    );

    await _statementRepo.update(updatedStatement);
    await updateStatementStatus(updatedStatement.id);

    return overpayment;
  }
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
  Future<void> processInstallmentsForStatement(
    String cardId,
    DateTime statementDate,
  ) async {
    await updateInstallmentCounters(cardId, statementDate);
  }
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

    final totalPaid = statements.fold<double>(
      0,
      (sum, s) => sum + s.paidAmount,
    );
    final totalInterest = statements.fold<double>(
      0,
      (sum, s) => sum + s.interestCharged,
    );

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
  Future<List<Map<String, dynamic>>> getStatementPaymentHistory(
    String statementId,
  ) async {
    return [];
  }
  Future<Map<String, dynamic>> calculateNextStatementPreview(
    String cardId,
  ) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    final now = DateTime.now();
    var nextStatementDate = DateTime(
      now.year,
      now.month + 1,
      card.statementDay,
    );
    if (card.statementDay > 28) {
      final lastDayOfMonth = DateTime(now.year, now.month + 2, 0).day;
      if (card.statementDay > lastDayOfMonth) {
        nextStatementDate = DateTime(now.year, now.month + 1, lastDayOfMonth);
      }
    }
    final currentStatement = await getCurrentStatement(cardId);
    final periodStart = currentStatement != null
        ? currentStatement.periodEnd.add(const Duration(days: 1))
        : DateTime(now.year, now.month, card.statementDay);
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

    final projectedTotalDebt =
        projectedPreviousBalance +
        projectedInterest +
        projectedNewPurchases +
        projectedInstallments;

    final projectedMinimumPayment = calculateMinimumPayment(
      projectedTotalDebt,
      0.33,
    );

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
