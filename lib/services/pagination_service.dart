class PaginationService<T> {
  final int pageSize;
  final Future<List<T>> Function(int page, int pageSize) fetchPage;

  List<T> items = [];
  int currentPage = 0;
  bool hasMore = true;
  bool isLoading = false;
  String? error;

  PaginationService({required this.pageSize, required this.fetchPage});
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
        if (newItems.length < pageSize) {
          hasMore = false;
        }
      }
    } catch (e) {
      error = e.toString();
      hasMore = true;
    } finally {
      isLoading = false;
    }
  }
  Future<void> refresh() async {
    reset();
    await loadNextPage();
  }
  void reset() {
    items.clear();
    currentPage = 0;
    hasMore = true;
    isLoading = false;
    error = null;
  }
  int get itemCount => items.length;
  bool shouldLoadMore(int index) {
    return !isLoading && hasMore && index >= items.length - 5;
  }
}
