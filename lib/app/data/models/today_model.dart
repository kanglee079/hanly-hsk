import 'vocab_model.dart';
import '../repositories/game_repo.dart' show GameLimitInfo;

/// Streak status details from BE
class StreakStatus {
  final bool hasStudiedToday;
  final DateTime? lastStudyDate;
  final DateTime? streakSafeUntil;
  final DateTime? willLoseStreakAt;

  StreakStatus({
    this.hasStudiedToday = false,
    this.lastStudyDate,
    this.streakSafeUntil,
    this.willLoseStreakAt,
  });

  factory StreakStatus.fromJson(Map<String, dynamic> json) {
    return StreakStatus(
      hasStudiedToday: json['hasStudiedToday'] as bool? ?? false,
      lastStudyDate: json['lastStudyDate'] != null
          ? DateTime.tryParse(json['lastStudyDate'] as String)
          : null,
      streakSafeUntil: json['streakSafeUntil'] != null
          ? DateTime.tryParse(json['streakSafeUntil'] as String)
          : null,
      willLoseStreakAt: json['willLoseStreakAt'] != null
          ? DateTime.tryParse(json['willLoseStreakAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasStudiedToday': hasStudiedToday,
      'lastStudyDate': lastStudyDate?.toIso8601String(),
      'streakSafeUntil': streakSafeUntil?.toIso8601String(),
      'willLoseStreakAt': willLoseStreakAt?.toIso8601String(),
    };
  }

  /// Time remaining until streak is lost (human readable)
  String get timeUntilLoseStreak {
    if (willLoseStreakAt == null) return '';
    final diff = willLoseStreakAt!.difference(DateTime.now());
    if (diff.isNegative) return 'Đã mất streak!';

    if (diff.inDays > 0) {
      return '${diff.inDays} ngày ${diff.inHours % 24} giờ';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} giờ ${diff.inMinutes % 60} phút';
    } else {
      return '${diff.inMinutes} phút';
    }
  }

  /// Check if streak is at risk (less than 6 hours remaining)
  bool get isAtRisk {
    if (hasStudiedToday) return false;
    if (willLoseStreakAt == null) return false;
    final diff = willLoseStreakAt!.difference(DateTime.now());
    return diff.inHours < 6;
  }
}

/// Unlock requirement info from BE
class UnlockRequirement {
  final String currentBatch;
  final int masteredCount;
  final int requiredCount;
  final String message;

  UnlockRequirement({
    required this.currentBatch,
    required this.masteredCount,
    required this.requiredCount,
    required this.message,
  });

  factory UnlockRequirement.fromJson(Map<String, dynamic> json) {
    return UnlockRequirement(
      currentBatch: json['currentBatch'] as String? ?? '',
      masteredCount: json['masteredCount'] as int? ?? 0,
      requiredCount: json['requiredCount'] as int? ?? 0,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'currentBatch': currentBatch,
    'masteredCount': masteredCount,
    'requiredCount': requiredCount,
    'message': message,
  };

  int get wordsToMaster =>
      (requiredCount - masteredCount).clamp(0, requiredCount);
}

/// Review overload info from BE
class ReviewOverloadInfo {
  final int currentReviewCount;
  final int maxAllowed;
  final String message;

  ReviewOverloadInfo({
    required this.currentReviewCount,
    required this.maxAllowed,
    required this.message,
  });

  factory ReviewOverloadInfo.fromJson(Map<String, dynamic> json) {
    return ReviewOverloadInfo(
      currentReviewCount: json['currentReviewCount'] as int? ?? 0,
      maxAllowed: json['maxAllowed'] as int? ?? 50,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'currentReviewCount': currentReviewCount,
    'maxAllowed': maxAllowed,
    'message': message,
  };

  int get excessCount =>
      (currentReviewCount - maxAllowed).clamp(0, currentReviewCount);
}

/// Level advancement notification from BE
/// Returned when user is ready to advance to next HSK level
class LevelAdvancementInfo {
  final bool canAdvance;
  final String currentLevel;
  final String nextLevel;
  final double currentMastery;
  final int requiredMastery;
  final String message;

  LevelAdvancementInfo({
    this.canAdvance = false,
    required this.currentLevel,
    required this.nextLevel,
    this.currentMastery = 0,
    this.requiredMastery = 80,
    this.message = '',
  });

