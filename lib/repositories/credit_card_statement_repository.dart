import 'package:hive/hive.dart';
import '../models/credit_card_statement.dart';
import '../services/credit_card_box_service.dart';

class CreditCardStatementRepository {
  Box<CreditCardStatement> get _box => CreditCardBoxService.statementsBox;

  /// Save a statement
  Future<void> save(CreditCardStatement statement) async {
    await _box.put(statement.id, statement);
  }

  /// Find a statement by ID
  Future<CreditCardStatement?> findById(String id) async {
    return _box.get(id);
  }

  /// Find all statements
  Future<List<CreditCardStatement>> findAll() async {
    return _box.values.toList();
  }

  /// Find all statements for a specific card
  Future<List<CreditCardStatement>> findByCardId(String cardId) async {
    final statements = _box.values
        .where((statement) => statement.cardId == cardId)
        .toList();
    
    // Sort by period end date (newest first)
    statements.sort((a, b) => b.periodEnd.compareTo(a.periodEnd));
    
    return statements;
  }

  /// Find current statement for a card (most recent unpaid or pending)
  Future<CreditCardStatement?> findCurrentStatement(String cardId) async {
    final statements = await findByCardId(cardId);
    
    // Find the most recent statement that is not fully paid
    for (var statement in statements) {
      if (!statement.isPaidFully) {
        return statement;
      }
    }
    
    // If all are paid, return the most recent one
    return statements.isNotEmpty ? statements.first : null;
  }

  /// Find previous statement for a card (the one before current)
  Future<CreditCardStatement?> findPreviousStatement(String cardId) async {
    final statements = await findByCardId(cardId);
    
    if (statements.length < 2) {
      return null;
    }
    
    return statements[1]; // Second most recent
  }

  /// Find all overdue statements
  Future<List<CreditCardStatement>> findOverdueStatements() async {
    final now = DateTime.now();
    return _box.values
        .where((statement) =>
            statement.dueDate.isBefore(now) &&
            !statement.isPaidFully)
        .toList();
  }

  /// Find statements by status
  Future<List<CreditCardStatement>> findByStatus(String status) async {
    return _box.values
        .where((statement) => statement.status == status)
        .toList();
  }

  /// Find statements by date range
  Future<List<CreditCardStatement>> findByDateRange(
    String cardId,
    DateTime start,
    DateTime end,
  ) async {
    return _box.values
        .where((statement) =>
            statement.cardId == cardId &&
            statement.periodEnd.isAfter(start.subtract(const Duration(seconds: 1))) &&
            statement.periodEnd.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  /// Find statement by period end date
  Future<CreditCardStatement?> findByPeriodEnd(
    String cardId,
    DateTime periodEnd,
  ) async {
    final statements = _box.values
        .where((statement) =>
            statement.cardId == cardId &&
            statement.periodEnd.year == periodEnd.year &&
            statement.periodEnd.month == periodEnd.month &&
            statement.periodEnd.day == periodEnd.day)
        .toList();
    
    return statements.isNotEmpty ? statements.first : null;
  }

  /// Update a statement
  Future<void> update(CreditCardStatement statement) async {
    await _box.put(statement.id, statement);
  }

  /// Delete a statement
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Get total debt across all statements for a card
  Future<double> getTotalDebt(String cardId) async {
    final statements = await findByCardId(cardId);
    return statements
        .where((s) => !s.isPaidFully)
        .fold<double>(0, (sum, s) => sum + s.remainingDebt);
  }

  /// Get total overdue debt
  Future<double> getTotalOverdueDebt() async {
    final overdueStatements = await findOverdueStatements();
    return overdueStatements.fold<double>(0, (sum, s) => sum + s.remainingDebt);
  }

  /// Get count of statements for a card
  Future<int> countByCardId(String cardId) async {
    return _box.values.where((s) => s.cardId == cardId).length;
  }

  /// Clear all statements (for testing)
  Future<void> clear() async {
    await _box.clear();
  }
}
