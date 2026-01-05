import 'package:flutter/material.dart';
import '../services/unified_auth_service.dart';
import '../services/auth/session_manager.dart';
import '../services/auth/auth_service.dart';

/// Background lock debug utility
class BackgroundLockDebug {
  static final UnifiedAuthService _unifiedAuth = UnifiedAuthService();
  static final SessionManager _sessionManager = SessionManager();
  static final AuthService _authService = AuthService();
  
  /// Debug background lock functionality
  static Future<void> debugBackgroundLock() async {
    debugPrint('🧪 === BACKGROUND LOCK DEBUG START ===');
    
    try {
      // 1. Check current auth state
      final isAuth = await _authService.isAuthenticated();
      debugPrint('📊 Current auth state: $isAuth');
      
      // 2. Get security config
      final config = await _authService.getSecurityConfig();
      debugPrint('⚙️ Background lock enabled: ${config.sessionConfig.enableBackgroundLock}');
      debugPrint('⏱️ Background lock delay: ${config.sessionConfig.backgroundLockDelay.inSeconds}s');
      debugPrint('⏱️ Session timeout: ${config.sessionTimeout.inSeconds}s');
      
      // 3. Check session state
      final sessionActive = await _sessionManager.isSessionActive();
      final sessionRemaining = await _sessionManager.getSessionRemainingTime();
      debugPrint('📊 Session active: $sessionActive');
      debugPrint('⏱️ Session remaining: ${sessionRemaining?.inSeconds ?? 0}s');
      
      // 4. Test lifecycle simulation
      await _testLifecycleSimulation();
      
      debugPrint('✅ === BACKGROUND LOCK DEBUG END ===');
      
    } catch (e) {
      debugPrint('❌ Background lock debug failed: $e');
    }
  }
  
  /// Test lifecycle simulation
  static Future<void> _testLifecycleSimulation() async {
    debugPrint('🔄 Testing lifecycle simulation...');
    
    // Simulate background
    debugPrint('📱 Simulating app going to background...');
    await _unifiedAuth.onAppBackground();
    
    // Wait 2 seconds
    debugPrint('⏰ Waiting 2 seconds...');
    await Future.delayed(Duration(seconds: 2));
    
    // Simulate foreground
    debugPrint('📱 Simulating app coming to foreground...');
    await _unifiedAuth.onAppForeground();
    
    // Check auth state after
    final isAuthAfter = await _authService.isAuthenticated();
    debugPrint('📊 Auth state after simulation: $isAuthAfter');
  }
  
  /// Get current debug info
  static Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      final isAuth = await _authService.isAuthenticated();
      final config = await _authService.getSecurityConfig();
      final sessionActive = await _sessionManager.isSessionActive();
      final sessionRemaining = await _sessionManager.getSessionRemainingTime();
      
      return {
        'isAuthenticated': isAuth,
        'backgroundLockEnabled': config.sessionConfig.enableBackgroundLock,
        'backgroundLockDelay': config.sessionConfig.backgroundLockDelay.inSeconds,
        'sessionTimeout': config.sessionTimeout.inSeconds,
        'sessionActive': sessionActive,
        'sessionRemainingSeconds': sessionRemaining?.inSeconds ?? 0,
        'lastActivityTime': _sessionManager.lastActivityTime.toIso8601String(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// Force inactivity timeout test (simulates no user activity)
  static Future<void> testInactivityTimeout() async {
    debugPrint('🧪 Testing inactivity timeout (simulating no activity for 6 minutes)...');
    
    try {
      // Get current config
      final config = await _authService.getSecurityConfig();
      final originalTimeout = config.sessionTimeout;
      
      debugPrint('⚙️ Original session timeout: ${originalTimeout.inMinutes} minutes');
      
      // Temporarily set a shorter timeout for testing (10 seconds)
      final testConfig = config.copyWith(
        sessionTimeout: Duration(seconds: 10),
      );
      
      await _authService.updateSecurityConfig(testConfig);
      debugPrint('⚙️ Temporarily set session timeout to 10 seconds for testing');
      
      // Record initial activity to start fresh
      await _sessionManager.recordActivity();
      debugPrint('📝 Initial activity recorded');
      
      // Wait 12 seconds (longer than the test timeout) without any activity
      debugPrint('⏰ Waiting 12 seconds without activity (exceeds 10s timeout)...');
      await Future.delayed(Duration(seconds: 12));
      
      // Check if session is still active
      final isSessionActive = await _sessionManager.isSessionActive();
      final isAuth = await _authService.isAuthenticated();
      
      debugPrint('📊 Session active after timeout: $isSessionActive (should be false)');
      debugPrint('📊 Auth state after timeout: $isAuth (should be false)');
      
      // Restore original config
      await _authService.updateSecurityConfig(config);
      debugPrint('⚙️ Restored original session timeout: ${originalTimeout.inMinutes} minutes');
      
    } catch (e) {
      debugPrint('❌ Inactivity timeout test failed: $e');
    }
  }
}