  factory LevelAdvancementInfo.fromJson(Map<String, dynamic> json) {
    return LevelAdvancementInfo(
      canAdvance: json['canAdvance'] as bool? ?? false,
      currentLevel: json['currentLevel'] as String? ?? 'HSK1',
      nextLevel: json['nextLevel'] as String? ?? 'HSK2',
      currentMastery: (json['currentMastery'] as num?)?.toDouble() ?? 0,
      requiredMastery: json['requiredMastery'] as int? ?? 80,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'canAdvance': canAdvance,
    'currentLevel': currentLevel,
    'nextLevel': nextLevel,
    'currentMastery': currentMastery,
    'requiredMastery': requiredMastery,
    'message': message,
  };

  /// Get current level number (1-6)
  int get currentLevelInt =>
      int.tryParse(currentLevel.replaceAll('HSK', '')) ?? 1;

  /// Get next level number (1-6)
  int get nextLevelInt => int.tryParse(nextLevel.replaceAll('HSK', '')) ?? 2;
}

/// Today's learning data - matches BE API response
class TodayModel {
  final int streak;
  final int bestStreak; // 🆕 Kỷ lục streak cao nhất từng đạt
  final String streakRank; // 'top5', 'top10', 'top25', 'top50', ''
  final StreakStatus? streakStatus; // 🆕 Chi tiết trạng thái streak
  final int totalUsers;
  final int newLearned;
  final int reviewed;
  final int masteredCount;
  final int totalLearned;
  final int dailyGoalMinutes;
  final int completedMinutes;
  final int todayAccuracy;
  final int newCount;
  final int reviewCount;
  final List<VocabModel> newQueue;
  final List<VocabModel> reviewQueue;
  final List<DayProgress> weeklyProgress;

  // New fields from BE update
  final int dailyNewLimit; // Giới hạn từ mới/ngày (từ profile)
  final int newLearnedToday; // Số từ mới ĐÃ HỌC hôm nay
  final int remainingNewLimit; // Số từ mới CÒN LẠI có thể học hôm nay

  // 🆕 Level Progress System fields
  final bool isNewQueueLocked; // Có bị lock học từ mới không
  final String? lockReason; // 'review_overload' | 'mastery_required' | null
  final UnlockRequirement? unlockRequirement; // Thông tin yêu cầu để unlock
  final ReviewOverloadInfo? reviewOverloadInfo; // Thông tin quá tải review

  // 🆕 Game limit fields
  final GameLimitInfo? gameLimit; // Game 30s daily limit info

  // 🆕 Level advancement notification
  final LevelAdvancementInfo? levelAdvancement; // null if not ready to advance

  TodayModel({
    this.streak = 0,
    this.bestStreak = 0,
    this.streakRank = '',
    this.streakStatus,
    this.totalUsers = 0,
    this.newLearned = 0,
    this.reviewed = 0,
    this.masteredCount = 0,
    this.totalLearned = 0,
    this.dailyGoalMinutes = 15,
    this.completedMinutes = 0,
    this.todayAccuracy = 0,
    this.newCount = 0,
    this.reviewCount = 0,
    this.newQueue = const [],
    this.reviewQueue = const [],
    this.weeklyProgress = const [],
    this.dailyNewLimit = 30,
    this.newLearnedToday = 0,
    this.remainingNewLimit = 30,
    this.isNewQueueLocked = false,
    this.lockReason,
    this.unlockRequirement,
    this.reviewOverloadInfo,
    this.gameLimit,
    this.levelAdvancement,
  });

