import '../models/credit_card_transaction.dart';
import '../repositories/credit_card_transaction_repository.dart';
import '../repositories/credit_card_repository.dart';

class InstallmentTrackerService {
  final CreditCardTransactionRepository _transactionRepo =
      CreditCardTransactionRepository();
  final CreditCardRepository _cardRepo = CreditCardRepository();
  Future<List<CreditCardTransaction>> getActiveInstallments(
    String cardId,
  ) async {
    return await _transactionRepo.findActiveInstallments(cardId);
  }
  Future<List<CreditCardTransaction>> getAllActiveInstallments() async {
    return await _transactionRepo.findAllActiveInstallments();
  }
  Future<Map<DateTime, double>> getFutureInstallmentProjection(
    String cardId,
    int months,
  ) async {
    final activeInstallments = await getActiveInstallments(cardId);
    final projection = <DateTime, double>{};
    final now = DateTime.now();
    for (int i = 0; i < months; i++) {
      final month = DateTime(now.year, now.month + i, 1);
      projection[month] = 0;
    }
    for (var transaction in activeInstallments) {
      final remainingInstallments = transaction.remainingInstallments;
      final installmentAmount = transaction.installmentAmount;
      for (int i = 0; i < remainingInstallments && i < months; i++) {
        final month = DateTime(now.year, now.month + i, 1);
        projection[month] = (projection[month] ?? 0) + installmentAmount;
      }
    }

    return projection;
  }
  Future<Map<DateTime, double>> getAllCardsFutureProjection(int months) async {
    final cards = await _cardRepo.findActive();
    final projection = <DateTime, double>{};
    final now = DateTime.now();
    for (int i = 0; i < months; i++) {
      final month = DateTime(now.year, now.month + i, 1);
      projection[month] = 0;
    }
    for (var card in cards) {
      final cardProjection = await getFutureInstallmentProjection(
        card.id,
        months,
      );

      for (var entry in cardProjection.entries) {
        projection[entry.key] = (projection[entry.key] ?? 0) + entry.value;
      }
    }

    return projection;
  }
  Future<Map<String, dynamic>> getDetailedFutureProjection(int months) async {
    final cards = await _cardRepo.findActive();
    final cardProjections = <String, Map<DateTime, double>>{};
    final totalProjection = <DateTime, double>{};
    final now = DateTime.now();
    for (int i = 0; i < months; i++) {
      final month = DateTime(now.year, now.month + i, 1);
      totalProjection[month] = 0;
    }
    for (var card in cards) {
      final projection = await getFutureInstallmentProjection(card.id, months);
      cardProjections[card.id] = projection;
      for (var entry in projection.entries) {
        totalProjection[entry.key] =
            (totalProjection[entry.key] ?? 0) + entry.value;
      }
    }

    return {
      'totalProjection': totalProjection,
      'cardProjections': cardProjections,
      'cards': cards,
    };
  }
  Future<void> incrementInstallmentCounter(String transactionId) async {
    final transaction = await _transactionRepo.findById(transactionId);
    if (transaction == null) {
      throw Exception('İşlem bulunamadı');
    }

    if (transaction.isCompleted) {
      throw Exception('Taksitler zaten tamamlanmış');
    }

    final updatedTransaction = transaction.copyWith(
      installmentsPaid: transaction.installmentsPaid + 1,
    );

    await _transactionRepo.update(updatedTransaction);
  }
  Future<void> processInstallmentsForStatement(
    String cardId,
    DateTime statementDate,
  ) async {
    final allTransactions = await _transactionRepo.findByCardId(cardId);
    final installmentTransactions = allTransactions.where(
      (t) =>
          t.installmentCount > 1 &&
          !t.isCompleted &&
          t.transactionDate.isBefore(
            statementDate.add(const Duration(days: 1)),
          ),
    );

    for (var transaction in installmentTransactions) {
      await incrementInstallmentCounter(transaction.id);
    }
  }
  Future<double> getTotalRemainingInstallments(String cardId) async {
    final activeInstallments = await getActiveInstallments(cardId);
    return activeInstallments.fold<double>(
      0,
      (sum, t) => sum + t.remainingAmount,
    );
  }
  Future<int> getActiveInstallmentCount(String cardId) async {
    final activeInstallments = await getActiveInstallments(cardId);
    return activeInstallments.length;
  }
  Future<Map<String, dynamic>> getInstallmentSummary(String cardId) async {
    final activeInstallments = await getActiveInstallments(cardId);

    if (activeInstallments.isEmpty) {
      return {
        'activeCount': 0,
        'totalRemaining': 0.0,
        'monthlyAverage': 0.0,
        'installments': <CreditCardTransaction>[],
      };
    }

    final totalRemaining = activeInstallments.fold<double>(
      0,
      (sum, t) => sum + t.remainingAmount,
    );
    final projection = await getFutureInstallmentProjection(cardId, 12);
    final monthlyAverage = projection.values.isNotEmpty
        ? projection.values.reduce((a, b) => a + b) / projection.length
        : 0.0;

    return {
      'activeCount': activeInstallments.length,
      'totalRemaining': totalRemaining,
      'monthlyAverage': monthlyAverage,
      'installments': activeInstallments,
    };
  }
  Future<Map<String, dynamic>> getInstallmentDetails(
    String transactionId,
  ) async {
    final transaction = await _transactionRepo.findById(transactionId);
    if (transaction == null) {
      throw Exception('İşlem bulunamadı');
    }

    if (transaction.installmentCount <= 1) {
      throw Exception('Bu işlem taksitli değil');
    }
    final schedule = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 0; i < transaction.installmentCount; i++) {
      final isPaid = i < transaction.installmentsPaid;
      final monthOffset = i - transaction.installmentsPaid;
      final paymentDate = DateTime(
        now.year,
        now.month + monthOffset,
        transaction.transactionDate.day,
      );

      schedule.add({
        'installmentNumber': i + 1,
        'amount': transaction.installmentAmount,
        'isPaid': isPaid,
        'paymentDate': paymentDate,
        'status': isPaid ? 'paid' : (monthOffset == 0 ? 'current' : 'future'),
      });
    }

