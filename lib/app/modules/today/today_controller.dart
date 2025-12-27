import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../data/models/today_model.dart';
import '../../data/models/dashboard_model.dart';
import '../../services/auth_session_service.dart';
import '../../services/next_action_engine.dart';
import '../../services/storage_service.dart';
import '../../core/widgets/hm_streak_bottom_sheet.dart';
import '../../routes/app_routes.dart';
import '../../services/realtime/today_store.dart';
import '../practice/practice_controller.dart';

/// Session mode preset (legacy - for backwards compatibility)
enum SessionMode { 
  newWords,    // Learn new words
  review,      // Review due words (SRS)
  reviewToday, // Review words learned today (reinforcement)
  game30,      // Quick game
}

/// Today controller
class TodayController extends GetxController {
  final AuthSessionService _authService = Get.find<AuthSessionService>();
  final TodayStore _todayStore = Get.find<TodayStore>();
  final StorageService _storage = Get.find<StorageService>();
  
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

  @override
  void onInit() {
    super.onInit();
    _updateDisplayName();
    _refreshLocalCacheCount();
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
    _computeNextAction();
  }
  
  /// Refresh local cache count (called when returning from Practice)
  void _refreshLocalCacheCount() {
    final localIds = _storage.getLearnNewCompletedVocabIds(_todayKey);
    localLearnedCount.value = localIds.length;
  }
  
  /// Called when screen becomes visible again (from Practice)
  void onScreenVisible() {
    _refreshLocalCacheCount();
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
    if (learnedTodayApiCount > actualLearnedCount) actualLearnedCount = learnedTodayApiCount;
    
    // Adjust model với learned count thực tế
    final adjusted = today.copyWith(
      newLearnedToday: actualLearnedCount,
      remainingNewLimit: (today.dailyNewLimit - actualLearnedCount).clamp(0, today.dailyNewLimit),
    );
    nextAction.value = NextActionEngine.computeNextAction(adjusted);
  }
  
  /// Execute the recommended next action
  void executeNextAction() {
    final action = nextAction.value;
    if (action == null) return;
    
    Get.toNamed(action.route, arguments: action.payload);
  }
  
  // ===== FORECAST HELPERS =====
  
  /// Get tomorrow's review count from forecast
  int get tomorrowReviewCount => forecastData.value?.tomorrowReviewCount ?? 0;
  
  /// Get forecast days
  List<ForecastDay> get forecastDays => forecastData.value?.days ?? [];
  
  // ===== LEARNED TODAY HELPERS =====
  
  /// Get words learned today
  List<LearnedTodayItem> get learnedTodayItems => learnedTodayData.value?.items ?? [];
  
  /// Get learned today count - combine BE data and local cache
  /// Capped at daily limit (không hiển thị hơn limit)
  int get learnedTodayCount {
    final limit = todayData.value?.dailyNewLimit ?? 30;
    
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
    final limit = todayData.value?.dailyNewLimit ?? 30;
    return learnedTodayCount >= limit;
  }
  
  /// Get remaining words that can be learned today
  int get remainingNewWords {
    final limit = todayData.value?.dailyNewLimit ?? 30;
    return (limit - learnedTodayCount).clamp(0, limit);
  }
  
  /// Get list of vocab IDs learned today from local cache
  List<String> get learnedTodayVocabIds => _storage.getLearnNewCompletedVocabIds(_todayKey);

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
  
  /// Get daily goal minutes
  int get dailyGoalMinutes => todayData.value?.dailyGoalMinutes ?? 15;
  
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
}
