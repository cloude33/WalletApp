import 'package:uuid/uuid.dart';
import '../models/credit_card.dart';
import '../models/credit_card_transaction.dart';
import '../models/credit_card_payment.dart';
import '../repositories/credit_card_repository.dart';
import '../repositories/credit_card_transaction_repository.dart';
import '../repositories/credit_card_statement_repository.dart';
import '../repositories/credit_card_payment_repository.dart';
import 'installment_tracker_service.dart';
import 'statement_generator_service.dart';

class CreditCardService {
  final CreditCardRepository _cardRepo = CreditCardRepository();
  final CreditCardTransactionRepository _transactionRepo = CreditCardTransactionRepository();
  final CreditCardStatementRepository _statementRepo = CreditCardStatementRepository();
  final CreditCardPaymentRepository _paymentRepo = CreditCardPaymentRepository();

  // ==================== CREDIT CARD OPERATIONS ====================

  /// Create a new credit card
  Future<CreditCard> createCard(CreditCard card) async {
    // Validate
    final error = card.validate();
    if (error != null) {
      throw Exception(error);
    }

    await _cardRepo.save(card);
    return card;
  }

  /// Update an existing credit card
  Future<void> updateCard(CreditCard card) async {
    // Validate
    final error = card.validate();
    if (error != null) {
      throw Exception(error);
    }

    // Check if exists
    final exists = await _cardRepo.exists(card.id);
    if (!exists) {
      throw Exception('Kart bulunamadı');
    }

    await _cardRepo.update(card);
  }

  /// Delete a credit card
  Future<void> deleteCard(String cardId) async {
    // Check if exists
    final exists = await _cardRepo.exists(cardId);
    if (!exists) {
      throw Exception('Kart bulunamadı');
    }

    // Check if card has outstanding debt
    final debt = await getCurrentDebt(cardId);
    if (debt > 0.01) {
      throw Exception('Borcu olan kart silinemez. Önce borcu kapatın.');
    }

    await _cardRepo.delete(cardId);
  }

  /// Get a credit card by ID
  Future<CreditCard?> getCard(String cardId) async {
    return await _cardRepo.findById(cardId);
  }

  /// Get all credit cards
  Future<List<CreditCard>> getAllCards() async {
    return await _cardRepo.findAll();
  }

  /// Get all active credit cards
  Future<List<CreditCard>> getActiveCards() async {
    return await _cardRepo.findActive();
  }

  // ==================== TRANSACTION OPERATIONS ====================

