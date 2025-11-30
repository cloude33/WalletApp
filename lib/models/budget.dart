class Budget {
  final String id;
  final String name;
  final String category;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final double spent;
  final bool isActive;

  Budget({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.spent = 0.0,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'amount': amount,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'spent': spent,
    'isActive': isActive,
  };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    id: json['id'],
    name: json['name'],
    category: json['category'],
    amount: json['amount'],
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    spent: json['spent'] ?? 0.0,
    isActive: json['isActive'] ?? true,
  );

  double get remaining => amount - spent;
  double get percentage => amount > 0 ? (spent / amount) * 100 : 0;
}