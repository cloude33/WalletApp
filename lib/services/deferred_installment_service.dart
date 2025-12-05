import 'package:uuid/uuid.dart';
import '../models/credit_card_transaction.dart';
import '../repositories/credit_card_transaction_repository.dart';
import '../exceptions/credit_card_exception.dart';
import '../exceptions/error_codes.dart';
import '../utils/service_error_handler.dart';

/// Service for managing deferred installment transactions
/// 
/// Deferred installments are installment transactions where the first payment
/// starts after a specified number of months (e.g., 3 months deferred, 6 installments)
class DeferredInstallmentService {
  final CreditCardTransactionRepository _repo = CreditCardTransactionRepository();
  final Uuid _uuid = const Uuid();
  static const String _serviceName = 'DeferredInstallmentService';

  // ==================== ERTELENMIŞ TAKSİT OLUŞTURMA ====================

  /// Create a deferred installment transaction
  /// 
  /// [cardId] - The credit card ID
  /// [amount] - Total transaction amount
  /// [description] - Transaction description
  /// [installmentCount] - Number of installments
  /// [deferredMonths] - Number of months to defer the first payment
  /// [category] - Transaction category (default: 'Genel')
  /// 
  /// Returns the created transaction
  /// 
  /// Throws [CreditCardException] if validation fails
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
        // Validate inputs
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
        
        // Calculate installment start date (deferred by specified months)
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

        // Validate the transaction
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

        // Save the transaction
        await _repo.save(transaction);
        return transaction;
      },
      serviceName: _serviceName,
      operationName: 'createDeferredInstallment',
      errorCode: ErrorCodes.SAVE_FAILED,
      errorMessage: 'Ertelenmiş taksit oluşturulamadı',
    );
  }

  // ==================== ERTELENMIŞ TAKSİT SORGULAMA ====================

  /// Get all deferred installments for a specific card
  /// 
  /// Returns list of transactions that have deferred months > 0
  Future<List<CreditCardTransaction>> getDeferredInstallments(String cardId) async {
    final transactions = await _repo.findByCardId(cardId);
    return transactions
        .where((t) => t.isDeferred && !t.isCompleted)
        .toList();
  }

  /// Get all deferred installments across all cards
  Future<List<CreditCardTransaction>> getAllDeferredInstallments() async {
    final transactions = await _repo.findAllActiveInstallments();
    return transactions
        .where((t) => t.isDeferred)
        .toList();
  }

  /// Get deferred installments that start in the current month
  /// 
  /// [cardId] - Optional card ID to filter by specific card
  /// 
  /// Returns list of deferred installments starting this month
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

  /// Get deferred installment schedule for a card
  /// 
  /// Returns a map of DateTime (month) to list of transactions starting that month
  Future<Map<DateTime, List<CreditCardTransaction>>> getDeferredInstallmentSchedule(String cardId) async {
    final deferredInstallments = await getDeferredInstallments(cardId);
    final schedule = <DateTime, List<CreditCardTransaction>>{};

    for (var transaction in deferredInstallments) {
      final startDate = transaction.installmentStartDate;
      if (startDate == null) continue;

      // Normalize to first day of month
      final monthKey = DateTime(startDate.year, startDate.month, 1);
      
      if (!schedule.containsKey(monthKey)) {
        schedule[monthKey] = [];
      }
      schedule[monthKey]!.add(transaction);
    }

    return schedule;
  }

  /// Get total deferred amount for a card
  /// 
  /// Returns the sum of all deferred installment amounts
  Future<double> getTotalDeferredAmount(String cardId) async {
    final deferredInstallments = await getDeferredInstallments(cardId);
    return deferredInstallments.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );
  }

  /// Get count of deferred installments for a card
  Future<int> getDeferredInstallmentCount(String cardId) async {
    final deferredInstallments = await getDeferredInstallments(cardId);
    return deferredInstallments.length;
  }

  // ==================== ERTELENMIŞ TAKSİT AKTİVASYONU ====================

  /// Activate deferred installments that should start on or before the current date
  /// 
  /// This method should be called periodically (e.g., daily) to check if any
  /// deferred installments should start their payment schedule.
  /// 
  /// [currentDate] - The date to check against (defaults to now)
  /// 
  /// Returns list of activated transaction IDs
  Future<List<String>> activateDeferredInstallments([DateTime? currentDate]) async {
    final checkDate = currentDate ?? DateTime.now();
    final allDeferred = await getAllDeferredInstallments();
    final activatedIds = <String>[];

    for (var transaction in allDeferred) {
      final startDate = transaction.installmentStartDate;
      if (startDate == null) continue;

      // Check if the start date has arrived or passed
      if (startDate.isBefore(checkDate) || 
          startDate.isAtSameMomentAs(checkDate) ||
          (startDate.year == checkDate.year && 
           startDate.month == checkDate.month)) {
        
        // The installment is now active - no need to update the transaction
        // as it's already marked with the correct start date
        // This method is mainly for querying which installments are now active
        activatedIds.add(transaction.id);
      }
    }

    return activatedIds;
  }

  /// Check if a deferred installment is active (payment period has started)
  /// 
  /// [transactionId] - The transaction ID to check
  /// [currentDate] - The date to check against (defaults to now)
  /// 
  /// Returns true if the installment payment period has started
  Future<bool> isInstallmentActive(String transactionId, [DateTime? currentDate]) async {
    final transaction = await _repo.findById(transactionId);
    if (transaction == null) {
      throw Exception('İşlem bulunamadı');
    }

    if (!transaction.isDeferred) {
      // Non-deferred installments are always active
      return true;
    }

    final checkDate = currentDate ?? DateTime.now();
    final startDate = transaction.installmentStartDate;
    if (startDate == null) return false;

    // Check if start date has arrived
    return startDate.isBefore(checkDate) || 
           startDate.isAtSameMomentAs(checkDate) ||
           (startDate.year == checkDate.year && 
            startDate.month == checkDate.month);
  }

  /// Get months until installment starts
  /// 
  /// [transactionId] - The transaction ID
  /// [currentDate] - The date to check against (defaults to now)
  /// 
  /// Returns number of months until the installment starts (0 if already started)
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

    // If already started, return 0
    if (startDate.isBefore(checkDate) || startDate.isAtSameMomentAs(checkDate)) {
      return 0;
    }

    // Calculate month difference
    final monthDiff = (startDate.year - checkDate.year) * 12 + 
                      (startDate.month - checkDate.month);
    
    return monthDiff > 0 ? monthDiff : 0;
  }

  /// Get deferred installments ending soon (within specified months)
  /// 
  /// [cardId] - Optional card ID to filter by specific card
  /// [withinMonths] - Number of months to look ahead (default: 2)
  /// 
  /// Returns list of installments that will complete within the specified period
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
      
      // Calculate when the last installment will be paid
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
