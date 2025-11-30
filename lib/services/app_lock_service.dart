import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class AppLockService {
  static final AppLockService _instance = AppLockService._internal();
  factory AppLockService() => _instance;
  AppLockService._internal();

  SharedPreferences? _prefs;
  Timer? _lockTimer;
  DateTime? _lastActiveTime;
  bool _isLocked = false;

  // Lock timeout in minutes (default: 5 minutes)
  int _lockTimeoutMinutes = 5;

  // Callbacks
  Function()? onLock;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _lockTimeoutMinutes = _prefs?.getInt('lock_timeout_minutes') ?? 5;
    _lastActiveTime = DateTime.now();
  }

  // Set lock timeout
  Future<void> setLockTimeout(int minutes) async {
    _lockTimeoutMinutes = minutes;
    await _prefs?.setInt('lock_timeout_minutes', minutes);
  }

  // Get lock timeout
  int getLockTimeout() => _lockTimeoutMinutes;

  // Check if auto-lock is enabled
  Future<bool> isAutoLockEnabled() async {
    return _prefs?.getBool('auto_lock_enabled') ?? true;
  }

  // Set auto-lock enabled
  Future<void> setAutoLockEnabled(bool enabled) async {
    await _prefs?.setBool('auto_lock_enabled', enabled);
    if (enabled) {
      startMonitoring();
    } else {
      stopMonitoring();
    }
  }

  // Start monitoring for inactivity
  void startMonitoring() {
    _lockTimer?.cancel();
    _lastActiveTime = DateTime.now();
    _isLocked = false;

    _lockTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkInactivity();
    });
  }

  // Stop monitoring
  void stopMonitoring() {
    _lockTimer?.cancel();
    _lockTimer = null;
  }

  // Update last active time
  void updateActivity() {
    _lastActiveTime = DateTime.now();
    if (_isLocked) {
      _isLocked = false;
    }
  }

  // Check for inactivity
  void _checkInactivity() async {
    if (_lastActiveTime == null) return;

    final autoLockEnabled = await isAutoLockEnabled();
    if (!autoLockEnabled) return;

    final now = DateTime.now();
    final difference = now.difference(_lastActiveTime!);

    if (difference.inMinutes >= _lockTimeoutMinutes && !_isLocked) {
      _isLocked = true;
      onLock?.call();
    }
  }

  // Check if app is locked
  bool get isLocked => _isLocked;

  // Manually lock the app
  void lock() {
    _isLocked = true;
    onLock?.call();
  }

  // Unlock the app
  void unlock() {
    _isLocked = false;
    _lastActiveTime = DateTime.now();
  }

  // Dispose
  void dispose() {
    _lockTimer?.cancel();
  }
}
