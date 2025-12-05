import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Utility class for optimizing images
class ImageOptimizer {
  /// Maximum width for card images
  static const int maxCardImageWidth = 800;

  /// Maximum height for card images
  static const int maxCardImageHeight = 600;

  /// JPEG quality for compression (0-100)
  static const int jpegQuality = 85;

  /// Optimize image bytes for storage
  /// Resizes and compresses the image to reduce file size
  static Future<Uint8List> optimizeImage(
    Uint8List imageBytes, {
    int? maxWidth,
    int? maxHeight,
    int? quality,
  }) async {
    try {
      // Decode the image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return imageBytes;
      }

      // Calculate new dimensions while maintaining aspect ratio
      final targetWidth = maxWidth ?? maxCardImageWidth;
      final targetHeight = maxHeight ?? maxCardImageHeight;

      img.Image resized;
      if (image.width > targetWidth || image.height > targetHeight) {
        // Calculate aspect ratio
        final aspectRatio = image.width / image.height;

        int newWidth;
        int newHeight;

        if (aspectRatio > 1) {
          // Landscape
          newWidth = targetWidth;
          newHeight = (targetWidth / aspectRatio).round();
        } else {
          // Portrait
          newHeight = targetHeight;
          newWidth = (targetHeight * aspectRatio).round();
        }

        resized = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      } else {
        resized = image;
      }

      // Compress as JPEG
      final compressed = img.encodeJpg(
        resized,
        quality: quality ?? jpegQuality,
      );

      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('Error optimizing image: $e');
      return imageBytes;
    }
  }

  /// Optimize image for card photo
  static Future<Uint8List> optimizeCardImage(Uint8List imageBytes) async {
    return optimizeImage(
      imageBytes,
      maxWidth: maxCardImageWidth,
      maxHeight: maxCardImageHeight,
      quality: jpegQuality,
    );
  }

  /// Create thumbnail from image
  static Future<Uint8List> createThumbnail(
    Uint8List imageBytes, {
    int size = 200,
  }) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return imageBytes;
      }

      // Create square thumbnail
      final thumbnail = img.copyResizeCropSquare(image, size: size);

      // Compress
      final compressed = img.encodeJpg(thumbnail, quality: 80);

      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('Error creating thumbnail: $e');
      return imageBytes;
    }
  }

  /// Get image dimensions without fully decoding
  static Future<Size?> getImageDimensions(Uint8List imageBytes) async {
    try {
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      return Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
    } catch (e) {
      debugPrint('Error getting image dimensions: $e');
      return null;
    }
  }

  /// Calculate file size reduction percentage
  static double calculateReduction(int originalSize, int optimizedSize) {
    if (originalSize == 0) return 0;
    return ((originalSize - optimizedSize) / originalSize) * 100;
  }
}
