import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

/// Simple property-based testing utility for Dart
class PropertyTest {
  static final Random _random = Random();
  
  /// Run a property test with the specified number of iterations
  static void forAll<T>({
    required String description,
    required T Function() generator,
    required dynamic Function(T) property,
    int iterations = 100,
  }) {
    test(description, () async {
      for (int i = 0; i < iterations; i++) {
        final value = generator();
        final result = await property(value);
        
        if (result is! bool || !result) {
          fail('Property failed for input: $value (iteration $i)');
        }
      }
    });
  }
  
  /// Generate a random string
  static String randomString({int minLength = 1, int maxLength = 20}) {
    final length = minLength + _random.nextInt(maxLength - minLength + 1);
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(_random.nextInt(chars.length)))
    );
  }
  
  /// Generate a random positive double
  static double randomPositiveDouble({double min = 0.01, double max = 100000.0}) {
    return min + _random.nextDouble() * (max - min);
  }
  
  /// Generate a random double (can be negative)
  static double randomDouble({double min = -100000.0, double max = 100000.0}) {
    return min + _random.nextDouble() * (max - min);
  }
  
  /// Generate a random integer
  static int randomInt({int min = 0, int max = 1000}) {
    return min + _random.nextInt(max - min + 1);
  }
  
  /// Generate a random boolean
  static bool randomBool() {
    return _random.nextBool();
  }
  
  /// Generate a random DateTime
  static DateTime randomDateTime({DateTime? start, DateTime? end}) {
    final startDate = start ?? DateTime(2020, 1, 1);
    final endDate = end ?? DateTime(2030, 12, 31);
    final diff = endDate.difference(startDate).inDays;
    final randomDays = _random.nextInt(diff);
    return startDate.add(Duration(days: randomDays));
  }
  
  /// Generate a random DateTime for a specific month (first day of month)
  static DateTime randomMonthPeriod({int? year, int? month}) {
    final y = year ?? (2020 + _random.nextInt(10));
    final m = month ?? (1 + _random.nextInt(12));
    return DateTime(y, m, 1);
  }
}
