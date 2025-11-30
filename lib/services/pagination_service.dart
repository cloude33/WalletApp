/// Generic pagination service for lazy loading large datasets
class PaginationService<T> {
  final int pageSize;
  final Future<List<T>> Function(int page, int pageSize) fetchPage;

  List<T> items = [];
  int currentPage = 0;
  bool hasMore = true;
  bool isLoading = false;
  String? error;

  PaginationService({
    required this.pageSize,
    required this.fetchPage,
  });

  /// Load the next page of data
  Future<void> loadNextPage() async {
    if (isLoading || !hasMore) return;

    isLoading = true;
    error = null;

    try {
      final newItems = await fetchPage(currentPage, pageSize);

      if (newItems.isEmpty) {
        hasMore = false;
      } else {
        items.addAll(newItems);
        currentPage++;
        
        // If we got fewer items than page size, we've reached the end
        if (newItems.length < pageSize) {
          hasMore = false;
        }
      }
    } catch (e) {
      error = e.toString();
      hasMore = true; // Allow retry
    } finally {
      isLoading = false;
    }
  }

  /// Refresh data from the beginning
  Future<void> refresh() async {
    reset();
    await loadNextPage();
  }

  /// Reset pagination state
  void reset() {
    items.clear();
    currentPage = 0;
    hasMore = true;
    isLoading = false;
    error = null;
  }

  /// Get total item count
  int get itemCount => items.length;

  /// Check if we should load more (when scrolled near end)
  bool shouldLoadMore(int index) {
    // Load more when we're 5 items from the end
    return !isLoading && hasMore && index >= items.length - 5;
  }
}
