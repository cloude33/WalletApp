import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'lib/services/unified_auth_service.dart';
import 'lib/services/auth/session_manager.dart';
import 'lib/services/auth/auth_service.dart';

/// Background lock test utility
class BackgroundLockTester {
  static final UnifiedAuthService _unifiedAuth = UnifiedAuthService();
  static final SessionManager _sessionManager = SessionManager();
  static final AuthService _authService = AuthService();
  
  /// Test background lock functionality
  static Future<void> testBackgroundLock() async {
    debugPrint('🧪 Starting background lock test...');
    
    try {
      // 1. Initialize services
      await _unifiedAuth.initialize();
      await _sessionManager.initialize();
      await _authService.initialize();
      
      // 2. Check current auth state
      final isAuth = await _authService.isAuthenticated();
      debugPrint('📊 Current auth state: $isAuth');
      
      // 3. Get security config
      final config = await _authService.getSecurityConfig();
      debugPrint('⚙️ Background lock enabled: ${config.sessionConfig.enableBackgroundLock}');
      debugPrint('⏱️ Background lock delay: ${config.sessionConfig.backgroundLockDelay.inSeconds}s');
      
      // 4. Test lifecycle events
      debugPrint('🔄 Testing app lifecycle events...');
      await _testLifecycleEvents();
      
      // 5. Test timer conflicts
      await _testTimerConflicts();
      
      debugPrint('✅ Background lock test completed');
      
    } catch (e) {
      debugPrint('❌ Background lock test failed: $e');
    }
  }
  
  /// Test lifecycle events
  static Future<void> _testLifecycleEvents() async {
    debugPrint('📱 Simulating app going to background...');
    
    // Simulate app going to background
    await _unifiedAuth.onAppBackground();
    await _sessionManager.onAppBackground();
    await _authService.onAppBackground();
    
    debugPrint('⏰ Waiting 2 seconds...');
    await Future.delayed(Duration(seconds: 2));
    
    debugPrint('📱 Simulating app coming to foreground...');
    
    // Simulate app coming to foreground
    await _unifiedAuth.onAppForeground();
    await _sessionManager.onAppForeground();
    await _authService.onAppForeground();
    
    // Check auth state after foreground
    final isAuthAfter = await _authService.isAuthenticated();
    debugPrint('📊 Auth state after foreground: $isAuthAfter');
  }
  
  /// Test timer conflicts between services
  static Future<void> _testTimerConflicts() async {
    debugPrint('⚡ Testing timer conflicts...');
    
    // Check if multiple timers are running
    final sessionActive = await _sessionManager.isSessionActive();
    final authState = _authService.currentAuthState;
    
    debugPrint('📊 Session manager active: $sessionActive');
    debugPrint('📊 Auth service state: ${authState.isAuthenticated}');
    
    // Test rapid background/foreground switches
    for (int i = 0; i < 3; i++) {
      debugPrint('🔄 Rapid switch test $i');
      await _unifiedAuth.onAppBackground();
      await Future.delayed(Duration(milliseconds: 100));
      await _unifiedAuth.onAppForeground();
      await Future.delayed(Duration(milliseconds: 100));
    }
  }
  
  /// Get current timer states for debugging
  static Future<Map<String, dynamic>> getTimerStates() async {
    final sessionRemaining = await _sessionManager.getSessionRemainingTime();
    final isSessionActive = await _sessionManager.isSessionActive();
    final authState = _authService.currentAuthState;
    
    return {
      'sessionRemainingTime': sessionRemaining?.inSeconds,
      'isSessionActive': isSessionActive,
      'isAuthenticated': authState.isAuthenticated,
      'lastActivityTime': _sessionManager.lastActivityTime.toIso8601String(),
    };
  }
}