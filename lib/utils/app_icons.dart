import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Uygulama genelinde kullanılan renkli ikonlar
class AppIcons {
  // ==================== FİNANSAL İKONLAR ====================

  /// Para ve finans ikonları
  static const IconData money = FontAwesomeIcons.moneyBill;
  static const IconData wallet = FontAwesomeIcons.wallet;
  static const IconData creditCard = FontAwesomeIcons.creditCard;
  static const IconData bank = FontAwesomeIcons.buildingColumns;
  static const IconData coins = FontAwesomeIcons.coins;
  static const IconData piggyBank = FontAwesomeIcons.piggyBank;
  static const IconData handHoldingDollar = FontAwesomeIcons.handHoldingDollar;
  static const IconData receipt = FontAwesomeIcons.receipt;
  static const IconData invoice = FontAwesomeIcons.fileInvoiceDollar;

  /// Gelir/Gider ikonları
  static const IconData income = FontAwesomeIcons.arrowTrendUp;
  static const IconData expense = FontAwesomeIcons.arrowTrendDown;
  static const IconData transfer = FontAwesomeIcons.rightLeft;
  static const IconData exchange = FontAwesomeIcons.arrowsRotate;

  // ==================== KATEGORİ İKONLARI ====================

  /// Yemek ve içecek
  static const IconData food = FontAwesomeIcons.utensils;
  static const IconData coffee = FontAwesomeIcons.mugHot;
  static const IconData pizza = FontAwesomeIcons.pizzaSlice;
  static const IconData burger = FontAwesomeIcons.burger;

  /// Ulaşım
  static const IconData car = FontAwesomeIcons.car;
  static const IconData bus = FontAwesomeIcons.bus;
  static const IconData plane = FontAwesomeIcons.plane;
  static const IconData train = FontAwesomeIcons.train;
  static const IconData bicycle = FontAwesomeIcons.bicycle;
  static const IconData motorcycle = FontAwesomeIcons.motorcycle;
  static const IconData taxi = FontAwesomeIcons.taxi;
  static const IconData gasStation = FontAwesomeIcons.gasPump;

  /// Alışveriş
  static const IconData shopping = FontAwesomeIcons.bagShopping;
  static const IconData shoppingCart = FontAwesomeIcons.cartShopping;
  static const IconData store = FontAwesomeIcons.store;
  static const IconData gift = FontAwesomeIcons.gift;
  static const IconData tshirt = FontAwesomeIcons.shirt;

  /// Sağlık
  static const IconData health = FontAwesomeIcons.heartPulse;
  static const IconData hospital = FontAwesomeIcons.hospital;
  static const IconData pills = FontAwesomeIcons.pills;
  static const IconData stethoscope = FontAwesomeIcons.stethoscope;

  /// Eğlence
  static const IconData entertainment = FontAwesomeIcons.masksTheater;
  static const IconData movie = FontAwesomeIcons.film;
  static const IconData music = FontAwesomeIcons.music;
  static const IconData gamepad = FontAwesomeIcons.gamepad;
  static const IconData camera = FontAwesomeIcons.camera;

  /// Ev ve yaşam
  static const IconData home = FontAwesomeIcons.house;
  static const IconData bed = FontAwesomeIcons.bed;
  static const IconData couch = FontAwesomeIcons.couch;
  static const IconData hammer = FontAwesomeIcons.hammer;
  static const IconData paintBrush = FontAwesomeIcons.paintbrush;

  // ==================== FATURA İKONLARI ====================

  /// Elektrik
  static const IconData electricity = FontAwesomeIcons.bolt;
  static const IconData lightbulb = FontAwesomeIcons.lightbulb;

  /// Su
  static const IconData water = FontAwesomeIcons.droplet;
  static const IconData faucet = FontAwesomeIcons.faucetDrip;

  /// Doğalgaz
  static const IconData gas = FontAwesomeIcons.fire;
  static const IconData fireFlame = FontAwesomeIcons.fireFlameSimple;

