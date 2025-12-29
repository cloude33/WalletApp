import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/wallet.dart';
import '../models/kmh_alert.dart';
import '../models/kmh_alert_settings.dart';
import '../models/app_notification.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
class KmhAlertService {
  final DataService _dataService;
  final NotificationService _notificationService;
  final Uuid _uuid = const Uuid();

  static const String _settingsKey = 'kmh_alert_settings';
  static const String _lastCheckKey = 'kmh_alert_last_check';
  KmhAlertSettings? _cachedSettings;

  KmhAlertService({
    DataService? dataService,
    NotificationService? notificationService,
  })  : _dataService = dataService ?? DataService(),
        _notificationService = notificationService ?? NotificationService();
  Future<KmhAlertSettings> getAlertSettings() async {
    if (_cachedSettings != null) return _cachedSettings!;

    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_settingsKey);

    if (json == null) {
      _cachedSettings = KmhAlertSettings.defaults;
      await updateAlertSettings(_cachedSettings!);
      return _cachedSettings!;
    }

    _cachedSettings = KmhAlertSettings.fromJson(jsonDecode(json));
    return _cachedSettings!;
  }
  Future<void> updateAlertSettings(KmhAlertSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    _cachedSettings = settings;
  }
  Future<List<KmhAlert>> checkAccountAlerts(Wallet account) async {
    final alerts = <KmhAlert>[];
    if (!account.isKmhAccount) {
      return alerts;
    }

    final settings = await getAlertSettings();
    if (settings.limitAlertsEnabled && account.balance < 0) {
      final utilizationRate = account.utilizationRate;
      if (utilizationRate >= settings.criticalThreshold) {
        alerts.add(KmhAlert(
          type: KmhAlertType.limitCritical,
          walletId: account.id,
          walletName: account.name,
          message: 'KMH limitinizin %${utilizationRate.toStringAsFixed(1)}\'ini kullandınız! '
              'Kullanılabilir kredi: ₺${account.availableCredit.toStringAsFixed(2)}',
          utilizationRate: utilizationRate,
        ));
      }
      else if (utilizationRate >= settings.warningThreshold) {
        alerts.add(KmhAlert(
          type: KmhAlertType.limitWarning,
          walletId: account.id,
          walletName: account.name,
          message: 'KMH limitinizin %${utilizationRate.toStringAsFixed(1)}\'ini kullandınız. '
              'Kullanılabilir kredi: ₺${account.availableCredit.toStringAsFixed(2)}',
          utilizationRate: utilizationRate,
        ));
      }
    }

    return alerts;
  }
  Future<List<KmhAlert>> checkAllAccountsForAlerts() async {
    final wallets = await _dataService.getWallets();
    final kmhAccounts = wallets.where((w) => w.isKmhAccount).toList();

    final allAlerts = <KmhAlert>[];
    for (final account in kmhAccounts) {
      final alerts = await checkAccountAlerts(account);
      allAlerts.addAll(alerts);
    }

    return allAlerts;
  }
  Future<void> sendLimitWarning(Wallet account, double utilizationRate) async {
    final settings = await getAlertSettings();
    if (!settings.limitAlertsEnabled) {
      return;
    }
    final isCritical = utilizationRate >= settings.criticalThreshold;
    final notificationType = isCritical 
        ? NotificationType.kmhLimitCritical 
        : NotificationType.kmhLimitWarning;
    final priority = isCritical 
        ? NotificationPriority.urgent 
        : NotificationPriority.high;

    final notification = AppNotification(
      id: _uuid.v4(),
      type: notificationType,
      priority: priority,
      title: isCritical ? 'KMH Limit Kritik!' : 'KMH Limit Uyarısı',
      message: '${account.name}: KMH limitinizin %${utilizationRate.toStringAsFixed(1)}\'ini kullandınız. '
          'Kullanılabilir kredi: ₺${account.availableCredit.toStringAsFixed(2)}',
      createdAt: DateTime.now(),
      data: {
        'walletId': account.id,
        'walletName': account.name,
        'utilizationRate': utilizationRate,
        'usedCredit': account.usedCredit,
        'availableCredit': account.availableCredit,
        'creditLimit': account.creditLimit,
      },
      actions: [
        const NotificationAction(id: 'view', title: 'Görüntüle'),
        const NotificationAction(id: 'deposit', title: 'Para Yatır'),
      ],
    );

    await _notificationService.addNotification(notification);
  }
  Future<void> sendInterestNotification(
    Wallet account,
    double interestAmount,
  ) async {
    final settings = await getAlertSettings();
    if (!settings.interestNotificationsEnabled) {
      return;
    }
    if (interestAmount < settings.minimumInterestAmount) {
      return;
    }

    final notification = AppNotification(
      id: _uuid.v4(),
      type: NotificationType.kmhInterestAccrued,
      priority: NotificationPriority.normal,
      title: 'KMH Faiz Tahakkuku',
      message: '${account.name}: ₺${interestAmount.toStringAsFixed(2)} faiz tahakkuk etti. '
          'Güncel borç: ₺${account.usedCredit.toStringAsFixed(2)}',
      createdAt: DateTime.now(),
      data: {
        'walletId': account.id,
        'walletName': account.name,
        'interestAmount': interestAmount,
        'currentDebt': account.usedCredit,
        'accruedInterest': account.accruedInterest,
      },
      actions: [
        const NotificationAction(id: 'view', title: 'Görüntüle'),
        const NotificationAction(id: 'payment_plan', title: 'Ödeme Planı'),
      ],
    );

    await _notificationService.addNotification(notification);
  }
  Future<int> checkAndSendAlerts() async {
    final alerts = await checkAllAccountsForAlerts();
    int notificationsSent = 0;

    for (final alert in alerts) {
      final wallets = await _dataService.getWallets();
      final wallet = wallets.firstWhere(
        (w) => w.id == alert.walletId,
        orElse: () => throw Exception('Wallet not found'),
      );
      switch (alert.type) {
        case KmhAlertType.limitWarning:
        case KmhAlertType.limitCritical:
          if (alert.utilizationRate != null) {
            await sendLimitWarning(wallet, alert.utilizationRate!);
            notificationsSent++;
          }
          break;
        case KmhAlertType.interestAccrued:
          if (alert.interestAmount != null) {
            await sendInterestNotification(wallet, alert.interestAmount!);
            notificationsSent++;
          }
          break;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());

    return notificationsSent;
  }
  Future<DateTime?> getLastCheckTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastCheckKey);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }
  void clearCache() {
    _cachedSettings = null;
  }
}
