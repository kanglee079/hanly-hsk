import 'package:get/get.dart';

import '../core/utils/logger.dart';
import '../data/local/database_service.dart';
import '../data/local/vocab_local_datasource.dart';
import '../data/models/today_model.dart';
import 'local_progress_service.dart';
import 'storage_service.dart';

/// LocalTodayService - Builds TodayModel entirely from local SQLite data
///
/// This eliminates the need for GET /today API calls.
/// All stats (streak, minutes, learned count) come from local database.
/// Server is only for backup sync, not for fetching data.
class LocalTodayService extends GetxService {
  late DatabaseService _db;
  late VocabLocalDataSource _vocabLocal;
  late LocalProgressService _localProgress;
  late StorageService _storage;

  // Reactive today model - UI subscribes to this
  final Rx<TodayModel?> today = Rx<TodayModel?>(null);

  // Reactive local forecast - keys are date strings (YYYY-MM-DD), values are counts
  final RxMap<String, int> localForecast = <String, int>{}.obs;

  // Loading state
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _db = Get.find<DatabaseService>();
    _vocabLocal = Get.find<VocabLocalDataSource>();
    _storage = Get.find<StorageService>();

    try {
      _localProgress = Get.find<LocalProgressService>();

      // Listen to progress updates and rebuild TodayModel
      _localProgress.onProgressUpdate.listen((_) {
        Logger.d(
          'LocalTodayService',
          '📊 Progress updated, rebuilding TodayModel',
        );
        buildTodayModel();
      });
    } catch (_) {
      Logger.w('LocalTodayService', 'LocalProgressService not available');
    }

