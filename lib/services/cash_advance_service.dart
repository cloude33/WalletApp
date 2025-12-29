import 'package:uuid/uuid.dart';
import '../models/credit_card_transaction.dart';
import '../repositories/credit_card_repository.dart';
import '../repositories/credit_card_transaction_repository.dart';
class CashAdvanceService {
  final CreditCardRepository _cardRepo = CreditCardRepository();
  final CreditCardTransactionRepository _transactionRepo = CreditCardTransactionRepository();
  final Uuid _uuid = const Uuid();
  Future<CreditCardTransaction> recordCashAdvance({
    required String cardId,
    required double amount,
    required String description,
    String category = 'Nakit Avans',
  }) async {
    if (cardId.trim().isEmpty) {
      throw Exception('Kart ID boş olamaz');
    }
    if (amount <= 0) {
      throw Exception('Tutar sıfırdan büyük olmalı');
    }
    if (description.trim().isEmpty) {
      throw Exception('Açıklama boş olamaz');
    }
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }
    if (card.cashAdvanceLimit != null && card.cashAdvanceLimit! > 0) {
      final currentCashAdvanceDebt = await getTotalCashAdvanceDebt(cardId);
      if (currentCashAdvanceDebt + amount > card.cashAdvanceLimit!) {
        throw Exception(
          'Nakit avans limiti aşıldı. Limit: ${card.cashAdvanceLimit}, '
          'Mevcut borç: $currentCashAdvanceDebt, İstenen: $amount',
        );
      }
    }

    final now = DateTime.now();
    final transaction = CreditCardTransaction(
      id: _uuid.v4(),
      cardId: cardId,
      amount: amount,
      description: description,
      transactionDate: now,
      category: category,
      installmentCount: 1,
      installmentsPaid: 0,
      createdAt: now,
      isCashAdvance: true,
    );
    final validationError = transaction.validate();
    if (validationError != null) {
      throw Exception(validationError);
    }

    await _transactionRepo.save(transaction);
    return transaction;
  }
  Future<List<CreditCardTransaction>> getCashAdvances(String cardId) async {
    final transactions = await _transactionRepo.findByCardId(cardId);
    return transactions
        .where((t) => t.isCashAdvance)
        .toList();
  }
  Future<List<CreditCardTransaction>> getUnpaidCashAdvances(String cardId) async {
    final cashAdvances = await getCashAdvances(cardId);
    return cashAdvances
        .where((t) => !t.isCompleted)
        .toList();
  }
  Future<double> getTotalCashAdvanceDebt(String cardId) async {
    final unpaidCashAdvances = await getUnpaidCashAdvances(cardId);
    return unpaidCashAdvances.fold<double>(
      0,
      (sum, t) => sum + t.remainingAmount,
    );
  }
  Future<double> getAvailableCashAdvanceLimit(String cardId) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }
    if (card.cashAdvanceLimit == null || card.cashAdvanceLimit! <= 0) {
      return 0.0;
    }

    final currentDebt = await getTotalCashAdvanceDebt(cardId);
    final available = card.cashAdvanceLimit! - currentDebt;
    
    return available > 0 ? available : 0.0;
  }
  Future<int> getCashAdvanceCount(String cardId) async {
    final cashAdvances = await getCashAdvances(cardId);
    return cashAdvances.length;
  }
  Future<int> getUnpaidCashAdvanceCount(String cardId) async {
    final unpaidCashAdvances = await getUnpaidCashAdvances(cardId);
    return unpaidCashAdvances.length;
  }
  Future<double> calculateCashAdvanceInterest(
    String cardId, [
    DateTime? currentDate,
  ]) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }
    final cashAdvanceRate = card.cashAdvanceRate ?? (card.monthlyInterestRate * 1.5);
    final dailyRate = cashAdvanceRate / 30.0 / 100.0;

    final checkDate = currentDate ?? DateTime.now();
    final unpaidCashAdvances = await getUnpaidCashAdvances(cardId);
    
    double totalInterest = 0.0;

    for (var transaction in unpaidCashAdvances) {
      final daysSince = checkDate.difference(transaction.transactionDate).inDays;
      final interest = transaction.remainingAmount * dailyRate * daysSince;
      totalInterest += interest;
    }

    return totalInterest;
  }
  Future<Map<String, dynamic>> getCashAdvanceSummary(String cardId) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    final totalDebt = await getTotalCashAdvanceDebt(cardId);
    final availableLimit = await getAvailableCashAdvanceLimit(cardId);
    final totalInterest = await calculateCashAdvanceInterest(cardId);
    final cashAdvanceCount = await getCashAdvanceCount(cardId);
    final unpaidCount = await getUnpaidCashAdvanceCount(cardId);
    
    final cashAdvanceRate = card.cashAdvanceRate ?? (card.monthlyInterestRate * 1.5);

    return {
      'totalDebt': totalDebt,
      'totalInterest': totalInterest,
      'totalWithInterest': totalDebt + totalInterest,
      'cashAdvanceLimit': card.cashAdvanceLimit ?? 0.0,
      'availableLimit': availableLimit,
      'cashAdvanceRate': cashAdvanceRate,
      'dailyRate': cashAdvanceRate / 30.0,
      'totalCount': cashAdvanceCount,
      'unpaidCount': unpaidCount,
      'hasLimit': card.cashAdvanceLimit != null && card.cashAdvanceLimit! > 0,
    };
  }
  Future<double> calculateTransactionInterest(
    String transactionId, [
    DateTime? currentDate,
  ]) async {
    final transaction = await _transactionRepo.findById(transactionId);
    if (transaction == null) {
      throw Exception('İşlem bulunamadı');
    }

    if (!transaction.isCashAdvance) {
      return 0.0;
    }

    if (transaction.isCompleted) {
      return 0.0;
    }

    final card = await _cardRepo.findById(transaction.cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }
    final cashAdvanceRate = card.cashAdvanceRate ?? (card.monthlyInterestRate * 1.5);
    final dailyRate = cashAdvanceRate / 30.0 / 100.0;

    final checkDate = currentDate ?? DateTime.now();
    final daysSince = checkDate.difference(transaction.transactionDate).inDays;
    final interest = transaction.remainingAmount * dailyRate * daysSince;

    return interest;
  }
  Future<List<CreditCardTransaction>> getCashAdvancesByDateRange(
    String cardId,
    DateTime start,
    DateTime end,
  ) async {
    final transactions = await _transactionRepo.findByDateRange(cardId, start, end);
    return transactions
        .where((t) => t.isCashAdvance)
        .toList();
  }
  Future<bool> hasUnpaidCashAdvances(String cardId) async {
    final unpaidCount = await getUnpaidCashAdvanceCount(cardId);
    return unpaidCount > 0;
  }
  Future<double> getTotalCashAdvanceAmount(String cardId) async {
    final cashAdvances = await getCashAdvances(cardId);
    return cashAdvances.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );
  }
}
