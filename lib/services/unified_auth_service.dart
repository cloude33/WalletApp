import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_auth_service.dart';
import 'auth/auth_service.dart';
import '../models/security/security_models.dart';
import '../services/data_service.dart';
import '../models/user.dart' as app_user;

class UnifiedAuthService {
  static final UnifiedAuthService _instance = UnifiedAuthService._internal();
  factory UnifiedAuthService() => _instance;
  UnifiedAuthService._internal();

  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();
  final AuthService _localAuth = AuthService();
  
  final StreamController<UnifiedAuthState> _authStateController = 
      StreamController<UnifiedAuthState>.broadcast();
  
  UnifiedAuthState _currentState = UnifiedAuthState.unauthenticated();
  bool _isInitialized = false;

  /// Authentication state stream
  Stream<UnifiedAuthState> get authStateStream => _authStateController.stream;
  
  /// Current authentication state
  UnifiedAuthState get currentState => _currentState;
  
  /// Current Firebase user
  User? get currentFirebaseUser => _firebaseAuth.currentUser;
  
  /// Is user authenticated (both Firebase and local if enabled)
  bool get isAuthenticated => _currentState.isFullyAuthenticated;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _localAuth.initialize();
      
      // Listen to Firebase auth changes
      _firebaseAuth.authStateChanges.listen(_onFirebaseAuthChanged);
      
      // Listen to local auth changes
      _localAuth.authStateStream.listen(_onLocalAuthChanged);
      
      // Load initial state
      await _loadInitialState();
      
      _isInitialized = true;
      debugPrint('✅ Unified Auth Service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize Unified Auth Service: $e');
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      debugPrint('🔄 Creating Firebase account...');
      
