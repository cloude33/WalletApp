import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/theme_service.dart';
import 'services/auto_backup_service.dart';
import 'services/unified_auth_service.dart';
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
import 'services/kmh_box_service.dart';
import 'models/kmh_transaction.dart';
import 'models/kmh_transaction_type.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase'i başlat
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
    Hive.registerAdapter(KmhTransactionAdapter());
    Hive.registerAdapter(KmhTransactionTypeAdapter());
    await CreditCardBoxService.init();
    await KmhBoxService.init();
    debugPrint('Hive boxes initialized for credit cards and KMH');
  } catch (e) {
    debugPrint('Hive init error: $e');
  }

  await ThemeService().init();

  // Unified Auth servisini başlat (Auth ve Firebase senkronizasyonu için)
  try {
    await UnifiedAuthService().initialize();
    debugPrint('Unified auth service initialized');
  } catch (e) {
    debugPrint('Unified auth service init error: $e');
  }

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
  final UnifiedAuthService _unifiedAuthService = UnifiedAuthService();
  final ThemeService _themeService = ThemeService();
  final AutoBackupService _autoBackupService = AutoBackupService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  ThemeMode _themeMode = ThemeMode.system;
  UnifiedAuthState _authState = UnifiedAuthState.unauthenticated();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTheme();
    _unifiedAuthService.authStateStream.listen((authState) {
      if (mounted) {
        final wasClickable = _authState.canUseApp;
        setState(() {
          _authState = authState;
        });
        
        // Eğer uygulama kilitlenmişse (local auth gerekli hale gelmişse) giriş ekranına veya kilit ekranına yönlendir
        if (!authState.canUseApp && wasClickable) {
          debugPrint('App locked or logged out - redirecting');
          _navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
        } else if (authState.status == UnifiedAuthStatus.firebaseAuthenticatedLocalRequired) {
          // Eğer Firebase ile giriş yapılmış ama yerel kilit gerekliyse kilit ekranını göster
          // Not: /login rotası hem normal girişi hem biyometrik girişi handle ediyor
          debugPrint('Local authentication required - redirecting to login/lock');
          _navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
        }
      }
    });
    _themeService.addListener(_onThemeChanged);
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

  // _checkAuthenticationStatus kaldırıldı, UnifiedAuthService stream'i kullanılıyor

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('App lifecycle state changed: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        _unifiedAuthService.onAppForeground();
        // Uygulama ön plana geldiğinde otomatik yedekleme kontrolü yap
        _autoBackupService.checkAndPerformBackupIfNeeded();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _unifiedAuthService.onAppBackground();
        break;
      case AppLifecycleState.detached:
        // Uygulama tamamen kapatılıyor - oturumu sonlandır
        _unifiedAuthService.signOut();
        _autoBackupService.dispose();
        break;
      case AppLifecycleState.hidden:
        // Uygulama gizlendi - arka plan işlemi başlat
        _unifiedAuthService.onAppBackground();
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
      navigatorKey: _navigatorKey,
      home: _getInitialScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }

  Widget _getInitialScreen() {
    if (_authState.canUseApp) {
      return const HomeScreen();
    }
    return const WelcomeScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeService.removeListener(_onThemeChanged);
    _unifiedAuthService.dispose();
    _autoBackupService.dispose();
    super.dispose();
  }
}
