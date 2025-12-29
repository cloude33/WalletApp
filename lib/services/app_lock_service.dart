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
  int _lockTimeoutMinutes = 5;
  Function()? onLock;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _lockTimeoutMinutes = _prefs?.getInt('lock_timeout_minutes') ?? 5;
    _lastActiveTime = DateTime.now();
    _isLocked = false;
    await _prefs?.setBool('is_locked', false);
  }
  Future<void> setLockTimeout(int minutes) async {
    _lockTimeoutMinutes = minutes;
    await _prefs?.setInt('lock_timeout_minutes', minutes);
  }
  int getLockTimeout() => _lockTimeoutMinutes;
  Future<bool> isAutoLockEnabled() async {
    return _prefs?.getBool('auto_lock_enabled') ?? true;
  }
  Future<void> setAutoLockEnabled(bool enabled) async {
    await _prefs?.setBool('auto_lock_enabled', enabled);
    if (enabled) {
      startMonitoring();
    } else {
      stopMonitoring();
    }
  }
  void startMonitoring() {
    _lockTimer?.cancel();
    _lastActiveTime = DateTime.now();

    _lockTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkInactivity();
    });
  }
  void stopMonitoring() {
    _lockTimer?.cancel();
    _lockTimer = null;
  }
  void updateActivity() {
    _lastActiveTime = DateTime.now();
  }
  void _checkInactivity() async {
    if (_lastActiveTime == null) return;
    if (_isLocked) return;

    final autoLockEnabled = await isAutoLockEnabled();
    if (!autoLockEnabled) return;

    final now = DateTime.now();
    final difference = now.difference(_lastActiveTime!);

    if (difference.inMinutes >= _lockTimeoutMinutes) {
      _isLocked = true;
      await _prefs?.setBool('is_locked', true);
      onLock?.call();
    }
  }
  bool get isLocked => _isLocked;
  void lock() {
    _isLocked = true;
    _prefs?.setBool('is_locked', true);
    onLock?.call();
  }
  void unlock() {
    _isLocked = false;
    _prefs?.setBool('is_locked', false);
    _lastActiveTime = DateTime.now();
    startMonitoring();
  }
  void dispose() {
    _lockTimer?.cancel();
  }
}