    // Initial build
    buildTodayModel();
  }

  /// Build TodayModel entirely from local data
  /// NO API CALLS - everything from SQLite
  Future<void> buildTodayModel() async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      final currentLevel = _storage.userLevel ?? 'HSK1';
      final dailyNewLimit = _storage.userDailyNewLimit;
      final dailyGoalMinutes = _storage.userDailyMinutes;

      // Get queues from local DB
      final newQueue = await _vocabLocal.getNewQueue(
        level: currentLevel,
        limit: dailyNewLimit,
      );
      final reviewQueue = await _vocabLocal.getReviewQueue(limit: 50);

      // Get today's stats from local
      final stats = _localProgress.getStats();
      final newLearnedToday = stats['newLearnedToday'] as int? ?? 0;
      final reviewedToday = stats['reviewedToday'] as int? ?? 0;
      final completedMinutes = stats['totalMinutesToday'] as int? ?? 0;

      // Get streak from local
      final streakInfo = await _getLocalStreak();

      // Get weekly progress from local
      final weeklyProgress = await _getLocalWeeklyProgress();

      // Build local counts
      final masteredCount = await _getMasteredCount();
      final totalLearned = await _getTotalLearnedCount();

      // Calculate remaining limit
      final remainingNewLimit = (dailyNewLimit - newLearnedToday).clamp(
        0,
        dailyNewLimit,
      );

      today.value = TodayModel(
        streak: streakInfo['streak'] as int,
        bestStreak: streakInfo['bestStreak'] as int,
        streakStatus: StreakStatus(
          hasStudiedToday: completedMinutes > 0 || newLearnedToday > 0,
          lastStudyDate: streakInfo['lastStudyDate'] as DateTime?,
        ),
        newLearned: newLearnedToday,
        reviewed: reviewedToday,
        masteredCount: masteredCount,
        totalLearned: totalLearned,
        dailyGoalMinutes: dailyGoalMinutes,
        completedMinutes: completedMinutes,
        newCount: newQueue.length,
        reviewCount: reviewQueue.length,
        newQueue: newQueue,
        reviewQueue: reviewQueue,
        dailyNewLimit: dailyNewLimit,
        newLearnedToday: newLearnedToday,
        remainingNewLimit: remainingNewLimit,
        weeklyProgress: weeklyProgress,
      );

      // Build local forecast for next 7 days
      final forecastCounts = await _vocabLocal.getForecastCounts(days: 7);
      localForecast.value = forecastCounts;

      Logger.d(
        'LocalTodayService',
        '✅ Built TodayModel: new=${newQueue.length}, review=${reviewQueue.length}, '
            'streak=${streakInfo['streak']}, minutes=$completedMinutes, '
            'forecast=${forecastCounts.values.fold(0, (a, b) => a + b)} total',
      );
    } catch (e) {
      Logger.e('LocalTodayService', 'Failed to build TodayModel', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Get streak from local daily_stats
  Future<Map<String, dynamic>> _getLocalStreak() async {
    try {
      final today = DateTime.now();
      final todayKey = _formatDateKey(today);
      final yesterdayKey = _formatDateKey(
        today.subtract(const Duration(days: 1)),
      );

      // Check today's session
      final todayResult = await _db.db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['daily_stats_${todayKey}_streak'],
      );

      if (todayResult.isNotEmpty) {
        final streak =
            int.tryParse(todayResult.first['value'] as String? ?? '0') ?? 0;
        final bestStreak = await _getBestStreak();
        return {
          'streak': streak,
          'bestStreak': bestStreak,
          'lastStudyDate': today,
        };
      }

      // Check yesterday's session
      final yesterdayResult = await _db.db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['daily_stats_${yesterdayKey}_streak'],
      );

      if (yesterdayResult.isNotEmpty) {
        final streak =
            int.tryParse(yesterdayResult.first['value'] as String? ?? '0') ?? 0;
        final bestStreak = await _getBestStreak();
        return {
          'streak': streak, // Still valid until end of today
          'bestStreak': bestStreak,
          'lastStudyDate': today.subtract(const Duration(days: 1)),
        };
      }

      return {
        'streak': 0,
        'bestStreak': await _getBestStreak(),
        'lastStudyDate': null,
      };
    } catch (e) {
      return {'streak': 0, 'bestStreak': 0, 'lastStudyDate': null};
    }
  }

  Future<int> _getBestStreak() async {
    try {
      final result = await _db.db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['best_streak'],
      );
      if (result.isNotEmpty) {
        return int.tryParse(result.first['value'] as String? ?? '0') ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  /// Get weekly progress from local
  Future<List<DayProgress>> _getLocalWeeklyProgress() async {
    final result = <DayProgress>[];
    final today = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateKey = _formatDateKey(date);

      try {
        final minutesResult = await _db.db.query(
          'settings',
          where: 'key = ?',
          whereArgs: ['daily_stats_${dateKey}_minutes'],
        );
        final newResult = await _db.db.query(
          'settings',
          where: 'key = ?',
          whereArgs: ['daily_stats_${dateKey}_new'],
        );
        final reviewResult = await _db.db.query(
          'settings',
          where: 'key = ?',
          whereArgs: ['daily_stats_${dateKey}_review'],
        );

        result.add(
          DayProgress(
            date: dateKey,
            minutes: minutesResult.isNotEmpty
                ? int.tryParse(
                        minutesResult.first['value'] as String? ?? '0',
                      ) ??
                      0
                : 0,
            newCount: newResult.isNotEmpty
                ? int.tryParse(newResult.first['value'] as String? ?? '0') ?? 0
                : 0,
            reviewCount: reviewResult.isNotEmpty
                ? int.tryParse(reviewResult.first['value'] as String? ?? '0') ??
                      0
                : 0,
          ),
        );
      } catch (_) {
        result.add(DayProgress(date: dateKey));
      }
    }

    return result;
  }

  Future<int> _getMasteredCount() async {
    try {
      final result = await _db.db.rawQuery('''
        SELECT COUNT(*) as count FROM vocab_progress WHERE state = 'mastered'
      ''');
      return result.first['count'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _getTotalLearnedCount() async {
    try {
      final result = await _db.db.rawQuery('''
        SELECT COUNT(*) as count FROM vocab_progress WHERE state != 'new'
      ''');
      return result.first['count'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Force refresh (called after session ends, etc)
  Future<void> refresh() async {
    await buildTodayModel();
  }
}
