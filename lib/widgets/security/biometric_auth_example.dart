import 'package:flutter/material.dart';
import 'biometric_auth_widget.dart';

/// Biyometrik kimlik doğrulama widget'ı kullanım örneği
///
/// Bu dosya BiometricAuthWidget'ın nasıl kullanılacağını gösterir.
class BiometricAuthExample extends StatefulWidget {
  const BiometricAuthExample({super.key});

  @override
  State<BiometricAuthExample> createState() => _BiometricAuthExampleState();
}

class _BiometricAuthExampleState extends State<BiometricAuthExample> {
  String _statusMessage = 'Biyometrik doğrulama bekleniyor...';
  bool _isAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biyometrik Doğrulama Örneği')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Durum göstergesi
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isAuthenticated
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isAuthenticated ? Icons.check_circle : Icons.info,
                      size: 48,
                      color: _isAuthenticated ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Biyometrik doğrulama widget'ı
              BiometricAuthWidget(
                title: 'Güvenli Giriş',
                subtitle: 'Devam etmek için kimliğinizi doğrulayın',
                onAuthSuccess: () {
                  setState(() {
                    _isAuthenticated = true;
                    _statusMessage = 'Kimlik doğrulama başarılı!';
                  });

                  // Başarılı giriş sonrası işlemler
                  _showSuccessDialog();
                },
                onAuthFailure: (error) {
                  setState(() {
                    _isAuthenticated = false;
                    _statusMessage = 'Hata: $error';
                  });

                  // Hata mesajı göster
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                },
                onFallbackToPIN: () {
                  // PIN giriş ekranına yönlendir
                  Navigator.of(context).pushNamed('/pin-login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Başarı dialogunu gösterir
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Başarılı'),
        content: const Text('Kimlik doğrulama başarıyla tamamlandı!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}

/// Kompakt mod örneği
class BiometricAuthCompactExample extends StatelessWidget {
  const BiometricAuthCompactExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kompakt Mod Örneği')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: BiometricAuthWidget(
            compact: true,
            autoStart: true,
            onAuthSuccess: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kimlik doğrulama başarılı!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onAuthFailure: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hata: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Otomatik başlatma örneği
class BiometricAuthAutoStartExample extends StatelessWidget {
  const BiometricAuthAutoStartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Otomatik Başlatma Örneği')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: BiometricAuthWidget(
            title: 'Hızlı Giriş',
            subtitle: 'Biyometrik doğrulama otomatik olarak başlatılıyor...',
            autoStart: true,
            fallbackButtonText: 'PIN ile devam et',
            cancelButtonText: 'İptal',
            onAuthSuccess: () {
              // Ana ekrana yönlendir
              Navigator.of(context).pushReplacementNamed('/home');
            },
            onAuthFailure: (error) {
              // Hata durumunda kullanıcıya bilgi ver
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(error)));
            },
            onFallbackToPIN: () {
              // PIN giriş ekranına yönlendir
              Navigator.of(context).pushReplacementNamed('/pin-login');
            },
          ),
        ),
      ),
    );
  }
}

/// Özel tema örneği
class BiometricAuthCustomThemeExample extends StatelessWidget {
  const BiometricAuthCustomThemeExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Özel Tema Örneği')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: BiometricAuthWidget(
            title: 'Özel Tasarım',
            subtitle: 'Özelleştirilmiş biyometrik doğrulama',
            iconSize: 100.0,
            animationDuration: const Duration(milliseconds: 400),
            onAuthSuccess: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Başarılı!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
