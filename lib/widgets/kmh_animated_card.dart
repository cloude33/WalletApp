import 'package:flutter/material.dart';
class KmhAnimatedCard extends StatefulWidget {
  final Widget child;
  final int delay;
  final Duration duration;

  const KmhAnimatedCard({
    super.key,
    required this.child,
    this.delay = 0,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<KmhAnimatedCard> createState() => _KmhAnimatedCardState();
}

class _KmhAnimatedCardState extends State<KmhAnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
class KmhAnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final int baseDelay;

  const KmhAnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.baseDelay = 50,
  });

  @override
  Widget build(BuildContext context) {
    return KmhAnimatedCard(
      delay: baseDelay * index,
      child: child,
    );
  }
}
class KmhScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const KmhScaleButton({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.95,
  });

  @override
  State<KmhScaleButton> createState() => _KmhScaleButtonState();
}

class _KmhScaleButtonState extends State<KmhScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
class KmhAnimatedProgress extends StatefulWidget {
  final double value;
  final Color color;
  final Color backgroundColor;
  final double height;
  final Duration duration;

  const KmhAnimatedProgress({
    super.key,
    required this.value,
    required this.color,
    this.backgroundColor = Colors.grey,
    this.height = 12,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<KmhAnimatedProgress> createState() => _KmhAnimatedProgressState();
}

class _KmhAnimatedProgressState extends State<KmhAnimatedProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(KmhAnimatedProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _animation = Tween<double>(
        begin: _previousValue,
        end: widget.value,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.height / 2),
          child: LinearProgressIndicator(
            value: _animation.value,
            backgroundColor: widget.backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(widget.color),
            minHeight: widget.height,
          ),
        );
      },
    );
  }
}
