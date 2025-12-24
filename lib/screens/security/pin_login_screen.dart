import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../services/auth/pin_service.dart';
import '../../models/security/security_models.dart';

/// PIN giriş ekranı
/// 
/// Bu ekran kullanıcının PIN kodu ile kimlik doğrulaması yapmasını sağlar.
/// Deneme sayacı gösterimi, kilitleme durumu ve hata yönetimi içerir.
/// 
/// Implements Requirement 1.3: Şifrelenmiş PIN ile karşılaştırma yapmalı
/// Implements Requirement 1.4: PIN başarıyla doğrulandığında kullanıcı oturumu başlatmalı
/// Implements Requirement 2.5: Hesap kilitliyken kalan süreyi kullanıcıya göstermeli
class PINLoginScreen extends StatefulWidget {
  /// Başarılı giriş sonrası çağrılacak callback
  final VoidCallback? onSuccess;
  
  /// İptal edildiğinde çağrılacak callback
  final VoidCallback? onCancel;
  
  /// Biyometrik giriş seçeneği gösterilsin mi?
  final bool showBiometricOption;
  
  /// Ekran başlığı
  final String? title;

  const PINLoginScreen({
    super.key,
    this.onSuccess,
    this.onCancel,
    this.showBiometricOption = false,
    this.title,
  });

  @override
  State<PINLoginScreen> createState() => _PINLoginScreenState();
}

class _PINLoginScreenState extends State<PINLoginScreen> {
  final PINService _pinService = PINService();
  
  String _pin = '';
  bool _isLoading = false;
  String? _errorMessage;
  int _failedAttempts = 0;
  int _remainingAttempts = 0;
  bool _isLocked = false;
  Duration? _lockoutDuration;
  
  Timer? _lockoutTimer;
  Timer? _countdownTimer;
  
