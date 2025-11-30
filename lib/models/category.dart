import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String type; // 'income' or 'expense'
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
      'iconCodePoint': icon.codePoint,
      'color': color.value,
      'type': type,
      'isBank': isBank,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: _getIconFromCodePoint(json['iconCodePoint'] as int),
      color: Color(json['color'] as int),
      type: json['type'] as String,
      isBank: json['isBank'] as bool? ?? false,
    );
  }

  static IconData _getIconFromCodePoint(int codePoint) {
    // Map common icon codePoints to their const IconData
    switch (codePoint) {
      case 0xe25f: return Icons.account_balance_wallet;
      case 0xe8e5: return Icons.trending_up;
      case 0xe237: return Icons.card_giftcard;
      case 0xe3e8: return Icons.emoji_events;
      case 0xe227: return Icons.attach_money;
      case 0xf04bf: return Icons.water_drop;
      case 0xe14a: return Icons.checkroom;
      case 0xe80c: return Icons.school;
      case 0xe7e9: return Icons.celebration;
      case 0xe25d: return Icons.fitness_center;
      case 0xe56c: return Icons.restaurant;
      case 0xe3f4: return Icons.local_hospital;
      case 0xe25e: return Icons.weekend;
      case 0xe8cc: return Icons.shopping_cart;
      default: return Icons.category; // Fallback icon
    }
  }
}

final List<Category> _defaultCategories = [
  // Gelir Kategorileri
  Category(id: 'i1', name: 'Maaş', icon: Icons.account_balance_wallet, color: Colors.green, type: 'income'),
  Category(id: 'i2', name: 'Yatırım', icon: Icons.trending_up, color: Colors.teal, type: 'income'),
  Category(id: 'i3', name: 'Hediye', icon: Icons.card_giftcard, color: Colors.pink, type: 'income'),
  Category(id: 'i4', name: 'Ödül', icon: Icons.emoji_events, color: Colors.amber, type: 'income'),
  Category(id: 'i5', name: 'Diğer Gelir', icon: Icons.attach_money, color: Colors.lightGreen, type: 'income'),
  
  // Gider Kategorileri
  Category(id: 'e1', name: 'Faturalar', icon: Icons.water_drop, color: Colors.cyan, type: 'expense'),
  Category(id: 'e2', name: 'Giyim', icon: Icons.checkroom, color: Colors.blue, type: 'expense'),
  Category(id: 'e3', name: 'Eğitim', icon: Icons.school, color: Colors.teal, type: 'expense'),
  Category(id: 'e4', name: 'Eğlence', icon: Icons.celebration, color: Colors.lightBlue, type: 'expense'),
  Category(id: 'e5', name: 'Fitness', icon: Icons.fitness_center, color: Colors.lightGreen, type: 'expense'),
  Category(id: 'e6', name: 'Yiyecek', icon: Icons.restaurant, color: Colors.yellow, type: 'expense'),
  Category(id: 'e7', name: 'Hediyeler', icon: Icons.card_giftcard, color: Colors.orange, type: 'expense'),
  Category(id: 'e8', name: 'Sağlık', icon: Icons.local_hospital, color: Colors.red, type: 'expense'),
  Category(id: 'e9', name: 'Mobilya', icon: Icons.weekend, color: Colors.purple, type: 'expense'),
  Category(id: 'e10', name: 'Alışveriş', icon: Icons.shopping_cart, color: Colors.deepPurple, type: 'expense'),
];

List<Category> defaultCategories = List.from(_defaultCategories);