import 'dart:io';
import 'package:xml/xml.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/import_result.dart';

/// OFX (Open Financial Exchange) import service
class OfxService {
  static final OfxService _instance = OfxService._internal();
  factory OfxService() => _instance;
  OfxService._internal();

  /// Import transactions from OFX format
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
    
    // Parse XML
    final document = XmlDocument.parse(content);
    
    final transactions = <Transaction>[];
    final errors = <ImportError>[];
    final duplicateIds = <String>{};
    int successCount = 0;
    int failureCount = 0;
    int rowNumber = 0;

    // Find transaction list
    final transactionList = document.findAllElements('STMTTRN');

    for (var transactionElement in transactionList) {
      rowNumber++;

      try {
        final transaction = _parseOfxTransaction(
          transactionElement,
          defaultWalletId,
          rowNumber,
        );

        // Check for duplicates
        final fitId = _getElementText(transactionElement, 'FITID');
        if (fitId != null && existingTransactionIds != null) {
          if (existingTransactionIds.contains(fitId)) {
            duplicateIds.add(fitId);
            errors.add(ImportError(
              rowNumber: rowNumber,
              field: 'FITID',
              message: 'Duplicate transaction ID',
              value: fitId,
            ));
            failureCount++;
            continue;
          }
        }

        if (_validateTransaction(transaction)) {
          transactions.add(transaction);
          successCount++;
        } else {
          errors.add(ImportError(
            rowNumber: rowNumber,
            field: 'Transaction',
            message: 'Invalid transaction data',
          ));
          failureCount++;
        }
      } catch (e) {
        errors.add(ImportError(
          rowNumber: rowNumber,
          field: 'Transaction',
          message: 'Error parsing transaction: $e',
        ));
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

  /// Parse OFX transaction element
  Transaction _parseOfxTransaction(
    XmlElement element,
    String walletId,
    int rowNumber,
  ) {
    // Extract fields
    final fitId = _getElementText(element, 'FITID');
    final dateStr = _getElementText(element, 'DTPOSTED');
    final amountStr = _getElementText(element, 'TRNAMT');
    final name = _getElementText(element, 'NAME');
    final memo = _getElementText(element, 'MEMO');
    final type = _getElementText(element, 'TRNTYPE');

    // Parse date
    DateTime date;
    if (dateStr != null) {
      date = _parseOfxDate(dateStr);
    } else {
      throw FormatException('Missing date field');
    }

    // Parse amount
    double amount;
    if (amountStr != null) {
      amount = double.parse(amountStr);
    } else {
      throw FormatException('Missing amount field');
    }

    // Determine transaction type
    String transactionType;
    if (amount < 0) {
      transactionType = 'expense';
      amount = amount.abs();
    } else {
      transactionType = 'income';
    }

    // Map OFX type to category
    final category = _mapOfxTypeToCategory(type);

    // Create transaction
    return Transaction(
      id: fitId ?? DateTime.now().millisecondsSinceEpoch.toString() + '_$rowNumber',
      type: transactionType,
      amount: amount,
      description: name ?? memo ?? 'Imported transaction',
      category: category,
      walletId: walletId,
      date: date,
      memo: memo,
    );
  }

  /// Get text content of XML element
  String? _getElementText(XmlElement parent, String tagName) {
    try {
      final element = parent.findElements(tagName).firstOrNull;
      return element?.innerText.trim();
    } catch (e) {
      return null;
    }
  }

  /// Parse OFX date format (YYYYMMDDHHMMSS)
  DateTime _parseOfxDate(String dateStr) {
    // OFX date format: YYYYMMDDHHMMSS[.XXX][+/-TZ]
    // Extract just the date part
    final cleanDate = dateStr.substring(0, 8);
    
    final year = int.parse(cleanDate.substring(0, 4));
    final month = int.parse(cleanDate.substring(4, 6));
    final day = int.parse(cleanDate.substring(6, 8));

    return DateTime(year, month, day);
  }

  /// Map OFX transaction type to category
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

  /// Validate transaction data
  bool _validateTransaction(Transaction transaction) {
    return transaction.amount > 0 &&
           transaction.description.isNotEmpty &&
           transaction.category.isNotEmpty;
  }
}
