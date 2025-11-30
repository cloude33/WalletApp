import 'package:uuid/uuid.dart';

enum AuthMethod { email, google, facebook }

class User {
  final String id;
  final String name;
  final String? email;
  final String? passwordHash; // Şifre hash'li olarak saklanacak
  final String? avatar;
  final String currencyCode;
  final String currencySymbol;
  final AuthMethod authMethod;
  final DateTime? lastActive;
  final bool isLocked;
  final int loginAttempts;
  final DateTime? lockUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    this.email,
    this.passwordHash,
    this.avatar,
    this.currencyCode = 'TRY',
    this.currencySymbol = '₺',
    this.authMethod = AuthMethod.email,
    this.lastActive,
    this.isLocked = false,
    this.loginAttempts = 0,
    this.lockUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Kullanıcıyı kilitler
  User lock() {
    return copyWith(
      isLocked: true,
      lockUntil: DateTime.now().add(
        const Duration(minutes: 30),
      ), // 30 dakika kilitli kalsın
      updatedAt: DateTime.now(),
    );
  }

  // Kullanıcının kilidini açar
  User unlock() {
    return copyWith(
      isLocked: false,
      loginAttempts: 0,
      lockUntil: null,
      updatedAt: DateTime.now(),
    );
  }

  // Başarısız giriş denemesi ekler
  User addFailedLoginAttempt() {
    final newAttempts = loginAttempts + 1;
    return copyWith(
      loginAttempts: newAttempts,
      isLocked: newAttempts >= 5, // 5 başarısız denemede kilitlensin
      lockUntil: newAttempts >= 5
          ? DateTime.now().add(const Duration(minutes: 30))
          : null,
      updatedAt: DateTime.now(),
    );
  }

  // Kullanıcı aktif olduğunda çağrılır
  User updateLastActive() {
    return copyWith(lastActive: DateTime.now());
  }

  // Kopyalama metodu
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? passwordHash,
    String? avatar,
    String? currencyCode,
    String? currencySymbol,
    AuthMethod? authMethod,
    DateTime? lastActive,
    bool? isLocked,
    int? loginAttempts,
    DateTime? lockUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      avatar: avatar ?? this.avatar,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      authMethod: authMethod ?? this.authMethod,
      lastActive: lastActive ?? this.lastActive,
      isLocked: isLocked ?? this.isLocked,
      loginAttempts: loginAttempts ?? this.loginAttempts,
      lockUntil: lockUntil ?? this.lockUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'passwordHash': passwordHash,
    'avatar': avatar,
    'currencyCode': currencyCode,
    'currencySymbol': currencySymbol,
    'authMethod': authMethod.toString(),
    'lastActive': lastActive?.toIso8601String(),
    'isLocked': isLocked,
    'loginAttempts': loginAttempts,
    'lockUntil': lockUntil?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['id']?.toString() ?? const Uuid().v4(), // ID yoksa yeni oluştur
        name: json['name']?.toString() ?? 'Kullanıcı',
        email: json['email']?.toString(),
        passwordHash: json['passwordHash']?.toString(),
        avatar: json['avatar']?.toString(),
        currencyCode: json['currencyCode']?.toString() ?? 'TRY',
        currencySymbol: json['currencySymbol']?.toString() ?? '₺',
        authMethod: AuthMethod.values.firstWhere(
          (e) => e.toString() == json['authMethod'],
          orElse: () => AuthMethod.email,
        ),
        lastActive: json['lastActive'] != null
            ? DateTime.tryParse(json['lastActive'].toString())
            : null,
        isLocked: json['isLocked'] == true, // Güvenli boolean kontrolü
        loginAttempts: int.tryParse(json['loginAttempts']?.toString() ?? '0') ?? 0,
        lockUntil: json['lockUntil'] != null
            ? DateTime.tryParse(json['lockUntil'].toString())
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    } catch (e, stack) {
      print('User.fromJson HATASI: $e');
      print('Hatalı JSON Verisi: $json');
      print(stack);
      // Hata durumunda varsayılan güvenli bir kullanıcı döndür
      return User(
        id: const Uuid().v4(),
        name: 'Hatalı Veri',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }
}
