class Loan {
  final String id;
  final String name;
  final String bankName;
  final double totalAmount;
  final double remainingAmount;
  final int totalInstallments;
  final int remainingInstallments;
  final int currentInstallment;
  final double installmentAmount;
  final DateTime startDate;
  final DateTime endDate;
  final String walletId;
  final List<LoanInstallment> installments;

  Loan({
    required this.id,
    required this.name,
    required this.bankName,
    required this.totalAmount,
    required this.remainingAmount,
    required this.totalInstallments,
    required this.remainingInstallments,
    required this.currentInstallment,
    required this.installmentAmount,
    required this.startDate,
    required this.endDate,
    required this.walletId,
    required this.installments,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bankName': bankName,
    'totalAmount': totalAmount,
    'remainingAmount': remainingAmount,
    'totalInstallments': totalInstallments,
    'remainingInstallments': remainingInstallments,
    'currentInstallment': currentInstallment,
    'installmentAmount': installmentAmount,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'walletId': walletId,
    'installments': installments.map((i) => i.toJson()).toList(),
  };

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
    id: json['id'],
    name: json['name'],
    bankName: json['bankName'],
    totalAmount: json['totalAmount'],
    remainingAmount: json['remainingAmount'],
    totalInstallments: json['totalInstallments'],
    remainingInstallments: json['remainingInstallments'],
    currentInstallment: json['currentInstallment'],
    installmentAmount: json['installmentAmount'],
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    walletId: json['walletId'],
    installments: (json['installments'] as List)
        .map((i) => LoanInstallment.fromJson(i))
        .toList(),
  );
}

class LoanInstallment {
  final int installmentNumber;
  final double amount;
  final DateTime dueDate;
  final DateTime? paymentDate;
  final bool isPaid;

  LoanInstallment({
    required this.installmentNumber,
    required this.amount,
    required this.dueDate,
    this.paymentDate,
    this.isPaid = false,
  });

  Map<String, dynamic> toJson() => {
    'installmentNumber': installmentNumber,
    'amount': amount,
    'dueDate': dueDate.toIso8601String(),
    'paymentDate': paymentDate?.toIso8601String(),
    'isPaid': isPaid,
  };

  factory LoanInstallment.fromJson(Map<String, dynamic> json) =>
      LoanInstallment(
        installmentNumber: json['installmentNumber'],
        amount: json['amount'],
        dueDate: DateTime.parse(json['dueDate']),
        paymentDate: json['paymentDate'] != null
            ? DateTime.parse(json['paymentDate'])
            : null,
        isPaid: json['isPaid'] ?? false,
      );
}