  /// İnternet ve telefon
  static const IconData internet = FontAwesomeIcons.wifi;
  static const IconData phone = FontAwesomeIcons.phone;
  static const IconData mobile = FontAwesomeIcons.mobileScreen;
  static const IconData router = FontAwesomeIcons.wifi;

  /// Kira ve sigorta
  static const IconData rent = FontAwesomeIcons.houseChimney;
  static const IconData insurance = FontAwesomeIcons.shield;
  static const IconData umbrella = FontAwesomeIcons.umbrella;

  /// Abonelik
  static const IconData subscription = FontAwesomeIcons.repeat;
  static const IconData netflix = FontAwesomeIcons.tv;
  static const IconData spotify = FontAwesomeIcons.spotify;

  // ==================== UYGULAMA İKONLARI ====================

  /// Navigasyon
  static const IconData dashboard = FontAwesomeIcons.chartLine;
  static const IconData statistics = FontAwesomeIcons.chartPie;
  static const IconData calendar = FontAwesomeIcons.calendar;
  static const IconData settings = FontAwesomeIcons.gear;
  static const IconData profile = FontAwesomeIcons.user;

  /// Aksiyonlar
  static const IconData add = FontAwesomeIcons.plus;
  static const IconData edit = FontAwesomeIcons.penToSquare;
  static const IconData delete = FontAwesomeIcons.trash;
  static const IconData save = FontAwesomeIcons.floppyDisk;
  static const IconData search = FontAwesomeIcons.magnifyingGlass;
  static const IconData filter = FontAwesomeIcons.filter;
  static const IconData sort = FontAwesomeIcons.sort;

  /// Güvenlik
  static const IconData lock = FontAwesomeIcons.lock;
  static const IconData unlock = FontAwesomeIcons.lockOpen;
  static const IconData fingerprint = FontAwesomeIcons.fingerprint;
  static const IconData eye = FontAwesomeIcons.eye;
  static const IconData eyeSlash = FontAwesomeIcons.eyeSlash;
  static const IconData shield = FontAwesomeIcons.shieldHalved;

  /// Bildirimler
  static const IconData notification = FontAwesomeIcons.bell;
  static const IconData notificationOff = FontAwesomeIcons.bellSlash;
  static const IconData warning = FontAwesomeIcons.triangleExclamation;
  static const IconData info = FontAwesomeIcons.circleInfo;
  static const IconData success = FontAwesomeIcons.circleCheck;
  static const IconData error = FontAwesomeIcons.circleXmark;

  /// Yedekleme ve senkronizasyon
  static const IconData backup = FontAwesomeIcons.cloudArrowUp;
  static const IconData restore = FontAwesomeIcons.cloudArrowDown;
  static const IconData sync = FontAwesomeIcons.arrowsRotate;
  static const IconData cloud = FontAwesomeIcons.cloud;
  static const IconData download = FontAwesomeIcons.download;
  static const IconData upload = FontAwesomeIcons.upload;

  /// Sosyal medya
  static const IconData google = FontAwesomeIcons.google;
  static const IconData apple = FontAwesomeIcons.apple;
  static const IconData twitter = FontAwesomeIcons.twitter;

  // ==================== PHOSPHOR İKONLARI ====================

  /// Modern ve minimal ikonlar
  static final IconData walletPhosphor = PhosphorIcons.wallet();
  static final IconData chartPhosphor = PhosphorIcons.chartPie();
  static final IconData trendUpPhosphor = PhosphorIcons.trendUp();
  static final IconData trendDownPhosphor = PhosphorIcons.trendDown();
  static final IconData coinPhosphor = PhosphorIcons.coin();
  static final IconData creditCardPhosphor = PhosphorIcons.creditCard();

  // ==================== LINE İKONLARI ====================

  /// İnce çizgili ikonlar
  static const IconData walletLine = LineIcons.wallet;
  static const IconData chartLine = LineIcons.lineChart;
  static const IconData moneyLine = LineIcons.moneyBill;
  static const IconData creditCardLine = LineIcons.creditCard;
  static const IconData bankLine = LineIcons.university;

