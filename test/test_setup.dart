import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:money/models/credit_card.dart';
import 'package:money/models/credit_card_statement.dart';
import 'package:money/models/credit_card_transaction.dart';
import 'package:money/services/credit_card_box_service.dart';
import 'package:money/services/data_service.dart';
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
  }

  /// Setup for each individual test
  static Future<void> setupTest() async {
    // Initialize SharedPreferences with empty data
    SharedPreferences.setMockInitialValues({});

    // Initialize services
    try {
      await CreditCardBoxService.init();
      await DataService().init();
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
    } catch (e) {
      // Ignore cleanup errors
      print('Cleanup warning: $e');
    }
  }

  /// Final cleanup after all tests
  static Future<void> cleanupTestEnvironment() async {
    try {
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
  static Widget createTestWidget(Widget child) {
    return MaterialApp(
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
  static Widget createConstrainedTestWidget(Widget child, {double? height, double? width}) {
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