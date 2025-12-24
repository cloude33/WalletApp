import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/transaction.dart';
import '../models/export_filter.dart';
class PdfExportService {
  Future<File> exportToPdf({
    required List<Transaction> transactions,
    required DateRange dateRange,
    ExportFilter? filter,
    String? currencySymbol,
  }) async {
    final filteredTransactions = filter != null
        ? transactions.where((t) => filter.matches(t)).toList()
        : transactions;

    final currency = currencySymbol ?? '₺';
    final pdf = pw.Document();
    final totalIncome = filteredTransactions
        .where((t) => t.type == 'income')
        .fold<double>(0, (sum, t) => sum + t.amount);

    final totalExpense = filteredTransactions
        .where((t) => t.type == 'expense')
        .fold<double>(0, (sum, t) => sum + t.amount);

    final netBalance = totalIncome - totalExpense;
    final categoryTotals = <String, double>{};
    for (final transaction in filteredTransactions) {
      if (transaction.type == 'expense') {
        categoryTotals[transaction.category] =
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(dateRange),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSummarySection(totalIncome, totalExpense, netBalance, currency),
          pw.SizedBox(height: 20),
          _buildCategoryChart(categoryTotals, currency),
          pw.SizedBox(height: 20),
          _buildTransactionTable(filteredTransactions, currency),
        ],
      ),
    );
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final filePath = path.join(directory.path, 'exports', fileName);
    final exportDir = Directory(path.join(directory.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return file;
  }
  pw.Widget _buildHeader(DateRange dateRange) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Financial Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${DateFormat('MMM dd, yyyy').format(dateRange.start)} - ${DateFormat('MMM dd, yyyy').format(dateRange.end)}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    );
  }
  pw.Widget _buildSummarySection(
    double income,
    double expense,
    double net,
    String currency,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Income', income, currency, PdfColors.green),
          _buildSummaryItem('Expense', expense, currency, PdfColors.red),
          _buildSummaryItem('Net', net, currency, PdfColors.blue),
        ],
      ),
    );
  }
  pw.Widget _buildSummaryItem(
    String label,
    double amount,
    String currency,
    PdfColor color,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '$currency${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  pw.Widget _buildCategoryChart(
    Map<String, double> categoryTotals,
    String currency,
  ) {
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Expense by Category',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          ...sortedCategories.take(5).map((entry) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(entry.key),
                  pw.Text(
                    '$currency${entry.value.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  pw.Widget _buildTransactionTable(
    List<Transaction> transactions,
    String currency,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Transaction Details',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
          ),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellHeight: 25,
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerLeft,
          },
          headers: ['Date', 'Description', 'Amount', 'Category'],
          data: transactions.map((t) {
            return [
              DateFormat('yyyy-MM-dd').format(t.date),
              t.description,
              '$currency${t.amount.toStringAsFixed(2)}',
              t.category,
            ];
          }).toList(),
        ),
      ],
    );
  }
}
