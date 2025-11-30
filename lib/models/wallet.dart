class Wallet {
  final String id;
  final String name;
  final double balance;
  final String type; // 'cash', 'credit_card', 'bank'
  final String color;
  final String icon;
  final int cutOffDay;
  final int paymentDay;
  final int installment;
  final double creditLimit; // Kredi/KMH Limiti

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
  });

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
    );
  }
}