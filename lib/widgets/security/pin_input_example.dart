import 'package:flutter/material.dart';
import 'pin_input_widget.dart';

/// PIN Input Widget kullanım örneği
/// 
/// Bu dosya PINInputWidget'ın nasıl kullanılacağını gösterir.
class PINInputExample extends StatefulWidget {
  const PINInputExample({super.key});

  @override
  State<PINInputExample> createState() => _PINInputExampleState();
}

class _PINInputExampleState extends State<PINInputExample> {
  String _pin = '';
  bool _hasError = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PIN Input Widget Örneği'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Başlık
            Text(
              'PIN Kodunuzu Girin',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Açıklama
            Text(
              '6 haneli PIN kodunuzu girin',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 48),
            
            // PIN Input Widget
            PINInputWidget(
              pin: _pin,
              onChanged: (pin) {
                setState(() {
                  _pin = pin;
                  _hasError = false;
                });
              },
              onCompleted: (pin) {
                // PIN tamamlandığında
                _simulateValidation(pin);
              },
              maxLength: 6,
              hasError: _hasError,
              isLoading: _isLoading,
              obscureText: true,
            ),
            
            const SizedBox(height: 32),
            
            // Durum göstergesi
            if (_pin.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _hasError 
                      ? Colors.red[50] 
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _hasError 
                        ? Colors.red[200]! 
                        : Colors.blue[200]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _hasError ? Icons.error : Icons.info,
                      color: _hasError ? Colors.red[600] : Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _hasError 
                          ? 'Yanlış PIN kodu!' 
                          : 'PIN: ${_pin.length}/6 hane',
                      style: TextStyle(
                        color: _hasError ? Colors.red[700] : Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ],
            
            // Test butonları
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Hata Göster'),
                ),
                
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _pin = '';
                      _hasError = false;
                      _isLoading = false;
                    });
                  },
                  child: const Text('Temizle'),
                ),
                
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = !_isLoading;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isLoading ? 'Loading Kapat' : 'Loading Aç'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// PIN doğrulama simülasyonu
  void _simulateValidation(String pin) {
    setState(() {
      _isLoading = true;
    });
    
    // 2 saniye bekle (API çağrısı simülasyonu)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Örnek: "123456" doğru PIN
          _hasError = pin != '123456';
        });
        
        if (!_hasError) {
          // Başarılı giriş
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN doğrulandı! ✅'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }
}

/// Farklı tema örnekleri
class PINInputThemeExamples extends StatefulWidget {
  const PINInputThemeExamples({super.key});

  @override
  State<PINInputThemeExamples> createState() => _PINInputThemeExamplesState();
}

class _PINInputThemeExamplesState extends State<PINInputThemeExamples> {
  String _pin1 = '';
  String _pin2 = '';
  String _pin3 = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PIN Input Tema Örnekleri'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Varsayılan tema
            Text(
              'Varsayılan Tema',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            PINInputWidget(
              pin: _pin1,
              onChanged: (pin) => setState(() => _pin1 = pin),
              maxLength: 4,
            ),
            
            const SizedBox(height: 48),
            
            // Büyük tema
            Text(
              'Büyük Tema',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            PINInputWidget(
              pin: _pin2,
              onChanged: (pin) => setState(() => _pin2 = pin),
              maxLength: 6,
              dotSize: 20.0,
              dotSpacing: 12.0,
              numberPadButtonSize: 70.0,
              activeDotColor: Colors.purple,
              filledDotColor: Colors.purple,
            ),
            
            const SizedBox(height: 48),
            
            // Kompakt tema
            Text(
              'Kompakt Tema',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            PINInputWidget(
              pin: _pin3,
              onChanged: (pin) => setState(() => _pin3 = pin),
              maxLength: 4,
              dotSize: 12.0,
              dotSpacing: 6.0,
              numberPadButtonSize: 50.0,
              activeDotColor: Colors.green,
              filledDotColor: Colors.green,
            ),
            
            const SizedBox(height: 48),
            
            // Sayı tuş takımı olmadan
            Text(
              'Sayı Tuş Takımı Olmadan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            PINInputWidget(
              pin: '',
              onChanged: (pin) {},
              maxLength: 4,
              showNumberPad: false,
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Bu modda sadece cihaz klavyesi kullanılır.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}