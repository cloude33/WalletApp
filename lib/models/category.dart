import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String type;
  final bool isBank;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isBank = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconName': _getIconName(icon),
      'color': color.toARGB32(),
      'type': type,
      'isBank': isBank,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: _getIconFromJson(json),
      color: Color(json['color'] as int),
      type: json['type'] as String,
      isBank: json['isBank'] as bool? ?? false,
    );
  }
  static IconData _getIconFromJson(Map<String, dynamic> json) {
    if (json.containsKey('iconName')) {
      return _getIconFromName(json['iconName'] as String);
    }
    if (json.containsKey('iconCodePoint')) {
      final int codePoint = json['iconCodePoint'] as int;
      final IconData? mappedIcon = _getIconFromCodePoint(codePoint);
      if (mappedIcon != null) {
        return mappedIcon;
      }
    }
    return Icons.category;
  }
  static String _getIconName(IconData icon) {
    if (icon == Icons.account_balance_wallet) return 'account_balance_wallet';
    if (icon == Icons.trending_up) return 'trending_up';
    if (icon == Icons.card_giftcard) return 'card_giftcard';
    if (icon == Icons.emoji_events) return 'emoji_events';
    if (icon == Icons.attach_money) return 'attach_money';
    if (icon == Icons.water_drop) return 'water_drop';
    if (icon == Icons.checkroom) return 'checkroom';
    if (icon == Icons.school) return 'school';
    if (icon == Icons.celebration) return 'celebration';
    if (icon == Icons.fitness_center) return 'fitness_center';
    if (icon == Icons.restaurant) return 'restaurant';
    if (icon == Icons.local_hospital) return 'local_hospital';
    if (icon == Icons.weekend) return 'weekend';
    if (icon == Icons.shopping_cart) return 'shopping_cart';
    if (icon == Icons.bolt) return 'bolt';
    if (icon == Icons.receipt_long) return 'receipt_long';
    return 'category';
  }
  static IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'trending_up':
        return Icons.trending_up;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'attach_money':
        return Icons.attach_money;
      case 'water_drop':
        return Icons.water_drop;
      case 'checkroom':
        return Icons.checkroom;
      case 'school':
        return Icons.school;
      case 'celebration':
        return Icons.celebration;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'weekend':
        return Icons.weekend;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'bolt':
      case 'electric_bolt':
        return Icons.bolt;
      case 'receipt':
      case 'receipt_long':
        return Icons.receipt_long;
      default:
        return Icons.category;
    }
  }
  static IconData? _getIconFromCodePoint(int codePoint) {
    switch (codePoint) {
      case 0xe84d:
        return Icons.account_balance_wallet;
      case 0xe8e5:
        return Icons.trending_up;
      case 0xe8f6:
        return Icons.card_giftcard;
      case 0xea6f:
        return Icons.emoji_events;
      case 0xe227:
        return Icons.attach_money;
      case 0xe798:
        return Icons.water_drop;
      case 0xf1d9:
        return Icons.checkroom;
      case 0xe80c:
        return Icons.school;
      case 0xea65:
        return Icons.celebration;
      case 0xeb43:
        return Icons.fitness_center;
      case 0xe56c:
        return Icons.restaurant;
      case 0xe88e:
        return Icons.local_hospital;
      case 0xf000:
        return Icons.weekend;
      case 0xe8cc:
        return Icons.shopping_cart;
      default:
        return null;
    }
  }
}

final List<Category> _defaultCategories = [
  Category(
    id: 'i1',
    name: 'Maaş',
    icon: Icons.account_balance_wallet,
    color: Colors.green,
    type: 'income',
  ),
  Category(
    id: 'i2',
    name: 'Yatırım',
    icon: Icons.trending_up,
    color: Colors.teal,
    type: 'income',
  ),
  Category(
    id: 'i3',
    name: 'Hediye',
    icon: Icons.card_giftcard,
    color: Colors.pink,
    type: 'income',
  ),
  Category(
    id: 'i4',
    name: 'Ödül',
    icon: Icons.emoji_events,
    color: Colors.amber,
    type: 'income',
  ),
  Category(
    id: 'i5',
    name: 'Diğer Gelir',
    icon: Icons.attach_money,
    color: Colors.lightGreen,
    type: 'income',
  ),
  Category(
    id: 'e1',
    name: 'Faturalar',
    icon: Icons.receipt_long,
    color: Colors.cyan,
    type: 'expense',
  ),
  Category(
    id: 'e2',
    name: 'Giyim',
    icon: Icons.checkroom,
    color: Colors.blue,
    type: 'expense',
  ),
  Category(
    id: 'e3',
    name: 'Eğitim',
    icon: Icons.school,
    color: Colors.teal,
    type: 'expense',
  ),
  Category(
    id: 'e4',
    name: 'Eğlence',
    icon: Icons.celebration,
    color: Colors.lightBlue,
    type: 'expense',
  ),
  Category(
    id: 'e5',
    name: 'Fitness',
    icon: Icons.fitness_center,
    color: Colors.lightGreen,
    type: 'expense',
  ),
  Category(
    id: 'e6',
    name: 'Yiyecek',
    icon: Icons.restaurant,
    color: Colors.yellow,
    type: 'expense',
  ),
  Category(
    id: 'e7',
    name: 'Hediyeler',
    icon: Icons.card_giftcard,
    color: Colors.orange,
    type: 'expense',
  ),
  Category(
    id: 'e8',
    name: 'Sağlık',
    icon: Icons.local_hospital,
    color: Colors.red,
    type: 'expense',
  ),
  Category(
    id: 'e9',
    name: 'Mobilya',
    icon: Icons.weekend,
    color: Colors.purple,
    type: 'expense',
  ),
  Category(
    id: 'e10',
    name: 'Alışveriş',
    icon: Icons.shopping_cart,
    color: Colors.deepPurple,
    type: 'expense',
  ),
];

List<Category> defaultCategories = List.from(_defaultCategories);