  // ==================== MODERN İKONLAR ====================

  /// Minimal ve modern ikonlar (resimdeki gibi)
  static const IconData shoppingModern = LucideIcons.shoppingCart;
  static const IconData foodModern = LucideIcons.utensils;
  static const IconData phoneModern = LucideIcons.smartphone;
  static const IconData entertainmentModern = LucideIcons.music;
  static const IconData educationModern = LucideIcons.bookOpen;
  static const IconData beautyModern = LucideIcons.sparkles;
  static const IconData sportsModern = LucideIcons.trophy;
  static const IconData socialModern = LucideIcons.users;
  static const IconData transportModern = LucideIcons.bus;
  static const IconData clothingModern = LucideIcons.shirt;
  static const IconData carModern = LucideIcons.car;
  static const IconData wineModern = LucideIcons.wine;
  static const IconData insuranceModern = LucideIcons.shield;
  static const IconData electronicsModern = LucideIcons.laptop;
  static const IconData travelModern = LucideIcons.plane;
  static const IconData healthModern = LucideIcons.heart;
  static const IconData petModern = LucideIcons.heart;
  static const IconData repairModern = LucideIcons.wrench;
  static const IconData housingModern = LucideIcons.building;
  static const IconData homeModern = LucideIcons.home;
  static const IconData giftModern = LucideIcons.gift;
  static const IconData donationModern = LucideIcons.heart;
  static const IconData lotteryModern = LucideIcons.coins;
  static const IconData shoppingBagModern = LucideIcons.shoppingBag;
  static const IconData babyModern = LucideIcons.baby;
  static const IconData vegetableModern = LucideIcons.carrot;
  static const IconData fruitModern = LucideIcons.apple;
  static const IconData otherModern = LucideIcons.moreHorizontal;

  // ==================== LUCIDE İKONLARI ====================

  /// Modern ve temiz ikonlar
  static const IconData walletLucide = LucideIcons.wallet;
  static const IconData trendingUpLucide = LucideIcons.trendingUp;
  static const IconData trendingDownLucide = LucideIcons.trendingDown;
  static const IconData pieChartLucide = LucideIcons.pieChart;
  static const IconData barChartLucide = LucideIcons.barChart;

  // ==================== RENKLI İKON YARDIMCILARı ====================

