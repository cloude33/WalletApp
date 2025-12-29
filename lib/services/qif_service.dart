import 'dart:io';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/import_result.dart';
class QifService {
  static final QifService _instance = QifService._internal();
  factory QifService() => _instance;
  QifService._internal();
  Future<File> exportToQif({
    required List<Transaction> transactions,
    required List<Wallet> wallets,
    required String filePath,
  }) async {
    final buffer = StringBuffer();
    final transactionsByWallet = <String, List<Transaction>>{};
    for (var transaction in transactions) {
      transactionsByWallet
          .putIfAbsent(transaction.walletId, () => [])
          .add(transaction);
    }
    for (var entry in transactionsByWallet.entries) {
      final wallet = wallets.firstWhere(
        (w) => w.id == entry.key,
        orElse: () => wallets.first,
      );
      buffer.writeln('!Account');
      buffer.writeln('N${wallet.name}');
      buffer.writeln('T${_getAccountType(wallet.type)}');
      buffer.writeln('^');
      buffer.writeln('!Type:${_getTransactionType(wallet.type)}');
      for (var transaction in entry.value) {
        buffer.write(_formatQifTransaction(transaction));
      }
    }
    final file = File(filePath);
    await file.writeAsString(buffer.toString());
    return file;
  }
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

    Transaction? currentTransaction;
    int successCount = 0;
    int failureCount = 0;

    for (var line in lines) {
      lineNumber++;

      if (line.isEmpty) continue;
      if (line.startsWith('!Type:')) {
        continue;
      }

      if (line.startsWith('!Account')) {
        continue;
      }
      if (line.startsWith('D')) {
        try {
          final dateStr = line.substring(1);
          final date = _parseQifDate(dateStr);
          currentTransaction = Transaction(
            id: '${DateTime.now().millisecondsSinceEpoch}_$lineNumber',
            type: 'expense',
            amount: 0,
            description: '',
            category: 'Diğer',
            walletId: defaultWalletId,
            date: date,
          );
        } catch (e) {
          errors.add(
            ImportError(
              rowNumber: lineNumber,
              field: 'Date',
              message: 'Invalid date format',
              value: line.substring(1),
            ),
          );
          failureCount++;
        }
      } else if (line.startsWith('T')) {
        if (currentTransaction != null) {
          try {
            final amountStr = line.substring(1).replaceAll(',', '');
            final amount = double.parse(amountStr);
            currentTransaction = currentTransaction.copyWith(
              amount: amount.abs(),
              type: amount < 0 ? 'expense' : 'income',
            );
          } catch (e) {
            errors.add(
              ImportError(
                rowNumber: lineNumber,
                field: 'Amount',
                message: 'Invalid amount format',
                value: line.substring(1),
              ),
            );
          }
        }
      } else if (line.startsWith('P')) {
        if (currentTransaction != null) {
          currentTransaction = currentTransaction.copyWith(
            description: line.substring(1),
          );
        }
      } else if (line.startsWith('L')) {
        if (currentTransaction != null) {
          currentTransaction = currentTransaction.copyWith(
            category: line.substring(1),
          );
        }
      } else if (line.startsWith('M')) {
        if (currentTransaction != null) {
          currentTransaction = currentTransaction.copyWith(
            memo: line.substring(1),
          );
        }
      } else if (line == '^') {
        if (currentTransaction != null) {
          if (_validateTransaction(currentTransaction)) {
            transactions.add(currentTransaction);
            successCount++;
          } else {
            errors.add(
              ImportError(
                rowNumber: lineNumber,
                field: 'Transaction',
                message: 'Invalid transaction data',
              ),
            );
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
  String _formatQifTransaction(Transaction transaction) {
    final buffer = StringBuffer();
    buffer.writeln('D${_formatQifDate(transaction.date)}');
    final amount = transaction.type == 'expense'
        ? -transaction.amount
        : transaction.amount;
    buffer.writeln('T${amount.toStringAsFixed(2)}');
    buffer.writeln('P${transaction.description}');
    buffer.writeln('L${transaction.category}');
    if (transaction.memo != null && transaction.memo!.isNotEmpty) {
      buffer.writeln('M${transaction.memo}');
    }
    buffer.writeln('^');

    return buffer.toString();
  }
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
  String _formatQifDate(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }
  DateTime _parseQifDate(String dateStr) {
    try {
      return DateFormat('MM/dd/yyyy').parse(dateStr);
    } catch (e) {
      try {
        return DateFormat('M/d/yy').parse(dateStr);
      } catch (e) {
        try {
          return DateFormat('dd/MM/yyyy').parse(dateStr);
        } catch (e) {
          throw FormatException('Invalid date format: $dateStr');
        }
      }
    }
  }
  bool _validateTransaction(Transaction transaction) {
    return transaction.amount > 0 &&
        transaction.description.isNotEmpty &&
        transaction.category.isNotEmpty;
  }
}
