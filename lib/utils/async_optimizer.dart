import 'dart:async';

/// Utility class for optimizing async operations
class AsyncOptimizer {
  /// Debounce a function call
  /// Delays execution until after [duration] has elapsed since the last call
  static Timer? _debounceTimer;

  static void debounce(
    Duration duration,
    void Function() action,
  ) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, action);
  }

  /// Throttle a function call
  /// Ensures function is called at most once per [duration]
  static DateTime? _lastThrottleTime;

  static void throttle(
    Duration duration,
    void Function() action,
  ) {
    final now = DateTime.now();
    if (_lastThrottleTime == null ||
        now.difference(_lastThrottleTime!) >= duration) {
      _lastThrottleTime = now;
      action();
    }
  }

  /// Batch multiple async operations and execute them in parallel
  /// Returns results in the same order as the futures
  static Future<List<T>> batchExecute<T>(
    List<Future<T> Function()> operations, {
    int? maxConcurrent,
  }) async {
    if (maxConcurrent == null) {
      // Execute all in parallel
      return Future.wait(operations.map((op) => op()));
    }

    // Execute with concurrency limit
    final results = <T>[];
    final queue = List<Future<T> Function()>.from(operations);

    while (queue.isNotEmpty) {
      final batch = queue.take(maxConcurrent).toList();
      queue.removeRange(0, batch.length);

      final batchResults = await Future.wait(batch.map((op) => op()));
      results.addAll(batchResults);
    }

    return results;
  }

  /// Execute operations with retry logic
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(dynamic error)? retryIf,
  }) async {
    int attempts = 0;

    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        if (attempts >= maxAttempts) {
          rethrow;
        }

        if (retryIf != null && !retryIf(e)) {
          rethrow;
        }

        await Future.delayed(delay * attempts);
      }
    }
  }

  /// Execute operation with timeout
  static Future<T> withTimeout<T>(
    Future<T> Function() operation, {
    required Duration timeout,
    T? defaultValue,
  }) async {
    try {
      return await operation().timeout(timeout);
    } on TimeoutException {
      if (defaultValue != null) {
        return defaultValue;
      }
      rethrow;
    }
  }

  /// Memoize async function results
  static final Map<String, _MemoizedResult> _memoCache = {};

  static Future<T> memoize<T>(
    String key,
    Future<T> Function() operation, {
    Duration? cacheDuration,
  }) async {
    final cached = _memoCache[key];
    if (cached != null) {
      if (cacheDuration == null ||
          DateTime.now().difference(cached.timestamp) < cacheDuration) {
        return cached.value as T;
      }
    }

    final result = await operation();
    _memoCache[key] = _MemoizedResult(
      value: result,
      timestamp: DateTime.now(),
    );

    return result;
  }

  /// Clear memoization cache
  static void clearMemoCache([String? key]) {
    if (key != null) {
      _memoCache.remove(key);
    } else {
      _memoCache.clear();
    }
  }

  /// Execute operations in sequence with delay between each
  static Future<List<T>> executeSequentially<T>(
    List<Future<T> Function()> operations, {
    Duration? delayBetween,
  }) async {
    final results = <T>[];

    for (var i = 0; i < operations.length; i++) {
      results.add(await operations[i]());

      if (delayBetween != null && i < operations.length - 1) {
        await Future.delayed(delayBetween);
      }
    }

    return results;
  }

  /// Cancel all pending operations
  static void cancelAll() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _lastThrottleTime = null;
    _memoCache.clear();
  }
}

class _MemoizedResult {
  final dynamic value;
  final DateTime timestamp;

  _MemoizedResult({
    required this.value,
    required this.timestamp,
  });
}

/// Stream debouncer for search and filter operations
class StreamDebouncer<T> {
  final Duration duration;
  Timer? _timer;
  T? _lastValue;
  final void Function(T value) onValue;

  StreamDebouncer({
    required this.duration,
    required this.onValue,
  });

  void call(T value) {
    _lastValue = value;
    _timer?.cancel();
    _timer = Timer(duration, () {
      if (_lastValue != null) {
        onValue(_lastValue as T);
      }
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}
