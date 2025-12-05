import 'package:uuid/uuid.dart';
import '../models/credit_card_transaction.dart';
import '../repositories/credit_card_repository.dart';
import '../repositories/credit_card_transaction_repository.dart';

/// Service for managing cash advance transactions
/// 
/// Cash advances have different interest rates and are tracked separately
/// from regular purchases. They typically have higher interest rates and
/// start accruing interest immediately (no grace period).
class CashAdvanceService {
  final CreditCardRepository _cardRepo = CreditCardRepository();
  final CreditCardTransactionRepository _transactionRepo = CreditCardTransactionRepository();
  final Uuid _uuid = const Uuid();

  // ==================== NAKİT AVANS YÖNETİMİ ====================

  /// Record a cash advance transaction
  /// 
  /// [cardId] - The credit card ID
  /// [amount] - Cash advance amount
  /// [description] - Transaction description
  /// [category] - Transaction category (default: 'Nakit Avans')
  /// 
  /// Returns the created transaction
  /// 
  /// Throws [Exception] if validation fails or card not found
  Future<CreditCardTransaction> recordCashAdvance({
    required String cardId,
    required double amount,
    required String description,
    String category = 'Nakit Avans',
  }) async {
    // Validate inputs
    if (cardId.trim().isEmpty) {
      throw Exception('Kart ID boş olamaz');
    }
    if (amount <= 0) {
      throw Exception('Tutar sıfırdan büyük olmalı');
    }
    if (description.trim().isEmpty) {
      throw Exception('Açıklama boş olamaz');
    }

    // Get the card to check cash advance limit
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    // Check cash advance limit if set
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
    
    // Create cash advance transaction
    final transaction = CreditCardTransaction(
      id: _uuid.v4(),
      cardId: cardId,
      amount: amount,
      description: description,
      transactionDate: now,
      category: category,
      installmentCount: 1, // Cash advances are always single payment
      installmentsPaid: 0,
      createdAt: now,
      isCashAdvance: true, // Mark as cash advance
    );

    // Validate the transaction
    final validationError = transaction.validate();
    if (validationError != null) {
      throw Exception(validationError);
    }

    await _transactionRepo.save(transaction);
    return transaction;
  }

  // ==================== NAKİT AVANS SORGULARI ====================

  /// Get all cash advance transactions for a specific card
  /// 
  /// Returns list of transactions marked as cash advances
  Future<List<CreditCardTransaction>> getCashAdvances(String cardId) async {
    final transactions = await _transactionRepo.findByCardId(cardId);
    return transactions
        .where((t) => t.isCashAdvance)
        .toList();
  }

  /// Get all unpaid cash advance transactions for a specific card
  /// 
  /// Returns list of cash advance transactions that haven't been paid
  Future<List<CreditCardTransaction>> getUnpaidCashAdvances(String cardId) async {
    final cashAdvances = await getCashAdvances(cardId);
    return cashAdvances
        .where((t) => !t.isCompleted)
        .toList();
  }

  /// Get total cash advance debt for a specific card
  /// 
  /// Returns the sum of all unpaid cash advance amounts
  Future<double> getTotalCashAdvanceDebt(String cardId) async {
    final unpaidCashAdvances = await getUnpaidCashAdvances(cardId);
    return unpaidCashAdvances.fold<double>(
      0,
      (sum, t) => sum + t.remainingAmount,
    );
  }

  /// Get available cash advance limit for a card
  /// 
  /// Returns the remaining cash advance limit
  Future<double> getAvailableCashAdvanceLimit(String cardId) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    // If no cash advance limit is set, return 0
    if (card.cashAdvanceLimit == null || card.cashAdvanceLimit! <= 0) {
      return 0.0;
    }

    final currentDebt = await getTotalCashAdvanceDebt(cardId);
    final available = card.cashAdvanceLimit! - currentDebt;
    
