import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/bill_template.dart';

/// Fatura şablonlarını yöneten servis
class BillTemplateService {
  static const String _storageKey = 'bill_templates';
  final Uuid _uuid = const Uuid();

  /// Tüm şablonları getir
  Future<List<BillTemplate>> getTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => BillTemplate.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Aktif şablonları getir
  Future<List<BillTemplate>> getActiveTemplates() async {
    final templates = await getTemplates();
    return templates.where((t) => t.isActive).toList();
  }

  /// ID'ye göre şablon getir
  Future<BillTemplate?> getTemplate(String id) async {
    final templates = await getTemplates();
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Yeni şablon ekle
  Future<BillTemplate> addTemplate({
    required String name,
    String? provider,
    required BillTemplateCategory category,
    String? accountNumber,
    String? phoneNumber,
    String? description,
    String? walletId,
  }) async {
    final now = DateTime.now();
    final template = BillTemplate(
      id: _uuid.v4(),
      name: name.trim(),
      provider: provider?.trim(),
      category: category,
      accountNumber: accountNumber?.trim(),
      phoneNumber: phoneNumber?.trim(),
      description: description?.trim(),
      walletId: walletId,
      isActive: true,
      createdDate: now,
      updatedDate: now,
    );

    final templates = await getTemplates();
    templates.add(template);
    await _saveTemplates(templates);

    return template;
  }

  /// Şablon oluştur (BillTemplate nesnesi ile)
  Future<void> createTemplate(BillTemplate template) async {
    final templates = await getTemplates();
    templates.add(template);
    await _saveTemplates(templates);
  }

  /// Şablonu güncelle
  Future<void> updateTemplate(BillTemplate template) async {
    final templates = await getTemplates();
    final index = templates.indexWhere((t) => t.id == template.id);

    if (index == -1) {
      throw Exception('Şablon bulunamadı');
    }

    templates[index] = template.copyWith(updatedDate: DateTime.now());
    await _saveTemplates(templates);
  }

  /// Şablonu sil
  Future<void> deleteTemplate(String id) async {
    final templates = await getTemplates();
    templates.removeWhere((t) => t.id == id);
    await _saveTemplates(templates);
  }

  /// Şablonu aktif/pasif yap
  Future<void> toggleActive(String id) async {
    final templates = await getTemplates();
    final index = templates.indexWhere((t) => t.id == id);

    if (index == -1) {
      throw Exception('Şablon bulunamadı');
    }

    templates[index] = templates[index].copyWith(
      isActive: !templates[index].isActive,
      updatedDate: DateTime.now(),
    );
    await _saveTemplates(templates);
  }

  /// Şablonları kaydet
  Future<void> _saveTemplates(List<BillTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = templates.map((t) => t.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }

  /// Kategoriye göre şablonları getir
  Future<List<BillTemplate>> getTemplatesByCategory(
    BillTemplateCategory category,
  ) async {
    final templates = await getTemplates();
    return templates
        .where((t) => t.category == category && t.isActive)
        .toList();
  }

  /// Tüm şablonları temizle (migration için)
  Future<void> clearAllTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Şablon ekle (migration için - BillTemplate nesnesi ile)
  Future<void> addTemplateDirect(BillTemplate template) async {
    final templates = await getTemplates();
    templates.add(template);
    await _saveTemplates(templates);
  }
}
