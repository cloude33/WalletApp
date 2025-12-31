import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

/// Test configuration utilities for managing Hive and other dependencies
class TestConfig {
  static late String testPath;
  static bool _hiveInitialized = false;

  /// Initialize test environment with minimal setup
  static Future<void> initializeMinimal() async {
    // Initialize SharedPreferences with empty data
    SharedPreferences.setMockInitialValues({});
  }

  /// Initialize test environment with Hive (slower, use sparingly)
  static Future<void> initializeWithHive() async {
    if (_hiveInitialized) return;

    testPath = 'test_hive_${DateTime.now().millisecondsSinceEpoch}';
    await Directory(testPath).create(recursive: true);
    Hive.init(testPath);
    
    _hiveInitialized = true;
  }

  /// Clean up test environment
  static Future<void> cleanup() async {
    try {
      if (_hiveInitialized) {
        await Hive.close();
        await Directory(testPath).delete(recursive: true);
        _hiveInitialized = false;
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  /// Create a test timeout configuration
  static Timeout createTimeout({int seconds = 15}) {
    return Timeout(Duration(seconds: seconds));
  }

  /// Skip heavy tests in CI or when running all tests
  static bool get shouldSkipHeavyTests {
    return Platform.environment['CI'] == 'true' || 
           Platform.environment['SKIP_HEAVY_TESTS'] == 'true';
  }
}

/// Test utilities for common widget testing patterns
class TestUtils {
  /// Pump widget with standard timeout
  static Future<void> pumpWidgetWithTimeout(
    WidgetTester tester, 
    Widget widget, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle(timeout);
  }

  /// Create a basic MaterialApp wrapper
  static Widget wrapWithMaterialApp(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  /// Create a test data set for transactions
  static List<Map<String, dynamic>> createTestTransactions(int count) {
    return List.generate(count, (i) => {
      'id': 'trans_$i',
      'amount': 100.0 * (i + 1),
      'description': 'Test Transaction $i',
      'date': DateTime.now().subtract(Duration(days: i)),
      'type': i % 2 == 0 ? 'income' : 'expense',
      'category': 'Test Category',
    });
  }
}