    return available > 0 ? available : 0.0;
  }

  /// Get count of cash advance transactions for a card
  Future<int> getCashAdvanceCount(String cardId) async {
    final cashAdvances = await getCashAdvances(cardId);
    return cashAdvances.length;
  }

  /// Get count of unpaid cash advance transactions for a card
  Future<int> getUnpaidCashAdvanceCount(String cardId) async {
    final unpaidCashAdvances = await getUnpaidCashAdvances(cardId);
    return unpaidCashAdvances.length;
  }

  // ==================== NAKİT AVANS FAİZ HESAPLAMA ====================

  /// Calculate daily interest for cash advances
  /// 
  /// Cash advances typically accrue interest daily from the transaction date
  /// 
  /// [cardId] - The credit card ID
  /// [currentDate] - The date to calculate interest up to (defaults to now)
  /// 
  /// Returns the total accrued interest on all unpaid cash advances
  Future<double> calculateCashAdvanceInterest(
    String cardId, [
    DateTime? currentDate,
  ]) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    // Get cash advance rate, default to monthly rate * 1.5 if not set
    final cashAdvanceRate = card.cashAdvanceRate ?? (card.monthlyInterestRate * 1.5);
    
    // Convert monthly rate to daily rate
    // Assuming 30 days per month for simplicity
    final dailyRate = cashAdvanceRate / 30.0 / 100.0;

    final checkDate = currentDate ?? DateTime.now();
    final unpaidCashAdvances = await getUnpaidCashAdvances(cardId);
    
    double totalInterest = 0.0;

    for (var transaction in unpaidCashAdvances) {
      // Calculate days since transaction
      final daysSince = checkDate.difference(transaction.transactionDate).inDays;
      
      // Calculate interest: principal * daily_rate * days
      final interest = transaction.remainingAmount * dailyRate * daysSince;
      totalInterest += interest;
    }

    return totalInterest;
  }

  /// Get cash advance summary for a card
  /// 
  /// Returns a map with detailed cash advance information
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

  /// Calculate interest for a specific cash advance transaction
  /// 
  /// [transactionId] - The transaction ID
  /// [currentDate] - The date to calculate interest up to (defaults to now)
  /// 
  /// Returns the accrued interest for this specific transaction
  Future<double> calculateTransactionInterest(
    String transactionId, [
    DateTime? currentDate,
  ]) async {
    final transaction = await _transactionRepo.findById(transactionId);
    if (transaction == null) {
      throw Exception('İşlem bulunamadı');
    }

    if (!transaction.isCashAdvance) {
      return 0.0; // Not a cash advance, no interest
    }

    if (transaction.isCompleted) {
      return 0.0; // Already paid, no interest
    }

    final card = await _cardRepo.findById(transaction.cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    // Get cash advance rate
    final cashAdvanceRate = card.cashAdvanceRate ?? (card.monthlyInterestRate * 1.5);
    
    // Convert monthly rate to daily rate
    final dailyRate = cashAdvanceRate / 30.0 / 100.0;

    final checkDate = currentDate ?? DateTime.now();
    
    // Calculate days since transaction
    final daysSince = checkDate.difference(transaction.transactionDate).inDays;
    
    // Calculate interest: principal * daily_rate * days
    final interest = transaction.remainingAmount * dailyRate * daysSince;

    return interest;
  }

  /// Get cash advances by date range
  /// 
  /// [cardId] - The credit card ID
  /// [start] - Start date
  /// [end] - End date
  /// 
  /// Returns list of cash advances within the date range
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

  /// Check if a card has any unpaid cash advances
  Future<bool> hasUnpaidCashAdvances(String cardId) async {
    final unpaidCount = await getUnpaidCashAdvanceCount(cardId);
    return unpaidCount > 0;
  }

  /// Get total cash advance amount (including paid ones) for a card
  Future<double> getTotalCashAdvanceAmount(String cardId) async {
    final cashAdvances = await getCashAdvances(cardId);
    return cashAdvances.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );
  }
}
