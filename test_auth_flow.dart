import 'package:flutter/material.dart';
import 'lib/services/unified_auth_service.dart';
import 'lib/services/auth/auth_service.dart';
import 'lib/services/auth/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Testing Authentication Flow...');
  
  final unifiedAuth = UnifiedAuthService();
  final authService = AuthService();
  final sessionManager = SessionManager();
  
  try {
    // Initialize services
    await unifiedAuth.initialize();
    await authService.initialize();
    await sessionManager.initialize();
    
    print('✅ Services initialized');
    
    // Test 1: Check current authentication state
    print('\n📊 Test 1: Current Authentication State');
    final currentState = unifiedAuth.currentState;
    print('Unified Auth Status: ${currentState.status}');
    print('Firebase User: ${currentState.firebaseUser?.email ?? 'None'}');
    print('Can Use App: ${currentState.canUseApp}');
    print('Is Fully Authenticated: ${currentState.isFullyAuthenticated}');
    
    // Test 2: Check local auth state
    print('\n📊 Test 2: Local Authentication State');
    final isLocalAuth = await authService.isAuthenticated();
    final sessionActive = await sessionManager.isSessionActive();
    print('Local Auth: $isLocalAuth');
    print('Session Active: $sessionActive');
    
    // Test 3: Check biometric availability and status
    print('\n📊 Test 3: Biometric Authentication');
    final isBiometricAvailable = await unifiedAuth.isBiometricAvailable();
    final isBiometricEnabled = await unifiedAuth.isBiometricEnabledForCurrentUser();
    print('Biometric Available: $isBiometricAvailable');
    print('Biometric Enabled for User: $isBiometricEnabled');
    
    // Test 4: Test background/foreground handling
    print('\n📊 Test 4: Background/Foreground Handling');
    print('Simulating background...');
    await unifiedAuth.onAppBackground();
    
    await Future.delayed(const Duration(seconds: 2));
    
    print('Simulating foreground...');
    await unifiedAuth.onAppForeground();
    
    // Test 5: Final state check
    print('\n📊 Test 5: Final State Check');
    final finalState = unifiedAuth.currentState;
    print('Final Auth Status: ${finalState.status}');
    print('Final Can Use App: ${finalState.canUseApp}');
    
    print('\n✅ Authentication flow test completed successfully!');
    
  } catch (e, stackTrace) {
    print('❌ Authentication flow test failed: $e');
    print('Stack trace: $stackTrace');
  }
}