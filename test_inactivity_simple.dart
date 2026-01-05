import 'package:flutter/material.dart';
import 'lib/services/unified_auth_service.dart';
import 'lib/services/auth/session_manager.dart';
import 'lib/services/auth/auth_service.dart';
import 'lib/models/security/security_models.dart';

/// Simple inactivity test
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Starting Inactivity Test...');
  
  try {
    final unifiedAuth = UnifiedAuthService();
    final sessionManager = SessionManager();
    final authService = AuthService();
    
    // Initialize services
    await unifiedAuth.initialize();
    await sessionManager.initialize();
    await authService.initialize();
    
    print('✅ Services initialized');
    
    // Get current config
    final config = await authService.getSecurityConfig();
    print('⚙️ Current session timeout: ${config.sessionTimeout.inMinutes} minutes');
    
    // Set a short timeout for testing (30 seconds)
    final testConfig = config.copyWith(
      sessionTimeout: Duration(seconds: 30),
    );
    
    await authService.updateSecurityConfig(testConfig);
    print('⚙️ Set test timeout: 30 seconds');
    
    // Simulate authentication
    await authService.setAuthenticatedForTesting(method: AuthMethod.biometric);
    print('🔐 Simulated authentication');
    
    // Check initial state
    bool isAuth = await authService.isAuthenticated();
    bool sessionActive = await sessionManager.isSessionActive();
    print('📊 Initial state - Auth: $isAuth, Session: $sessionActive');
    
    // Wait 35 seconds (longer than timeout)
    print('⏰ Waiting 35 seconds (exceeds 30s timeout)...');
    await Future.delayed(Duration(seconds: 35));
    
    // Check final state
    isAuth = await authService.isAuthenticated();
    sessionActive = await sessionManager.isSessionActive();
    print('📊 Final state - Auth: $isAuth, Session: $sessionActive');
    
    if (!isAuth && !sessionActive) {
      print('✅ SUCCESS: Session correctly expired due to inactivity');
    } else {
      print('❌ FAILED: Session should have expired');
    }
    
    // Restore original config
    await authService.updateSecurityConfig(config);
    print('⚙️ Restored original timeout');
    
  } catch (e) {
    print('❌ Test failed: $e');
  }
}