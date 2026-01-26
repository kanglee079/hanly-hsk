import '../models/today_model.dart';
import '../models/study_modes_model.dart';
import '../models/vocab_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../../core/utils/logger.dart';

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final String? code;

  ApiException(this.message, {this.code});

  @override
  String toString() => 'ApiException: $message (code: $code)';
}

/// Learning repository - matches BE API exactly
class LearningRepo {
  final ApiClient _api;

  LearningRepo(this._api);

  /// Get today's learning data
  /// BE endpoint: GET /today
  /// Response: { success, data: { newQueue[], reviewQueue[], todayStats{} } }
  Future<TodayModel> getToday() async {
    final response = await _api.get(ApiEndpoints.today);
    final data = response.data;

    // Check for API error response
    if (data is Map<String, dynamic>) {
      if (data['success'] == false) {
        final error = data['error'] as Map<String, dynamic>?;
        final message = error?['message'] as String? ?? 'Lỗi không xác định';
        final code = error?['code'] as String?;
        Logger.e('LearningRepo', 'getToday failed: $message ($code)');
        throw ApiException(message, code: code);
      }
    }

    return TodayModel.fromJson(data);
  }

  /// Submit review answer
  /// BE endpoint: POST /review/answer
  /// Body: { vocabId, rating, mode, timeSpent }
  Future<ReviewAnswerResponse> submitReviewAnswer({
    required String vocabId,
    required ReviewRating rating,
    String mode = 'flashcard',
    int timeSpent = 5000, // milliseconds
  }) async {
    final response = await _api.post(
      ApiEndpoints.reviewAnswer,
      data: {
        'vocabId': vocabId,
        'rating': rating.value,
        'mode': mode,
        'timeSpent': timeSpent,
      },
    );

    final data = response.data;
    Logger.d('LearningRepo', 'submitReviewAnswer response: $data');

    // Check for API error response
    if (data is Map<String, dynamic>) {
      if (data['success'] == false) {
        final error = data['error'] as Map<String, dynamic>?;
        final message = error?['message'] as String? ?? 'Lỗi không xác định';
        final code = error?['code'] as String?;
        Logger.e('LearningRepo', 'submitReviewAnswer failed: $message ($code)');
        throw ApiException(message, code: code);
      }
    }

    return ReviewAnswerResponse.fromJson(data);
  }

  /// Finish session
  /// BE endpoint: POST /session/finish
  /// Body: { minutes, newCount, reviewCount, accuracy, dateKey }
  Future<SessionFinishResponse> finishSession(SessionResultModel result) async {
    final response = await _api.post(
      ApiEndpoints.sessionFinish,
      data: result.toJson(),
    );

    final data = response.data;
    Logger.d('LearningRepo', 'finishSession response: $data');

    // Check for API error response
    if (data is Map<String, dynamic>) {
      if (data['success'] == false) {
        final error = data['error'] as Map<String, dynamic>?;
        final message = error?['message'] as String? ?? 'Lỗi không xác định';
        final code = error?['code'] as String?;
        Logger.e('LearningRepo', 'finishSession failed: $message ($code)');
        throw ApiException(message, code: code);
      }
    }

    return SessionFinishResponse.fromJson(data);
  }

  /// Get study modes data
  /// BE endpoint: GET /study-modes
  Future<StudyModesResponse> getStudyModes() async {
    final response = await _api.get(ApiEndpoints.studyModes);
    final data = response.data;

    // Check for API error response
    if (data is Map<String, dynamic>) {
      if (data['success'] == false) {
        final error = data['error'] as Map<String, dynamic>?;
        final message = error?['message'] as String? ?? 'Lỗi không xác định';
        final code = error?['code'] as String?;
        Logger.e('LearningRepo', 'getStudyModes failed: $message ($code)');
        throw ApiException(message, code: code);
      }
    }

    return StudyModesResponse.fromJson(data);
  }

