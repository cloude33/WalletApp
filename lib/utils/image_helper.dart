import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'image_optimizer.dart';

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();
  static Future<String?> pickImage({
    required ImageSource source,
    bool optimize = true,
    bool enableCrop = true,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) {
        debugPrint('Resim seçilmedi');
        return null;
      }

      String imagePath = image.path;
      debugPrint('Resim seçildi: $imagePath');
      if (enableCrop) {
        try {
          final croppedFile = await _cropImage(imagePath);
          if (croppedFile != null) {
            imagePath = croppedFile.path;
            debugPrint('Resim kırpıldı: $imagePath');
          } else {
            debugPrint('Resim kırpma iptal edildi, orijinal resim kullanılacak');
          }
        } catch (e) {
          debugPrint('Resim kırpma hatası, orijinal resim kullanılacak: $e');
        }
      }
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('Resim dosyası bulunamadı: $imagePath');
        return null;
      }
      Uint8List bytes = await file.readAsBytes();
      debugPrint('Resim okundu: ${bytes.length} bytes');
      if (optimize) {
        try {
          final originalSize = bytes.length;
          bytes = await ImageOptimizer.optimizeImage(bytes);
          final optimizedSize = bytes.length;

          final reduction = ImageOptimizer.calculateReduction(
            originalSize,
            optimizedSize,
          );
          debugPrint(
            'Image optimized: ${(originalSize / 1024).toStringAsFixed(1)}KB → '
            '${(optimizedSize / 1024).toStringAsFixed(1)}KB '
            '(${reduction.toStringAsFixed(1)}% reduction)',
          );
        } catch (e) {
          debugPrint('Resim optimizasyon hatası, orijinal resim kullanılacak: $e');
        }
      }
      final base64String = base64Encode(bytes);
      debugPrint('Resim base64\'e çevrildi: ${base64String.length} karakterler');
      return base64String;
    } catch (e, stackTrace) {
      debugPrint('Resim seçme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
  static Future<CroppedFile?> _cropImage(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        compressQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Resmi Kırp',
            toolbarColor: const Color(0xFF5E5CE6),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: false,
            hideBottomControls: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.original,
            ],
          ),
          IOSUiSettings(
            title: 'Resmi Kırp',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.original,
            ],
          ),
        ],
      );
      return croppedFile;
    } catch (e) {
      debugPrint('Resim kırpma hatası: $e');
      return null;
    }
  }
  static Future<List<String>> pickMultipleImages({
    bool optimize = true,
    bool enableCrop = true,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      List<String> savedPaths = [];
      for (var image in images) {
        String imagePath = image.path;
        if (enableCrop) {
          final croppedFile = await _cropImage(imagePath);
          if (croppedFile != null) {
            imagePath = croppedFile.path;
          }
        }
        Uint8List bytes = await File(imagePath).readAsBytes();
        if (optimize) {
          final originalSize = bytes.length;
          bytes = await ImageOptimizer.optimizeImage(bytes);
          final optimizedSize = bytes.length;

          final reduction = ImageOptimizer.calculateReduction(
            originalSize,
            optimizedSize,
          );
          debugPrint(
            'Image optimized: ${(originalSize / 1024).toStringAsFixed(1)}KB → '
            '${(optimizedSize / 1024).toStringAsFixed(1)}KB '
            '(${reduction.toStringAsFixed(1)}% reduction)',
          );
        }

        final base64Image = base64Encode(bytes);
        savedPaths.add(base64Image);
      }

      return savedPaths;
    } catch (e) {
      debugPrint('Resim seçme hatası: $e');
      return [];
    }
  }
  static Future<String?> saveImage(String imagePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(imagePath)}';
      final savedImage = File('${appDir.path}/$fileName');
      await File(imagePath).copy(savedImage.path);

      return savedImage.path;
    } catch (e) {
      debugPrint('Resim kaydetme hatası: $e');
      return null;
    }
  }
  static Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Resim silme hatası: $e');
      return false;
    }
  }
  static Future<String?> showImageSourceDialog(BuildContext context) async {
    try {
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Fotoğraf Ekle',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5E5CE6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt, color: Color(0xFF5E5CE6)),
                  ),
                  title: const Text('Kamera'),
                  subtitle: const Text('Fotoğraf çek ve kırp'),
                  onTap: () {
                    Navigator.pop(context, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5E5CE6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: Color(0xFF5E5CE6),
                    ),
                  ),
                  title: const Text('Galeri'),
                  subtitle: const Text('Galeriden seç ve kırp'),
                  onTap: () {
                    Navigator.pop(context, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        ),
      );

      if (source == null) return null;
      await Future.delayed(const Duration(milliseconds: 300));
      return await pickImage(
        source: source,
        enableCrop: true,
      );
    } catch (e) {
      debugPrint('Dialog gösterme hatası: $e');
      return null;
    }
  }
}
