import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/transaction.dart';
import '../models/export_filter.dart';

/// Service for exporting data to Excel format
class ExcelExportService {
  /// Export transactions to Excel file
  Future<File> exportToExcel({
    required List<Transaction> transactions,
    ExportFilter? filter,
    String? currencySymbol,
  }) async {
    // Apply filter if provided
    final filteredTransactions = filter != null
        ? transactions.where((t) => filter.matches(t)).toList()
        : transactions;

    // Create Excel workbook
    final excel = Excel.createExcel();

    // Add transaction sheet
    await addTransactionSheet(excel, filteredTransactions, currencySymbol);

    // Add summary sheet
    await addSummarySheet(excel, filteredTransactions, currencySymbol);

    // Remove default sheet
    excel.delete('Sheet1');

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'transactions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    final filePath = path.join(directory.path, 'exports', fileName);

    // Create directory if it doesn't exist
    final exportDir = Directory(path.join(directory.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    // Write file
    final file = File(filePath);
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    return file;
  }

  /// Add transaction sheet to Excel
  Future<void> addTransactionSheet(
    Excel excel,
    List<Transaction> transactions,
    String? currencySymbol,
  ) async {
    final sheet = excel['Transactions'];
    final currency = currencySymbol ?? '₺';

    // Add headers
    final headers = [
      'Date',
      'Type',
      'Amount',
      'Category',
      'Description',
      'Wallet',
      'Memo',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
      );
    }

    // Add data rows
    for (var i = 0; i < transactions.length; i++) {
      final transaction = transactions[i];
      final rowIndex = i + 1;

      // Date
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(DateFormat('yyyy-MM-dd').format(transaction.date));

      // Type
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(transaction.type);

      // Amount with currency
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue('$currency${transaction.amount.toStringAsFixed(2)}');

      // Category
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(transaction.category);

      // Description
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(transaction.description);

      // Wallet
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(transaction.walletId);

      // Memo
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(transaction.memo ?? '');
    }

    // Auto-fit columns
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 15);
    }
  }

  /// Add summary sheet to Excel
  Future<void> addSummarySheet(
    Excel excel,
    List<Transaction> transactions,
    String? currencySymbol,
  ) async {
    final sheet = excel['Summary'];
    final currency = currencySymbol ?? '₺';

    // Calculate totals by category
    final categoryTotals = <String, double>{};
    for (final transaction in transactions) {
      if (transaction.type == 'expense') {
        categoryTotals[transaction.category] =
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }

    // Calculate totals by month
    final monthTotals = <String, Map<String, double>>{};
    for (final transaction in transactions) {
      final monthKey = DateFormat('yyyy-MM').format(transaction.date);
      monthTotals.putIfAbsent(monthKey, () => {'income': 0, 'expense': 0});

      if (transaction.type == 'income') {
        monthTotals[monthKey]!['income'] =
            monthTotals[monthKey]!['income']! + transaction.amount;
      } else {
        monthTotals[monthKey]!['expense'] =
            monthTotals[monthKey]!['expense']! + transaction.amount;
      }
    }

    // Add category summary
    var rowIndex = 0;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
        TextCellValue('Category Summary');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .cellStyle = CellStyle(bold: true, fontSize: 14);

    rowIndex += 2;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
        TextCellValue('Category');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value =
        TextCellValue('Total');

    rowIndex++;
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedCategories) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
          TextCellValue(entry.key);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value =
          TextCellValue('$currency${entry.value.toStringAsFixed(2)}');
      rowIndex++;
    }

    // Add monthly summary
    rowIndex += 2;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
        TextCellValue('Monthly Summary');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .cellStyle = CellStyle(bold: true, fontSize: 14);

    rowIndex += 2;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
        TextCellValue('Month');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value =
        TextCellValue('Income');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value =
        TextCellValue('Expense');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value =
        TextCellValue('Net');

    rowIndex++;
    final sortedMonths = monthTotals.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    for (final entry in sortedMonths) {
      final income = entry.value['income']!;
      final expense = entry.value['expense']!;
      final net = income - expense;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
          TextCellValue(entry.key);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value =
          TextCellValue('$currency${income.toStringAsFixed(2)}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value =
          TextCellValue('$currency${expense.toStringAsFixed(2)}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value =
          TextCellValue('$currency${net.toStringAsFixed(2)}');
      rowIndex++;
    }

    // Auto-fit columns
    for (var i = 0; i < 4; i++) {
      sheet.setColumnWidth(i, 15);
    }
  }
}
