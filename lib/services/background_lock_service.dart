import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BackgroundLockService {
  static final BackgroundLockService _instance = BackgroundLockService._internal();
  factory BackgroundLockService() => _instance;
  BackgroundLockService._internal();

  Timer? _backgroundTimer;
  DateTime? _backgroundTime;
  bool _isLocked = false;
  final Duration _lockDuration = const Duration(minutes: 1);

  final StreamController<bool> _lockStateController = StreamController<bool>.broadcast();
  Stream<bool> get lockStateStream => _lockStateController.stream;

  bool get isLocked => _isLocked;

  void initialize() {
    SystemChannels.lifecycle.setMessageHandler(_handleLifecycleMessage);
  }

  Future<String?> _handleLifecycleMessage(String? message) async {
    debugPrint('Lifecycle message: $message');
    
    switch (message) {
      case 'AppLifecycleState.paused':
      case 'AppLifecycleState.inactive':
        _onAppPaused();
        break;
      case 'AppLifecycleState.resumed':
        _onAppResumed();
        break;
      case 'AppLifecycleState.detached':
        _onAppDetached();
        break;
    }
    return null;
  }

  void _onAppPaused() {
    debugPrint('App paused - starting background timer');
    _backgroundTime = DateTime.now();
    _startBackgroundTimer();
  }

  void _onAppResumed() {
    debugPrint('App resumed - checking if lock needed');
    _stopBackgroundTimer();
    
    if (_backgroundTime != null) {
      final timeDifference = DateTime.now().difference(_backgroundTime!);
      debugPrint('Time in background: ${timeDifference.inSeconds} seconds');
      
      if (timeDifference >= _lockDuration) {
        _lockApp();
      }
    }
    
    _backgroundTime = null;
  }

  void _onAppDetached() {
    debugPrint('App detached - locking immediately');
    _stopBackgroundTimer();
    _lockApp(); // Uygulama kapatıldığında hemen kilitle
  }

  void _startBackgroundTimer() {
    _stopBackgroundTimer();
    _backgroundTimer = Timer(_lockDuration, () {
      debugPrint('Background timer expired - app should be locked');
    });
  }

  void _stopBackgroundTimer() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
  }

  void _lockApp() {
    if (!_isLocked) {
      debugPrint('Locking app due to background timeout');
      _isLocked = true;
      _lockStateController.add(true);
    }
  }

  void unlockApp() {
    if (_isLocked) {
      debugPrint('Unlocking app');
      _isLocked = false;
      _lockStateController.add(false);
    }
  }

  void dispose() {
    _stopBackgroundTimer();
    _lockStateController.close();
  }
}