  factory TodayModel.fromJson(Map<String, dynamic> json) {
    // Handle wrapped response: { success: true, data: {...} }
    final data = json['data'] ?? json;

    // Parse nested stats object if available (New BE Spec)
    final stats = data['stats'] as Map<String, dynamic>? ?? {};

    // Helper to safely parse int from JSON (handles null, int, double)
    int safeInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Parse streakStatus if available
    StreakStatus? streakStatus;
    final streakStatusJson = data['streakStatus'] as Map<String, dynamic>?;
    if (streakStatusJson != null) {
      streakStatus = StreakStatus.fromJson(streakStatusJson);
    }

    // Parse unlockRequirement if available
    UnlockRequirement? unlockRequirement;
    final unlockJson = data['unlockRequirement'] as Map<String, dynamic>?;
    if (unlockJson != null) {
      unlockRequirement = UnlockRequirement.fromJson(unlockJson);
    }

    // Parse reviewOverloadInfo if available
    ReviewOverloadInfo? reviewOverloadInfo;
    final overloadJson = data['reviewOverloadInfo'] as Map<String, dynamic>?;
    if (overloadJson != null) {
      reviewOverloadInfo = ReviewOverloadInfo.fromJson(overloadJson);
    }

    // Parse game limit info
    GameLimitInfo? gameLimit;
    if (data['gamePlaysToday'] != null || data['gameLimit'] != null) {
      gameLimit = GameLimitInfo.fromJson(data);
    }

    // Parse level advancement info
    LevelAdvancementInfo? levelAdvancement;
    final levelAdvJson = data['levelAdvancement'] as Map<String, dynamic>?;
    if (levelAdvJson != null) {
      levelAdvancement = LevelAdvancementInfo.fromJson(levelAdvJson);
    }

    return TodayModel(
      streak: safeInt(stats['streak'] ?? data['streak']),
      bestStreak: safeInt(stats['bestStreak'] ?? data['bestStreak']),
      streakRank: data['streakRank'] as String? ?? '',
      streakStatus: streakStatus,
      totalUsers: safeInt(data['totalUsers']),
      newLearned: safeInt(stats['newLearned'] ?? data['newLearned']),
      reviewed: safeInt(stats['reviewed'] ?? data['reviewed']),
      masteredCount: safeInt(stats['masteredCount'] ?? data['masteredCount']),
      totalLearned: safeInt(stats['totalLearned'] ?? data['totalLearned']),
      dailyGoalMinutes: safeInt(
        stats['dailyGoalMinutes'] ?? data['dailyGoalMinutes'],
        15,
      ),
      completedMinutes: safeInt(
        stats['completedMinutes'] ?? data['completedMinutes'],
      ),
      todayAccuracy: safeInt(stats['todayAccuracy'] ?? data['todayAccuracy']),
      newCount: safeInt(stats['newCount'] ?? data['newCount']),
      reviewCount: safeInt(stats['reviewCount'] ?? data['reviewCount']),
      newQueue:
          (data['newQueue'] as List<dynamic>?)
              ?.map((e) => VocabModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reviewQueue:
          (data['reviewQueue'] as List<dynamic>?)
              ?.map((e) => VocabModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      weeklyProgress:
          (data['weeklyProgress'] as List<dynamic>?)
              ?.map((e) => DayProgress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dailyNewLimit: safeInt(data['dailyNewLimit'], 30),
      newLearnedToday: safeInt(data['newLearnedToday']) > 0
          ? safeInt(data['newLearnedToday'])
          : safeInt(data['newLearned']),
      remainingNewLimit: safeInt(data['remainingNewLimit'], 30),
      isNewQueueLocked: data['isNewQueueLocked'] as bool? ?? false,
      lockReason: data['lockReason'] as String?,
      unlockRequirement: unlockRequirement,
      reviewOverloadInfo: reviewOverloadInfo,
      gameLimit: gameLimit,
      levelAdvancement: levelAdvancement,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'streak': streak,
      'bestStreak': bestStreak,
      'streakRank': streakRank,
      'streakStatus': streakStatus?.toJson(),
      'totalUsers': totalUsers,
      'newLearned': newLearned,
      'reviewed': reviewed,
      'masteredCount': masteredCount,
      'totalLearned': totalLearned,
      'dailyGoalMinutes': dailyGoalMinutes,
      'completedMinutes': completedMinutes,
      'todayAccuracy': todayAccuracy,
      'newCount': newCount,
      'reviewCount': reviewCount,
      'newQueue': newQueue.map((e) => e.toJson()).toList(),
      'reviewQueue': reviewQueue.map((e) => e.toJson()).toList(),
      'weeklyProgress': weeklyProgress.map((e) => e.toJson()).toList(),
      'dailyNewLimit': dailyNewLimit,
      'newLearnedToday': newLearnedToday,
      'remainingNewLimit': remainingNewLimit,
      'isNewQueueLocked': isNewQueueLocked,
      'lockReason': lockReason,
      'unlockRequirement': unlockRequirement?.toJson(),
      'reviewOverloadInfo': reviewOverloadInfo?.toJson(),
      if (gameLimit != null) 'gamePlaysToday': gameLimit!.gamePlaysToday,
      if (gameLimit != null) 'dailyGameLimit': gameLimit!.dailyGameLimit,
      if (gameLimit != null) 'canPlayGame': gameLimit!.canPlayGame,
      if (levelAdvancement != null)
        'levelAdvancement': levelAdvancement!.toJson(),
    };
  }

  /// Create a copy with modified values
  TodayModel copyWith({
    int? streak,
    int? bestStreak,
    String? streakRank,
    StreakStatus? streakStatus,
    int? totalUsers,
    int? newLearned,
    int? reviewed,
    int? masteredCount,
    int? totalLearned,
    int? dailyGoalMinutes,
    int? completedMinutes,
    int? todayAccuracy,
    int? newCount,
    int? reviewCount,
    List<VocabModel>? newQueue,
    List<VocabModel>? reviewQueue,
    List<DayProgress>? weeklyProgress,
    int? dailyNewLimit,
    int? newLearnedToday,
    int? remainingNewLimit,
    bool? isNewQueueLocked,
    String? lockReason,
    UnlockRequirement? unlockRequirement,
    ReviewOverloadInfo? reviewOverloadInfo,
    GameLimitInfo? gameLimit,
    LevelAdvancementInfo? levelAdvancement,
  }) {
    return TodayModel(
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      streakRank: streakRank ?? this.streakRank,
      streakStatus: streakStatus ?? this.streakStatus,
      totalUsers: totalUsers ?? this.totalUsers,
      newLearned: newLearned ?? this.newLearned,
      reviewed: reviewed ?? this.reviewed,
      masteredCount: masteredCount ?? this.masteredCount,
      totalLearned: totalLearned ?? this.totalLearned,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      completedMinutes: completedMinutes ?? this.completedMinutes,
      todayAccuracy: todayAccuracy ?? this.todayAccuracy,
      newCount: newCount ?? this.newCount,
      reviewCount: reviewCount ?? this.reviewCount,
      newQueue: newQueue ?? this.newQueue,
      reviewQueue: reviewQueue ?? this.reviewQueue,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
      dailyNewLimit: dailyNewLimit ?? this.dailyNewLimit,
      newLearnedToday: newLearnedToday ?? this.newLearnedToday,
      remainingNewLimit: remainingNewLimit ?? this.remainingNewLimit,
      isNewQueueLocked: isNewQueueLocked ?? this.isNewQueueLocked,
      lockReason: lockReason ?? this.lockReason,
      unlockRequirement: unlockRequirement ?? this.unlockRequirement,
      reviewOverloadInfo: reviewOverloadInfo ?? this.reviewOverloadInfo,
      gameLimit: gameLimit ?? this.gameLimit,
      levelAdvancement: levelAdvancement ?? this.levelAdvancement,
    );
  }

  /// Check if user can play Game 30s
  bool get canPlayGame => gameLimit?.canPlayGame ?? true;

  /// Get remaining game plays
  int get remainingGamePlays => gameLimit?.remainingPlays ?? 3;

  /// Check if learning new words is blocked due to review overload
  bool get isBlockedByReviewOverload => lockReason == 'review_overload';

  /// Check if learning new words is blocked due to mastery requirement
  bool get isBlockedByMastery => lockReason == 'mastery_required';

  /// Get lock message based on lock reason
  String get lockMessage {
    if (reviewOverloadInfo != null && isBlockedByReviewOverload) {
      return reviewOverloadInfo!.message;
    }
    if (unlockRequirement != null && isBlockedByMastery) {
      return unlockRequirement!.message;
    }
    return '';
  }

  double get progressPercent {
    if (dailyGoalMinutes == 0) return 0;
    return (completedMinutes / dailyGoalMinutes).clamp(0.0, 1.0);
  }

  int get dueCount => reviewQueue.length;
  int get newWordsToday => newLearned;
  int get reviewedToday => reviewed;

  /// Get streak rank display text
  String get streakRankDisplay {
    switch (streakRank) {
      case 'top5':
        return 'Top 5%';
      case 'top10':
        return 'Top 10%';
      case 'top25':
        return 'Top 25%';
      case 'top50':
        return 'Top 50%';
      default:
        return '';
    }
  }
}

/// Daily progress for weekly chart
class DayProgress {
  final String date; // YYYY-MM-DD
  final int minutes;
  final int newCount;
  final int reviewCount;
  final int accuracy;

  DayProgress({
    required this.date,
    this.minutes = 0,
    this.newCount = 0,
    this.reviewCount = 0,
    this.accuracy = 0,
  });

  factory DayProgress.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse int from JSON (handles null, int, double)
    int safeInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return DayProgress(
      date: json['date'] as String? ?? '',
      minutes: safeInt(json['minutes']),
      newCount: safeInt(json['newCount']),
      reviewCount: safeInt(json['reviewCount']),
      accuracy: safeInt(json['accuracy']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'minutes': minutes,
      'newCount': newCount,
      'reviewCount': reviewCount,
      'accuracy': accuracy,
    };
  }

  /// Get day of week (Mon, Tue, etc.)
  String get dayLabel {
    try {
      final dt = DateTime.parse(date);
      const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      return days[dt.weekday - 1];
    } catch (_) {
      return '';
    }
  }

  /// Check if this is today
  bool get isToday {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return date == todayStr;
  }
}

/// Session result for finishing session
class SessionResultModel {
  final int seconds; // Track in seconds for accuracy
  final int newCount;
  final int reviewCount;
  final double accuracy;
  final String dateKey; // Format: YYYY-MM-DD

  SessionResultModel({
    required this.seconds,
    required this.newCount,
    required this.reviewCount,
    required this.accuracy,
    String? dateKey,
  }) : dateKey = dateKey ?? _formatDateKey(DateTime.now());

  static String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Convert seconds to minutes for BE
  /// Standard rounding: 30+ seconds of a minute rounds up
  /// Example: 89s = 1min, 90s = 2min, 29s = 0min
  int get minutes {
    if (seconds <= 0) return 0;
    // Standard rounding: add 30 then divide by 60 and floor
    return ((seconds + 30) / 60).floor();
  }

  /// Get formatted display string for UI
  String get minutesDisplay {
    if (seconds <= 0) return '0';
    if (seconds < 60) return '< 1'; // Less than 1 minute
    return (seconds / 60).ceil().toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'minutes': minutes, // Send calculated minutes to BE
      'seconds': seconds, // Also send seconds for more accurate tracking
      'newCount': newCount,
      'reviewCount': reviewCount,
      'accuracy': (accuracy * 100).round(), // BE expects 0-100
    };
  }
}

/// Review answer rating
enum ReviewRating { again, hard, good, easy }

extension ReviewRatingExtension on ReviewRating {
  String get value {
    switch (this) {
      case ReviewRating.again:
        return 'again';
      case ReviewRating.hard:
        return 'hard';
      case ReviewRating.good:
        return 'good';
      case ReviewRating.easy:
        return 'easy'; // Spec requires lowercase
    }
  }
}

/// Review answer response
class ReviewAnswerResponse {
  final String vocabId;
  final String state;
  final int intervalDays;
  final double ease;
  final DateTime? dueDate;
  final int reps;

  ReviewAnswerResponse({
    required this.vocabId,
    required this.state,
    required this.intervalDays,
    required this.ease,
    this.dueDate,
    required this.reps,
  });

  factory ReviewAnswerResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final progress = data['progress'] ?? data;

    return ReviewAnswerResponse(
      vocabId: progress['vocabId'] as String? ?? '',
      state:
          data['newState'] as String? ?? progress['state'] as String? ?? 'new',
      intervalDays: progress['intervalDays'] as int? ?? 0,
      ease: (progress['ease'] as num?)?.toDouble() ?? 2.5,
      dueDate: progress['dueDate'] != null
          ? DateTime.tryParse(progress['dueDate'])
          : null,
      reps: progress['reps'] as int? ?? 0,
    );
  }
}

/// Session finish response
class SessionFinishResponse {
  final int minutes;
  final int newCount;
  final int reviewCount;
  final int accuracy;
  final int streak;
  final int bestStreak;

  SessionFinishResponse({
    required this.minutes,
    required this.newCount,
    required this.reviewCount,
    required this.accuracy,
    required this.streak,
    required this.bestStreak,
  });

  factory SessionFinishResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final session = data['session'] ?? data;

    return SessionFinishResponse(
      minutes: session['minutes'] as int? ?? 0,
      newCount: session['newCount'] as int? ?? 0,
      reviewCount: session['reviewCount'] as int? ?? 0,
      accuracy: session['accuracy'] as int? ?? 0,
      streak: data['streak'] as int? ?? session['streak'] as int? ?? 0,
      bestStreak:
          data['bestStreak'] as int? ?? session['bestStreak'] as int? ?? 0,
    );
  }
}
