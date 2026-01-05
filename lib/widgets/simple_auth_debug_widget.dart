import 'package:flutter/material.dart';
import 'dart:async';
import '../services/unified_auth_service.dart';
import '../services/auth/session_manager.dart';
import '../services/auth/auth_service.dart';

class SimpleAuthDebugWidget extends StatefulWidget {
  const SimpleAuthDebugWidget({super.key});

  @override
  State<SimpleAuthDebugWidget> createState() => _SimpleAuthDebugWidgetState();
}

class _SimpleAuthDebugWidgetState extends State<SimpleAuthDebugWidget> {
  final UnifiedAuthService _unifiedAuth = UnifiedAuthService();
  final SessionManager _sessionManager = SessionManager();
  final AuthService _authService = AuthService();
  
  Timer? _updateTimer;
  Map<String, dynamic> _debugInfo = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _updateDebugInfo();
    });
    _updateDebugInfo();
  }

  Future<void> _updateDebugInfo() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final isAuth = await _authService.isAuthenticated();
      final sessionActive = await _sessionManager.isSessionActive();
      final sessionRemaining = await _sessionManager.getSessionRemainingTime();
      final config = await _authService.getSecurityConfig();
      final unifiedState = _unifiedAuth.currentState;
      
      // Firebase auth durumunu da kontrol et
      final firebaseUser = _unifiedAuth.currentFirebaseUser;
      final isFirebaseAuth = firebaseUser != null;
      final isBiometricEnabled = await _unifiedAuth.isBiometricEnabledForCurrentUser();
      
      final info = {
        'localAuth': isAuth,
        'firebaseAuth': isFirebaseAuth,
        'biometricEnabled': isBiometricEnabled,
        'sessionActive': sessionActive,
        'sessionRemainingSeconds': sessionRemaining?.inSeconds ?? 0,
        'backgroundLockEnabled': config.sessionConfig.enableBackgroundLock,
        'backgroundLockDelay': config.sessionConfig.backgroundLockDelay.inSeconds,
        'sessionTimeout': config.sessionTimeout.inSeconds,
        'unifiedAuthStatus': unifiedState.status.toString().split('.').last,
        'canUseApp': unifiedState.canUseApp,
        'firebaseEmail': firebaseUser?.email ?? 'None',
        'lastActivityTime': _sessionManager.lastActivityTime.toIso8601String(),
      };
      
      if (mounted) {
        setState(() {
          _debugInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _debugInfo = {'error': e.toString()};
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Auth Debug',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_debugInfo.containsKey('error'))
              Text(
                'Error: ${_debugInfo['error']}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              )
            else
              _buildDebugInfo(),
            const SizedBox(height: 8),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugInfo() {
    return Column(
      children: [
        _buildInfoRow('Firebase', _debugInfo['firebaseAuth']?.toString() ?? 'Unknown'),
        _buildInfoRow('Local', _debugInfo['localAuth']?.toString() ?? 'Unknown'),
        _buildInfoRow('Biometric', _debugInfo['biometricEnabled']?.toString() ?? 'Unknown'),
        _buildInfoRow('Session', _debugInfo['sessionActive']?.toString() ?? 'Unknown'),
        _buildInfoRow('Remaining', '${_debugInfo['sessionRemainingSeconds'] ?? 0}s'),
        _buildInfoRow('Status', _debugInfo['unifiedAuthStatus']?.toString() ?? 'Unknown'),
        _buildInfoRow('Can Use', _debugInfo['canUseApp']?.toString() ?? 'Unknown'),
        _buildInfoRow('Email', _debugInfo['firebaseEmail']?.toString() ?? 'None'),
        _buildInfoRow('BG Lock', _debugInfo['backgroundLockEnabled']?.toString() ?? 'Unknown'),
        _buildInfoRow('BG Delay', '${_debugInfo['backgroundLockDelay'] ?? 0}s'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: value.contains('true') ? Colors.green : 
                       value.contains('false') ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await _enableBiometric();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  textStyle: const TextStyle(fontSize: 10),
                  backgroundColor: Colors.blue,
                ),
                child: const Text('Enable Bio'),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await _testBackgroundLock();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  textStyle: const TextStyle(fontSize: 10),
                ),
                child: const Text('Test BG'),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await _testInactivity();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  textStyle: const TextStyle(fontSize: 10),
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Test Timeout'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _testBackgroundLock() async {
    debugPrint('🧪 Testing background lock...');
    
    // Simulate background
    await _unifiedAuth.onAppBackground();
    
    // Wait 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    
    // Simulate foreground
    await _unifiedAuth.onAppForeground();
    
    debugPrint('✅ Background lock test completed');
  }

  Future<void> _testInactivity() async {
    debugPrint('🧪 Testing inactivity timeout...');
    
    try {
      // Get current config
      final config = await _authService.getSecurityConfig();
      final originalTimeout = config.sessionTimeout;
      
      // Set short timeout for testing while preserving authentication methods
      final testConfig = config.copyWith(
        sessionTimeout: const Duration(seconds: 5),
        // Ensure at least one auth method is enabled to pass validation
        isBiometricEnabled: config.isBiometricEnabled || true, // Enable biometric if not already enabled
      );
      
      await _authService.updateSecurityConfig(testConfig);
      debugPrint('⚙️ Set test timeout: 5 seconds');
      
      // Wait 7 seconds without activity
      await Future.delayed(const Duration(seconds: 7));
      
      // Check if session expired
      final isAuth = await _authService.isAuthenticated();
      debugPrint('📊 Auth after timeout: $isAuth (should be false)');
      
      // Restore original config
      final restoreConfig = config.copyWith(
        sessionTimeout: originalTimeout,
      );
      await _authService.updateSecurityConfig(restoreConfig);
      debugPrint('⚙️ Restored original timeout');
      
    } catch (e) {
      debugPrint('❌ Inactivity test failed: $e');
    }
  }

  Future<void> _enableBiometric() async {
    debugPrint('🧪 Enabling biometric authentication...');
    
    try {
      // Check if Firebase user is logged in
      final firebaseUser = _unifiedAuth.currentFirebaseUser;
      if (firebaseUser == null) {
        debugPrint('❌ No Firebase user found. Please login first.');
        return;
      }
      
      debugPrint('✅ Firebase user found: ${firebaseUser.email}');
      
      // Enable biometric authentication through UnifiedAuthService
      final result = await _unifiedAuth.enableBiometricAuth();
      
      if (result.isSuccess) {
        debugPrint('✅ Biometric authentication enabled successfully');
        
        // Test biometric authentication immediately
        final authResult = await _unifiedAuth.authenticateWithBiometric();
        if (authResult.isSuccess) {
          debugPrint('✅ Biometric authentication test successful');
        } else {
          debugPrint('⚠️ Biometric authentication test failed: ${authResult.errorMessage}');
        }
      } else {
        debugPrint('❌ Failed to enable biometric: ${result.errorMessage}');
      }
      
    } catch (e) {
      debugPrint('❌ Enable biometric error: $e');
    }
  }
}