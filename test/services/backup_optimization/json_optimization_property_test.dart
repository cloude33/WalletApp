import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/backup_optimization/compression_service.dart';
import 'package:parion/services/backup_optimization/optimization_engine.dart';
import '../../property_test_utils.dart';

void main() {
  group('JSON Optimization Property Tests', () {
    late CompressionService compressionService;
    late OptimizationEngine optimizationEngine;

    setUp(() {
      compressionService = CompressionService();
      optimizationEngine = OptimizationEngine();
    });

    /// **Feature: backup-optimization, Property 7: JSON Data Compression Optimization**
    /// **Validates: Requirements 2.3**
    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 7: JSON Data Compression Optimization - For any JSON data, the compression engine should remove unnecessary whitespace and redundancies before compression',
      generator: _generateJsonOptimizationScenario,
      property: (jsonData) async {
        // Get original JSON size (with whitespace)
        final originalJsonString = _jsonEncodeWithWhitespace(jsonData);
        final originalBytes = utf8.encode(originalJsonString);

        // Compress using the JSON optimization method
        final compressedBytes = await compressionService.compressJsonData(
          jsonData,
        );

        // Also test the optimization engine directly
        final optimizedJson = await optimizationEngine.optimizeJsonData(
          jsonData,
        );
        final optimizedJsonString = jsonEncode(optimizedJson);
        final optimizedBytes = utf8.encode(optimizedJsonString);

        // Property 1: Optimized JSON should be smaller or equal to original
        final optimizationReducesSize =
            optimizedBytes.length <= originalBytes.length;

        // Property 2: Compressed result should not be empty
        final compressionProducesOutput = compressedBytes.isNotEmpty;

        // Property 3: Optimized JSON should preserve essential data structure
        final dataStructurePreserved = _validateDataStructurePreservation(
          jsonData,
          optimizedJson,
        );

        // Property 4: Optimized JSON should remove null values and empty strings
        final nullsAndEmptyStringsRemoved = _validateNullAndEmptyStringRemoval(
          jsonData,
          optimizedJson,
        );

        // Property 5: If original has redundant strings, optimization should apply string interning
        final stringInterningApplied = _validateStringInterning(
          jsonData,
          optimizedJson,
        );

        // Property 6: Optimized JSON should be valid JSON
        bool optimizedJsonIsValid = true;
        try {
          jsonDecode(optimizedJsonString);
        } catch (e) {
          optimizedJsonIsValid = false;
        }

        return optimizationReducesSize &&
            compressionProducesOutput &&
            dataStructurePreserved &&
            nullsAndEmptyStringsRemoved &&
            stringInterningApplied &&
            optimizedJsonIsValid;
      },
      iterations: 20,
    );

    /// Additional property test for whitespace removal
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'JSON optimization should remove unnecessary whitespace',
      generator: _generateJsonWithWhitespace,
      property: (jsonData) async {
        final optimizedJson = await optimizationEngine.optimizeJsonData(
          jsonData,
        );

        // Convert both to compact JSON strings
        final originalCompact = jsonEncode(jsonData);
        final optimizedCompact = jsonEncode(optimizedJson);

        // Property 1: Optimized version should not be larger than original compact version
        final sizeNotIncreased =
            optimizedCompact.length <= originalCompact.length;

        // Property 2: Both should decode to equivalent data (after removing nulls/empty strings)
        final normalizedOriginal = _removeNullsAndEmptyStrings(jsonData);
        final equivalentData = _deepEquals(normalizedOriginal, optimizedJson);

        return sizeNotIncreased && equivalentData;
      },
      iterations: 20,
    );

    /// Property test for string interning optimization
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'String interning should be applied when beneficial',
      generator: _generateJsonWithRepeatedStrings,
      property: (jsonData) async {
        final optimizedJson = await optimizationEngine.optimizeJsonData(
          jsonData,
        );

        // Property 1: If optimization applied string interning, should have __stringMap
        final hasStringMap = optimizedJson.containsKey('__stringMap');

        // Property 2: If string interning was applied, the data should be under 'data' key
        final hasDataKey = !hasStringMap || optimizedJson.containsKey('data');

        // Property 3: String interning should only be applied when beneficial
        final stringInterningBeneficial = _validateStringInterningBenefit(
          jsonData,
          optimizedJson,
        );

        return hasDataKey && stringInterningBeneficial;
      },
      iterations: 20,
    );

    test('JSON optimization should handle edge cases', () async {
      // Test empty object
      final emptyResult = await optimizationEngine.optimizeJsonData({});
      expect(emptyResult, isEmpty);

      // Test object with only null values
      final nullOnlyResult = await optimizationEngine.optimizeJsonData({
        'field1': null,
        'field2': null,
      });
      expect(nullOnlyResult, isEmpty);

      // Test object with only empty strings
      final emptyStringResult = await optimizationEngine.optimizeJsonData({
        'field1': '',
        'field2': '',
      });
      expect(emptyStringResult, isEmpty);
    });
  });
}

