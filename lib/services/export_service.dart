import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/transaction.dart';
import '../models/export_filter.dart';
import 'pdf_export_service.dart';
import 'excel_export_service.dart';
import 'csv_export_service.dart';
class ExportService {
  final PdfExportService _pdfService;
  final ExcelExportService _excelService;
  final CsvExportService _csvService;

  ExportService({
    PdfExportService? pdfService,
    ExcelExportService? excelService,
    CsvExportService? csvService,
  })  : _pdfService = pdfService ?? PdfExportService(),
        _excelService = excelService ?? ExcelExportService(),
        _csvService = csvService ?? CsvExportService();
  Future<File> exportToPdf({
    required List<Transaction> transactions,
    required DateRange dateRange,
    ExportFilter? filter,
    String? currencySymbol,
    String? fileName,
  }) async {
    final file = await _pdfService.exportToPdf(
      transactions: transactions,
      dateRange: dateRange,
      filter: filter,
      currencySymbol: currencySymbol,
    );
    if (fileName != null) {
      final newPath = path.join(
        path.dirname(file.path),
        _sanitizeFileName(fileName, 'pdf'),
      );
      return await file.rename(newPath);
    }

    return file;
  }
  Future<File> exportToExcel({
    required List<Transaction> transactions,
    ExportFilter? filter,
    String? currencySymbol,
    String? fileName,
  }) async {
    final file = await _excelService.exportToExcel(
      transactions: transactions,
      filter: filter,
      currencySymbol: currencySymbol,
    );
    if (fileName != null) {
      final newPath = path.join(
        path.dirname(file.path),
        _sanitizeFileName(fileName, 'xlsx'),
      );
      return await file.rename(newPath);
    }

    return file;
  }
  Future<File> exportToCsv({
    required List<Transaction> transactions,
    ExportFilter? filter,
    String? fileName,
  }) async {
    final file = await _csvService.exportToCsv(
      transactions: transactions,
      filter: filter,
    );
    if (fileName != null) {
      final newPath = path.join(
        path.dirname(file.path),
        _sanitizeFileName(fileName, 'csv'),
      );
      return await file.rename(newPath);
    }

    return file;
  }
  Future<File> exportChartToPng({
    required GlobalKey chartKey,
    String? fileName,
    double pixelRatio = 3.0,
  }) async {
    try {
      final RenderRepaintBoundary boundary =
          chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to convert image to byte data');
      }
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory(path.join(directory.path, 'exports'));
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      final defaultFileName =
          'chart_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.png';
      final finalFileName = fileName != null
          ? _sanitizeFileName(fileName, 'png')
          : defaultFileName;
      final filePath = path.join(exportDir.path, finalFileName);
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return file;
    } catch (e) {
      throw Exception('Failed to export chart to PNG: $e');
    }
  }
  String generateFileName({
    required String prefix,
    required String extension,
    bool includeDate = true,
  }) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final sanitizedPrefix = _sanitizeFileName(prefix, '');

    if (includeDate) {
      return '${sanitizedPrefix}_$timestamp.$extension';
    } else {
      return '$sanitizedPrefix.$extension';
    }
  }
  String _sanitizeFileName(String fileName, String extension) {
    var sanitized = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    sanitized = sanitized.trim().replaceAll(RegExp(r'^\.+|\.+$'), '');
    if (extension.isNotEmpty && !sanitized.toLowerCase().endsWith('.$extension')) {
      sanitized = sanitized.replaceAll(RegExp(r'\.[^.]+$'), '');
      sanitized = '$sanitized.$extension';
    }

    return sanitized;
  }
  Future<String> getExportsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory(path.join(directory.path, 'exports'));

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    return exportDir.path;
  }
  Future<bool> deleteExportFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  Future<List<File>> listExportFiles() async {
    try {
      final exportPath = await getExportsDirectory();
      final exportDir = Directory(exportPath);

      if (!await exportDir.exists()) {
        return [];
      }

      final files = await exportDir
          .list()
          .where((entity) => entity is File)
          .map((entity) => entity as File)
          .toList();
      files.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

      return files;
    } catch (e) {
      return [];
    }
  }
  Future<int> clearAllExports() async {
    try {
      final files = await listExportFiles();
      var deletedCount = 0;

      for (final file in files) {
        try {
          await file.delete();
          deletedCount++;
        } catch (e) {
          debugPrint('Error: $e');
        }
      }

      return deletedCount;
    } catch (e) {
      return 0;
    }
  }
}
