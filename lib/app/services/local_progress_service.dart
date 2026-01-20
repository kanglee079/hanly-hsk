import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';

import '../core/utils/logger.dart';
import '../data/local/database_service.dart';
import '../data/local/vocab_local_datasource.dart';

/// SRS Rating from user
enum SrsRating { again, hard, good, easy }

/// Result of an SRS update
class SrsUpdateResult {
  final String vocabId;
  final String newState;
  final double newEase;
  final int newIntervalDays;
  final int newReps;
  final DateTime dueDate;
  final bool isNewlyMastered;

  SrsUpdateResult({
    required this.vocabId,
    required this.newState,
    required this.newEase,
    required this.newIntervalDays,
    required this.newReps,
    required this.dueDate,
    this.isNewlyMastered = false,
  });
}

/// Local Progress Service - Handles all SRS calculations locally
///
/// This is the core of offline-first learning:
/// - All progress updates happen locally first
/// - SRS algorithm runs on device
/// - Changes are queued for background sync
class LocalProgressService extends GetxService {
  late DatabaseService _db;
  late VocabLocalDataSource _vocabLocal;

  // Event streams for reactive UI
  final _progressController = StreamController<SrsUpdateResult>.broadcast();
  Stream<SrsUpdateResult> get onProgressUpdate => _progressController.stream;

  // Today's stats (reactive)
  final RxInt newLearnedToday = 0.obs;
  final RxInt reviewedToday = 0.obs;
  final RxInt totalMinutesToday = 0.obs;
  final RxDouble accuracyToday = 0.0.obs;

  // Session tracking
  DateTime? _sessionStart;
  int _sessionCorrect = 0;
  int _sessionTotal = 0;

  @override
  void onInit() {
    super.onInit();
    _db = Get.find<DatabaseService>();
    _vocabLocal = Get.find<VocabLocalDataSource>();
    _loadTodayStats();
  }

  /// Load today's stats from local DB
  Future<void> _loadTodayStats() async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final result = await _db.db.query(
        'settings',
        where: 'key LIKE ?',
        whereArgs: ['daily_stats_$today%'],
      );

      for (final row in result) {
        final key = row['key'] as String;
        final value = int.tryParse(row['value'] as String? ?? '0') ?? 0;

        if (key.endsWith('_new')) {
          newLearnedToday.value = value;
        } else if (key.endsWith('_review')) {
          reviewedToday.value = value;
        } else if (key.endsWith('_minutes')) {
          totalMinutesToday.value = value;
        }
      }

