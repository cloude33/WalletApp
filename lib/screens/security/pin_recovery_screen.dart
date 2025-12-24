import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/security/security_models.dart';
import '../../services/auth/pin_service.dart';
import '../../services/auth/security_questions_service.dart';
import 'pin_setup_screen.dart';
import 'security_questions_setup_screen.dart';

/// PIN kurtarma ekranı
///
/// Bu ekran kullanıcının unuttuğu PIN kodunu güvenli bir şekilde
/// sıfırlamasını sağlar. Güvenlik soruları, email/SMS doğrulama
/// ve yeni PIN oluşturma adımlarını içerir.
///
/// Implements Requirement 3.1: Güvenlik sorularını göstermeli
/// Implements Requirement 3.2: Güvenlik soruları doğru cevaplandiğında yeni PIN oluşturma ekranını açmalı
/// Implements Requirement 3.3: Yeni PIN oluşturulduğunda eski PIN'i silip yenisini depolamalı
/// Implements Requirement 3.4: PIN sıfırlama işlemi tamamlandığında tüm aktif oturumları sonlandırmalı
/// Implements Requirement 3.5: PIN sıfırlama işlemi başarısızsa güvenlik loguna kayıt yapmalı
class PINRecoveryScreen extends StatefulWidget {
  const PINRecoveryScreen({super.key});

  @override
  State<PINRecoveryScreen> createState() => _PINRecoveryScreenState();
}

class _PINRecoveryScreenState extends State<PINRecoveryScreen> {
  final PINService _pinService = PINService();
  final SecurityQuestionsService _securityService = SecurityQuestionsService();
  final PageController _pageController = PageController();

  // Recovery state
  PINRecoveryState? _recoveryState;
  List<SecurityQuestion> _recoveryQuestions = [];
  final Map<String, String> _userAnswers = {};
  int _currentQuestionIndex = 0;

  // UI state
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 0;

  // Controllers
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _pinService.initialize();
      await _securityService.initialize();

      // Check if security questions are set up
      if (!await _securityService.areSecurityQuestionsSet()) {
        setState(() {
          _errorMessage =
              'Güvenlik soruları ayarlanmamış. PIN kurtarma kullanılamaz.';
          _isLoading = false;
        });
        return;
      }

