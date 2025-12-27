import '../models/limit_alert.dart';
import '../repositories/limit_alert_repository.dart';
import '../repositories/credit_card_repository.dart';
import 'credit_card_service.dart';
import 'notification_scheduler_service.dart';

class LimitAlertService {
  final LimitAlertRepository _alertRepo = LimitAlertRepository();
  final CreditCardRepository _cardRepo = CreditCardRepository();
  final CreditCardService _cardService = CreditCardService();
  final NotificationSchedulerService _notificationService =
      NotificationSchedulerService();
  static const int _limitAlertBaseId = 8000;
  static const double threshold80 = 80.0;
  static const double threshold90 = 90.0;
  static const double threshold100 = 100.0;
  Future<void> initializeAlertsForCard(String cardId) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }
    final existingAlerts = await _alertRepo.findByCardId(cardId);
    if (existingAlerts.isNotEmpty) {
      return;
    }
    final thresholds = [threshold80, threshold90, threshold100];

    for (var threshold in thresholds) {
      final alert = LimitAlert(
        id: '${cardId}_${threshold.toInt()}',
        cardId: cardId,
        threshold: threshold,
        isTriggered: false,
        triggeredAt: null,
        createdAt: DateTime.now(),
      );

      await _alertRepo.save(alert);
    }
  }
  Future<void> initializeAlertsForAllCards() async {
    final cards = await _cardRepo.findActive();

    for (var card in cards) {
      await initializeAlertsForCard(card.id);
    }
  }
  Future<double> calculateUtilizationPercentage(String cardId) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    if (card.creditLimit <= 0) {
      return 0.0;
    }

    final currentDebt = await _cardService.getCurrentDebt(cardId);
    final utilization = (currentDebt / card.creditLimit) * 100;
    return utilization > 100 ? 100.0 : utilization;
  }
  Future<bool> shouldTriggerAlert(String cardId, double threshold) async {
    final utilization = await calculateUtilizationPercentage(cardId);
    return utilization >= threshold;
  }
  Future<void> checkAndTriggerAlerts(String cardId) async {
    final utilization = await calculateUtilizationPercentage(cardId);
    final alerts = await _alertRepo.findByCardId(cardId);

    for (var alert in alerts) {
      if (utilization >= alert.threshold && !alert.isTriggered) {
        final updatedAlert = alert.copyWith(
          isTriggered: true,
          triggeredAt: () => DateTime.now(),
        );

        await _alertRepo.update(updatedAlert);
        await sendLimitNotification(cardId, alert.threshold, utilization);
      }
    }
  }
  Future<List<LimitAlert>> getActiveAlerts(String cardId) async {
    final alerts = await _alertRepo.findByCardId(cardId);
    return alerts.where((alert) => alert.isTriggered).toList();
  }
  Future<List<LimitAlert>> getAllAlerts(String cardId) async {
    return await _alertRepo.findByCardId(cardId);
  }
  Future<void> resetAlertsAfterPayment(String cardId) async {
    final utilization = await calculateUtilizationPercentage(cardId);
    final alerts = await _alertRepo.findByCardId(cardId);

    for (var alert in alerts) {
      if (utilization < alert.threshold && alert.isTriggered) {
        final updatedAlert = alert.copyWith(
          isTriggered: false,
          triggeredAt: () => null,
        );

        await _alertRepo.update(updatedAlert);
      }
    }
  }
  Future<void> resetAllAlerts(String cardId) async {
    await _alertRepo.resetAlerts(cardId);
  }
  Future<void> sendLimitNotification(
    String cardId,
    double threshold,
    double currentUtilization,
  ) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) return;

    final availableCredit = await _cardService.getAvailableCredit(cardId);
    final notificationId = _limitAlertBaseId + cardId.hashCode % 1000;

    String title;
    String body;
    NotificationPriority priority;

    if (threshold >= threshold100) {
      title = 'Limit Doldu!';
      body =
          '${card.bankName} ${card.cardName} kartınızın limiti doldu. '
          'Kalan limit: ₺${availableCredit.toStringAsFixed(2)}';
      priority = NotificationPriority.high;
    } else if (threshold >= threshold90) {
      title = 'Limite Çok Yaklaştınız!';
      body =
          '${card.bankName} ${card.cardName} kartınızın limitinin %${threshold.toInt()}\'i kullanıldı. '
          'Kalan limit: ₺${availableCredit.toStringAsFixed(2)}';
      priority = NotificationPriority.high;
    } else {
      title = 'Limit Uyarısı';
      body =
          '${card.bankName} ${card.cardName} kartınızın limitinin %${threshold.toInt()}\'i kullanıldı. '
          'Kalan limit: ₺${availableCredit.toStringAsFixed(2)}';
      priority = NotificationPriority.normal;
    }

    await _notificationService.scheduleNotification(
      id: notificationId + threshold.toInt(),
      title: title,
      body: body,
      scheduledDate: DateTime.now(),
      payload: 'limit_alert:$cardId:${threshold.toInt()}',
      priority: priority,
    );
  }
  Future<void> cancelLimitNotifications(String cardId) async {
    final notificationId = _limitAlertBaseId + cardId.hashCode % 1000;
    await _notificationService.cancelNotification(notificationId + 80);
    await _notificationService.cancelNotification(notificationId + 90);
    await _notificationService.cancelNotification(notificationId + 100);
  }
  Future<Map<String, dynamic>> getLimitAlertSummary(String cardId) async {
    final utilization = await calculateUtilizationPercentage(cardId);
    final alerts = await _alertRepo.findByCardId(cardId);
    final activeAlerts = alerts.where((a) => a.isTriggered).toList();
    final card = await _cardRepo.findById(cardId);
    final availableCredit = await _cardService.getAvailableCredit(cardId);

    return {
      'cardId': cardId,
      'cardName': card?.cardName ?? 'Unknown',
      'utilization': utilization,
      'availableCredit': availableCredit,
      'totalAlerts': alerts.length,
      'activeAlerts': activeAlerts.length,
      'alerts': alerts,
      'isAtRisk': utilization >= threshold80,
      'isCritical': utilization >= threshold90,
      'isFull': utilization >= threshold100,
    };
  }
  Future<List<Map<String, dynamic>>> getAllCardsLimitSummary() async {
    final cards = await _cardRepo.findActive();
    final summaries = <Map<String, dynamic>>[];

    for (var card in cards) {
      final summary = await getLimitAlertSummary(card.id);
      summaries.add(summary);
    }

    return summaries;
  }
  Future<bool> shouldShowVisualWarning(String cardId) async {
    final utilization = await calculateUtilizationPercentage(cardId);
    return utilization >= threshold80;
  }
  Future<int> getWarningLevel(String cardId) async {
    final utilization = await calculateUtilizationPercentage(cardId);

    if (utilization >= threshold100) {
      return 3;
    } else if (utilization >= threshold90) {
      return 2;
    } else if (utilization >= threshold80) {
      return 1;
    } else {
      return 0;
    }
  }
}
