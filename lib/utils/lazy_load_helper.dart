import 'package:flutter/material.dart';
class LazyLoadHelper {
  static bool isWidgetVisible({
    required BuildContext context,
    required GlobalKey key,
    double threshold = 0.0,
  }) {
    final RenderObject? renderObject = key.currentContext?.findRenderObject();
    if (renderObject == null || !renderObject.attached) {
      return false;
    }

    final RenderBox renderBox = renderObject as RenderBox;
    final Size size = renderBox.size;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size viewportSize = MediaQuery.of(context).size;
    final bool isVisible = position.dy + size.height >= -threshold &&
        position.dy <= viewportSize.height + threshold;

    return isVisible;
  }
  static double getVisibilityPercentage({
    required BuildContext context,
    required GlobalKey key,
  }) {
    final RenderObject? renderObject = key.currentContext?.findRenderObject();
    if (renderObject == null || !renderObject.attached) {
      return 0.0;
    }

    final RenderBox renderBox = renderObject as RenderBox;
    final Size size = renderBox.size;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size viewportSize = MediaQuery.of(context).size;
    final double top = position.dy;
    final double bottom = position.dy + size.height;
    final double viewportTop = 0.0;
    final double viewportBottom = viewportSize.height;

    if (bottom < viewportTop || top > viewportBottom) {
      return 0.0;
    }

    final double visibleTop = top < viewportTop ? viewportTop : top;
    final double visibleBottom = bottom > viewportBottom ? viewportBottom : bottom;
    final double visibleHeight = visibleBottom - visibleTop;

    return (visibleHeight / size.height).clamp(0.0, 1.0);
  }
}
class LazyLoadController extends ChangeNotifier {
  final Set<int> _loadedIndices = {};
  final int preloadThreshold;
  final int maxLoadedItems;

  LazyLoadController({
    this.preloadThreshold = 2,
    this.maxLoadedItems = 50,
  });
  bool isLoaded(int index) => _loadedIndices.contains(index);
  Set<int> get loadedIndices => Set.unmodifiable(_loadedIndices);
  void loadItem(int index) {
    if (!_loadedIndices.contains(index)) {
      _loadedIndices.add(index);
      if (_loadedIndices.length > maxLoadedItems) {
        _unloadFarthestItems(index);
      }
      
      notifyListeners();
    }
  }
  void loadItems(List<int> indices) {
    bool changed = false;
    for (final index in indices) {
      if (!_loadedIndices.contains(index)) {
        _loadedIndices.add(index);
        changed = true;
      }
    }
    if (_loadedIndices.length > maxLoadedItems) {
      final middleIndex = indices.isNotEmpty ? indices[indices.length ~/ 2] : 0;
      _unloadFarthestItems(middleIndex);
    }
    
    if (changed) {
      notifyListeners();
    }
  }
  void unloadItem(int index) {
    if (_loadedIndices.remove(index)) {
      notifyListeners();
    }
  }
  void _unloadFarthestItems(int currentIndex) {
    if (_loadedIndices.length <= maxLoadedItems) {
      return;
    }
    final sortedIndices = _loadedIndices.toList()
      ..sort((a, b) {
        final distA = (a - currentIndex).abs();
        final distB = (b - currentIndex).abs();
        return distB.compareTo(distA);
      });
    final itemsToRemove = _loadedIndices.length - maxLoadedItems;
    for (int i = 0; i < itemsToRemove; i++) {
      _loadedIndices.remove(sortedIndices[i]);
    }
  }
  void clear() {
    if (_loadedIndices.isNotEmpty) {
      _loadedIndices.clear();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _loadedIndices.clear();
    super.dispose();
  }
}
class LazyLoadScrollListener {
  final ScrollController scrollController;
  final LazyLoadController lazyLoadController;
  final int totalItems;
  final double preloadOffset;

  LazyLoadScrollListener({
    required this.scrollController,
    required this.lazyLoadController,
    required this.totalItems,
    this.preloadOffset = 200.0,
  }) {
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;

    final scrollPosition = scrollController.position;
    final viewportHeight = scrollPosition.viewportDimension;
    final scrollOffset = scrollPosition.pixels;
    final maxScroll = scrollPosition.maxScrollExtent;
    final visibleStart = scrollOffset - preloadOffset;
    final visibleEnd = scrollOffset + viewportHeight + preloadOffset;
    final estimatedItemHeight = maxScroll / totalItems;
    final startIndex = (visibleStart / estimatedItemHeight).floor().clamp(0, totalItems - 1);
    final endIndex = (visibleEnd / estimatedItemHeight).ceil().clamp(0, totalItems - 1);
    final indicesToLoad = <int>[];
    for (int i = startIndex; i <= endIndex; i++) {
      if (!lazyLoadController.isLoaded(i)) {
        indicesToLoad.add(i);
      }
    }

    if (indicesToLoad.isNotEmpty) {
      lazyLoadController.loadItems(indicesToLoad);
    }
  }

