/// Helper class for pagination of long lists
class PaginationHelper<T> {
  final List<T> _allItems;
  final int itemsPerPage;

  int _currentPage = 0;
  List<T> _currentPageItems = [];

  PaginationHelper({
    required List<T> items,
    this.itemsPerPage = 20,
  }) : _allItems = items {
    _loadPage(0);
  }

  /// Get current page items
  List<T> get currentItems => _currentPageItems;

  /// Get current page number (0-indexed)
  int get currentPage => _currentPage;

  /// Get total number of pages
  int get totalPages => (_allItems.length / itemsPerPage).ceil();

  /// Check if there are more pages
  bool get hasNextPage => _currentPage < totalPages - 1;

  /// Check if there is a previous page
  bool get hasPreviousPage => _currentPage > 0;

  /// Get total number of items
  int get totalItems => _allItems.length;

  /// Load a specific page
  void _loadPage(int page) {
    if (page < 0 || page >= totalPages) {
      return;
    }

    _currentPage = page;
    final startIndex = page * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, _allItems.length);

    _currentPageItems = _allItems.sublist(startIndex, endIndex);
  }

  /// Load next page
  bool loadNextPage() {
    if (!hasNextPage) {
      return false;
    }

    _loadPage(_currentPage + 1);
    return true;
  }

  /// Load previous page
  bool loadPreviousPage() {
    if (!hasPreviousPage) {
      return false;
    }

    _loadPage(_currentPage - 1);
    return true;
  }

  /// Load first page
  void loadFirstPage() {
    _loadPage(0);
  }

  /// Load last page
  void loadLastPage() {
    _loadPage(totalPages - 1);
  }

  /// Jump to specific page
  bool jumpToPage(int page) {
    if (page < 0 || page >= totalPages) {
      return false;
    }

    _loadPage(page);
    return true;
  }

  /// Load more items (for infinite scroll)
  /// Returns the newly loaded items
  List<T> loadMore() {
    if (!hasNextPage) {
      return [];
    }

    final nextPage = _currentPage + 1;
    final startIndex = nextPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, _allItems.length);

    final newItems = _allItems.sublist(startIndex, endIndex);
    _currentPageItems.addAll(newItems);
    _currentPage = nextPage;

    return newItems;
  }

  /// Reset pagination
  void reset() {
    _loadPage(0);
  }

  /// Get page info string (e.g., "1-20 of 100")
  String getPageInfo() {
    if (_allItems.isEmpty) {
      return '0 of 0';
    }

    final startIndex = _currentPage * itemsPerPage + 1;
    final endIndex = (_currentPage * itemsPerPage + _currentPageItems.length);

    return '$startIndex-$endIndex of $totalItems';
  }
}

/// Lazy loading helper for infinite scroll
class LazyLoadHelper<T> {
  final List<T> _allItems;
  final int initialLoadCount;
  final int loadMoreCount;

  List<T> _loadedItems = [];
  int _loadedCount = 0;

  LazyLoadHelper({
    required List<T> items,
    this.initialLoadCount = 20,
    this.loadMoreCount = 10,
  }) : _allItems = items {
    _loadInitial();
  }

  /// Get currently loaded items
  List<T> get loadedItems => _loadedItems;

  /// Check if there are more items to load
  bool get hasMore => _loadedCount < _allItems.length;

  /// Get total number of items
  int get totalItems => _allItems.length;

  /// Get number of loaded items
  int get loadedCount => _loadedCount;

  /// Load initial items
  void _loadInitial() {
    final count = initialLoadCount.clamp(0, _allItems.length);
    _loadedItems = _allItems.sublist(0, count);
    _loadedCount = count;
  }

  /// Load more items
  /// Returns the newly loaded items
  List<T> loadMore() {
    if (!hasMore) {
      return [];
    }

    final startIndex = _loadedCount;
    final endIndex = (startIndex + loadMoreCount).clamp(0, _allItems.length);

    final newItems = _allItems.sublist(startIndex, endIndex);
    _loadedItems.addAll(newItems);
    _loadedCount = endIndex;

    return newItems;
  }

  /// Reset to initial state
  void reset() {
    _loadInitial();
  }

  /// Get loading progress (0.0 to 1.0)
  double get progress {
    if (_allItems.isEmpty) {
      return 1.0;
    }
    return _loadedCount / _allItems.length;
  }
}
