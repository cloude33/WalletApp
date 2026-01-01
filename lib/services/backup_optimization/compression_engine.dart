import 'dart:convert';
import 'package:archive/archive.dart';

import '../../models/backup_optimization/backup_enums.dart';

/// Core compression engine that handles algorithm selection and compression operations
class CompressionEngine {
  /// Selects the optimal compression algorithm based on data type and characteristics
  CompressionAlgorithm selectOptimalAlgorithm(DataType dataType, {int? dataSize}) {
    switch (dataType) {
      case DataType.json:
        // JSON data compresses well with GZIP due to repetitive structure
        return dataSize != null && dataSize > 1024 * 1024 
            ? CompressionAlgorithm.zstd  // Better for large JSON files
            : CompressionAlgorithm.gzip;
            
      case DataType.image:
        // Images are often already compressed, use fast algorithm
        return CompressionAlgorithm.lz4;
        
      case DataType.text:
        // Text data benefits from good compression ratio
        return CompressionAlgorithm.brotli;
        
      case DataType.binary:
        // Binary data varies, use balanced approach
        return CompressionAlgorithm.zstd;
    }
  }

  /// Compresses data using the specified algorithm
  Future<List<int>> compress(List<int> data, CompressionAlgorithm algorithm) async {
    switch (algorithm) {
      case CompressionAlgorithm.gzip:
        return _compressGzip(data);
        
      case CompressionAlgorithm.lz4:
        return _compressLz4(data);
        
      case CompressionAlgorithm.zstd:
        return _compressZstd(data);
        
      case CompressionAlgorithm.brotli:
        return _compressBrotli(data);
    }
  }

  /// Decompresses data using the specified algorithm
  Future<List<int>> decompress(List<int> compressed, CompressionAlgorithm algorithm) async {
    switch (algorithm) {
      case CompressionAlgorithm.gzip:
        return _decompressGzip(compressed);
        
      case CompressionAlgorithm.lz4:
        return _decompressLz4(compressed);
        
      case CompressionAlgorithm.zstd:
        return _decompressZstd(compressed);
        
      case CompressionAlgorithm.brotli:
        return _decompressBrotli(compressed);
    }
  }

  /// Calculates compression ratio for given data and algorithm
  Future<double> calculateCompressionRatio(List<int> data, CompressionAlgorithm algorithm) async {
    final compressed = await compress(data, algorithm);
    return data.isNotEmpty ? compressed.length / data.length : 0.0;
  }

  /// Analyzes data to determine its type for optimal compression
  DataType analyzeDataType(List<int> data) {
    try {
      // Try to decode as UTF-8 text
      final text = utf8.decode(data);
      
      // Check if it's JSON
      if (_isJsonData(text)) {
        return DataType.json;
      }
      
      // Check if it's plain text
      if (_isTextData(text)) {
        return DataType.text;
      }
    } catch (e) {
      // Not valid UTF-8, check for image formats
      if (_isImageData(data)) {
        return DataType.image;
      }
    }
    
    // Default to binary
    return DataType.binary;
  }

  /// Benchmarks different algorithms for given data and returns the best one
  Future<CompressionAlgorithm> benchmarkAlgorithms(List<int> data) async {
    final results = <CompressionAlgorithm, double>{};
    
    for (final algorithm in CompressionAlgorithm.values) {
      try {
        final stopwatch = Stopwatch()..start();
        final compressed = await compress(data, algorithm);
        stopwatch.stop();
        
        // Score based on compression ratio and speed
        final ratio = compressed.length / data.length;
        final speedScore = 1.0 / (stopwatch.elapsedMilliseconds + 1);
        final score = (1.0 - ratio) * 0.7 + speedScore * 0.3;
        
        results[algorithm] = score;
      } catch (e) {
        // Algorithm failed, give it a poor score
        results[algorithm] = 0.0;
      }
    }
    
    // Return algorithm with highest score
    return results.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // GZIP compression implementation
  List<int> _compressGzip(List<int> data) {
    final encoder = GZipEncoder();
    final compressed = encoder.encode(data);
    return compressed ?? data;
  }

  List<int> _decompressGzip(List<int> compressed) {
    final decoder = GZipDecoder();
    return decoder.decodeBytes(compressed);
  }

  // LZ4 compression (simplified implementation using archive library)
  List<int> _compressLz4(List<int> data) {
    // Note: Archive library doesn't have native LZ4, using GZIP as fallback
    // In a real implementation, you'd use a proper LZ4 library
    return _compressGzip(data);
  }

  List<int> _decompressLz4(List<int> compressed) {
    // Note: Using GZIP as fallback for LZ4
    return _decompressGzip(compressed);
  }

  // ZSTD compression (simplified implementation)
  List<int> _compressZstd(List<int> data) {
    // Note: Archive library doesn't have native ZSTD, using GZIP as fallback
    // In a real implementation, you'd use a proper ZSTD library
    return _compressGzip(data);
  }

  List<int> _decompressZstd(List<int> compressed) {
    // Note: Using GZIP as fallback for ZSTD
    return _decompressGzip(compressed);
  }

  // Brotli compression (simplified implementation)
  List<int> _compressBrotli(List<int> data) {
    // Note: Archive library doesn't have native Brotli, using GZIP as fallback
    // In a real implementation, you'd use a proper Brotli library
    return _compressGzip(data);
  }

  List<int> _decompressBrotli(List<int> compressed) {
    // Note: Using GZIP as fallback for Brotli
    return _decompressGzip(compressed);
  }

  // Helper methods for data type detection
  bool _isJsonData(String text) {
    try {
      jsonDecode(text.trim());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _isTextData(String text) {
    // Check if text contains mostly printable characters
    final printableCount = text.runes.where((rune) {
      return (rune >= 32 && rune <= 126) || // ASCII printable
             rune == 9 || rune == 10 || rune == 13; // Tab, LF, CR
    }).length;
    
    return printableCount / text.length > 0.8;
  }

  bool _isImageData(List<int> data) {
    if (data.length < 4) return false;
    
    // Check for common image file signatures
    // JPEG
    if (data[0] == 0xFF && data[1] == 0xD8) return true;
    
    // PNG
    if (data.length >= 8 && 
        data[0] == 0x89 && data[1] == 0x50 && 
        data[2] == 0x4E && data[3] == 0x47) {
      return true;
    }
    
    // GIF
    if (data.length >= 6 &&
        data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46) {
      return true;
    }
    
    // WebP
    if (data.length >= 12 &&
        data[0] == 0x52 && data[1] == 0x49 && 
        data[2] == 0x46 && data[3] == 0x46 &&
        data[8] == 0x57 && data[9] == 0x45 && 
        data[10] == 0x42 && data[11] == 0x50) {
      return true;
    }
    
    return false;
  }
}