  void dispose() {
    scrollController.removeListener(_onScroll);
  }
}
class LazyLoadWidget extends StatefulWidget {
  final Widget child;
  final Widget placeholder;
  final double threshold;
  final VoidCallback? onLoad;
  final VoidCallback? onUnload;

  const LazyLoadWidget({
    super.key,
    required this.child,
    this.placeholder = const SizedBox.shrink(),
    this.threshold = 200.0,
    this.onLoad,
    this.onUnload,
  });

  @override
  State<LazyLoadWidget> createState() => _LazyLoadWidgetState();
}

class _LazyLoadWidgetState extends State<LazyLoadWidget> {
  final GlobalKey _key = GlobalKey();
  bool _isLoaded = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  @override
  void dispose() {
    if (_isLoaded) {
      widget.onUnload?.call();
    }
    super.dispose();
  }

  void _checkVisibility() {
    if (!mounted) return;

    final isVisible = LazyLoadHelper.isWidgetVisible(
      context: context,
      key: _key,
      threshold: widget.threshold,
    );

    if (isVisible != _isVisible) {
      setState(() {
        _isVisible = isVisible;
        if (isVisible && !_isLoaded) {
          _isLoaded = true;
          widget.onLoad?.call();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _checkVisibility();
        return false;
      },
      child: Container(
        key: _key,
        child: _isLoaded ? widget.child : widget.placeholder,
      ),
    );
  }
}
class LazyLoadListView extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Widget Function(BuildContext, int)? placeholderBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final double preloadOffset;
  final int maxLoadedItems;
  final Axis scrollDirection;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const LazyLoadListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.placeholderBuilder,
    this.controller,
    this.padding,
    this.preloadOffset = 200.0,
    this.maxLoadedItems = 50,
    this.scrollDirection = Axis.vertical,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<LazyLoadListView> createState() => _LazyLoadListViewState();
}

class _LazyLoadListViewState extends State<LazyLoadListView> {
  late ScrollController _scrollController;
  late LazyLoadController _lazyLoadController;
  late LazyLoadScrollListener _scrollListener;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _lazyLoadController = LazyLoadController(
      maxLoadedItems: widget.maxLoadedItems,
    );
    _scrollListener = LazyLoadScrollListener(
      scrollController: _scrollController,
      lazyLoadController: _lazyLoadController,
      totalItems: widget.itemCount,
      preloadOffset: widget.preloadOffset,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialItems();
    });
  }

  @override
  void dispose() {
    _scrollListener.dispose();
    _lazyLoadController.dispose();
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _loadInitialItems() {
    final initialLoadCount = (widget.maxLoadedItems * 0.3).ceil();
    _lazyLoadController.loadItems(
      List.generate(
        initialLoadCount.clamp(0, widget.itemCount),
        (index) => index,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _lazyLoadController,
      builder: (context, child) {
        return ListView.builder(
          controller: _scrollController,
          padding: widget.padding,
          itemCount: widget.itemCount,
          scrollDirection: widget.scrollDirection,
          shrinkWrap: widget.shrinkWrap,
          physics: widget.physics,
          itemBuilder: (context, index) {
            final isLoaded = _lazyLoadController.isLoaded(index);
            
            if (isLoaded) {
              return widget.itemBuilder(context, index);
            } else {
              return widget.placeholderBuilder?.call(context, index) ??
                  const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            }
          },
        );
      },
    );
  }
}
class VisibilityDetector extends StatefulWidget {
  final Widget child;
  final Function(bool isVisible)? onVisibilityChanged;
  final Function(double percentage)? onVisibilityPercentageChanged;
  final double threshold;

  const VisibilityDetector({
    super.key,
    required this.child,
    this.onVisibilityChanged,
    this.onVisibilityPercentageChanged,
    this.threshold = 0.0,
  });

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  final GlobalKey _key = GlobalKey();
  bool _wasVisible = false;
  double _lastPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    if (!mounted) return;

    final isVisible = LazyLoadHelper.isWidgetVisible(
      context: context,
      key: _key,
      threshold: widget.threshold,
    );

    if (isVisible != _wasVisible) {
      _wasVisible = isVisible;
      widget.onVisibilityChanged?.call(isVisible);
    }

    if (widget.onVisibilityPercentageChanged != null) {
      final percentage = LazyLoadHelper.getVisibilityPercentage(
        context: context,
        key: _key,
      );

      if ((percentage - _lastPercentage).abs() > 0.05) {
        _lastPercentage = percentage;
        widget.onVisibilityPercentageChanged?.call(percentage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _checkVisibility();
        return false;
      },
      child: Container(
        key: _key,
        child: widget.child,
      ),
    );
  }
}
