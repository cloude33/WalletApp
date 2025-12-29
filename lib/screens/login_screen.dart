import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/user_service.dart';
import '../services/app_lock_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
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
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();
  final FirestoreService _firestore = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isBiometricAvailable = false;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _rememberMe = false;
  String? _userName;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkBiometricAndPin();
    _loadRememberedEmail();
    _loadUserName();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  Future<void> _loadRememberedEmail() async {
    final userService = UserService();
    final rememberedEmail = await userService.getRememberedEmail();
    final shouldRemember = await userService.shouldRememberEmail();

    if (rememberedEmail != null && shouldRemember) {
      setState(() {
        _emailController.text = rememberedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _loadUserName() async {
    try {
      final users = await _dataService.getAllUsers();
      if (users.isNotEmpty) {
        final rememberedEmail = _emailController.text.trim();
        final user = rememberedEmail.isNotEmpty
            ? users.firstWhere(
                (u) => u.email == rememberedEmail,
                orElse: () => users.first,
              )
            : users.first;

        if (mounted) {
          setState(() {
            _userName = user.name;
          });
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
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
    final enabled = await _authService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _isBiometricAvailable = available && enabled;
      });
    }
  }

  Future<void> _handleBiometricAuth() async {
    try {
      final authenticated = await _authService.authenticateWithBiometric();
      if (authenticated && mounted) {
        _navigateToApp();
      } else if (!authenticated && mounted) {}
    } on PlatformException catch (e) {
      if (mounted) {
        if (e.code == 'LockedOut') {
          _showError(
            'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.',
          );
        } else if (e.code == 'PermanentlyLockedOut') {
          _showError(
            'Biyometrik doğrulama kalıcı olarak kilitlendi. Lütfen şifre kullanın.',
          );
        } else if (e.code == 'NotEnrolled') {
          _showError('Cihazınızda biyometrik doğrulama ayarlanmamış.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Biyometrik doğrulama sırasında bir hata oluştu');
      }
    }
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Firebase Authentication ile giriş yap
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (credential?.user != null) {
        // Kullanıcı bilgilerini kaydet
        final userService = UserService();
        if (_rememberMe) {
          await userService.saveRememberedEmail(_emailController.text.trim());
          await userService.setRememberEmail(true);
        } else {
          await userService.clearRememberedEmail();
          await userService.setRememberEmail(false);
        }

        if (mounted) {
          _navigateToApp();
        }
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
      final credential = await _firebaseAuth.signInWithGoogle();
      if (credential?.user != null && mounted) {
        // Kullanıcı profilini Firestore'da oluştur/güncelle
        await _firestore.createUserProfile(
          uid: credential!.user!.uid,
          email: credential.user!.email!,
          displayName: credential.user!.displayName ?? 'Kullanıcı',
        );
        _navigateToApp();
      }
    } catch (e) {
      if (mounted) {
        _showError('Google ile giriş başarısız: ${e.toString()}');
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
      await Future.delayed(const Duration(seconds: 1));
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

  Future<void> _handleForgotPassword() async {
    final emailController = TextEditingController();
    if (_emailController.text.isNotEmpty) {
      emailController.text = _emailController.text;
    }

    return showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Şifre Sıfırlama'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'E-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Geçerli bir e-posta adresi girin'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                setState(() => _isLoading = true);

                try {
                  await _firebaseAuth.sendPasswordResetEmail(email);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Şifre sıfırlama bağlantısı $email adresine gönderildi',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
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
              },
              child: const Text('Gönder'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToApp() {
    AppLockService().unlock();
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
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'E-posta',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFDB32A),
                  width: 2,
                ),
              ),
              prefixIcon: Icon(
                Icons.email,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) async {
              if (value.contains('@')) {
                try {
                  final users = await _dataService.getAllUsers();
                  final user = users.firstWhere(
                    (u) => u.email == value.trim(),
                    orElse: () =>
                        users.isNotEmpty ? users.first : throw Exception(),
                  );
                  if (mounted) {
                    setState(() {
                      _userName = user.name;
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      _userName = null;
                    });
                  }
                }
              }
            },
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
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Şifre',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFDB32A),
                  width: 2,
                ),
              ),
              prefixIcon: Icon(
                Icons.lock,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white.withValues(alpha: 0.7),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFFFDB32A),
                    checkColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    'Beni Hatırla',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _isLoading ? null : _handleForgotPassword,
                child: const Text(
                  'Şifremi Unuttum',
                  style: TextStyle(color: Color(0xFFFDB32A)),
                ),
              ),
            ],
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
          Text(
            'veya',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: Image.asset(
                    'assets/images/google-logo.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.g_mobiledata,
                        size: 24,
                        color: Colors.white,
                      );
                    },
                  ),
                  label: const Text(
                    'Google',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
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
                  icon: const Icon(Icons.apple, size: 24, color: Colors.white),
                  label: const Text(
                    'Apple',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isBiometricAvailable) _buildBiometricButton(),

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
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
            color: Colors.white.withValues(alpha: 0.1),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.fingerprint,
              size: 40,
              color: Color(0xFFFDB32A),
            ),
            onPressed: _handleBiometricAuth,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Parmak İzi ile Giriş',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0f2027),
                    const Color(0xFF203a43),
                    const Color(0xFF2c5364),
                  ]
                : [
                    const Color(0xFF0f2027),
                    const Color(0xFF203a43),
                    const Color(0xFF2c5364),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Image.asset(
                        'assets/icon/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.account_balance_wallet,
                            size: 110,
                            color: Color(0xFFFDB32A),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    _userName != null ? 'Hoş Geldin' : 'Hoş Geldiniz',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_userName != null) ...[
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      _userName!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFDB32A),
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Hesabınıza giriş yapın',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildLoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
