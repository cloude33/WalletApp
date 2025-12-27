library;
enum AssetType {
  cash,
  bankAccount,
  kmhPositive,
  investment,
  other,
}
class NetWorthTrendData {
  final DateTime date;
  final double assets;
  final double liabilities;
  final double netWorth;

  NetWorthTrendData({
    required this.date,
    required this.assets,
    required this.liabilities,
    required this.netWorth,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'assets': assets,
    'liabilities': liabilities,
    'netWorth': netWorth,
  };

  factory NetWorthTrendData.fromJson(Map<String, dynamic> json) => NetWorthTrendData(
    date: DateTime.parse(json['date']),
    assets: json['assets'],
    liabilities: json['liabilities'],
    netWorth: json['netWorth'],
  );
}
class FinancialHealthScore {
  final double liquidityScore;
  final double debtManagementScore;
  final double savingsScore;
  final double investmentScore;
  final double overallScore;
  final List<String> recommendations;

  FinancialHealthScore({
    required this.liquidityScore,
    required this.debtManagementScore,
    required this.savingsScore,
    required this.investmentScore,
    required this.overallScore,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() => {
    'liquidityScore': liquidityScore,
    'debtManagementScore': debtManagementScore,
    'savingsScore': savingsScore,
    'investmentScore': investmentScore,
    'overallScore': overallScore,
    'recommendations': recommendations,
  };

  factory FinancialHealthScore.fromJson(Map<String, dynamic> json) => FinancialHealthScore(
    liquidityScore: json['liquidityScore'],
    debtManagementScore: json['debtManagementScore'],
    savingsScore: json['savingsScore'],
    investmentScore: json['investmentScore'],
    overallScore: json['overallScore'],
    recommendations: List<String>.from(json['recommendations']),
  );
}
class AssetAnalysis {
  final double totalAssets;
  final double totalLiabilities;
  final double netWorth;
  final double liquidityRatio;
  final Map<AssetType, double> assetBreakdown;
  final double cashAndEquivalents;
  final double bankAccounts;
  final double positiveKmhBalances;
  final double investments;
  final List<NetWorthTrendData> netWorthTrend;
  final FinancialHealthScore healthScore;

  AssetAnalysis({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
    required this.liquidityRatio,
    required this.assetBreakdown,
    required this.cashAndEquivalents,
    required this.bankAccounts,
    required this.positiveKmhBalances,
    required this.investments,
    required this.netWorthTrend,
    required this.healthScore,
  });

  Map<String, dynamic> toJson() => {
    'totalAssets': totalAssets,
    'totalLiabilities': totalLiabilities,
    'netWorth': netWorth,
    'liquidityRatio': liquidityRatio,
    'assetBreakdown': assetBreakdown.map(
      (key, value) => MapEntry(key.name, value),
    ),
    'cashAndEquivalents': cashAndEquivalents,
    'bankAccounts': bankAccounts,
    'positiveKmhBalances': positiveKmhBalances,
    'investments': investments,
    'netWorthTrend': netWorthTrend.map((n) => n.toJson()).toList(),
    'healthScore': healthScore.toJson(),
  };

  factory AssetAnalysis.fromJson(Map<String, dynamic> json) => AssetAnalysis(
    totalAssets: json['totalAssets'],
    totalLiabilities: json['totalLiabilities'],
    netWorth: json['netWorth'],
    liquidityRatio: json['liquidityRatio'],
    assetBreakdown: (json['assetBreakdown'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        AssetType.values.firstWhere((t) => t.name == key),
        value as double,
      ),
    ),
    cashAndEquivalents: json['cashAndEquivalents'],
    bankAccounts: json['bankAccounts'],
    positiveKmhBalances: json['positiveKmhBalances'],
    investments: json['investments'],
    netWorthTrend: (json['netWorthTrend'] as List)
        .map((n) => NetWorthTrendData.fromJson(n))
        .toList(),
    healthScore: FinancialHealthScore.fromJson(json['healthScore']),
  );
}
