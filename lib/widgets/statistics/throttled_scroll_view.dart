import 'package:flutter/material.dart';
import '../../utils/debounce_throttle.dart';
class ThrottledScrollView extends StatefulWidget {
  final Widget child;
  final Function(ScrollNotification)? onScroll;
  final int throttleMilliseconds;
  final ScrollController? controller;

  const ThrottledScrollView({
    super.key,
    required this.child,
    this.onScroll,
    this.throttleMilliseconds = 100,
    this.controller,
  });

  @override
  State<ThrottledScrollView> createState() => _ThrottledScrollViewState();
}

class _ThrottledScrollViewState extends State<ThrottledScrollView> {
  late Throttler _scrollThrottler;

  @override
  void initState() {
    super.initState();
    _scrollThrottler = Throttler(
      duration: Duration(milliseconds: widget.throttleMilliseconds),
    );
  }

  @override
  void dispose() {
    _scrollThrottler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (widget.onScroll != null) {
          _scrollThrottler.call(() {
            widget.onScroll!(notification);
          });
        }
        return false;
      },
      child: widget.child,
    );
  }
}
class ThrottledListView extends StatefulWidget {
  final List<Widget> children;
  final Function(ScrollNotification)? onScroll;
  final int throttleMilliseconds;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ThrottledListView({
    super.key,
    required this.children,
    this.onScroll,
    this.throttleMilliseconds = 100,
    this.controller,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  State<ThrottledListView> createState() => _ThrottledListViewState();
}

class _ThrottledListViewState extends State<ThrottledListView> {
  late Throttler _scrollThrottler;

  @override
  void initState() {
    super.initState();
    _scrollThrottler = Throttler(
      duration: Duration(milliseconds: widget.throttleMilliseconds),
    );
  }

  @override
  void dispose() {
    _scrollThrottler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (widget.onScroll != null) {
          _scrollThrottler.call(() {
            widget.onScroll!(notification);
          });
        }
        return false;
      },
      child: ListView(
        controller: widget.controller,
        padding: widget.padding,
        physics: widget.physics,
        shrinkWrap: widget.shrinkWrap,
        children: widget.children,
      ),
    );
  }
}
class ThrottledSingleChildScrollView extends StatefulWidget {
  final Widget child;
  final Function(ScrollNotification)? onScroll;
  final int throttleMilliseconds;
  final ScrollController? controller;
  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  const ThrottledSingleChildScrollView({
    super.key,
    required this.child,
    this.onScroll,
    this.throttleMilliseconds = 100,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.physics,
  });

  @override
  State<ThrottledSingleChildScrollView> createState() =>
      _ThrottledSingleChildScrollViewState();
}

class _ThrottledSingleChildScrollViewState
    extends State<ThrottledSingleChildScrollView> {
  late Throttler _scrollThrottler;

  @override
  void initState() {
    super.initState();
    _scrollThrottler = Throttler(
      duration: Duration(milliseconds: widget.throttleMilliseconds),
    );
  }

  @override
  void dispose() {
    _scrollThrottler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (widget.onScroll != null) {
          _scrollThrottler.call(() {
            widget.onScroll!(notification);
          });
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: widget.controller,
        scrollDirection: widget.scrollDirection,
        padding: widget.padding,
        physics: widget.physics,
        child: widget.child,
      ),
    );
  }
}
mixin ThrottledScrollMixin<T extends StatefulWidget> on State<T> {
  late Throttler scrollThrottler;
  
  void initializeScrollThrottler({int milliseconds = 100}) {
    scrollThrottler = Throttler(
      duration: Duration(milliseconds: milliseconds),
    );
  }
  
  void disposeScrollThrottler() {
    scrollThrottler.dispose();
  }
  
  void handleThrottledScroll(ScrollNotification notification, void Function() action) {
    scrollThrottler.call(action);
  }
}
