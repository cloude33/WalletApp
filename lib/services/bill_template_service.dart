import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/bill_template.dart';
class BillTemplateService {
  static const String _storageKey = 'bill_templates';
  final Uuid _uuid = const Uuid();
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
  Future<List<BillTemplate>> getActiveTemplates() async {
    final templates = await getTemplates();
    return templates.where((t) => t.isActive).toList();
  }
  Future<BillTemplate?> getTemplate(String id) async {
    final templates = await getTemplates();
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
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
  Future<void> createTemplate(BillTemplate template) async {
    final templates = await getTemplates();
    templates.add(template);
    await _saveTemplates(templates);
  }
  Future<void> updateTemplate(BillTemplate template) async {
    final templates = await getTemplates();
    final index = templates.indexWhere((t) => t.id == template.id);

    if (index == -1) {
      throw Exception('Şablon bulunamadı');
    }

    templates[index] = template.copyWith(updatedDate: DateTime.now());
    await _saveTemplates(templates);
  }
  Future<void> deleteTemplate(String id) async {
    final templates = await getTemplates();
    templates.removeWhere((t) => t.id == id);
    await _saveTemplates(templates);
  }
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
  Future<void> _saveTemplates(List<BillTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = templates.map((t) => t.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }
  Future<List<BillTemplate>> getTemplatesByCategory(
    BillTemplateCategory category,
  ) async {
    final templates = await getTemplates();
    return templates
        .where((t) => t.category == category && t.isActive)
        .toList();
  }
  Future<void> clearAllTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
  Future<void> addTemplateDirect(BillTemplate template) async {
    final templates = await getTemplates();
    templates.add(template);
    await _saveTemplates(templates);
  }
}
