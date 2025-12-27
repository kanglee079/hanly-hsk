/// Level Progress Model - from GET /me/progress/level API
class LevelProgressModel {
  final String currentLevel;
  final String currentBatch;
  final int batchNumber;
  final int totalBatchesInLevel;
  final BatchProgress progress;
  final NextUnlock nextUnlock;
  final OverallProgress overallProgress;

  LevelProgressModel({
    required this.currentLevel,
    required this.currentBatch,
    required this.batchNumber,
    required this.totalBatchesInLevel,
    required this.progress,
    required this.nextUnlock,
    required this.overallProgress,
  });

  factory LevelProgressModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return LevelProgressModel(
      currentLevel: data['currentLevel'] as String? ?? 'HSK1',
      currentBatch: data['currentBatch'] as String? ?? 'HSK1.1',
      batchNumber: data['batchNumber'] as int? ?? 1,
      totalBatchesInLevel: data['totalBatchesInLevel'] as int? ?? 8,
      progress: BatchProgress.fromJson(data['progress'] ?? {}),
      nextUnlock: NextUnlock.fromJson(data['nextUnlock'] ?? {}),
      overallProgress: OverallProgress.fromJson(data['overallProgress'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'currentLevel': currentLevel,
    'currentBatch': currentBatch,
    'batchNumber': batchNumber,
    'totalBatchesInLevel': totalBatchesInLevel,
    'progress': progress.toJson(),
    'nextUnlock': nextUnlock.toJson(),
    'overallProgress': overallProgress.toJson(),
  };

  /// Get mastery percentage (0-100)
  int get masteryPercent => (progress.masteryRate * 100).round();

  /// Check if can unlock next batch
  bool get canUnlockNext => nextUnlock.canUnlock;

  /// Words needed to master before unlocking
  int get wordsToMaster => nextUnlock.wordsToMaster;
}

/// Progress within current batch
class BatchProgress {
  final int total;
  final int learned;
  final int mastered;
  final double masteryRate;

  BatchProgress({
    required this.total,
    required this.learned,
    required this.mastered,
    required this.masteryRate,
  });

  factory BatchProgress.fromJson(Map<String, dynamic> json) {
    return BatchProgress(
      total: json['total'] as int? ?? 0,
      learned: json['learned'] as int? ?? 0,
      mastered: json['mastered'] as int? ?? 0,
      masteryRate: (json['masteryRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'total': total,
    'learned': learned,
    'mastered': mastered,
    'masteryRate': masteryRate,
  };

  /// Remaining words to learn in batch
  int get remaining => total - learned;

  /// Mastery percentage (0-100)
  int get masteryPercent => (masteryRate * 100).round();
}

/// Info about unlocking next batch
class NextUnlock {
  final String batch;
  final double requiredMasteryRate;
  final int requiredCount;
  final int currentMastered;
  final bool canUnlock;
  final int wordsToMaster;

  NextUnlock({
    required this.batch,
    required this.requiredMasteryRate,
    required this.requiredCount,
    required this.currentMastered,
    required this.canUnlock,
    required this.wordsToMaster,
  });

  factory NextUnlock.fromJson(Map<String, dynamic> json) {
    return NextUnlock(
      batch: json['batch'] as String? ?? '',
      requiredMasteryRate: (json['requiredMasteryRate'] as num?)?.toDouble() ?? 0.8,
      requiredCount: json['requiredCount'] as int? ?? 0,
      currentMastered: json['currentMastered'] as int? ?? 0,
      canUnlock: json['canUnlock'] as bool? ?? false,
      wordsToMaster: json['wordsToMaster'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'batch': batch,
    'requiredMasteryRate': requiredMasteryRate,
    'requiredCount': requiredCount,
    'currentMastered': currentMastered,
    'canUnlock': canUnlock,
    'wordsToMaster': wordsToMaster,
  };

  /// Required mastery percentage (0-100)
  int get requiredPercent => (requiredMasteryRate * 100).round();
}

/// Overall progress in current level
class OverallProgress {
  final String level;
  final int totalWords;
  final int learnedWords;
  final int masteredWords;
  final int percentComplete;

  OverallProgress({
    required this.level,
    required this.totalWords,
    required this.learnedWords,
    required this.masteredWords,
    required this.percentComplete,
  });

  factory OverallProgress.fromJson(Map<String, dynamic> json) {
    return OverallProgress(
      level: json['level'] as String? ?? 'HSK1',
      totalWords: json['totalWords'] as int? ?? 0,
      learnedWords: json['learnedWords'] as int? ?? 0,
      masteredWords: json['masteredWords'] as int? ?? 0,
      percentComplete: json['percentComplete'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'level': level,
    'totalWords': totalWords,
    'learnedWords': learnedWords,
    'masteredWords': masteredWords,
    'percentComplete': percentComplete,
  };
}

