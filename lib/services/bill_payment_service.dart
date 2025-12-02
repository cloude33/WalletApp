import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/bill_payment.dart';
import 'bill_template_service.dart';

/// Fatura ödemelerini yöneten servis
class BillPaymentService {
  static const String _storageKey = 'bill_payments';
  final Uuid _uuid = const Uuid();
  final BillTemplateService _templateService = BillTemplateService();

  /// Tüm ödemeleri getir
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

  /// Bekleyen ödemeleri getir
  Future<List<BillPayment>> getPendingPayments() async {
    final payments = await getPayments();
    return payments.where((p) => p.isPending).toList();
  }

  /// Vadesi geçmiş ödemeleri getir
  Future<List<BillPayment>> getOverduePayments() async {
    final payments = await getPayments();
    return payments.where((p) => p.isOverdue).toList();
  }

  /// Ödenen faturaları getir
  Future<List<BillPayment>> getPaidPayments() async {
    final payments = await getPayments();
    return payments.where((p) => p.isPaid).toList();
  }

  /// Şablona göre ödemeleri getir
  Future<List<BillPayment>> getPaymentsByTemplate(String templateId) async {
    final payments = await getPayments();
    return payments.where((p) => p.templateId == templateId).toList();
  }

  /// Belirli bir dönem için ödemeleri getir
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

  /// Yeni ödeme ekle
  Future<BillPayment> addPayment({
    required String templateId,
    required double amount,
    required DateTime dueDate,
    required DateTime periodStart,
    required DateTime periodEnd,
    String? notes,
  }) async {
    // Şablonun var olduğunu kontrol et
    final template = await _templateService.getTemplate(templateId);
    if (template == null) {
      throw Exception('Fatura şablonu bulunamadı');
    }

    final now = DateTime.now();
    final payment = BillPayment(
      id: _uuid.v4(),
      templateId: templateId,
      amount: amount,
      dueDate: dueDate,
      periodStart: periodStart,
      periodEnd: periodEnd,
      status: BillPaymentStatus.pending,
      notes: notes?.trim(),
      createdDate: now,
      updatedDate: now,
    );

    final payments = await getPayments();
    payments.add(payment);
    await _savePayments(payments);

    return payment;
  }

  /// Ödemeyi güncelle
  Future<void> updatePayment(BillPayment payment) async {
    final payments = await getPayments();
    final index = payments.indexWhere((p) => p.id == payment.id);
    
    if (index == -1) {
      throw Exception('Ödeme bulunamadı');
    }

    payments[index] = payment.copyWith(updatedDate: DateTime.now());
    await _savePayments(payments);
  }

  /// Ödemeyi sil
  Future<void> deletePayment(String id) async {
    final payments = await getPayments();
    payments.removeWhere((p) => p.id == id);
    await _savePayments(payments);
  }

  /// Ödemeyi ödendi olarak işaretle
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

    payments[index] = payments[index].copyWith(
      status: BillPaymentStatus.paid,
      paidDate: DateTime.now(),
      paidWithWalletId: walletId,
      transactionId: transactionId,
      updatedDate: DateTime.now(),
    );
    await _savePayments(payments);
  }

  /// Ödemeleri kaydet
  Future<void> _savePayments(List<BillPayment> payments) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = payments.map((p) => p.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }

  /// Bu ay için ödeme var mı kontrol et
  Future<bool> hasPaymentForCurrentMonth(String templateId) async {
    final now = DateTime.now();
    final payments = await getPaymentsByTemplate(templateId);
    return payments.any((p) =>
        p.periodStart.year == now.year && p.periodStart.month == now.month);
  }

  /// Toplam ödenen tutar (belirli bir dönem için)
  Future<double> getTotalPaidAmount(DateTime start, DateTime end) async {
    final payments = await getPaymentsByPeriod(start, end);
    final paidPayments = payments.where((p) => p.isPaid).toList();
    return paidPayments.fold<double>(0.0, (sum, p) => sum + p.amount);
  }

  /// Toplam bekleyen tutar
  Future<double> getTotalPendingAmount() async {
    final payments = await getPendingPayments();
    return payments.fold<double>(0.0, (sum, p) => sum + p.amount);
  }

  /// Tüm ödemeleri temizle (migration için)
  Future<void> clearAllPayments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Ödeme ekle (migration için - BillPayment nesnesi ile)
  Future<void> addPaymentDirect(BillPayment payment) async {
    final payments = await getPayments();
    payments.add(payment);
    await _savePayments(payments);
  }
}
