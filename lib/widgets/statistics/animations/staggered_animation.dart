import 'package:flutter/material.dart';
import 'fade_in_animation.dart';
import 'slide_transition_animation.dart';
import 'scale_animation.dart';

/// Combines multiple animations for a staggered effect
class StaggeredAnimation extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration staggerDelay;
  final bool useFade;
  final bool useSlide;
  final bool useScale;
  final SlideDirection slideDirection;

  const StaggeredAnimation({
    super.key,
    required this.child,
    this.index = 0,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.useFade = true,
    this.useSlide = true,
    this.useScale = false,
    this.slideDirection = SlideDirection.up,
  });

  @override
  Widget build(BuildContext context) {
    final delay = staggerDelay * index;
    Widget result = child;

    if (useScale) {
      result = ScaleAnimation(
        delay: delay,
        child: result,
      );
    }

    if (useSlide) {
      result = SlideTransitionAnimation(
        delay: delay,
        direction: slideDirection,
        offset: 0.3,
        child: result,
      );
    }

    if (useFade) {
      result = FadeInAnimation(
        delay: delay,
        child: result,
      );
    }

    return result;
  }
}

/// List view with staggered animations for children
class StaggeredListView extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;

  const StaggeredListView({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.physics,
    this.padding,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: physics,
      padding: padding,
      shrinkWrap: shrinkWrap,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return StaggeredAnimation(
          index: index,
          staggerDelay: staggerDelay,
          child: children[index],
        );
      },
    );
  }
}
