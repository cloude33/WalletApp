import 'package:flutter/material.dart';
import '../../utils/debounce_throttle.dart';
class StatisticsSearchBar extends StatefulWidget {
  final String searchQuery;
  final Function(String) onSearchChanged;
  final VoidCallback? onClear;
  final String hintText;
  final int debounceMilliseconds;

  const StatisticsSearchBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    this.onClear,
    this.hintText = 'İşlem veya kategori ara...',
    this.debounceMilliseconds = 300,
  });

  @override
  State<StatisticsSearchBar> createState() => _StatisticsSearchBarState();
}

class _StatisticsSearchBarState extends State<StatisticsSearchBar> {
  late TextEditingController _controller;
  late Debouncer _debouncer;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
    _debouncer = Debouncer(
      delay: Duration(milliseconds: widget.debounceMilliseconds),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StatisticsSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery &&
        widget.searchQuery != _controller.text) {
      _controller.text = widget.searchQuery;
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _isSearching = true;
    });
    _debouncer.call(() {
      widget.onSearchChanged(value);
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  void _clearSearch() {
    _controller.clear();
    _debouncer.cancel();
    widget.onSearchChanged('');
    if (widget.onClear != null) {
      widget.onClear!();
    }
    setState(() {
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      child: TextField(
        controller: _controller,
        onChanged: _onSearchChanged,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[500] : Colors.grey[400],
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            size: 22,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSearching)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? Colors.grey[400]! : Colors.grey[600]!,
                            ),
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: _clearSearch,
                      tooltip: 'Aramayı Temizle',
                    ),
                  ],
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF00BFA5),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
