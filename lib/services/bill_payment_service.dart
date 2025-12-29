import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/bill_payment.dart';
import '../models/transaction.dart';
import 'bill_template_service.dart';
import 'data_service.dart';
class BillPaymentService {
  static const String _storageKey = 'bill_payments';
  final Uuid _uuid = const Uuid();
  final BillTemplateService _templateService = BillTemplateService();
  Future<List<BillPayment>> getPayments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => BillPayment.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  Future<List<BillPayment>> getPendingPayments() async {
    final payments = await getPayments();
    return payments.where((p) => p.isPending).toList();
  }
  Future<List<BillPayment>> getOverduePayments() async {
    final payments = await getPayments();
    return payments.where((p) => p.isOverdue).toList();
  }
  Future<List<BillPayment>> getPaidPayments() async {
    final payments = await getPayments();
    return payments.where((p) => p.isPaid).toList();
  }
  Future<List<BillPayment>> getPaymentsByTemplate(String templateId) async {
    final payments = await getPayments();
    return payments.where((p) => p.templateId == templateId).toList();
  }
  Future<List<BillPayment>> getPaymentsByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final payments = await getPayments();
    return payments.where((p) {
      return p.periodStart.isAfter(start.subtract(const Duration(days: 1))) &&
          p.periodEnd.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }
  Future<BillPayment> addPayment({
    required String templateId,
    required double amount,
    required DateTime dueDate,
    required DateTime periodStart,
    required DateTime periodEnd,
    String? notes,
  }) async {
    final template = await _templateService.getTemplate(templateId);
    if (template == null) {
      throw Exception('Fatura şablonu bulunamadı');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final isOverdue = dueDateOnly.isBefore(today) || dueDateOnly.isAtSameMomentAs(today);
    
    final payment = BillPayment(
      id: _uuid.v4(),
      templateId: templateId,
      amount: amount,
      dueDate: dueDate,
      periodStart: periodStart,
      periodEnd: periodEnd,
      status: isOverdue ? BillPaymentStatus.paid : BillPaymentStatus.pending,
      paidDate: isOverdue ? now : null,
      paidWithWalletId: isOverdue ? template.walletId : null,
      notes: notes?.trim(),
      createdDate: now,
      updatedDate: now,
    );

    final payments = await getPayments();
    payments.add(payment);
    await savePayments(payments);
    if (isOverdue && template.walletId != null) {
      final dataService = DataService();
      final transaction = Transaction(
        id: _uuid.v4(),
        description: '${template.name} Fatura Ödemesi',
        amount: amount,
        type: 'expense',
        category: template.categoryDisplayName,
        date: dueDate,
        walletId: template.walletId!,
      );
      
      await dataService.addTransaction(transaction);
      final updatedPayment = payment.copyWith(transactionId: transaction.id);
      final index = payments.indexWhere((p) => p.id == payment.id);
      if (index != -1) {
        payments[index] = updatedPayment;
        await savePayments(payments);
      }
    }

    return payment;
  }
  Future<void> updatePayment(BillPayment payment) async {
    final payments = await getPayments();
    final index = payments.indexWhere((p) => p.id == payment.id);

    if (index == -1) {
      throw Exception('Ödeme bulunamadı');
    }

    payments[index] = payment.copyWith(updatedDate: DateTime.now());
    await savePayments(payments);
  }
  Future<void> deletePayment(String id) async {
    final payments = await getPayments();
    payments.removeWhere((p) => p.id == id);
    await savePayments(payments);
  }
  Future<void> markAsPaid({
    required String paymentId,
    required String walletId,
    String? transactionId,
  }) async {
    final payments = await getPayments();
    final index = payments.indexWhere((p) => p.id == paymentId);

    if (index == -1) {
      throw Exception('Ödeme bulunamadı');
    }

    final payment = payments[index];
    String? newTransactionId = transactionId;
    if (newTransactionId == null) {
      final template = await _templateService.getTemplate(payment.templateId);
      
      if (template != null) {
        final dataService = DataService();
        final transaction = Transaction(
          id: _uuid.v4(),
          description: '${template.name} Fatura Ödemesi',
          amount: payment.amount,
          type: 'expense',
          category: template.categoryDisplayName,
          date: DateTime.now(),
          walletId: walletId,
        );
        
        await dataService.addTransaction(transaction);
        newTransactionId = transaction.id;
      }
    }

    payments[index] = payment.copyWith(
      status: BillPaymentStatus.paid,
      paidDate: DateTime.now(),
      paidWithWalletId: walletId,
      transactionId: newTransactionId,
      updatedDate: DateTime.now(),
    );
    await savePayments(payments);
  }
  Future<void> savePayments(List<BillPayment> payments) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = payments.map((p) => p.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }
  Future<bool> hasPaymentForCurrentMonth(String templateId) async {
    final now = DateTime.now();
    final payments = await getPaymentsByTemplate(templateId);
    return payments.any(
      (p) => p.periodStart.year == now.year && p.periodStart.month == now.month,
    );
  }
  Future<double> getTotalPaidAmount(DateTime start, DateTime end) async {
    final payments = await getPaymentsByPeriod(start, end);
    final paidPayments = payments.where((p) => p.isPaid).toList();
    return paidPayments.fold<double>(0.0, (sum, p) => sum + p.amount);
  }
  Future<double> getTotalPendingAmount() async {
    final payments = await getPendingPayments();
    return payments.fold<double>(0.0, (sum, p) => sum + p.amount);
  }
  Future<void> clearAllPayments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
  Future<void> addPaymentDirect(BillPayment payment) async {
    final payments = await getPayments();
    payments.add(payment);
    await savePayments(payments);
  }
}
