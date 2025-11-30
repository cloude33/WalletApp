import 'dart:io';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/import_result.dart';

/// QIF (Quicken Interchange Format) import/export service
class QifService {
  static final QifService _instance = QifService._internal();
  factory QifService() => _instance;
  QifService._internal();

  /// Export transactions to QIF format
  Future<File> exportToQif({
    required List<Transaction> transactions,
    required List<Wallet> wallets,
    required String filePath,
  }) async {
    final buffer = StringBuffer();

    // Group transactions by wallet
    final transactionsByWallet = <String, List<Transaction>>{};
    for (var transaction in transactions) {
      transactionsByWallet.putIfAbsent(transaction.walletId, () => []).add(transaction);
    }

    // Export each wallet's transactions
    for (var entry in transactionsByWallet.entries) {
      final wallet = wallets.firstWhere(
        (w) => w.id == entry.key,
        orElse: () => wallets.first,
      );

      // Account header
      buffer.writeln('!Account');
      buffer.writeln('N${wallet.name}');
      buffer.writeln('T${_getAccountType(wallet.type)}');
      buffer.writeln('^');

      // Transaction type header
      buffer.writeln('!Type:${_getTransactionType(wallet.type)}');

      // Export transactions
      for (var transaction in entry.value) {
        buffer.write(_formatQifTransaction(transaction));
      }
    }

    // Write to file
    final file = File(filePath);
    await file.writeAsString(buffer.toString());
    return file;
  }

  /// Import transactions from QIF format
  Future<ImportResult> importFromQif({
    required String filePath,
    required String defaultWalletId,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final content = await file.readAsString();
    final lines = content.split('\n').map((l) => l.trim()).toList();

    final transactions = <Transaction>[];
    final errors = <ImportError>[];
    int lineNumber = 0;
    String? currentAccountType;

    Transaction? currentTransaction;
    int successCount = 0;
    int failureCount = 0;

    for (var line in lines) {
      lineNumber++;

      if (line.isEmpty) continue;

      // Check for headers
      if (line.startsWith('!Type:')) {
        currentAccountType = line.substring(6);
        continue;
      }

      if (line.startsWith('!Account')) {
        continue;
      }

      // Parse transaction fields
      if (line.startsWith('D')) {
        // Date
        try {
          final dateStr = line.substring(1);
          final date = _parseQifDate(dateStr);
          currentTransaction = Transaction(
            id: DateTime.now().millisecondsSinceEpoch.toString() + '_$lineNumber',
            type: 'expense',
            amount: 0,
            description: '',
            category: 'Diğer',
            walletId: defaultWalletId,
            date: date,
          );
        } catch (e) {
          errors.add(ImportError(
            rowNumber: lineNumber,
            field: 'Date',
            message: 'Invalid date format',
            value: line.substring(1),
          ));
          failureCount++;
        }
      } else if (line.startsWith('T')) {
        // Amount
        if (currentTransaction != null) {
          try {
            final amountStr = line.substring(1).replaceAll(',', '');
            final amount = double.parse(amountStr);
            currentTransaction = currentTransaction.copyWith(
              amount: amount.abs(),
              type: amount < 0 ? 'expense' : 'income',
            );
          } catch (e) {
            errors.add(ImportError(
              rowNumber: lineNumber,
              field: 'Amount',
              message: 'Invalid amount format',
              value: line.substring(1),
            ));
          }
        }
      } else if (line.startsWith('P')) {
        // Payee/Description
        if (currentTransaction != null) {
          currentTransaction = currentTransaction.copyWith(
            description: line.substring(1),
          );
        }
      } else if (line.startsWith('L')) {
        // Category
        if (currentTransaction != null) {
          currentTransaction = currentTransaction.copyWith(
            category: line.substring(1),
          );
        }
      } else if (line.startsWith('M')) {
        // Memo
        if (currentTransaction != null) {
          currentTransaction = currentTransaction.copyWith(
            memo: line.substring(1),
          );
        }
      } else if (line == '^') {
        // End of transaction
        if (currentTransaction != null) {
          // Validate transaction
          if (_validateTransaction(currentTransaction)) {
            transactions.add(currentTransaction);
            successCount++;
          } else {
            errors.add(ImportError(
              rowNumber: lineNumber,
              field: 'Transaction',
              message: 'Invalid transaction data',
            ));
            failureCount++;
          }
          currentTransaction = null;
        }
      }
    }

    return ImportResult(
      successCount: successCount,
      failureCount: failureCount,
      errors: errors,
      importedTransactions: transactions,
    );
  }

  /// Format a transaction in QIF format
  String _formatQifTransaction(Transaction transaction) {
    final buffer = StringBuffer();

    // Date
    buffer.writeln('D${_formatQifDate(transaction.date)}');

    // Amount (negative for expenses)
    final amount = transaction.type == 'expense' ? -transaction.amount : transaction.amount;
    buffer.writeln('T${amount.toStringAsFixed(2)}');

    // Payee/Description
    buffer.writeln('P${transaction.description}');

    // Category
    buffer.writeln('L${transaction.category}');

    // Memo
    if (transaction.memo != null && transaction.memo!.isNotEmpty) {
      buffer.writeln('M${transaction.memo}');
    }

    // End of transaction
    buffer.writeln('^');

    return buffer.toString();
  }

  /// Get QIF account type from wallet type
  String _getAccountType(String walletType) {
    switch (walletType) {
      case 'bank':
        return 'Bank';
      case 'credit_card':
        return 'CCard';
      case 'cash':
        return 'Cash';
      case 'investment':
        return 'Invst';
      default:
        return 'Bank';
    }
  }

  /// Get QIF transaction type from wallet type
  String _getTransactionType(String walletType) {
    switch (walletType) {
      case 'bank':
        return 'Bank';
      case 'credit_card':
        return 'CCard';
      case 'cash':
        return 'Cash';
      default:
        return 'Bank';
    }
  }

  /// Format date in QIF format (MM/DD/YYYY)
  String _formatQifDate(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }

  /// Parse QIF date format
  DateTime _parseQifDate(String dateStr) {
    // QIF supports multiple date formats
    // Try MM/DD/YYYY
    try {
      return DateFormat('MM/dd/yyyy').parse(dateStr);
    } catch (e) {
      // Try M/D/YY
      try {
        return DateFormat('M/d/yy').parse(dateStr);
      } catch (e) {
        // Try DD/MM/YYYY
        try {
          return DateFormat('dd/MM/yyyy').parse(dateStr);
        } catch (e) {
          throw FormatException('Invalid date format: $dateStr');
        }
      }
    }
  }

  /// Validate transaction data
  bool _validateTransaction(Transaction transaction) {
    return transaction.amount > 0 &&
           transaction.description.isNotEmpty &&
           transaction.category.isNotEmpty;
  }
}
