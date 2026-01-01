import 'dart:convert';
import 'dart:io';

import '../../models/backup_optimization/backup_enums.dart';
import '../../models/backup_optimization/compression_models.dart';
import 'compression_engine.dart';
import 'optimization_engine.dart';

/// High-level compression service that orchestrates compression operations
class CompressionService {
  final CompressionEngine _engine = CompressionEngine();
  final OptimizationEngine _optimizer = OptimizationEngine();

  /// Compresses backup data using optimal algorithm selection
  Future<CompressedData> compressBackup(Map<String, dynamic> backupData) async {
    final stopwatch = Stopwatch()..start();
    
    // Convert backup data to bytes
    final jsonString = jsonEncode(backupData);
    final originalBytes = utf8.encode(jsonString);
    final originalSize = originalBytes.length;
    
    // Analyze data type
    final dataType = _engine.analyzeDataType(originalBytes);
    
    // Select optimal algorithm
    final algorithm = _engine.selectOptimalAlgorithm(dataType, dataSize: originalSize);
    
    // Compress the data
    final compressedBytes = await _engine.compress(originalBytes, algorithm);
    
    stopwatch.stop();
    
    return CompressedData(
      data: compressedBytes,
      algorithm: algorithm,
      originalSize: originalSize,
      compressedSize: compressedBytes.length,
      compressionTime: stopwatch.elapsed,
      metadata: {
        'dataType': dataType.name,
        'compressionRatio': compressedBytes.length / originalSize,
      },
    );
  }

  /// Decompresses backup data
  Future<Map<String, dynamic>> decompressBackup(CompressedData compressed) async {
    final decompressedBytes = await _engine.decompress(
      compressed.data, 
      compressed.algorithm,
    );
    
    final jsonString = utf8.decode(decompressedBytes);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Analyzes compression ratio for different algorithms
  Future<CompressionStats> analyzeCompressionRatio(Map<String, dynamic> backupData) async {
    final jsonString = jsonEncode(backupData);
    final originalBytes = utf8.encode(jsonString);
    final originalSize = originalBytes.length;
    
    // Benchmark all algorithms
    final algorithm = await _engine.benchmarkAlgorithms(originalBytes);
    
    final stopwatch = Stopwatch()..start();
    final compressedBytes = await _engine.compress(originalBytes, algorithm);
    stopwatch.stop();
    
    final ratio = compressedBytes.length / originalSize;
    final speed = originalSize / (1024 * 1024) / (stopwatch.elapsedMilliseconds / 1000.0);
    
    return CompressionStats(
      algorithm: algorithm,
      ratio: ratio,
      time: stopwatch.elapsed,
      originalSize: originalSize,
      compressedSize: compressedBytes.length,
      speed: speed,
    );
  }

  /// Compresses images with specialized optimization
  Future<List<int>> compressImages(List<String> imagePaths) async {
    final optimizedImages = <String, List<int>>{};
    
    for (final imagePath in imagePaths) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          final imageBytes = await file.readAsBytes();
          final optimized = await _optimizer.optimizeImage(imageBytes);
          optimizedImages[imagePath] = optimized;
        }
      } catch (e) {
        // Skip problematic images
        continue;
      }
    }
    
    // Compress the collection of optimized images
    final jsonString = jsonEncode(optimizedImages);
    final jsonBytes = utf8.encode(jsonString);
    
    return await _engine.compress(jsonBytes, CompressionAlgorithm.lz4);
  }

  /// Compresses JSON data with whitespace removal and optimization
  Future<List<int>> compressJsonData(Map<String, dynamic> jsonData) async {
    // Optimize JSON structure
    final optimizedJson = await _optimizer.optimizeJsonData(jsonData);
    
    // Convert to compact JSON string (no whitespace)
    final compactJsonString = jsonEncode(optimizedJson);
    final jsonBytes = utf8.encode(compactJsonString);
    
    // Use optimal algorithm for JSON
    final algorithm = _engine.selectOptimalAlgorithm(DataType.json, dataSize: jsonBytes.length);
    return await _engine.compress(jsonBytes, algorithm);
  }

  /// Compresses text data with preprocessing
  Future<List<int>> compressTextData(String textData) async {
    // Optimize text (remove unnecessary whitespace, normalize line endings)
    final optimizedText = await _optimizer.optimizeTextData(textData);
    final textBytes = utf8.encode(optimizedText);
    
    // Use optimal algorithm for text
    final algorithm = _engine.selectOptimalAlgorithm(DataType.text, dataSize: textBytes.length);
    return await _engine.compress(textBytes, algorithm);
  }

  /// Gets compression statistics for a specific algorithm and data
  Future<CompressionStats> getCompressionStats(
    List<int> data, 
    CompressionAlgorithm algorithm,
  ) async {
    final stopwatch = Stopwatch()..start();
    final compressed = await _engine.compress(data, algorithm);
    stopwatch.stop();
    
    final ratio = compressed.length / data.length;
    final speed = data.length / (1024 * 1024) / (stopwatch.elapsedMilliseconds / 1000.0);
    
    return CompressionStats(
      algorithm: algorithm,
      ratio: ratio,
      time: stopwatch.elapsed,
      originalSize: data.length,
      compressedSize: compressed.length,
      speed: speed,
    );
  }

  /// Compares compression performance across all algorithms
  Future<List<CompressionStats>> compareAlgorithms(List<int> data) async {
    final results = <CompressionStats>[];
    
    for (final algorithm in CompressionAlgorithm.values) {
      try {
        final stats = await getCompressionStats(data, algorithm);
        results.add(stats);
      } catch (e) {
        // Skip failed algorithms
        continue;
      }
    }
    
    // Sort by compression ratio (best first)
    results.sort((a, b) => a.ratio.compareTo(b.ratio));
    return results;
  }

  /// Estimates compression benefit for given data
  Future<bool> shouldCompress(List<int> data) async {
    // Don't compress very small data
    if (data.length < 1024) return false;
    
    // Quick test with GZIP
    final ratio = await _engine.calculateCompressionRatio(data, CompressionAlgorithm.gzip);
    
    // Only compress if we get at least 10% reduction
    return ratio < 0.9;
  }
}