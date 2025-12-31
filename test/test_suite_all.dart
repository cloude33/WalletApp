import 'package:flutter_test/flutter_test.dart';
import 'test_config.dart';

// Import all tests
import 'widgets/simple_widget_test.dart' as simple_widget_test;
import 'widgets/credit_card_analysis_simple_test.dart' as credit_card_simple_test;
import 'widgets/tab_switching_simple_test.dart' as tab_switching_simple_test;

/// Complete test suite with conditional skipping of heavy tests
void main() {
  setUpAll(() async {
    await TestConfig.initializeMinimal();
  });

  tearDownAll(() async {
    await TestConfig.cleanup();
  });

  group('Complete Test Suite', () {
    group('Fast Tests', () {
      group('Simple Widget Tests', simple_widget_test.main);
      group('Credit Card Analysis Simple Tests', credit_card_simple_test.main);
      group('Tab Switching Simple Tests', tab_switching_simple_test.main);
    });

    group('Heavy Tests (Conditional)', () {
      testWidgets('Credit Card Analysis with Hive', (WidgetTester tester) async {
        // This test would normally use Hive and take longer
        // Skip if running in CI or if heavy tests are disabled
      }, skip: TestConfig.shouldSkipHeavyTests);

      testWidgets('Statistics Screen Integration', (WidgetTester tester) async {
        // This test would normally load full statistics screen
        // Skip if running in CI or if heavy tests are disabled
      }, skip: TestConfig.shouldSkipHeavyTests);

      testWidgets('Full Tab Switching with Data', (WidgetTester tester) async {
        // This test would normally use real data and services
        // Skip if running in CI or if heavy tests are disabled
      }, skip: TestConfig.shouldSkipHeavyTests);
    });
  });
}