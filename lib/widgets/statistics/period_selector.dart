import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class PeriodSelector extends StatefulWidget {
  final PeriodType selectedPeriod;
  final Function(PeriodType) onPeriodChanged;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    this.customStartDate,
    this.customEndDate,
  });

  @override
  State<PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<PeriodSelector> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Karşılaştırma Dönemi',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPeriodChip(
                  context,
                  'Bu Ay vs Geçen Ay',
                  PeriodType.thisMonthVsLastMonth,
                  Icons.calendar_month,
                ),
                _buildPeriodChip(
                  context,
                  'Bu Yıl vs Geçen Yıl',
                  PeriodType.thisYearVsLastYear,
                  Icons.calendar_today,
                ),
                _buildPeriodChip(
                  context,
                  'Bu Çeyrek vs Geçen Çeyrek',
                  PeriodType.thisQuarterVsLastQuarter,
                  Icons.date_range,
                ),
                _buildPeriodChip(
                  context,
                  'Son 30 Gün vs Önceki 30 Gün',
                  PeriodType.last30DaysVsPrevious30Days,
                  Icons.today,
                ),
                _buildPeriodChip(
                  context,
                  'Özel Tarih',
                  PeriodType.custom,
                  Icons.edit_calendar,
                ),
              ],
            ),

            if (widget.selectedPeriod == PeriodType.custom) ...[
              const SizedBox(height: 16),
              _buildCustomDateRange(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(
    BuildContext context,
    String label,
    PeriodType type,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isSelected = widget.selectedPeriod == type;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : theme.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          widget.onPeriodChanged(type);
        }
      },
      selectedColor: theme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildCustomDateRange(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Özel Tarih Aralığı',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  context,
                  'Başlangıç',
                  widget.customStartDate,
                  () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateButton(
                  context,
                  'Bitiş',
                  widget.customEndDate,
                  () => _selectDate(context, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(
    BuildContext context,
    String label,
    DateTime? date,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM', 'tr_TR');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? dateFormat.format(date) : 'Seç',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate
        ? widget.customStartDate ?? DateTime.now()
        : widget.customEndDate ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );

    if (picked != null) {
    }
  }
}
enum PeriodType {
  thisMonthVsLastMonth,
  thisYearVsLastYear,
  thisQuarterVsLastQuarter,
  last30DaysVsPrevious30Days,
  custom,
}
class PeriodHelper {
  static PeriodDates getPeriodDates(
    PeriodType type, {
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final now = DateTime.now();

    switch (type) {
      case PeriodType.thisMonthVsLastMonth:
        final thisMonthStart = DateTime(now.year, now.month, 1);
        final thisMonthEnd = DateTime(now.year, now.month + 1, 0);
        final lastMonthStart = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 0);

        return PeriodDates(
          period1Start: lastMonthStart,
          period1End: lastMonthEnd,
          period2Start: thisMonthStart,
          period2End: thisMonthEnd,
          period1Label: _getMonthLabel(lastMonthStart),
          period2Label: _getMonthLabel(thisMonthStart),
        );

      case PeriodType.thisYearVsLastYear:
        final thisYearStart = DateTime(now.year, 1, 1);
        final thisYearEnd = DateTime(now.year, 12, 31);
        final lastYearStart = DateTime(now.year - 1, 1, 1);
        final lastYearEnd = DateTime(now.year - 1, 12, 31);

        return PeriodDates(
          period1Start: lastYearStart,
          period1End: lastYearEnd,
          period2Start: thisYearStart,
          period2End: thisYearEnd,
          period1Label: '${now.year - 1}',
          period2Label: '${now.year}',
        );

      case PeriodType.thisQuarterVsLastQuarter:
        final currentQuarter = ((now.month - 1) ~/ 3) + 1;
        final thisQuarterStart = DateTime(
          now.year,
          (currentQuarter - 1) * 3 + 1,
          1,
        );
        final thisQuarterEnd = DateTime(now.year, currentQuarter * 3 + 1, 0);

        final lastQuarterStart = currentQuarter == 1
            ? DateTime(now.year - 1, 10, 1)
            : DateTime(now.year, (currentQuarter - 2) * 3 + 1, 1);
        final lastQuarterEnd = currentQuarter == 1
            ? DateTime(now.year - 1, 12, 31)
            : DateTime(now.year, (currentQuarter - 1) * 3 + 1, 0);

        return PeriodDates(
          period1Start: lastQuarterStart,
          period1End: lastQuarterEnd,
          period2Start: thisQuarterStart,
          period2End: thisQuarterEnd,
          period1Label: 'Ç${currentQuarter == 1 ? 4 : currentQuarter - 1}',
          period2Label: 'Ç$currentQuarter',
        );

      case PeriodType.last30DaysVsPrevious30Days:
        final period2End = now;
        final period2Start = now.subtract(const Duration(days: 30));
        final period1End = period2Start.subtract(const Duration(days: 1));
        final period1Start = period1End.subtract(const Duration(days: 30));

        return PeriodDates(
          period1Start: period1Start,
          period1End: period1End,
          period2Start: period2Start,
          period2End: period2End,
          period1Label: 'Önceki 30 Gün',
          period2Label: 'Son 30 Gün',
        );

      case PeriodType.custom:
        if (customStart == null || customEnd == null) {
          return getPeriodDates(PeriodType.thisMonthVsLastMonth);
        }

        final duration = customEnd.difference(customStart);
        final period1End = customStart.subtract(const Duration(days: 1));
        final period1Start = period1End.subtract(duration);

        final dateFormat = DateFormat('dd MMM', 'tr_TR');

        return PeriodDates(
          period1Start: period1Start,
          period1End: period1End,
          period2Start: customStart,
          period2End: customEnd,
          period1Label:
              '${dateFormat.format(period1Start)} - ${dateFormat.format(period1End)}',
          period2Label:
              '${dateFormat.format(customStart)} - ${dateFormat.format(customEnd)}',
        );
    }
  }

  static String _getMonthLabel(DateTime date) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
class PeriodDates {
  final DateTime period1Start;
  final DateTime period1End;
  final DateTime period2Start;
  final DateTime period2End;
  final String period1Label;
  final String period2Label;

  PeriodDates({
    required this.period1Start,
    required this.period1End,
    required this.period2Start,
    required this.period2End,
    required this.period1Label,
    required this.period2Label,
  });
}
