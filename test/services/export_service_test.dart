import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/export_filter.dart';
import 'package:parion/models/transaction.dart';
import 'package:parion/services/export_service.dart';
// These imports are needed for testing but not direct dependencies
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:path/path.dart' as path;

/// Mock PathProviderPlatform for testing
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExportService exportService;
  late List<Transaction> testTransactions;

  setUp(() {
    // Set up mock path provider
    PathProviderPlatform.instance = MockPathProviderPlatform();

    exportService = ExportService();

    // Create test transactions
    testTransactions = [
      Transaction(
        id: '1',
        type: 'income',
        amount: 5000.0,
        category: 'Salary',
        description: 'Monthly salary',
        date: DateTime(2024, 1, 1),
        walletId: 'wallet1',
      ),
      Transaction(
        id: '2',
        type: 'expense',
        amount: 1500.0,
        category: 'Rent',
        description: 'Monthly rent',
        date: DateTime(2024, 1, 5),
        walletId: 'wallet1',
      ),
      Transaction(
        id: '3',
        type: 'expense',
        amount: 500.0,
        category: 'Groceries',
        description: 'Weekly groceries',
        date: DateTime(2024, 1, 10),
        walletId: 'wallet1',
      ),
    ];
  });

  tearDown(() async {
    // Clean up test files
    try {
      await exportService.clearAllExports();
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  group('ExportService - PDF Export', () {
    test('should export transactions to PDF successfully', () async {
      final dateRange = DateRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );

      final file = await exportService.exportToPdf(
        transactions: testTransactions,
        dateRange: dateRange,
      );

      expect(file.existsSync(), isTrue);
      expect(file.path.endsWith('.pdf'), isTrue);
      expect(file.lengthSync(), greaterThan(0));
    });

    test('should export PDF with custom file name', () async {
      final dateRange = DateRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );

      final file = await exportService.exportToPdf(
        transactions: testTransactions,
        dateRange: dateRange,
        fileName: 'custom_report',
      );

      expect(file.existsSync(), isTrue);
      expect(path.basename(file.path), equals('custom_report.pdf'));
    });

    test('should export PDF with filter applied', () async {
      final dateRange = DateRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );

      final filter = ExportFilter(categories: ['Rent']);

      final file = await exportService.exportToPdf(
        transactions: testTransactions,
        dateRange: dateRange,
        filter: filter,
      );

      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(0));
    });

    test('should export PDF with custom currency symbol', () async {
      final dateRange = DateRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );

      final file = await exportService.exportToPdf(
        transactions: testTransactions,
        dateRange: dateRange,
        currencySymbol: '\$',
      );

      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(0));
    });
  });

  group('ExportService - Excel Export', () {
    test('should export transactions to Excel successfully', () async {
      final file = await exportService.exportToExcel(
        transactions: testTransactions,
      );

      expect(file.existsSync(), isTrue);
      expect(file.path.endsWith('.xlsx'), isTrue);
      expect(file.lengthSync(), greaterThan(0));
    });

    test('should export Excel with custom file name', () async {
      final file = await exportService.exportToExcel(
        transactions: testTransactions,
        fileName: 'custom_transactions',
      );

      expect(file.existsSync(), isTrue);
      expect(path.basename(file.path), equals('custom_transactions.xlsx'));
    });

    test('should export Excel with filter applied', () async {
      final filter = ExportFilter(transactionTypes: ['expense']);

      final file = await exportService.exportToExcel(
        transactions: testTransactions,
        filter: filter,
      );

      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(0));
    });

    test('should export Excel with custom currency symbol', () async {
      final file = await exportService.exportToExcel(
        transactions: testTransactions,
        currencySymbol: '€',
      );

      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(0));
    });
  });

  group('ExportService - CSV Export', () {
    test('should export transactions to CSV successfully', () async {
      final file = await exportService.exportToCsv(
        transactions: testTransactions,
      );

      expect(file.existsSync(), isTrue);
      expect(file.path.endsWith('.csv'), isTrue);
      expect(file.lengthSync(), greaterThan(0));

      // Verify CSV content
      final content = await file.readAsString();
      expect(content, contains('Date'));
      expect(content, contains('Type'));
      expect(content, contains('Amount'));
    });

    test('should export CSV with custom file name', () async {
      final file = await exportService.exportToCsv(
        transactions: testTransactions,
        fileName: 'custom_data',
      );

      expect(file.existsSync(), isTrue);
      expect(path.basename(file.path), equals('custom_data.csv'));
    });

    test('should export CSV with filter applied', () async {
      final filter = ExportFilter(categories: ['Groceries']);

      final file = await exportService.exportToCsv(
        transactions: testTransactions,
        filter: filter,
      );

      expect(file.existsSync(), isTrue);
      final content = await file.readAsString();
      expect(content, contains('Groceries'));
      expect(content.split('\n').length, lessThan(testTransactions.length + 2));
    });

    test('should handle empty transaction list', () async {
      final file = await exportService.exportToCsv(transactions: []);

      expect(file.existsSync(), isTrue);
      final content = await file.readAsString();
      // Should only have header row
      expect(
        content.split('\n').where((line) => line.isNotEmpty).length,
        equals(1),
      );
    });
  });

  group('ExportService - File Name Generation', () {
    test('should generate file name with timestamp', () {
      final fileName = exportService.generateFileName(
        prefix: 'report',
        extension: 'pdf',
      );

      expect(fileName, startsWith('report_'));
      expect(fileName, endsWith('.pdf'));
      expect(fileName, matches(RegExp(r'report_\d{8}_\d{6}\.pdf')));
    });

    test('should generate file name without date', () {
      final fileName = exportService.generateFileName(
        prefix: 'chart',
        extension: 'png',
        includeDate: false,
      );

      expect(fileName, equals('chart.png'));
    });

    test('should sanitize invalid characters in file name', () {
      final fileName = exportService.generateFileName(
        prefix: 'report<>:"/\\|?*test',
        extension: 'pdf',
        includeDate: false,
      );

      // Should replace invalid characters with underscores
      expect(fileName, contains('report'));
      expect(fileName, contains('test.pdf'));
      expect(fileName, isNot(contains('<')));
      expect(fileName, isNot(contains('>')));
      expect(fileName, isNot(contains(':')));
    });
  });

  group('ExportService - File Management', () {
    test('should get exports directory path', () async {
      final dirPath = await exportService.getExportsDirectory();

      expect(dirPath, isNotEmpty);
      expect(Directory(dirPath).existsSync(), isTrue);
    });

    test('should list export files', () async {
      // Create some test files
      final file1 = await exportService.exportToCsv(
        transactions: testTransactions,
      );
      final file2 = await exportService.exportToCsv(
        transactions: testTransactions,
      );

      final files = await exportService.listExportFiles();

      // Should have at least the files we just created
      expect(files.length, greaterThanOrEqualTo(1));
      expect(files.every((f) => f.existsSync()), isTrue);

      // Verify our files are in the list
      final filePaths = files.map((f) => f.path).toList();
      expect(filePaths.any((p) => p == file1.path || p == file2.path), isTrue);
    });

    test('should delete export file', () async {
      final file = await exportService.exportToCsv(
        transactions: testTransactions,
      );

      expect(file.existsSync(), isTrue);

      final deleted = await exportService.deleteExportFile(file.path);

      expect(deleted, isTrue);
      expect(file.existsSync(), isFalse);
    });

    test('should return false when deleting non-existent file', () async {
      final deleted = await exportService.deleteExportFile(
        '/non/existent/file.csv',
      );

      expect(deleted, isFalse);
    });

    test('should clear all exports', () async {
      // Create multiple test files
      await exportService.exportToCsv(transactions: testTransactions);
      await exportService.exportToCsv(transactions: testTransactions);
      await exportService.exportToCsv(transactions: testTransactions);

      final deletedCount = await exportService.clearAllExports();

      // Should delete at least the files we created
      expect(deletedCount, greaterThanOrEqualTo(1));

      final remainingFiles = await exportService.listExportFiles();
      expect(remainingFiles, isEmpty);
    });
  });

  group('ExportService - Edge Cases', () {
    test('should handle transactions with special characters', () async {
      final specialTransactions = [
        Transaction(
          id: '1',
          type: 'expense',
          amount: 100.0,
          category: 'Test, "Category"',
          description: 'Description with\nnewline',
          date: DateTime(2024, 1, 1),
          walletId: 'wallet1',
        ),
      ];

      final file = await exportService.exportToCsv(
        transactions: specialTransactions,
      );

      expect(file.existsSync(), isTrue);
      final content = await file.readAsString();
      // CSV should properly escape special characters
      expect(content, contains('Test'));
      expect(content, contains('Category'));
      expect(content, contains('Description'));
    });

    test('should handle large transaction lists', () async {
      final largeList = List.generate(
        1000,
        (i) => Transaction(
          id: 'id_$i',
          type: i % 2 == 0 ? 'income' : 'expense',
          amount: 100.0 + i,
          category: 'Category ${i % 10}',
          description: 'Transaction $i',
          date: DateTime(2024, 1, 1).add(Duration(days: i)),
          walletId: 'wallet1',
        ),
      );

      final file = await exportService.exportToCsv(transactions: largeList);

      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(0));
    });

    test('should handle transactions with null memo', () async {
      final transactionsWithNullMemo = [
        Transaction(
          id: '1',
          type: 'expense',
          amount: 100.0,
          category: 'Test',
          description: 'Test transaction',
          date: DateTime(2024, 1, 1),
          walletId: 'wallet1',
          memo: null,
        ),
      ];

      final file = await exportService.exportToCsv(
        transactions: transactionsWithNullMemo,
      );

      expect(file.existsSync(), isTrue);
    });
  });
}
