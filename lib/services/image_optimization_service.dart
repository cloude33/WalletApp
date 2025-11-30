import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Handles image compression and caching
class ImageOptimizationService {
  static final ImageOptimizationService _instance =
      ImageOptimizationService._internal();
  factory ImageOptimizationService() => _instance;
  ImageOptimizationService._internal();

  final int maxCacheSizeBytes = 100 * 1024 * 1024; // 100MB
  final Map<String, Uint8List> _imageCache = {};
  int _currentCacheSize = 0;

  /// Compress and store an image
  Future<String> compressAndStore(File imageFile) async {
    try {
      // Read image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if too large (max 1920x1920)
      img.Image resized = image;
      if (image.width > 1920 || image.height > 1920) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? 1920 : null,
          height: image.height > image.width ? 1920 : null,
        );
      }

      // Compress as JPEG with 85% quality
      final compressed = img.encodeJpg(resized, quality: 85);

      // Save to app directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = path.join(directory.path, 'images', fileName);

      // Create directory if it doesn't exist
      final imageDir = Directory(path.join(directory.path, 'images'));
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      // Write file
      final file = File(filePath);
      await file.writeAsBytes(compressed);

      debugPrint('Image compressed: ${bytes.length} -> ${compressed.length} bytes');

      return filePath;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      rethrow;
    }
  }

  /// Generate thumbnail for an image
  Future<String> generateThumbnail(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Create 200x200 thumbnail
      final thumbnail = img.copyResize(
        image,
        width: 200,
        height: 200,
        interpolation: img.Interpolation.average,
      );

      // Compress
      final compressed = img.encodeJpg(thumbnail, quality: 80);

      // Save thumbnail
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basenameWithoutExtension(imagePath);
      final thumbnailPath = path.join(
        directory.path,
        'thumbnails',
        '${fileName}_thumb.jpg',
      );

      // Create directory if it doesn't exist
      final thumbDir = Directory(path.join(directory.path, 'thumbnails'));
      if (!await thumbDir.exists()) {
        await thumbDir.create(recursive: true);
      }

      // Write file
      final thumbFile = File(thumbnailPath);
      await thumbFile.writeAsBytes(compressed);

      return thumbnailPath;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      rethrow;
    }
  }

  /// Cache an image in memory
  Future<void> cacheImage(String key, Uint8List data) async {
    // Check if adding this image would exceed cache size
    if (_currentCacheSize + data.length > maxCacheSizeBytes) {
      await _evictOldestImages(data.length);
    }

    _imageCache[key] = data;
    _currentCacheSize += data.length;
  }

  /// Get cached image
  Uint8List? getCachedImage(String key) {
    return _imageCache[key];
  }

  /// Cleanup old images from disk
  Future<void> cleanupOldImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imageDir = Directory(path.join(directory.path, 'images'));
      final thumbDir = Directory(path.join(directory.path, 'thumbnails'));

      // Get all image files
      final imageFiles = <File>[];
      if (await imageDir.exists()) {
        imageFiles.addAll(
          imageDir.listSync().whereType<File>().toList(),
        );
      }
      if (await thumbDir.exists()) {
        imageFiles.addAll(
          thumbDir.listSync().whereType<File>().toList(),
        );
      }

      // Sort by modification time
      imageFiles.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

      // Calculate total size
      int totalSize = 0;
      for (final file in imageFiles) {
        totalSize += file.lengthSync();
      }

      // Remove oldest files if over limit
      while (totalSize > maxCacheSizeBytes && imageFiles.isNotEmpty) {
        final oldestFile = imageFiles.removeLast();
        final fileSize = oldestFile.lengthSync();
        await oldestFile.delete();
        totalSize -= fileSize;
        debugPrint('Deleted old image: ${oldestFile.path}');
      }
    } catch (e) {
      debugPrint('Error cleaning up old images: $e');
    }
  }

  /// Evict oldest images from memory cache
  Future<void> _evictOldestImages(int requiredSpace) async {
    // Simple FIFO eviction
    while (_currentCacheSize + requiredSpace > maxCacheSizeBytes &&
        _imageCache.isNotEmpty) {
      final firstKey = _imageCache.keys.first;
      final size = _imageCache[firstKey]!.length;
      _imageCache.remove(firstKey);
      _currentCacheSize -= size;
    }
  }

  /// Clear memory cache
  void clearCache() {
    _imageCache.clear();
    _currentCacheSize = 0;
  }

  /// Get cache statistics
  ImageCacheStats getStats() {
    return ImageCacheStats(
      cachedImages: _imageCache.length,
      totalSizeBytes: _currentCacheSize,
      maxSizeBytes: maxCacheSizeBytes,
    );
  }
}

/// Image cache statistics
class ImageCacheStats {
  final int cachedImages;
  final int totalSizeBytes;
  final int maxSizeBytes;

  ImageCacheStats({
    required this.cachedImages,
    required this.totalSizeBytes,
    required this.maxSizeBytes,
  });

  String get totalSizeMB => (totalSizeBytes / (1024 * 1024)).toStringAsFixed(2);
  String get maxSizeMB => (maxSizeBytes / (1024 * 1024)).toStringAsFixed(2);
  int get utilizationPercent => ((totalSizeBytes / maxSizeBytes) * 100).toInt();
}
