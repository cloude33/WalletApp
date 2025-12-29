import 'package:flutter/material.dart';
import '../services/unified_auth_service.dart';
import '../services/backup_service.dart';


class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final UnifiedAuthService _authService = UnifiedAuthService();
  final BackupService _backupService = BackupService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
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
          _statusMessage = '✅ Firebase signed in: ${state.firebaseUser?.email}';
          break;
        case UnifiedAuthStatus.firebaseAuthenticatedLocalRequired:
          _statusMessage = '🔐 Firebase OK, biometric required: ${state.firebaseUser?.email}';
          break;
        case UnifiedAuthStatus.fullyAuthenticated:
          _statusMessage = '✅ Fully authenticated: ${state.firebaseUser?.email}';
          break;
      }
    });
  }

  Future<void> _signInWithTestAccount() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '🔄 Test hesabı ile giriş yapılıyor...';
    });

    try {
      // Test hesabı bilgileri
      const testEmail = 'test@firebasebackup.com';
      const testPassword = 'TestPassword123!';
      
      // Önce giriş yapmayı dene
      var result = await _authService.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );

      if (!result.isSuccess) {
        // Hesap yoksa oluştur
        debugPrint('Test hesabı bulunamadı, oluşturuluyor...');
        result = await _authService.signUpWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
          displayName: 'Test User',
        );
      }

      setState(() {
        if (result.isSuccess) {
          _statusMessage = '✅ Test hesabı ile giriş başarılı';
          _checkAuthStatus();
        } else {
          _statusMessage = '❌ Test hesabı giriş hatası: ${result.errorMessage}';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Test hesabı giriş hatası: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithCustomAccount() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _statusMessage = '❌ E-posta ve şifre gerekli';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '🔄 Giriş yapılıyor...';
    });

    try {
      final result = await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() {
        if (result.isSuccess) {
          _statusMessage = '✅ Giriş başarılı';
          _checkAuthStatus();
        } else {
          _statusMessage = '❌ Giriş hatası: ${result.errorMessage}';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Giriş hatası: $e';
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
      _statusMessage = '🔄 Çıkış yapılıyor...';
    });

    try {
      await _authService.signOut();
      setState(() {
        _statusMessage = '✅ Çıkış yapıldı';
        _checkAuthStatus();
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Çıkış hatası: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testBackup() async {
    if (!_authService.currentState.canUseBackup) {
      setState(() {
        _statusMessage = '❌ Yedekleme için Firebase giriş gerekli';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '🔄 Test yedekleme yapılıyor...';
    });

    try {
      final success = await _backupService.uploadToCloud();
      setState(() {
        _statusMessage = success 
            ? '✅ Test yedekleme başarılı'
            : '❌ Test yedekleme başarısız';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Test yedekleme hatası: $e';
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
        title: const Text('Firebase Test'),
        backgroundColor: const Color(0xFF5E5CE6),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Durum kartı
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

            // Test hesabı ile giriş
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _signInWithTestAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.science),
              label: const Text('Test Hesabı ile Giriş Yap'),
            ),
            const SizedBox(height: 16),

            // Manuel giriş
            const Text(
              'Manuel Giriş:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Şifre',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _signInWithCustomAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.login),
              label: const Text('Giriş Yap'),
            ),
            const SizedBox(height: 24),

            // Test butonları
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testBackup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.backup),
              label: const Text('Test Yedekleme Yap'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _signOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış Yap'),
            ),
            const SizedBox(height: 24),

            // Firebase durumu
            StreamBuilder<UnifiedAuthState>(
              stream: _authService.authStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data ?? _authService.currentState;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: state.isFirebaseAuthenticated ? Colors.green.shade50 : Colors.red.shade50,
                    border: Border.all(
                      color: state.isFirebaseAuthenticated ? Colors.green : Colors.red,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Firebase Auth Durumu:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: state.isFirebaseAuthenticated ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.isFirebaseAuthenticated
                            ? 'Oturum Açık\nE-posta: ${state.firebaseUser!.email}\nUID: ${state.firebaseUser!.uid}\nDurum: ${state.status.name}\nYedekleme: ${state.canUseBackup ? "✅" : "❌"}'
                            : 'Oturum Kapalı\nYedekleme: ❌',
                        style: TextStyle(
                          fontSize: 12,
                          color: state.isFirebaseAuthenticated ? Colors.green.shade600 : Colors.red.shade600,
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}