import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/auth_service.dart';
import '../services/data_service.dart';
import 'pin_setup_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final DataService _dataService = DataService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isBiometricAvailable = false;
  bool _hasPinCode = false;
  bool _hasExistingData = false;
  bool _isLoading = false;
  bool _showPassword = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkBiometricAndPin();
    _checkExistingData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAndPin() async {
    final available = await _authService.isBiometricAvailable();
    final hasPin = await _authService.hasPinCode();
    if (mounted) {
      setState(() {
        _isBiometricAvailable = available;
        _hasPinCode = hasPin;
      });
    }
  }

  Future<void> _checkExistingData() async {
    try {
      final users = await _dataService.getAllUsers();
      final hasPin = await _authService.hasPinCode();
      final authMethod = await _authService.getCurrentAuthMethod();
      final hasGoogle = authMethod == 'google';
      final hasFacebook = authMethod == 'facebook';

      if (mounted) {
        setState(() {
          _hasExistingData =
              users.isNotEmpty || hasPin || hasGoogle || hasFacebook;
        });
      }
    } catch (e) {
      debugPrint('Error checking existing data: $e');
    }
  }

  Future<void> _handleBiometricAuth() async {
    try {
      final authenticated = await _authService.authenticateWithBiometric();
      if (authenticated && mounted) {
        _navigateToApp();
      }
    } on PlatformException catch (e) {
      if (mounted) {
        _showError(e.message ?? 'Biyometrik doğrulama başarısız');
      }
    }
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final users = await _dataService.getAllUsers();
      final user = users.firstWhere(
        (u) => u.email == _emailController.text.trim(),
        orElse: () => throw Exception('Kullanıcı bulunamadı'),
      );

      // Verify password (in production, use proper password hashing)
      // For now, we'll just navigate to app
      if (mounted) {
        _navigateToApp();
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final account = await _authService.signInWithGoogle();
      if (account != null && mounted) {
        _navigateToApp();
      }
    } catch (e) {
      if (mounted) {
        _showError('Google ile giriş başarısız');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Implement Apple Sign In
      await Future.delayed(const Duration(seconds: 1)); // Simülasyon
      if (mounted) {
        _showError('Apple ile giriş henüz aktif değil');
      }
    } catch (e) {
      if (mounted) {
        _showError('Apple ile giriş başarısız');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'E-posta',
              labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFDB32A), width: 2),
              ),
              prefixIcon: const Icon(Icons.email, color: Color(0xFF8E8E93)),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen e-posta adresinizi girin';
              }
              if (!value.contains('@')) {
                return 'Geçerli bir e-posta adresi girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Şifre',
              labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFDB32A), width: 2),
              ),
              prefixIcon: const Icon(Icons.lock, color: Color(0xFF8E8E93)),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF8E8E93),
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
            ),
            obscureText: !_showPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen şifrenizi girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Implement password reset
              },
              child: const Text(
                'Şifremi Unuttum',
                style: TextStyle(color: Color(0xFFFDB32A)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleEmailLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDB32A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Giriş Yap',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'veya',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF8E8E93)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: const Icon(Icons.g_mobiledata, size: 24, color: Color(0xFF1C1C1E)),
                  label: const Text(
                    'Google',
                    style: TextStyle(color: Color(0xFF1C1C1E)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFE5E5EA)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleAppleSignIn,
                  icon: const Icon(Icons.apple, size: 24, color: Color(0xFF1C1C1E)),
                  label: const Text(
                    'Apple',
                    style: TextStyle(color: Color(0xFF1C1C1E)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFE5E5EA)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isBiometricAvailable && _hasPinCode) _buildBiometricButton(),
          if (_hasPinCode) _buildPinLoginButton(),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              );
            },
            child: const Text(
              'Hesabınız yok mu? Kayıt olun',
              style: TextStyle(color: Color(0xFFFDB32A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricButton() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
          ),
          child: IconButton(
            icon: const Icon(Icons.fingerprint, size: 40, color: Color(0xFFFDB32A)),
            onPressed: _handleBiometricAuth,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Parmak İzi ile Giriş',
          style: TextStyle(color: Color(0xFF8E8E93)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPinLoginButton() {
    return TextButton.icon(
      onPressed: () {
        // TODO: Implement PIN login
      },
      icon: const Icon(Icons.dialpad, size: 20, color: Color(0xFF8E8E93)),
      label: const Text(
        'PIN Kodu ile Giriş Yap',
        style: TextStyle(color: Color(0xFF8E8E93)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo/Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDB32A).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 60,
                  color: Color(0xFFFDB32A),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Hoş Geldiniz',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Hesabınıza giriş yapın',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildLoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}
