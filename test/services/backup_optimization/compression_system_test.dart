import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import 'package:parion/services/backup_optimization/compression_service.dart';
import 'package:parion/services/backup_optimization/compression_engine.dart';
import 'package:parion/models/backup_optimization/backup_enums.dart';

void main() {
  group('Compression System Tests', () {
    late CompressionService compressionService;
    late CompressionEngine compressionEngine;

    setUp(() {
      compressionService = CompressionService();
      compressionEngine = CompressionEngine();
    });

    test('should compress and decompress backup data correctly', () async {
      // Arrange
      final testData = {
        'transactions': [
          {'id': '1', 'amount': 100.0, 'description': 'Test transaction'},
          {'id': '2', 'amount': 200.0, 'description': 'Another transaction'},
        ],
        'wallets': [
          {'id': '1', 'name': 'Main Wallet', 'balance': 1000.0},
        ],
      };

      // Act
      final compressed = await compressionService.compressBackup(testData);
      final decompressed = await compressionService.decompressBackup(
        compressed,
      );

      // Assert
      expect(decompressed, equals(testData));
      expect(compressed.compressionRatio, lessThan(1.0));
    });

    test('should select optimal algorithm for JSON data', () {
      // Arrange
      final jsonData = utf8.encode(jsonEncode({'test': 'data'}));

      // Act
      final algorithm = compressionEngine.selectOptimalAlgorithm(
        DataType.json,
        dataSize: jsonData.length,
      );

      // Assert
      expect(algorithm, equals(CompressionAlgorithm.gzip));
    });

    test('should select optimal algorithm for image data', () {
      // Act
      final algorithm = compressionEngine.selectOptimalAlgorithm(
        DataType.image,
      );

      // Assert
      expect(algorithm, equals(CompressionAlgorithm.lz4));
    });

    test('should analyze data type correctly', () {
      // Arrange
      final jsonData = utf8.encode(jsonEncode({'test': 'data'}));
      final textData = utf8.encode('This is plain text data');

      // Act
      final jsonType = compressionEngine.analyzeDataType(jsonData);
      final textType = compressionEngine.analyzeDataType(textData);

      // Assert
      expect(jsonType, equals(DataType.json));
      expect(textType, equals(DataType.text));
    });

    test('should compress JSON data with optimization', () async {
      // Arrange
      final jsonData = {
        'users': [
          {'name': 'John', 'email': 'john@example.com'},
          {'name': 'Jane', 'email': 'jane@example.com'},
        ],
      };

      // Act
      final compressed = await compressionService.compressJsonData(jsonData);

      // Assert
      expect(compressed, isNotEmpty);
      expect(
        compressed.length,
        lessThan(utf8.encode(jsonEncode(jsonData)).length),
      );
    });

    test('should compress text data with optimization', () async {
      // Arrange
      const textData = '''
      This is a test text with    multiple spaces.
      
      
      It has multiple empty lines.
      And trailing spaces.   
      ''';

      // Act
      final compressed = await compressionService.compressTextData(textData);

      // Assert
      expect(compressed, isNotEmpty);
    });

    test('should calculate compression ratio', () async {
      // Arrange
      final testData = List.generate(1000, (i) => i % 256);

      // Act
      final ratio = await compressionEngine.calculateCompressionRatio(
        testData,
        CompressionAlgorithm.gzip,
      );

      // Assert
      expect(ratio, greaterThan(0.0));
      expect(ratio, lessThanOrEqualTo(1.0));
    });

    test('should determine if compression is beneficial', () async {
      // Arrange
      final smallData = [1, 2, 3]; // Too small to compress
      final largeData = List.generate(
        10000,
        (i) => i % 256,
      ); // Worth compressing

      // Act
      final shouldCompressSmall = await compressionService.shouldCompress(
        smallData,
      );
      final shouldCompressLarge = await compressionService.shouldCompress(
        largeData,
      );

      // Assert
      expect(shouldCompressSmall, isFalse);
      expect(shouldCompressLarge, isTrue);
    });
  });
}
