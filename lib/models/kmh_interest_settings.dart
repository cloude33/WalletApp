class KmhInterestSettings {
  final double standardInterestRate;
  final double overdueInterestRate;
  final double kkdfRate;
  final double bsmvRate;

  const KmhInterestSettings({
    required this.standardInterestRate,
    required this.overdueInterestRate,
    required this.kkdfRate,
    required this.bsmvRate,
  });

  static const KmhInterestSettings defaults = KmhInterestSettings(
    standardInterestRate: 4.25,
    overdueInterestRate: 4.55,
    kkdfRate: 15.0,
    bsmvRate: 15.0,
  );

  Map<String, dynamic> toJson() => {
    'standardInterestRate': standardInterestRate,
    'overdueInterestRate': overdueInterestRate,
    'kkdfRate': kkdfRate,
    'bsmvRate': bsmvRate,
  };

  factory KmhInterestSettings.fromJson(Map<String, dynamic> json) {
    return KmhInterestSettings(
      standardInterestRate: (json['standardInterestRate'] as num?)?.toDouble() ?? 4.25,
      overdueInterestRate: (json['overdueInterestRate'] as num?)?.toDouble() ?? 4.55,
      kkdfRate: (json['kkdfRate'] as num?)?.toDouble() ?? 15.0,
      bsmvRate: (json['bsmvRate'] as num?)?.toDouble() ?? 15.0,
    );
  }

  KmhInterestSettings copyWith({
    double? standardInterestRate,
    double? overdueInterestRate,
    double? kkdfRate,
    double? bsmvRate,
  }) {
    return KmhInterestSettings(
      standardInterestRate: standardInterestRate ?? this.standardInterestRate,
      overdueInterestRate: overdueInterestRate ?? this.overdueInterestRate,
      kkdfRate: kkdfRate ?? this.kkdfRate,
      bsmvRate: bsmvRate ?? this.bsmvRate,
    );
  }
}
