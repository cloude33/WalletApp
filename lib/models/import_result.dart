import 'transaction.dart';
class ImportResult {
  final int successCount;
  final int failureCount;
  final List<ImportError> errors;
  final List<Transaction> importedTransactions;

  const ImportResult({
    required this.successCount,
    required this.failureCount,
    required this.errors,
    required this.importedTransactions,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => failureCount == 0;
  int get totalCount => successCount + failureCount;
}
class ImportError {
  final int rowNumber;
  final String field;
  final String message;
  final String? value;

  const ImportError({
    required this.rowNumber,
    required this.field,
    required this.message,
    this.value,
  });

  @override
  String toString() {
    return 'Row $rowNumber, Field "$field": $message${value != null ? ' (value: $value)' : ''}';
  }
}
