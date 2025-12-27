import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
class ImageOptimizer {
  static const int maxCardImageWidth = 800;
  static const int maxCardImageHeight = 600;
  static const int jpegQuality = 85;
  static Future<Uint8List> optimizeImage(
    Uint8List imageBytes, {
    int? maxWidth,
    int? maxHeight,
    int? quality,
  }) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return imageBytes;
      }
      final targetWidth = maxWidth ?? maxCardImageWidth;
      final targetHeight = maxHeight ?? maxCardImageHeight;

      img.Image resized;
      if (image.width > targetWidth || image.height > targetHeight) {
        final aspectRatio = image.width / image.height;

        int newWidth;
        int newHeight;

        if (aspectRatio > 1) {
          newWidth = targetWidth;
          newHeight = (targetWidth / aspectRatio).round();
        } else {
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
  static Future<Uint8List> optimizeCardImage(Uint8List imageBytes) async {
    return optimizeImage(
      imageBytes,
      maxWidth: maxCardImageWidth,
      maxHeight: maxCardImageHeight,
      quality: jpegQuality,
    );
  }
  static Future<Uint8List> createThumbnail(
    Uint8List imageBytes, {
    int size = 200,
  }) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return imageBytes;
      }
      final thumbnail = img.copyResizeCropSquare(image, size: size);
      final compressed = img.encodeJpg(thumbnail, quality: 80);

      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('Error creating thumbnail: $e');
      return imageBytes;
    }
  }
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
  static double calculateReduction(int originalSize, int optimizedSize) {
    if (originalSize == 0) return 0;
    return ((originalSize - optimizedSize) / originalSize) * 100;
  }
}
