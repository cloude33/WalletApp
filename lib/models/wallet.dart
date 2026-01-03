class Wallet {
  final String id;
  final String name;
  final double balance;
  final String type;
  final String color;
  final String icon;
  final int cutOffDay;
  final int paymentDay;
  final int installment;
  final double creditLimit;
  /// The interest rate for this wallet.
  /// For KMH (Overdraft) accounts, this is interpreted as a monthly rate (e.g. 4.25).
  final double? interestRate;
  final DateTime? lastInterestDate;
  final double? accruedInterest;
  final String? accountNumber;
  final String? bankName;
  final String? iban;
  Wallet({
    required this.id,
    required this.name,
    required this.balance,
    required this.type,
    required this.color,
    required this.icon,
    this.cutOffDay = 0,
    this.paymentDay = 0,
    this.installment = 1,
    this.creditLimit = 0.0,
    this.interestRate,
    this.lastInterestDate,
    this.accruedInterest,
    this.accountNumber,
    this.bankName,
    this.iban,
  });
  bool get isKmhAccount => type == 'overdraft' || (type == 'bank' && creditLimit > 0);
  double get usedCredit => balance < 0 ? balance.abs() : 0.0;
  double get availableCredit => creditLimit + balance;
  double get utilizationRate => creditLimit > 0 ? (usedCredit / creditLimit) * 100 : 0.0;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'balance': balance,
    'type': type,
    'color': color,
    'icon': icon,
    'cutOffDay': cutOffDay,
    'paymentDay': paymentDay,
    'installment': installment,
    'creditLimit': creditLimit,
    'interestRate': interestRate,
    'lastInterestDate': lastInterestDate?.toIso8601String(),
    'accruedInterest': accruedInterest,
    'accountNumber': accountNumber,
    'bankName': bankName,
    'iban': iban,
  };
  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
    id: json['id'],
    name: json['name'],
    balance: json['balance'],
    type: json['type'],
    color: json['color'],
    icon: json['icon'],
    cutOffDay: json['cutOffDay'] ?? 0,
    paymentDay: json['paymentDay'] ?? 0,
    installment: json['installment'] ?? 1,
    creditLimit: json['creditLimit'] ?? 0.0,
    interestRate: json['interestRate'],
    lastInterestDate: json['lastInterestDate'] != null 
        ? DateTime.parse(json['lastInterestDate']) 
        : null,
    accruedInterest: json['accruedInterest'],
    accountNumber: json['accountNumber'],
    bankName: json['bankName'],
    iban: json['iban'],
  );
  Wallet copyWith({
    String? id,
    String? name,
    double? balance,
    String? type,
    String? color,
    String? icon,
    int? cutOffDay,
    int? paymentDay,
    int? installment,
    double? creditLimit,
    double? interestRate,
    bool updateInterestRate = false,
    DateTime? lastInterestDate,
    bool updateLastInterestDate = false,
    double? accruedInterest,
    bool updateAccruedInterest = false,
    String? accountNumber,
    bool updateAccountNumber = false,
    String? bankName,
    bool updateBankName = false,
    String? iban,
    bool updateIban = false,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      type: type ?? this.type,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      cutOffDay: cutOffDay ?? this.cutOffDay,
      paymentDay: paymentDay ?? this.paymentDay,
      installment: installment ?? this.installment,
      creditLimit: creditLimit ?? this.creditLimit,
      interestRate: updateInterestRate ? interestRate : (interestRate ?? this.interestRate),
      lastInterestDate: updateLastInterestDate ? lastInterestDate : (lastInterestDate ?? this.lastInterestDate),
      accruedInterest: updateAccruedInterest ? accruedInterest : (accruedInterest ?? this.accruedInterest),
      accountNumber: updateAccountNumber ? accountNumber : (accountNumber ?? this.accountNumber),
      bankName: updateBankName ? bankName : (bankName ?? this.bankName),
      iban: updateIban ? iban : (iban ?? this.iban),
    );
  }
}
