import 'package:flutter/material.dart';
import '../utils/category_icons.dart';

class IconPickerDialog extends StatefulWidget {
  final IconData? initialIcon;
  final Color selectedColor;

  const IconPickerDialog({
    super.key,
    this.initialIcon,
    required this.selectedColor,
  });

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  IconData? _selectedIcon;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.initialIcon;
    _tabController = TabController(
      length: CategoryIcons.categorizedIcons.length + 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<IconData> _getFilteredIcons(List<IconData> icons) {
    if (_searchQuery.isEmpty) return icons;
    // For simplicity, we'll just return all icons when searching
    // In a real app, you might want to add icon names/tags
    return icons;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'İkon Seç',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'İkon ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
            const SizedBox(height: 16),
            
            // Tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: widget.selectedColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: widget.selectedColor,
              tabs: [
                const Tab(text: 'Tümü'),
                ...CategoryIcons.categorizedIcons.keys.map((category) => Tab(text: category)),
              ],
            ),
            const SizedBox(height: 16),
            
            // Icon grid
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIconGrid(CategoryIcons.allIcons),
                  ...CategoryIcons.categorizedIcons.values.map((icons) => _buildIconGrid(icons)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedIcon != null
                      ? () => Navigator.pop(context, _selectedIcon)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.selectedColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Seç'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconGrid(List<IconData> icons) {
    final filteredIcons = _getFilteredIcons(icons);
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: filteredIcons.length,
      itemBuilder: (context, index) {
        final icon = filteredIcons[index];
        final isSelected = _selectedIcon == icon;
        
        return GestureDetector(
          onTap: () => setState(() => _selectedIcon = icon),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? widget.selectedColor : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? widget.selectedColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}
