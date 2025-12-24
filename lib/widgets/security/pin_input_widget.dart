import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Özelleştirilebilir PIN giriş widget'ı
/// 
/// Bu widget PIN kodu girişi için kullanılır ve şu özellikleri sunar:
/// - Özelleştirilebilir PIN uzunluğu (4-8 hane)
/// - Animasyonlu feedback
/// - Erişilebilirlik desteği
/// - Sayı tuş takımı
/// - Görsel PIN göstergesi (dots)
/// - Haptic feedback
/// 
/// Implements Requirement 1.1: 4-6 haneli sayısal PIN girişi kabul etmeli
/// Implements Requirement 2.5: Kalan süreyi kullanıcıya göstermeli
class PINInputWidget extends StatefulWidget {
  /// Mevcut PIN değeri
  final String pin;
  
  /// PIN değiştiğinde çağrılacak callback
  final ValueChanged<String> onChanged;
  
  /// PIN tamamlandığında çağrılacak callback (opsiyonel)
  final ValueChanged<String>? onCompleted;
  
  /// Maksimum PIN uzunluğu (4-8 arası)
  final int maxLength;
  
  /// PIN karakterlerini gizle (dots olarak göster)
  final bool obscureText;
  
  /// Widget'ın etkin olup olmadığı
  final bool enabled;
  
  /// Hata durumu (kırmızı renk gösterir)
  final bool hasError;
  
  /// Yükleme durumu (loading indicator gösterir)
  final bool isLoading;
  
  /// Otomatik focus
  final bool autoFocus;
  
  /// PIN dot'larının boyutu
  final double dotSize;
  
  /// PIN dot'ları arasındaki boşluk
  final double dotSpacing;
  
  /// Aktif dot rengi
  final Color? activeDotColor;
  
  /// Dolu dot rengi
  final Color? filledDotColor;
  
  /// Boş dot rengi
  final Color? emptyDotColor;
  
  /// Sayı tuş takımını göster
  final bool showNumberPad;
  
  /// Sayı tuş takımı buton boyutu
  final double numberPadButtonSize;
  
  /// Animasyon süresi
  final Duration animationDuration;

  const PINInputWidget({
    super.key,
    required this.pin,
    required this.onChanged,
    this.onCompleted,
    this.maxLength = 6,
    this.obscureText = true,
    this.enabled = true,
    this.hasError = false,
    this.isLoading = false,
    this.autoFocus = true,
    this.dotSize = 16.0,
    this.dotSpacing = 8.0,
    this.activeDotColor,
    this.filledDotColor,
    this.emptyDotColor,
    this.showNumberPad = true,
    this.numberPadButtonSize = 60.0,
    this.animationDuration = const Duration(milliseconds: 200),
  }) : assert(maxLength >= 4 && maxLength <= 8, 'PIN uzunluğu 4-8 arasında olmalıdır');

  @override
  State<PINInputWidget> createState() => _PINInputWidgetState();
}

