enum KmhAlertType {
  limitWarning,
  limitCritical,
  interestAccrued,
}
class KmhAlert {
  final KmhAlertType type;
  final String walletId;
  final String walletName;
  final String message;
  final double? utilizationRate;
  final double? interestAmount;
  final DateTime timestamp;

  KmhAlert({
    required this.type,
    required this.walletId,
    required this.walletName,
    required this.message,
    this.utilizationRate,
    this.interestAmount,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'walletId': walletId,
    'walletName': walletName,
    'message': message,
    'utilizationRate': utilizationRate,
    'interestAmount': interestAmount,
    'timestamp': timestamp.toIso8601String(),
  };

  factory KmhAlert.fromJson(Map<String, dynamic> json) {
    return KmhAlert(
      type: KmhAlertType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => KmhAlertType.limitWarning,
      ),
      walletId: json['walletId'],
      walletName: json['walletName'],
      message: json['message'],
      utilizationRate: json['utilizationRate'],
      interestAmount: json['interestAmount'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
