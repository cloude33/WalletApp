import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth/biometric_service.dart';
import '../../models/security/biometric_type.dart' as app_biometric;
import '../../models/security/auth_result.dart';

/// Biyometrik kurulum ekranı
/// 
/// Bu ekran kullanıcının biyometrik kimlik doğrulamayı kurmasını sağlar.
/// Mevcut biyometrik türlerin listelenmesi, kayıt akışı ve hata yönetimi içerir.
/// 
/// Implements Requirement 4.1: Cihazın biyometrik desteğini kontrol etmeli
/// Implements Requirement 4.2: Parmak izi doğrulaması sunmalı
/// Implements Requirement 4.3: Face ID/yüz tanıma doğrulaması sunmalı
/// Implements Requirement 7.3: Biyometrik ayar değiştirildiğinde yeniden kayıt sürecini başlatmalı
class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final BiometricService _biometricService = BiometricServiceSingleton.instance;
  
  bool _isLoading = true;
  bool _isEnrolling = false;
  String? _errorMessage;
  bool _isBiometricAvailable = false;
  List<app_biometric.BiometricType> _availableBiometrics = [];
  app_biometric.BiometricType? _selectedBiometric;
  bool _setupCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  /// Biyometrik kullanılabilirliği kontrol eder
  Future<void> _checkBiometricAvailability() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Cihazın biyometrik desteğini kontrol et
      final bool isAvailable = await _biometricService.isBiometricAvailable();
      final List<app_biometric.BiometricType> availableBiometrics = 
          await _biometricService.getAvailableBiometrics();

      setState(() {
        _isBiometricAvailable = isAvailable;
        _availableBiometrics = availableBiometrics;
        _isLoading = false;
      });

      // Eğer sadece bir tür varsa otomatik seç
      if (_availableBiometrics.length == 1) {
        setState(() {
          _selectedBiometric = _availableBiometrics.first;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Biyometrik kontrol hatası: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Biyometrik Kurulum',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _setupCompleted
              ? _buildSuccessView()
              : _isBiometricAvailable
                  ? _buildSetupView()
                  : _buildUnavailableView(),
    );
  }

  /// Yükleme görünümü
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Biyometrik destek kontrol ediliyor...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Biyometrik mevcut değil görünümü
  Widget _buildUnavailableView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.warning_outlined,
              size: 50,
              color: Colors.orange[700],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            'Biyometrik Doğrulama Mevcut Değil',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            _getUnavailableMessage(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Error message if any
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600], size: 24),
                  const SizedBox(width: 12),
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
            const SizedBox(height: 32),
          ],
          
          // Action buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _checkBiometricAvailability,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tekrar Kontrol Et',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[400]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Geri Dön',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Kurulum görünümü
  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
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
              Icons.fingerprint,
              size: 40,
              color: Colors.blue[700],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            'Biyometrik Doğrulama Kurulumu',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            'Uygulamanıza daha hızlı ve güvenli erişim için biyometrik doğrulamayı etkinleştirin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Available biometrics list
          _buildBiometricsList(),
          
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
          
          // Setup button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedBiometric != null && !_isEnrolling
                  ? _enrollBiometric
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isEnrolling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Biyometrik Doğrulamayı Etkinleştir',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Skip button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _isEnrolling ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Şimdi Değil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Başarı görünümü
  Widget _buildSuccessView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          
          // Success icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.check_circle,
              size: 60,
              color: Colors.green[700],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            'Biyometrik Doğrulama Etkinleştirildi!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            'Artık ${_selectedBiometric?.displayName ?? 'biyometrik doğrulama'} kullanarak uygulamanıza hızlı ve güvenli bir şekilde erişebilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Güvenlik İpucu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Biyometrik doğrulama başarısız olduğunda her zaman PIN kodunuzla giriş yapabilirsiniz.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Done button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Tamam',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mevcut biyometrik türlerin listesi
  Widget _buildBiometricsList() {
    if (_availableBiometrics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_outlined, color: Colors.orange[700], size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cihazınızda kayıtlı biyometrik veri bulunamadı. Lütfen cihaz ayarlarından biyometrik doğrulamayı etkinleştirin.',
                style: TextStyle(
                  color: Colors.orange[800],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mevcut Biyometrik Türler:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        
        ..._availableBiometrics.map((biometric) => _buildBiometricTile(biometric)),
      ],
    );
  }

  /// Biyometrik tür tile'ı
  Widget _buildBiometricTile(app_biometric.BiometricType biometric) {
    final bool isSelected = _selectedBiometric == biometric;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedBiometric = biometric;
            _errorMessage = null;
          });
          HapticFeedback.lightImpact();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[50] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[100] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  _getBiometricIcon(biometric),
                  size: 24,
                  color: isSelected ? Colors.blue[700] : Colors.grey[600],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      biometric.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.blue[800] : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getBiometricDescription(biometric),
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? Colors.blue[600] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Selection indicator
              if (isSelected) ...[
                const SizedBox(width: 12),
                Icon(
                  Icons.check_circle,
                  color: Colors.blue[700],
                  size: 24,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Biyometrik kayıt işlemi
  Future<void> _enrollBiometric() async {
    if (_selectedBiometric == null) return;

    setState(() {
      _isEnrolling = true;
      _errorMessage = null;
    });

    try {
      // Önce test doğrulaması yap
      final AuthResult testResult = await _biometricService.authenticate(
        localizedFallbackTitle: 'PIN ile Doğrula',
        cancelButtonText: 'İptal',
      );

      if (testResult.isSuccess) {
        // Biyometrik kayıt başarılı
        setState(() {
          _setupCompleted = true;
        });
      } else {
        // Biyometrik doğrulama başarısız
        setState(() {
          _errorMessage = testResult.errorMessage ?? 'Biyometrik doğrulama başarısız oldu';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Beklenmeyen bir hata oluştu: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isEnrolling = false;
        });
      }
    }
  }

  /// Biyometrik tür için ikon döndürür
  IconData _getBiometricIcon(app_biometric.BiometricType biometric) {
    switch (biometric) {
      case app_biometric.BiometricType.fingerprint:
        return Icons.fingerprint;
      case app_biometric.BiometricType.face:
        return Icons.face;
      case app_biometric.BiometricType.voice:
        return Icons.record_voice_over;
      case app_biometric.BiometricType.iris:
        return Icons.visibility;
    }
  }

  /// Biyometrik tür için açıklama döndürür
  String _getBiometricDescription(app_biometric.BiometricType biometric) {
    switch (biometric) {
      case app_biometric.BiometricType.fingerprint:
        return 'Parmak izinizi kullanarak hızlı giriş yapın';
      case app_biometric.BiometricType.face:
        return 'Yüzünüzü kullanarak güvenli giriş yapın';
      case app_biometric.BiometricType.voice:
        return 'Sesinizi kullanarak kimlik doğrulama yapın';
      case app_biometric.BiometricType.iris:
        return 'Iris tarama ile gelişmiş güvenlik';
    }
  }

  /// Mevcut olmama mesajı döndürür
  String _getUnavailableMessage() {
    if (_availableBiometrics.isEmpty) {
      return 'Bu cihazda biyometrik doğrulama desteklenmiyor veya cihaz ayarlarından etkinleştirilmemiş. '
             'Lütfen cihaz ayarlarından parmak izi, yüz tanıma veya diğer biyometrik seçenekleri etkinleştirin.';
    } else {
      return 'Biyometrik doğrulama şu anda kullanılamıyor. Lütfen cihazınızın güvenlik ayarlarını kontrol edin.';
    }
  }
}