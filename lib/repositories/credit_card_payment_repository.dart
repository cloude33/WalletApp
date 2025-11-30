import 'package:hive/hive.dart';
import '../models/credit_card_payment.dart';
import '../services/credit_card_box_service.dart';

class CreditCardPaymentRepository {
  Box<CreditCardPayment> get _box => CreditCardBoxService.paymentsBox;

  /// Save a payment
  Future<void> save(CreditCardPayment payment) async {
    await _box.put(payment.id, payment);
  }

  /// Find a payment by ID
  Future<CreditCardPayment?> findById(String id) async {
    return _box.get(id);
  }

  /// Find all payments for a specific card
  Future<List<CreditCardPayment>> findByCardId(String cardId) async {
    final payments = _box.values
        .where((payment) => payment.cardId == cardId)
        .toList();
    
    // Sort by payment date (newest first)
    payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    
    return payments;
  }

  /// Find all payments for a specific statement
  Future<List<CreditCardPayment>> findByStatementId(String statementId) async {
    return _box.values
        .where((payment) => payment.statementId == statementId)
        .toList();
  }

  /// Find payments by date range for a specific card
  Future<List<CreditCardPayment>> findByDateRange(
    String cardId,
    DateTime start,
    DateTime end,
  ) async {
    return _box.values
        .where((payment) =>
            payment.cardId == cardId &&
            payment.paymentDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
            payment.paymentDate.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  /// Find payments by payment method
  Future<List<CreditCardPayment>> findByPaymentMethod(
    String cardId,
    String paymentMethod,
  ) async {
    return _box.values
        .where((payment) =>
            payment.cardId == cardId &&
            payment.paymentMethod == paymentMethod)
        .toList();
  }

  /// Get total payments for a statement
  Future<double> getTotalPayments(String statementId) async {
    final payments = await findByStatementId(statementId);
    return payments.fold<double>(0, (sum, p) => sum + p.amount);
  }

  /// Get total payments for a card
  Future<double> getTotalPaymentsByCard(String cardId) async {
    final payments = await findByCardId(cardId);
    return payments.fold<double>(0, (sum, p) => sum + p.amount);
  }

  /// Get total payments for a card in a date range
  Future<double> getTotalPaymentsInRange(
    String cardId,
    DateTime start,
    DateTime end,
  ) async {
    final payments = await findByDateRange(cardId, start, end);
    return payments.fold<double>(0, (sum, p) => sum + p.amount);
  }

  /// Delete a payment
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Update a payment
  Future<void> update(CreditCardPayment payment) async {
    await _box.put(payment.id, payment);
  }

  /// Get count of payments for a card
  Future<int> countByCardId(String cardId) async {
    return _box.values.where((p) => p.cardId == cardId).length;
  }

  /// Get count of payments for a statement
  Future<int> countByStatementId(String statementId) async {
    return _box.values.where((p) => p.statementId == statementId).length;
  }

  /// Get latest payment for a card
  Future<CreditCardPayment?> getLatestPayment(String cardId) async {
    final payments = await findByCardId(cardId);
    return payments.isNotEmpty ? payments.first : null;
  }

  /// Clear all payments (for testing)
  Future<void> clear() async {
    await _box.clear();
  }
}
