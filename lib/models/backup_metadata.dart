class BackupMetadata {
  final String version;
  final DateTime createdAt;
  final int transactionCount;
  final int walletCount;
  final String appVersion;
  final String platform; // 'android' or 'ios'
  final String deviceModel;

  const BackupMetadata({
    required this.version,
    required this.createdAt,
    required this.transactionCount,
    required this.walletCount,
    this.appVersion = '1.0.0',
    this.platform = 'unknown',
    this.deviceModel = 'unknown',
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'createdAt': createdAt.toIso8601String(),
    'transactionCount': transactionCount,
    'walletCount': walletCount,
    'appVersion': appVersion,
    'platform': platform,
    'deviceModel': deviceModel,
  };

  factory BackupMetadata.fromJson(Map<String, dynamic> json) {
    return BackupMetadata(
      version: json['version'] ?? '1.0',
      createdAt: DateTime.parse(json['createdAt']),
      transactionCount: json['transactionCount'] ?? 0,
      walletCount: json['walletCount'] ?? 0,
      appVersion: json['appVersion'] ?? '1.0.0',
      platform: json['platform'] ?? 'unknown',
      deviceModel: json['deviceModel'] ?? 'unknown',
    );
  }

  bool get isAndroidBackup => platform.toLowerCase() == 'android';
  bool get isIOSBackup => platform.toLowerCase() == 'ios';
  bool get isCrossPlatformCompatible => 
      version == '1.0' || 
      version == '2.0' || 
      version.startsWith('2.');
}