  @override
  void initState() {
    super.initState();
    _initializePINService();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializePINService() async {
    try {
      await _pinService.initialize();
      await _updateSecurityStatus();
    } catch (e) {
      setState(() {
        _errorMessage = 'PIN servisi başlatılamadı: ${e.toString()}';
      });
    }
  }

  /// Güvenlik durumunu günceller
  Future<void> _updateSecurityStatus() async {
    try {
      final failedAttempts = await _pinService.getFailedAttempts();
      final isLocked = await _pinService.isLocked();
      final lockoutDuration = await _pinService.getRemainingLockoutTime();
      
      setState(() {
        _failedAttempts = failedAttempts;
        _remainingAttempts = 10 - failedAttempts; // Max attempts is 10
        _isLocked = isLocked;
        _lockoutDuration = lockoutDuration;
      });
      
      if (isLocked && lockoutDuration != null) {
        _startLockoutCountdown();
      }
    } catch (e) {
      debugPrint('Failed to update security status: $e');
    }
  }

  /// Kilitleme geri sayımını başlatır
  void _startLockoutCountdown() {
    _countdownTimer?.cancel();
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      _updateSecurityStatus();
      
      if (!_isLocked) {
        timer.cancel();
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.title ?? 'PIN Girişi',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        leading: widget.onCancel != null
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onCancel,
              )
            : null,
        automaticallyImplyLeading: widget.onCancel == null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 200,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isLocked ? Colors.red[100] : Colors.blue[100],
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    _isLocked ? Icons.lock : Icons.lock_outline,
                    size: 40,
                    color: _isLocked ? Colors.red[700] : Colors.blue[700],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Title
                Text(
                  _isLocked ? 'Hesap Kilitli' : 'PIN Kodunuzu Girin',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  _isLocked 
                      ? 'Çok fazla yanlış deneme yapıldı. Lütfen bekleyin.'
                      : 'Uygulamanıza erişmek için PIN kodunuzu girin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Security Status
                if (_failedAttempts > 0 || _isLocked) ...[
                  _buildSecurityStatus(),
                  const SizedBox(height: 24),
                ],
                
                // PIN Input
                if (!_isLocked) ...[
                  _PINInputWidget(
                    pin: _pin,
                    onChanged: (pin) {
                      setState(() {
                        _pin = pin;
                        _errorMessage = null;
                      });
                      
                      // Auto-verify when PIN is complete
                      if (pin.length >= 4) {
                        _verifyPIN();
                      }
                    },
                    maxLength: 6,
                    obscureText: true,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 32),
                ],
                
                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Loading indicator
                if (_isLoading) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                ],
                
                const SizedBox(height: 40),
                
                // Biometric option
                if (widget.showBiometricOption && !_isLocked) ...[
                  TextButton.icon(
                    onPressed: _useBiometric,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Biyometrik Giriş Kullan'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Forgot PIN option
                if (!_isLocked) ...[
                  TextButton(
                    onPressed: _forgotPIN,
                    child: Text(
                      'PIN\'imi Unuttum',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Güvenlik durumu widget'ı
  Widget _buildSecurityStatus() {
    if (_isLocked && _lockoutDuration != null) {
      return _buildLockoutStatus();
    } else if (_failedAttempts > 0) {
      return _buildAttemptCounter();
    }
    
    return const SizedBox.shrink();
  }

  /// Kilitleme durumu widget'ı
  Widget _buildLockoutStatus() {
    final duration = _lockoutDuration!;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.timer,
            color: Colors.red[600],
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Kalan Süre',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hesabınız geçici olarak kilitlendi',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Deneme sayacı widget'ı
  Widget _buildAttemptCounter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: Colors.orange[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Başarısız Deneme: $_failedAttempts',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kalan hak: $_remainingAttempts',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// PIN doğrulaması yapar
  Future<void> _verifyPIN() async {
    if (_pin.length < 4 || _isLoading || _isLocked) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final result = await _pinService.verifyPIN(_pin);
      
      if (result.isSuccess) {
        // Başarılı doğrulama
        _showSuccessAnimation();
        
        // Callback'i çağır
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else if (mounted) {
          // Navigate to login screen (user selection)
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      } else {
        // Başarısız doğrulama
        _handleVerificationFailure(result);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Beklenmeyen bir hata oluştu: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _pin = ''; // PIN'i temizle
        });
      }
    }
  }

  /// Doğrulama başarısızlığını işler
  void _handleVerificationFailure(AuthResult result) {
    setState(() {
      _errorMessage = result.errorMessage;
    });
    
    // Güvenlik durumunu güncelle
    _updateSecurityStatus();
    
    // Haptic feedback
    HapticFeedback.heavyImpact();
    
    // Kilitleme durumu varsa countdown başlat
    if (result.lockoutDuration != null) {
      _startLockoutCountdown();
    }
  }

  /// Başarı animasyonu gösterir
  void _showSuccessAnimation() {
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // Success animation could be added here
    // For now, just show a brief success state
    setState(() {
      _errorMessage = null;
    });
  }

  /// Biyometrik giriş kullanır
  void _useBiometric() {
    // TODO: Implement biometric authentication
    // This will be implemented in the biometric service task
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Biyometrik giriş henüz kullanılamıyor'),
      ),
    );
  }

  /// PIN unutma işlemi
  void _forgotPIN() {
    Navigator.of(context).pushNamed('/pin-recovery');
  }
}

/// PIN giriş widget'ı
class _PINInputWidget extends StatefulWidget {
  final String pin;
  final ValueChanged<String> onChanged;
  final int maxLength;
  final bool obscureText;
  final bool enabled;

  const _PINInputWidget({
    required this.pin,
    required this.onChanged,
    this.maxLength = 6,
    this.obscureText = false,
    this.enabled = true,
  });

  @override
  State<_PINInputWidget> createState() => _PINInputWidgetState();
}

class _PINInputWidgetState extends State<_PINInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.pin;
    
    // Otomatik focus
    if (widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(_PINInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pin != widget.pin) {
      _controller.text = widget.pin;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PIN dots display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.maxLength, (index) {
            final bool isFilled = index < widget.pin.length;
            final bool isActive = index == widget.pin.length && widget.enabled;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled
                    ? (widget.enabled ? Colors.blue[700] : Colors.grey[500])
                    : (isActive ? Colors.blue[300] : Colors.grey[300]),
                border: Border.all(
                  color: isActive ? Colors.blue[700]! : Colors.transparent,
                  width: 2,
                ),
              ),
            );
          }),
        ),
        
        const SizedBox(height: 32),
        
        // Hidden text field for input
        SizedBox(
          width: 1,
          height: 1,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(widget.maxLength),
            ],
            onChanged: widget.onChanged,
            style: const TextStyle(color: Colors.transparent),
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
            ),
            obscureText: widget.obscureText,
          ),
        ),
        
        // Number pad
        _buildNumberPad(),
      ],
    );
  }

  /// Sayı tuş takımı
  Widget _buildNumberPad() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        children: [
          // First row: 1, 2, 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('1'),
              _buildNumberButton('2'),
              _buildNumberButton('3'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Second row: 4, 5, 6
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('4'),
              _buildNumberButton('5'),
              _buildNumberButton('6'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Third row: 7, 8, 9
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('7'),
              _buildNumberButton('8'),
              _buildNumberButton('9'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Fourth row: empty, 0, backspace
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 60, height: 60), // Empty space
              _buildNumberButton('0'),
              _buildBackspaceButton(),
            ],
          ),
        ],
      ),
    );
  }

  /// Sayı butonu
  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: widget.enabled ? () => _onNumberPressed(number) : null,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: widget.enabled ? Colors.grey[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: widget.enabled ? Colors.grey[300]! : Colors.grey[400]!,
          ),
        ),
        child: Center(
          child: Text(
            number,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: widget.enabled ? Colors.grey[800] : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }

  /// Silme butonu
  Widget _buildBackspaceButton() {
    return GestureDetector(
      onTap: widget.enabled ? _onBackspacePressed : null,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: widget.enabled ? Colors.grey[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: widget.enabled ? Colors.grey[300]! : Colors.grey[400]!,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 24,
            color: widget.enabled ? Colors.grey[600] : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  /// Sayı tuşuna basıldığında
  void _onNumberPressed(String number) {
    if (widget.pin.length < widget.maxLength) {
      final newPin = widget.pin + number;
      widget.onChanged(newPin);
      
      // Haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  /// Silme tuşuna basıldığında
  void _onBackspacePressed() {
    if (widget.pin.isNotEmpty) {
      final newPin = widget.pin.substring(0, widget.pin.length - 1);
      widget.onChanged(newPin);
      
      // Haptic feedback
      HapticFeedback.lightImpact();
    }
  }
}