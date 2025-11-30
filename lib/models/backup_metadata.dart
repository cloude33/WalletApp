/// Metadata for backup files
class BackupMetadata {
  final String version;
  final DateTime createdAt;
  final int transactionCount;
  final int budgetCount;
  final int walletCount;
  final String appVersion;

  const BackupMetadata({
    required this.version,
    required this.createdAt,
    required this.transactionCount,
    required this.budgetCount,
    required this.walletCount,
    this.appVersion = '1.0.0',
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'createdAt': createdAt.toIso8601String(),
        'transactionCount': transactionCount,
        'budgetCount': budgetCount,
        'walletCount': walletCount,
        'appVersion': appVersion,
      };

  factory BackupMetadata.fromJson(Map<String, dynamic> json) {
    return BackupMetadata(
      version: json['version'] ?? '1.0',
      createdAt: DateTime.parse(json['createdAt']),
      transactionCount: json['transactionCount'] ?? 0,
      budgetCount: json['budgetCount'] ?? 0,
      walletCount: json['walletCount'] ?? 0,
      appVersion: json['appVersion'] ?? '1.0.0',
    );
  }
}
