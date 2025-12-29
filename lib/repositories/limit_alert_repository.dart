import 'package:hive/hive.dart';
import '../models/limit_alert.dart';
import '../services/credit_card_box_service.dart';

class LimitAlertRepository {
  Box<LimitAlert> get _box => CreditCardBoxService.limitAlertsBox;
  Future<void> save(LimitAlert alert) async {
    await _box.put(alert.id, alert);
  }
  Future<LimitAlert?> findById(String id) async {
    return _box.get(id);
  }
  Future<List<LimitAlert>> findByCardId(String cardId) async {
    final alerts = _box.values.where((alert) => alert.cardId == cardId).toList();
    alerts.sort((a, b) => a.threshold.compareTo(b.threshold));

    return alerts;
  }
  Future<List<LimitAlert>> findTriggeredAlerts(String cardId) async {
    return _box.values
        .where((alert) => alert.cardId == cardId && alert.isTriggered)
        .toList();
  }
  Future<List<LimitAlert>> findNonTriggeredAlerts(String cardId) async {
    return _box.values
        .where((alert) => alert.cardId == cardId && !alert.isTriggered)
        .toList();
  }
  Future<LimitAlert?> findByCardIdAndThreshold(
    String cardId,
    double threshold,
  ) async {
    final alerts = _box.values.where(
      (alert) => alert.cardId == cardId && alert.threshold == threshold,
    );
    return alerts.isNotEmpty ? alerts.first : null;
  }
  Future<List<LimitAlert>> findAll() async {
    return _box.values.toList();
  }
  Future<List<LimitAlert>> findAllTriggeredAlerts() async {
    return _box.values.where((alert) => alert.isTriggered).toList();
  }
  Future<void> update(LimitAlert alert) async {
    await _box.put(alert.id, alert);
  }
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
  Future<void> deleteByCardId(String cardId) async {
    final alerts = await findByCardId(cardId);
    for (var alert in alerts) {
      await delete(alert.id);
    }
  }
  Future<void> resetAlerts(String cardId) async {
    final alerts = await findByCardId(cardId);
    for (var alert in alerts) {
      if (alert.isTriggered) {
        final updatedAlert = alert.copyWith(
          isTriggered: false,
          triggeredAt: null,
        );
        await update(updatedAlert);
      }
    }
  }
  Future<void> resetAlertByThreshold(String cardId, double threshold) async {
    final alert = await findByCardIdAndThreshold(cardId, threshold);
    if (alert != null && alert.isTriggered) {
      final updatedAlert = alert.copyWith(
        isTriggered: false,
        triggeredAt: null,
      );
      await update(updatedAlert);
    }
  }
  Future<bool> exists(String cardId, double threshold) async {
    final alert = await findByCardIdAndThreshold(cardId, threshold);
    return alert != null;
  }
  Future<bool> hasTriggeredAlerts(String cardId) async {
    final triggeredAlerts = await findTriggeredAlerts(cardId);
    return triggeredAlerts.isNotEmpty;
  }
  Future<int> countByCardId(String cardId) async {
    return _box.values.where((alert) => alert.cardId == cardId).length;
  }
  Future<int> countTriggeredAlerts(String cardId) async {
    return _box.values
        .where((alert) => alert.cardId == cardId && alert.isTriggered)
        .length;
  }
  Future<double?> getHighestTriggeredThreshold(String cardId) async {
    final triggeredAlerts = await findTriggeredAlerts(cardId);
    if (triggeredAlerts.isEmpty) return null;

    triggeredAlerts.sort((a, b) => b.threshold.compareTo(a.threshold));
    return triggeredAlerts.first.threshold;
  }
  Future<void> clear() async {
    await _box.clear();
  }
}
