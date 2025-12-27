import '../models/vocab_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Pronunciation practice repository
class PronunciationRepo {
  final ApiClient _api;

  PronunciationRepo(this._api);

  /// Get words for pronunciation practice
  Future<List<VocabModel>> getWords({
    String? level,
    int count = 10,
  }) async {
    final response = await _api.get(
      ApiEndpoints.pronunciationWords,
      queryParameters: {
        if (level != null) 'level': level,
        'count': count,
      },
    );
    final data = response.data['data'] ?? response.data;
    return (data as List).map((e) => VocabModel.fromJson(e)).toList();
  }

  /// Evaluate pronunciation
  /// Returns score 0-100 and feedback
  Future<PronunciationEvaluation> evaluate({
    required String vocabId,
    required String spokenText, // STT result
    int? manualScore, // Optional manual score if no STT
  }) async {
    final response = await _api.post(
      ApiEndpoints.pronunciationEvaluate,
      data: {
        'vocabId': vocabId,
        if (spokenText.isNotEmpty) 'spokenText': spokenText,
        if (manualScore != null) 'manualScore': manualScore,
      },
    );
    final data = response.data['data'] ?? response.data;
    return PronunciationEvaluation.fromJson(data);
  }

  /// Submit pronunciation session
  Future<PronunciationSessionResult> submitSession({
    required List<PronunciationAttempt> attempts,
    required int totalDuration, // milliseconds
  }) async {
    final response = await _api.post(
      ApiEndpoints.pronunciationSession,
      data: {
        'attempts': attempts.map((e) => e.toJson()).toList(),
        'totalDuration': totalDuration,
      },
    );
    final data = response.data['data'] ?? response.data;
    return PronunciationSessionResult.fromJson(data);
  }

  /// Get pronunciation history
  Future<List<PronunciationSession>> getHistory({
    int limit = 20,
    int page = 1,
  }) async {
    final response = await _api.get(
      ApiEndpoints.pronunciationHistory,
      queryParameters: {
        'limit': limit,
        'page': page,
      },
    );
    final data = response.data['data'] ?? response.data;
    return (data as List).map((e) => PronunciationSession.fromJson(e)).toList();
  }
}

/// Pronunciation evaluation result
class PronunciationEvaluation {
  final String vocabId;
  final int score; // 0-100
  final String feedback;
  final bool passed; // score >= 70
  final String? detailedFeedback;
  final Map<String, double>? phonemeScores;

  PronunciationEvaluation({
    required this.vocabId,
    required this.score,
    required this.feedback,
    required this.passed,
    this.detailedFeedback,
    this.phonemeScores,
  });

  factory PronunciationEvaluation.fromJson(Map<String, dynamic> json) {
    return PronunciationEvaluation(
      vocabId: json['vocabId'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      feedback: json['feedback'] as String? ?? '',
      passed: json['passed'] as bool? ?? (json['score'] as int? ?? 0) >= 70,
      detailedFeedback: json['detailedFeedback'] as String?,
      phonemeScores: (json['phonemeScores'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }

  String get feedbackEmoji {
    if (score >= 90) return '🌟';
    if (score >= 80) return '👏';
    if (score >= 70) return '✅';
    if (score >= 50) return '🔄';
    return '💪';
  }
}

/// Pronunciation attempt
class PronunciationAttempt {
  final String vocabId;
  final int score;
  final String? spokenText;
  final int duration; // milliseconds

  PronunciationAttempt({
    required this.vocabId,
    required this.score,
    this.spokenText,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'vocabId': vocabId,
      'score': score,
      if (spokenText != null) 'spokenText': spokenText,
      'duration': duration,
    };
  }
}

/// Pronunciation session result
class PronunciationSessionResult {
  final String sessionId;
  final int totalAttempts;
  final int passedCount;
  final double averageScore;
  final int totalDuration;
  final List<String>? newAchievements;

  PronunciationSessionResult({
    required this.sessionId,
    required this.totalAttempts,
    required this.passedCount,
    required this.averageScore,
    required this.totalDuration,
    this.newAchievements,
  });

  factory PronunciationSessionResult.fromJson(Map<String, dynamic> json) {
    return PronunciationSessionResult(
      sessionId: json['sessionId'] as String? ?? json['_id'] as String? ?? '',
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      passedCount: json['passedCount'] as int? ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0,
      totalDuration: json['totalDuration'] as int? ?? 0,
      newAchievements: (json['newAchievements'] as List?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  double get passRate =>
      totalAttempts > 0 ? (passedCount / totalAttempts) * 100 : 0;
}

/// Pronunciation session history item
class PronunciationSession {
  final String id;
  final int totalAttempts;
  final int passedCount;
  final double averageScore;
  final int totalDuration;
  final DateTime createdAt;

  PronunciationSession({
    required this.id,
    required this.totalAttempts,
    required this.passedCount,
    required this.averageScore,
    required this.totalDuration,
    required this.createdAt,
  });

  factory PronunciationSession.fromJson(Map<String, dynamic> json) {
    return PronunciationSession(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      passedCount: json['passedCount'] as int? ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0,
      totalDuration: json['totalDuration'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

