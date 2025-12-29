import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams, XFile;
import '../models/export_filter.dart';
import '../services/excel_export_service.dart';
import '../services/csv_export_service.dart';
import '../services/pdf_export_service.dart';
import '../services/data_service.dart';
class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  final DataService _dataService = DataService();

  ExportFormat _selectedFormat = ExportFormat.excel;
  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> _selectedCategories = [];
  final List<String> _selectedWallets = [];
  final List<String> _selectedTypes = [];
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Transactions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Format',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ExportFormat>(
              segments: const [
                ButtonSegment(
                  value: ExportFormat.excel,
                  label: Text('Excel'),
                  icon: Icon(Icons.table_chart),
                ),
                ButtonSegment(
                  value: ExportFormat.csv,
                  label: Text('CSV'),
                  icon: Icon(Icons.text_snippet),
                ),
                ButtonSegment(
                  value: ExportFormat.pdf,
                  label: Text('PDF'),
                  icon: Icon(Icons.picture_as_pdf),
                ),
              ],
              selected: {_selectedFormat},
              onSelectionChanged: (Set<ExportFormat> newSelection) {
                setState(() {
                  _selectedFormat = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Date Range (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, true),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _startDate != null
                          ? DateFormat('MMM dd, yyyy').format(_startDate!)
                          : 'Start Date',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, false),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _endDate != null
                          ? DateFormat('MMM dd, yyyy').format(_endDate!)
                          : 'End Date',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Filters',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Categories'),
                  selected: _selectedCategories.isNotEmpty,
                  onSelected: (selected) {
                  },
                ),
                FilterChip(
                  label: const Text('Wallets'),
                  selected: _selectedWallets.isNotEmpty,
                  onSelected: (selected) {
                  },
                ),
                FilterChip(
                  label: const Text('Types'),
                  selected: _selectedTypes.isNotEmpty,
                  onSelected: (selected) {
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isExporting ? null : _handleExport,
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.file_download),
          label: Text(_isExporting ? 'Exporting...' : 'Export'),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final transactions = await _dataService.getTransactions();
      ExportFilter? filter;
      if (_startDate != null && _endDate != null) {
        filter = ExportFilter(
          dateRange: DateRange(start: _startDate!, end: _endDate!),
          categories: _selectedCategories.isNotEmpty
              ? _selectedCategories
              : null,
          wallets: _selectedWallets.isNotEmpty ? _selectedWallets : null,
          transactionTypes: _selectedTypes.isNotEmpty ? _selectedTypes : null,
        );
      }
      late final String filePath;
      switch (_selectedFormat) {
        case ExportFormat.excel:
          final excelService = ExcelExportService();
          final file = await excelService.exportToExcel(
            transactions: transactions,
            filter: filter,
            currencySymbol: '₺',
          );
          filePath = file.path;
          break;

        case ExportFormat.csv:
          final csvService = CsvExportService();
          final file = await csvService.exportToCsv(
            transactions: transactions,
            filter: filter,
          );
          filePath = file.path;
          break;

        case ExportFormat.pdf:
          final pdfService = PdfExportService();
          final file = await pdfService.exportToPdf(
            transactions: transactions,
            dateRange: DateRange(
              start: _startDate ?? DateTime(2000),
              end: _endDate ?? DateTime.now(),
            ),
            filter: filter,
            currencySymbol: '₺',
          );
          filePath = file.path;
          break;
      }
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: 'Transaction Export',
        ),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}

enum ExportFormat { excel, csv, pdf }
