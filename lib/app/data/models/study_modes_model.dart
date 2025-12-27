// Study modes API models - matches BE API response
// GET /study-modes

/// Quick review data
class QuickReviewModel {
  final bool available;
  final int wordCount;
  final int estimatedMinutes;

  QuickReviewModel({
    this.available = false,
    this.wordCount = 0,
    this.estimatedMinutes = 3,
  });

  factory QuickReviewModel.fromJson(Map<String, dynamic> json) {
    return QuickReviewModel(
      available: json['available'] as bool? ?? false,
      wordCount: _safeInt(json['wordCount']),
      estimatedMinutes: _safeInt(json['estimatedMinutes'], 3),
    );
  }

  Map<String, dynamic> toJson() => {
        'available': available,
        'wordCount': wordCount,
        'estimatedMinutes': estimatedMinutes,
      };
}

/// Individual study mode
class StudyModeModel {
  final String id; // srs_vocabulary, listening, writing, matching, comprehensive
  final String name; // "Thẻ từ"
  final String nameEn; // "SRS Vocabulary"
  final String description; // "20 từ cần ôn tập"
  final String icon; // "📚" or icon name
  final int estimatedMinutes;
  final int wordCount;
  final bool isPremium;
  final bool isAvailable;
  final String? unavailableReason;

  StudyModeModel({
    required this.id,
    required this.name,
    this.nameEn = '',
    this.description = '',
    this.icon = '',
    this.estimatedMinutes = 5,
    this.wordCount = 0,
    this.isPremium = false,
    this.isAvailable = true,
    this.unavailableReason,
  });

  factory StudyModeModel.fromJson(Map<String, dynamic> json) {
    return StudyModeModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      estimatedMinutes: _safeInt(json['estimatedMinutes'], 5),
      wordCount: _safeInt(json['wordCount']),
      isPremium: json['isPremium'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      unavailableReason: json['unavailableReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameEn': nameEn,
        'description': description,
        'icon': icon,
        'estimatedMinutes': estimatedMinutes,
        'wordCount': wordCount,
        'isPremium': isPremium,
        'isAvailable': isAvailable,
        'unavailableReason': unavailableReason,
      };
}

/// Today progress summary
class TodayProgressModel {
  final int completedMinutes;
  final int goalMinutes;
  final int newLearned;
  final int reviewed;
  final int accuracy;

  TodayProgressModel({
    this.completedMinutes = 0,
    this.goalMinutes = 15,
    this.newLearned = 0,
    this.reviewed = 0,
    this.accuracy = 0,
  });

  factory TodayProgressModel.fromJson(Map<String, dynamic> json) {
    return TodayProgressModel(
      completedMinutes: _safeInt(json['completedMinutes']),
      goalMinutes: _safeInt(json['goalMinutes'], 15),
      newLearned: _safeInt(json['newLearned']),
      reviewed: _safeInt(json['reviewed']),
      accuracy: _safeInt(json['accuracy']),
    );
  }

  Map<String, dynamic> toJson() => {
        'completedMinutes': completedMinutes,
        'goalMinutes': goalMinutes,
        'newLearned': newLearned,
        'reviewed': reviewed,
        'accuracy': accuracy,
      };

  double get progressPercent {
    if (goalMinutes == 0) return 0;
    return (completedMinutes / goalMinutes).clamp(0.0, 1.0);
  }
}

/// Main study modes response
class StudyModesResponse {
  final String date;
  final int streak;
  final bool isPremium;
  final QuickReviewModel quickReview;
  final List<StudyModeModel> studyModes;
  final TodayProgressModel todayProgress;

  StudyModesResponse({
    required this.date,
    this.streak = 0,
    this.isPremium = false,
    required this.quickReview,
    required this.studyModes,
    required this.todayProgress,
  });

  factory StudyModesResponse.fromJson(Map<String, dynamic> json) {
    // Handle wrapped response: { success: true, data: {...} }
    final data = json['data'] ?? json;

    return StudyModesResponse(
      date: data['date'] as String? ?? '',
      streak: _safeInt(data['streak']),
      isPremium: data['isPremium'] as bool? ?? false,
      quickReview: data['quickReview'] != null
          ? QuickReviewModel.fromJson(data['quickReview'] as Map<String, dynamic>)
          : QuickReviewModel(),
      studyModes: (data['studyModes'] as List<dynamic>?)
              ?.map((e) => StudyModeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      todayProgress: data['todayProgress'] != null
          ? TodayProgressModel.fromJson(data['todayProgress'] as Map<String, dynamic>)
          : TodayProgressModel(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'streak': streak,
        'isPremium': isPremium,
        'quickReview': quickReview.toJson(),
        'studyModes': studyModes.map((e) => e.toJson()).toList(),
        'todayProgress': todayProgress.toJson(),
      };

  /// Get mode by ID
  StudyModeModel? getModeById(String id) {
    try {
      return studyModes.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Helper function to safely parse int
int _safeInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

