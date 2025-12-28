/// HSK Level Progress model
class LevelProgressModel {
  final String currentLevel;
  final String targetLevel;
  final Map<String, HskLevelInfo> levels;
  final LevelAdvancement? advancement;
  final LevelStats stats;

  LevelProgressModel({
    required this.currentLevel,
    required this.targetLevel,
    this.levels = const {},
    this.advancement,
    LevelStats? stats,
  }) : stats = stats ?? LevelStats();

  factory LevelProgressModel.fromJson(Map<String, dynamic> json) {
    final levelsJson = json['levels'] as Map<String, dynamic>? ?? {};
    final levels = <String, HskLevelInfo>{};
    levelsJson.forEach((key, value) {
      levels[key] = HskLevelInfo.fromJson(value as Map<String, dynamic>);
    });

    return LevelProgressModel(
      currentLevel: json['currentLevel'] as String? ?? 'HSK1',
      targetLevel: json['targetLevel'] as String? ?? 'HSK3',
      levels: levels,
      advancement: json['advancement'] != null
          ? LevelAdvancement.fromJson(json['advancement'] as Map<String, dynamic>)
          : null,
      stats: json['stats'] != null
          ? LevelStats.fromJson(json['stats'] as Map<String, dynamic>)
          : LevelStats(),
    );
  }

  Map<String, dynamic> toJson() => {
        'currentLevel': currentLevel,
        'targetLevel': targetLevel,
        'levels': levels.map((key, value) => MapEntry(key, value.toJson())),
        'advancement': advancement?.toJson(),
        'stats': stats.toJson(),
      };

  /// Get info for a specific level
  HskLevelInfo? getLevelInfo(String level) => levels[level];

  /// Get current level number (1-6)
  int get currentLevelInt => int.tryParse(currentLevel.replaceAll('HSK', '')) ?? 1;
}

/// Info for a specific HSK level
class HskLevelInfo {
  final int totalWords;
  final int learned;
  final int mastered;
  final int inProgress;
  final double percentage;
  final double masteryPercentage;
  final bool isCompleted;
  final bool canAdvance;
  final bool isLocked;
  final int requiredMasteryPercent;

  HskLevelInfo({
    this.totalWords = 0,
    this.learned = 0,
    this.mastered = 0,
    this.inProgress = 0,
    this.percentage = 0,
    this.masteryPercentage = 0,
    this.isCompleted = false,
    this.canAdvance = false,
    this.isLocked = false,
    this.requiredMasteryPercent = 80,
  });

  factory HskLevelInfo.fromJson(Map<String, dynamic> json) {
    return HskLevelInfo(
      totalWords: json['totalWords'] as int? ?? 0,
      learned: json['learned'] as int? ?? 0,
      mastered: json['mastered'] as int? ?? 0,
      inProgress: json['inProgress'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      masteryPercentage: (json['masteryPercentage'] as num?)?.toDouble() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      canAdvance: json['canAdvance'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
      requiredMasteryPercent: json['requiredMasteryPercent'] as int? ?? 80,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalWords': totalWords,
        'learned': learned,
        'mastered': mastered,
        'inProgress': inProgress,
        'percentage': percentage,
        'masteryPercentage': masteryPercentage,
        'isCompleted': isCompleted,
        'canAdvance': canAdvance,
        'isLocked': isLocked,
        'requiredMasteryPercent': requiredMasteryPercent,
      };

  /// Words remaining to complete this level
  int get remainingWords => totalWords - learned;

  /// Words needed to master for advancement
  int get wordsToMaster => ((totalWords * requiredMasteryPercent / 100) - mastered).ceil().clamp(0, totalWords);
}

/// Level advancement info
class LevelAdvancement {
  final bool canAdvanceNow;
  final String? nextLevel;
  final double currentMastery;
  final int requiredMastery;
  final String message;

  LevelAdvancement({
    this.canAdvanceNow = false,
    this.nextLevel,
    this.currentMastery = 0,
    this.requiredMastery = 80,
    this.message = '',
  });

  factory LevelAdvancement.fromJson(Map<String, dynamic> json) {
    return LevelAdvancement(
      canAdvanceNow: json['canAdvanceNow'] as bool? ?? json['canAdvance'] as bool? ?? false,
      nextLevel: json['nextLevel'] as String?,
      currentMastery: (json['currentMastery'] as num?)?.toDouble() ?? 0,
      requiredMastery: json['requiredMastery'] as int? ?? 80,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'canAdvanceNow': canAdvanceNow,
        'nextLevel': nextLevel,
        'currentMastery': currentMastery,
        'requiredMastery': requiredMastery,
        'message': message,
      };
}

/// Overall level stats
class LevelStats {
  final int totalWordsLearned;
  final int totalWordsMastered;
  final double overallProgress;

  LevelStats({
    this.totalWordsLearned = 0,
    this.totalWordsMastered = 0,
    this.overallProgress = 0,
  });

  factory LevelStats.fromJson(Map<String, dynamic> json) {
    return LevelStats(
      totalWordsLearned: json['totalWordsLearned'] as int? ?? 0,
      totalWordsMastered: json['totalWordsMastered'] as int? ?? 0,
      overallProgress: (json['overallProgress'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalWordsLearned': totalWordsLearned,
        'totalWordsMastered': totalWordsMastered,
        'overallProgress': overallProgress,
      };
}
