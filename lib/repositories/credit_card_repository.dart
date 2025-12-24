import 'package:hive/hive.dart';
import '../models/credit_card.dart';
import '../services/credit_card_box_service.dart';

class CreditCardRepository {
  Box<CreditCard> get _box => CreditCardBoxService.creditCardsBox;
  Future<void> save(CreditCard card) async {
    await _box.put(card.id, card);
  }
  Future<CreditCard?> findById(String id) async {
    return _box.get(id);
  }
  Future<List<CreditCard>> findAll() async {
    return _box.values.toList();
  }
  Future<List<CreditCard>> findActive() async {
    return _box.values.where((card) => card.isActive).toList();
  }
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
  Future<void> update(CreditCard card) async {
    await _box.put(card.id, card);
  }
  Future<bool> exists(String id) async {
    return _box.containsKey(id);
  }
  Future<int> count() async {
    return _box.length;
  }
  Future<int> countActive() async {
    return _box.values.where((card) => card.isActive).length;
  }
  Future<void> clear() async {
    await _box.clear();
  }
}
