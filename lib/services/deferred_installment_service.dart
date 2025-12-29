import 'package:uuid/uuid.dart';
import '../models/credit_card_transaction.dart';
import '../repositories/credit_card_transaction_repository.dart';
import '../exceptions/credit_card_exception.dart';
import '../exceptions/error_codes.dart';
import '../utils/service_error_handler.dart';
class DeferredInstallmentService {
  final CreditCardTransactionRepository _repo = CreditCardTransactionRepository();
  final Uuid _uuid = const Uuid();
  static const String _serviceName = 'DeferredInstallmentService';
  Future<CreditCardTransaction> createDeferredInstallment({
    required String cardId,
    required double amount,
    required String description,
    required int installmentCount,
    required int deferredMonths,
    String category = 'Genel',
  }) async {
    return await ServiceErrorHandler.execute(
      operation: () async {
        ServiceErrorHandler.validateNotEmpty(
          value: cardId,
          fieldName: 'Kart ID',
          errorCode: ErrorCodes.INVALID_CARD_DATA,
        );

        ServiceErrorHandler.validatePositive(
          value: amount,
          fieldName: 'Tutar',
          errorCode: ErrorCodes.INVALID_AMOUNT,
        );

        ServiceErrorHandler.validateNotEmpty(
          value: description,
          fieldName: 'Açıklama',
          errorCode: ErrorCodes.INVALID_INPUT,
        );

        ServiceErrorHandler.validateRange(
          value: installmentCount.toDouble(),
          min: 2,
          max: 36,
          fieldName: 'Taksit sayısı',
          errorCode: ErrorCodes.INVALID_INSTALLMENT_COUNT,
        );

        ServiceErrorHandler.validateRange(
          value: deferredMonths.toDouble(),
          min: 1,
          max: 12,
          fieldName: 'Erteleme süresi',
          errorCode: ErrorCodes.INVALID_DEFERRED_MONTHS,
        );

        final now = DateTime.now();
        final startDate = DateTime(
          now.year,
          now.month + deferredMonths,
          now.day,
        );

        final transaction = CreditCardTransaction(
          id: _uuid.v4(),
          cardId: cardId,
          amount: amount,
          description: description,
          transactionDate: now,
          category: category,
          installmentCount: installmentCount,
          installmentsPaid: 0,
          createdAt: now,
          deferredMonths: deferredMonths,
          installmentStartDate: startDate,
          isCashAdvance: false,
        );
        final validationError = transaction.validate();
        if (validationError != null) {
          throw CreditCardException(
            validationError,
            ErrorCodes.INVALID_TRANSACTION,
            {
              'cardId': cardId,
              'amount': amount,
              'installmentCount': installmentCount,
              'deferredMonths': deferredMonths,
            },
          );
        }
        await _repo.save(transaction);
        return transaction;
      },
      serviceName: _serviceName,
      operationName: 'createDeferredInstallment',
      errorCode: ErrorCodes.SAVE_FAILED,
      errorMessage: 'Ertelenmiş taksit oluşturulamadı',
    );
  }
  Future<List<CreditCardTransaction>> getDeferredInstallments(String cardId) async {
    final transactions = await _repo.findByCardId(cardId);
    return transactions
        .where((t) => t.isDeferred && !t.isCompleted)
        .toList();
  }
  Future<List<CreditCardTransaction>> getAllDeferredInstallments() async {
    final transactions = await _repo.findAllActiveInstallments();
    return transactions
        .where((t) => t.isDeferred)
        .toList();
  }
  Future<List<CreditCardTransaction>> getInstallmentsStartingThisMonth([String? cardId]) async {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);

    List<CreditCardTransaction> transactions;
    if (cardId != null) {
      transactions = await getDeferredInstallments(cardId);
    } else {
      transactions = await getAllDeferredInstallments();
    }

