import 'package:json_annotation/json_annotation.dart';

part 'debt.g.dart';

enum DebtType {
  @JsonValue('lent')
  lent,

  @JsonValue('borrowed')
  borrowed,
}

enum DebtStatus {
  @JsonValue('active')
  active,

  @JsonValue('paid')
  paid,

  @JsonValue('overdue')
  overdue,
}

enum DebtCategory {
  @JsonValue('friend')
  friend,

  @JsonValue('family')
  family,

  @JsonValue('business')
  business,

  @JsonValue('other')
  other,
}

@JsonSerializable()
class Debt {
  final String id;
  final String personName;
  final String? phone;
  final double originalAmount;
  final double remainingAmount;
  final DebtType type;
  final DebtStatus status;
  final DebtCategory category;
  final DateTime createdDate;
  final DateTime? dueDate;
  final String? description;
  final List<String> paymentIds;
  final List<String> reminderIds;
  final DateTime? lastPaymentDate;
  final DateTime updatedDate;

  const Debt({
    required this.id,
    required this.personName,
    this.phone,
    required this.originalAmount,
    required this.remainingAmount,
    required this.type,
    required this.status,
    required this.category,
    required this.createdDate,
    this.dueDate,
    this.description,
    this.paymentIds = const [],
    this.reminderIds = const [],
    this.lastPaymentDate,
    required this.updatedDate,
  });

  factory Debt.fromJson(Map<String, dynamic> json) => _$DebtFromJson(json);
  Map<String, dynamic> toJson() => _$DebtToJson(this);

  Debt copyWith({
    String? id,
    String? personName,
    String? phone,
    double? originalAmount,
    double? remainingAmount,
    DebtType? type,
    DebtStatus? status,
    DebtCategory? category,
    DateTime? createdDate,
    DateTime? dueDate,
    String? description,
    List<String>? paymentIds,
    List<String>? reminderIds,
    DateTime? lastPaymentDate,
    DateTime? updatedDate,
  }) {
    return Debt(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      phone: phone ?? this.phone,
      originalAmount: originalAmount ?? this.originalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      type: type ?? this.type,
      status: status ?? this.status,
      category: category ?? this.category,
      createdDate: createdDate ?? this.createdDate,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      paymentIds: paymentIds ?? this.paymentIds,
      reminderIds: reminderIds ?? this.reminderIds,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

  bool get isPaid => remainingAmount <= 0.01;

  bool get isOverdue {
    if (dueDate == null || isPaid) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  double get paymentPercentage {
    if (originalAmount <= 0) return 0;
    return ((originalAmount - remainingAmount) / originalAmount) * 100;
  }

  double get paidAmount => originalAmount - remainingAmount;

  String get categoryText {
    switch (category) {
      case DebtCategory.friend:
        return 'Arkadaş';
      case DebtCategory.family:
        return 'Aile';
      case DebtCategory.business:
        return 'İş';
      case DebtCategory.other:
        return 'Diğer';
    }
  }

  String get dueDateStatus {
    if (dueDate == null) return 'Vade yok';
    if (isPaid) return 'Ödendi';

    final now = DateTime.now();
    final difference = dueDate!.difference(now).inDays;

    if (difference < 0) {
      return '${difference.abs()} gün gecikmiş';
    } else if (difference == 0) {
      return 'Bugün vade';
    } else if (difference <= 3) {
      return '$difference gün kaldı';
    } else {
      final day = dueDate!.day.toString().padLeft(2, '0');
      final month = dueDate!.month.toString().padLeft(2, '0');
      return 'Vade: $day.$month.${dueDate!.year}';
    }
  }

  String? validate() {
    if (personName.trim().isEmpty) {
      return 'Kişi adı boş olamaz';
    }
    if (originalAmount <= 0) {
      return 'Tutar sıfırdan büyük olmalı';
    }
    if (remainingAmount < 0) {
      return 'Kalan tutar negatif olamaz';
    }
    if (remainingAmount > originalAmount) {
      return 'Kalan tutar orijinal tutardan büyük olamaz';
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Debt && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
