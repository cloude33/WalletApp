import 'package:flutter/material.dart';
class CustomTooltip extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;
  final String? subtitle;
  final IconData? icon;
  final List<TooltipItem>? additionalItems;
  final EdgeInsets? padding;
  final double? borderRadius;

  const CustomTooltip({
    super.key,
    required this.title,
    required this.value,
    this.color,
    this.subtitle,
    this.icon,
    this.additionalItems,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.black87,
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: Colors.white70,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
          if (additionalItems != null && additionalItems!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(
              color: Colors.white24,
              height: 1,
            ),
            const SizedBox(height: 8),
            ...additionalItems!.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.color != null) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        '${item.label}: ',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        item.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
class TooltipItem {
  final String label;
  final String value;
  final Color? color;

  const TooltipItem({
    required this.label,
    required this.value,
    this.color,
  });
}
class AnimatedTooltip extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const AnimatedTooltip({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<AnimatedTooltip> createState() => _AnimatedTooltipState();
}

class _AnimatedTooltipState extends State<AnimatedTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
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
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
