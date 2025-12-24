import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';

import 'services/data_service.dart';
import 'services/theme_service.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/app_lock_service.dart';
import 'services/notification_scheduler_service.dart';
import 'services/auth/auth_service.dart' as security_auth;
import 'services/auth/pin_service.dart';
import 'routes/auth_guard.dart';
import 'models/recurring_transaction.dart';
import 'models/recurrence_frequency.dart';
import 'models/recurring_template.dart';
import 'repositories/recurring_transaction_repository.dart';
import 'services/recurring_template_service.dart';
import 'services/recurring_transaction_service.dart';
import 'services/recurring_scheduler_service.dart';
import 'services/notification_service.dart';
import 'models/credit_card.dart';
import 'models/credit_card_transaction.dart';
import 'models/credit_card_statement.dart';
import 'models/credit_card_payment.dart';
import 'models/reward_points.dart';
import 'models/reward_transaction.dart';
import 'models/limit_alert.dart';
import 'models/kmh_transaction.dart';
import 'models/kmh_transaction_type.dart';
import 'services/credit_card_box_service.dart';
import 'services/kmh_box_service.dart';
import 'services/bill_migration_service.dart';
import 'services/credit_card_migration_service.dart';
import 'services/kmh_interest_scheduler_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  await Hive.initFlutter();
  Hive.registerAdapter(RecurrenceFrequencyAdapter());
  Hive.registerAdapter(RecurringTransactionAdapter());
  Hive.registerAdapter(RecurringTemplateAdapter());
  Hive.registerAdapter(CreditCardAdapter());
  Hive.registerAdapter(CreditCardTransactionAdapter());
  Hive.registerAdapter(CreditCardStatementAdapter());
  Hive.registerAdapter(CreditCardPaymentAdapter());
  Hive.registerAdapter(RewardPointsAdapter());
  Hive.registerAdapter(RewardTransactionAdapter());
  Hive.registerAdapter(LimitAlertAdapter());
  Hive.registerAdapter(KmhTransactionTypeAdapter());
  Hive.registerAdapter(KmhTransactionAdapter());

  await DataService().init();
  await CreditCardBoxService.init();
  await KmhBoxService.init();

  await ThemeService().init();
  await AuthService().init();
  await UserService().init();
  await AppLockService().init();

  // Initialize security authentication services
  try {
    await security_auth.AuthService().initialize();
    
    debugPrint('Security authentication services initialized');
  } catch (e) {
    debugPrint('Security authentication initialization error: $e');
  }
  final recurringRepo = RecurringTransactionRepository();
  await recurringRepo.init();
  final templateService = RecurringTemplateService();
  await templateService.init();
  await NotificationSchedulerService().initialize();
  await NotificationSchedulerService().requestPermissions();
  try {
    final dataService = DataService();
    final notificationService = NotificationService();
    final recurringService = RecurringTransactionService(
      recurringRepo,
      dataService,
      notificationService,
    );
    final schedulerService = RecurringSchedulerService(recurringService);
    await schedulerService.initialize();
  } catch (e) {
    debugPrint('Recurring scheduler initialization error: $e');
  }
  try {
    final migrationService = BillMigrationService();
    await migrationService.migrateBills();
  } catch (e) {
    debugPrint('Bill migration error: $e');
  }
  try {
    final creditCardMigrationService = CreditCardMigrationService();
    final result = await creditCardMigrationService.migrateCreditCards();
    debugPrint('Credit card migration: ${result.message}');
  } catch (e) {
    debugPrint('Credit card migration error: $e');
  }
  try {
    final kmhScheduler = KmhInterestSchedulerService();
    await kmhScheduler.initialize();
  } catch (e) {
    debugPrint('KMH interest scheduler error: $e');
  }

  runApp(const MoneyApp());
}

class MoneyApp extends StatefulWidget {
  const MoneyApp({super.key});

  @override
  State<MoneyApp> createState() => _MoneyAppState();
}

class _MoneyAppState extends State<MoneyApp> with WidgetsBindingObserver {
  final ThemeService _themeService = ThemeService();
  final AppLockService _lockService = AppLockService();
  final security_auth.AuthService _securityAuthService =
      security_auth.AuthService();

  final AuthGuardMiddleware _authGuardMiddleware = AuthGuardMiddleware();

  ThemeMode _themeMode = ThemeMode.system;
  bool _isFirstLaunch = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTheme();
    _checkFirstLaunch();
    _checkAuthenticationStatus();
    _setupAppLock();
    _setupSecurityAuth();
    _themeService.addListener(_onThemeChanged);
  }

  Future<void> _loadTheme() async {
    final theme = await _themeService.getThemeMode();
    setState(() {
      _themeMode = theme;
    });
  }

  Future<void> _checkFirstLaunch() async {
    final dataService = DataService();
    final users = await dataService.getAllUsers();

    setState(() {
      _isFirstLaunch = users.isEmpty;
    });
  }



  Future<void> _checkAuthenticationStatus() async {
    try {
      final isAuth = await _securityAuthService.isAuthenticated();
      setState(() {
        _isAuthenticated = isAuth;
      });
    } catch (e) {
      debugPrint('Error checking authentication status: $e');
    }
  }

  void _setupAppLock() {
    _lockService.startMonitoring();
    _lockService.onLock = () {
      // Temporary: Disable lock screen
      // _navigateToLockScreen();
    };
  }

  void _setupSecurityAuth() {
    // Listen to authentication state changes
    _securityAuthService.authStateStream.listen((authState) {
      setState(() {
        _isAuthenticated = authState.isAuthenticated;
      });

      if (!authState.isAuthenticated) {
        // User logged out - navigate to appropriate screen
        // Temporary: Disable auth screen navigation
        // _navigateToAuthScreen();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // Handle app foreground
      _securityAuthService.onAppForeground();

      // Temporary: Disable lock screen logic
      /*
      if (_lockService.isLocked) {
        _navigateToLockScreen();
      } else {
        _lockService.updateActivity();
      }

      // Check authentication status when app resumes
      _checkAuthenticationStatus().then((_) {
        if (!_isAuthenticated && _hasPIN) {
          _navigateToAuthScreen();
        }
      });
      */
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Handle app background
      _securityAuthService.onAppBackground();
    }
  }

  void updateTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    _themeService.setThemeMode(mode);
  }

  void _onThemeChanged() async {
    final theme = await _themeService.getThemeMode();
    setState(() {
      _themeMode = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Para Yönetimi',
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
      builder: (context, child) {
        return Listener(
          onPointerDown: (_) => _lockService.updateActivity(),
          onPointerMove: (_) => _lockService.updateActivity(),
          onPointerUp: (_) => _lockService.updateActivity(),
          child: child,
        );
      },
    );
  }

  /// Determines the initial screen based on app state
  ///
  /// Implements Requirement 6.3: Uygulama tekrar açıldığında kimlik doğrulama gerektirmeli
  Widget _getInitialScreen() {
    // First launch - show welcome screen
    if (_isFirstLaunch) {
      return const WelcomeScreen();
    }

    // Return login screen with password and biometric options
    return const LoginScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeService.removeListener(_onThemeChanged);
    _lockService.dispose();
    _securityAuthService.dispose();
    super.dispose();
  }
}
