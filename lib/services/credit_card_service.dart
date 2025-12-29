import 'package:flutter/foundation.dart';
import '../models/credit_card.dart';
import '../models/credit_card_transaction.dart';
import '../models/credit_card_payment.dart';
import '../repositories/credit_card_repository.dart';
import '../repositories/credit_card_transaction_repository.dart';
import '../repositories/credit_card_statement_repository.dart';
import '../repositories/credit_card_payment_repository.dart';
import 'installment_tracker_service.dart';
import 'statement_generator_service.dart';
import 'reward_points_service.dart';
import 'limit_alert_service.dart';

class CreditCardService {
  final CreditCardRepository _cardRepo = CreditCardRepository();
  final CreditCardTransactionRepository _transactionRepo =
      CreditCardTransactionRepository();
  final CreditCardStatementRepository _statementRepo =
      CreditCardStatementRepository();
  final CreditCardPaymentRepository _paymentRepo =
      CreditCardPaymentRepository();
  Future<CreditCard> createCard(CreditCard card) async {
    final error = card.validate();
    if (error != null) {
      throw Exception(error);
    }

    await _cardRepo.save(card);
    return card;
  }
  Future<void> updateCard(CreditCard card) async {
    final error = card.validate();
    if (error != null) {
      throw Exception(error);
    }
    final exists = await _cardRepo.exists(card.id);
    if (!exists) {
      throw Exception('Kart bulunamadı');
    }

    await _cardRepo.update(card);
  }
  Future<void> deleteCard(String cardId) async {
    final exists = await _cardRepo.exists(cardId);
    if (!exists) {
      throw Exception('Kart bulunamadı');
    }
    final debt = await getCurrentDebt(cardId);
    if (debt > 0.01) {
      throw Exception('Borcu olan kart silinemez. Önce borcu kapatın.');
    }

    await _cardRepo.delete(cardId);
  }
  Future<CreditCard?> getCard(String cardId) async {
    return await _cardRepo.findById(cardId);
  }
  Future<List<CreditCard>> getAllCards() async {
    return await _cardRepo.findAll();
  }
  Future<List<CreditCard>> getActiveCards() async {
    return await _cardRepo.findActive();
  }
  Future<CreditCardTransaction> addTransaction(
    CreditCardTransaction transaction,
  ) async {
    final error = transaction.validate();
    if (error != null) {
      throw Exception(error);
    }
    final card = await _cardRepo.findById(transaction.cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }
    final currentDebt = await getCurrentDebt(transaction.cardId);
    final availableCredit = card.creditLimit - currentDebt;

    if (transaction.amount > availableCredit) {
      throw Exception(
        'Kredi limiti aşıldı! Kullanılabilir limit: ₺${availableCredit.toStringAsFixed(2)}',
      );
    }
    await _transactionRepo.save(transaction);
    try {
      final rewardPointsService = RewardPointsService();
      final points = await rewardPointsService.calculatePointsForTransaction(
        transaction.cardId,
        transaction.amount,
      );
      
      if (points > 0 && !transaction.isCashAdvance) {
        await rewardPointsService.addPoints(
          transaction.cardId,
          points,
          'Harcama: ${transaction.description}',
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    try {
      final limitAlertService = LimitAlertService();
      await limitAlertService.checkAndTriggerAlerts(transaction.cardId);
    } catch (e) {
      debugPrint('Error: $e');
    }

    return transaction;
  }
  Future<void> updateTransaction(CreditCardTransaction transaction) async {
    final error = transaction.validate();
    if (error != null) {
      throw Exception(error);
    }
    final exists = await _transactionRepo.findById(transaction.id);
    if (exists == null) {
      throw Exception('İşlem bulunamadı');
    }

    await _transactionRepo.update(transaction);
  }
  Future<void> deleteTransaction(String transactionId) async {
    final transaction = await _transactionRepo.findById(transactionId);
    if (transaction == null) {
      throw Exception('İşlem bulunamadı');
    }
    if (transaction.installmentsPaid > 0) {
      throw Exception('Taksitleri ödenmiş işlem silinemez');
    }

    await _transactionRepo.delete(transactionId);
  }
  Future<List<CreditCardTransaction>> getCardTransactions(String cardId) async {
    return await _transactionRepo.findByCardId(cardId);
  }
  Future<List<CreditCardTransaction>> getActiveInstallments(
    String cardId,
  ) async {
    return await _transactionRepo.findActiveInstallments(cardId);
  }
  Future<Map<String, dynamic>> recordPayment(CreditCardPayment payment) async {
    final error = payment.validate();
    if (error != null) {
      throw Exception(error);
    }
    final card = await _cardRepo.findById(payment.cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }
    final statement = await _statementRepo.findById(payment.statementId);
    if (statement == null) {
      throw Exception('Ekstre bulunamadı');
    }
    await _paymentRepo.save(payment);
    final statementGenerator = StatementGeneratorService();
    final overpayment = await statementGenerator.applyPaymentToStatement(
      payment.statementId,
      payment.amount,
    );
    try {
      final limitAlertService = LimitAlertService();
      await limitAlertService.resetAlertsAfterPayment(payment.cardId);
    } catch (e) {
      debugPrint('Error: $e');
    }

    return {
      'payment': payment,
      'overpayment': overpayment,
      'hasOverpayment': overpayment > 0,
    };
  }
  Future<List<CreditCardPayment>> getCardPayments(String cardId) async {
    return await _paymentRepo.findByCardId(cardId);
  }
  Future<double> getCurrentDebt(String cardId) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      return 0;
    }
    final statements = await _statementRepo.findByCardId(cardId);
    final unpaidStatements = statements.where((s) => !s.isPaidFully);
    double statementDebt = unpaidStatements.fold<double>(
      0,
      (sum, s) => sum + s.remainingDebt,
    );
    final allTransactions = await _transactionRepo.findByCardId(cardId);
    DateTime? latestStatementDate;
    if (statements.isNotEmpty) {
      statements.sort((a, b) => b.periodEnd.compareTo(a.periodEnd));
      latestStatementDate = statements.first.periodEnd;
    }
    double pendingTransactionDebt = 0;
    for (var transaction in allTransactions) {
      if (latestStatementDate == null ||
          transaction.transactionDate.isAfter(latestStatementDate)) {
        if (transaction.installmentCount > 1) {
          pendingTransactionDebt += transaction.remainingAmount;
        } else {
          pendingTransactionDebt += transaction.amount;
        }
      }
    }
    double initialDebtAmount = 0;
    if (statements.isEmpty) {
      initialDebtAmount = card.initialDebt;
    }

    return statementDebt + pendingTransactionDebt + initialDebtAmount;
  }
  Future<double> getAvailableCredit(String cardId) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    final currentDebt = await getCurrentDebt(cardId);
    return card.creditLimit - currentDebt;
  }
  Future<Map<String, double>> getAllCardsDebtSummary() async {
    final cards = await _cardRepo.findActive();
    final summary = <String, double>{};

    for (var card in cards) {
      final debt = await getCurrentDebt(card.id);
      summary[card.id] = debt;
    }

    return summary;
  }
  Future<double> getTotalDebtAllCards() async {
    final summary = await getAllCardsDebtSummary();
    return summary.values.fold<double>(0, (sum, debt) => sum + debt);
  }
  Future<double> getTotalDueThisMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final cards = await _cardRepo.findActive();
    double totalDue = 0;

