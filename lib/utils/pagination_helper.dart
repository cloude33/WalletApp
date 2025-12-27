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
  List<T> get currentItems => _currentPageItems;
  int get currentPage => _currentPage;
  int get totalPages => (_allItems.length / itemsPerPage).ceil();
  bool get hasNextPage => _currentPage < totalPages - 1;
  bool get hasPreviousPage => _currentPage > 0;
  int get totalItems => _allItems.length;
  void _loadPage(int page) {
    if (page < 0 || page >= totalPages) {
      return;
    }

    _currentPage = page;
    final startIndex = page * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, _allItems.length);

    _currentPageItems = _allItems.sublist(startIndex, endIndex);
  }
  bool loadNextPage() {
    if (!hasNextPage) {
      return false;
    }

    _loadPage(_currentPage + 1);
    return true;
  }
  bool loadPreviousPage() {
    if (!hasPreviousPage) {
      return false;
    }

    _loadPage(_currentPage - 1);
    return true;
  }
  void loadFirstPage() {
    _loadPage(0);
  }
  void loadLastPage() {
    _loadPage(totalPages - 1);
  }
  bool jumpToPage(int page) {
    if (page < 0 || page >= totalPages) {
      return false;
    }

    _loadPage(page);
    return true;
  }
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
  void reset() {
    _loadPage(0);
  }
  String getPageInfo() {
    if (_allItems.isEmpty) {
      return '0 of 0';
    }

    final startIndex = _currentPage * itemsPerPage + 1;
    final endIndex = (_currentPage * itemsPerPage + _currentPageItems.length);

    return '$startIndex-$endIndex of $totalItems';
  }
}
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
  List<T> get loadedItems => _loadedItems;
  bool get hasMore => _loadedCount < _allItems.length;
  int get totalItems => _allItems.length;
  int get loadedCount => _loadedCount;
  void _loadInitial() {
    final count = initialLoadCount.clamp(0, _allItems.length);
    _loadedItems = _allItems.sublist(0, count);
    _loadedCount = count;
  }
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
  void reset() {
    _loadInitial();
  }
  double get progress {
    if (_allItems.isEmpty) {
      return 1.0;
    }
    return _loadedCount / _allItems.length;
  }
}
