/// Güvenlik sorusu modeli
class SecurityQuestion {
  /// Soru ID'si
  final String id;
  
  /// Soru metni
  final String question;
  
  /// Kullanıcının cevabı (şifrelenmiş)
  final String? answer;
  
  /// Soru kategorisi
  final SecurityQuestionCategory category;
  
  /// Soru aktif mi?
  final bool isActive;
  
  /// Oluşturulma zamanı
  final DateTime createdAt;

  SecurityQuestion({
    required this.id,
    required this.question,
    this.answer,
    required this.category,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// JSON'dan oluşturur
  factory SecurityQuestion.fromJson(Map<String, dynamic> json) {
    return SecurityQuestion(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String?,
      category: SecurityQuestionCategory.values.firstWhere(
        (cat) => cat.name == json['category'],
        orElse: () => SecurityQuestionCategory.personal,
      ),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Kopya oluşturur
  SecurityQuestion copyWith({
    String? id,
    String? question,
    String? answer,
    SecurityQuestionCategory? category,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return SecurityQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SecurityQuestion &&
        other.id == id &&
        other.question == question &&
        other.answer == answer &&
        other.category == category &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(id, question, answer, category, isActive);
  }

  @override
  String toString() {
    return 'SecurityQuestion(id: $id, question: $question, category: $category, isActive: $isActive)';
  }
}

/// Güvenlik sorusu kategorileri
enum SecurityQuestionCategory {
  /// Kişisel bilgiler
  personal,
  
  /// Aile bilgileri
  family,
  
  /// Eğitim bilgileri
  education,
  
  /// Hobiler ve ilgi alanları
  hobbies,
  
  /// Geçmiş deneyimler
  experiences;

  /// Kullanıcı dostu isim döndürür
  String get displayName {
    switch (this) {
      case SecurityQuestionCategory.personal:
        return 'Kişisel Bilgiler';
      case SecurityQuestionCategory.family:
        return 'Aile Bilgileri';
      case SecurityQuestionCategory.education:
        return 'Eğitim Bilgileri';
      case SecurityQuestionCategory.hobbies:
        return 'Hobiler ve İlgi Alanları';
      case SecurityQuestionCategory.experiences:
        return 'Geçmiş Deneyimler';
    }
  }
}

/// PIN kurtarma durumu
class PINRecoveryState {
  /// Kurtarma işlemi aktif mi?
  final bool isActive;
  
  /// Mevcut adım
  final PINRecoveryStep currentStep;
  
  /// Doğrulanan soru sayısı
  final int verifiedQuestions;
  
  /// Toplam soru sayısı
  final int totalQuestions;
  
  /// Başlangıç zamanı
  final DateTime startTime;
  
  /// Son aktivite zamanı
  final DateTime lastActivity;
  
  /// Hata sayısı
  final int errorCount;

  PINRecoveryState({
    this.isActive = false,
    this.currentStep = PINRecoveryStep.securityQuestions,
    this.verifiedQuestions = 0,
    this.totalQuestions = 3,
    DateTime? startTime,
    DateTime? lastActivity,
    this.errorCount = 0,
  }) : startTime = startTime ?? DateTime.fromMillisecondsSinceEpoch(0),
       lastActivity = lastActivity ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'currentStep': currentStep.name,
      'verifiedQuestions': verifiedQuestions,
      'totalQuestions': totalQuestions,
      'startTime': startTime.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'errorCount': errorCount,
    };
  }

  /// JSON'dan oluşturur
  factory PINRecoveryState.fromJson(Map<String, dynamic> json) {
    return PINRecoveryState(
      isActive: json['isActive'] as bool? ?? false,
      currentStep: PINRecoveryStep.values.firstWhere(
        (step) => step.name == json['currentStep'],
        orElse: () => PINRecoveryStep.securityQuestions,
      ),
      verifiedQuestions: json['verifiedQuestions'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? 3,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : DateTime.now(),
      lastActivity: json['lastActivity'] != null
          ? DateTime.parse(json['lastActivity'] as String)
          : DateTime.now(),
      errorCount: json['errorCount'] as int? ?? 0,
    );
  }

  /// Kopya oluşturur
  PINRecoveryState copyWith({
    bool? isActive,
    PINRecoveryStep? currentStep,
    int? verifiedQuestions,
    int? totalQuestions,
    DateTime? startTime,
    DateTime? lastActivity,
    int? errorCount,
  }) {
    return PINRecoveryState(
      isActive: isActive ?? this.isActive,
      currentStep: currentStep ?? this.currentStep,
      verifiedQuestions: verifiedQuestions ?? this.verifiedQuestions,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      startTime: startTime ?? this.startTime,
      lastActivity: lastActivity ?? this.lastActivity,
      errorCount: errorCount ?? this.errorCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PINRecoveryState &&
        other.isActive == isActive &&
        other.currentStep == currentStep &&
        other.verifiedQuestions == verifiedQuestions &&
        other.totalQuestions == totalQuestions &&
        other.errorCount == errorCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      isActive,
      currentStep,
      verifiedQuestions,
      totalQuestions,
      errorCount,
    );
  }

  @override
  String toString() {
    return 'PINRecoveryState(isActive: $isActive, currentStep: $currentStep, '
           'verifiedQuestions: $verifiedQuestions/$totalQuestions, errorCount: $errorCount)';
  }
}

/// PIN kurtarma adımları
enum PINRecoveryStep {
  /// Güvenlik soruları
  securityQuestions,
  
  /// Email/SMS doğrulama
  verification,
  
  /// Yeni PIN oluşturma
  newPIN,
  
  /// Tamamlandı
  completed;

  /// Kullanıcı dostu isim döndürür
  String get displayName {
    switch (this) {
      case PINRecoveryStep.securityQuestions:
        return 'Güvenlik Soruları';
      case PINRecoveryStep.verification:
        return 'Doğrulama';
      case PINRecoveryStep.newPIN:
        return 'Yeni PIN';
      case PINRecoveryStep.completed:
        return 'Tamamlandı';
    }
  }
}