  /// Add a new transaction
  Future<CreditCardTransaction> addTransaction(CreditCardTransaction transaction) async {
    // Validate
    final error = transaction.validate();
    if (error != null) {
      throw Exception(error);
    }

    // Check if card exists
    final card = await _cardRepo.findById(transaction.cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    // Check credit limit
    final currentDebt = await getCurrentDebt(transaction.cardId);
    final availableCredit = card.creditLimit - currentDebt;
    
    if (transaction.amount > availableCredit) {
      throw Exception(
        'Kredi limiti aşıldı! Kullanılabilir limit: ₺${availableCredit.toStringAsFixed(2)}'
      );
    }

    await _transactionRepo.save(transaction);
    return transaction;
  }

  /// Update a transaction
  Future<void> updateTransaction(CreditCardTransaction transaction) async {
    // Validate
    final error = transaction.validate();
    if (error != null) {
      throw Exception(error);
    }

    // Check if exists
    final exists = await _transactionRepo.findById(transaction.id);
    if (exists == null) {
      throw Exception('İşlem bulunamadı');
    }

    await _transactionRepo.update(transaction);
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    // Check if exists
    final transaction = await _transactionRepo.findById(transactionId);
    if (transaction == null) {
      throw Exception('İşlem bulunamadı');
    }

    // Check if transaction is part of a statement
    // If installments are already paid, we shouldn't allow deletion
    if (transaction.installmentsPaid > 0) {
      throw Exception('Taksitleri ödenmiş işlem silinemez');
    }

    await _transactionRepo.delete(transactionId);
  }

  /// Get transactions for a card
  Future<List<CreditCardTransaction>> getCardTransactions(String cardId) async {
    return await _transactionRepo.findByCardId(cardId);
  }

  /// Get active installments for a card
  Future<List<CreditCardTransaction>> getActiveInstallments(String cardId) async {
    return await _transactionRepo.findActiveInstallments(cardId);
  }

  // ==================== PAYMENT OPERATIONS ====================

  /// Record a payment
  /// Returns a map with payment info and overpayment amount if applicable
  Future<Map<String, dynamic>> recordPayment(CreditCardPayment payment) async {
    // Validate
    final error = payment.validate();
    if (error != null) {
      throw Exception(error);
    }

    // Check if card exists
    final card = await _cardRepo.findById(payment.cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    // Check if statement exists
    final statement = await _statementRepo.findById(payment.statementId);
    if (statement == null) {
      throw Exception('Ekstre bulunamadı');
    }

    // Save payment
    await _paymentRepo.save(payment);
    
    // Apply payment to statement and get overpayment
    final statementGenerator = StatementGeneratorService();
    final overpayment = await statementGenerator.applyPaymentToStatement(
      payment.statementId,
      payment.amount,
    );
    
    return {
      'payment': payment,
      'overpayment': overpayment,
      'hasOverpayment': overpayment > 0,
    };
  }

  /// Get payments for a card
  Future<List<CreditCardPayment>> getCardPayments(String cardId) async {
    return await _paymentRepo.findByCardId(cardId);
  }

  // ==================== COMPUTED DATA ====================

  /// Get current debt for a card
  Future<double> getCurrentDebt(String cardId) async {
    // Get all unpaid statements
    final statements = await _statementRepo.findByCardId(cardId);
    final unpaidStatements = statements.where((s) => !s.isPaidFully);
    
    // Sum remaining debt from statements
    double statementDebt = unpaidStatements.fold<double>(0, (sum, s) => sum + s.remainingDebt);
    
    // Get all transactions that haven't been included in any statement yet
    final allTransactions = await _transactionRepo.findByCardId(cardId);
    
    // Get the latest statement date, or use card creation date if no statements
    DateTime? latestStatementDate;
    if (statements.isNotEmpty) {
      statements.sort((a, b) => b.periodEnd.compareTo(a.periodEnd));
      latestStatementDate = statements.first.periodEnd;
    }
    
    // Calculate debt from transactions not yet in any statement
    double pendingTransactionDebt = 0;
    for (var transaction in allTransactions) {
      // If transaction is after latest statement (or no statement exists), include it
      if (latestStatementDate == null || transaction.transactionDate.isAfter(latestStatementDate)) {
        // For installment transactions, only count remaining installments
        if (transaction.installmentCount > 1) {
          pendingTransactionDebt += transaction.remainingAmount;
        } else {
          // For single payment transactions, count full amount
          pendingTransactionDebt += transaction.amount;
        }
      }
    }
    
    return statementDebt + pendingTransactionDebt;
  }

  /// Get available credit for a card
  Future<double> getAvailableCredit(String cardId) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    final currentDebt = await getCurrentDebt(cardId);
    return card.creditLimit - currentDebt;
  }

  /// Get debt summary for all cards
  Future<Map<String, double>> getAllCardsDebtSummary() async {
    final cards = await _cardRepo.findActive();
    final summary = <String, double>{};

    for (var card in cards) {
      final debt = await getCurrentDebt(card.id);
      summary[card.id] = debt;
    }

    return summary;
  }

  /// Get total debt across all cards
  Future<double> getTotalDebtAllCards() async {
    final summary = await getAllCardsDebtSummary();
    return summary.values.fold<double>(0, (sum, debt) => sum + debt);
  }

  /// Get total amount due this month across all cards
  Future<double> getTotalDueThisMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final cards = await _cardRepo.findActive();
    double totalDue = 0;

    for (var card in cards) {
      final statements = await _statementRepo.findByCardId(card.id);
      
      // Find statements with due date in this month
      final thisMonthStatements = statements.where((s) =>
        s.dueDate.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
        s.dueDate.isBefore(endOfMonth.add(const Duration(days: 1))) &&
        !s.isPaidFully
      );

      totalDue += thisMonthStatements.fold<double>(0, (sum, s) => sum + s.remainingDebt);
    }

    return totalDue;
  }

