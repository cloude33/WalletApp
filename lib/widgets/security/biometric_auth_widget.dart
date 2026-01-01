import 'package:flutter/material.dart';
import 'package:parion/services/auth/biometric_service.dart';
import 'package:parion/models/security/security_models.dart';

/// Biyometrik kimlik doğrulama widget'ı
///
/// Bu widget, kullanıcıdan biyometrik kimlik doğrulaması almak için kullanılır.
/// Farklı biyometrik türleri destekler ve özelleştirilebilir.
class BiometricAuthWidget extends StatefulWidget {
  /// Başarılı kimlik doğrulama callback'i
  final VoidCallback? onAuthSuccess;

  /// Başarısız kimlik doğrulama callback'i
  final ValueChanged<String>? onAuthFailure;

  /// PIN fallback callback'i
  final VoidCallback? onFallbackToPIN;

  /// Biyometrik servis (test için)
  final BiometricService? biometricService;

  /// Otomatik başlatma
  final bool autoStart;

  /// Başlık metni
  final String? title;

  /// Alt başlık metni
  final String? subtitle;

  /// Fallback buton metni
  final String? fallbackButtonText;

  /// İptal buton metni
  final String? cancelButtonText;

  /// Widget etkin mi?
  final bool enabled;

  /// Kompakt mod
  final bool compact;

  /// Icon boyutu
  final double iconSize;

  /// Animasyon süresi
  final Duration animationDuration;