    return {
      'transaction': transaction,
      'totalAmount': transaction.amount,
      'installmentAmount': transaction.installmentAmount,
      'totalInstallments': transaction.installmentCount,
      'paidInstallments': transaction.installmentsPaid,
      'remainingInstallments': transaction.remainingInstallments,
      'remainingAmount': transaction.remainingAmount,
      'schedule': schedule,
    };
  }
  Future<Map<String, List<CreditCardTransaction>>> getInstallmentsByMonth(
    String cardId,
  ) async {
    final activeInstallments = await getActiveInstallments(cardId);
    final grouped = <String, List<CreditCardTransaction>>{};
    final now = DateTime.now();

    for (var transaction in activeInstallments) {
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(monthKey, () => []).add(transaction);
    }

    return grouped;
  }
  Future<DateTime?> calculatePayoffDate(String cardId) async {
    final activeInstallments = await getActiveInstallments(cardId);

    if (activeInstallments.isEmpty) {
      return null;
    }
    int maxRemainingMonths = 0;

    for (var transaction in activeInstallments) {
      if (transaction.remainingInstallments > maxRemainingMonths) {
        maxRemainingMonths = transaction.remainingInstallments;
      }
    }

    final now = DateTime.now();
    return DateTime(now.year, now.month + maxRemainingMonths, now.day);
  }
  Future<Map<String, dynamic>> getInstallmentStatistics(String cardId) async {
    final allTransactions = await _transactionRepo.findByCardId(cardId);

    final installmentTransactions = allTransactions.where(
      (t) => t.installmentCount > 1,
    );
    final completedInstallments = installmentTransactions.where(
      (t) => t.isCompleted,
    );
    final activeInstallments = installmentTransactions.where(
      (t) => !t.isCompleted,
    );

    final totalInstallmentPurchases = installmentTransactions.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );

    final totalPaid = installmentTransactions.fold<double>(
      0,
      (sum, t) => sum + (t.installmentAmount * t.installmentsPaid),
    );

    final totalRemaining = activeInstallments.fold<double>(
      0,
      (sum, t) => sum + t.remainingAmount,
    );

    return {
      'totalInstallmentTransactions': installmentTransactions.length,
      'completedInstallments': completedInstallments.length,
      'activeInstallments': activeInstallments.length,
      'totalInstallmentPurchases': totalInstallmentPurchases,
      'totalPaid': totalPaid,
      'totalRemaining': totalRemaining,
      'payoffDate': await calculatePayoffDate(cardId),
    };
  }
  Future<Map<String, dynamic>> compareInstallmentVsCash(String cardId) async {
    final allTransactions = await _transactionRepo.findByCardId(cardId);

    final cashPurchases = allTransactions.where((t) => t.installmentCount == 1);
    final installmentPurchases = allTransactions.where(
      (t) => t.installmentCount > 1,
    );

    final cashTotal = cashPurchases.fold<double>(0, (sum, t) => sum + t.amount);
    final installmentTotal = installmentPurchases.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );
    final grandTotal = cashTotal + installmentTotal;

    final cashPercentage = grandTotal > 0 ? (cashTotal / grandTotal) * 100 : 0;
    final installmentPercentage = grandTotal > 0
        ? (installmentTotal / grandTotal) * 100
        : 0;

    return {
      'cashCount': cashPurchases.length,
      'cashTotal': cashTotal,
      'cashPercentage': cashPercentage,
      'installmentCount': installmentPurchases.length,
      'installmentTotal': installmentTotal,
      'installmentPercentage': installmentPercentage,
      'grandTotal': grandTotal,
    };
  }
}