    return transactions.where((t) {
      final startDate = t.installmentStartDate;
      if (startDate == null) return false;
      
      return startDate.isAfter(currentMonth.subtract(const Duration(days: 1))) &&
             startDate.isBefore(nextMonth);
    }).toList();
  }
  Future<Map<DateTime, List<CreditCardTransaction>>> getDeferredInstallmentSchedule(String cardId) async {
    final deferredInstallments = await getDeferredInstallments(cardId);
    final schedule = <DateTime, List<CreditCardTransaction>>{};

    for (var transaction in deferredInstallments) {
      final startDate = transaction.installmentStartDate;
      if (startDate == null) continue;
      final monthKey = DateTime(startDate.year, startDate.month, 1);
      
      if (!schedule.containsKey(monthKey)) {
        schedule[monthKey] = [];
      }
      schedule[monthKey]!.add(transaction);
    }

    return schedule;
  }
  Future<double> getTotalDeferredAmount(String cardId) async {
    final deferredInstallments = await getDeferredInstallments(cardId);
    return deferredInstallments.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );
  }
  Future<int> getDeferredInstallmentCount(String cardId) async {
    final deferredInstallments = await getDeferredInstallments(cardId);
    return deferredInstallments.length;
  }
  Future<List<String>> activateDeferredInstallments([DateTime? currentDate]) async {
    final checkDate = currentDate ?? DateTime.now();
    final allDeferred = await getAllDeferredInstallments();
    final activatedIds = <String>[];

    for (var transaction in allDeferred) {
      final startDate = transaction.installmentStartDate;
      if (startDate == null) continue;
      if (startDate.isBefore(checkDate) || 
          startDate.isAtSameMomentAs(checkDate) ||
          (startDate.year == checkDate.year && 
           startDate.month == checkDate.month)) {
        activatedIds.add(transaction.id);
      }
    }

    return activatedIds;
  }
  Future<bool> isInstallmentActive(String transactionId, [DateTime? currentDate]) async {
    final transaction = await _repo.findById(transactionId);
    if (transaction == null) {
      throw Exception('İşlem bulunamadı');
    }

    if (!transaction.isDeferred) {
      return true;
    }

    final checkDate = currentDate ?? DateTime.now();
    final startDate = transaction.installmentStartDate;
    if (startDate == null) return false;
    return startDate.isBefore(checkDate) || 
           startDate.isAtSameMomentAs(checkDate) ||
           (startDate.year == checkDate.year && 
            startDate.month == checkDate.month);
  }
  Future<int> getMonthsUntilStart(String transactionId, [DateTime? currentDate]) async {
    final transaction = await _repo.findById(transactionId);
    if (transaction == null) {
      throw Exception('İşlem bulunamadı');
    }

    if (!transaction.isDeferred) {
      return 0;
    }

    final checkDate = currentDate ?? DateTime.now();
    final startDate = transaction.installmentStartDate;
    if (startDate == null) return 0;
    if (startDate.isBefore(checkDate) || startDate.isAtSameMomentAs(checkDate)) {
      return 0;
    }
    final monthDiff = (startDate.year - checkDate.year) * 12 + 
                      (startDate.month - checkDate.month);
    
    return monthDiff > 0 ? monthDiff : 0;
  }
  Future<List<CreditCardTransaction>> getInstallmentsEndingSoon({
    String? cardId,
    int withinMonths = 2,
  }) async {
    List<CreditCardTransaction> transactions;
    if (cardId != null) {
      transactions = await getDeferredInstallments(cardId);
    } else {
      transactions = await getAllDeferredInstallments();
    }

    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month + withinMonths, now.day);

    return transactions.where((t) {
      if (t.isCompleted) return false;
      
      final startDate = t.installmentStartDate ?? t.transactionDate;
      final remainingMonths = t.remainingInstallments;
      final lastPaymentDate = DateTime(
        startDate.year,
        startDate.month + remainingMonths,
        startDate.day,
      );

      return lastPaymentDate.isBefore(endDate) || 
             lastPaymentDate.isAtSameMomentAs(endDate);
    }).toList();
  }
}
