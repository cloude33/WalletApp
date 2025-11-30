import 'transaction.dart';

/// Filter for export operations
class ExportFilter {
  final DateRange? dateRange;
  final List<String>? categories;
  final List<String>? wallets;
  final List<String>? transactionTypes;

  const ExportFilter({
    this.dateRange,
    this.categories,
    this.wallets,
    this.transactionTypes,
  });

  /// Check if a transaction matches the filter
  bool matches(Transaction transaction) {
    // Check date range
    if (dateRange != null) {
      if (transaction.date.isBefore(dateRange!.start) ||
          transaction.date.isAfter(dateRange!.end)) {
        return false;
      }
    }

    // Check categories
    if (categories != null && categories!.isNotEmpty) {
      if (!categories!.contains(transaction.category)) {
        return false;
      }
    }

    // Check wallets
    if (wallets != null && wallets!.isNotEmpty) {
      if (!wallets!.contains(transaction.walletId)) {
        return false;
      }
    }

    // Check transaction types
    if (transactionTypes != null && transactionTypes!.isNotEmpty) {
      if (!transactionTypes!.contains(transaction.type)) {
        return false;
      }
    }

    return true;
  }

  ExportFilter copyWith({
    DateRange? dateRange,
    List<String>? categories,
    List<String>? wallets,
    List<String>? transactionTypes,
  }) {
    return ExportFilter(
      dateRange: dateRange ?? this.dateRange,
      categories: categories ?? this.categories,
      wallets: wallets ?? this.wallets,
      transactionTypes: transactionTypes ?? this.transactionTypes,
    );
  }
}

/// Date range for filtering
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({
    required this.start,
    required this.end,
  });

  bool isValid() => start.isBefore(end) || start.isAtSameMomentAs(end);
}