  /// Kategori renkli ikonları
  static Widget getCategoryIcon(
    String category, {
    double size = 24,
    Color? color,
  }) {
    IconData iconData;
    Color defaultColor;

    switch (category.toLowerCase()) {
      case 'alışveriş':
      case 'alisveris':
      case 'shopping':
        iconData = shoppingModern;
        defaultColor = Colors.purple;
        break;
      case 'gıda':
      case 'gida':
      case 'yemek':
      case 'food':
        iconData = foodModern;
        defaultColor = Colors.orange;
        break;
      case 'telefon':
      case 'phone':
        iconData = phoneModern;
        defaultColor = Colors.blue;
        break;
      case 'eğlence':
      case 'eglence':
      case 'entertainment':
        iconData = entertainmentModern;
        defaultColor = Colors.pink;
        break;
      case 'eğitim':
      case 'egitim':
      case 'education':
        iconData = educationModern;
        defaultColor = Colors.indigo;
        break;
      case 'güzellik':
      case 'guzellik':
      case 'beauty':
        iconData = beautyModern;
        defaultColor = Colors.pink.shade300;
        break;
      case 'spor':
      case 'sports':
        iconData = sportsModern;
        defaultColor = Colors.cyan;
        break;
      case 'sosyal':
      case 'social':
        iconData = socialModern;
        defaultColor = Colors.teal;
        break;
      case 'toplu taşıma':
      case 'toplu tasima':
      case 'transport':
        iconData = transportModern;
        defaultColor = Colors.blue.shade600;
        break;
      case 'giyim':
      case 'clothing':
        iconData = clothingModern;
        defaultColor = Colors.purple.shade300;
        break;
      case 'araba':
      case 'car':
        iconData = carModern;
        defaultColor = Colors.red;
        break;
      case 'şarap':
      case 'sarap':
      case 'wine':
        iconData = wineModern;
        defaultColor = Colors.red.shade700;
        break;
      case 'sigara':
      case 'insurance':
        iconData = insuranceModern;
        defaultColor = Colors.grey;
        break;
      case 'elektronik':
      case 'electronics':
        iconData = electronicsModern;
        defaultColor = Colors.blue.shade800;
        break;
      case 'yolculuk':
      case 'travel':
        iconData = travelModern;
        defaultColor = Colors.orange.shade600;
        break;
      case 'sağlık':
      case 'saglik':
      case 'health':
        iconData = healthModern;
        defaultColor = Colors.red;
        break;
      case 'evcil hayvan':
      case 'pet':
        iconData = petModern;
        defaultColor = Colors.brown;
        break;
      case 'onarım':
      case 'onarim':
      case 'repair':
        iconData = repairModern;
        defaultColor = Colors.grey.shade600;
        break;
      case 'konut':
      case 'housing':
        iconData = housingModern;
        defaultColor = Colors.brown.shade400;
        break;
      case 'ev':
      case 'home':
        iconData = homeModern;
        defaultColor = Colors.green;
        break;
      case 'hediye':
      case 'gift':
        iconData = giftModern;
        defaultColor = Colors.red.shade400;
        break;
      case 'bağış yapmak':
      case 'bagis yapmak':
      case 'donation':
        iconData = donationModern;
        defaultColor = Colors.pink.shade400;
        break;
      case 'piyango':
      case 'lottery':
        iconData = lotteryModern;
        defaultColor = Colors.yellow.shade700;
        break;
      case 'alıştırmalıklar':
      case 'alistirmalikar':
      case 'shopping_bag':
        iconData = shoppingBagModern;
        defaultColor = Colors.purple.shade400;
        break;
      case 'bebek':
      case 'baby':
        iconData = babyModern;
        defaultColor = Colors.pink.shade200;
        break;
      case 'sebze':
      case 'vegetable':
        iconData = vegetableModern;
        defaultColor = Colors.green.shade600;
        break;
      case 'meyve':
      case 'fruit':
        iconData = fruitModern;
        defaultColor = Colors.red.shade400;
        break;
      case 'ayar':
      case 'other':
        iconData = otherModern;
        defaultColor = Colors.grey.shade500;
        break;
      case 'ulaşım':
      case 'ulasim':
        iconData = car;
        defaultColor = Colors.blue;
        break;
      case 'elektrik':
      case 'electricity':
        iconData = electricity;
        defaultColor = Colors.yellow.shade700;
        break;
      case 'su':
      case 'water':
        iconData = water;
        defaultColor = Colors.blue.shade600;
        break;
      case 'doğalgaz':
      case 'dogalgaz':
      case 'gas':
        iconData = gas;
        defaultColor = Colors.orange.shade700;
        break;
      case 'internet':
        iconData = internet;
        defaultColor = Colors.indigo;
        break;
      case 'kira':
      case 'rent':
        iconData = rent;
        defaultColor = Colors.brown;
        break;
      case 'sigorta':
        iconData = insurance;
        defaultColor = Colors.cyan;
        break;
      case 'abonelik':
      case 'subscription':
        iconData = subscription;
        defaultColor = Colors.deepPurple;
        break;
      default:
        iconData = money;
        defaultColor = Colors.grey;
    }

    return Icon(iconData, size: size, color: color ?? defaultColor);
  }

