import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth/auth_service.dart' as security_auth;
import 'services/theme_service.dart';
import 'services/auto_backup_service.dart';
import 'routes/auth_guard.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/credit_card_box_service.dart';
import 'models/credit_card.dart';
import 'models/credit_card_transaction.dart';
import 'models/credit_card_statement.dart';
import 'models/credit_card_payment.dart';
import 'models/reward_points.dart';
import 'models/reward_transaction.dart';
import 'models/limit_alert.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await initializeDateFormatting('tr_TR', null);
  await Hive.initFlutter();

  try {
    Hive.registerAdapter(CreditCardAdapter());
    Hive.registerAdapter(CreditCardTransactionAdapter());
    Hive.registerAdapter(CreditCardStatementAdapter());
    Hive.registerAdapter(CreditCardPaymentAdapter());
    Hive.registerAdapter(RewardPointsAdapter());
    Hive.registerAdapter(RewardTransactionAdapter());
    Hive.registerAdapter(LimitAlertAdapter());
    await CreditCardBoxService.init();
    debugPrint('Hive boxes initialized for credit cards');
  } catch (e) {
    debugPrint('Hive init error: $e');
  }

  try {
    await security_auth.AuthService().initialize();
    debugPrint('Auth service initialized');
  } catch (e) {
    debugPrint('Auth service init error: $e');
  }

  await ThemeService().init();

  // Otomatik yedekleme servisini başlat
  try {
    await AutoBackupService().initialize();
    debugPrint('Auto backup service initialized');
  } catch (e) {
    debugPrint('Auto backup service init error: $e');
  }

  runApp(const MoneyApp());
}

class MoneyApp extends StatefulWidget {
  const MoneyApp({super.key});

  @override
  State<MoneyApp> createState() => _MoneyAppState();
}

class _MoneyAppState extends State<MoneyApp> with WidgetsBindingObserver {
  final AuthGuardMiddleware _authGuardMiddleware = AuthGuardMiddleware();
  final security_auth.AuthService _securityAuthService = security_auth.AuthService();
  final ThemeService _themeService = ThemeService();
  final AutoBackupService _autoBackupService = AutoBackupService();

  ThemeMode _themeMode = ThemeMode.system;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTheme();
    _checkAuthenticationStatus();
    _themeService.addListener(_onThemeChanged);
    _securityAuthService.authStateStream.listen((authState) {
      if (mounted) {
        setState(() {
          _isAuthenticated = authState.isAuthenticated;
        });
      }
    });
  }

  Future<void> _loadTheme() async {
    final themeMode = await _themeService.getThemeMode();
    if (mounted) {
      setState(() {
        _themeMode = themeMode;
      });
    }
  }

  void _onThemeChanged() {
    debugPrint('Theme changed notification received');
    _loadTheme();
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      final isFirebaseAuth = FirebaseAuth.instance.currentUser != null;
      final isLocalAuth = await _securityAuthService.isAuthenticated();
      
      if (mounted) {
        setState(() {
          _isAuthenticated = isFirebaseAuth || isLocalAuth;
        });
      }
    } catch (e) {
      debugPrint('Error checking authentication status: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('App lifecycle state changed: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        _securityAuthService.onAppForeground();
        // Uygulama ön plana geldiğinde otomatik yedekleme kontrolü yap
        _autoBackupService.checkAndPerformBackupIfNeeded();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _securityAuthService.onAppBackground();
        break;
      case AppLifecycleState.detached:
        // Uygulama tamamen kapatılıyor - oturumu sonlandır
        _securityAuthService.logout();
        _autoBackupService.dispose();
        break;
      case AppLifecycleState.hidden:
        // Uygulama gizlendi - arka plan işlemi başlat
        _securityAuthService.onAppBackground();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parion',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeService.lightTheme,
      darkTheme: ThemeService.darkTheme,
      locale: const Locale('tr', 'TR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR')],
      navigatorObservers: [_authGuardMiddleware],
      home: _getInitialScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }

  Widget _getInitialScreen() {
    if (_isAuthenticated) {
      return const HomeScreen();
    }
    return const WelcomeScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeService.removeListener(_onThemeChanged);
    _securityAuthService.dispose();
    _autoBackupService.dispose();
    super.dispose();
  }
}
