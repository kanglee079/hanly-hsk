import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../data/models/today_model.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/repositories/progress_repo.dart';
import '../../services/auth_session_service.dart';
import '../../services/next_action_engine.dart';
import '../../services/storage_service.dart';
import '../../services/local_today_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/hm_streak_bottom_sheet.dart';
import '../../core/widgets/hm_button.dart';
import '../../core/widgets/hm_toast.dart';
import '../../core/utils/logger.dart';
import '../../routes/app_routes.dart';
import '../../services/realtime/today_store.dart';
import '../practice/practice_controller.dart';
import '../shell/shell_controller.dart';

/// Session mode preset (legacy - for backwards compatibility)
enum SessionMode {
  newWords, // Learn new words
  review, // Review due words (SRS)
  reviewToday, // Review words learned today (reinforcement)
  game30, // Quick game
}

/// Today controller
class TodayController extends GetxController {
  final AuthSessionService _authService = Get.find<AuthSessionService>();
  final TodayStore _todayStore = Get.find<TodayStore>();
  final StorageService _storage = Get.find<StorageService>();
  late final LocalTodayService _localTodayService;

  // Date key for local cache (yyyy-MM-dd)
  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // Store-backed (single source of truth)
  late final Rxn<TodayModel> todayData = _todayStore.today.data;
  late final Rxn<ForecastModel> forecastData =
      _todayStore.forecast?.data ?? Rxn<ForecastModel>();
  late final Rxn<LearnedTodayModel> learnedTodayData =
      _todayStore.learnedToday?.data ?? Rxn<LearnedTodayModel>();

  // Loading states (store-backed)
  late final RxBool isLoading = _todayStore.today.isBootstrapping;
  late final RxBool isLoadingForecast =
      _todayStore.forecast?.isBootstrapping ?? false.obs;
  late final RxBool isLoadingLearnedToday =
      _todayStore.learnedToday?.isBootstrapping ?? false.obs;

  final Rx<RecommendedAction?> nextAction = Rx<RecommendedAction?>(null);
  final RxString displayName = ''.obs;

  // Reactive trigger for local cache updates (when returning from Practice)
  final RxInt localLearnedCount = 0.obs;

  // OFFLINE-FIRST: Local review queue count (updated immediately after review)
  final RxInt localDueCount = 0.obs;

  // Track if local data has been initialized (to distinguish 0 from "not loaded")
  final RxBool hasLocalData = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Initialize LocalTodayService for offline-first review queue
    try {
      _localTodayService = Get.find<LocalTodayService>();
    } catch (_) {
      // Fallback: register if not found
      _localTodayService = Get.put(LocalTodayService());
    }

    _updateDisplayName();
    _refreshLocalCacheCount();
    // OPTIMIZED: Only sync if no data yet (RealtimeSyncService handles regular sync)
    // This prevents duplicate API calls on every tab switch
    if (todayData.value == null) {
      _todayStore.syncNow(force: true);
    }
    // Listen to user changes - reset local cache when user changes
    ever(_authService.currentUser, (_) {
      _updateDisplayName();
      _refreshLocalCacheCount(); // Re-read from storage (which is cleared on logout)
      _computeNextAction();
    });
    // Recompute next action whenever Today payload updates
    ever(todayData, (_) => _computeNextAction());
    // Also recompute when learnedTodayData updates (may have different count)
    ever(learnedTodayData, (_) => _computeNextAction());

    // Listen to onLearnedUpdate event from Practice for refresh
    // Note: PracticeController ensures data is synced before triggering this
    ever(_todayStore.onLearnedUpdate, (_) {
      _refreshLocalCacheCount();
      _computeNextAction();
    });

    // OFFLINE-FIRST: Listen to LocalTodayService for immediate review queue updates
    ever(_localTodayService.today, (localToday) {
      if (localToday != null) {
        localDueCount.value = localToday.reviewQueue.length;
        hasLocalData.value = true; // Mark as initialized
        _computeNextAction();
      }
    });
    // Initialize localDueCount from current local data
    _refreshLocalDueCount();

