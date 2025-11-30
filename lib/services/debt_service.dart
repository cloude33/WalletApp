import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/debt.dart';
import '../models/debt_payment.dart';
import '../models/debt_reminder.dart';

class DebtService {
  static final DebtService _instance = DebtService._internal();
  factory DebtService() => _instance;
  DebtService._internal();

  final Uuid _uuid = const Uuid();

  // Cache
  List<Debt>? _cachedDebts;
  Map<String, List<DebtPayment>> _cachedPayments = {};
  Map<String, List<DebtReminder>> _cachedReminders = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Cache'i temizle
  void clearCache() {
    _cachedDebts = null;
    _cachedPayments.clear();
    _cachedReminders.clear();
    _lastCacheUpdate = null;
  }

  /// Cache geçerli mi?
  bool get _isCacheValid {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheTimeout;
  }

  // ==================== DEBT CRUD ====================

  /// Tüm borç/alacakları getir
  Future<List<Debt>> getDebts({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid && _cachedDebts != null) {
      return _cachedDebts!;
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('debts');
    
    final debts = jsonString != null
        ? (jsonDecode(jsonString) as List<dynamic>)
            .map((json) => Debt.fromJson(json as Map<String, dynamic>))
            .toList()
        : <Debt>[];

    _cachedDebts = debts;
    _lastCacheUpdate = DateTime.now();

    return debts;
  }

  /// ID'ye göre borç/alacak getir
  Future<Debt?> getDebtById(String id) async {
    final debts = await getDebts();
    try {
      return debts.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Kişiye göre borç/alacakları getir
  Future<List<Debt>> getDebtsByPerson(String personName) async {
    final debts = await getDebts();
    return debts
        .where((d) => d.personName.toLowerCase() == personName.toLowerCase())
        .toList();
  }

  /// Tipe göre borç/alacakları getir
  Future<List<Debt>> getDebtsByType(DebtType type) async {
    final debts = await getDebts();
    return debts.where((d) => d.type == type).toList();
  }

  /// Duruma göre borç/alacakları getir
  Future<List<Debt>> getDebtsByStatus(DebtStatus status) async {
    final debts = await getDebts();
    return debts.where((d) => d.status == status).toList();
  }

  /// Aktif borç/alacakları getir
  Future<List<Debt>> getActiveDebts() async {
    final debts = await getDebts();
    return debts.where((d) => d.status == DebtStatus.active).toList();
  }

  /// Vadesi geçmiş borç/alacakları getir
  Future<List<Debt>> getOverdueDebts() async {
    final debts = await getDebts();
    return debts.where((d) => d.isOverdue).toList();
  }

  /// Yeni borç/alacak ekle
  Future<Debt> addDebt({
    required String personName,
    String? phone,
    required double amount,
    required DebtType type,
    required DebtCategory category,
    DateTime? dueDate,
    String? description,
  }) async {
    // Validation
    if (personName.trim().isEmpty) {
      throw ArgumentError('Kişi adı boş olamaz');
    }
    if (amount <= 0) {
      throw ArgumentError('Tutar sıfırdan büyük olmalı');
    }

    final now = DateTime.now();
    final debt = Debt(
      id: _uuid.v4(),
      personName: personName.trim(),
      phone: phone?.trim(),
      originalAmount: amount,
      remainingAmount: amount,
      type: type,
      status: DebtStatus.active,
      category: category,
      createdDate: now,
      dueDate: dueDate,
      description: description?.trim(),
      updatedDate: now,
    );

    // Validation
    final validationError = debt.validate();
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final debts = await getDebts();
    debts.add(debt);
    await _saveDebts(debts);

    return debt;
  }

  /// Borç/alacak güncelle
  Future<Debt> updateDebt(Debt debt) async {
    // Validation
    final validationError = debt.validate();
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final debts = await getDebts();
    final index = debts.indexWhere((d) => d.id == debt.id);

    if (index == -1) {
      throw ArgumentError('Borç/alacak bulunamadı');
    }

    final updatedDebt = debt.copyWith(updatedDate: DateTime.now());
    debts[index] = updatedDebt;
    await _saveDebts(debts);

    return updatedDebt;
  }

  /// Borç/alacak sil
  Future<void> deleteDebt(String id) async {
    final debts = await getDebts();
    debts.removeWhere((d) => d.id == id);
    await _saveDebts(debts);

    // İlgili ödemeleri ve hatırlatmaları da sil
    _cachedPayments.remove(id);
    _cachedReminders.remove(id);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('debt_payments_$id');
    await prefs.remove('debt_reminders_$id');
  }

  /// Borç/alacak durumunu güncelle
  Future<Debt> updateDebtStatus(String id, DebtStatus status) async {
    final debt = await getDebtById(id);
    if (debt == null) {
      throw ArgumentError('Borç/alacak bulunamadı');
    }

    final updatedDebt = debt.copyWith(
      status: status,
      updatedDate: DateTime.now(),
    );

    return await updateDebt(updatedDebt);
  }

  /// Borç/alacağı ödendi olarak işaretle
  Future<Debt> markAsPaid(String id) async {
    final debt = await getDebtById(id);
    if (debt == null) {
      throw ArgumentError('Borç/alacak bulunamadı');
    }

    final updatedDebt = debt.copyWith(
      status: DebtStatus.paid,
      remainingAmount: 0,
      updatedDate: DateTime.now(),
    );

    return await updateDebt(updatedDebt);
  }

  /// Vadesi geçmiş borç/alacakları güncelle
  Future<void> updateOverdueDebts() async {
    final debts = await getDebts();
    bool hasChanges = false;

    for (int i = 0; i < debts.length; i++) {
      if (debts[i].isOverdue && debts[i].status != DebtStatus.overdue) {
        debts[i] = debts[i].copyWith(
          status: DebtStatus.overdue,
          updatedDate: DateTime.now(),
        );
        hasChanges = true;
      }
    }

    if (hasChanges) {
      await _saveDebts(debts);
    }
  }

  // ==================== PAYMENT MANAGEMENT ====================

  /// Borç/alacağın ödemelerini getir
  Future<List<DebtPayment>> getPayments(String debtId) async {
    if (_cachedPayments.containsKey(debtId)) {
      return _cachedPayments[debtId]!;
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('debt_payments_$debtId');
    
    final payments = jsonString != null
        ? (jsonDecode(jsonString) as List<dynamic>)
            .map((json) => DebtPayment.fromJson(json as Map<String, dynamic>))
            .where((p) => !p.isDeleted)
            .toList()
        : <DebtPayment>[];

    _cachedPayments[debtId] = payments;
    return payments;
  }

  /// Ödeme ekle
  Future<DebtPayment> addPayment({
    required String debtId,
    required double amount,
    required DateTime date,
    PaymentType type = PaymentType.partial,
    String? note,
  }) async {
    // Validation
    if (amount == 0) {
      throw ArgumentError('Ödeme tutarı sıfır olamaz');
    }

    final debt = await getDebtById(debtId);
    if (debt == null) {
      throw ArgumentError('Borç/alacak bulunamadı');
    }

    if (amount.abs() > debt.remainingAmount) {
      throw ArgumentError('Ödeme tutarı kalan tutardan fazla olamaz');
    }

    final now = DateTime.now();
    final payment = DebtPayment(
      id: _uuid.v4(),
      debtId: debtId,
      amount: amount,
      date: date,
      type: type,
      note: note?.trim(),
      createdDate: now,
      updatedDate: now,
    );

    // Validation
    final validationError = payment.validate();
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    // Ödemeyi kaydet
    final payments = await getPayments(debtId);
    payments.add(payment);
    await _savePayments(debtId, payments);

    // Borç/alacağı güncelle
    final newRemainingAmount = debt.remainingAmount - amount;
    final newStatus = newRemainingAmount <= 0.01
        ? DebtStatus.paid
        : (debt.isOverdue ? DebtStatus.overdue : DebtStatus.active);

    final updatedDebt = debt.copyWith(
      remainingAmount: newRemainingAmount > 0 ? newRemainingAmount : 0,
      status: newStatus,
      lastPaymentDate: date,
      paymentIds: [...debt.paymentIds, payment.id],
      updatedDate: now,
    );

    await updateDebt(updatedDebt);

    return payment;
  }

  /// Ödeme sil
  Future<void> deletePayment(String debtId, String paymentId) async {
    final payments = await getPayments(debtId);
    final payment = payments.firstWhere((p) => p.id == paymentId);

    // Ödemeyi soft delete yap
    final updatedPayment = payment.copyWith(
      isDeleted: true,
      updatedDate: DateTime.now(),
    );

    final index = payments.indexWhere((p) => p.id == paymentId);
    payments[index] = updatedPayment;
    await _savePayments(debtId, payments);

    // Borç/alacağı güncelle
    final debt = await getDebtById(debtId);
    if (debt != null) {
      final newRemainingAmount = debt.remainingAmount + payment.amount;
      final updatedDebt = debt.copyWith(
        remainingAmount: newRemainingAmount,
        status: DebtStatus.active,
        paymentIds: debt.paymentIds.where((id) => id != paymentId).toList(),
        updatedDate: DateTime.now(),
      );
      await updateDebt(updatedDebt);
    }

    // Cache'i güncelle
    _cachedPayments[debtId] = payments.where((p) => !p.isDeleted).toList();
  }

  /// Toplam ödenen tutarı hesapla
  Future<double> calculateTotalPaid(String debtId) async {
    final payments = await getPayments(debtId);
    return payments.fold<double>(0, (sum, p) => sum + p.amount);
  }

  // ==================== REMINDER MANAGEMENT ====================

  /// Borç/alacağın hatırlatmalarını getir
  Future<List<DebtReminder>> getReminders(String debtId) async {
    if (_cachedReminders.containsKey(debtId)) {
      return _cachedReminders[debtId]!;
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('debt_reminders_$debtId');
    
    final reminders = jsonString != null
        ? (jsonDecode(jsonString) as List<dynamic>)
            .map((json) => DebtReminder.fromJson(json as Map<String, dynamic>))
            .where((r) => r.isActive)
            .toList()
        : <DebtReminder>[];

    _cachedReminders[debtId] = reminders;
    return reminders;
  }

  /// Hatırlatma ekle
  Future<DebtReminder> addReminder({
    required String debtId,
    required DateTime reminderDate,
    required String message,
    required ReminderType type,
    RecurrenceFrequency? recurrenceFrequency,
    int? recurrenceInterval,
    int? maxRecurrences,
  }) async {
    final debt = await getDebtById(debtId);
    if (debt == null) {
      throw ArgumentError('Borç/alacak bulunamadı');
    }

    final now = DateTime.now();
    final reminder = DebtReminder(
      id: _uuid.v4(),
      debtId: debtId,
      reminderDate: reminderDate,
      message: message.trim(),
      type: type,
      status: ReminderStatus.pending,
      createdDate: now,
      recurrenceFrequency: recurrenceFrequency,
      recurrenceInterval: recurrenceInterval,
      maxRecurrences: maxRecurrences,
    );

    // Validation
    final validationError = reminder.validate();
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final reminders = await getReminders(debtId);
    reminders.add(reminder);
    await _saveReminders(debtId, reminders);

    // Borç/alacağı güncelle
    final updatedDebt = debt.copyWith(
      reminderIds: [...debt.reminderIds, reminder.id],
      updatedDate: now,
    );
    await updateDebt(updatedDebt);

    return reminder;
  }

  /// Hatırlatma sil
  Future<void> deleteReminder(String debtId, String reminderId) async {
    final reminders = await getReminders(debtId);
    final reminder = reminders.firstWhere((r) => r.id == reminderId);

    final updatedReminder = reminder.copyWith(isActive: false);
    final index = reminders.indexWhere((r) => r.id == reminderId);
    reminders[index] = updatedReminder;
    await _saveReminders(debtId, reminders);

    // Cache'i güncelle
    _cachedReminders[debtId] = reminders.where((r) => r.isActive).toList();

    // Borç/alacağı güncelle
    final debt = await getDebtById(debtId);
    if (debt != null) {
      final updatedDebt = debt.copyWith(
        reminderIds: debt.reminderIds.where((id) => id != reminderId).toList(),
        updatedDate: DateTime.now(),
      );
      await updateDebt(updatedDebt);
    }
  }

  // ==================== STATISTICS ====================

  /// Toplam alacak (verdiklerim)
  Future<double> getTotalLent() async {
    final debts = await getDebts();
    return debts
        .where((d) => d.type == DebtType.lent && d.status != DebtStatus.paid)
        .fold<double>(0, (sum, d) => sum + d.remainingAmount);
  }

  /// Toplam borç (aldıklarım)
  Future<double> getTotalBorrowed() async {
    final debts = await getDebts();
    return debts
        .where(
            (d) => d.type == DebtType.borrowed && d.status != DebtStatus.paid)
        .fold<double>(0, (sum, d) => sum + d.remainingAmount);
  }

  /// Net durum (alacak - borç)
  Future<double> getNetBalance() async {
    final lent = await getTotalLent();
    final borrowed = await getTotalBorrowed();
    return lent - borrowed;
  }

  /// Vadesi geçen sayısı
  Future<int> getOverdueCount() async {
    final debts = await getOverdueDebts();
    return debts.length;
  }

  /// Aktif borç/alacak sayısı
  Future<int> getActiveCount() async {
    final debts = await getActiveDebts();
    return debts.length;
  }

  // ==================== PRIVATE METHODS ====================

  Future<void> _saveDebts(List<Debt> debts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(debts.map((d) => d.toJson()).toList());
    await prefs.setString('debts', jsonString);
    
    _cachedDebts = debts;
    _lastCacheUpdate = DateTime.now();
  }

  Future<void> _savePayments(String debtId, List<DebtPayment> payments) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(payments.map((p) => p.toJson()).toList());
    await prefs.setString('debt_payments_$debtId', jsonString);
    
    _cachedPayments[debtId] = payments.where((p) => !p.isDeleted).toList();
  }

  Future<void> _saveReminders(
      String debtId, List<DebtReminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(reminders.map((r) => r.toJson()).toList());
    await prefs.setString('debt_reminders_$debtId', jsonString);
    
    _cachedReminders[debtId] = reminders.where((r) => r.isActive).toList();
  }
}
