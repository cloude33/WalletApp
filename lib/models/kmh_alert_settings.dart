class KmhAlertSettings {
  final bool limitAlertsEnabled;
  final double warningThreshold;
  final double criticalThreshold;
  final bool interestNotificationsEnabled;
  final double minimumInterestAmount;

  const KmhAlertSettings({
    required this.limitAlertsEnabled,
    required this.warningThreshold,
    required this.criticalThreshold,
    required this.interestNotificationsEnabled,
    required this.minimumInterestAmount,
  });
  static const KmhAlertSettings defaults = KmhAlertSettings(
    limitAlertsEnabled: true,
    warningThreshold: 80.0,
    criticalThreshold: 95.0,
    interestNotificationsEnabled: true,
    minimumInterestAmount: 1.0,
  );

  Map<String, dynamic> toJson() => {
    'limitAlertsEnabled': limitAlertsEnabled,
    'warningThreshold': warningThreshold,
    'criticalThreshold': criticalThreshold,
    'interestNotificationsEnabled': interestNotificationsEnabled,
    'minimumInterestAmount': minimumInterestAmount,
  };

  factory KmhAlertSettings.fromJson(Map<String, dynamic> json) {
    return KmhAlertSettings(
      limitAlertsEnabled: json['limitAlertsEnabled'] ?? true,
      warningThreshold: json['warningThreshold'] ?? 80.0,
      criticalThreshold: json['criticalThreshold'] ?? 95.0,
      interestNotificationsEnabled: json['interestNotificationsEnabled'] ?? true,
      minimumInterestAmount: json['minimumInterestAmount'] ?? 1.0,
    );
  }

  KmhAlertSettings copyWith({
    bool? limitAlertsEnabled,
    double? warningThreshold,
    double? criticalThreshold,
    bool? interestNotificationsEnabled,
    double? minimumInterestAmount,
  }) {
    return KmhAlertSettings(
      limitAlertsEnabled: limitAlertsEnabled ?? this.limitAlertsEnabled,
      warningThreshold: warningThreshold ?? this.warningThreshold,
      criticalThreshold: criticalThreshold ?? this.criticalThreshold,
      interestNotificationsEnabled: interestNotificationsEnabled ?? this.interestNotificationsEnabled,
      minimumInterestAmount: minimumInterestAmount ?? this.minimumInterestAmount,
    );
  }
}
