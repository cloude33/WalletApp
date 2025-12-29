import 'package:flutter/material.dart';
import '../services/unified_auth_service.dart';
import '../utils/app_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UnifiedAuthScreen extends StatefulWidget {
  const UnifiedAuthScreen({super.key});

  @override
  State<UnifiedAuthScreen> createState() => _UnifiedAuthScreenState();
}

class _UnifiedAuthScreenState extends State<UnifiedAuthScreen> {
  final UnifiedAuthService _authService = UnifiedAuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSignUp = false;
  String _statusMessage = '';
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      await _authService.initialize();
      _checkAuthStatus();
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Initialization error: $e';
      });
    }
  }

  void _checkAuthStatus() {
    final state = _authService.currentState;
    setState(() {
      switch (state.status) {
        case UnifiedAuthStatus.unauthenticated:
          _statusMessage = '❌ Not signed in';
          break;
        case UnifiedAuthStatus.firebaseOnlyAuthenticated:
          _statusMessage = '✅ Signed in: ${state.firebaseUser?.email}';
          break;
        case UnifiedAuthStatus.firebaseAuthenticatedLocalRequired:
          _statusMessage = '🔐 Biometric authentication required';
          break;
        case UnifiedAuthStatus.fullyAuthenticated:
          _statusMessage = '✅ Fully authenticated: ${state.firebaseUser?.email}';
          break;
      }
    });
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _statusMessage = '❌ Email and password required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '🔄 Signing in...';
    });

    try {
      final result = await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() {
        if (result.isSuccess) {
          _statusMessage = '✅ Sign in successful';
          _checkAuthStatus();
        } else {
          _statusMessage = '❌ Sign in failed: ${result.errorMessage}';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Sign in error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _nameController.text.isEmpty) {
      setState(() {
        _statusMessage = '❌ All fields required for sign up';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '🔄 Creating account...';
    });

    try {
      final result = await _authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      setState(() {
        if (result.isSuccess) {
          _statusMessage = '✅ Account created successfully';
          _checkAuthStatus();
        } else {
          _statusMessage = '❌ Sign up failed: ${result.errorMessage}';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Sign up error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '🔄 Signing in with Google...';
    });

    try {
      final result = await _authService.signInWithGoogle();

      setState(() {
        if (result.isSuccess) {
          _statusMessage = '✅ Google sign in successful';
          _checkAuthStatus();
        } else {
          _statusMessage = '❌ Google sign in failed: ${result.errorMessage}';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Google sign in error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _enableBiometric() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '🔄 Enabling biometric authentication...';
    });

    try {
      final result = await _authService.enableBiometricAuth();

      setState(() {
        if (result.isSuccess) {
          _statusMessage = '✅ Biometric authentication enabled';
          _checkAuthStatus();
        } else {
          _statusMessage = '❌ Failed to enable biometric: ${result.errorMessage}';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Biometric enable error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _authenticateWithBiometric() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '🔄 Authenticating with biometric...';
    });

    try {
      final result = await _authService.authenticateWithBiometric();

      setState(() {
        if (result.isSuccess) {
          _statusMessage = '✅ Biometric authentication successful';
          _checkAuthStatus();
        } else {
          _statusMessage = '❌ Biometric authentication failed: ${result.errorMessage}';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Biometric authentication error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '🔄 Signing out...';
    });

    try {
      await _authService.signOut();
      setState(() {
        _statusMessage = '✅ Signed out successfully';
        _checkAuthStatus();
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Sign out error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unified Authentication'),
        backgroundColor: const Color(0xFF5E5CE6),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Auth form
            if (_authService.currentState.status == UnifiedAuthStatus.unauthenticated) ...[
              // Toggle between sign in and sign up
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _isSignUp = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_isSignUp ? Colors.blue : Colors.grey.shade300,
                        foregroundColor: !_isSignUp ? Colors.white : Colors.black,
                      ),
                      child: const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _isSignUp = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSignUp ? Colors.blue : Colors.grey.shade300,
                        foregroundColor: _isSignUp ? Colors.white : Colors.black,
                      ),
                      child: const Text('Sign Up'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Name field (only for sign up)
              if (_isSignUp) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: FaIcon(AppIcons.profile, size: 20),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Email field
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: FaIcon(FontAwesomeIcons.envelope, size: 20),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),

              // Password field
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: FaIcon(AppIcons.lock, size: 20),
                  suffixIcon: IconButton(
                    icon: FaIcon(_obscurePassword ? AppIcons.eyeSlash : AppIcons.eye, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 16),

              // Submit button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : (_isSignUp ? _signUpWithEmail : _signInWithEmail),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: FaIcon(_isSignUp ? FontAwesomeIcons.userPlus : FontAwesomeIcons.rightToBracket, size: 20),
                label: Text(_isSignUp ? 'Create Account' : 'Sign In'),
              ),
              const SizedBox(height: 16),

              // Google sign in
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: FaIcon(AppIcons.google, size: 20),
                label: const Text('Sign In with Google'),
              ),
            ],

            // Biometric options (when Firebase authenticated)
            if (_authService.currentState.isFirebaseAuthenticated) ...[
              const Divider(height: 32),
              const Text(
                'Biometric Authentication:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              if (!_authService.currentState.biometricEnabled) ...[
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _enableBiometric,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: FaIcon(AppIcons.fingerprint, size: 20),
                  label: const Text('Enable Biometric Authentication'),
                ),
              ] else if (_authService.currentState.requiresLocalAuth) ...[
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _authenticateWithBiometric,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: FaIcon(AppIcons.fingerprint, size: 20),
                  label: const Text('Authenticate with Biometric'),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      FaIcon(AppIcons.success, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('Biometric authentication active'),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Sign out button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: FaIcon(FontAwesomeIcons.rightFromBracket, size: 20),
                label: const Text('Sign Out'),
              ),
            ],

            const SizedBox(height: 24),

            // Auth state display
            StreamBuilder<UnifiedAuthState>(
              stream: _authService.authStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data ?? _authService.currentState;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: state.isFullyAuthenticated 
                        ? Colors.green.shade50 
                        : state.isFirebaseAuthenticated 
                            ? Colors.orange.shade50 
                            : Colors.red.shade50,
                    border: Border.all(
                      color: state.isFullyAuthenticated 
                          ? Colors.green 
                          : state.isFirebaseAuthenticated 
                              ? Colors.orange 
                              : Colors.red,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Authentication Status:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: state.isFullyAuthenticated 
                              ? Colors.green.shade700 
                              : state.isFirebaseAuthenticated 
                                  ? Colors.orange.shade700 
                                  : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusDescription(state),
                        style: TextStyle(
                          fontSize: 12,
                          color: state.isFullyAuthenticated 
                              ? Colors.green.shade600 
                              : state.isFirebaseAuthenticated 
                                  ? Colors.orange.shade600 
                                  : Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusDescription(UnifiedAuthState state) {
    switch (state.status) {
      case UnifiedAuthStatus.unauthenticated:
        return 'Not signed in\nBackup: ❌ Not available\nApp access: ❌ Limited';
      case UnifiedAuthStatus.firebaseOnlyAuthenticated:
        return 'Firebase: ✅ ${state.firebaseUser?.email}\nBiometric: ❌ Not enabled\nBackup: ✅ Available\nApp access: ✅ Full';
      case UnifiedAuthStatus.firebaseAuthenticatedLocalRequired:
        return 'Firebase: ✅ ${state.firebaseUser?.email}\nBiometric: 🔐 Authentication required\nBackup: ✅ Available\nApp access: 🔐 Requires biometric';
      case UnifiedAuthStatus.fullyAuthenticated:
        return 'Firebase: ✅ ${state.firebaseUser?.email}\nBiometric: ✅ Authenticated\nBackup: ✅ Available\nApp access: ✅ Full';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}