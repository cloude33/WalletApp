import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/transaction.dart';
import '../models/export_filter.dart';

/// Service for exporting data to CSV format
class CsvExportService {
  /// Export transactions to CSV file
  Future<File> exportToCsv({
    required List<Transaction> transactions,
    ExportFilter? filter,
  }) async {
    // Apply filter if provided
    final filteredTransactions = filter != null
        ? transactions.where((t) => filter.matches(t)).toList()
        : transactions;

    // Create CSV data
    final List<List<dynamic>> rows = [];

    // Add header row
    rows.add([
      'Date',
      'Type',
      'Amount',
      'Category',
      'Description',
      'Wallet',
      'Memo',
    ]);

    // Add data rows
    for (final transaction in filteredTransactions) {
      rows.add([
        formatDate(transaction.date),
        escapeField(transaction.type),
        transaction.amount.toStringAsFixed(2),
        escapeField(transaction.category),
        escapeField(transaction.description),
        escapeField(transaction.walletId),
        escapeField(transaction.memo ?? ''),
      ]);
    }

    // Convert to CSV string
    final csvString = const ListToCsvConverter().convert(rows);

    // Add UTF-8 BOM for Excel compatibility
    final utf8Bom = '\uFEFF';
    final csvWithBom = utf8Bom + csvString;

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'transactions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final filePath = path.join(directory.path, 'exports', fileName);

    // Create directory if it doesn't exist
    final exportDir = Directory(path.join(directory.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    // Write file
    final file = File(filePath);
    await file.writeAsString(csvWithBom, encoding: utf8);

    return file;
  }

  /// Escape field for CSV (handle commas, quotes, newlines)
  String escapeField(String field) {
    // If field contains comma, quote, or newline, wrap in quotes
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      // Escape quotes by doubling them
      final escaped = field.replaceAll('"', '""');
      return '"$escaped"';
    }
    return field;
  }

  /// Format date in ISO 8601 format (YYYY-MM-DD)
  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