      final credential = await _firebaseAuth.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      
      if (credential?.user != null) {
        debugPrint('✅ Firebase account created: ${credential!.user!.email}');
        return AuthResult.success(
          method: AuthMethod.twoFactor, // Using twoFactor as placeholder for email/password
          metadata: {'email': email, 'displayName': displayName},
        );
      } else {
        return AuthResult.failure(
          method: AuthMethod.twoFactor,
          errorMessage: 'Failed to create account',
        );
      }
    } catch (e) {
      debugPrint('❌ Sign up error: $e');
      return AuthResult.failure(
        method: AuthMethod.twoFactor,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔄 Signing in with email...');
      
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential?.user != null) {
        debugPrint('✅ Firebase sign in successful: ${credential!.user!.email}');
        return AuthResult.success(
          method: AuthMethod.twoFactor,
          metadata: {'email': email},
        );
      } else {
        return AuthResult.failure(
          method: AuthMethod.twoFactor,
          errorMessage: 'Failed to sign in',
        );
      }
    } catch (e) {
      debugPrint('❌ Sign in error: $e');
      return AuthResult.failure(
        method: AuthMethod.twoFactor,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      debugPrint('🔄 Signing in with Google...');
      
      final credential = await _firebaseAuth.signInWithGoogle();
      
      if (credential?.user != null) {
        debugPrint('✅ Google sign in successful: ${credential!.user!.email}');
        return AuthResult.success(
          method: AuthMethod.twoFactor, // Using twoFactor as placeholder for OAuth
          metadata: {'provider': 'google', 'email': credential.user!.email},
        );
      } else {
        return AuthResult.failure(
          method: AuthMethod.twoFactor,
          errorMessage: 'Google sign in was cancelled',
        );
      }
    } catch (e) {
      debugPrint('❌ Google sign in error: $e');
      return AuthResult.failure(
        method: AuthMethod.twoFactor,
        errorMessage: e.toString(),
      );
    }
  }

  /// Enable biometric authentication (requires Firebase user)
  Future<AuthResult> enableBiometricAuth() async {
    try {
      if (_firebaseAuth.currentUser == null) {
        return AuthResult.failure(
          method: AuthMethod.biometric,
          errorMessage: 'Firebase account required to enable biometric authentication',
        );
      }

      debugPrint('🔄 Enabling biometric authentication...');
      
      // Test biometric authentication first
      final result = await _localAuth.authenticateWithBiometric();
      
      if (result.isSuccess) {
        // Store biometric enabled flag tied to Firebase user
        await _setBiometricEnabledForUser(true);
        debugPrint('✅ Biometric authentication enabled');
        
        await _updateState();
        return result;
      } else {
        return result;
      }
    } catch (e) {
      debugPrint('❌ Enable biometric error: $e');
      return AuthResult.failure(
        method: AuthMethod.biometric,
        errorMessage: e.toString(),
      );
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometricAuth() async {
    try {
      if (_firebaseAuth.currentUser != null) {
        await _setBiometricEnabledForUser(false);
        await _updateState();
        debugPrint('✅ Biometric authentication disabled');
      }
    } catch (e) {
      debugPrint('❌ Disable biometric error: $e');
    }
  }

  /// Authenticate with biometric (requires Firebase user and enabled biometric)
  Future<AuthResult> authenticateWithBiometric() async {
    try {
      if (_firebaseAuth.currentUser == null) {
        return AuthResult.failure(
          method: AuthMethod.biometric,
          errorMessage: 'Firebase account required for biometric authentication',
        );
      }

      final isBiometricEnabled = await _isBiometricEnabledForUser();
      if (!isBiometricEnabled) {
        return AuthResult.failure(
          method: AuthMethod.biometric,
          errorMessage: 'Biometric authentication not enabled for this account',
        );
      }

      debugPrint('🔄 Authenticating with biometric...');
      
      final result = await _localAuth.authenticateWithBiometric();
      
      if (result.isSuccess) {
        await _updateState();
        debugPrint('✅ Biometric authentication successful');
      }
      
      return result;
    } catch (e) {
      debugPrint('❌ Biometric authentication error: $e');
      return AuthResult.failure(
        method: AuthMethod.biometric,
        errorMessage: e.toString(),
      );
    }
  }

  /// Check if user is authenticated for sensitive operations
  Future<bool> requiresSensitiveAuth() async {
    if (!isAuthenticated) return true;
    
    // If biometric is enabled, check local auth requirements
    if (await _isBiometricEnabledForUser()) {
      return await _localAuth.requiresSensitiveAuth();
    }
    
    // If only Firebase auth, always require re-auth for sensitive operations
    return true;
  }

  /// Authenticate for sensitive operations
  Future<AuthResult> authenticateForSensitiveOperation() async {
    try {
      if (_firebaseAuth.currentUser == null) {
        return AuthResult.failure(
          method: AuthMethod.biometric,
          errorMessage: 'Firebase account required',
        );
      }

      final isBiometricEnabled = await _isBiometricEnabledForUser();
      if (isBiometricEnabled) {
        // Use biometric for sensitive operations
        return await _localAuth.authenticateForSensitiveOperation();
      } else {
        // For non-biometric users, we could implement password re-entry
        // For now, we'll consider them authenticated if they have Firebase session
        return AuthResult.success(
          method: AuthMethod.twoFactor,
          metadata: {'sensitive': true},
        );
      }
    } catch (e) {
      debugPrint('❌ Sensitive operation auth error: $e');
      return AuthResult.failure(
        method: AuthMethod.biometric,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sign out from all services
  Future<void> signOut() async {
    try {
      debugPrint('🔄 Signing out...');
      
      // Sign out from Firebase
      await _firebaseAuth.signOut();
      
      // Sign out from local auth
      await _localAuth.logout();
      
      // Update state
      _currentState = UnifiedAuthState.unauthenticated();
      _authStateController.add(_currentState);
      
      debugPrint('✅ Signed out successfully');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
    }
  }

  /// Check if biometric is available on device
  Future<bool> isBiometricAvailable() async {
    try {
      await _localAuth.initialize();
      return await _localAuth.isAuthenticated(); // This checks if biometric is available
    } catch (e) {
      return false;
    }
  }

  /// Check if biometric is enabled for current user
  Future<bool> isBiometricEnabledForCurrentUser() async {
    return await _isBiometricEnabledForUser();
  }

  /// Record user activity to extend session
  Future<void> recordActivity() async {
    try {
      if (isAuthenticated) {
        await _localAuth.recordActivity();
      }
    } catch (e) {
      debugPrint('❌ Record activity error: $e');
    }
  }

  /// Handle app background
  Future<void> onAppBackground() async {
    try {
      if (isAuthenticated) {
        // Store background timestamp
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('background_timestamp', DateTime.now().millisecondsSinceEpoch);
        
        await _localAuth.onAppBackground();
        debugPrint('🌙 App went to background - timestamp stored, auth services notified');
      }
    } catch (e) {
      debugPrint('❌ Background handling error: $e');
    }
  }

  /// Handle app foreground
  Future<void> onAppForeground() async {
    try {
      if (_firebaseAuth.currentUser != null) {
        // Check background duration
        final prefs = await SharedPreferences.getInstance();
        final backgroundTimestamp = prefs.getInt('background_timestamp');
        
        if (backgroundTimestamp != null) {
          final backgroundTime = DateTime.fromMillisecondsSinceEpoch(backgroundTimestamp);
          final elapsedTime = DateTime.now().difference(backgroundTime);
          
          debugPrint('📱 App returned from background after ${elapsedTime.inSeconds} seconds');
          
          // Get security config to check background lock settings
          final config = await _localAuth.getSecurityConfig();
          
          // Check if background time exceeded threshold
          if (config.sessionConfig.enableBackgroundLock && 
              elapsedTime >= config.sessionConfig.backgroundLockDelay) {
            debugPrint('🔒 Background time exceeded threshold - signing out');
            await signOut();
            return;
          }
          
          // Check if session timeout exceeded during background
          final sessionActive = await _localAuth.isAuthenticated();
          if (!sessionActive) {
            debugPrint('🔒 Session expired during background - signing out');
            await signOut();
            return;
          }
          
          // Clear background timestamp
          await prefs.remove('background_timestamp');
        }
        
        // Notify other services about foreground
        await _localAuth.onAppForeground();
        await _updateState();
        
        debugPrint('✅ App foreground handling completed successfully');
      }
    } catch (e) {
      debugPrint('❌ Foreground handling error: $e');
    }
  }

  /// Dispose the service
  void dispose() {
    _localAuth.dispose();
    if (!_authStateController.isClosed) {
      _authStateController.close();
    }
  }

  // Private methods

  Future<void> _loadInitialState() async {
    await _updateState();
  }

  Future<void> _updateState() async {
    final firebaseUser = _firebaseAuth.currentUser;
    final isLocalAuthenticated = await _localAuth.isAuthenticated();
    final isBiometricEnabled = await _isBiometricEnabledForUser();
    
    if (firebaseUser != null) {
      // Sync Firebase user details to local data service
      await _syncFirebaseUserToLocal(firebaseUser);

      if (isBiometricEnabled && isLocalAuthenticated) {
        _currentState = UnifiedAuthState.fullyAuthenticated(
          firebaseUser: firebaseUser,
          localAuthState: _localAuth.currentAuthState,
          biometricEnabled: true,
        );
      } else if (isBiometricEnabled && !isLocalAuthenticated) {
        _currentState = UnifiedAuthState.firebaseOnlyAuthenticated(
          firebaseUser: firebaseUser,
          biometricEnabled: true,
          requiresLocalAuth: true,
        );
      } else {
        _currentState = UnifiedAuthState.firebaseOnlyAuthenticated(
          firebaseUser: firebaseUser,
          biometricEnabled: false,
          requiresLocalAuth: false,
        );
      }
    } else {
      _currentState = UnifiedAuthState.unauthenticated();
    }

    _authStateController.add(_currentState);
    debugPrint('🔄 Auth state updated: ${_currentState.status}');
  }

  Future<void> _syncFirebaseUserToLocal(User firebaseUser) async {
    try {
      final dataService = DataService();
      // Ensure data service is initialized
      await dataService.getPrefs();

      app_user.User? localUser = await dataService.getCurrentUser();

      if (localUser == null) {
        // Create new local user if none exists
        final newUser = app_user.User(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'Kullanıcı',
          email: firebaseUser.email,
          authMethod: app_user.AuthMethod.email, // Default to email, update if needed
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await dataService.saveUser(newUser);
        debugPrint('✅ Created new local user from Firebase: ${newUser.name}');
      } else {
        bool changed = false;
        app_user.User updatedUser = localUser;

        // Update email if different
        if (firebaseUser.email != null && updatedUser.email != firebaseUser.email) {
          updatedUser = updatedUser.copyWith(email: firebaseUser.email);
          changed = true;
        }

        // Update name if different and available in Firebase
        if (firebaseUser.displayName != null &&
            firebaseUser.displayName!.isNotEmpty &&
            updatedUser.name != firebaseUser.displayName) {
          updatedUser = updatedUser.copyWith(name: firebaseUser.displayName);
          changed = true;
        }

        if (changed) {
          await dataService.updateUser(updatedUser);
          debugPrint('✅ Synced Firebase user data to local user: ${updatedUser.name} (${updatedUser.email})');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to sync Firebase user to local: $e');
    }
  }

  void _onFirebaseAuthChanged(User? user) {
    debugPrint('🔄 Firebase auth changed: ${user?.email ?? 'null'}');
    _updateState();
  }

  void _onLocalAuthChanged(AuthState localState) {
    debugPrint('🔄 Local auth changed: ${localState.isAuthenticated}');
    _updateState();
  }

  Future<bool> _isBiometricEnabledForUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled_${user.uid}') ?? false;
  }

  Future<void> _setBiometricEnabledForUser(bool enabled) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled_${user.uid}', enabled);
  }
}

/// Unified authentication state
class UnifiedAuthState {
  final UnifiedAuthStatus status;
  final User? firebaseUser;
  final AuthState? localAuthState;
  final bool biometricEnabled;
  final bool requiresLocalAuth;

  const UnifiedAuthState._({
    required this.status,
    this.firebaseUser,
    this.localAuthState,
    this.biometricEnabled = false,
    this.requiresLocalAuth = false,
  });

  factory UnifiedAuthState.unauthenticated() {
    return const UnifiedAuthState._(
      status: UnifiedAuthStatus.unauthenticated,
    );
  }

  factory UnifiedAuthState.firebaseOnlyAuthenticated({
    required User firebaseUser,
    required bool biometricEnabled,
    required bool requiresLocalAuth,
  }) {
    return UnifiedAuthState._(
      status: requiresLocalAuth 
          ? UnifiedAuthStatus.firebaseAuthenticatedLocalRequired
          : UnifiedAuthStatus.firebaseOnlyAuthenticated,
      firebaseUser: firebaseUser,
      biometricEnabled: biometricEnabled,
      requiresLocalAuth: requiresLocalAuth,
    );
  }

  factory UnifiedAuthState.fullyAuthenticated({
    required User firebaseUser,
    required AuthState localAuthState,
    required bool biometricEnabled,
  }) {
    return UnifiedAuthState._(
      status: UnifiedAuthStatus.fullyAuthenticated,
      firebaseUser: firebaseUser,
      localAuthState: localAuthState,
      biometricEnabled: biometricEnabled,
      requiresLocalAuth: false,
    );
  }

  bool get isFirebaseAuthenticated => firebaseUser != null;
  bool get isLocalAuthenticated => localAuthState?.isAuthenticated ?? false;
  bool get isFullyAuthenticated => status == UnifiedAuthStatus.fullyAuthenticated;
  bool get canUseApp => isFullyAuthenticated || status == UnifiedAuthStatus.firebaseOnlyAuthenticated;
  bool get canUseBackup => isFirebaseAuthenticated;
}

enum UnifiedAuthStatus {
  unauthenticated,
  firebaseOnlyAuthenticated,
  firebaseAuthenticatedLocalRequired,
  fullyAuthenticated,
}