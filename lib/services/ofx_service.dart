import 'dart:io';
import 'package:xml/xml.dart';
import '../models/transaction.dart';
import '../models/import_result.dart';
class OfxService {
  static final OfxService _instance = OfxService._internal();
  factory OfxService() => _instance;
  OfxService._internal();
  Future<ImportResult> importFromOfx({
    required String filePath,
    required String defaultWalletId,
    List<String>? existingTransactionIds,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final content = await file.readAsString();
    final document = XmlDocument.parse(content);

    final transactions = <Transaction>[];
    final errors = <ImportError>[];
    final duplicateIds = <String>{};
    int successCount = 0;
    int failureCount = 0;
    int rowNumber = 0;
    final transactionList = document.findAllElements('STMTTRN');

    for (var transactionElement in transactionList) {
      rowNumber++;

      try {
        final transaction = _parseOfxTransaction(
          transactionElement,
          defaultWalletId,
          rowNumber,
        );
        final fitId = _getElementText(transactionElement, 'FITID');
        if (fitId != null && existingTransactionIds != null) {
          if (existingTransactionIds.contains(fitId)) {
            duplicateIds.add(fitId);
            errors.add(
              ImportError(
                rowNumber: rowNumber,
                field: 'FITID',
                message: 'Duplicate transaction ID',
                value: fitId,
              ),
            );
            failureCount++;
            continue;
          }
        }

        if (_validateTransaction(transaction)) {
          transactions.add(transaction);
          successCount++;
        } else {
          errors.add(
            ImportError(
              rowNumber: rowNumber,
              field: 'Transaction',
              message: 'Invalid transaction data',
            ),
          );
          failureCount++;
        }
      } catch (e) {
        errors.add(
          ImportError(
            rowNumber: rowNumber,
            field: 'Transaction',
            message: 'Error parsing transaction: $e',
          ),
        );
        failureCount++;
      }
    }

    return ImportResult(
      successCount: successCount,
      failureCount: failureCount,
      errors: errors,
      importedTransactions: transactions,
    );
  }
  Transaction _parseOfxTransaction(
    XmlElement element,
    String walletId,
    int rowNumber,
  ) {
    final fitId = _getElementText(element, 'FITID');
    final dateStr = _getElementText(element, 'DTPOSTED');
    final amountStr = _getElementText(element, 'TRNAMT');
    final name = _getElementText(element, 'NAME');
    final memo = _getElementText(element, 'MEMO');
    final type = _getElementText(element, 'TRNTYPE');
    DateTime date;
    if (dateStr != null) {
      date = _parseOfxDate(dateStr);
    } else {
      throw FormatException('Missing date field');
    }
    double amount;
    if (amountStr != null) {
      amount = double.parse(amountStr);
    } else {
      throw FormatException('Missing amount field');
    }
    String transactionType;
    if (amount < 0) {
      transactionType = 'expense';
      amount = amount.abs();
    } else {
      transactionType = 'income';
    }
    final category = _mapOfxTypeToCategory(type);
    return Transaction(
      id: fitId ?? '${DateTime.now().millisecondsSinceEpoch}_$rowNumber',
      type: transactionType,
      amount: amount,
      description: name ?? memo ?? 'Imported transaction',
      category: category,
      walletId: walletId,
      date: date,
      memo: memo,
    );
  }
  String? _getElementText(XmlElement parent, String tagName) {
    try {
      final element = parent.findElements(tagName).firstOrNull;
      return element?.innerText.trim();
    } catch (e) {
      return null;
    }
  }
  DateTime _parseOfxDate(String dateStr) {
    final cleanDate = dateStr.substring(0, 8);

    final year = int.parse(cleanDate.substring(0, 4));
    final month = int.parse(cleanDate.substring(4, 6));
    final day = int.parse(cleanDate.substring(6, 8));

    return DateTime(year, month, day);
  }
  String _mapOfxTypeToCategory(String? ofxType) {
    if (ofxType == null) return 'Diğer';

    switch (ofxType.toUpperCase()) {
      case 'ATM':
        return 'Nakit Çekme';
      case 'CASH':
        return 'Nakit';
      case 'CHECK':
        return 'Çek';
      case 'CREDIT':
        return 'Kredi';
      case 'DEBIT':
        return 'Banka Kartı';
      case 'DEP':
      case 'DEPOSIT':
        return 'Maaş';
      case 'DIRECTDEP':
        return 'Maaş';
      case 'DIRECTDEBIT':
        return 'Otomatik Ödeme';
      case 'DIV':
        return 'Yatırım';
      case 'FEE':
        return 'Banka Masrafları';
      case 'INT':
        return 'Faiz';
      case 'OTHER':
        return 'Diğer';
      case 'PAYMENT':
        return 'Ödeme';
      case 'POS':
        return 'Alışveriş';
      case 'REPEATPMT':
        return 'Tekrarlayan Ödeme';
      case 'SRVCHG':
        return 'Hizmet Bedeli';
      case 'XFER':
        return 'Transfer';
      default:
        return 'Diğer';
    }
  }
  bool _validateTransaction(Transaction transaction) {
    return transaction.amount > 0 &&
        transaction.description.isNotEmpty &&
        transaction.category.isNotEmpty;
  }
}
