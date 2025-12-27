import '../models/level_progress_model.dart';
import '../models/vocab_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Progress Repository - Level progress and mastery APIs
class ProgressRepo {
  final ApiClient _api;

  ProgressRepo(this._api);

  /// Get current level progress with mastery info
  /// GET /me/progress/level
  Future<LevelProgressModel> getLevelProgress() async {
    final response = await _api.get(ApiEndpoints.meProgressLevel);
    return LevelProgressModel.fromJson(response.data);
  }

  /// Attempt to unlock next batch
  /// POST /me/progress/unlock-next
  /// Returns error 400 if mastery requirement not met
  Future<UnlockNextResponse> unlockNext() async {
    final response = await _api.post(ApiEndpoints.meProgressUnlockNext);
    return UnlockNextResponse.fromJson(response.data);
  }

  /// Get words that need mastery in current batch
  /// GET /me/progress/needs-mastery?limit=20
  Future<List<VocabModel>> getNeedsMastery({int limit = 20}) async {
    final response = await _api.get(
      ApiEndpoints.meProgressNeedsMastery,
      queryParameters: {'limit': limit},
    );
    final data = response.data['data'] ?? response.data;
    final List<dynamic> vocabs = data['vocabs'] ?? [];
    return vocabs.map((e) => VocabModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

/// Response from unlock-next API
class UnlockNextResponse {
  final bool success;
  final String? newBatch;
  final String? message;
  final String? errorCode;

  UnlockNextResponse({
    required this.success,
    this.newBatch,
    this.message,
    this.errorCode,
  });

  factory UnlockNextResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final error = json['error'] as Map<String, dynamic>?;
    
    return UnlockNextResponse(
      success: json['success'] as bool? ?? data['success'] as bool? ?? false,
      newBatch: data['newBatch'] as String?,
      message: data['message'] as String? ?? error?['message'] as String?,
      errorCode: error?['code'] as String?,
    );
  }

  bool get isMasteryRequired => errorCode == 'MASTERY_REQUIRED';
}

