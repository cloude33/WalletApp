import 'package:flutter_test/flutter_test.dart';

// Import all fast tests
import 'widgets/simple_widget_test.dart' as simple_widget_test;
import 'widgets/credit_card_analysis_simple_test.dart' as credit_card_simple_test;
import 'widgets/tab_switching_simple_test.dart' as tab_switching_simple_test;

/// Fast test suite that runs quickly without heavy dependencies
void main() {
  group('Fast Test Suite', () {
    group('Simple Widget Tests', simple_widget_test.main);
    group('Credit Card Analysis Simple Tests', credit_card_simple_test.main);
    group('Tab Switching Simple Tests', tab_switching_simple_test.main);
  });
}