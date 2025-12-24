import 'package:flutter/material.dart';
import '../../models/security/security_models.dart';
import '../../services/auth/security_questions_service.dart';

/// Security Questions Setup Screen
///
/// This screen allows users to set up security questions for PIN recovery.
/// Users select and answer 3 security questions from predefined categories.
class SecurityQuestionsSetupScreen extends StatefulWidget {
  const SecurityQuestionsSetupScreen({super.key});

  @override
  State<SecurityQuestionsSetupScreen> createState() =>
      _SecurityQuestionsSetupScreenState();
}

class _SecurityQuestionsSetupScreenState
    extends State<SecurityQuestionsSetupScreen> {
  final SecurityQuestionsService _securityService =
      SecurityQuestionsService();
  late final PageController _pageController;

  // State
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 0;

  // Selected questions and answers
  final Map<String, String> _questionsWithAnswers = {};
  final List<SecurityQuestion?> _selectedQuestions = [null, null, null];
  final List<TextEditingController> _answerControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  // Available questions
  List<SecurityQuestion> _availableQuestions = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initializeService();
  }

  Future<void> _initializeService() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _securityService.initialize();
      _availableQuestions = _securityService.getAllPredefinedQuestions();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Servis başlatılamadı: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Güvenlik Soruları Kurulumu',
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
                        value: (_currentPage + 1) / 4,
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
                          _buildQuestionPage(0),
                          _buildQuestionPage(1),
                          _buildQuestionPage(2),
                          _buildCompletionPage(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 24),
            Text(
              'Hata Oluştu',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Geri Dön',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionPage(int questionIndex) {
    final selectedQuestion = _selectedQuestions[questionIndex];
    final answerController = _answerControllers[questionIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Header
          Text(
            'Soru ${questionIndex + 1} / 3',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Güvenlik Sorusu Seçin',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 32),

          // Question selector
          // Question selector
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Güvenlik Sorusu',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.orange[600]!),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4, // Reduced vertical padding for DropdownButton alignment
              ),
              prefixIcon: Icon(Icons.help_outline, color: Colors.orange[600]),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SecurityQuestion>(
                value: selectedQuestion,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                hint: const Text('Seçiniz'),
                items: _getAvailableQuestionsForIndex(questionIndex)
                    .map((question) => DropdownMenuItem(
                          value: question,
                          child: Text(
                            question.question,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedQuestions[questionIndex] = value;
                    _errorMessage = null;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Answer input
          if (selectedQuestion != null) ...[
            TextField(
              controller: answerController,
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cevabınızı hatırlayabileceğiniz bir şey seçin. Büyük/küçük harf fark etmez.',
                      style: TextStyle(color: Colors.blue[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

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
                      style: TextStyle(color: Colors.red[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Action buttons
          Row(
            children: [
              if (questionIndex > 0) ...[
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _goToPreviousPage,
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
                    onPressed: _canProceed(questionIndex)
                        ? () => _goToNextPage(questionIndex)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      questionIndex < 2 ? 'Devam Et' : 'Tamamla',
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
    );
  }

  Widget _buildCompletionPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            Text(
              'Güvenlik Soruları Ayarlandı!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Artık PIN kurtarma özelliğini kullanabilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tamam',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<SecurityQuestion> _getAvailableQuestionsForIndex(int index) {
    // Get already selected question IDs (excluding current index)
    final selectedIds = <String>[];
    for (int i = 0; i < _selectedQuestions.length; i++) {
      if (i != index && _selectedQuestions[i] != null) {
        selectedIds.add(_selectedQuestions[i]!.id);
      }
    }

    // Return questions that haven't been selected yet
    return _availableQuestions
        .where((q) => !selectedIds.contains(q.id))
        .toList();
  }

  bool _canProceed(int questionIndex) {
    return _selectedQuestions[questionIndex] != null &&
        _answerControllers[questionIndex].text.trim().isNotEmpty;
  }

  void _goToNextPage(int questionIndex) {
    if (!_canProceed(questionIndex)) {
      setState(() {
        _errorMessage = 'Lütfen bir soru seçin ve cevabını girin';
      });
      return;
    }

    // Save the answer
    final question = _selectedQuestions[questionIndex]!;
    final answer = _answerControllers[questionIndex].text.trim();
    _questionsWithAnswers[question.id] = answer;

    if (questionIndex < 2) {
      // Move to next question
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // All questions answered, save them
      _saveSecurityQuestions();
    }
  }

  void _goToPreviousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _saveSecurityQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _securityService.setupSecurityQuestions(
        _questionsWithAnswers,
      );

      if (success) {
        setState(() {
          _isLoading = false;
        });

        // Move to completion page
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        setState(() {
          _errorMessage = 'Güvenlik soruları kaydedilemedi';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Hata: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
}
