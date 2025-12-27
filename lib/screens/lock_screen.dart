import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/app_lock_service.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final AppLockService _lockService = AppLockService();
  final _passwordController = TextEditingController();

  bool _showPassword = false;
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkBiometric();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _userService.getUserProfile();
    if (mounted) {
      setState(() => _userProfile = profile);
    }
  }

  Future<void> _checkBiometric() async {
    final available = await _authService.isBiometricAvailable();
    final enabled = await _authService.isBiometricEnabled();
    if (mounted) {
      setState(() => _isBiometricAvailable = available && enabled);
    }
    if (available && enabled && mounted) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _handleBiometricAuth();
        }
      });
    }
  }

  Future<void> _handleBiometricAuth() async {
    try {
      final authenticated = await _authService.authenticateWithBiometric();
      if (authenticated && mounted) {
        _unlock();
      } else if (!authenticated && mounted) {
      }
    } on PlatformException catch (e) {
      if (mounted) {
        if (e.code == 'LockedOut') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        } else if (e.code == 'PermanentlyLockedOut') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biyometrik doğrulama kalıcı olarak kilitlendi. Lütfen PIN kullanın.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        } else if (e.code == 'NotEnrolled') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cihazınızda biyometrik doğrulama ayarlanmamış.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biyometrik doğrulama sırasında bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePasswordAuth() async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen şifrenizi girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isValid = await _userService.verifyPassword(
        _userProfile!.email,
        _passwordController.text,
      );

      if (isValid) {
        _unlock();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Şifre hatalı'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _unlock() {
    _lockService.unlock();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)]
                : [
                    const Color(0xFFFDB32A).withValues(alpha: 0.1),
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDB32A).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 80,
                      color: Color(0xFFFDB32A),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Uygulama Kilitli',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_userProfile != null)
                    Text(
                      'Hoş geldiniz, ${_userProfile!.name}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 32),
                  if (_isBiometricAvailable) ...[
                    IconButton(
                      onPressed: _handleBiometricAuth,
                      icon: const Icon(Icons.fingerprint),
                      iconSize: 64,
                      color: const Color(0xFFFDB32A),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Parmak izi ile kilidi aç',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'veya',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                        ),
                      ),
                      obscureText: !_showPassword,
                      onSubmitted: (_) => _handlePasswordAuth(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 300,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handlePasswordAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDB32A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Kilidi Aç',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
