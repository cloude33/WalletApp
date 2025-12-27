import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/security/security_models.dart';
import '../../utils/security/encryption_helper.dart';
import 'secure_storage_service.dart';

/// Güvenlik soruları yönetim servisi
/// 
/// Bu servis güvenlik sorularının oluşturulması ve
/// cevapların doğrulanmasını sağlar.
/// 
/// Özellikler:
/// - Önceden tanımlı güvenlik soruları
/// - Güvenlik sorusu cevaplarının şifrelenmiş depolanması
/// - PIN kurtarma süreci yönetimi
/// - Cevap doğrulama ve güvenlik kontrolleri
class SecurityQuestionsService {
  static final SecurityQuestionsService _instance = SecurityQuestionsService._internal();
  factory SecurityQuestionsService() => _instance;
  SecurityQuestionsService._internal();

  final AuthSecureStorageService _storage = AuthSecureStorageService();
  final EncryptionHelper _encryption = EncryptionHelper();
  
  bool _isInitialized = false;
  
  // Önceden tanımlı güvenlik soruları
  static final List<SecurityQuestion> _predefinedQuestions = [
    // Kişisel bilgiler
    SecurityQuestion(
      id: 'personal_1',
      question: 'İlk evcil hayvanınızın adı neydi?',
      category: SecurityQuestionCategory.personal,
    ),
    SecurityQuestion(
      id: 'personal_2',
      question: 'Doğduğunuz şehir neresidir?',
      category: SecurityQuestionCategory.personal,
    ),
    SecurityQuestion(
      id: 'personal_3',
      question: 'En sevdiğiniz renk nedir?',
      category: SecurityQuestionCategory.personal,
    ),
    
    // Aile bilgileri
    SecurityQuestion(
      id: 'family_1',
      question: 'Annenizin kızlık soyadı nedir?',
      category: SecurityQuestionCategory.family,
    ),
    SecurityQuestion(
      id: 'family_2',
      question: 'En büyük kardeşinizin adı nedir?',
      category: SecurityQuestionCategory.family,
    ),
    SecurityQuestion(
      id: 'family_3',
      question: 'Büyükbabanızın adı nedir?',
      category: SecurityQuestionCategory.family,
    ),
    
    // Eğitim bilgileri
    SecurityQuestion(
      id: 'education_1',
      question: 'İlkokul öğretmeninizin soyadı neydi?',
      category: SecurityQuestionCategory.education,
    ),
    SecurityQuestion(
      id: 'education_2',
      question: 'Üniversitede okuduğunuz bölüm nedir?',
      category: SecurityQuestionCategory.education,
    ),
    SecurityQuestion(
      id: 'education_3',
      question: 'En sevdiğiniz ders hangisiydi?',
      category: SecurityQuestionCategory.education,
    ),
    
    // Hobiler ve ilgi alanları
    SecurityQuestion(
      id: 'hobbies_1',
      question: 'En sevdiğiniz spor dalı nedir?',
      category: SecurityQuestionCategory.hobbies,
    ),
    SecurityQuestion(
      id: 'hobbies_2',
      question: 'En sevdiğiniz müzik türü nedir?',
      category: SecurityQuestionCategory.hobbies,
    ),
    SecurityQuestion(
      id: 'hobbies_3',
      question: 'En sevdiğiniz yemek nedir?',
      category: SecurityQuestionCategory.hobbies,
    ),
    
    // Geçmiş deneyimler
    SecurityQuestion(
      id: 'experiences_1',
      question: 'İlk işinizde çalıştığınız şirketin adı neydi?',
      category: SecurityQuestionCategory.experiences,
    ),
    SecurityQuestion(
      id: 'experiences_2',
      question: 'İlk gittiğiniz konser hangi sanatçının konseriydi?',
      category: SecurityQuestionCategory.experiences,
    ),
    SecurityQuestion(
      id: 'experiences_3',
      question: 'Çocukken en sevdiğiniz oyuncak neydi?',
      category: SecurityQuestionCategory.experiences,
    ),
  ];

