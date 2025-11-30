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
import 'services/credit_card_box_service.dart';

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
    print('Recurring scheduler initialization error: $e');
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
  final UserService _userService = UserService();
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
    final isFirst = await _userService.isFirstLaunch();
    setState(() {
      _isFirstLaunch = isFirst;
    });
  }

  void _setupAppLock() {
    _lockService.startMonitoring();
    _lockService.onLock = () {
      // Navigate to lock screen when app is locked
      // This will be handled by the navigator
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      _lockService.updateActivity();
    } else if (state == AppLifecycleState.paused) {
      // App is going to background
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
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      home: _isFirstLaunch ? const WelcomeScreen() : const LoginScreen(),
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
