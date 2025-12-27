import 'package:hive/hive.dart';
import '../models/credit_card_payment.dart';
import '../services/credit_card_box_service.dart';

class CreditCardPaymentRepository {
  Box<CreditCardPayment> get _box => CreditCardBoxService.paymentsBox;
  Future<void> save(CreditCardPayment payment) async {
    await _box.put(payment.id, payment);
  }
  Future<CreditCardPayment?> findById(String id) async {
    return _box.get(id);
  }
  Future<List<CreditCardPayment>> findByCardId(String cardId) async {
    final payments = _box.values
        .where((payment) => payment.cardId == cardId)
        .toList();
    payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    return payments;
  }
  Future<List<CreditCardPayment>> findByStatementId(String statementId) async {
    return _box.values
        .where((payment) => payment.statementId == statementId)
        .toList();
  }
  Future<List<CreditCardPayment>> findByDateRange(
    String cardId,
    DateTime start,
    DateTime end,
  ) async {
    return _box.values
        .where(
          (payment) =>
              payment.cardId == cardId &&
              payment.paymentDate.isAfter(
                start.subtract(const Duration(seconds: 1)),
              ) &&
              payment.paymentDate.isBefore(end.add(const Duration(days: 1))),
        )
        .toList();
  }
  Future<List<CreditCardPayment>> findByPaymentMethod(
    String cardId,
    String paymentMethod,
  ) async {
    return _box.values
        .where(
          (payment) =>
              payment.cardId == cardId &&
              payment.paymentMethod == paymentMethod,
        )
        .toList();
  }
  Future<double> getTotalPayments(String statementId) async {
    final payments = await findByStatementId(statementId);
    return payments.fold<double>(0, (sum, p) => sum + p.amount);
  }
  Future<double> getTotalPaymentsByCard(String cardId) async {
    final payments = await findByCardId(cardId);
    return payments.fold<double>(0, (sum, p) => sum + p.amount);
  }
  Future<double> getTotalPaymentsInRange(
    String cardId,
    DateTime start,
    DateTime end,
  ) async {
    final payments = await findByDateRange(cardId, start, end);
    return payments.fold<double>(0, (sum, p) => sum + p.amount);
  }
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
  Future<void> update(CreditCardPayment payment) async {
    await _box.put(payment.id, payment);
  }
  Future<int> countByCardId(String cardId) async {
    return _box.values.where((p) => p.cardId == cardId).length;
  }
  Future<int> countByStatementId(String statementId) async {
    return _box.values.where((p) => p.statementId == statementId).length;
  }
  Future<CreditCardPayment?> getLatestPayment(String cardId) async {
    final payments = await findByCardId(cardId);
    return payments.isNotEmpty ? payments.first : null;
  }
  Future<void> clear() async {
    await _box.clear();
  }
}
