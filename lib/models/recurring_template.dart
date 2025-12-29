import 'package:hive/hive.dart';
import 'recurrence_frequency.dart';

part 'recurring_template.g.dart';

@HiveType(typeId: 9)
class RecurringTemplate extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String category;

  @HiveField(3)
  late RecurrenceFrequency defaultFrequency;

  @HiveField(4)
  late bool isIncome;

  @HiveField(5)
  String? icon;

  @HiveField(6)
  late bool isCustom;

  RecurringTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultFrequency,
    required this.isIncome,
    this.icon,
    this.isCustom = false,
  });

  static List<RecurringTemplate> getDefaultTemplates() {
    return [
      RecurringTemplate(
        id: 'rent',
        name: 'Kira',
        category: 'Konut',
        defaultFrequency: RecurrenceFrequency.monthly,
        isIncome: false,
        icon: '🏠',
      ),
      RecurringTemplate(
        id: 'electricity',
        name: 'Elektrik',
        category: 'Faturalar',
        defaultFrequency: RecurrenceFrequency.monthly,
        isIncome: false,
        icon: '⚡',
      ),
      RecurringTemplate(
        id: 'water',
        name: 'Su',
        category: 'Faturalar',
        defaultFrequency: RecurrenceFrequency.monthly,
        isIncome: false,
        icon: '💧',
      ),
      RecurringTemplate(
        id: 'internet',
        name: 'İnternet',
        category: 'Faturalar',
        defaultFrequency: RecurrenceFrequency.monthly,
        isIncome: false,
        icon: '🌐',
      ),
      RecurringTemplate(
        id: 'phone',
        name: 'Telefon',
        category: 'Faturalar',
        defaultFrequency: RecurrenceFrequency.monthly,
        isIncome: false,
        icon: '📱',
      ),
      RecurringTemplate(
        id: 'salary',
        name: 'Maaş',
        category: 'Gelir',
        defaultFrequency: RecurrenceFrequency.monthly,
        isIncome: true,
        icon: '💰',
      ),
      RecurringTemplate(
        id: 'netflix',
        name: 'Netflix',
        category: 'Abonelik',
        defaultFrequency: RecurrenceFrequency.monthly,
        isIncome: false,
        icon: '🎬',
      ),
      RecurringTemplate(
        id: 'spotify',
        name: 'Spotify',
        category: 'Abonelik',
        defaultFrequency: RecurrenceFrequency.monthly,
        isIncome: false,
        icon: '🎵',
      ),
      RecurringTemplate(
        id: 'gym',
        name: 'Spor Salonu',
        category: 'Sağlık',
        defaultFrequency: RecurrenceFrequency.monthly,
        isIncome: false,
        icon: '💪',
      ),
      RecurringTemplate(
        id: 'insurance',
        name: 'Sigorta',
        category: 'Sigorta',
        defaultFrequency: RecurrenceFrequency.monthly,
        isIncome: false,
        icon: '🛡️',
      ),
    ];
  }
}