  const BiometricAuthWidget({
    super.key,
    this.onAuthSuccess,
    this.onAuthFailure,
    this.onFallbackToPIN,
    this.biometricService,
    this.autoStart = false,
    this.title,
    this.subtitle,
    this.fallbackButtonText,
    this.cancelButtonText,
    this.enabled = true,
    this.compact = false,
    this.iconSize = 80.0,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<BiometricAuthWidget> createState() => _BiometricAuthWidgetState();
}

class _BiometricAuthWidgetState extends State<BiometricAuthWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;

  BiometricAuthState _authState = BiometricAuthState.idle;
  List<BiometricType> _availableBiometrics = [];
  String? _errorMessage;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkBiometricAvailability();

    // Otomatik başlatma istenmişse doğrulamayı başlat
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAuthentication();
      });
    }
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final service =
          widget.biometricService ?? BiometricServiceSingleton.instance;

      // Biyometrik doğrulama mevcut mu?
      final isAvailable = await service.isBiometricAvailable();
      setState(() {
        _isBiometricAvailable = isAvailable;
      });

      if (isAvailable) {
        // Mevcut biyometrik türleri al
        final availableTypes = await service.getAvailableBiometrics();
        setState(() {
          _availableBiometrics = availableTypes;
        });
      } else {
        setState(() {
          _authState = BiometricAuthState.notAvailable;
        });
      }
    } catch (e) {
      setState(() {
        _authState = BiometricAuthState.error;
        _errorMessage =
            'Biyometrik doğrulama kontrolü sırasında hata oluştu: ${e.toString()}';
      });
    }
  }

  Future<void> _startAuthentication() async {
    if (!_isBiometricAvailable || !widget.enabled) return;

    setState(() {
      _authState = BiometricAuthState.authenticating;
    });

    // Animasyonu başlat
    _animationController.repeat(reverse: true);

    try {
      final service =
          widget.biometricService ?? BiometricServiceSingleton.instance;

      final result = await service.authenticate(
        localizedFallbackTitle: widget.fallbackButtonText ?? 'PIN ile devam et',
        cancelButtonText: widget.cancelButtonText ?? 'İptal',
      );

      if (result.isSuccess) {
        // Başarılı doğrulama
        _animationController.stop();
        setState(() {
          _authState = BiometricAuthState.success;
        });

        // Başarı callback'i
        widget.onAuthSuccess?.call();
      } else {
        // Başarısız doğrulama
        _animationController.stop();
        _triggerShakeAnimation();

        setState(() {
          _authState = BiometricAuthState.failure;
          _errorMessage =
              result.errorMessage ?? 'Biyometrik doğrulama başarısız oldu';
        });

        // Hata callback'i
        widget.onAuthFailure?.call(_errorMessage!);
      }
    } catch (e) {
      _animationController.stop();
      _triggerShakeAnimation();

      setState(() {
        _authState = BiometricAuthState.error;
        _errorMessage = 'Beklenmeyen hata: ${e.toString()}';
      });

      // Hata callback'i
      widget.onAuthFailure?.call(_errorMessage!);
    }
  }

  void _triggerShakeAnimation() {
    _animationController.duration = const Duration(milliseconds: 500);
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  Future<void> _retryAuthentication() async {
    setState(() {
      _authState = BiometricAuthState.idle;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    _startAuthentication();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Biyometrik kimlik doğrulama',
      hint:
          'Mevcut biyometrik türler: ${_availableBiometrics.map((e) => e.displayName).join(', ')}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık ve alt başlık (kompakt modda gösterilmez)
          if (!widget.compact && widget.title != null) ...[
            Text(
              widget.title!,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],

          if (!widget.compact && widget.subtitle != null) ...[
            Text(
              widget.subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],

          // Mevcut biyometrik türler (birden fazlaysa)
          if (_availableBiometrics.length > 1) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableBiometrics.map((biometric) {
                return Chip(
                  label: Text(biometric.displayName),
                  avatar: Icon(_getBiometricIcon(biometric)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Ana içerik
          _buildMainContent(),

          const SizedBox(height: 24),

          // Fallback butonu (gerekiyorsa)
          if (widget.onFallbackToPIN != null) ...[
            TextButton.icon(
              onPressed: widget.enabled ? widget.onFallbackToPIN : null,
              icon: const Icon(Icons.pin),
              label: Text(widget.fallbackButtonText ?? 'PIN ile giriş'),
            ),
            const SizedBox(height: 8),
          ],

          // Tekrar dene butonu (başarısızlık durumunda)
          if (_authState == BiometricAuthState.failure ||
              _authState == BiometricAuthState.error) ...[
            ElevatedButton(
              onPressed: widget.enabled ? _retryAuthentication : null,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_authState) {
      case BiometricAuthState.idle:
      case BiometricAuthState.notAvailable:
        return _buildIdleView();
      case BiometricAuthState.authenticating:
        return _buildAuthenticatingView();
      case BiometricAuthState.success:
        return _buildSuccessView();
      case BiometricAuthState.failure:
        return _buildFailureView();
      case BiometricAuthState.error:
        return _buildErrorView();
    }
  }

  Widget _buildIdleView() {
    if (!_isBiometricAvailable) {
      return Column(
        children: [
          const Icon(Icons.block, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Biyometrik doğrulama kullanılamıyor',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      );
    }

    final primaryBiometric = _availableBiometrics.isNotEmpty
        ? _availableBiometrics.first
        : BiometricType.fingerprint;

    return Column(
      children: [
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Icon(
                _getBiometricIcon(primaryBiometric),
                size: widget.iconSize,
                color: Colors.blue,
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          _getBiometricMessage(primaryBiometric),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: widget.enabled ? _startAuthentication : null,
          child: Text(widget.compact ? 'Doğrula' : 'Biyometrik Doğrulama'),
        ),
      ],
    );
  }

  Widget _buildAuthenticatingView() {
    final primaryBiometric = _availableBiometrics.isNotEmpty
        ? _availableBiometrics.first
        : BiometricType.fingerprint;

    return Column(
      children: [
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Icon(
                _getBiometricIcon(primaryBiometric),
                size: widget.iconSize,
                color: Colors.blue,
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Kimliğiniz doğrulanıyor...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        const Icon(Icons.check_circle, size: 80, color: Colors.green),
        const SizedBox(height: 16),
        const Text(
          'Kimlik doğrulama başarılı!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildFailureView() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(10 * (_shakeAnimation.value - 0.5) * 2, 0),
          child: Column(
            children: [
              const Icon(Icons.error, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Kimlik doğrulama başarısız!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorView() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(10 * (_shakeAnimation.value - 0.5) * 2, 0),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Bir hata oluştu!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Biyometrik türe göre uygun ikonu döndürür
  IconData _getBiometricIcon(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return Icons.fingerprint;
      case BiometricType.face:
        return Icons.face_unlock_outlined;
      case BiometricType.voice:
        return Icons.record_voice_over_outlined;
      case BiometricType.iris:
        return Icons.remove_red_eye_outlined;
    }
  }

  /// Biyometrik türe göre uygun mesajı döndürür
  String _getBiometricMessage(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return widget.compact
            ? 'Parmak izinizi taratın'
            : 'Devam etmek için parmak izinizi taratın';
      case BiometricType.face:
        return widget.compact
            ? 'Yüzünüzü taratın'
            : 'Devam etmek için yüzünüzü taratın';
      case BiometricType.voice:
        return widget.compact
            ? 'Sesinizi tanıtın'
            : 'Devam etmek için sesinizi tanıtın';
      case BiometricType.iris:
        return widget.compact
            ? 'İrisinizi taratın'
            : 'Devam etmek için irisinizi taratın';
    }
  }
}

/// Biyometrik kimlik doğrulama durumlarını tanımlayan enum
enum BiometricAuthState {
  /// Başlangıç durumu
  idle,

  /// Kimlik doğrulama yapılıyor
  authenticating,

  /// Kimlik doğrulama başarılı
  success,

  /// Kimlik doğrulama başarısız
  failure,

  /// Hata oluştu
  error,

  /// Biyometrik doğrulama kullanılamıyor
  notAvailable,
}

/// Biyometrik kimlik doğrulama temasını tanımlayan sınıf
class BiometricAuthTheme {
  /// Icon boyutu
  final double iconSize;

  /// Animasyon süresi
  final Duration animationDuration;

  const BiometricAuthTheme({
    required this.iconSize,
    required this.animationDuration,
  });

  /// Varsayılan tema
  static const BiometricAuthTheme defaultTheme = BiometricAuthTheme(
    iconSize: 80.0,
    animationDuration: Duration(milliseconds: 300),
  );

  /// Kompakt tema
  static const BiometricAuthTheme compactTheme = BiometricAuthTheme(
    iconSize: 60.0,
    animationDuration: Duration(milliseconds: 200),
  );

  /// Büyük tema
  static const BiometricAuthTheme largeTheme = BiometricAuthTheme(
    iconSize: 100.0,
    animationDuration: Duration(milliseconds: 400),
  );
}
