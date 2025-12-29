import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/category.dart';
import '../../models/wallet.dart';
class FilterBar extends StatelessWidget {
  final String selectedTimeFilter;
  final List<String> selectedCategories;
  final List<String> selectedWallets;
  final String selectedTransactionType;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final List<Category> availableCategories;
  final List<Wallet> availableWallets;
  final Function(String) onTimeFilterChanged;
  final Function(List<String>) onCategoriesChanged;
  final Function(List<String>) onWalletsChanged;
  final Function(String) onTransactionTypeChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onCustomDateRange;

  const FilterBar({
    super.key,
    required this.selectedTimeFilter,
    required this.selectedCategories,
    required this.selectedWallets,
    required this.selectedTransactionType,
    this.customStartDate,
    this.customEndDate,
    required this.availableCategories,
    required this.availableWallets,
    required this.onTimeFilterChanged,
    required this.onCategoriesChanged,
    required this.onWalletsChanged,
    required this.onTransactionTypeChanged,
    required this.onClearFilters,
    required this.onCustomDateRange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasActiveFilters = selectedCategories.isNotEmpty ||
        selectedWallets.isNotEmpty ||
        selectedTransactionType != 'all';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeFilterRow(context, isDark),
          if (hasActiveFilters || selectedCategories.isNotEmpty || selectedWallets.isNotEmpty)
            _buildAdditionalFiltersRow(context, isDark),
          _buildFilterChips(context, isDark),
        ],
      ),
    );
  }

  Widget _buildTimeFilterRow(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTimeFilterChip(context, 'Günlük', isDark),
            const SizedBox(width: 8),
            _buildTimeFilterChip(context, 'Haftalık', isDark),
            const SizedBox(width: 8),
            _buildTimeFilterChip(context, 'Aylık', isDark),
            const SizedBox(width: 8),
            _buildTimeFilterChip(context, 'Yıllık', isDark),
            const SizedBox(width: 8),
            _buildCustomDateChip(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalFiltersRow(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterButton(
                    context,
                    icon: Icons.category,
                    label: selectedCategories.isEmpty
                        ? 'Kategori'
                        : '${selectedCategories.length} Kategori',
                    isActive: selectedCategories.isNotEmpty,
                    onTap: () => _showCategoryFilter(context),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    context,
                    icon: Icons.account_balance_wallet,
                    label: selectedWallets.isEmpty
                        ? 'Cüzdan'
                        : '${selectedWallets.length} Cüzdan',
                    isActive: selectedWallets.isNotEmpty,
                    onTap: () => _showWalletFilter(context),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    context,
                    icon: Icons.swap_vert,
                    label: _getTransactionTypeLabel(),
                    isActive: selectedTransactionType != 'all',
                    onTap: () => _showTransactionTypeFilter(context),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
          if (selectedCategories.isNotEmpty ||
              selectedWallets.isNotEmpty ||
              selectedTransactionType != 'all')
            Container(
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.clear_all, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Filtreler temizlendi'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: const Color(0xFF00BFA5),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                  onClearFilters();
                },
                tooltip: 'Filtreleri Temizle',
                color: const Color(0xFF00BFA5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, bool isDark) {
    final chips = <Widget>[];
    for (final categoryId in selectedCategories) {
      final category = availableCategories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => Category(
          id: categoryId,
          name: categoryId,
          icon: Icons.category,
          color: const Color(0xFF9E9E9E),
          type: 'expense',
        ),
      );
      chips.add(_buildRemovableChip(
        context,
        label: category.name,
        onRemove: () {
          final updated = List<String>.from(selectedCategories)
            ..remove(categoryId);
          onCategoriesChanged(updated);
        },
        isDark: isDark,
      ));
    }
    for (final walletId in selectedWallets) {
      final wallet = availableWallets.firstWhere(
        (w) => w.id == walletId,
        orElse: () => Wallet(
          id: walletId,
          name: walletId,
          balance: 0,
          type: 'unknown',
          color: '0xFF9E9E9E',
          icon: 'wallet',
          creditLimit: 0.0,
        ),
      );
      chips.add(_buildRemovableChip(
        context,
        label: wallet.name,
        onRemove: () {
          final updated = List<String>.from(selectedWallets)..remove(walletId);
          onWalletsChanged(updated);
        },
        isDark: isDark,
      ));
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips,
      ),
    );
  }

  Widget _buildTimeFilterChip(BuildContext context, String label, bool isDark) {
    final isSelected = selectedTimeFilter == label;
    return GestureDetector(
      onTap: () => onTimeFilterChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00BFA5)
              : (isDark ? const Color(0xFF2C2C2E) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDateChip(BuildContext context, bool isDark) {
    final isSelected = selectedTimeFilter == 'Özel';
    final dateText = customStartDate != null && customEndDate != null
        ? '${DateFormat('dd/MM').format(customStartDate!)} - ${DateFormat('dd/MM').format(customEndDate!)}'
        : 'Özel';

    return GestureDetector(
      onTap: onCustomDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00BFA5)
              : (isDark ? const Color(0xFF2C2C2E) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(width: 6),
            Text(
              dateText,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF00BFA5).withValues(alpha: 0.1)
              : (isDark ? const Color(0xFF2C2C2E) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? const Color(0xFF00BFA5)
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? const Color(0xFF00BFA5)
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive
                    ? const Color(0xFF00BFA5)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemovableChip(
    BuildContext context, {
    required String label,
    required VoidCallback onRemove,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00BFA5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF00BFA5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 14,
              color: Color(0xFF00BFA5),
            ),
          ),
        ],
      ),
    );
  }

  String _getTransactionTypeLabel() {
    switch (selectedTransactionType) {
      case 'income':
        return 'Gelir';
      case 'expense':
        return 'Gider';
      default:
        return 'Tümü';
    }
  }

  void _showCategoryFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryFilterSheet(
        availableCategories: availableCategories,
        selectedCategories: selectedCategories,
        onChanged: onCategoriesChanged,
      ),
    );
  }

  void _showWalletFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WalletFilterSheet(
        availableWallets: availableWallets,
        selectedWallets: selectedWallets,
        onChanged: onWalletsChanged,
      ),
    );
  }

  void _showTransactionTypeFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TransactionTypeFilterSheet(
        selectedType: selectedTransactionType,
        onChanged: onTransactionTypeChanged,
      ),
    );
  }
}
class _CategoryFilterSheet extends StatefulWidget {
  final List<Category> availableCategories;
  final List<String> selectedCategories;
  final Function(List<String>) onChanged;

