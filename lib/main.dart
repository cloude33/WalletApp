import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/lock_screen.dart';
import 'services/data_service.dart';
import 'services/theme_service.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/app_lock_service.dart';
import 'services/notification_scheduler_service.dart';
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
import 'services/credit_card_box_service.dart';
import 'services/bill_migration_service.dart';
import 'services/credit_card_migration_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(RecurrenceFrequencyAdapter());
  Hive.registerAdapter(RecurringTransactionAdapter());
  Hive.registerAdapter(RecurringTemplateAdapter());

  // Register credit card adapters
  Hive.registerAdapter(CreditCardAdapter());
  Hive.registerAdapter(CreditCardTransactionAdapter());
  Hive.registerAdapter(CreditCardStatementAdapter());
  Hive.registerAdapter(CreditCardPaymentAdapter());
  Hive.registerAdapter(RewardPointsAdapter());
  Hive.registerAdapter(RewardTransactionAdapter());
  Hive.registerAdapter(LimitAlertAdapter());

  await DataService().init();

  // Initialize credit card boxes
  await CreditCardBoxService.init();
  await ThemeService().init();
  await AuthService().init();

  // Initialize user service
  await UserService().init();

  // Initialize app lock service
  await AppLockService().init();

  // Initialize recurring transaction repository
  final recurringRepo = RecurringTransactionRepository();
  await recurringRepo.init();

  // Initialize recurring template service
  final templateService = RecurringTemplateService();
  await templateService.init();

  // Initialize notification service
  await NotificationSchedulerService().initialize();
  await NotificationSchedulerService().requestPermissions();

  // Initialize recurring scheduler service
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
    // Error handling for recurring scheduler initialization
  }

  // Migrate old Bill data to new BillTemplate + BillPayment structure
  try {
    final migrationService = BillMigrationService();
    await migrationService.migrateBills();
  } catch (e) {
    debugPrint('Bill migration error: $e');
  }

  // Migrate credit card data to new enhanced fields
  try {
    final creditCardMigrationService = CreditCardMigrationService();
    final result = await creditCardMigrationService.migrateCreditCards();
    debugPrint('Credit card migration: ${result.message}');
  } catch (e) {
    debugPrint('Credit card migration error: $e');
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
  ThemeMode _themeMode = ThemeMode.system;
  bool _isFirstLaunch = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTheme();
    _checkFirstLaunch();
    _setupAppLock();
    _themeService.addListener(_onThemeChanged);
  }

  Future<void> _loadTheme() async {
    final theme = await _themeService.getThemeMode();
    setState(() {
      _themeMode = theme;
    });
  }

  Future<void> _checkFirstLaunch() async {
    // Check if any users exist in the system
    final dataService = DataService();
    final users = await dataService.getAllUsers();

    setState(() {
      // If users exist, go to login screen, otherwise go to welcome screen
      _isFirstLaunch = users.isEmpty;
    });
  }

  void _setupAppLock() {
    _lockService.startMonitoring();
    _lockService.onLock = () {
      // Navigate to lock screen when app is locked
      _navigateToLockScreen();
    };
  }

  void _navigateToLockScreen() {
    // Navigate to lock screen when app is locked
    // Add a small delay to ensure proper initialization
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      // Check if lock screen is already showing
      final currentRoute = ModalRoute.of(context);
      if (currentRoute?.settings.name == '/lock' ||
          currentRoute?.settings.arguments == 'LockScreen') {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LockScreen(),
          settings: const RouteSettings(name: '/lock'),
        ),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // Check if app should be locked when resuming
      if (_lockService.isLocked) {
        _navigateToLockScreen();
      } else {
        // Update activity when app resumes
        _lockService.updateActivity();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App is going to background or becoming inactive
      // Don't update activity, let the timer check for inactivity
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
      home: _isFirstLaunch ? const WelcomeScreen() : const LoginScreen(),
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeService.removeListener(_onThemeChanged);
    _lockService.dispose();
    super.dispose();
  }
}