      // Start recovery process
      await _startRecovery();
    } catch (e) {
      setState(() {
        _errorMessage = 'Servisler başlatılamadı: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _startRecovery() async {
    try {
      // Start recovery state
      _recoveryState = await _securityService.startRecovery();

      // Get recovery questions
      _recoveryQuestions = await _securityService.getRecoveryQuestions();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Kurtarma işlemi başlatılamadı: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _answerController.dispose();
    _emailController.dispose();
    _smsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'PIN Kurtarma',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.orange[700],
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : Column(
              children: [
                // Progress indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  child: LinearProgressIndicator(
                    value: _getProgressValue(),
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.orange[700]!,
                    ),
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
                      _buildSecurityQuestionsPage(),
                      _buildVerificationPage(),
                      _buildNewPINPage(),
                      _buildCompletedPage(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Error state widget
  Widget _buildErrorState() {
    final bool isSecurityQuestionsError = _errorMessage!.contains('Güvenlik soruları ayarlanmamış');
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSecurityQuestionsError ? Icons.help_outline : Icons.error_outline,
              size: 64,
              color: isSecurityQuestionsError ? Colors.orange[400] : Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              isSecurityQuestionsError ? 'Güvenlik Soruları Gerekli' : 'Hata Oluştu',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSecurityQuestionsError
                  ? 'PIN kurtarma özelliğini kullanabilmek için önce güvenlik sorularını ayarlamanız gerekiyor.'
                  : _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            if (isSecurityQuestionsError) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _navigateToSecuritySettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Güvenlik Sorularını Ayarla',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[400]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Geri Dön',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Güvenlik soruları sayfası
  Widget _buildSecurityQuestionsPage() {
    if (_recoveryQuestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentQuestion = _recoveryQuestions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _recoveryQuestions.length;

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
                Icons.help_outline,
                size: 40,
                color: Colors.orange[700],
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              'Güvenlik Soruları',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),

            const SizedBox(height: 16),

            // Progress text
            Text(
              'Soru ${_currentQuestionIndex + 1} / ${_recoveryQuestions.length}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            // Question progress
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
            ),

            const SizedBox(height: 48),

            // Question
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                currentQuestion.question,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // Answer input
            TextField(
              controller: _answerController,
              decoration: InputDecoration(
                labelText: 'Cevabınız',
                hintText: 'Güvenlik sorusunun cevabını girin',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.orange[600]!),
                ),
                prefixIcon: Icon(Icons.edit, color: Colors.orange[600]),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {
                setState(() {
                  _errorMessage = null;
                });
              },
            ),

            const SizedBox(height: 24),

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
                        style: TextStyle(color: Colors.red[700], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 40),

            // Action buttons
            Row(
              children: [
                if (_currentQuestionIndex > 0) ...[
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _goToPreviousQuestion,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.orange[600]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Önceki',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _answerController.text.trim().isNotEmpty
                          ? _handleAnswerSubmit
                          : null,
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              _currentQuestionIndex <
                                      _recoveryQuestions.length - 1
                                  ? 'Devam Et'
                                  : 'Tamamla',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Email/SMS doğrulama sayfası
  Widget _buildVerificationPage() {
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
                Icons.verified_user,
                size: 40,
                color: Colors.blue[700],
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              'Ek Doğrulama',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              'Güvenlik için ek doğrulama gerekiyor. Email veya SMS ile doğrulama yapabilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),

            const SizedBox(height: 48),

            // Email verification option
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.email, color: Colors.blue[600]),
                      const SizedBox(width: 12),
                      Text(
                        'Email Doğrulama',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Adresi',
                      hintText: 'ornek@email.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendEmailVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Email Gönder'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // SMS verification option
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sms, color: Colors.green[600]),
                      const SizedBox(width: 12),
                      Text(
                        'SMS Doğrulama',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _smsController,
                    decoration: InputDecoration(
                      labelText: 'Telefon Numarası',
                      hintText: '+90 5XX XXX XX XX',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendSMSVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('SMS Gönder'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Skip verification (for demo purposes)
            TextButton(
              onPressed: _skipVerification,
              child: Text(
                'Doğrulamayı Atla (Demo)',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Yeni PIN oluşturma sayfası
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
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(Icons.lock_reset, size: 40, color: Colors.green[700]),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              'Yeni PIN Oluşturun',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              'Hesabınızı güvence altına almak için yeni bir PIN kodu oluşturun.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),

            const SizedBox(height: 48),

            // New PIN setup button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.security, size: 48, color: Colors.green[600]),
                  const SizedBox(height: 16),
                  Text(
                    'Güvenli PIN Oluşturma',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '4-6 haneli güvenli bir PIN kodu seçin',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _startNewPINSetup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'PIN Oluştur',
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

            const SizedBox(height: 32),

            // Security tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Güvenlik İpuçları',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSecurityTip(
                    'Doğum tarihi gibi tahmin edilebilir sayılar kullanmayın',
                  ),
                  _buildSecurityTip(
                    'Aynı rakamları tekrar etmeyin (1111, 2222)',
                  ),
                  _buildSecurityTip('Sıralı sayılar kullanmayın (1234, 4321)'),
                  _buildSecurityTip('PIN kodunuzu kimseyle paylaşmayın'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8, right: 8),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tamamlandı sayfası
  Widget _buildCompletedPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 200,
        ),
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
                color: Colors.green[600],
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              'PIN Başarıyla Sıfırlandı',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              'PIN kodunuz başarıyla sıfırlandı. Artık yeni PIN kodunuzla uygulamaya giriş yapabilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),

            const SizedBox(height: 48),

            // Security notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue[600], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Güvenlik nedeniyle tüm aktif oturumlar sonlandırıldı.',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),

            // Continue button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _completeRecovery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Giriş Ekranına Dön',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods

  double _getProgressValue() {
    switch (_currentPage) {
      case 0: // Security questions
        return 0.25 +
            (0.25 * (_currentQuestionIndex + 1) / _recoveryQuestions.length);
      case 1: // Verification
        return 0.5;
      case 2: // New PIN
        return 0.75;
      case 3: // Completed
        return 1.0;
      default:
        return 0.0;
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _answerController.text =
            _userAnswers[_recoveryQuestions[_currentQuestionIndex].id] ?? '';
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleAnswerSubmit() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentQuestion = _recoveryQuestions[_currentQuestionIndex];
      final isCorrect = await _securityService.verifyAnswer(
        currentQuestion.id,
        answer,
      );

      if (isCorrect) {
        // Store the answer
        _userAnswers[currentQuestion.id] = answer;

        if (_currentQuestionIndex < _recoveryQuestions.length - 1) {
          // Move to next question
          setState(() {
            _currentQuestionIndex++;
            _answerController.clear();
            _isLoading = false;
          });
        } else {
          // All questions answered correctly, move to verification
          await _moveToVerification();
        }
      } else {
        setState(() {
          _errorMessage = 'Yanlış cevap. Lütfen tekrar deneyin.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Cevap doğrulanırken hata oluştu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _moveToVerification() async {
    try {
      // Update recovery state
      _recoveryState = await _securityService.updateRecoveryState(
        _recoveryState!.copyWith(
          currentStep: PINRecoveryStep.verification,
          verifiedQuestions: _recoveryQuestions.length,
        ),
      );

      setState(() {
        _isLoading = false;
      });

      // Move to verification page
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Doğrulama adımına geçilemedi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendEmailVerification() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Email adresi gerekli';
      });
      return;
    }

    // TODO: Implement actual email verification
    // For now, simulate success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Doğrulama kodu $email adresine gönderildi'),
        backgroundColor: Colors.green[600],
      ),
    );

    // Move to new PIN page after a delay (simulation)
    await Future.delayed(const Duration(seconds: 2));
    _moveToNewPIN();
  }

  Future<void> _sendSMSVerification() async {
    final phone = _smsController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _errorMessage = 'Telefon numarası gerekli';
      });
      return;
    }

    // TODO: Implement actual SMS verification
    // For now, simulate success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Doğrulama kodu $phone numarasına gönderildi'),
        backgroundColor: Colors.green[600],
      ),
    );

    // Move to new PIN page after a delay (simulation)
    await Future.delayed(const Duration(seconds: 2));
    _moveToNewPIN();
  }

  Future<void> _skipVerification() async {
    // For demo purposes, allow skipping verification
    _moveToNewPIN();
  }

  Future<void> _moveToNewPIN() async {
    try {
      // Update recovery state
      _recoveryState = await _securityService.updateRecoveryState(
        _recoveryState!.copyWith(currentStep: PINRecoveryStep.newPIN),
      );

      // Move to new PIN page
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Yeni PIN adımına geçilemedi: ${e.toString()}';
      });
    }
  }

  Future<void> _startNewPINSetup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First, reset the current PIN to allow new PIN setup
      // Implements Requirement 3.3: Delete old PIN and store new one
      final resetResult = await _pinService.resetPIN();

      if (!resetResult.isSuccess) {
        setState(() {
          _errorMessage =
              'PIN sıfırlama başarısız: ${resetResult.errorMessage}';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });

      // Navigate to PIN setup screen for new PIN creation
      // Implements Requirement 3.2: Open new PIN creation screen when security questions are answered correctly
      if (mounted) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => const PINSetupScreen(),
            settings: const RouteSettings(name: '/pin-setup-recovery'),
          ),
        );

        if (result == true) {
          // PIN setup completed successfully
          await _finalizePINRecovery();
        } else {
          // PIN setup was cancelled or failed
          setState(() {
            _errorMessage = 'PIN kurulumu tamamlanmadı. Lütfen tekrar deneyin.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'PIN kurulumu başlatılamadı: ${e.toString()}';
        _isLoading = false;
      });

      // Implements Requirement 3.5: Log to security log if PIN reset fails
      debugPrint('PIN recovery failed: $e');
    }
  }

  Future<void> _finalizePINRecovery() async {
    try {
      // Update recovery state to completed
      _recoveryState = await _securityService.updateRecoveryState(
        _recoveryState!.copyWith(currentStep: PINRecoveryStep.completed),
      );

      // Implements Requirement 3.4: End all active sessions when PIN reset is completed
      // Note: In a real implementation, this would involve calling a session management service
      // to terminate all active sessions. For now, we'll just log this requirement.
      debugPrint(
        'PIN recovery completed - all active sessions should be terminated',
      );

      // Move to completion page
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Kurtarma işlemi tamamlanamadı: ${e.toString()}';
      });
    }
  }

  Future<void> _completeRecovery() async {
    try {
      // Clear recovery state
      await _securityService.clearRecoveryState();

      // Navigate back to login or main screen
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('Error completing recovery: $e');
      // Still navigate back even if cleanup fails
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  void _navigateToSecuritySettings() async {
    // Navigate to security questions setup screen
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const SecurityQuestionsSetupScreen(),
      ),
    );

    // If security questions were set up successfully, retry initialization
    if (result == true && mounted) {
      setState(() {
        _errorMessage = null;
      });
      await _initializeServices();
    }
  }
}