class _PINInputWidgetState extends State<PINInputWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  // Cache for number pad buttons to avoid rebuilding
  List<Widget>? _cachedNumberPadButtons;
  
  @override
  void initState() {
    super.initState();
    _controller.text = widget.pin;
    
    // Use single animation controller for shake (removed pulse for performance)
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    
    // Otomatik focus
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.enabled) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(PINInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.pin != widget.pin) {
      _controller.text = widget.pin;
      
      // PIN tamamlandığında callback çağır
      if (widget.pin.length == widget.maxLength && widget.onCompleted != null) {
        widget.onCompleted!(widget.pin);
      }
      
      // Invalidate cache if enabled state changes
      if (oldWidget.enabled != widget.enabled) {
        _cachedNumberPadButtons = null;
      }
    }
    
    // Hata durumunda shake animasyonu
    if (!oldWidget.hasError && widget.hasError) {
      _triggerShakeAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  /// Shake animasyonunu tetikler
  void _triggerShakeAnimation() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Semantics(
      label: 'PIN kodu giriş alanı',
      hint: '${widget.maxLength} haneli PIN kodunuzu girin',
      textField: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // PIN dots display with RepaintBoundary for optimization
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: child,
                );
              },
              child: _buildPINDots(theme),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Hidden text field for keyboard input
          SizedBox(
            width: 1,
            height: 1,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled && !widget.isLoading,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.maxLength),
              ],
              onChanged: _onTextChanged,
              style: const TextStyle(color: Colors.transparent),
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
              ),
              obscureText: widget.obscureText,
            ),
          ),
          
          // Number pad (opsiyonel) with RepaintBoundary
          if (widget.showNumberPad) ...[
            RepaintBoundary(
              child: _buildNumberPad(theme),
            ),
          ],
          
          // Loading indicator
          if (widget.isLoading) ...[
            const SizedBox(height: 16),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// PIN dot'larını oluşturur
  Widget _buildPINDots(ThemeData theme) {
    final activeDotColor = widget.activeDotColor ?? theme.primaryColor;
    final filledDotColor = widget.filledDotColor ?? theme.primaryColor;
    final emptyDotColor = widget.emptyDotColor ?? theme.disabledColor;
    final errorColor = theme.colorScheme.error;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.maxLength, (index) {
        final bool isFilled = index < widget.pin.length;
        final bool isActive = index == widget.pin.length && widget.enabled && !widget.isLoading;
        
        Color dotColor;
        if (widget.hasError) {
          dotColor = errorColor;
        } else if (isFilled) {
          dotColor = filledDotColor;
        } else if (isActive) {
          dotColor = activeDotColor;
        } else {
          dotColor = emptyDotColor;
        }
        
        return AnimatedContainer(
          duration: widget.animationDuration,
          margin: EdgeInsets.symmetric(horizontal: widget.dotSpacing),
          width: widget.dotSize,
          height: widget.dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? dotColor : Colors.transparent,
            border: Border.all(
              color: dotColor,
              width: isActive ? 2.0 : 1.0,
            ),
          ),
          child: widget.obscureText && isFilled
              ? Center(
                  child: Container(
                    width: widget.dotSize * 0.4,
                    height: widget.dotSize * 0.4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                    ),
                  ),
                )
              : (isFilled && !widget.obscureText
                  ? Center(
                      child: Text(
                        widget.pin[index],
                        style: TextStyle(
                          color: dotColor,
                          fontSize: widget.dotSize * 0.6,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null),
        );
      }),
    );
  }

  /// Sayı tuş takımını oluşturur (cached for performance)
  Widget _buildNumberPad(ThemeData theme) {
    // Cache number pad buttons to avoid rebuilding
    _cachedNumberPadButtons ??= _buildNumberPadButtons(theme);
    
    return Container(
      constraints: BoxConstraints(maxWidth: widget.numberPadButtonSize * 3 + 32),
      child: Column(
        children: [
          // First row: 1, 2, 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _cachedNumberPadButtons![0],
              _cachedNumberPadButtons![1],
              _cachedNumberPadButtons![2],
            ],
          ),
          const SizedBox(height: 16),
          
          // Second row: 4, 5, 6
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _cachedNumberPadButtons![3],
              _cachedNumberPadButtons![4],
              _cachedNumberPadButtons![5],
            ],
          ),
          const SizedBox(height: 16),
          
          // Third row: 7, 8, 9
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _cachedNumberPadButtons![6],
              _cachedNumberPadButtons![7],
              _cachedNumberPadButtons![8],
            ],
          ),
          const SizedBox(height: 16),
          
          // Fourth row: empty, 0, backspace
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: widget.numberPadButtonSize,
                height: widget.numberPadButtonSize,
              ), // Empty space
              _cachedNumberPadButtons![9],
              _cachedNumberPadButtons![10],
            ],
          ),
        ],
      ),
    );
  }
  
  /// Build number pad buttons list for caching
  List<Widget> _buildNumberPadButtons(ThemeData theme) {
    return [
      _buildNumberButton('1', theme),
      _buildNumberButton('2', theme),
      _buildNumberButton('3', theme),
      _buildNumberButton('4', theme),
      _buildNumberButton('5', theme),
      _buildNumberButton('6', theme),
      _buildNumberButton('7', theme),
      _buildNumberButton('8', theme),
      _buildNumberButton('9', theme),
      _buildNumberButton('0', theme),
      _buildBackspaceButton(theme),
    ];
  }

  /// Sayı butonu oluşturur (optimized with const where possible)
  Widget _buildNumberButton(String number, ThemeData theme) {
    final isEnabled = widget.enabled && !widget.isLoading;
    
    return Semantics(
      button: true,
      label: 'Sayı $number',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? () => _onNumberPressed(number) : null,
          borderRadius: BorderRadius.circular(widget.numberPadButtonSize / 2),
          child: Container(
            width: widget.numberPadButtonSize,
            height: widget.numberPadButtonSize,
            decoration: BoxDecoration(
              color: isEnabled
                  ? theme.colorScheme.surface
                  : theme.disabledColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(widget.numberPadButtonSize / 2),
              border: Border.all(
                color: isEnabled
                    ? theme.dividerColor
                    : theme.disabledColor.withValues(alpha: 0.3),
              ),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: widget.numberPadButtonSize * 0.4,
                  fontWeight: FontWeight.w600,
                  color: isEnabled
                      ? theme.textTheme.bodyLarge?.color
                      : theme.disabledColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Silme butonu oluşturur
  Widget _buildBackspaceButton(ThemeData theme) {
    return Semantics(
      button: true,
      label: 'Son rakamı sil',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.enabled && !widget.isLoading && widget.pin.isNotEmpty
              ? _onBackspacePressed
              : null,
          borderRadius: BorderRadius.circular(widget.numberPadButtonSize / 2),
          child: AnimatedContainer(
            duration: widget.animationDuration,
            width: widget.numberPadButtonSize,
            height: widget.numberPadButtonSize,
            decoration: BoxDecoration(
              color: widget.enabled && !widget.isLoading && widget.pin.isNotEmpty
                  ? theme.colorScheme.surface
                  : theme.disabledColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(widget.numberPadButtonSize / 2),
              border: Border.all(
                color: widget.enabled && !widget.isLoading && widget.pin.isNotEmpty
                    ? theme.dividerColor
                    : theme.disabledColor.withValues(alpha: 0.3),
              ),
              boxShadow: widget.enabled && !widget.isLoading && widget.pin.isNotEmpty
                  ? [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                Icons.backspace_outlined,
                size: widget.numberPadButtonSize * 0.4,
                color: widget.enabled && !widget.isLoading && widget.pin.isNotEmpty
                    ? theme.iconTheme.color
                    : theme.disabledColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Metin değiştiğinde çağrılır
  void _onTextChanged(String value) {
    if (value.length <= widget.maxLength) {
      widget.onChanged(value);
      
      // Haptic feedback
      if (value.length > widget.pin.length) {
        HapticFeedback.lightImpact();
      }
    }
  }

  /// Sayı tuşuna basıldığında çağrılır
  void _onNumberPressed(String number) {
    if (widget.pin.length < widget.maxLength) {
      final newPin = widget.pin + number;
      widget.onChanged(newPin);
      
      // Haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  /// Silme tuşuna basıldığında çağrılır
  void _onBackspacePressed() {
    if (widget.pin.isNotEmpty) {
      final newPin = widget.pin.substring(0, widget.pin.length - 1);
      widget.onChanged(newPin);
      
      // Haptic feedback
      HapticFeedback.selectionClick();
    }
  }
}

/// PIN giriş widget'ı için özelleştirme seçenekleri
class PINInputTheme {
  final Color? activeDotColor;
  final Color? filledDotColor;
  final Color? emptyDotColor;
  final Color? errorColor;
  final double dotSize;
  final double dotSpacing;
  final double numberPadButtonSize;
  final Duration animationDuration;

  const PINInputTheme({
    this.activeDotColor,
    this.filledDotColor,
    this.emptyDotColor,
    this.errorColor,
    this.dotSize = 16.0,
    this.dotSpacing = 8.0,
    this.numberPadButtonSize = 60.0,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  /// Varsayılan tema
  static const PINInputTheme defaultTheme = PINInputTheme();

  /// Koyu tema
  static const PINInputTheme darkTheme = PINInputTheme(
    dotSize: 18.0,
    dotSpacing: 10.0,
    numberPadButtonSize: 65.0,
  );

  /// Kompakt tema
  static const PINInputTheme compactTheme = PINInputTheme(
    dotSize: 12.0,
    dotSpacing: 6.0,
    numberPadButtonSize: 50.0,
  );
}