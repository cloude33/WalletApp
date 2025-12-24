import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/bill_template.dart';
import '../models/bill_payment.dart';
import 'bill_template_service.dart';
import 'bill_payment_service.dart';
class BillMigrationService {
  static final BillMigrationService _instance =
      BillMigrationService._internal();
  factory BillMigrationService() => _instance;
  BillMigrationService._internal();

  final Uuid _uuid = const Uuid();
  final BillTemplateService _templateService = BillTemplateService();
  final BillPaymentService _paymentService = BillPaymentService();

  static const String _migrationKey = 'bill_migration_completed';
  Future<bool> isMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationKey) ?? false;
  }
  Future<void> markMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, true);
  }
  Future<void> migrateBills() async {
    try {
      if (await isMigrationCompleted()) {
        debugPrint('Migration zaten tamamlanmış, atlanıyor');
        return;
      }

      debugPrint('Bill migration başlatılıyor...');
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('bills');

      if (jsonString == null || jsonString.isEmpty) {
        debugPrint('Migrate edilecek bill verisi bulunamadı');
        await markMigrationCompleted();
        return;
      }
      final List<dynamic> oldBillsJson =
          jsonDecode(jsonString) as List<dynamic>;

      debugPrint('${oldBillsJson.length} adet bill bulundu');
      final Map<String, List<Map<String, dynamic>>> groupedBills = {};

      for (var billJson in oldBillsJson) {
        final bill = billJson as Map<String, dynamic>;
        final name = bill['name'] as String? ?? 'Bilinmeyen';
        final provider = bill['provider'] as String?;
        final key = '${name}_${provider ?? ''}';
        if (!groupedBills.containsKey(key)) {
          groupedBills[key] = [];
        }
        groupedBills[key]!.add(bill);
      }

      debugPrint('${groupedBills.length} benzersiz fatura tanımı bulundu');

      int templateCount = 0;
      int paymentCount = 0;
      for (var entry in groupedBills.entries) {
        final bills = entry.value;
        final firstBill = bills.first;
        final template = BillTemplate(
          id: _uuid.v4(),
          name: firstBill['name'] as String? ?? 'Bilinmeyen',
          provider: firstBill['provider'] as String?,
          category: _mapBillCategoryToTemplateCategory(
            firstBill['category'] as String?,
          ),
          accountNumber: firstBill['accountNumber'] as String?,
          phoneNumber: firstBill['phoneNumber'] as String?,
          description: firstBill['description'] as String?,
          isActive: true,
          createdDate: _parseDateTime(firstBill['createdDate']),
          updatedDate: DateTime.now(),
        );

        await _templateService.addTemplateDirect(template);
        templateCount++;
        for (var billJson in bills) {
          final currentMonthAmount = billJson['currentMonthAmount'] as double?;
          final fixedAmount = billJson['fixedAmount'] as double?;
          final amount = currentMonthAmount ?? fixedAmount;

          if (amount != null && amount > 0) {
            BillPaymentStatus status;
            final statusStr = billJson['status'] as String?;
            final isPaid = billJson['isPaid'] as bool? ?? false;

            if (statusStr == 'paid' || isPaid) {
              status = BillPaymentStatus.paid;
            } else if (statusStr == 'overdue') {
              status = BillPaymentStatus.overdue;
            } else {
              status = BillPaymentStatus.pending;
            }
            DateTime periodStart;
            DateTime periodEnd;
            DateTime dueDate;

            final dueDateStr = billJson['dueDate'];
            if (dueDateStr != null) {
              dueDate = _parseDateTime(dueDateStr);
              periodEnd = DateTime(dueDate.year, dueDate.month, dueDate.day);
              periodStart = DateTime(
                periodEnd.year,
                periodEnd.month - 1,
                periodEnd.day,
              );
            } else {
              final created = _parseDateTime(billJson['createdDate']);
              periodStart = DateTime(created.year, created.month, 1);
              periodEnd = DateTime(created.year, created.month + 1, 0);
              dueDate = periodEnd;
            }

            final payment = BillPayment(
              id: _uuid.v4(),
              templateId: template.id,
              amount: amount,
              dueDate: dueDate,
              periodStart: periodStart,
              periodEnd: periodEnd,
              status: status,
              paidDate: _parseDateTime(billJson['paidDate']),
              paidWithWalletId: billJson['autoPaymentWalletId'] as String?,
              transactionId:
                  (billJson['paymentIds'] as List?)?.isNotEmpty == true
                  ? (billJson['paymentIds'] as List).first as String
                  : null,
              notes: billJson['description'] as String?,
              createdDate: _parseDateTime(billJson['createdDate']),
              updatedDate: DateTime.now(),
            );

            await _paymentService.addPaymentDirect(payment);
            paymentCount++;
          }
        }
      }

      debugPrint(
        'Migration tamamlandı: $templateCount template, $paymentCount payment oluşturuldu',
      );
      await prefs.setString('bills_backup', jsonString);
      await prefs.remove('bills');
      await markMigrationCompleted();

      debugPrint('Bill migration başarıyla tamamlandı!');
    } catch (e, stackTrace) {
      debugPrint('Migration hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
  BillTemplateCategory _mapBillCategoryToTemplateCategory(String? oldCategory) {
    if (oldCategory == null) return BillTemplateCategory.other;

    switch (oldCategory) {
      case 'electricity':
        return BillTemplateCategory.electricity;
      case 'water':
        return BillTemplateCategory.water;
      case 'gas':
        return BillTemplateCategory.gas;
      case 'internet':
        return BillTemplateCategory.internet;
      case 'phone':
        return BillTemplateCategory.phone;
      case 'rent':
        return BillTemplateCategory.rent;
      case 'insurance':
        return BillTemplateCategory.insurance;
      case 'subscription':
        return BillTemplateCategory.subscription;
      default:
        return BillTemplateCategory.other;
    }
  }
  Future<void> rollbackMigration() async {
    final prefs = await SharedPreferences.getInstance();
    final backup = prefs.getString('bills_backup');
    if (backup != null) {
      await prefs.setString('bills', backup);
    }
    await _templateService.clearAllTemplates();
    await _paymentService.clearAllPayments();
    await prefs.remove(_migrationKey);

    debugPrint('Migration geri alındı');
  }
}
