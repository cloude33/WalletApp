import 'package:hive/hive.dart';
import '../models/limit_alert.dart';
import '../services/credit_card_box_service.dart';

class LimitAlertRepository {
  Box<LimitAlert> get _box => CreditCardBoxService.limitAlertsBox;

  /// Save a limit alert
  Future<void> save(LimitAlert alert) async {
    await _box.put(alert.id, alert);
  }

  /// Find a limit alert by ID
  Future<LimitAlert?> findById(String id) async {
    return _box.get(id);
  }

  /// Find all limit alerts for a specific card
  Future<List<LimitAlert>> findByCardId(String cardId) async {
    final alerts = _box.values.where((alert) => alert.cardId == cardId).toList();

    // Sort by threshold (ascending)
    alerts.sort((a, b) => a.threshold.compareTo(b.threshold));

    return alerts;
  }

  /// Find all triggered alerts for a card
  Future<List<LimitAlert>> findTriggeredAlerts(String cardId) async {
    return _box.values
        .where((alert) => alert.cardId == cardId && alert.isTriggered)
        .toList();
  }

  /// Find all non-triggered alerts for a card
  Future<List<LimitAlert>> findNonTriggeredAlerts(String cardId) async {
    return _box.values
        .where((alert) => alert.cardId == cardId && !alert.isTriggered)
        .toList();
  }

  /// Find alert by card ID and threshold
  Future<LimitAlert?> findByCardIdAndThreshold(
    String cardId,
    double threshold,
  ) async {
    final alerts = _box.values.where(
      (alert) => alert.cardId == cardId && alert.threshold == threshold,
    );
    return alerts.isNotEmpty ? alerts.first : null;
  }

  /// Find all alerts
  Future<List<LimitAlert>> findAll() async {
    return _box.values.toList();
  }

  /// Find all triggered alerts across all cards
  Future<List<LimitAlert>> findAllTriggeredAlerts() async {
    return _box.values.where((alert) => alert.isTriggered).toList();
  }

  /// Update a limit alert
  Future<void> update(LimitAlert alert) async {
    await _box.put(alert.id, alert);
  }

  /// Delete a limit alert
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Delete all alerts for a card
  Future<void> deleteByCardId(String cardId) async {
    final alerts = await findByCardId(cardId);
    for (var alert in alerts) {
      await delete(alert.id);
    }
  }

  /// Reset all alerts for a card (set isTriggered to false)
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

  /// Reset a specific alert by threshold
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

  /// Check if an alert exists for a card and threshold
  Future<bool> exists(String cardId, double threshold) async {
    final alert = await findByCardIdAndThreshold(cardId, threshold);
    return alert != null;
  }

  /// Check if any alert is triggered for a card
  Future<bool> hasTriggeredAlerts(String cardId) async {
    final triggeredAlerts = await findTriggeredAlerts(cardId);
    return triggeredAlerts.isNotEmpty;
  }

  /// Get count of alerts for a card
  Future<int> countByCardId(String cardId) async {
    return _box.values.where((alert) => alert.cardId == cardId).length;
  }

  /// Get count of triggered alerts for a card
  Future<int> countTriggeredAlerts(String cardId) async {
    return _box.values
        .where((alert) => alert.cardId == cardId && alert.isTriggered)
        .length;
  }

  /// Get the highest triggered threshold for a card
  Future<double?> getHighestTriggeredThreshold(String cardId) async {
    final triggeredAlerts = await findTriggeredAlerts(cardId);
    if (triggeredAlerts.isEmpty) return null;

    triggeredAlerts.sort((a, b) => b.threshold.compareTo(a.threshold));
    return triggeredAlerts.first.threshold;
  }

  /// Clear all limit alerts (for testing)
  Future<void> clear() async {
    await _box.clear();
  }
}
