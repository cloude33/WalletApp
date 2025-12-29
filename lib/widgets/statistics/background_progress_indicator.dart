import 'package:flutter/material.dart';
class BackgroundProgressIndicator extends StatelessWidget {
  final double? progress;
  final String? message;
  final bool isOverlay;
  final Color? backgroundColor;
  final Color? progressColor;

  const BackgroundProgressIndicator({
    super.key,
    this.progress,
    this.message,
    this.isOverlay = false,
    this.backgroundColor,
    this.progressColor,
  });
  factory BackgroundProgressIndicator.overlay({
    double? progress,
    String? message,
    Color? backgroundColor,
    Color? progressColor,
  }) {
    return BackgroundProgressIndicator(
      progress: progress,
      message: message,
      isOverlay: true,
      backgroundColor: backgroundColor,
      progressColor: progressColor,
    );
  }
  factory BackgroundProgressIndicator.inline({
    double? progress,
    String? message,
    Color? progressColor,
  }) {
    return BackgroundProgressIndicator(
      progress: progress,
      message: message,
      isOverlay: false,
      progressColor: progressColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveProgressColor = progressColor ?? theme.primaryColor;
    final effectiveBackgroundColor =
        backgroundColor ?? Colors.black.withValues(alpha: 0.5);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: progress != null
              ? CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    effectiveProgressColor,
                  ),
                )
              : CircularProgressIndicator(
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    effectiveProgressColor,
                  ),
                ),
        ),
        if (progress != null) ...[
          const SizedBox(height: 16),
          Text(
            '${(progress! * 100).toInt()}%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isOverlay ? Colors.white : theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isOverlay
                  ? Colors.white.withValues(alpha: 0.9)
                  : theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ],
    );

    if (isOverlay) {
      return Container(
        color: effectiveBackgroundColor,
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: content,
            ),
          ),
        ),
      );
    } else {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      );
    }
  }
}
mixin BackgroundProgressMixin<T extends StatefulWidget> on State<T> {
  Future<R> showBackgroundProgress<R>(
    BuildContext context, {
    required Future<R> Function() computation,
    String? message,
    void Function(double)? onProgress,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: BackgroundProgressIndicator.overlay(
          message: message ?? 'İşleniyor...',
        ),
      ),
    );

    try {
      final result = await computation();
      if (mounted && context.mounted) {
        Navigator.of(context).pop();
      }

      return result;
    } catch (e) {
      if (mounted && context.mounted) {
        Navigator.of(context).pop();
      }
      rethrow;
    }
  }
  Future<R> showBackgroundProgressWithTracking<R>(
    BuildContext context, {
    required Future<R> Function(void Function(double)) computation,
    String? message,
  }) async {
    double progress = 0.0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return PopScope(
            canPop: false,
            child: BackgroundProgressIndicator.overlay(
              progress: progress,
              message: message ?? 'İşleniyor...',
            ),
          );
        },
      ),
    );

    try {
      final result = await computation((p) {
        if (mounted) {
          setState(() {
            progress = p;
          });
        }
      });
      if (mounted && context.mounted) {
        Navigator.of(context).pop();
      }

      return result;
    } catch (e) {
      if (mounted && context.mounted) {
        Navigator.of(context).pop();
      }
      rethrow;
    }
  }
}
class BackgroundProgressContainer extends StatelessWidget {
  final bool isLoading;
  final double? progress;
  final String? message;
  final Widget child;

  const BackgroundProgressContainer({
    super.key,
    required this.isLoading,
    this.progress,
    this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: BackgroundProgressIndicator.inline(
                progress: progress,
                message: message,
              ),
            ),
          ),
      ],
    );
  }
}