  /// Get total overdue debt across all cards
  Future<double> getTotalOverdueDebt() async {
    return await _statementRepo.getTotalOverdueDebt();
  }

  /// Get next statement date for a card
  Future<DateTime> getNextStatementDate(String cardId) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    final now = DateTime.now();
    var nextDate = DateTime(now.year, now.month, card.statementDay);

    // Handle months with fewer days
    if (card.statementDay > 28) {
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
      if (card.statementDay > lastDayOfMonth) {
        nextDate = DateTime(now.year, now.month, lastDayOfMonth);
      }
    }

    // If date has passed, move to next month
    if (nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now)) {
      nextDate = DateTime(now.year, now.month + 1, card.statementDay);
      
      // Handle edge case for next month too
      if (card.statementDay > 28) {
        final lastDayOfNextMonth = DateTime(now.year, now.month + 2, 0).day;
        if (card.statementDay > lastDayOfNextMonth) {
          nextDate = DateTime(now.year, now.month + 1, lastDayOfNextMonth);
        }
      }
    }

    return nextDate;
  }

  /// Get next due date for a card
  Future<DateTime> getNextDueDate(String cardId) async {
    final nextStatementDate = await getNextStatementDate(cardId);
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    return nextStatementDate.add(Duration(days: card.dueDateOffset));
  }

  /// Get credit utilization percentage for a card
  Future<double> getCreditUtilization(String cardId) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    if (card.creditLimit <= 0) {
      return 0;
    }

    final currentDebt = await getCurrentDebt(cardId);
    return (currentDebt / card.creditLimit) * 100;
  }

  /// Get total available credit across all cards
  Future<double> getTotalAvailableCredit() async {
    final cards = await _cardRepo.findActive();
    double totalAvailable = 0;

    for (var card in cards) {
      final available = await getAvailableCredit(card.id);
      totalAvailable += available;
    }

    return totalAvailable;
  }

  /// Get future payment projection for 3 months
  Future<Map<DateTime, double>> getFuturePaymentProjection(int months) async {
    final cards = await _cardRepo.findActive();
    final projection = <DateTime, double>{};
    final now = DateTime.now();

    // Initialize projection map
    for (int i = 0; i < months; i++) {
      final month = DateTime(now.year, now.month + i, 1);
      projection[month] = 0;
    }

    // Add installment projections
    final installmentTracker = InstallmentTrackerService();
    final installmentProjection = await installmentTracker.getAllCardsFutureProjection(months);
    
    for (var entry in installmentProjection.entries) {
      projection[entry.key] = (projection[entry.key] ?? 0) + entry.value;
    }

    // Add statement payments (estimated based on current debt)
    for (var card in cards) {
      final currentDebt = await getCurrentDebt(card.id);
      if (currentDebt > 0) {
        // Assume minimum payment for projection
        final minimumPayment = currentDebt * 0.33;
        
        // Add to next month's projection
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        if (projection.containsKey(nextMonth)) {
          projection[nextMonth] = (projection[nextMonth] ?? 0) + minimumPayment;
        }
      }
    }

    return projection;
  }

  /// Get card with computed properties
  Future<Map<String, dynamic>> getCardWithDetails(String cardId) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    final currentDebt = await getCurrentDebt(cardId);
    final availableCredit = await getAvailableCredit(cardId);
    final utilization = await getCreditUtilization(cardId);
    final nextStatementDate = await getNextStatementDate(cardId);
    final nextDueDate = await getNextDueDate(cardId);
    final activeInstallments = await getActiveInstallments(cardId);

    return {
      'card': card,
      'currentDebt': currentDebt,
      'availableCredit': availableCredit,
      'utilization': utilization,
      'nextStatementDate': nextStatementDate,
      'nextDueDate': nextDueDate,
      'activeInstallmentCount': activeInstallments.length,
    };
  }
}
