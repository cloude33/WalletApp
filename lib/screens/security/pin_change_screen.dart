import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth/pin_service.dart';

/// PIN değiştirme ekranı
/// 
/// Bu ekran kullanıcının mevcut PIN kodunu değiştirmesini sağlar.
/// Mevcut PIN doğrulama, yeni PIN kurulum akışı ve başarı/hata mesajları içerir.
/// 
/// Implements Requirement 7.2: PIN değiştirme seçildiğinde mevcut PIN doğrulaması gerektirmeli
class PINChangeScreen extends StatefulWidget {
  const PINChangeScreen({super.key});

  @override
  State<PINChangeScreen> createState() => _PINChangeScreenState();
}

class _PINChangeScreenState extends State<PINChangeScreen> {
  final PINService _pinService = PINService();
  final PageController _pageController = PageController();
  
  String _currentPIN = '';
  String _newPIN = '';
  String _confirmPIN = '';
  bool _isLoading = false;
  String? _errorMessage;
  
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _initializePINService();
  }

  Future<void> _initializePINService() async {
    try {
      await _pinService.initialize();
    } catch (e) {
      setState(() {
        _errorMessage = 'PIN servisi başlatılamadı: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'PIN Değiştir',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _goToPreviousPage,
              )
            : IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / 3,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            ),
          ),
          
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildCurrentPINPage(),
                _buildNewPINPage(),
                _buildConfirmPINPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mevcut PIN doğrulama sayfası
  Widget _buildCurrentPINPage() {
    return SingleChildScrollView(
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
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.lock_reset,
                size: 40,
                color: Colors.orange[700],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              'Mevcut PIN\'inizi Girin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              'PIN kodunuzu değiştirmek için önce mevcut PIN\'inizi doğrulayın.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // PIN Input
            _PINInputWidget(
              pin: _currentPIN,
              onChanged: (pin) {
                setState(() {
                  _currentPIN = pin;
                  _errorMessage = null;
                });
              },
              maxLength: 6,
              obscureText: true,
            ),
            
            const SizedBox(height: 32),
            
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
            
            const SizedBox(height: 40),
            
            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _currentPIN.length >= 4 ? _verifyCurrentPIN : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Doğrula',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Yeni PIN giriş sayfası
  Widget _buildNewPINPage() {
    return SingleChildScrollView(
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
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.lock_outline,
                size: 40,
                color: Colors.blue[700],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              'Yeni PIN Kodu Oluşturun',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              'Güvenliğiniz için yeni bir PIN kodu oluşturun.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // PIN Input
            _PINInputWidget(
              pin: _newPIN,
              onChanged: (pin) {
                setState(() {
                  _newPIN = pin;
                  _errorMessage = null;
                });
              },
              maxLength: 6,
              obscureText: true,
            ),
            
            const SizedBox(height: 24),
            
            // PIN Strength Indicator
            if (_newPIN.isNotEmpty) ...[
              _PINStrengthIndicator(pin: _newPIN),
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
            
            const SizedBox(height: 40),
            
            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _newPIN.length >= 4 ? _goToConfirmPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Devam Et',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// PIN onay sayfası
  Widget _buildConfirmPINPage() {
    return SingleChildScrollView(
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
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 40,
                color: Colors.green[700],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              'Yeni PIN\'i Onaylayın',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              'Güvenlik için yeni PIN kodunuzu tekrar girin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // PIN Input
            _PINInputWidget(
              pin: _confirmPIN,
              onChanged: (pin) {
                setState(() {
                  _confirmPIN = pin;
                  _errorMessage = null;
                });
              },
              maxLength: 6,
              obscureText: true,
            ),
            
            const SizedBox(height: 24),
            
            // Match indicator
            if (_confirmPIN.isNotEmpty) ...[
              _buildMatchIndicator(),
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
            
            const SizedBox(height: 40),
            
            // Change PIN Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _canChangePIN() ? _changePIN : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'PIN\'i Değiştir',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// PIN eşleşme göstergesi
  Widget _buildMatchIndicator() {
    final bool matches = _newPIN == _confirmPIN;
    final bool isComplete = _confirmPIN.length >= 4;
    
    if (!isComplete) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: matches ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: matches ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            matches ? Icons.check_circle : Icons.error,
            color: matches ? Colors.green[600] : Colors.red[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            matches ? 'PIN kodları eşleşiyor' : 'PIN kodları eşleşmiyor',
            style: TextStyle(
              color: matches ? Colors.green[700] : Colors.red[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// PIN değiştirme yapılabilir mi kontrol eder
  bool _canChangePIN() {
    return _newPIN.length >= 4 &&
           _confirmPIN.length >= 4 &&
           _newPIN == _confirmPIN &&
           !_isLoading;
  }

  /// Mevcut PIN'i doğrular
  Future<void> _verifyCurrentPIN() async {
    if (_currentPIN.length < 4 || _isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final result = await _pinService.verifyPIN(_currentPIN);
      
      if (result.isSuccess) {
        // Başarılı doğrulama - yeni PIN sayfasına geç
        _goToNewPINPage();
      } else {
        // Hata durumu
        setState(() {
          _errorMessage = result.errorMessage ?? 'Mevcut PIN yanlış';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Beklenmeyen bir hata oluştu: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Yeni PIN sayfasına geçer
  void _goToNewPINPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Onay sayfasına geçer
  void _goToConfirmPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Önceki sayfaya geçer
  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// PIN değiştirme işlemini yapar
  Future<void> _changePIN() async {
    if (!_canChangePIN()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final result = await _pinService.changePIN(_currentPIN, _newPIN);
      
      if (result.isSuccess) {
        // Başarılı değiştirme
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        // Hata durumu
        setState(() {
          _errorMessage = result.errorMessage ?? 'PIN değiştirme başarısız oldu';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Beklenmeyen bir hata oluştu: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Başarı dialog'unu gösterir
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.check,
                size: 30,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'PIN Başarıyla Değiştirildi!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'PIN kodunuz güvenli bir şekilde güncellendi. Yeni PIN kodunuzla uygulamanıza erişebilirsiniz.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dialog'u kapat
                  Navigator.of(context).pop(true); // Screen'i kapat ve başarı döndür
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tamam',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// PIN giriş widget'ı
class _PINInputWidget extends StatefulWidget {
  final String pin;
  final ValueChanged<String> onChanged;
  final int maxLength;
  final bool obscureText;

  const _PINInputWidget({
    required this.pin,
    required this.onChanged,
    this.maxLength = 6,
    this.obscureText = false,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
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
            final bool isActive = index == widget.pin.length;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled
                    ? Colors.blue[700]
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
      onTap: () => _onNumberPressed(number),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            number,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
      ),
    );
  }

  /// Silme butonu
  Widget _buildBackspaceButton() {
    return GestureDetector(
      onTap: _onBackspacePressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 24,
            color: Colors.grey[600],
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

/// PIN güçlülük göstergesi
class _PINStrengthIndicator extends StatelessWidget {
  final String pin;

  const _PINStrengthIndicator({required this.pin});

  @override
  Widget build(BuildContext context) {
    final PINService pinService = PINService();
    final int strength = pinService.checkPINStrength(pin);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'PIN Güçlülüğü: ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _getStrengthText(strength),
              style: TextStyle(
                fontSize: 14,
                color: _getStrengthColor(strength),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Progress bar
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: strength / 100,
            child: Container(
              decoration: BoxDecoration(
                color: _getStrengthColor(strength),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Strength tips
        if (strength < 80) ...[
          Text(
            _getStrengthTip(strength),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  String _getStrengthText(int strength) {
    if (strength >= 80) return 'Güçlü';
    if (strength >= 60) return 'Orta';
    if (strength >= 40) return 'Zayıf';
    return 'Çok Zayıf';
  }

  Color _getStrengthColor(int strength) {
    if (strength >= 80) return Colors.green;
    if (strength >= 60) return Colors.orange;
    if (strength >= 40) return Colors.red[300]!;
    return Colors.red;
  }

  String _getStrengthTip(int strength) {
    if (strength < 40) {
      return 'Daha güvenli bir PIN için farklı rakamlar kullanın ve sıralı sayılardan kaçının.';
    } else if (strength < 60) {
      return 'PIN\'inizi güçlendirmek için 6 hane kullanın ve tekrar eden rakamları azaltın.';
    } else if (strength < 80) {
      return 'İyi! Daha da güçlü bir PIN için sıralı olmayan rakamlar tercih edin.';
    }
    return '';
  }
}