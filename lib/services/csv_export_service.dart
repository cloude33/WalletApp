import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/transaction.dart';
import '../models/export_filter.dart';
class CsvExportService {
  Future<File> exportToCsv({
    required List<Transaction> transactions,
    ExportFilter? filter,
  }) async {
    final filteredTransactions = filter != null
        ? transactions.where((t) => filter.matches(t)).toList()
        : transactions;
    final List<List<dynamic>> rows = [];
    rows.add([
      'Date',
      'Type',
      'Amount',
      'Category',
      'Description',
      'Wallet',
      'Memo',
    ]);
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
    final csvString = const ListToCsvConverter().convert(rows);
    final utf8Bom = '\uFEFF';
    final csvWithBom = utf8Bom + csvString;
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'transactions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final filePath = path.join(directory.path, 'exports', fileName);
    final exportDir = Directory(path.join(directory.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final file = File(filePath);
    await file.writeAsString(csvWithBom, encoding: utf8);

    return file;
  }
  String escapeField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      final escaped = field.replaceAll('"', '""');
      return '"$escaped"';
    }
    return field;
  }
  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