    _computeNextAction();
  }

  /// Refresh local cache count (called when returning from Practice)
  void _refreshLocalCacheCount() {
    final localIds = _storage.getLearnNewCompletedVocabIds(_todayKey);
    localLearnedCount.value = localIds.length;
  }

  /// Refresh local due count from LocalTodayService
  void _refreshLocalDueCount() {
    final localToday = _localTodayService.today.value;
    if (localToday != null) {
      localDueCount.value = localToday.reviewQueue.length;
      hasLocalData.value = true; // Mark as initialized
    }
  }

  /// Called when screen becomes visible again (from Practice)
  void onScreenVisible() {
    _refreshLocalCacheCount();
    _refreshLocalDueCount();
    _computeNextAction();
  }

  void _updateDisplayName() {
    final user = _authService.currentUser.value;
    displayName.value = user?.displayName ?? user?.profile?.displayName ?? '';
  }

  Future<void> loadTodayData() async {
    _refreshLocalCacheCount(); // Refresh local cache first
    await _todayStore.syncNow(force: true);
  }

  /// Compute next recommended action based on today data + local cache
  ///
  /// Sử dụng TẤT CẢ nguồn data: todayData, learnedTodayData, localCache
  void _computeNextAction() {
    final today = todayData.value;
    if (today == null) {
      nextAction.value = null;
      return;
    }

    // Lấy learned count từ TẤT CẢ nguồn, dùng giá trị lớn nhất
    final localCount = localLearnedCount.value;
    final todayApiCount = today.newLearnedToday;
    final learnedTodayApiCount = learnedTodayData.value?.count ?? 0;

    // Chọn max từ tất cả nguồn
    int actualLearnedCount = localCount;
    if (todayApiCount > actualLearnedCount) actualLearnedCount = todayApiCount;
    if (learnedTodayApiCount > actualLearnedCount) {
      actualLearnedCount = learnedTodayApiCount;
    }

    // Use LOCAL STORAGE dailyNewLimit (user's choice) instead of API value
    // This ensures consistency with the displayed stats
    final effectiveDailyLimit =
        dailyNewLimit; // getter uses local storage priority

    // Adjust model với learned count thực tế VÀ dailyNewLimit từ local
    final adjusted = today.copyWith(
      newLearnedToday: actualLearnedCount,
      dailyNewLimit:
          effectiveDailyLimit, // Override API value with local preference
      remainingNewLimit: (effectiveDailyLimit - actualLearnedCount).clamp(
        0,
        effectiveDailyLimit,
      ),
    );
    nextAction.value = NextActionEngine.computeNextAction(adjusted);
  }

  /// Execute the recommended next action
  void executeNextAction() {
    final action = nextAction.value;
    if (action == null) return;

    // Skip if no route (e.g., "Nghỉ ngơi" action)
    if (action.route.isEmpty) return;

    // Handle shell navigation with tab switching
    if (action.route == Routes.shell && action.payload != null) {
      final tabIndex = action.payload!['tab'] as int?;
      if (tabIndex != null) {
        // Switch tab in shell
        final shellController = Get.find<ShellController>();
        shellController.changePage(tabIndex);
        return;
      }
    }

    Get.toNamed(action.route, arguments: action.payload);
  }

  // ===== REVIEW QUEUE (OFFLINE-FIRST) =====

  /// Get due count - PREFERS LOCAL DATA for immediate reactivity
  /// After review, local SQLite is updated first, so this reflects changes immediately
  int get dueCount {
    // Local data is primary (updated immediately after review)
    final localCount = localDueCount.value;
    if (localCount > 0) return localCount;

    // Fallback to server data
    return todayData.value?.dueCount ?? 0;
  }

  // ===== FORECAST HELPERS =====

  /// Get tomorrow's review count from forecast
  int get tomorrowReviewCount => forecastData.value?.tomorrowReviewCount ?? 0;

  /// Get forecast days
  List<ForecastDay> get forecastDays => forecastData.value?.days ?? [];

  // ===== GOAL HELPER =====

  /// Get daily new word limit - LOCAL STORAGE is PRIMARY for user-set preferences
  /// User chọn số từ/ngày, 1 từ = 1 phút
  int get dailyNewLimit {
    // 1. LOCAL STORAGE FIRST - User's explicit choice during setup
    // This ensures user's choice is respected even if backend sync fails
    final storedLimit = _storage.userDailyNewLimit;
    if (storedLimit > 0) return storedLimit;

    // 2. Fallback to API data (for users who set on another device)
    final apiLimit = _authService.currentUser.value?.profile?.dailyNewLimit;
    if (apiLimit != null && apiLimit > 0) return apiLimit;

    return 10; // Default
  }

  /// Get daily goal in minutes (1 word = 1 minute)
  int get dailyGoalMinutes => dailyNewLimit;

  // ===== LEARNED TODAY HELPERS =====

  /// Get words learned today
  List<LearnedTodayItem> get learnedTodayItems =>
      learnedTodayData.value?.items ?? [];

  /// Get learned today count - combine BE data and local cache
  /// Capped at daily limit (không hiển thị hơn limit)
  int get learnedTodayCount {
    final limit = dailyNewLimit; // Use profile source

    // Lấy max giữa BE và local cache
    final beCount = learnedTodayData.value?.count ?? 0;
    final todayCount = todayData.value?.newLearnedToday ?? 0;
    final localCount = localLearnedCount.value;

    // Lấy giá trị lớn nhất
    int rawCount = beCount;
    if (todayCount > rawCount) rawCount = todayCount;
    if (localCount > rawCount) rawCount = localCount;

    // Cap tại daily limit (không cho hiển thị quá limit)
    return rawCount > limit ? limit : rawCount;
  }

  /// Check if user has reached daily limit
  bool get hasReachedDailyLimit {
    return learnedTodayCount >= dailyNewLimit;
  }

  /// Get remaining words that can be learned today
  int get remainingNewWords {
    final limit = dailyNewLimit;
    return (limit - learnedTodayCount).clamp(0, limit);
  }

  /// Get list of vocab IDs learned today from local cache
  List<String> get learnedTodayVocabIds =>
      _storage.getLearnNewCompletedVocabIds(_todayKey);

  // ===== STREAK HELPERS =====

  /// Get current streak value
  int get streak => todayData.value?.streak ?? 0;

  /// Get best streak (kỷ lục)
  int get bestStreak => todayData.value?.bestStreak ?? streak;

  /// Get streak rank display (Top 5%, Top 10%, etc.)
  String get streakRank => todayData.value?.streakRank ?? '';

  /// Get streak status from BE
  StreakStatus? get streakStatus => todayData.value?.streakStatus;

  /// Check if user has studied today
  /// Ưu tiên dùng streakStatus từ BE, fallback về completedMinutes
  bool get hasStudiedToday {
    // Prefer BE's streakStatus if available
    if (streakStatus != null) {
      return streakStatus!.hasStudiedToday;
    }
    // Fallback to checking completedMinutes
    return (todayData.value?.completedMinutes ?? 0) > 0;
  }

  /// Check if streak is at risk (sắp mất streak)
  bool get isStreakAtRisk {
    // Tick from store to keep countdown & risk status updating in real-time
    _todayStore.now.value;
    return streakStatus?.isAtRisk ?? (!hasStudiedToday && streak > 0);
  }

  /// Get time remaining until streak is lost
  String get timeUntilLoseStreak {
    _todayStore.now.value;
    return streakStatus?.timeUntilLoseStreak ?? '';
  }

  /// Get completed minutes today
  int get completedMinutes => todayData.value?.completedMinutes ?? 0;

  // dailyGoalMinutes defined above (backed by User Profile)

  /// Get weekly progress data for streak calendar
  List<StreakDayData> get weeklyStreakData {
    final weeklyProgress = todayData.value?.weeklyProgress ?? [];
    if (weeklyProgress.isEmpty) return [];

    return weeklyProgress.map((day) {
      final dt = DateTime.tryParse(day.date);
      return StreakDayData(
        dayOfWeek: dt?.weekday ?? 1,
        isCompleted: day.minutes > 0,
        isToday: day.isToday,
        minutes: day.minutes,
      );
    }).toList();
  }

  /// Show streak bottom sheet with detailed info
  void showStreakDetails() {
    HMStreakBottomSheet.show(
      streak: streak,
      bestStreak: bestStreak,
      streakRank: streakRank,
      hasStudiedToday: hasStudiedToday,
      completedMinutes: completedMinutes,
      dailyGoalMinutes: dailyGoalMinutes,
      weeklyData: weeklyStreakData,
      onStartLearning: () => startSession(SessionMode.newWords),
    );
  }

  /// Start session - NOW USES NEW PRACTICE FLOW
  void startSession(SessionMode mode) {
    // Map old SessionMode to new PracticeMode
    PracticeMode practiceMode;

    switch (mode) {
      case SessionMode.newWords:
        practiceMode = PracticeMode.learnNew;
        break;
      case SessionMode.review:
        practiceMode = PracticeMode.reviewSRS;
        break;
      case SessionMode.reviewToday:
        practiceMode = PracticeMode.reviewToday; // Củng cố từ vừa học hôm nay
        break;
      case SessionMode.game30:
        // Navigate to Game30 Home with leaderboard instead of direct practice
        Get.toNamed(Routes.game30Home);
        return;
    }

    Get.toNamed(Routes.practice, arguments: {'mode': practiceMode});
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  // ===== HSK LEVEL ADVANCEMENT =====

  /// Level advancement info from API (via TodayModel)
  LevelAdvancementInfo? get levelAdvancement =>
      todayData.value?.levelAdvancement;

  /// Check if user can advance to next HSK level
  bool get canAdvanceLevel => levelAdvancement?.canAdvance ?? false;

  /// Get current HSK level from profile
  int get currentHskLevel {
    final levelStr = _authService.currentUser.value?.profile?.currentLevel;
    if (levelStr == null) return 1;
    return int.tryParse(levelStr.replaceAll('HSK', '')) ?? 1;
  }

  /// Get next HSK level
  int get nextHskLevel =>
      levelAdvancement?.nextLevelInt ?? (currentHskLevel + 1).clamp(1, 6);

  /// Show HSK level advancement dialog
  void showLevelAdvancementDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebration icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Xuất sắc! 🎉',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Bạn đã hoàn thành HSK$currentHskLevel!',
                style: AppTypography.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                'Bạn có muốn chuyển sang học HSK$nextHskLevel?',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: HMButton(
                      text: 'Để sau',
                      variant: HMButtonVariant.outline,
                      onPressed: () => Get.back(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HMButton(
                      text: 'Lên HSK$nextHskLevel',
                      onPressed: () {
                        Get.back();
                        advanceToNextLevel();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Advance to next HSK level
  Future<void> advanceToNextLevel() async {
    try {
      final progressRepo = Get.find<ProgressRepo>();
      await progressRepo.unlockNext();

      // Refresh user and today data
      await Future.wait([
        _authService.fetchCurrentUser(),
        _todayStore.syncNow(force: true),
      ]);

      HMToast.success('Chúc mừng! Bạn đã chuyển sang HSK$nextHskLevel 🎉');
    } catch (e) {
      Logger.e('TodayController', 'Error advancing level', e);
      HMToast.error(
        'Chưa thể chuyển level. Vui lòng hoàn thành level hiện tại.',
      );
    }
  }
}
