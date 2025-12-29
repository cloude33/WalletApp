import 'package:flutter/material.dart';
import 'statistics_error_state.dart';
import 'statistics_empty_state.dart';
import 'statistics_skeleton_loader.dart';

/// Unified state management widget for statistics screens
class StatisticsStateBuilder<T> extends StatelessWidget {
  final AsyncSnapshot<T> snapshot;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final String? loadingMessage;
  final SkeletonType skeletonType;

  const StatisticsStateBuilder({
    super.key,
    required this.snapshot,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.onRetry,
    this.isEmpty,
    this.loadingMessage,
    this.skeletonType = SkeletonType.card,
  });

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (snapshot.connectionState == ConnectionState.waiting) {
      if (loadingBuilder != null) {
        return loadingBuilder!(context);
      }
      return StatisticsSkeletonLoader(
        itemCount: 3,
        type: skeletonType,
      );
    }

    // Error state
    if (snapshot.hasError) {
      if (errorBuilder != null) {
        return errorBuilder!(context, snapshot.error!);
      }
      return StatisticsErrorState(
        message: 'Bir Hata Oluştu',
        details: snapshot.error.toString(),
        onRetry: onRetry,
      );
    }

    // No data
    if (!snapshot.hasData) {
      if (emptyBuilder != null) {
        return emptyBuilder!(context);
      }
      return StatisticsEmptyStates.noTransactions();
    }

    final data = snapshot.data as T;

    // Empty data check
    if (isEmpty != null && isEmpty!(data)) {
      if (emptyBuilder != null) {
        return emptyBuilder!(context);
      }
      return StatisticsEmptyStates.noTransactions();
    }

    // Success state
    return builder(context, data);
  }
}

/// Future-based state builder
class StatisticsFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final String? loadingMessage;
  final SkeletonType skeletonType;

  const StatisticsFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.onRetry,
    this.isEmpty,
    this.loadingMessage,
    this.skeletonType = SkeletonType.card,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        return StatisticsStateBuilder<T>(
          snapshot: snapshot,
          builder: builder,
          loadingBuilder: loadingBuilder,
          errorBuilder: errorBuilder,
          emptyBuilder: emptyBuilder,
          onRetry: onRetry,
          isEmpty: isEmpty,
          loadingMessage: loadingMessage,
          skeletonType: skeletonType,
        );
      },
    );
  }
}

/// Stream-based state builder
class StatisticsStreamBuilder<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final String? loadingMessage;
  final SkeletonType skeletonType;

  const StatisticsStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.onRetry,
    this.isEmpty,
    this.loadingMessage,
    this.skeletonType = SkeletonType.card,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        return StatisticsStateBuilder<T>(
          snapshot: snapshot,
          builder: builder,
          loadingBuilder: loadingBuilder,
          errorBuilder: errorBuilder,
          emptyBuilder: emptyBuilder,
          onRetry: onRetry,
          isEmpty: isEmpty,
          loadingMessage: loadingMessage,
          skeletonType: skeletonType,
        );
      },
    );
  }
}

/// State enum for manual state management
enum DataState {
  initial,
  loading,
  success,
  error,
  empty,
}

/// Manual state builder widget
class StatisticsManualStateBuilder<T> extends StatelessWidget {
  final DataState state;
  final T? data;
  final Object? error;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final VoidCallback? onRetry;
  final String? loadingMessage;
  final SkeletonType skeletonType;

  const StatisticsManualStateBuilder({
    super.key,
    required this.state,
    this.data,
    this.error,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.onRetry,
    this.loadingMessage,
    this.skeletonType = SkeletonType.card,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case DataState.initial:
      case DataState.loading:
        if (loadingBuilder != null) {
          return loadingBuilder!(context);
        }
        return StatisticsSkeletonLoader(
          itemCount: 3,
          type: skeletonType,
        );

      case DataState.error:
        if (errorBuilder != null && error != null) {
          return errorBuilder!(context, error!);
        }
        return StatisticsErrorState(
          message: 'Bir Hata Oluştu',
          details: error?.toString(),
          onRetry: onRetry,
        );

      case DataState.empty:
        if (emptyBuilder != null) {
          return emptyBuilder!(context);
        }
        return StatisticsEmptyStates.noTransactions();

      case DataState.success:
        if (data == null) {
          return StatisticsEmptyStates.noTransactions();
        }
        return builder(context, data as T);
    }
  }
}