  const _CategoryFilterSheet({
    required this.availableCategories,
    required this.selectedCategories,
    required this.onChanged,
  });

  @override
  State<_CategoryFilterSheet> createState() => _CategoryFilterSheetState();
}

class _CategoryFilterSheetState extends State<_CategoryFilterSheet> {
  late List<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.selectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Kategori Seç',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _tempSelected.clear();
                    });
                  },
                  child: const Text('Temizle'),
                ),
                TextButton(
                  onPressed: () {
                    widget.onChanged(_tempSelected);
                    Navigator.pop(context);
                  },
                  child: const Text('Uygula'),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.availableCategories.length,
              itemBuilder: (context, index) {
                final category = widget.availableCategories[index];
                final isSelected = _tempSelected.contains(category.id);
                
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _tempSelected.add(category.id);
                      } else {
                        _tempSelected.remove(category.id);
                      }
                    });
                  },
                  title: Text(category.name),
                  secondary: CircleAvatar(
                    backgroundColor: category.color,
                    radius: 16,
                    child: Icon(
                      category.icon,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  activeColor: const Color(0xFF00BFA5),
                );
              },
            ),
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
class _WalletFilterSheet extends StatefulWidget {
  final List<Wallet> availableWallets;
  final List<String> selectedWallets;
  final Function(List<String>) onChanged;

  const _WalletFilterSheet({
    required this.availableWallets,
    required this.selectedWallets,
    required this.onChanged,
  });

  @override
  State<_WalletFilterSheet> createState() => _WalletFilterSheetState();
}

class _WalletFilterSheetState extends State<_WalletFilterSheet> {
  late List<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.selectedWallets);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Cüzdan Seç',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _tempSelected.clear();
                    });
                  },
                  child: const Text('Temizle'),
                ),
                TextButton(
                  onPressed: () {
                    widget.onChanged(_tempSelected);
                    Navigator.pop(context);
                  },
                  child: const Text('Uygula'),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.availableWallets.length,
              itemBuilder: (context, index) {
                final wallet = widget.availableWallets[index];
                final isSelected = _tempSelected.contains(wallet.id);
                
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _tempSelected.add(wallet.id);
                      } else {
                        _tempSelected.remove(wallet.id);
                      }
                    });
                  },
                  title: Text(wallet.name),
                  subtitle: Text(_getWalletTypeLabel(wallet.type)),
                  secondary: CircleAvatar(
                    backgroundColor: Color(int.parse(wallet.color)),
                    radius: 16,
                    child: Icon(
                      _getWalletIcon(wallet.type),
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  activeColor: const Color(0xFF00BFA5),
                );
              },
            ),
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  String _getWalletTypeLabel(String type) {
    switch (type) {
      case 'cash':
        return 'Nakit';
      case 'bank':
        return 'Banka Hesabı';
      case 'credit_card':
        return 'Kredi Kartı';
      default:
        return 'Diğer';
    }
  }

  IconData _getWalletIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.money;
      case 'bank':
        return Icons.account_balance;
      case 'credit_card':
        return Icons.credit_card;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
class _TransactionTypeFilterSheet extends StatelessWidget {
  final String selectedType;
  final Function(String) onChanged;

  const _TransactionTypeFilterSheet({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: const Text(
              'İşlem Tipi Seç',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.all_inclusive, color: Colors.blue),
            title: const Text('Tümü'),
            trailing: selectedType == 'all'
                ? const Icon(Icons.check, color: Color(0xFF00BFA5))
                : null,
            onTap: () {
              onChanged('all');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.trending_up, color: Colors.green),
            title: const Text('Gelir'),
            trailing: selectedType == 'income'
                ? const Icon(Icons.check, color: Color(0xFF00BFA5))
                : null,
            onTap: () {
              onChanged('income');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.trending_down, color: Colors.red),
            title: const Text('Gider'),
            trailing: selectedType == 'expense'
                ? const Icon(Icons.check, color: Color(0xFF00BFA5))
                : null,
            onTap: () {
              onChanged('expense');
              Navigator.pop(context);
            },
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
