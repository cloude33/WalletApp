import 'dart:async';
class Debouncer {
  final Duration delay;
  Timer? _timer;
  Debouncer({required this.delay});
  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
  void cancel() {
    _timer?.cancel();
  }
  void dispose() {
    _timer?.cancel();
  }
}
class Throttler {
  final Duration duration;
  Timer? _timer;
  bool _isThrottled = false;
  Throttler({required this.duration});
  void call(void Function() action) {
    if (_isThrottled) return;

    action();
    _isThrottled = true;

    _timer = Timer(duration, () {
      _isThrottled = false;
    });
  }
  void cancel() {
    _timer?.cancel();
    _isThrottled = false;
  }
  void dispose() {
    _timer?.cancel();
  }
}
class TrailingThrottler {
  final Duration duration;
  Timer? _timer;
  bool _isThrottled = false;
  void Function()? _pendingAction;
  TrailingThrottler({required this.duration});
  void call(void Function() action) {
    if (_isThrottled) {
      _pendingAction = action;
      return;
    }
    action();
    _isThrottled = true;

    _timer = Timer(duration, () {
      _isThrottled = false;
      if (_pendingAction != null) {
        final pending = _pendingAction;
        _pendingAction = null;
        call(pending!);
      }
    });
  }
  void cancel() {
    _timer?.cancel();
    _isThrottled = false;
    _pendingAction = null;
  }
  void dispose() {
    _timer?.cancel();
    _pendingAction = null;
  }
}
extension DebouncedCallback on void Function() {
  void Function() debounced(Duration delay) {
    final debouncer = Debouncer(delay: delay);
    return () => debouncer.call(this);
  }
  void Function() throttled(Duration duration) {
    final throttler = Throttler(duration: duration);
    return () => throttler.call(this);
  }
}
