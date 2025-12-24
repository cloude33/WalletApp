import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../models/report_data.dart';
import '../../models/transaction.dart';
import '../../models/export_filter.dart';
import '../../services/export_service.dart';
class ExportOptionsWidget extends StatefulWidget {
  final ReportData? report;
  final List<Transaction>? transactions;
  final String? customFileName;
  final VoidCallback? onExportComplete;

  const ExportOptionsWidget({
    super.key,
    this.report,
    this.transactions,
    this.customFileName,
    this.onExportComplete,
  });

  @override
  State<ExportOptionsWidget> createState() => _ExportOptionsWidgetState();
}

class _ExportOptionsWidgetState extends State<ExportOptionsWidget> {
  final ExportService _exportService = ExportService();
  bool _isExporting = false;
  String? _exportingFormat;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.file_download,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Raporu Dışa Aktar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildExportButton(
                    format: 'PDF',
                    icon: Icons.picture_as_pdf,
                    color: Colors.red,
                    onPressed: () => _handleExport('pdf'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildExportButton(
                    format: 'Excel',
                    icon: Icons.table_chart,
                    color: Colors.green,
                    onPressed: () => _handleExport('excel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildExportButton(
                    format: 'CSV',
                    icon: Icons.text_snippet,
                    color: Colors.blue,
                    onPressed: () => _handleExport('csv'),
                  ),
                ),
              ],
            ),
            if (_isExporting) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(height: 8),
              Text(
                '$_exportingFormat formatında dışa aktarılıyor...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildExportButton({
    required String format,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final isCurrentlyExporting = _isExporting && _exportingFormat == format;
    
    return OutlinedButton.icon(
      onPressed: _isExporting ? null : onPressed,
      icon: isCurrentlyExporting
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          : Icon(icon, color: color),
      label: Text(
        format,
        style: TextStyle(color: color),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
  Future<void> _handleExport(String format) async {
    if (widget.report == null && widget.transactions == null) {
      _showMessage('Dışa aktarılacak veri bulunamadı', isError: true);
      return;
    }

    setState(() {
      _isExporting = true;
      _exportingFormat = format.toUpperCase();
    });

    try {
      File? exportedFile;
      final fileName = _generateFileName(format);

      switch (format.toLowerCase()) {
        case 'pdf':
          exportedFile = await _exportToPdf(fileName);
          break;
        case 'excel':
          exportedFile = await _exportToExcel(fileName);
          break;
        case 'csv':
          exportedFile = await _exportToCsv(fileName);
          break;
      }

      if (exportedFile != null) {
        await _showExportSuccessDialog(exportedFile, format);
        widget.onExportComplete?.call();
      }
    } catch (e) {
      _showMessage('Dışa aktarma hatası: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportingFormat = null;
        });
      }
    }
  }
  Future<File?> _exportToPdf(String fileName) async {
    if (widget.transactions == null) {
      throw Exception('İşlem verisi bulunamadı');
    }

    final dateRange = DateRange(
      start: widget.report?.startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      end: widget.report?.endDate ?? DateTime.now(),
    );

    return await _exportService.exportToPdf(
      transactions: widget.transactions!,
      dateRange: dateRange,
      fileName: fileName,
      currencySymbol: '₺',
    );
  }
  Future<File?> _exportToExcel(String fileName) async {
    if (widget.transactions == null) {
      throw Exception('İşlem verisi bulunamadı');
    }

    return await _exportService.exportToExcel(
      transactions: widget.transactions!,
      fileName: fileName,
      currencySymbol: '₺',
    );
  }
  Future<File?> _exportToCsv(String fileName) async {
    if (widget.transactions == null) {
      throw Exception('İşlem verisi bulunamadı');
    }

    return await _exportService.exportToCsv(
      transactions: widget.transactions!,
      fileName: fileName,
    );
  }
  String _generateFileName(String format) {
    if (widget.customFileName != null) {
      return widget.customFileName!;
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final reportType = _getReportTypePrefix();
    
    return '${reportType}_$timestamp';
  }
  String _getReportTypePrefix() {
    if (widget.report == null) {
      return 'rapor';
    }

    switch (widget.report!.type) {
      case ReportType.income:
        return 'gelir_raporu';
      case ReportType.expense:
        return 'gider_raporu';
      case ReportType.bill:
        return 'fatura_raporu';
      case ReportType.custom:
        return 'ozel_rapor';
    }
  }
  Future<void> _showExportSuccessDialog(File file, String format) async {
    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Dışa Aktarma Başarılı'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rapor ${format.toUpperCase()} formatında başarıyla dışa aktarıldı.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder, color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file.path.split('/').last,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Dosya konumu:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              file.parent.path,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('close'),
            child: const Text('Kapat'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop('share'),
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Paylaş'),
          ),
        ],
      ),
    );
    if (result == 'share') {
      await _shareFile(file);
    }
  }
  Future<void> _shareFile(File file) async {
    try {
      final xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile],
        subject: 'Finansal Rapor - ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
        text: 'Money uygulamasından dışa aktarılan finansal rapor',
      );
    } catch (e) {
      _showMessage('Paylaşım hatası: ${e.toString()}', isError: true);
    }
  }
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
