import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/backup_optimization/compression_engine.dart';
import 'package:parion/models/backup_optimization/backup_enums.dart';
import '../../property_test_utils.dart';

void main() {
  group('Compression Algorithm Selection Property Tests', () {
    late CompressionEngine compressionEngine;

    setUp(() {
      compressionEngine = CompressionEngine();
    });

    /// **Feature: backup-optimization, Property 5: Optimal Compression Algorithm Selection**
    /// **Validates: Requirements 2.1**
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 5: Optimal Compression Algorithm Selection - For any data type, the compression engine should select the most appropriate compression algorithm based on data characteristics',
      generator: _generateAlgorithmSelectionScenario,
      property: (scenario) async {
        final dataType = scenario['dataType'] as DataType;
        final dataSize = scenario['dataSize'] as int?;
        final expectedAlgorithm = scenario['expectedAlgorithm'] as CompressionAlgorithm;
        final testData = scenario['testData'] as List<int>;
        
        // Test the algorithm selection
        final selectedAlgorithm = compressionEngine.selectOptimalAlgorithm(
          dataType, 
          dataSize: dataSize,
        );
        
        // Property 1: Selected algorithm should match expected algorithm for data type
        final correctAlgorithmSelected = selectedAlgorithm == expectedAlgorithm;
        
        // Property 2: Selected algorithm should be valid for the data type
        final algorithmIsValid = _isValidAlgorithmForDataType(selectedAlgorithm, dataType);
        
        // Property 3: Algorithm should be able to compress the test data
        bool canCompressData = true;
        try {
          final compressed = await compressionEngine.compress(testData, selectedAlgorithm);
          canCompressData = compressed.isNotEmpty;
        } catch (e) {
          canCompressData = false;
        }
        
        // Property 4: For large JSON data, should prefer ZSTD over GZIP
        bool correctLargeJsonHandling = true;
        if (dataType == DataType.json && dataSize != null && dataSize > 1024 * 1024) {
          correctLargeJsonHandling = selectedAlgorithm == CompressionAlgorithm.zstd;
        }
        
        return correctAlgorithmSelected && 
               algorithmIsValid && 
               canCompressData && 
               correctLargeJsonHandling;
      },
      iterations: 20,
    );

    /// Additional property test for data type analysis
    PropertyTest.forAll<List<int>>(
      description: 'Data type analysis should correctly identify data characteristics',
      generator: _generateDataTypeAnalysisScenario,
      property: (testData) async {
        final analyzedType = compressionEngine.analyzeDataType(testData);
        
        // Property 1: Analyzed type should be one of the valid enum values
        final validType = DataType.values.contains(analyzedType);
        
        // Property 2: JSON data should be correctly identified
        bool correctJsonIdentification = true;
        try {
          final text = utf8.decode(testData);
          final isValidJson = _isValidJson(text);
          if (isValidJson) {
            correctJsonIdentification = analyzedType == DataType.json;
          }
        } catch (e) {
          // Not UTF-8 text, so JSON identification is not applicable
        }
        
        // Property 3: Image data should be correctly identified
        final correctImageIdentification = _validateImageIdentification(testData, analyzedType);
        
        return validType && correctJsonIdentification && correctImageIdentification;
      },
      iterations: 20,
    );

    /// Property test for algorithm benchmarking (basic validation only)
    PropertyTest.forAll<List<int>>(
      description: 'Algorithm benchmarking should return valid algorithms',
      generator: _generateBenchmarkScenario,
      property: (testData) async {
        if (testData.isEmpty) return true; // Skip empty data
        
        final bestAlgorithm = await compressionEngine.benchmarkAlgorithms(testData);
        
        // Property 1: Best algorithm should be a valid algorithm
        final validAlgorithm = CompressionAlgorithm.values.contains(bestAlgorithm);
        
        // Property 2: Best algorithm should be able to compress the data
        bool canCompress = true;
        try {
          final compressed = await compressionEngine.compress(testData, bestAlgorithm);
          canCompress = compressed.isNotEmpty;
        } catch (e) {
          canCompress = false;
        }
        
        // Note: Removed deterministic check as benchmarking can vary due to timing
        return validAlgorithm && canCompress;
      },
      iterations: 20,
    );

    test('Algorithm selection should be consistent for same inputs', () async {
      final algorithm1 = compressionEngine.selectOptimalAlgorithm(DataType.json);
      final algorithm2 = compressionEngine.selectOptimalAlgorithm(DataType.json);
      
      expect(algorithm1, equals(algorithm2));
    });

    test('Different data types should get different optimal algorithms', () async {
      final jsonAlgorithm = compressionEngine.selectOptimalAlgorithm(DataType.json);
      final imageAlgorithm = compressionEngine.selectOptimalAlgorithm(DataType.image);
      final textAlgorithm = compressionEngine.selectOptimalAlgorithm(DataType.text);
      final binaryAlgorithm = compressionEngine.selectOptimalAlgorithm(DataType.binary);
      
      // At least some algorithms should be different
      final algorithms = {jsonAlgorithm, imageAlgorithm, textAlgorithm, binaryAlgorithm};
      expect(algorithms.length, greaterThan(1));
    });
  });
}