  /// Get words for a specific study mode
  /// BE endpoint: GET /study-modes/:modeId/words
  Future<List<VocabModel>> getStudyModeWords(String modeId, {int limit = 20}) async {
    final response = await _api.get(
      ApiEndpoints.studyModeWords(modeId),
      queryParameters: {'limit': limit},
    );
    final data = response.data;

    // Check for API error response
    if (data is Map<String, dynamic>) {
      if (data['success'] == false) {
        final error = data['error'] as Map<String, dynamic>?;
        final message = error?['message'] as String? ?? 'Lỗi không xác định';
        final code = error?['code'] as String?;
        Logger.e('LearningRepo', 'getStudyModeWords failed: $message ($code)');
        throw ApiException(message, code: code);
      }
    }

    // Parse response - handle both wrapped and unwrapped
    final wordsData = data['data']?['words'] ?? data['words'] ?? [];
    return (wordsData as List<dynamic>)
        .map((e) => VocabModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get all learned vocabs for games
  /// BE endpoint: GET /me/learned-vocabs
  /// Query params: limit, state (learning|review|mastered|all), shuffle
  Future<LearnedVocabsResponse> getLearnedVocabs({
    int limit = 100,
    String state = 'all',
    bool shuffle = true,
  }) async {
    final response = await _api.get(
      ApiEndpoints.meLearnedVocabs,
      queryParameters: {
        'limit': limit,
        'state': state,
        'shuffle': shuffle,
      },
    );
    final data = response.data;

    // Check for API error response
    if (data is Map<String, dynamic>) {
      if (data['success'] == false) {
        final error = data['error'] as Map<String, dynamic>?;
        final message = error?['message'] as String? ?? 'Lỗi không xác định';
        final code = error?['code'] as String?;
        Logger.e('LearningRepo', 'getLearnedVocabs failed: $message ($code)');
        throw ApiException(message, code: code);
      }
    }

    return LearnedVocabsResponse.fromJson(data);
  }

  /// Batch sync progress events (offline-first)
  /// BE endpoint: POST /sync/progress
  Future<ProgressSyncResponse> syncProgressBatch({
    required List<Map<String, dynamic>> events,
  }) async {
    final response = await _api.post(
      ApiEndpoints.syncProgress,
      data: {'events': events},
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == false) {
      final error = data['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String? ?? 'Lỗi không xác định';
      final code = error?['code'] as String?;
      Logger.e('LearningRepo', 'syncProgressBatch failed: $message ($code)');
      throw ApiException(message, code: code);
    }

    return ProgressSyncResponse.fromJson(data);
  }
}

class ProgressSyncResponse {
  final List<String> acked;
  final List<ProgressSyncFailure> failed;
  final String serverTime;

  ProgressSyncResponse({
    required this.acked,
    required this.failed,
    required this.serverTime,
  });

  factory ProgressSyncResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final acked = (data['acked'] as List<dynamic>? ?? []).cast<String>();
    final failedRaw = data['failed'] as List<dynamic>? ?? [];
    final failed = failedRaw
        .map((e) => ProgressSyncFailure.fromJson(e as Map<String, dynamic>))
        .toList();
    return ProgressSyncResponse(
      acked: acked,
      failed: failed,
      serverTime: data['serverTime'] as String? ?? '',
    );
  }
}

class ProgressSyncFailure {
  final String eventId;
  final String error;

  ProgressSyncFailure({
    required this.eventId,
    required this.error,
  });

  factory ProgressSyncFailure.fromJson(Map<String, dynamic> json) {
    return ProgressSyncFailure(
      eventId: json['eventId'] as String? ?? '',
      error: json['error'] as String? ?? '',
    );
  }
}

/// Response model for learned vocabs API
class LearnedVocabsResponse {
  final List<VocabModel> vocabs;
  final int total;
  final int returned;

  LearnedVocabsResponse({
    required this.vocabs,
    required this.total,
    required this.returned,
  });

  factory LearnedVocabsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final vocabsData = data['vocabs'] as List<dynamic>? ?? [];
    
    return LearnedVocabsResponse(
      vocabs: vocabsData
          .map((e) => VocabModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: data['total'] as int? ?? 0,
      returned: data['returned'] as int? ?? vocabsData.length,
    );
  }
}
