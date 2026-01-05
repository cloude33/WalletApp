import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:parion/models/credit_card.dart';
import 'package:parion/models/credit_card_statement.dart';
import 'package:parion/models/credit_card_transaction.dart';
import 'package:parion/models/kmh_transaction.dart';
import 'package:parion/models/kmh_transaction_type.dart';
import 'package:parion/models/recurring_transaction.dart';
import 'package:parion/models/recurrence_frequency.dart';
import 'package:parion/services/credit_card_box_service.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/services/google_drive_service.dart';
import 'package:parion/services/kmh_box_service.dart';
import 'package:parion/repositories/recurring_transaction_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io';

/// Setup Firebase for testing
Future<void> setupFirebaseForTesting() async {
  // Mock Firebase initialization for testing
  // In a real app, you would use Firebase.initializeApp() with test configuration
  // For now, we'll just skip Firebase initialization in tests
}

class TestSetup {
  static late String testPath;
  static bool _isInitialized = false;

  /// Initialize test environment once for all tests
  static Future<void> initializeTestEnvironment() async {
    if (_isInitialized) return;

    // Initialize Flutter test binding first
    TestWidgetsFlutterBinding.ensureInitialized();

    // Setup platform channel mocks
    _setupPlatformChannelMocks();

    // Enable test mode for Google Drive Service
    GoogleDriveService().setTestMode(true);

    // Initialize SharedPreferences for global access
    SharedPreferences.setMockInitialValues({});

    // Initialize locale data for date formatting
    await initializeDateFormatting('tr_TR', null);

    // Create unique test directory
    testPath = 'test_hive_${DateTime.now().millisecondsSinceEpoch}';
    await Directory(testPath).create(recursive: true);

    // Initialize Hive
    Hive.init(testPath);

    // Register adapters only once
    _registerAdapters();

    _isInitialized = true;
  }