/// Generate a scenario for testing algorithm selection
Map<String, dynamic> _generateAlgorithmSelectionScenario() {
  final dataTypes = DataType.values;
  final dataType = dataTypes[PropertyTest.randomInt(max: dataTypes.length - 1)];
  
  // Generate appropriate test data for the data type
  List<int> testData;
  int? dataSize;
  CompressionAlgorithm expectedAlgorithm;
  
  switch (dataType) {
    case DataType.json:
      final jsonObject = _generateRandomJsonObject();
      final jsonString = jsonEncode(jsonObject);
      testData = utf8.encode(jsonString);
      dataSize = testData.length;
      
      // Expected algorithm based on size
      expectedAlgorithm = dataSize > 1024 * 1024 
          ? CompressionAlgorithm.zstd 
          : CompressionAlgorithm.gzip;
      break;
      
    case DataType.image:
      testData = _generateImageData();
      dataSize = testData.length;
      expectedAlgorithm = CompressionAlgorithm.lz4;
      break;
      
    case DataType.text:
      final text = PropertyTest.randomString(minLength: 100, maxLength: 1000);
      testData = utf8.encode(text);
      dataSize = testData.length;
      expectedAlgorithm = CompressionAlgorithm.brotli;
      break;
      
    case DataType.binary:
      testData = List.generate(
        PropertyTest.randomInt(min: 100, max: 1000), 
        (_) => PropertyTest.randomInt(max: 255),
      );
      dataSize = testData.length;
      expectedAlgorithm = CompressionAlgorithm.zstd;
      break;
  }
  
  return {
    'dataType': dataType,
    'dataSize': dataSize,
    'expectedAlgorithm': expectedAlgorithm,
    'testData': testData,
  };
}

/// Generate a scenario for testing data type analysis
List<int> _generateDataTypeAnalysisScenario() {
  final scenarios = [
    () => _generateJsonData(),
    () => _generateTextData(),
    () => _generateImageData(),
    () => _generateBinaryData(),
  ];
  
  final scenarioIndex = PropertyTest.randomInt(max: scenarios.length - 1);
  return scenarios[scenarioIndex]();
}

/// Generate a scenario for benchmarking tests
List<int> _generateBenchmarkScenario() {
  final size = PropertyTest.randomInt(min: 100, max: 5000); // Reasonable size for benchmarking
  return List.generate(size, (_) => PropertyTest.randomInt(max: 255));
}

/// Generate random JSON data
List<int> _generateJsonData() {
  final jsonObject = _generateRandomJsonObject();
  final jsonString = jsonEncode(jsonObject);
  return utf8.encode(jsonString);
}

/// Generate random JSON object
Map<String, dynamic> _generateRandomJsonObject() {
  final object = <String, dynamic>{};
  final fieldCount = PropertyTest.randomInt(min: 1, max: 5);
  
  for (int i = 0; i < fieldCount; i++) {
    final key = 'field_${PropertyTest.randomString(maxLength: 10)}';
    final valueType = PropertyTest.randomInt(max: 3);
    
    switch (valueType) {
      case 0:
        object[key] = PropertyTest.randomString();
        break;
      case 1:
        object[key] = PropertyTest.randomDouble();
        break;
      case 2:
        object[key] = PropertyTest.randomBool();
        break;
      case 3:
        object[key] = List.generate(
          PropertyTest.randomInt(min: 1, max: 3),
          (_) => PropertyTest.randomString(),
        );
        break;
    }
  }
  
  return object;
}

/// Generate random text data
List<int> _generateTextData() {
  final text = PropertyTest.randomString(minLength: 50, maxLength: 500);
  return utf8.encode(text);
}

/// Generate fake image data (with proper headers)
List<int> _generateImageData() {
  final imageTypes = [
    () => _generateJpegHeader(),
    () => _generatePngHeader(),
    () => _generateGifHeader(),
  ];
  
  final typeIndex = PropertyTest.randomInt(max: imageTypes.length - 1);
  final header = imageTypes[typeIndex]();
  
  // Add some random data after the header
  final dataSize = PropertyTest.randomInt(min: 100, max: 1000);
  final randomData = List.generate(dataSize, (_) => PropertyTest.randomInt(max: 255));
  
  return [...header, ...randomData];
}

/// Generate JPEG header
List<int> _generateJpegHeader() {
  return [0xFF, 0xD8, 0xFF, 0xE0]; // JPEG SOI marker
}

/// Generate PNG header
List<int> _generatePngHeader() {
  return [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]; // PNG signature
}

/// Generate GIF header
List<int> _generateGifHeader() {
  return [0x47, 0x49, 0x46, 0x38, 0x39, 0x61]; // GIF89a signature
}

/// Generate random binary data
List<int> _generateBinaryData() {
  final size = PropertyTest.randomInt(min: 50, max: 500);
  return List.generate(size, (_) => PropertyTest.randomInt(max: 255));
}

/// Check if algorithm is valid for data type
bool _isValidAlgorithmForDataType(CompressionAlgorithm algorithm, DataType dataType) {
  // All algorithms should be valid for all data types in this implementation
  return CompressionAlgorithm.values.contains(algorithm);
}

/// Validate JSON string
bool _isValidJson(String text) {
  try {
    jsonDecode(text.trim());
    return true;
  } catch (e) {
    return false;
  }
}

/// Validate image identification
bool _validateImageIdentification(List<int> data, DataType analyzedType) {
  if (data.length < 4) return true; // Too small to determine
  
  // Check if it has image headers
  final hasJpegHeader = data.length >= 2 && data[0] == 0xFF && data[1] == 0xD8;
  final hasPngHeader = data.length >= 8 && 
      data[0] == 0x89 && data[1] == 0x50 && 
      data[2] == 0x4E && data[3] == 0x47;
  final hasGifHeader = data.length >= 6 &&
      data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46;
  
  final hasImageHeader = hasJpegHeader || hasPngHeader || hasGifHeader;
  
  // If it has image header, it should be identified as image
  if (hasImageHeader) {
    return analyzedType == DataType.image;
  }
  
  // If no image header, any identification is acceptable
  return true;
}