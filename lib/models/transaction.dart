class Transaction {
  final String id;
  final String type; // 'income', 'expense', 'transfer'
  final double amount;
  final String description;
  final String category;
  final String walletId;
  final DateTime date;
  final String? memo;
  final List<String>? images;
  final int? installments; // Taksit sayısı
  final int? currentInstallment; // Mevcut taksit numarası
  final String? parentTransactionId; // Ana işlem ID'si (taksitli işlemler için)
  final String? recurringTransactionId; // Tekrarlayan işlem ID'si
  final bool isIncome; // Gelir mi gider mi

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    required this.walletId,
    required this.date,
    this.memo,
    this.images,
    this.installments,
    this.currentInstallment,
    this.parentTransactionId,
    this.recurringTransactionId,
    this.isIncome = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'amount': amount,
    'description': description,
    'category': category,
    'walletId': walletId,
    'date': date.toIso8601String(),
    'memo': memo,
    'images': images,
    'installments': installments,
    'currentInstallment': currentInstallment,
    'parentTransactionId': parentTransactionId,
    'recurringTransactionId': recurringTransactionId,
    'isIncome': isIncome,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    type: json['type'],
    amount: json['amount'],
    description: json['description'],
    category: json['category'],
    walletId: json['walletId'],
    date: DateTime.parse(json['date']),
    memo: json['memo'],
    images: json['images'] != null ? List<String>.from(json['images']) : null,
    installments: json['installments'],
    currentInstallment: json['currentInstallment'],
    parentTransactionId: json['parentTransactionId'],
    recurringTransactionId: json['recurringTransactionId'],
    isIncome: json['isIncome'] ?? false,
  );

  Transaction copyWith({
    String? id,
    String? type,
    double? amount,
    String? description,
    String? category,
    String? walletId,
    DateTime? date,
    String? memo,
    List<String>? images,
    int? installments,
    int? currentInstallment,
    String? parentTransactionId,
    String? recurringTransactionId,
    bool? isIncome,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      walletId: walletId ?? this.walletId,
      date: date ?? this.date,
      memo: memo ?? this.memo,
      images: images ?? this.images,
      installments: installments ?? this.installments,
      currentInstallment: currentInstallment ?? this.currentInstallment,
      parentTransactionId: parentTransactionId ?? this.parentTransactionId,
      recurringTransactionId: recurringTransactionId ?? this.recurringTransactionId,
      isIncome: isIncome ?? this.isIncome,
    );
  }
}
