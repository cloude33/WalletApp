import 'package:flutter/material.dart';
class PaginatedListView<T> extends StatefulWidget {
  final List<T> items;
  final int itemsPerPage;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? header;
  final Widget? emptyWidget;
  final String loadMoreText;
  final String loadingText;
  final bool showItemCount;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.itemsPerPage = 20,
    this.header,
    this.emptyWidget,
    this.loadMoreText = 'Daha Fazla Yükle',
    this.loadingText = 'Yükleniyor...',
    this.showItemCount = true,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  int _currentPage = 0;
  bool _isLoading = false;
  List<T> _displayedItems = [];

  @override
  void initState() {
    super.initState();
    _loadInitialPage();
  }

  @override
  void didUpdateWidget(PaginatedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _reset();
    }
  }

  void _loadInitialPage() {
    setState(() {
      _currentPage = 0;
      _displayedItems = _getItemsForPage(0);
    });
  }

  void _reset() {
    setState(() {
      _currentPage = 0;
      _displayedItems = _getItemsForPage(0);
      _isLoading = false;
    });
  }

  List<T> _getItemsForPage(int page) {
    final startIndex = 0;
    final endIndex = ((page + 1) * widget.itemsPerPage).clamp(
      0,
      widget.items.length,
    );
    return widget.items.sublist(startIndex, endIndex);
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _currentPage++;
      _displayedItems = _getItemsForPage(_currentPage);
      _isLoading = false;
    });
  }

  bool get _hasMore => _displayedItems.length < widget.items.length;

  String _getPageInfo() {
    if (widget.items.isEmpty) return '0 öğe';

    final showing = _displayedItems.length;
    final total = widget.items.length;

    return '$showing / $total öğe gösteriliyor';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return widget.emptyWidget ??
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('Gösterilecek öğe bulunamadı'),
            ),
          );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.header != null) widget.header!,
          if (widget.showItemCount) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _getPageInfo(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ),
          ],
          ..._displayedItems.asMap().entries.map((entry) {
            return widget.itemBuilder(context, entry.value, entry.key);
          }),
          if (_hasMore) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isLoading
                  ? Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(
                            widget.loadingText,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: _loadMore,
                      icon: const Icon(Icons.expand_more),
                      label: Text(widget.loadMoreText),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
          if (!_hasMore && widget.items.length > widget.itemsPerPage) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Tüm öğeler gösteriliyor',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
class StatisticsPaginatedTable extends StatefulWidget {
  final List<String> headers;
  final List<List<dynamic>> rows;
  final int rowsPerPage;
  final List<int>? columnFlex;
  final Widget Function(BuildContext context, List<dynamic> row, int index)?
  rowBuilder;
  final bool showPageNavigation;

  const StatisticsPaginatedTable({
    super.key,
    required this.headers,
    required this.rows,
    this.rowsPerPage = 10,
    this.columnFlex,
    this.rowBuilder,
    this.showPageNavigation = true,
  });

  @override
  State<StatisticsPaginatedTable> createState() =>
      _StatisticsPaginatedTableState();
}

class _StatisticsPaginatedTableState extends State<StatisticsPaginatedTable> {
  int _currentPage = 0;

  int get _totalPages => (widget.rows.length / widget.rowsPerPage).ceil();

  List<List<dynamic>> get _currentPageRows {
    final startIndex = _currentPage * widget.rowsPerPage;
    final endIndex = (startIndex + widget.rowsPerPage).clamp(
      0,
      widget.rows.length,
    );
    return widget.rows.sublist(startIndex, endIndex);
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Gösterilecek veri bulunamadı'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.grey[100],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: widget.headers.asMap().entries.map((entry) {
              final index = entry.key;
              final header = entry.value;
              final flex =
                  widget.columnFlex != null && index < widget.columnFlex!.length
                  ? widget.columnFlex![index]
                  : 1;

              return Expanded(
                flex: flex,
                child: Text(
                  header,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: index == 0 ? TextAlign.left : TextAlign.right,
                ),
              );
            }).toList(),
          ),
        ),
        ..._currentPageRows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;

          if (widget.rowBuilder != null) {
            return widget.rowBuilder!(context, row, index);
          }

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: index.isEven
                  ? (isDark ? Colors.grey[900] : Colors.white)
                  : (isDark ? Colors.grey[850] : Colors.grey[50]),
            ),
            child: Row(
              children: row.asMap().entries.map((cellEntry) {
                final cellIndex = cellEntry.key;
                final cell = cellEntry.value;
                final flex =
                    widget.columnFlex != null &&
                        cellIndex < widget.columnFlex!.length
                    ? widget.columnFlex![cellIndex]
                    : 1;

                return Expanded(
                  flex: flex,
                  child: Text(
                    cell.toString(),
                    style: theme.textTheme.bodyMedium,
                    textAlign: cellIndex == 0
                        ? TextAlign.left
                        : TextAlign.right,
                  ),
                );
              }).toList(),
            ),
          );
        }),
        if (widget.showPageNavigation && _totalPages > 1) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[100],
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sayfa ${_currentPage + 1} / $_totalPages',
                  style: theme.textTheme.bodySmall,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentPage > 0 ? _previousPage : null,
                      iconSize: 20,
                    ),
                    ...List.generate(_totalPages.clamp(0, 5), (index) {
                      int pageIndex;
                      if (_totalPages <= 5) {
                        pageIndex = index;
                      } else if (_currentPage < 2) {
                        pageIndex = index;
                      } else if (_currentPage > _totalPages - 3) {
                        pageIndex = _totalPages - 5 + index;
                      } else {
                        pageIndex = _currentPage - 2 + index;
                      }

                      return TextButton(
                        onPressed: () => _goToPage(pageIndex),
                        style: TextButton.styleFrom(
                          backgroundColor: pageIndex == _currentPage
                              ? theme.primaryColor.withValues(alpha: 0.2)
                              : null,
                          minimumSize: const Size(36, 36),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          '${pageIndex + 1}',
                          style: TextStyle(
                            fontWeight: pageIndex == _currentPage
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: pageIndex == _currentPage
                                ? theme.primaryColor
                                : null,
                          ),
                        ),
                      );
                    }),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentPage < _totalPages - 1
                          ? _nextPage
                          : null,
                      iconSize: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
