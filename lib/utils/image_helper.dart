import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Kameradan veya galeriden resim seç
  static Future<String?> pickImage({required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Resmi base64 olarak kaydet
      final bytes = await image.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('Resim seçme hatası: $e');
      return null;
    }
  }

  /// Birden fazla resim seç (sadece galeri)
  static Future<List<String>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      List<String> savedPaths = [];
      for (var image in images) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        savedPaths.add(base64Image);
      }

      return savedPaths;
    } catch (e) {
      debugPrint('Resim seçme hatası: $e');
      return [];
    }
  }

  /// Resmi uygulama dizinine kaydet (eski sistem için)
  static Future<String?> saveImage(String imagePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(imagePath)}';
      final savedImage = File('${appDir.path}/$fileName');

      // Resmi kopyala
      await File(imagePath).copy(savedImage.path);

      return savedImage.path;
    } catch (e) {
      debugPrint('Resim kaydetme hatası: $e');
      return null;
    }
  }

  /// Resmi sil
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

  /// Resim seçme dialog'u göster
  static Future<String?> showImageSourceDialog(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5E5CE6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF5E5CE6),
                  ),
                ),
                title: const Text('Kamera'),
                subtitle: const Text('Fotoğraf çek'),
                onTap: () async {
                  final imagePath = await pickImage(source: ImageSource.camera);
                  if (context.mounted) {
                    Navigator.pop(context, imagePath);
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5E5CE6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF5E5CE6),
                  ),
                ),
                title: const Text('Galeri'),
                subtitle: const Text('Galeriden seç'),
                onTap: () async {
                  final imagePath = await pickImage(source: ImageSource.gallery);
                  if (context.mounted) {
                    Navigator.pop(context, imagePath);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