  /// Setup platform channel mocks for plugins
  static void _setupPlatformChannelMocks() {
    // Mock flutter_secure_storage
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'read':
        // Return a constant key for encryption to ensure consistent Hive box access across tests
        if (methodCall.arguments['key'] == 'kmh_encryption_key' || 
            methodCall.arguments['key'] == 'wallet_encryption_key') {
          return '[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32]';
        }
        return null; // Return null for other reads
              case 'write':
                return null; // Success for writes
              case 'delete':
                return null; // Success for deletes
              case 'deleteAll':
                return null; // Success for delete all
              case 'readAll':
                return <String, String>{}; // Return empty map
              case 'containsKey':
                return false; // No keys exist
              default:
                return null;
            }
          },
        );

    // Mock shared_preferences
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'getAll':
                return <String, dynamic>{}; // Return empty preferences
              case 'setBool':
              case 'setInt':
              case 'setDouble':
              case 'setString':
              case 'setStringList':
                return true; // Success for all sets
              case 'remove':
                return true; // Success for removes
              case 'clear':
                return true; // Success for clear
              default:
                return null;
            }
          },
        );

    // Mock local_auth
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/local_auth'),
          (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'isDeviceSupported':
                return true;
              case 'getAvailableBiometrics':
                return <String>['fingerprint'];
              case 'authenticate':
                return true; // Always succeed authentication in tests
              case 'stopAuthentication':
                return true;
              default:
                return null;
            }
          },
        );

    // Mock device_info_plus
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/device_info'),
          (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'getDeviceInfo':
                return {
                  'isPhysicalDevice': true,
                  'model': 'Test Device',
                  'brand': 'Test',
                  'device': 'test_device',
                  'id': 'test_id',
                };
              default:
                return null;
            }
          },
        );

    // Mock connectivity_plus
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'check':
                return 'wifi'; // Always return wifi connection
              default:
                return null;
            }
          },
        );

    // Mock battery_plus
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/battery'),
          (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'getBatteryLevel':
                return 80; // Return 80% battery
              case 'getBatteryState':
                return 'full';
              default:
                return null;
            }
          },
        );

    // Mock permission_handler
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'checkPermissionStatus':
                return 1; // PermissionStatus.granted
              case 'requestPermissions':
                return {methodCall.arguments[0]: 1}; // Grant all permissions
              default:
                return null;
            }
          },
        );

    // Mock google_sign_in
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/google_sign_in'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'init') {
              return null;
            } else if (methodCall.method == 'signIn' || 
                       methodCall.method == 'signInSilently') {
              return {
                'displayName': 'Test User',
                'email': 'test@example.com',
                'id': '123456789',
                'photoUrl': null,
                'idToken': 'mock_token',
              };
            } else if (methodCall.method == 'getTokens') {
              return {
                'idToken': 'mock_id_token',
                'accessToken': 'mock_access_token',
              };
            } else if (methodCall.method == 'signOut' || methodCall.method == 'disconnect') {
              return null;
            }
            return null; 
          },
        );
  }

  /// Register all Hive adapters
  static void _registerAdapters() {
    // Credit Card adapters
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(CreditCardAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(CreditCardTransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(CreditCardStatementAdapter());
    }

    // KMH adapters
    if (!Hive.isAdapterRegistered(30)) {
      Hive.registerAdapter(KmhTransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(31)) {
      Hive.registerAdapter(KmhTransactionTypeAdapter());
    }

    // Recurring Transaction adapters
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(RecurringTransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(RecurrenceFrequencyAdapter());
    }
  }

  /// Setup for each individual test
  static Future<void> setupTest() async {
    // Initialize SharedPreferences with empty data
    SharedPreferences.setMockInitialValues({});

    // Initialize services
    try {
      await CreditCardBoxService.init();
      await DataService().init();

      // Initialize KMH and Recurring Transaction services
      print('TestSetup: Initializing KMH Box Service');
      await KmhBoxService.init();
      print('TestSetup: KMH Box Service initialized');

      final recurringRepo = RecurringTransactionRepository();
      await recurringRepo.init();
    } catch (e) {
      // Services might already be initialized
      print('Service initialization warning: $e');
    }
  }

  /// Cleanup after each test
  static Future<void> tearDownTest() async {
    try {
      // Clear all boxes instead of closing them
      if (CreditCardBoxService.creditCardsBox.isOpen) {
        await CreditCardBoxService.creditCardsBox.clear();
      }
      if (CreditCardBoxService.transactionsBox.isOpen) {
        await CreditCardBoxService.transactionsBox.clear();
      }
      if (CreditCardBoxService.statementsBox.isOpen) {
        await CreditCardBoxService.statementsBox.clear();
      }

      // Clear KMH boxes
      try {
        if (KmhBoxService.transactionsBox.isOpen) {
          await KmhBoxService.transactionsBox.clear();
          await KmhBoxService.transactionsBox.close();
        }
      } catch (_) {
        // Box might not be initialized
      }
    } catch (e) {
      // Ignore cleanup errors
      print('Cleanup warning: $e');
    }
  }

  /// Final cleanup after all tests
  static Future<void> cleanupTestEnvironment() async {
    try {
      // Clear platform channel mocks
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
            null,
          );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/shared_preferences'),
            null,
          );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/local_auth'),
            null,
          );

      await Hive.close();
      if (await Directory(testPath).exists()) {
        await Directory(testPath).delete(recursive: true);
      }
    } catch (e) {
      // Ignore cleanup errors
      print('Final cleanup warning: $e');
    }
  }

  /// Create a test widget with proper MaterialApp wrapper
  static Widget createTestWidget(Widget child, {ThemeData? theme}) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            height: 800, // Fixed height to prevent overflow
            child: child,
          ),
        ),
      ),
      locale: const Locale('tr', 'TR'),
    );
  }

  /// Create a test widget with custom constraints
  static Widget createConstrainedTestWidget(
    Widget child, {
    double? height,
    double? width,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            height: height ?? 800,
            width: width ?? 400,
            child: child,
          ),
        ),
      ),
      locale: const Locale('tr', 'TR'),
    );
  }
}
