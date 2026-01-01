/// Supported image types for optimization
enum ImageType {
  jpeg,
  png,
  gif,
  webp,
  unknown,
}

/// Engine for optimizing different types of data before compression
class OptimizationEngine {
  /// Optimizes image data for better compression
  Future<List<int>> optimizeImage(List<int> imageBytes) async {
    // Detect image format and apply appropriate optimization
    final imageType = _detectImageType(imageBytes);
    
    switch (imageType) {
      case ImageType.jpeg:
        return await _optimizeJpeg(imageBytes);
      case ImageType.png:
        return await _optimizePng(imageBytes);
      case ImageType.gif:
        return await _optimizeGif(imageBytes);
      case ImageType.webp:
        return imageBytes; // WebP is already optimized
      case ImageType.unknown:
        return imageBytes; // Can't optimize unknown format
    }
  }

  /// Optimizes JSON data structure for better compression
  Future<Map<String, dynamic>> optimizeJsonData(Map<String, dynamic> jsonData) async {
    final optimized = _optimizeJsonRecursive(jsonData);
    
    // Additional JSON-specific optimizations
    return _applyJsonCompressionOptimizations(optimized);
  }

  /// Applies JSON-specific compression optimizations
  Map<String, dynamic> _applyJsonCompressionOptimizations(Map<String, dynamic> data) {
    final optimized = <String, dynamic>{};
    
    // Create string interning map for repeated values
    final stringInternMap = <String, String>{};
    final reverseLookup = <String, String>{};
    int internCounter = 0;
    
    // First pass: identify frequently used strings
    final stringFrequency = <String, int>{};
    _countStringFrequency(data, stringFrequency);
    
    // Create intern map for strings that appear more than once and are longer than 10 chars
    for (final entry in stringFrequency.entries) {
      if (entry.value > 1 && entry.key.length > 10) {
        final internKey = '\$${internCounter++}';
        stringInternMap[entry.key] = internKey;
        reverseLookup[internKey] = entry.key;
      }
    }
    
    // Second pass: apply string interning
    if (stringInternMap.isNotEmpty) {
      optimized['__stringMap'] = reverseLookup;
      optimized['data'] = _applyStringInterning(data, stringInternMap);
    } else {
      // No string interning needed, return optimized data directly
      return data;
    }
    
    return optimized;
  }

  /// Counts frequency of strings in JSON data
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

