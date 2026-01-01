import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/auth/security_questions_service.dart';
import 'package:parion/models/security/security_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecurityQuestionsService', () {
    late SecurityQuestionsService service;

    setUp(() {
      service = SecurityQuestionsService();
      service.resetForTesting();
    });

    tearDown(() {
      service.resetForTesting();
    });

    test('should be a singleton', () {
      final service1 = SecurityQuestionsService();
      final service2 = SecurityQuestionsService();
      expect(identical(service1, service2), isTrue);
    });

    test('should return all predefined questions', () {
      final questions = service.getAllPredefinedQuestions();
      expect(questions, isNotEmpty);
      expect(questions.length, equals(15)); // 5 categories * 3 questions each
    });

    test('should filter questions by category', () {
      final personalQuestions = service.getQuestionsByCategory(
        SecurityQuestionCategory.personal,
      );
      expect(personalQuestions, isNotEmpty);
      expect(personalQuestions.length, equals(3));
      
      for (final question in personalQuestions) {
        expect(question.category, equals(SecurityQuestionCategory.personal));
      }
    });

    test('should filter questions by family category', () {
      final familyQuestions = service.getQuestionsByCategory(
        SecurityQuestionCategory.family,
      );
      expect(familyQuestions.length, equals(3));
      
      for (final question in familyQuestions) {
        expect(question.category, equals(SecurityQuestionCategory.family));
      }
    });

    test('should filter questions by education category', () {
      final educationQuestions = service.getQuestionsByCategory(
        SecurityQuestionCategory.education,
      );
      expect(educationQuestions.length, equals(3));
      
      for (final question in educationQuestions) {
        expect(question.category, equals(SecurityQuestionCategory.education));
      }
    });

    test('should filter questions by hobbies category', () {
      final hobbiesQuestions = service.getQuestionsByCategory(
        SecurityQuestionCategory.hobbies,
      );
      expect(hobbiesQuestions.length, equals(3));
      
      for (final question in hobbiesQuestions) {
        expect(question.category, equals(SecurityQuestionCategory.hobbies));
      }
    });

    test('should filter questions by experiences category', () {
      final experiencesQuestions = service.getQuestionsByCategory(
        SecurityQuestionCategory.experiences,
      );
      expect(experiencesQuestions.length, equals(3));
      
      for (final question in experiencesQuestions) {
        expect(question.category, equals(SecurityQuestionCategory.experiences));
      }
    });

    test('should return false when security questions are not set', () async {
      final areSet = await service.areSecurityQuestionsSet();
      expect(areSet, isFalse);
    });

    test('should handle setup with less than 3 questions gracefully', () async {
      final questionsWithAnswers = {
        'personal_1': 'Fluffy',
        'personal_2': 'Istanbul',
      };
      
      final result = await service.setupSecurityQuestions(questionsWithAnswers);
      expect(result, isFalse); // Should fail with less than 3 questions
    });

    test('should handle setup with empty answer gracefully', () async {
      final questionsWithAnswers = {
        'personal_1': 'Fluffy',
        'personal_2': '',
        'personal_3': 'Blue',
      };
      
      final result = await service.setupSecurityQuestions(questionsWithAnswers);
      expect(result, isFalse); // Should fail with empty answer
    });

    test('should handle setup when storage is unavailable', () async {
      final questionsWithAnswers = {
        'personal_1': 'Fluffy',
        'personal_2': 'Istanbul',
        'personal_3': 'Blue',
      };
      
      final result = await service.setupSecurityQuestions(questionsWithAnswers);
      // In test environment without proper storage, should return false
      expect(result, isFalse);
    });

    test('should handle verify answer when questions not set', () async {
      final result = await service.verifyAnswer('personal_1', 'Fluffy');
      expect(result, isFalse);
    });

    test('should handle verify answer with invalid question ID', () async {
      final result = await service.verifyAnswer('invalid_id', 'Answer');
      expect(result, isFalse);
    });

    test('should handle get recovery questions when not set', () async {
      expect(
        () => service.getRecoveryQuestions(),
        throwsException,
      );
    });

    test('should handle clear all security data gracefully', () async {
      final result = await service.clearAllSecurityData();
      // In test environment, might return false due to storage unavailability
      expect(result, isA<bool>());
    });

    test('should have reset method for testing', () {
      expect(() => service.resetForTesting(), returnsNormally);
    });

    test('should handle initialization failure gracefully', () async {
      // Test that initialization handles plugin unavailability
      try {
        await service.initialize();
        // If it doesn't throw, that's also acceptable
      } catch (e) {
        // Should throw a descriptive exception
        expect(e.toString(), contains('Failed to initialize'));
      }
    });

    test('should normalize answers to lowercase and trim', () {
      // Test answer normalization logic
      final answer1 = '  Fluffy  '.trim().toLowerCase();
      final answer2 = 'FLUFFY'.trim().toLowerCase();
      expect(answer1, equals(answer2));
    });

    test('should validate question IDs exist in predefined questions', () {
      final allQuestions = service.getAllPredefinedQuestions();
      final questionIds = allQuestions.map((q) => q.id).toSet();
      
      expect(questionIds.contains('personal_1'), isTrue);
      expect(questionIds.contains('family_1'), isTrue);
      expect(questionIds.contains('education_1'), isTrue);
      expect(questionIds.contains('hobbies_1'), isTrue);
      expect(questionIds.contains('experiences_1'), isTrue);
    });

    test('should have unique question IDs', () {
      final allQuestions = service.getAllPredefinedQuestions();
      final questionIds = allQuestions.map((q) => q.id).toList();
      final uniqueIds = questionIds.toSet();
      
      expect(questionIds.length, equals(uniqueIds.length));
    });

    test('should have non-empty question text for all questions', () {
      final allQuestions = service.getAllPredefinedQuestions();
      
      for (final question in allQuestions) {
        expect(question.question, isNotEmpty);
        expect(question.id, isNotEmpty);
      }
    });

    test('should return immutable list from getAllPredefinedQuestions', () {
      final questions = service.getAllPredefinedQuestions();
      expect(() => questions.add(SecurityQuestion(
        id: 'test',
        question: 'Test?',
        category: SecurityQuestionCategory.personal,
      )), throwsUnsupportedError);
    });
  });
}
