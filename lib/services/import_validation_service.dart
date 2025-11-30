import 'dart:io';
import '../models/transaction.dart';
import '../models/import_result.dart';

/// Import validation service
class ImportValidationService {
  static final ImportValidationService _instance =
      ImportValidationService._internal();
  factory ImportValidationService() => _instance;
  ImportValidationService._internal();

  /// Detect file format from extension
  String detectFileFormat(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'csv':
        return 'csv';
      case 'qif':
        return 'qif';
      case 'ofx':
      case 'qfx':
        return 'ofx';
      case 'xlsx':
      case 'xls':
        return 'excel';
      default:
        throw Exception('Unsupported file format: $extension');
    }
  }

  /// Validate file exists and is readable
  Future<bool> validateFile(String filePath) async {
    final file = File(filePath);
    
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    try {
      await file.readAsString();
      return true;
    } catch (e) {
      throw Exception('File is not readable: $e');
    }
  }

  /// Validate transaction data
  List<ImportError> validateTransaction(
    Transaction transaction,
    int rowNumber,
  ) {
    final errors = <ImportError>[];

    // Validate amount
    if (transaction.amount <= 0) {
      errors.add(ImportError(
        rowNumber: rowNumber,
        field: 'amount',
        message: 'Amount must be greater than 0',
        value: transaction.amount.toString(),
      ));
    }

    // Validate description
    if (transaction.description.isEmpty) {
      errors.add(ImportError(
        rowNumber: rowNumber,
        field: 'description',
        message: 'Description is required',
      ));
    }

    // Validate category
    if (transaction.category.isEmpty) {
      errors.add(ImportError(
        rowNumber: rowNumber,
        field: 'category',
        message: 'Category is required',
      ));
    }

    // Validate type
    if (transaction.type != 'income' && transaction.type != 'expense') {
      errors.add(ImportError(
        rowNumber: rowNumber,
        field: 'type',
        message: 'Type must be "income" or "expense"',
        value: transaction.type,
      ));
    }

    // Validate date
    final now = DateTime.now();
    final futureLimit = now.add(const Duration(days: 365));
    final pastLimit = now.subtract(const Duration(days: 365 * 10));

    if (transaction.date.isAfter(futureLimit)) {
      errors.add(ImportError(
        rowNumber: rowNumber,
        field: 'date',
        message: 'Date is too far in the future',
        value: transaction.date.toString(),
      ));
    }

    if (transaction.date.isBefore(pastLimit)) {
      errors.add(ImportError(
        rowNumber: rowNumber,
        field: 'date',
        message: 'Date is too far in the past',
        value: transaction.date.toString(),
      ));
    }

    return errors;
  }

  /// Validate batch of transactions
  ImportResult validateBatch(List<Transaction> transactions) {
    final errors = <ImportError>[];
    final validTransactions = <Transaction>[];
    int successCount = 0;
    int failureCount = 0;

    for (var i = 0; i < transactions.length; i++) {
      final transaction = transactions[i];
      final rowNumber = i + 1;

      final transactionErrors = validateTransaction(transaction, rowNumber);

      if (transactionErrors.isEmpty) {
        validTransactions.add(transaction);
        successCount++;
      } else {
        errors.addAll(transactionErrors);
        failureCount++;
      }
    }

    return ImportResult(
      successCount: successCount,
      failureCount: failureCount,
      errors: errors,
      importedTransactions: validTransactions,
    );
  }

  /// Check for duplicate transactions
  List<Transaction> detectDuplicates(
    List<Transaction> newTransactions,
    List<Transaction> existingTransactions,
  ) {
    final duplicates = <Transaction>[];

    for (var newTx in newTransactions) {
      for (var existingTx in existingTransactions) {
        if (_areTransactionsSimilar(newTx, existingTx)) {
          duplicates.add(newTx);
          break;
        }
      }
    }

    return duplicates;
  }

  /// Check if two transactions are similar (potential duplicates)
  bool _areTransactionsSimilar(Transaction tx1, Transaction tx2) {
    // Same date
    if (tx1.date.year != tx2.date.year ||
        tx1.date.month != tx2.date.month ||
        tx1.date.day != tx2.date.day) {
      return false;
    }

    // Same amount
    if ((tx1.amount - tx2.amount).abs() > 0.01) {
      return false;
    }

    // Same type
    if (tx1.type != tx2.type) {
      return false;
    }

    // Similar description (case-insensitive)
    final desc1 = tx1.description.toLowerCase().trim();
    final desc2 = tx2.description.toLowerCase().trim();
    
    if (desc1 == desc2) {
      return true;
    }

    // Check if one description contains the other
    if (desc1.contains(desc2) || desc2.contains(desc1)) {
      return true;
    }

    return false;
  }

  /// Generate error message summary
  String generateErrorSummary(List<ImportError> errors) {
    if (errors.isEmpty) {
      return 'No errors found';
    }

    final buffer = StringBuffer();
    buffer.writeln('Found ${errors.length} error(s):');
    buffer.writeln();

    // Group errors by row
    final errorsByRow = <int, List<ImportError>>{};
    for (var error in errors) {
      errorsByRow.putIfAbsent(error.rowNumber, () => []).add(error);
    }

    // Format errors
    for (var entry in errorsByRow.entries) {
      buffer.writeln('Row ${entry.key}:');
      for (var error in entry.value) {
        buffer.writeln('  - ${error.field}: ${error.message}');
        if (error.value != null) {
          buffer.writeln('    Value: ${error.value}');
        }
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