  /// Kategori rengini getirir
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'yemek':
      case 'food':
        return Colors.orange;
      case 'ulaşım':
      case 'transport':
        return Colors.blue;
      case 'alışveriş':
      case 'shopping':
        return Colors.purple;
      case 'sağlık':
      case 'health':
        return Colors.red;
      case 'eğlence':
      case 'entertainment':
        return Colors.pink;
      case 'ev':
      case 'home':
        return Colors.green;
      case 'elektrik':
      case 'electricity':
        return Colors.yellow.shade700;
      case 'su':
      case 'water':
        return Colors.blue.shade600;
      case 'doğalgaz':
      case 'gas':
        return Colors.orange.shade700;
      case 'internet':
        return Colors.indigo;
      case 'telefon':
      case 'phone':
        return Colors.teal;
      case 'kira':
      case 'rent':
        return Colors.brown;
      case 'sigorta':
      case 'insurance':
        return Colors.cyan;
      case 'abonelik':
      case 'subscription':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  /// Finansal durum renkli ikonları
  static Widget getFinancialStatusIcon(String type, {double size = 24}) {
    switch (type.toLowerCase()) {
      case 'income':
      case 'gelir':
        return FaIcon(income, size: size, color: Colors.green);
      case 'expense':
      case 'gider':
        return FaIcon(expense, size: size, color: Colors.red);
      case 'transfer':
        return FaIcon(transfer, size: size, color: Colors.blue);
      default:
        return FaIcon(money, size: size, color: Colors.grey);
    }
  }

  /// Yedekleme durumu renkli ikonları
  static Widget getBackupStatusIcon(String status, {double size = 24}) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'başarılı':
        return FaIcon(success, size: size, color: Colors.green);
      case 'error':
      case 'hata':
        return FaIcon(error, size: size, color: Colors.red);
      case 'warning':
      case 'uyarı':
        return FaIcon(warning, size: size, color: Colors.orange);
      case 'info':
      case 'bilgi':
        return FaIcon(info, size: size, color: Colors.blue);
      case 'uploading':
      case 'yükleniyor':
        return FaIcon(upload, size: size, color: Colors.blue);
      case 'downloading':
      case 'indiriliyor':
        return FaIcon(download, size: size, color: Colors.green);
      default:
        return FaIcon(cloud, size: size, color: Colors.grey);
    }
  }

  /// Güvenlik durumu renkli ikonları
  static Widget getSecurityIcon(String type, {double size = 24}) {
    switch (type.toLowerCase()) {
      case 'locked':
      case 'kilitli':
        return FaIcon(lock, size: size, color: Colors.red);
      case 'unlocked':
      case 'açık':
        return FaIcon(unlock, size: size, color: Colors.green);
      case 'biometric':
      case 'biyometrik':
        return FaIcon(fingerprint, size: size, color: Colors.blue);
      case 'secure':
      case 'güvenli':
        return FaIcon(shield, size: size, color: Colors.green);
      default:
        return FaIcon(lock, size: size, color: Colors.grey);
    }
  }
}

/// Renkli ikon tema sınıfı
class AppIconTheme {
  static const Color primary = Color(0xFF2C6BED);
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  static const Color info = Colors.blue;

  /// Kategori renkleri
  static const Map<String, Color> categoryColors = {
    'yemek': Colors.orange,
    'ulaşım': Colors.blue,
    'alışveriş': Colors.purple,
    'sağlık': Colors.red,
    'eğlence': Colors.pink,
    'ev': Colors.green,
    'elektrik': Colors.yellow,
    'su': Colors.blue,
    'doğalgaz': Colors.orange,
    'internet': Colors.indigo,
    'telefon': Colors.teal,
    'kira': Colors.brown,
    'sigorta': Colors.cyan,
    'abonelik': Colors.deepPurple,
  };

  /// Gradient renkler
  static const List<Color> primaryGradient = [
    Color(0xFF2C6BED),
    Color(0xFF1E40AF),
  ];

  static const List<Color> successGradient = [
    Color(0xFF10B981),
    Color(0xFF059669),
  ];

  static const List<Color> errorGradient = [
    Color(0xFFEF4444),
    Color(0xFFDC2626),
  ];
}
