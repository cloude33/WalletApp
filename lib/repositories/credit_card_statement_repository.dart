import 'package:hive/hive.dart';
import '../models/credit_card_statement.dart';
import '../services/credit_card_box_service.dart';

class CreditCardStatementRepository {
  Box<CreditCardStatement> get _box => CreditCardBoxService.statementsBox;
  Future<void> save(CreditCardStatement statement) async {
    await _box.put(statement.id, statement);
  }
  Future<CreditCardStatement?> findById(String id) async {
    return _box.get(id);
  }
  Future<List<CreditCardStatement>> findAll() async {
    return _box.values.toList();
  }
  Future<List<CreditCardStatement>> findByCardId(String cardId) async {
    final statements = _box.values
        .where((statement) => statement.cardId == cardId)
        .toList();
    statements.sort((a, b) => b.periodEnd.compareTo(a.periodEnd));

    return statements;
  }
  Future<CreditCardStatement?> findCurrentStatement(String cardId) async {
    final statements = await findByCardId(cardId);
    for (var statement in statements) {
      if (!statement.isPaidFully) {
        return statement;
      }
    }
    return statements.isNotEmpty ? statements.first : null;
  }
  Future<CreditCardStatement?> findPreviousStatement(String cardId) async {
    final statements = await findByCardId(cardId);

    if (statements.length < 2) {
      return null;
    }

    return statements[1];
  }
  Future<List<CreditCardStatement>> findOverdueStatements() async {
    final now = DateTime.now();
    return _box.values
        .where(
          (statement) =>
              statement.dueDate.isBefore(now) && !statement.isPaidFully,
        )
        .toList();
  }
  Future<List<CreditCardStatement>> findByStatus(String status) async {
    return _box.values
        .where((statement) => statement.status == status)
        .toList();
  }
  Future<List<CreditCardStatement>> findByDateRange(
    String cardId,
    DateTime start,
    DateTime end,
  ) async {
    return _box.values
        .where(
          (statement) =>
              statement.cardId == cardId &&
              statement.periodEnd.isAfter(
                start.subtract(const Duration(seconds: 1)),
              ) &&
              statement.periodEnd.isBefore(end.add(const Duration(days: 1))),
        )
        .toList();
  }
  Future<CreditCardStatement?> findByPeriodEnd(
    String cardId,
    DateTime periodEnd,
  ) async {
    final statements = _box.values
        .where(
          (statement) =>
              statement.cardId == cardId &&
              statement.periodEnd.year == periodEnd.year &&
              statement.periodEnd.month == periodEnd.month &&
              statement.periodEnd.day == periodEnd.day,
        )
        .toList();

    return statements.isNotEmpty ? statements.first : null;
  }
  Future<void> update(CreditCardStatement statement) async {
    await _box.put(statement.id, statement);
  }
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
  Future<double> getTotalDebt(String cardId) async {
    final statements = await findByCardId(cardId);
    return statements
        .where((s) => !s.isPaidFully)
        .fold<double>(0, (sum, s) => sum + s.remainingDebt);
  }
  Future<double> getTotalOverdueDebt() async {
    final overdueStatements = await findOverdueStatements();
    return overdueStatements.fold<double>(0, (sum, s) => sum + s.remainingDebt);
  }
  Future<int> countByCardId(String cardId) async {
    return _box.values.where((s) => s.cardId == cardId).length;
  }
  Future<void> clear() async {
    await _box.clear();
  }
}
