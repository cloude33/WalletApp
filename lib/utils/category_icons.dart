import 'package:flutter/material.dart';

// Comprehensive icon list for categories
class CategoryIcons {
  static final List<IconData> allIcons = [
    // Finance & Money
    Icons.account_balance,
    Icons.account_balance_wallet,
    Icons.attach_money,
    Icons.money,
    Icons.currency_exchange,
    Icons.savings,
    Icons.credit_card,
    Icons.payment,
    Icons.wallet,
    
    // Shopping & Commerce
    Icons.shopping_cart,
    Icons.shopping_bag,
    Icons.store,
    Icons.local_mall,
    Icons.local_grocery_store,
    Icons.add_shopping_cart,
    
    // Food & Dining
    Icons.restaurant,
    Icons.local_dining,
    Icons.fastfood,
    Icons.local_pizza,
    Icons.local_cafe,
    Icons.coffee,
    Icons.lunch_dining,
    Icons.dinner_dining,
    Icons.breakfast_dining,
    Icons.cake,
    Icons.icecream,
    
    // Transportation
    Icons.directions_car,
    Icons.directions_bus,
    Icons.directions_subway,
    Icons.flight,
    Icons.local_taxi,
    Icons.train,
    Icons.two_wheeler,
    Icons.electric_car,
    Icons.local_gas_station,
    Icons.local_parking,
    
    // Home & Living
    Icons.home,
    Icons.house,
    Icons.apartment,
    Icons.cottage,
    Icons.weekend,
    Icons.chair,
    Icons.bed,
    Icons.kitchen,
    Icons.countertops,
    Icons.light,
    Icons.lightbulb,
    
    // Utilities & Bills
    Icons.water_drop,
    Icons.electric_bolt,
    Icons.wifi,
    Icons.phone,
    Icons.smartphone,
    Icons.router,
    Icons.cable,
    
    // Health & Fitness
    Icons.local_hospital,
    Icons.medical_services,
    Icons.medication,
    Icons.vaccines,
    Icons.fitness_center,
    Icons.sports_gymnastics,
    Icons.self_improvement,
    Icons.spa,
    Icons.favorite,
    Icons.monitor_heart,
    
    // Education
    Icons.school,
    Icons.menu_book,
    Icons.library_books,
    Icons.auto_stories,
    Icons.class_,
    Icons.science,
    Icons.calculate,
    
    // Entertainment
    Icons.celebration,
    Icons.movie,
    Icons.theater_comedy,
    Icons.music_note,
    Icons.headphones,
    Icons.sports_esports,
    Icons.videogame_asset,
    Icons.casino,
    Icons.attractions,
    
    // Clothing & Fashion
    Icons.checkroom,
    Icons.dry_cleaning,
    Icons.watch,
    Icons.diamond,
    
    // Gifts & Special
    Icons.card_giftcard,
    Icons.redeem,
    Icons.volunteer_activism,
    
    // Work & Business
    Icons.work,
    Icons.business,
    Icons.business_center,
    Icons.badge,
    Icons.engineering,
    Icons.construction,
    
    // Sports & Recreation
    Icons.sports_soccer,
    Icons.sports_basketball,
    Icons.sports_tennis,
    Icons.sports_golf,
    Icons.pool,
    Icons.hiking,
    Icons.downhill_skiing,
    Icons.surfing,
    
    // Pets & Animals
    Icons.pets,
    
    // Travel & Tourism
    Icons.luggage,
    Icons.beach_access,
    Icons.hotel,
    Icons.local_activity,
    Icons.tour,
    Icons.landscape,
    
    // Technology
    Icons.computer,
    Icons.laptop,
    Icons.tablet,
    Icons.devices,
    Icons.headset,
    Icons.camera,
    Icons.photo_camera,
    
    // Personal Care
    Icons.face,
    Icons.face_retouching_natural,
    Icons.content_cut,
    
    // Miscellaneous
    Icons.category,
    Icons.label,
    Icons.bookmark,
    Icons.star,
    Icons.emoji_events,
    Icons.trending_up,
    Icons.trending_down,
    Icons.arrow_upward,
    Icons.arrow_downward,
    Icons.add_circle,
    Icons.remove_circle,
  ];

  static final Map<String, List<IconData>> categorizedIcons = {
    'Finans': [
      Icons.account_balance,
      Icons.account_balance_wallet,
      Icons.attach_money,
      Icons.money,
      Icons.currency_exchange,
      Icons.savings,
      Icons.credit_card,
      Icons.payment,
    ],
    'Alışveriş': [
      Icons.shopping_cart,
      Icons.shopping_bag,
      Icons.store,
      Icons.local_mall,
      Icons.local_grocery_store,
    ],
    'Yemek': [
      Icons.restaurant,
      Icons.local_dining,
      Icons.fastfood,
      Icons.local_pizza,
      Icons.local_cafe,
      Icons.coffee,
    ],
    'Ulaşım': [
      Icons.directions_car,
      Icons.directions_bus,
      Icons.flight,
      Icons.local_taxi,
      Icons.train,
      Icons.two_wheeler,
    ],
    'Ev': [
      Icons.home,
      Icons.house,
      Icons.apartment,
      Icons.weekend,
      Icons.chair,
      Icons.bed,
    ],
    'Sağlık': [
      Icons.local_hospital,
      Icons.medical_services,
      Icons.fitness_center,
      Icons.spa,
      Icons.favorite,
    ],
    'Eğitim': [
      Icons.school,
      Icons.menu_book,
      Icons.library_books,
      Icons.class_,
      Icons.science,
    ],
    'Eğlence': [
      Icons.celebration,
      Icons.movie,
      Icons.music_note,
      Icons.sports_esports,
      Icons.videogame_asset,
    ],
    'Diğer': [
      Icons.category,
      Icons.label,
      Icons.star,
      Icons.emoji_events,
      Icons.trending_up,
    ],
  };
}
