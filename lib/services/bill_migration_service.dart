import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/bill_template.dart';
import '../models/bill_payment.dart';
import 'bill_template_service.dart';
import 'bill_payment_service.dart';

/// Eski Bill modelinden yeni BillTemplate + BillPayment yapısına geçiş servisi
class BillMigrationService {
  static final BillMigrationService _instance = BillMigrationService._internal();
  factory BillMigrationService() => _instance;
  BillMigrationService._internal();

  final Uuid _uuid = const Uuid();
  final BillTemplateService _templateService = BillTemplateService();
  final BillPaymentService _paymentService = BillPaymentService();

  static const String _migrationKey = 'bill_migration_completed';

  /// Migration yapılmış mı kontrol et
  Future<bool> isMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationKey) ?? false;
  }

  /// Migration'ı tamamlandı olarak işaretle
  Future<void> markMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, true);
  }

  /// Eski Bill verilerini yeni yapıya migrate et
  Future<void> migrateBills() async {
    try {
      // Zaten migrate edilmiş mi kontrol et
      if (await isMigrationCompleted()) {
        debugPrint('Migration zaten tamamlanmış, atlanıyor');
        return;
      }

      debugPrint('Bill migration başlatılıyor...');

      // Eski bill verilerini oku
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('bills');
      
      if (jsonString == null || jsonString.isEmpty) {
        debugPrint('Migrate edilecek bill verisi bulunamadı');
        await markMigrationCompleted();
        return;
      }

      // Eski bill verilerini parse et (dynamic olarak)
      final List<dynamic> oldBillsJson = jsonDecode(jsonString) as List<dynamic>;

      debugPrint('${oldBillsJson.length} adet bill bulundu');

      // Benzersiz fatura tanımlarını grupla (aynı name + provider)
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

      // Her grup için template ve payment oluştur
      for (var entry in groupedBills.entries) {
        final bills = entry.value;
        final firstBill = bills.first;

        // 1. BillTemplate oluştur
        final template = BillTemplate(
          id: _uuid.v4(),
          name: firstBill['name'] as String? ?? 'Bilinmeyen',
          provider: firstBill['provider'] as String?,
          category: _mapBillCategoryToTemplateCategory(firstBill['category'] as String?),
          accountNumber: firstBill['accountNumber'] as String?,
          phoneNumber: firstBill['phoneNumber'] as String?,
          description: firstBill['description'] as String?,
          isActive: true,
          createdDate: _parseDateTime(firstBill['createdDate']),
          updatedDate: DateTime.now(),
        );

        await _templateService.addTemplateDirect(template);
        templateCount++;

        // 2. Her bill için BillPayment oluştur (eğer tutar varsa)
        for (var billJson in bills) {
          final currentMonthAmount = billJson['currentMonthAmount'] as double?;
          final fixedAmount = billJson['fixedAmount'] as double?;
          final amount = currentMonthAmount ?? fixedAmount;
          
          if (amount != null && amount > 0) {
            // Ödeme durumunu belirle
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

            // Dönem tarihlerini belirle
            DateTime periodStart;
            DateTime periodEnd;
            DateTime dueDate;

            final dueDateStr = billJson['dueDate'];
            if (dueDateStr != null) {
              dueDate = _parseDateTime(dueDateStr);
              // Vade tarihinden dönemi tahmin et
              periodEnd = DateTime(dueDate.year, dueDate.month, dueDate.day);
              periodStart = DateTime(periodEnd.year, periodEnd.month - 1, periodEnd.day);
            } else {
              // Vade tarihi yoksa, oluşturulma tarihini kullan
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
              transactionId: (billJson['paymentIds'] as List?)?.isNotEmpty == true 
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

      debugPrint('Migration tamamlandı: $templateCount template, $paymentCount payment oluşturuldu');

      // Eski bill verilerini yedekle
      await prefs.setString('bills_backup', jsonString);
      
      // Eski bill verilerini temizle
      await prefs.remove('bills');

      // Migration'ı tamamlandı olarak işaretle
      await markMigrationCompleted();

      debugPrint('Bill migration başarıyla tamamlandı!');
    } catch (e, stackTrace) {
      debugPrint('Migration hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// DateTime parse helper
  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  /// Eski BillCategory string'ini yeni BillTemplateCategory'ye map et
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

  /// Migration'ı geri al (sadece test için)
  Future<void> rollbackMigration() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Yedekten geri yükle
    final backup = prefs.getString('bills_backup');
    if (backup != null) {
      await prefs.setString('bills', backup);
    }

    // Yeni verileri temizle
    await _templateService.clearAllTemplates();
    await _paymentService.clearAllPayments();

    // Migration flag'ini sıfırla
    await prefs.remove(_migrationKey);

    debugPrint('Migration geri alındı');
  }
}