/// Generate JSON data for optimization testing
Map<String, dynamic> _generateJsonOptimizationScenario() {
  final data = <String, dynamic>{};
  final fieldCount = PropertyTest.randomInt(min: 1, max: 8);

  for (int i = 0; i < fieldCount; i++) {
    final key = 'field_$i';
    final valueType = PropertyTest.randomInt(max: 6);

    switch (valueType) {
      case 0:
        data[key] = PropertyTest.randomString(minLength: 1, maxLength: 50);
        break;
      case 1:
        data[key] = PropertyTest.randomDouble();
        break;
      case 2:
        data[key] = PropertyTest.randomBool();
        break;
      case 3:
        data[key] = null; // Include nulls to test removal
        break;
      case 4:
        data[key] = ''; // Include empty strings to test removal
        break;
      case 5:
        // Nested object
        data[key] = {
          'nested_field': PropertyTest.randomString(),
          'nested_null': null,
          'nested_empty': '',
        };
        break;
      case 6:
        // Array with mixed content
        data[key] = [
          PropertyTest.randomString(),
          null,
          '',
          PropertyTest.randomDouble(),
        ];
        break;
    }
  }

  return data;
}

/// Generate JSON with extra whitespace (simulated by adding redundant fields)
Map<String, dynamic> _generateJsonWithWhitespace() {
  final data = _generateJsonOptimizationScenario();

  // Add some redundant empty fields to simulate "whitespace"
  data['__whitespace_1'] = '';
  data['__whitespace_2'] = null;
  data['__empty_array'] = <dynamic>[];
  data['__empty_object'] = <String, dynamic>{};

  return data;
}

/// Generate JSON with repeated strings for interning test
Map<String, dynamic> _generateJsonWithRepeatedStrings() {
  final repeatedString = PropertyTest.randomString(
    minLength: 15,
    maxLength: 30,
  );
  final shortString = PropertyTest.randomString(minLength: 1, maxLength: 5);

  return {
    'users': [
      {'name': 'User1', 'description': repeatedString, 'short': shortString},
      {'name': 'User2', 'description': repeatedString, 'short': shortString},
      {'name': 'User3', 'description': repeatedString, 'short': shortString},
    ],
    'metadata': {'description': repeatedString, 'category': shortString},
    'settings': {'help_text': repeatedString, 'label': shortString},
  };
}

/// Encode JSON with extra whitespace for testing
String _jsonEncodeWithWhitespace(Map<String, dynamic> data) {
  // Simulate JSON with extra whitespace by using JsonEncoder with indent
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(data);
}

/// Validate that data structure is preserved after optimization
bool _validateDataStructurePreservation(
  Map<String, dynamic> original,
  Map<String, dynamic> optimized,
) {
  // Remove nulls and empty strings from original for comparison
  final normalizedOriginal = _removeNullsAndEmptyStrings(original);

  // If optimization applied string interning, extract the actual data
  final actualOptimized = optimized.containsKey('__stringMap')
      ? optimized['data'] as Map<String, dynamic>? ?? {}
      : optimized;

  return _deepEquals(normalizedOriginal, actualOptimized);
}

/// Validate that null values and empty strings are removed
bool _validateNullAndEmptyStringRemoval(
  Map<String, dynamic> original,
  Map<String, dynamic> optimized,
) {
  // Extract actual data if string interning was applied
  final actualOptimized = optimized.containsKey('__stringMap')
      ? optimized['data'] as Map<String, dynamic>? ?? {}
      : optimized;

  return !_containsNullsOrEmptyStrings(actualOptimized);
}

