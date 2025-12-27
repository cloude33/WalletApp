import 'package:flutter/material.dart';
class ChartLegend extends StatelessWidget {
  final Map<String, Color> items;
  final Map<String, String>? values;
  final Axis direction;
  final Function(String)? onItemTap;
  final Set<String>? selectedItems;
  final bool showValues;
  final double spacing;
  final double runSpacing;
  final CrossAxisAlignment crossAxisAlignment;

  const ChartLegend({
    super.key,
    required this.items,
    this.values,
    this.direction = Axis.horizontal,
    this.onItemTap,
    this.selectedItems,
    this.showValues = true,
    this.spacing = 16,
    this.runSpacing = 8,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final legendItems = items.entries.map((entry) {
      final isSelected = selectedItems?.contains(entry.key) ?? true;
      final itemValue = showValues && values != null ? values![entry.key] : null;
      return LegendItem(
        label: entry.key,
        color: entry.value,
        value: itemValue,
        onTap: onItemTap != null ? () => onItemTap!(entry.key) : null,
        isSelected: isSelected,
      );
    }).toList();

    if (direction == Axis.horizontal) {
      return Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: legendItems,
      );
    } else {
      return Column(
        crossAxisAlignment: crossAxisAlignment,
        children: legendItems
            .map((item) => Padding(
                  padding: EdgeInsets.only(bottom: runSpacing),
                  child: item,
                ))
            .toList(),
      );
    }
  }
}
class LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final String? value;
  final VoidCallback? onTap;
  final bool isSelected;
  final double indicatorSize;
  final double indicatorRadius;

  const LegendItem({
    super.key,
    required this.label,
    required this.color,
    this.value,
    this.onTap,
    this.isSelected = true,
    this.indicatorSize = 16,
    this.indicatorRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Opacity(
          opacity: isSelected ? 1.0 : 0.4,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: indicatorSize,
                height: indicatorSize,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(indicatorRadius),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: isDark ? Colors.white54 : Colors.black26,
                          width: 1,
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 4),
                Text(
                  value!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
class InteractiveChartLegend extends StatefulWidget {
  final Map<String, Color> items;
  final Map<String, String>? values;
  final Axis direction;
  final Function(Set<String>)? onSelectionChanged;
  final bool allowMultipleSelection;
  final Set<String>? initialSelection;

  const InteractiveChartLegend({
    super.key,
    required this.items,
    this.values,
    this.direction = Axis.horizontal,
    this.onSelectionChanged,
    this.allowMultipleSelection = true,
    this.initialSelection,
  });

  @override
  State<InteractiveChartLegend> createState() =>
      _InteractiveChartLegendState();
}

class _InteractiveChartLegendState extends State<InteractiveChartLegend> {
  late Set<String> selectedItems;

  @override
  void initState() {
    super.initState();
    selectedItems = widget.initialSelection ?? widget.items.keys.toSet();
  }

  void _handleItemTap(String item) {
    setState(() {
      if (widget.allowMultipleSelection) {
        if (selectedItems.contains(item)) {
          if (selectedItems.length > 1) {
            selectedItems.remove(item);
          }
        } else {
          selectedItems.add(item);
        }
      } else {
        selectedItems = {item};
      }
    });

    widget.onSelectionChanged?.call(selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return ChartLegend(
      items: widget.items,
      values: widget.values,
      direction: widget.direction,
      selectedItems: selectedItems,
      onItemTap: _handleItemTap,
    );
  }
}
class CompactLegend extends StatelessWidget {
  final Map<String, Color> items;
  final int maxItemsPerRow;

  const CompactLegend({
    super.key,
    required this.items,
    this.maxItemsPerRow = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: items.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: entry.value,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              entry.key,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