      Logger.d(
        'LocalProgressService',
        'Loaded stats: new=${newLearnedToday.value}, review=${reviewedToday.value}',
      );
    } catch (e) {
      Logger.e('LocalProgressService', 'Failed to load today stats', e);
    }
  }

  /// Start a learning session
  void startSession() {
    _sessionStart = DateTime.now();
    _sessionCorrect = 0;
    _sessionTotal = 0;
    Logger.d('LocalProgressService', '📚 Session started');
  }

  /// Record an answer and update progress locally
  /// Returns the SRS update result for UI feedback
  Future<SrsUpdateResult> recordAnswer({
    required String vocabId,
    required SrsRating rating,
    required String mode, // 'learn', 'review', 'flashcard'
    int timeSpentMs = 5000,
  }) async {
    final now = DateTime.now();
    _sessionTotal++;
    if (rating == SrsRating.good || rating == SrsRating.easy) {
      _sessionCorrect++;
    }

    // Get current progress
    final currentProgress = await _getProgress(vocabId);

    // Calculate new SRS values
    final result = _calculateSrs(
      vocabId: vocabId,
      currentState: currentProgress?['state'] as String? ?? 'new',
      currentEase: (currentProgress?['ease_factor'] as num?)?.toDouble() ?? 2.5,
      currentInterval: currentProgress?['interval_days'] as int? ?? 0,
      currentReps: currentProgress?['repetitions'] as int? ?? 0,
      rating: rating,
      now: now,
    );

    // Update local database
    await _vocabLocal.updateProgress(
      vocabId: vocabId,
      state: result.newState,
      easeFactor: result.newEase,
      intervalDays: result.newIntervalDays,
      repetitions: result.newReps,
      dueDate: result.dueDate,
      lastReviewed: now,
    );

    // Update today's stats
    if (mode == 'learn' &&
        (currentProgress == null || currentProgress['state'] == 'new')) {
      newLearnedToday.value++;
      await _saveDailyStat('new', newLearnedToday.value);
    } else {
      reviewedToday.value++;
      await _saveDailyStat('review', reviewedToday.value);
    }

    // Emit event for reactive UI
    _progressController.add(result);

    Logger.d(
      'LocalProgressService',
      '✅ Updated $vocabId: ${result.newState}, interval=${result.newIntervalDays}d',
    );

    return result;
  }

  /// End session and save stats
  Future<Map<String, dynamic>> endSession() async {
    if (_sessionStart == null) {
      return {'minutes': 0, 'accuracy': 0};
    }

    final duration = DateTime.now().difference(_sessionStart!);
    final minutes = (duration.inSeconds / 60).ceil();
    final accuracy = _sessionTotal > 0
        ? (_sessionCorrect / _sessionTotal * 100).round()
        : 0;

    totalMinutesToday.value += minutes;
    await _saveDailyStat('minutes', totalMinutesToday.value);

    accuracyToday.value = _sessionTotal > 0
        ? _sessionCorrect / _sessionTotal
        : 0;

    Logger.d(
      'LocalProgressService',
      '📊 Session ended: ${minutes}min, $accuracy% accuracy',
    );

    _sessionStart = null;

    return {
      'minutes': minutes,
      'newCount': newLearnedToday.value,
      'reviewCount': reviewedToday.value,
      'accuracy': accuracy,
    };
  }

  /// Get current progress for a vocab
  Future<Map<String, dynamic>?> _getProgress(String vocabId) async {
    final results = await _db.db.query(
      'vocab_progress',
      where: 'vocab_id = ?',
      whereArgs: [vocabId],
    );
    return results.isEmpty ? null : results.first;
  }

  /// Core SRS algorithm (SM-2 variant)
  SrsUpdateResult _calculateSrs({
    required String vocabId,
    required String currentState,
    required double currentEase,
    required int currentInterval,
    required int currentReps,
    required SrsRating rating,
    required DateTime now,
  }) {
    double newEase = currentEase;
    int newInterval;
    int newReps = currentReps;
    String newState;
    bool isNewlyMastered = false;

    switch (rating) {
      case SrsRating.again:
        // Reset progress
        newReps = 0;
        newInterval = 1; // Review tomorrow
        newEase = max(1.3, currentEase - 0.2);
        newState = 'learning';
        break;

      case SrsRating.hard:
        newReps++;
        newInterval = max(1, (currentInterval * 1.2).round());
        newEase = max(1.3, currentEase - 0.15);
        newState = currentInterval >= 21 ? 'review' : 'learning';
        break;

      case SrsRating.good:
        newReps++;
        if (currentState == 'new') {
          newInterval = 1; // First time: review tomorrow
        } else if (currentInterval == 0) {
          newInterval = 1;
        } else if (currentInterval == 1) {
          newInterval = 6;
        } else {
          newInterval = (currentInterval * currentEase).round();
        }
        newState = newInterval >= 21 ? 'review' : 'learning';
        break;

      case SrsRating.easy:
        newReps++;
        newInterval = max(4, (currentInterval * currentEase * 1.3).round());
        newEase = currentEase + 0.15;
        newState = 'review';
        break;
    }

    // Check for mastery (interval >= 30 days)
    if (newInterval >= 30 && currentState != 'mastered') {
      newState = 'mastered';
      isNewlyMastered = true;
    }

    // Cap interval at 365 days
    newInterval = min(365, newInterval);

    final dueDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: newInterval));

    return SrsUpdateResult(
      vocabId: vocabId,
      newState: newState,
      newEase: newEase,
      newIntervalDays: newInterval,
      newReps: newReps,
      dueDate: dueDate,
      isNewlyMastered: isNewlyMastered,
    );
  }

  /// Save daily stat to settings table
  Future<void> _saveDailyStat(String stat, int value) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = 'daily_stats_${today}_$stat';

    await _db.db.insert('settings', {
      'key': key,
      'value': value.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get review queue from local DB
  Future<List<Map<String, dynamic>>> getLocalReviewQueue({
    int limit = 50,
  }) async {
    final now = DateTime.now().toIso8601String().substring(0, 10);

    return _db.db.rawQuery(
      '''
      SELECT v.*, p.*
      FROM vocabs v
      INNER JOIN vocab_progress p ON v.id = p.vocab_id
      WHERE p.state IN ('learning', 'review')
        AND p.due_date <= ?
      ORDER BY p.due_date ASC
      LIMIT ?
    ''',
      [now, limit],
    );
  }

  /// Get new words queue from local DB
  Future<List<Map<String, dynamic>>> getLocalNewQueue({
    required String level,
    int limit = 10,
  }) async {
    return _db.db.rawQuery(
      '''
      SELECT v.*
      FROM vocabs v
      LEFT JOIN vocab_progress p ON v.id = p.vocab_id
      WHERE v.level = ?
        AND (p.state IS NULL OR p.state = 'new')
        AND (p.is_locked = 0 OR p.is_locked IS NULL)
      ORDER BY v.order_in_level ASC
      LIMIT ?
    ''',
      [level, limit],
    );
  }

  /// Get local stats
  Map<String, dynamic> getStats() {
    return {
      'newLearnedToday': newLearnedToday.value,
      'reviewedToday': reviewedToday.value,
      'totalMinutesToday': totalMinutesToday.value,
      'accuracyToday': accuracyToday.value,
    };
  }

  @override
  void onClose() {
    _progressController.close();
    super.onClose();
  }
}