  /// Servisi başlatır
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _storage.initialize();
      _isInitialized = true;
      debugPrint('Security Questions Service initialized successfully');
    } catch (e) {
      throw Exception('Failed to initialize Security Questions service: ${e.toString()}');
    }
  }

  /// Kullanıcının güvenlik sorularını ayarlar
  /// 
  /// [questionsWithAnswers] - Soru ID'si ve cevap çiftleri
  /// 
  /// Returns işlem başarılı ise true
  Future<bool> setupSecurityQuestions(Map<String, String> questionsWithAnswers) async {
    try {
      await _ensureInitialized();
      
      if (questionsWithAnswers.length < 3) {
        throw Exception('En az 3 güvenlik sorusu ayarlanmalı');
      }
      
      // Cevapları şifrele ve depola
      final Map<String, String> encryptedAnswers = {};
      for (final entry in questionsWithAnswers.entries) {
        final questionId = entry.key;
        final answer = entry.value.trim().toLowerCase();
        
        if (answer.isEmpty) {
          throw Exception('Güvenlik sorusu cevabı boş olamaz');
        }
        
        // Get encryption key for security questions
        final encryptionKey = await _storage.getEncryptionKey();
        if (encryptionKey == null) {
          throw Exception('Şifreleme anahtarı alınamadı');
        }
        
        final encryptedAnswer = EncryptionHelper.encrypt(answer, encryptionKey);
        encryptedAnswers[questionId] = encryptedAnswer;
      }
      
      // Güvenli depolamaya kaydet
      final questionsJson = jsonEncode(encryptedAnswers);
      await _storage.storeSecurityQuestions(questionsJson);
      
      debugPrint('Security questions setup completed');
      return true;
    } catch (e) {
      debugPrint('Failed to setup security questions: $e');
      return false;
    }
  }

  /// Güvenlik sorularının ayarlanıp ayarlanmadığını kontrol eder
  Future<bool> areSecurityQuestionsSet() async {
    try {
      await _ensureInitialized();
      return await _storage.areSecurityQuestionsSet();
    } catch (e) {
      debugPrint('Failed to check security questions status: $e');
      return false;
    }
  }

  /// Rastgele güvenlik soruları seçer
  /// 
  /// [count] - Seçilecek soru sayısı (varsayılan: 3)
  /// 
  /// Returns seçilen sorular
  Future<List<SecurityQuestion>> getRecoveryQuestions({int count = 3}) async {
    try {
      await _ensureInitialized();
      
      if (!await areSecurityQuestionsSet()) {
        throw Exception('Güvenlik soruları ayarlanmamış');
      }
      
      // Kullanıcının ayarladığı soruları al
      final questionsJson = await _storage.getSecurityQuestions();
      if (questionsJson == null) {
        throw Exception('Güvenlik soruları bulunamadı');
      }
      
      final Map<String, dynamic> encryptedAnswers = jsonDecode(questionsJson);
      final List<String> userQuestionIds = encryptedAnswers.keys.toList();
      
      // Rastgele soru seç
      final random = Random();
      final selectedIds = <String>[];
      
      while (selectedIds.length < count && selectedIds.length < userQuestionIds.length) {
        final randomId = userQuestionIds[random.nextInt(userQuestionIds.length)];
        if (!selectedIds.contains(randomId)) {
          selectedIds.add(randomId);
        }
      }
      
      // Seçilen soruları döndür
      final selectedQuestions = <SecurityQuestion>[];
      for (final id in selectedIds) {
        final question = _predefinedQuestions.firstWhere(
          (q) => q.id == id,
          orElse: () => throw Exception('Soru bulunamadı: $id'),
        );
        selectedQuestions.add(question);
      }
      
      return selectedQuestions;
    } catch (e) {
      debugPrint('Failed to get recovery questions: $e');
      rethrow;
    }
  }

  /// Güvenlik sorusu cevabını doğrular
  /// 
  /// [questionId] - Soru ID'si
  /// [answer] - Kullanıcının verdiği cevap
  /// 
  /// Returns cevap doğru ise true
  Future<bool> verifyAnswer(String questionId, String answer) async {
    try {
      await _ensureInitialized();
      
      // Kullanıcının ayarladığı soruları al
      final questionsJson = await _storage.getSecurityQuestions();
      if (questionsJson == null) {
        return false;
      }
      
      final Map<String, dynamic> encryptedAnswers = jsonDecode(questionsJson);
      final encryptedAnswer = encryptedAnswers[questionId] as String?;
      
      if (encryptedAnswer == null) {
        return false;
      }
      
      // Get encryption key for security questions
      final encryptionKey = await _storage.getEncryptionKey();
      if (encryptionKey == null) {
        return false;
      }
      
      // Şifrelenmiş cevabı çöz
      final decryptedAnswer = EncryptionHelper.decrypt(encryptedAnswer, encryptionKey);
      final normalizedUserAnswer = answer.trim().toLowerCase();
      
      return decryptedAnswer == normalizedUserAnswer;
    } catch (e) {
      debugPrint('Failed to verify answer: $e');
      return false;
    }
  }

  /// Önceden tanımlı tüm soruları döndürür
  List<SecurityQuestion> getAllPredefinedQuestions() {
    return List.unmodifiable(_predefinedQuestions);
  }

  /// Kategoriye göre soruları filtreler
  List<SecurityQuestion> getQuestionsByCategory(SecurityQuestionCategory category) {
    return _predefinedQuestions
        .where((question) => question.category == category)
        .toList();
  }

  /// Tüm güvenlik sorusu verilerini temizler
  Future<bool> clearAllSecurityData() async {
    try {
      await _ensureInitialized();
      
      await _storage.clearSecurityQuestions();
      
      debugPrint('All security questions data cleared');
      return true;
    } catch (e) {
      debugPrint('Failed to clear security data: $e');
      return false;
    }
  }

  /// Test amaçlı servisi sıfırlar
  @visibleForTesting
  void resetForTesting() {
    _isInitialized = false;
    // ignore: invalid_use_of_visible_for_testing_member
    _storage.resetForTesting();
  }

  // Private helper methods

  /// Servisin başlatıldığından emin olur
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}