  /// Applies string interning to reduce JSON size
  dynamic _applyStringInterning(dynamic data, Map<String, String> internMap) {
    if (data is Map<String, dynamic>) {
      final result = <String, dynamic>{};
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is String && internMap.containsKey(value)) {
          result[entry.key] = internMap[value];
        } else if (value is Map || value is List) {
          result[entry.key] = _applyStringInterning(value, internMap);
        } else {
          result[entry.key] = value;
        }
      }
      return result;
    } else if (data is List) {
      return data.map((item) {
        if (item is String && internMap.containsKey(item)) {
          return internMap[item];
        } else if (item is Map || item is List) {
          return _applyStringInterning(item, internMap);
        } else {
          return item;
        }
      }).toList();
    }
    
    return data;
  }

  /// Optimizes text data for better compression
  Future<String> optimizeTextData(String textData) async {
    // Normalize line endings
    String optimized = textData.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    
    // Remove trailing whitespace from lines
    optimized = optimized
        .split('\n')
        .map((line) => line.trimRight())
        .join('\n');
    
    // Remove multiple consecutive empty lines (keep max 2)
    optimized = optimized.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');
    
    // Normalize multiple spaces to single space (except at line start for indentation)
    final lines = optimized.split('\n');
    final normalizedLines = lines.map((line) {
      if (line.trim().isEmpty) return '';
      
      // Preserve leading whitespace for indentation
      final leadingWhitespace = RegExp(r'^\s*').firstMatch(line)?.group(0) ?? '';
      final content = line.substring(leadingWhitespace.length);
      
      // Normalize multiple spaces in content
      final normalizedContent = content.replaceAll(RegExp(r' +'), ' ');
      
      return leadingWhitespace + normalizedContent;
    });
    
    optimized = normalizedLines.join('\n');
    
    // Remove excessive punctuation repetition (e.g., "!!!" -> "!")
    optimized = optimized.replaceAll(RegExp(r'([!?.])\1{2,}'), r'$1');
    
    // Trim leading and trailing whitespace
    optimized = optimized.trim();
    
    return optimized;
  }

  /// Recursively optimizes JSON structure
  Map<String, dynamic> _optimizeJsonRecursive(Map<String, dynamic> data) {
    final optimized = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value == null) {
        // Skip null values to reduce size
        continue;
      } else if (value is Map<String, dynamic>) {
        final optimizedNested = _optimizeJsonRecursive(value);
        if (optimizedNested.isNotEmpty) {
          optimized[key] = optimizedNested;
        }
      } else if (value is List) {
        final optimizedList = _optimizeJsonList(value);
        if (optimizedList.isNotEmpty) {
          optimized[key] = optimizedList;
        }
      } else if (value is String) {
        // Only include non-empty strings
        if (value.isNotEmpty) {
          optimized[key] = value;
        }
      } else if (value is num) {
        // Include all numbers (including 0)
        optimized[key] = value;
      } else if (value is bool) {
        // Include all boolean values
        optimized[key] = value;
      } else {
        // Include other types as-is
        optimized[key] = value;
      }
    }
    
    return optimized;
  }

  /// Optimizes JSON list by removing null values and empty objects
  List<dynamic> _optimizeJsonList(List<dynamic> list) {
    final optimized = <dynamic>[];
    
    for (final item in list) {
      if (item == null) {
        // Skip null values
        continue;
      } else if (item is Map<String, dynamic>) {
        final optimizedMap = _optimizeJsonRecursive(item);
        if (optimizedMap.isNotEmpty) {
          optimized.add(optimizedMap);
        }
      } else if (item is List) {
        final optimizedList = _optimizeJsonList(item);
        if (optimizedList.isNotEmpty) {
          optimized.add(optimizedList);
        }
      } else if (item is String) {
        // Only include non-empty strings
        if (item.isNotEmpty) {
          optimized.add(item);
        }
      } else {
        // Include other types as-is
        optimized.add(item);
      }
    }
    
    return optimized;
  }

  /// Analyzes data to suggest optimization strategies
  Map<String, dynamic> analyzeOptimizationPotential(Map<String, dynamic> data) {
    int nullCount = 0;
    int emptyStringCount = 0;
    int totalFields = 0;
    
    _countOptimizableFields(data, (type) {
      totalFields++;
      switch (type) {
        case 'null':
          nullCount++;
          break;
        case 'emptyString':
          emptyStringCount++;
          break;
      }
    });
    
    final optimizableFields = nullCount + emptyStringCount;
    final optimizationPotential = totalFields > 0 ? optimizableFields / totalFields : 0.0;
    
    return {
      'totalFields': totalFields,
      'nullFields': nullCount,
      'emptyStringFields': emptyStringCount,
      'optimizableFields': optimizableFields,
      'optimizationPotential': optimizationPotential,
      'estimatedSizeReduction': optimizationPotential * 0.1, // Rough estimate
    };
  }

  /// Recursively counts optimizable fields
  void _countOptimizableFields(dynamic data, void Function(String type) counter) {
    if (data is Map<String, dynamic>) {
      for (final value in data.values) {
        if (value == null) {
          counter('null');
        } else if (value is String && value.isEmpty) {
          counter('emptyString');
        } else if (value is Map || value is List) {
          _countOptimizableFields(value, counter);
        } else {
          counter('other');
        }
      }
    } else if (data is List) {
      for (final item in data) {
        if (item == null) {
          counter('null');
        } else if (item is String && item.isEmpty) {
          counter('emptyString');
        } else if (item is Map || item is List) {
          _countOptimizableFields(item, counter);
        } else {
          counter('other');
        }
      }
    }
  }

  // Image optimization methods

  /// Detects image type from byte signature
  ImageType _detectImageType(List<int> bytes) {
    if (bytes.length < 4) return ImageType.unknown;
    
    // JPEG signature
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return ImageType.jpeg;
    }
    
    // PNG signature
    if (bytes.length >= 8 && 
        bytes[0] == 0x89 && bytes[1] == 0x50 && 
        bytes[2] == 0x4E && bytes[3] == 0x47) {
      return ImageType.png;
    }
    
    // GIF signature
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return ImageType.gif;
    }
    
    // WebP signature
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && 
        bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && 
        bytes[10] == 0x42 && bytes[11] == 0x50) {
      return ImageType.webp;
    }
    
    return ImageType.unknown;
  }

  /// Optimizes JPEG images by removing metadata
  Future<List<int>> _optimizeJpeg(List<int> bytes) async {
    // Simple JPEG optimization: remove EXIF data
    // This is a basic implementation - in production you'd use a proper image library
    
    final optimized = <int>[];
    int i = 0;
    
    // Copy JPEG header
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      optimized.addAll([0xFF, 0xD8]);
      i = 2;
      
      while (i < bytes.length - 1) {
        if (bytes[i] == 0xFF) {
          final marker = bytes[i + 1];
          
          // Skip EXIF data (APP1 marker)
          if (marker == 0xE1) {
            // Skip this segment
            if (i + 3 < bytes.length) {
              final segmentLength = (bytes[i + 2] << 8) | bytes[i + 3];
              i += 2 + segmentLength;
              continue;
            }
          }
          
          // Copy other segments
          optimized.add(bytes[i]);
          i++;
        } else {
          optimized.add(bytes[i]);
          i++;
        }
      }
      
      // Add last byte if exists
      if (i < bytes.length) {
        optimized.add(bytes[i]);
      }
    } else {
      // Not a valid JPEG, return original
      return bytes;
    }
    
    return optimized.isEmpty ? bytes : optimized;
  }

  /// Optimizes PNG images by removing unnecessary chunks
  Future<List<int>> _optimizePng(List<int> bytes) async {
    // Simple PNG optimization: remove text chunks and other metadata
    // This is a basic implementation - in production you'd use a proper image library
    
    if (bytes.length < 8) return bytes;
    
    // Verify PNG signature
    final pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    for (int i = 0; i < 8; i++) {
      if (bytes[i] != pngSignature[i]) {
        return bytes; // Not a valid PNG
      }
    }
    
    final optimized = <int>[];
    optimized.addAll(pngSignature); // Copy PNG signature
    
    int i = 8;
    while (i < bytes.length - 8) {
      // Read chunk length
      if (i + 4 >= bytes.length) break;
      final length = (bytes[i] << 24) | (bytes[i + 1] << 16) | 
                    (bytes[i + 2] << 8) | bytes[i + 3];
      
      // Read chunk type
      if (i + 8 >= bytes.length) break;
      final chunkType = String.fromCharCodes(bytes.sublist(i + 4, i + 8));
      
      // Keep essential chunks, skip metadata chunks
      final keepChunk = _shouldKeepPngChunk(chunkType);
      
      if (keepChunk) {
        // Copy entire chunk (length + type + data + CRC)
        final chunkEnd = i + 12 + length;
        if (chunkEnd <= bytes.length) {
          optimized.addAll(bytes.sublist(i, chunkEnd));
        }
      }
      
      i += 12 + length; // Move to next chunk
    }
    
    return optimized.isEmpty ? bytes : optimized;
  }

  /// Determines which PNG chunks to keep
  bool _shouldKeepPngChunk(String chunkType) {
    // Keep essential chunks
    const essentialChunks = {
      'IHDR', // Image header
      'PLTE', // Palette
      'IDAT', // Image data
      'IEND', // Image end
      'tRNS', // Transparency
    };
    
    // Skip metadata chunks
    const metadataChunks = {
      'tEXt', // Text
      'zTXt', // Compressed text
      'iTXt', // International text
      'tIME', // Modification time
      'pHYs', // Physical pixel dimensions
      'sBIT', // Significant bits
      'gAMA', // Gamma
      'cHRM', // Chromaticity
      'sRGB', // Standard RGB color space
      'iCCP', // ICC color profile
    };
    
    return essentialChunks.contains(chunkType) && !metadataChunks.contains(chunkType);
  }

  /// Basic GIF optimization
  Future<List<int>> _optimizeGif(List<int> bytes) async {
    // For GIF, we mainly just return the original bytes
    // Real optimization would involve palette optimization and frame deduplication
    return bytes;
  }
}