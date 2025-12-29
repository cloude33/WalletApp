import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/recurring_template.dart';
import '../models/recurring_transaction.dart';

class RecurringTemplateService {
  static const String _boxName = 'recurring_templates';
  Box<RecurringTemplate>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<RecurringTemplate>(_boxName);
    await _loadDefaultTemplates();
  }

  Box<RecurringTemplate> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('RecurringTemplate box not initialized');
    }
    return _box!;
  }

  Future<void> _loadDefaultTemplates() async {
    if (box.isEmpty) {
      final defaults = RecurringTemplate.getDefaultTemplates();
      for (final template in defaults) {
        await box.put(template.id, template);
      }
    }
  }

  List<RecurringTemplate> getAll() {
    return box.values.toList();
  }

  List<RecurringTemplate> getDefaultTemplates() {
    return box.values.where((t) => !t.isCustom).toList();
  }

  List<RecurringTemplate> getCustomTemplates() {
    return box.values.where((t) => t.isCustom).toList();
  }

  Future<RecurringTemplate> saveCustomTemplate({
    required String name,
    required String category,
    required frequency,
    required bool isIncome,
    String? icon,
  }) async {
    final template = RecurringTemplate(
      id: const Uuid().v4(),
      name: name,
      category: category,
      defaultFrequency: frequency,
      isIncome: isIncome,
      icon: icon,
      isCustom: true,
    );

    await box.put(template.id, template);
    return template;
  }

  Future<void> deleteCustomTemplate(String id) async {
    final template = box.get(id);
    if (template != null && template.isCustom) {
      await box.delete(id);
    }
  }

  RecurringTransaction createFromTemplate({
    required RecurringTemplate template,
    required double amount,
    required DateTime startDate,
    DateTime? endDate,
    int? occurrenceCount,
    String? description,
  }) {
    return RecurringTransaction(
      id: const Uuid().v4(),
      title: template.name,
      amount: amount,
      category: template.category,
      description: description,
      frequency: template.defaultFrequency,
      startDate: startDate,
      endDate: endDate,
      occurrenceCount: occurrenceCount,
      isIncome: template.isIncome,
      createdAt: DateTime.now(),
    );
  }
}
