import 'package:hive/hive.dart';
import '../models/credit_card.dart';
import '../services/credit_card_box_service.dart';

class CreditCardRepository {
  Box<CreditCard> get _box => CreditCardBoxService.creditCardsBox;

  /// Save a credit card
  Future<void> save(CreditCard card) async {
    await _box.put(card.id, card);
  }

  /// Find a credit card by ID
  Future<CreditCard?> findById(String id) async {
    return _box.get(id);
  }

  /// Find all credit cards
  Future<List<CreditCard>> findAll() async {
    return _box.values.toList();
  }

  /// Find all active credit cards
  Future<List<CreditCard>> findActive() async {
    return _box.values.where((card) => card.isActive).toList();
  }

  /// Delete a credit card
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Update a credit card
  Future<void> update(CreditCard card) async {
    await _box.put(card.id, card);
  }

  /// Check if a credit card exists
  Future<bool> exists(String id) async {
    return _box.containsKey(id);
  }

  /// Get count of credit cards
  Future<int> count() async {
    return _box.length;
  }

  /// Get count of active credit cards
  Future<int> countActive() async {
    return _box.values.where((card) => card.isActive).length;
  }

  /// Clear all credit cards (for testing)
  Future<void> clear() async {
    await _box.clear();
  }
}