    for (var card in cards) {
      final statements = await _statementRepo.findByCardId(card.id);
      final thisMonthStatements = statements.where(
        (s) =>
            s.dueDate.isAfter(
              startOfMonth.subtract(const Duration(seconds: 1)),
            ) &&
            s.dueDate.isBefore(endOfMonth.add(const Duration(days: 1))) &&
            !s.isPaidFully,
      );

      totalDue += thisMonthStatements.fold<double>(
        0,
        (sum, s) => sum + s.remainingDebt,
      );
    }

    return totalDue;
  }
  Future<double> getTotalOverdueDebt() async {
    return await _statementRepo.getTotalOverdueDebt();
  }
  Future<DateTime> getNextStatementDate(String cardId) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    final now = DateTime.now();
    var nextDate = DateTime(now.year, now.month, card.statementDay);
    if (card.statementDay > 28) {
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
      if (card.statementDay > lastDayOfMonth) {
        nextDate = DateTime(now.year, now.month, lastDayOfMonth);
      }
    }
    if (nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now)) {
      nextDate = DateTime(now.year, now.month + 1, card.statementDay);
      if (card.statementDay > 28) {
        final lastDayOfNextMonth = DateTime(now.year, now.month + 2, 0).day;
        if (card.statementDay > lastDayOfNextMonth) {
          nextDate = DateTime(now.year, now.month + 1, lastDayOfNextMonth);
        }
      }
    }

    return nextDate;
  }
  Future<DateTime> getNextDueDate(String cardId) async {
    final nextStatementDate = await getNextStatementDate(cardId);
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    return nextStatementDate.add(Duration(days: card.dueDateOffset));
  }
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
  Future<double> getTotalAvailableCredit() async {
    final cards = await _cardRepo.findActive();
    double totalAvailable = 0;

    for (var card in cards) {
      final available = await getAvailableCredit(card.id);
      totalAvailable += available;
    }

    return totalAvailable;
  }
  Future<Map<DateTime, double>> getFuturePaymentProjection(int months) async {
    final cards = await _cardRepo.findActive();
    final projection = <DateTime, double>{};
    final now = DateTime.now();
    for (int i = 0; i < months; i++) {
      final month = DateTime(now.year, now.month + i, 1);
      projection[month] = 0;
    }
    final installmentTracker = InstallmentTrackerService();
    final installmentProjection = await installmentTracker
        .getAllCardsFutureProjection(months);

    for (var entry in installmentProjection.entries) {
      projection[entry.key] = (projection[entry.key] ?? 0) + entry.value;
    }
    for (var card in cards) {
      final currentDebt = await getCurrentDebt(card.id);
      if (currentDebt > 0) {
        final minimumPayment = currentDebt * 0.33;
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        if (projection.containsKey(nextMonth)) {
          projection[nextMonth] = (projection[nextMonth] ?? 0) + minimumPayment;
        }
      }
    }

    return projection;
  }
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
  Future<void> clearAllData() async {
    await _cardRepo.clear();
    await _transactionRepo.clear();
    await _paymentRepo.clear();
    await _statementRepo.clear();
  }
}
