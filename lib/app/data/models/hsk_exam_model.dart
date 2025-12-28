/// HSK Exam Overview model
class HskExamOverview {
  final List<String> availableLevels;
  final String userLevel;
  final ExamStats stats;
  final List<ExamAttemptSummary> recentAttempts;

  HskExamOverview({
    this.availableLevels = const ['HSK1', 'HSK2', 'HSK3', 'HSK4', 'HSK5', 'HSK6'],
    this.userLevel = 'HSK1',
    ExamStats? stats,
    this.recentAttempts = const [],
  }) : stats = stats ?? ExamStats();

  factory HskExamOverview.fromJson(Map<String, dynamic> json) {
    return HskExamOverview(
      availableLevels: (json['availableLevels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          ['HSK1', 'HSK2', 'HSK3', 'HSK4', 'HSK5', 'HSK6'],
      userLevel: json['userLevel'] as String? ?? 'HSK1',
      stats: json['stats'] != null
          ? ExamStats.fromJson(json['stats'] as Map<String, dynamic>)
          : ExamStats(),
      recentAttempts: (json['recentAttempts'] as List<dynamic>?)
              ?.map((e) => ExamAttemptSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'availableLevels': availableLevels,
        'userLevel': userLevel,
        'stats': stats.toJson(),
        'recentAttempts': recentAttempts.map((e) => e.toJson()).toList(),
      };
}

/// Exam statistics
class ExamStats {
  final int totalAttempts;
  final int averageScore;
  final int bestScore;
  final int passRate;

  ExamStats({
    this.totalAttempts = 0,
    this.averageScore = 0,
    this.bestScore = 0,
    this.passRate = 0,
  });

  factory ExamStats.fromJson(Map<String, dynamic> json) {
    return ExamStats(
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      averageScore: json['averageScore'] as int? ?? 0,
      bestScore: json['bestScore'] as int? ?? 0,
      passRate: json['passRate'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalAttempts': totalAttempts,
        'averageScore': averageScore,
        'bestScore': bestScore,
        'passRate': passRate,
      };
}

/// Mock test model
class MockTestModel {
  final String id;
  final String level;
  final String type; // "mock" | "practice"
  final String title;
  final String? description;
  final List<ExamSection> sections;
  final int totalQuestions;
  final int totalDuration; // minutes
  final int passingScore;
  final int maxScore;
  final bool isPremium;
  final int attempts;
  final int? bestScore;
  final DateTime? lastAttempt;

  MockTestModel({
    required this.id,
    required this.level,
    this.type = 'mock',
    required this.title,
    this.description,
    this.sections = const [],
    this.totalQuestions = 40,
    this.totalDuration = 35,
    this.passingScore = 60,
    this.maxScore = 100,
    this.isPremium = false,
    this.attempts = 0,
    this.bestScore,
    this.lastAttempt,
  });

  factory MockTestModel.fromJson(Map<String, dynamic> json) {
    return MockTestModel(
      id: json['id'] as String? ?? '',
      level: json['level'] as String? ?? 'HSK1',
      type: json['type'] as String? ?? 'mock',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => ExamSection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalQuestions: json['totalQuestions'] as int? ?? 40,
      totalDuration: json['totalDuration'] as int? ?? 35,
      passingScore: json['passingScore'] as int? ?? 60,
      maxScore: json['maxScore'] as int? ?? 100,
      isPremium: json['isPremium'] as bool? ?? false,
      attempts: json['attempts'] as int? ?? 0,
      bestScore: json['bestScore'] as int?,
      lastAttempt: json['lastAttempt'] != null
          ? DateTime.tryParse(json['lastAttempt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'level': level,
        'type': type,
        'title': title,
        'description': description,
        'sections': sections.map((e) => e.toJson()).toList(),
        'totalQuestions': totalQuestions,
        'totalDuration': totalDuration,
        'passingScore': passingScore,
        'maxScore': maxScore,
        'isPremium': isPremium,
        'attempts': attempts,
        'bestScore': bestScore,
        'lastAttempt': lastAttempt?.toIso8601String(),
      };

  /// Check if test is locked (premium required)
  bool isLocked(bool userIsPremium) => isPremium && !userIsPremium;

  /// Get level number
  int get levelInt => int.tryParse(level.replaceAll('HSK', '')) ?? 1;
}

/// Exam section (listening/reading)
class ExamSection {
  final String id;
  final String type; // "listening" | "reading"
  final String name;
  final String? instructions;
  final int duration; // minutes
  final int questionCount;
  final List<ExamQuestion> questions;

  ExamSection({
    required this.id,
    required this.type,
    required this.name,
    this.instructions,
    this.duration = 15,
    this.questionCount = 20,
    this.questions = const [],
  });

  factory ExamSection.fromJson(Map<String, dynamic> json) {
    return ExamSection(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'listening',
      name: json['name'] as String? ?? '',
      instructions: json['instructions'] as String?,
      duration: json['duration'] as int? ?? 15,
      questionCount: json['questionCount'] as int? ?? 20,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => ExamQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        'instructions': instructions,
        'duration': duration,
        'questionCount': questionCount,
        'questions': questions.map((e) => e.toJson()).toList(),
      };

  bool get isListening => type == 'listening';
  bool get isReading => type == 'reading';
}

/// Exam question
class ExamQuestion {
  final String id;
  final int order;
  final String type; // "listening_single", "listening_dialogue", "reading_match", "reading_comprehension"
  final String? audioUrl;
  final String? imageUrl;
  final String prompt;
  final String? passage;
  final String? context;
  final List<QuestionOption> options;

  ExamQuestion({
    required this.id,
    this.order = 0,
    required this.type,
    this.audioUrl,
    this.imageUrl,
    required this.prompt,
    this.passage,
    this.context,
    this.options = const [],
  });

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    return ExamQuestion(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      type: json['type'] as String? ?? 'listening_single',
      audioUrl: json['audioUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      prompt: json['prompt'] as String? ?? '',
      passage: json['passage'] as String?,
      context: json['context'] as String?,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => QuestionOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order': order,
        'type': type,
        'audioUrl': audioUrl,
        'imageUrl': imageUrl,
        'prompt': prompt,
        'passage': passage,
        'context': context,
        'options': options.map((e) => e.toJson()).toList(),
      };

  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
}

/// Question option
class QuestionOption {
  final String id;
  final String? text;
  final String? imageUrl;

  QuestionOption({
    required this.id,
    this.text,
    this.imageUrl,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['id'] as String? ?? '',
      text: json['text'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'imageUrl': imageUrl,
      };
}

/// Exam attempt summary
class ExamAttemptSummary {
  final String id;
  final String testId;
  final String? testTitle;
  final String level;
  final int score;
  final int maxScore;
  final bool passed;
  final int timeSpent; // seconds
  final DateTime completedAt;

  ExamAttemptSummary({
    required this.id,
    required this.testId,
    this.testTitle,
    required this.level,
    this.score = 0,
    this.maxScore = 100,
    this.passed = false,
    this.timeSpent = 0,
    required this.completedAt,
  });

  factory ExamAttemptSummary.fromJson(Map<String, dynamic> json) {
    return ExamAttemptSummary(
      id: json['id'] as String? ?? '',
      testId: json['testId'] as String? ?? '',
      testTitle: json['testTitle'] as String?,
      level: json['level'] as String? ?? 'HSK1',
      score: json['score'] as int? ?? 0,
      maxScore: json['maxScore'] as int? ?? 100,
      passed: json['passed'] as bool? ?? false,
      timeSpent: json['timeSpent'] as int? ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'testId': testId,
        'testTitle': testTitle,
        'level': level,
        'score': score,
        'maxScore': maxScore,
        'passed': passed,
        'timeSpent': timeSpent,
        'completedAt': completedAt.toIso8601String(),
      };

  /// Score percentage
  int get scorePercent => maxScore > 0 ? (score * 100 ~/ maxScore) : 0;

  /// Time spent formatted
  String get timeSpentFormatted {
    final minutes = timeSpent ~/ 60;
    final seconds = timeSpent % 60;
    return '${minutes}m ${seconds}s';
  }
}

/// Exam result after submission
class ExamResult {
  final String attemptId;
  final String testId;
  final int score;
  final int maxScore;
  final bool passed;
  final int passingScore;
  final int timeSpent;
  final DateTime completedAt;
  final SectionBreakdown? listeningBreakdown;
  final SectionBreakdown? readingBreakdown;
  final List<AnswerReview> answers;
  final bool isNewBest;
  final int? previousBest;

  ExamResult({
    required this.attemptId,
    required this.testId,
    this.score = 0,
    this.maxScore = 100,
    this.passed = false,
    this.passingScore = 60,
    this.timeSpent = 0,
    required this.completedAt,
    this.listeningBreakdown,
    this.readingBreakdown,
    this.answers = const [],
    this.isNewBest = false,
    this.previousBest,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>? ?? json;
    final breakdown = json['breakdown'] as Map<String, dynamic>?;

    return ExamResult(
      attemptId: result['attemptId'] as String? ?? '',
      testId: result['testId'] as String? ?? '',
      score: result['score'] as int? ?? 0,
      maxScore: result['maxScore'] as int? ?? 100,
      passed: result['passed'] as bool? ?? false,
      passingScore: result['passingScore'] as int? ?? 60,
      timeSpent: result['timeSpent'] as int? ?? 0,
      completedAt: result['completedAt'] != null
          ? DateTime.parse(result['completedAt'] as String)
          : DateTime.now(),
      listeningBreakdown: breakdown?['listening'] != null
          ? SectionBreakdown.fromJson(breakdown!['listening'] as Map<String, dynamic>)
          : null,
      readingBreakdown: breakdown?['reading'] != null
          ? SectionBreakdown.fromJson(breakdown!['reading'] as Map<String, dynamic>)
          : null,
      answers: (json['answers'] as List<dynamic>?)
              ?.map((e) => AnswerReview.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isNewBest: json['isNewBest'] as bool? ?? false,
      previousBest: json['previousBest'] as int?,
    );
  }

  int get scorePercent => maxScore > 0 ? (score * 100 ~/ maxScore) : 0;
}

/// Section breakdown in result
class SectionBreakdown {
  final int correct;
  final int total;
  final double score;
  final double maxScore;

  SectionBreakdown({
    this.correct = 0,
    this.total = 0,
    this.score = 0,
    this.maxScore = 50,
  });

  factory SectionBreakdown.fromJson(Map<String, dynamic> json) {
    return SectionBreakdown(
      correct: json['correct'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      maxScore: (json['maxScore'] as num?)?.toDouble() ?? 50,
    );
  }

  int get percentage => total > 0 ? (correct * 100 ~/ total) : 0;
}

/// Answer review
class AnswerReview {
  final String questionId;
  final String selectedOption;
  final String correctOption;
  final bool isCorrect;
  final String? explanation;

  AnswerReview({
    required this.questionId,
    required this.selectedOption,
    required this.correctOption,
    this.isCorrect = false,
    this.explanation,
  });

  factory AnswerReview.fromJson(Map<String, dynamic> json) {
    return AnswerReview(
      questionId: json['questionId'] as String? ?? '',
      selectedOption: json['selectedOption'] as String? ?? '',
      correctOption: json['correctOption'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'selectedOption': selectedOption,
        'correctOption': correctOption,
        'isCorrect': isCorrect,
        'explanation': explanation,
      };
}

/// Active exam attempt
class ExamAttempt {
  final String id;
  final DateTime startedAt;
  final DateTime expiresAt;

  ExamAttempt({
    required this.id,
    required this.startedAt,
    required this.expiresAt,
  });

  factory ExamAttempt.fromJson(Map<String, dynamic> json) {
    return ExamAttempt(
      id: json['id'] as String? ?? '',
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : DateTime.now().add(const Duration(hours: 1)),
    );
  }

  /// Time remaining in seconds
  int get remainingSeconds {
    final diff = expiresAt.difference(DateTime.now());
    return diff.inSeconds.clamp(0, 9999);
  }

  /// Check if attempt has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Time remaining formatted (MM:SS)
  String get remainingFormatted {
    final remaining = remainingSeconds;
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