/// Validate string interning application
bool _validateStringInterning(
  Map<String, dynamic> original,
  Map<String, dynamic> optimized,
) {
  final hasStringMap = optimized.containsKey('__stringMap');

  if (!hasStringMap) {
    // String interning not applied - this is fine if there are no repeated long strings
    return true;
  }

  // If string interning was applied, validate it was beneficial
  final stringMap = optimized['__stringMap'] as Map<String, dynamic>?;
  if (stringMap == null || stringMap.isEmpty) {
    return false; // Invalid string interning
  }

  // Check that interned strings are actually long enough to be worth interning
  return stringMap.values.every(
    (value) => value is String && value.length > 10,
  );
}

/// Validate that string interning is only applied when beneficial
bool _validateStringInterningBenefit(
  Map<String, dynamic> original,
  Map<String, dynamic> optimized,
) {
  final hasStringMap = optimized.containsKey('__stringMap');

  if (!hasStringMap) {
    return true; // No string interning is always valid
  }

  // If string interning was applied, the original should have had repeated long strings
  final stringFrequency = <String, int>{};
  _countStringFrequency(original, stringFrequency);

  // Check if there were strings worth interning (length > 10, frequency > 1)
  final worthInterning = stringFrequency.entries.any(
    (entry) => entry.key.length > 10 && entry.value > 1,
  );

  return worthInterning;
}

/// Remove nulls and empty strings from data structure
Map<String, dynamic> _removeNullsAndEmptyStrings(Map<String, dynamic> data) {
  final result = <String, dynamic>{};

  for (final entry in data.entries) {
    final value = entry.value;

    if (value == null || (value is String && value.isEmpty)) {
      continue; // Skip nulls and empty strings
    } else if (value is Map<String, dynamic>) {
      final nested = _removeNullsAndEmptyStrings(value);
      if (nested.isNotEmpty) {
        result[entry.key] = nested;
      }
    } else if (value is List) {
      final filtered = _removeNullsAndEmptyStringsFromList(value);
      if (filtered.isNotEmpty) {
        result[entry.key] = filtered;
      }
    } else {
      result[entry.key] = value;
    }
  }

  return result;
}

/// Remove nulls and empty strings from list
List<dynamic> _removeNullsAndEmptyStringsFromList(List<dynamic> list) {
  final result = <dynamic>[];

  for (final item in list) {
    if (item == null || (item is String && item.isEmpty)) {
      continue; // Skip nulls and empty strings
    } else if (item is Map<String, dynamic>) {
      final nested = _removeNullsAndEmptyStrings(item);
      if (nested.isNotEmpty) {
        result.add(nested);
      }
    } else if (item is List) {
      final filtered = _removeNullsAndEmptyStringsFromList(item);
      if (filtered.isNotEmpty) {
        result.add(filtered);
      }
    } else {
      result.add(item);
    }
  }

  return result;
}

/// Check if data contains nulls or empty strings
bool _containsNullsOrEmptyStrings(dynamic data) {
  if (data == null || (data is String && data.isEmpty)) {
    return true;
  } else if (data is Map<String, dynamic>) {
    return data.values.any(_containsNullsOrEmptyStrings);
  } else if (data is List) {
    return data.any(_containsNullsOrEmptyStrings);
  }

  return false;
}

/// Deep equality check for data structures
bool _deepEquals(dynamic a, dynamic b) {
  if (a.runtimeType != b.runtimeType) return false;

  if (a is Map<String, dynamic> && b is Map<String, dynamic>) {
    if (a.length != b.length) return false;

    for (final key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) {
        return false;
      }
    }
    return true;
  } else if (a is List && b is List) {
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) {
        return false;
      }
    }
    return true;
  } else {
    return a == b;
  }
}

/// Count string frequency in data structure
void _countStringFrequency(dynamic data, Map<String, int> frequency) {
  if (data is Map<String, dynamic>) {
    for (final value in data.values) {
      if (value is String && value.length > 10) {
        frequency[value] = (frequency[value] ?? 0) + 1;
      } else if (value is Map || value is List) {
        _countStringFrequency(value, frequency);
      }
    }
  } else if (data is List) {
    for (final item in data) {
      if (item is String && item.length > 10) {
        frequency[item] = (frequency[item] ?? 0) + 1;
      } else if (item is Map || item is List) {
        _countStringFrequency(item, frequency);
      }
    }
  }
}
