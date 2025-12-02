import 'package:json_annotation/json_annotation.dart';

part 'bill_template.g.dart';

/// Fatura kategorileri
enum BillTemplateCategory {
  electricity,
  water,
  gas,
  internet,
  phone,
  rent,
  insurance,
  subscription,
  other,
}

/// Fatura şablonu - Ayarlarda bir kez tanımlanır
@JsonSerializable()
class BillTemplate {
  final String id;
  final String name; // Örn: "Ev Elektriği"
  final String? provider; // Örn: "TOROSLAR EDAŞ"
  final BillTemplateCategory category;
  final String? accountNumber; // Abone numarası
  final String? phoneNumber; // GSM numarası (telefon faturaları için)
  final String? description;
  final bool isActive; // Aktif mi?
  final DateTime createdDate;
  final DateTime updatedDate;

  const BillTemplate({
    required this.id,
    required this.name,
    this.provider,
    required this.category,
    this.accountNumber,
    this.phoneNumber,
    this.description,
    this.isActive = true,
    required this.createdDate,
    required this.updatedDate,
  });

  factory BillTemplate.fromJson(Map<String, dynamic> json) =>
      _$BillTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$BillTemplateToJson(this);

  BillTemplate copyWith({
    String? id,
    String? name,
    String? provider,
    BillTemplateCategory? category,
    String? accountNumber,
    String? phoneNumber,
    String? description,
    bool? isActive,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return BillTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      category: category ?? this.category,
      accountNumber: accountNumber ?? this.accountNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

  String get categoryDisplayName {
    switch (category) {
      case BillTemplateCategory.electricity:
        return 'Elektrik';
      case BillTemplateCategory.water:
        return 'Su';
      case BillTemplateCategory.gas:
        return 'Doğalgaz';
      case BillTemplateCategory.internet:
        return 'İnternet';
      case BillTemplateCategory.phone:
        return 'Telefon';
      case BillTemplateCategory.rent:
        return 'Kira';
      case BillTemplateCategory.insurance:
        return 'Sigorta';
      case BillTemplateCategory.subscription:
        return 'Abonelik';
      case BillTemplateCategory.other:
        return 'Diğer';
    }
  }
}
