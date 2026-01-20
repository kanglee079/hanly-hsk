import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../data/models/today_model.dart';
import '../../data/repositories/me_repo.dart';
import '../../services/auth_session_service.dart';
import '../../services/storage_service.dart';
import '../../services/realtime/today_store.dart';
import '../../core/widgets/hm_bottom_sheet.dart';
import '../../core/widgets/hm_toast.dart';
import '../../core/widgets/hm_streak_bottom_sheet.dart';
import '../../core/constants/strings_vi.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/hm_button.dart';
import '../../routes/app_routes.dart';
import '../practice/practice_controller.dart' show PracticeMode;

/// Me controller
class MeController extends GetxController {
  final AuthSessionService _authService = Get.find<AuthSessionService>();
  final StorageService _storage = Get.find<StorageService>();
  final MeRepo _meRepo = Get.find<MeRepo>();
  final TodayStore _todayStore = Get.find<TodayStore>();

  // User data
  UserModel? get user => _authService.currentUser.value;
  String get displayName =>
      user?.displayName ?? user?.profile?.displayName ?? '';
  String get email => user?.email ?? '';
  String? get avatarUrl => user?.avatarUrl;

  // Anonymous user detection
  bool get isAnonymous => _authService.isAnonymous.value;
  String? get userEmail => isAnonymous ? null : email;

  // Offline mode detection (auth failed, but app still works)
  bool get isOfflineMode => _authService.isOfflineMode.value;

  /// Retry authentication (when offline mode is active)
  Future<bool> retryAuthentication() async {
    final success = await _authService.retryAuthentication();
    if (success) {
      await refresh(); // Refresh data after successful auth
    }
    return success;
  }

  // Stats data
  late final Rx<TodayModel?> todayData = _todayStore.today;
  final RxBool isUpdatingGoal = false.obs;

  // Optimistic local override for daily goal (used immediately after update)
  final RxnInt _localDailyGoalOverride = RxnInt(null);

  // Daily goal data - LOCAL STORAGE is primary for user preferences
  int get dailyGoalTarget {
    // Use local override if set (optimistic update)
    if (_localDailyGoalOverride.value != null) {
      return _localDailyGoalOverride.value!;
    }
    // LOCAL STORAGE FIRST - User's explicit choice
    final storedLimit = _storage.userDailyNewLimit;
    if (storedLimit > 0) return storedLimit;

    // Fallback to API data
    return user?.profile?.dailyNewLimit ?? todayData.value?.dailyNewLimit ?? 10;
  }

  int get dailyGoalCurrent => todayData.value?.newLearnedToday ?? 0;
  double get dailyGoalProgress {
    if (dailyGoalTarget == 0) return 0;
    return (dailyGoalCurrent / dailyGoalTarget).clamp(0.0, 1.0);
  }

  int get dailyGoalPercent => (dailyGoalProgress * 100).round();

  // Stats
  int get streak => todayData.value?.streak ?? 0;
  int get bestStreak => todayData.value?.bestStreak ?? streak;
  int get masteredCount => todayData.value?.masteredCount ?? 0;
  int get reviewedToday => todayData.value?.reviewed ?? 0;
  int get totalLearned => todayData.value?.totalLearned ?? 0;

  // Streak helpers
  String get streakRank => todayData.value?.streakRank ?? '';
  StreakStatus? get streakStatus => todayData.value?.streakStatus;
  bool get hasStudiedToday {
    if (streakStatus != null) return streakStatus!.hasStudiedToday;
    return (todayData.value?.completedMinutes ?? 0) > 0;
  }

  bool get isStreakAtRisk {
    _todayStore.now.value;
    return streakStatus?.isAtRisk ?? (!hasStudiedToday && streak > 0);
  }

  String get timeUntilLoseStreak {
    _todayStore.now.value;
    return streakStatus?.timeUntilLoseStreak ?? '';
  }

  int get completedMinutes => todayData.value?.completedMinutes ?? 0;

  // Words learned today (for review feature)
  int get wordsLearnedToday =>
      todayData.value?.newLearnedToday ?? todayData.value?.newLearned ?? 0;
  int get wordsDueToday => todayData.value?.reviewCount ?? 0;

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
      dailyGoalMinutes: todayData.value?.dailyGoalMinutes ?? 15,
      weeklyData: weeklyStreakData,
      onStartLearning: () => Get.toNamed(
        Routes.practice,
        arguments: {'mode': PracticeMode.learnNew},
      ),
    );
  }

  @override
  void onInit() {
    super.onInit();
    // OPTIMIZED: Only sync if no data yet (RealtimeSyncService handles regular sync)
    if (todayData.value == null) {
      _todayStore.syncNow(force: true);
    }

    // Watch for user profile changes - just refresh local data, don't re-sync
    // RealtimeSyncService already handles auth state changes
    ever(_authService.currentUser, (_) {
      todayData.refresh(); // Just trigger UI update
    });

    // Listen to onLearnedUpdate event from Practice for refresh
    ever(_todayStore.onLearnedUpdate, (_) {
      // Refresh local stats immediately when Practice finishes
      // Note: Data is already synced by PracticeController
      todayData.refresh(); // Trigger GetX update
    });
  }

  Future<void> loadStats() async {
    await _todayStore.syncNow(force: true);
  }

  /// Refresh all data - for pull-to-refresh
  @override
  Future<void> refresh() async {
    await Future.wait([loadStats(), _authService.fetchCurrentUser()]);
  }

  void goToFavorites() => Get.toNamed(Routes.favorites);
  void goToDecks() => Get.toNamed(Routes.decks);
  void goToSettings() => Get.toNamed(Routes.settings);
  void goToDonation() => Get.toNamed(Routes.donation);
  void goToStats() => Get.toNamed(Routes.stats);
  void goToLeaderboard() => Get.toNamed(Routes.leaderboard);

  /// Start review session for words learned today
  void reviewTodayWords() {
    if (wordsLearnedToday == 0) {
      HMToast.info('Chưa có từ nào được học hôm nay để ôn tập!');
      return;
    }

    // Navigate to practice with reviewSRS mode
    Get.toNamed(Routes.practice, arguments: {'mode': PracticeMode.reviewSRS});
  }

  void goToAccount() {
    Get.toNamed(Routes.editProfile);
  }

  void goToNotifications() {
    Get.toNamed(Routes.notificationSettings);
  }

  void goToSoundSettings() {
    Get.toNamed(Routes.soundSettings);
  }

  void goToVietnameseSupport() {
    // Vietnamese support is a profile setting - navigate to edit profile
    Get.toNamed(Routes.editProfile);
  }

  void goToOffline() {
    Get.toNamed(Routes.offlineDownload);
  }

  void editProfile() {
    Get.toNamed(Routes.editProfile);
  }

  /// Show comprehensive learning settings sheet (HSK level, goal type, focus skills)
  Future<void> adjustLearningSettings() async {
    // Get current profile values
    final profile = user?.profile;
    final RxString selectedLevel = RxString(profile?.currentLevel ?? 'HSK1');
    final RxString selectedGoalType = RxString(
      profile?.goalType?.apiValue ?? 'both',
    );
    // LOCAL STORAGE FIRST for user preferences, fallback to profile
    final storedLimit = _storage.userDailyNewLimit;
    final currentWords = storedLimit > 0
        ? storedLimit
        : (profile?.dailyNewLimit ?? 10);
    final RxInt selectedWords = RxInt(currentWords);
    final RxBool listeningEnabled = RxBool(
      (profile?.focusWeights?.listening ?? 0) > 0,
    );
    final RxBool hanziEnabled = RxBool((profile?.focusWeights?.hanzi ?? 0) > 0);

    final result = await Get.bottomSheet<bool>(
      Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final screenHeight = MediaQuery.of(context).size.height;
          final bottomPadding = MediaQuery.of(context).padding.bottom;

          return Container(
            constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title row with close button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Điều chỉnh học tập',
                          style: AppTypography.titleLarge.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // HSK Level Section
                          Text(
                            'Cấp độ HSK hiện tại',
                            style: AppTypography.titleSmall.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [1, 2, 3, 4, 5, 6].map((level) {
                              final isSelected =
                                  selectedLevel.value == 'HSK$level';
                              return GestureDetector(
                                onTap: () => selectedLevel.value = 'HSK$level',
                                child: Container(
                                  width: 56,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark
                                              ? AppColors.surfaceVariantDark
                                              : AppColors.surfaceVariant),
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                            color: isDark
                                                ? AppColors.borderDark
                                                : AppColors.border,
                                          ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'HSK$level',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: isSelected
                                          ? AppColors.white
                                          : (isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimary),
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),

                          // Goal Type Section
                          Text(
                            'Mục tiêu học tập',
                            style: AppTypography.titleSmall.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildGoalTypeOption(
                            'hsk_exam',
                            'Thi HSK',
                            'Tập trung ôn thi, học theo cấu trúc HSK',
                            Icons.school,
                            selectedGoalType.value == 'hsk_exam',
                            isDark,
                            () => selectedGoalType.value = 'hsk_exam',
                          ),
                          const SizedBox(height: 8),
                          _buildGoalTypeOption(
                            'conversation',
                            'Giao tiếp',
                            'Học hội thoại, nghe nói thực tế',
                            Icons.chat_bubble_outline,
                            selectedGoalType.value == 'conversation',
                            isDark,
                            () => selectedGoalType.value = 'conversation',
                          ),
                          const SizedBox(height: 8),
                          _buildGoalTypeOption(
                            'both',
                            'Cả hai',
                            'Kết hợp thi cử và giao tiếp',
                            Icons.auto_awesome,
                            selectedGoalType.value == 'both',
                            isDark,
                            () => selectedGoalType.value = 'both',
                          ),

                          const SizedBox(height: 24),

                          // Daily Words Section (primary)
                          Text(
                            'Số từ mới mỗi ngày',
                            style: AppTypography.titleSmall.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [3, 5, 10, 20].map((words) {
                              final isSelected = selectedWords.value == words;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => selectedWords.value = words,
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      right: words != 20 ? 8 : 0,
                                    ),
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDark
                                                ? AppColors.surfaceVariantDark
                                                : AppColors.surfaceVariant),
                                      borderRadius: BorderRadius.circular(12),
                                      border: isSelected
                                          ? null
                                          : Border.all(
                                              color: isDark
                                                  ? AppColors.borderDark
                                                  : AppColors.border,
                                            ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '$words',
                                          style: AppTypography.titleMedium
                                              .copyWith(
                                                color: isSelected
                                                    ? AppColors.white
                                                    : (isDark
                                                          ? AppColors
                                                                .textPrimaryDark
                                                          : AppColors
                                                                .textPrimary),
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                              ),
                                        ),
                                        Text(
                                          'từ',
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                                color: isSelected
                                                    ? AppColors.white.withAlpha(
                                                        200,
                                                      )
                                                    : (isDark
                                                          ? AppColors
                                                                .textTertiaryDark
                                                          : AppColors
                                                                .textTertiary),
                                                fontSize: 10,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          // Show estimated time
                          Obx(
                            () => Text(
                              _getWordsDescription(selectedWords.value),
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Focus Skills Section
                          Text(
                            'Kỹ năng tập trung',
                            style: AppTypography.titleSmall.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSkillToggle(
                                  'Nghe',
                                  Icons.headphones,
                                  listeningEnabled.value,
                                  isDark,
                                  () => listeningEnabled.value =
                                      !listeningEnabled.value,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSkillToggle(
                                  'Chữ Hán',
                                  Icons.translate,
                                  hanziEnabled.value,
                                  isDark,
                                  () =>
                                      hanziEnabled.value = !hanziEnabled.value,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),

                // Fixed bottom buttons
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: HMButton(
                          text: S.cancel,
                          variant: HMButtonVariant.outline,
                          onPressed: () => Get.back(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: HMButton(
                          text: S.save,
                          onPressed: () => Get.back(result: true),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );

    if (result == true) {
      await _updateLearningSettings(
        level: selectedLevel.value,
        goalType: selectedGoalType.value,
        dailyWords: selectedWords.value,
        listeningEnabled: listeningEnabled.value,
        hanziEnabled: hanziEnabled.value,
      );
    }
  }

  Widget _buildGoalTypeOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
    bool isSelected,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(20)
              : (isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariant),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.border),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withAlpha(30)
                    : (isDark ? AppColors.surfaceDark : AppColors.surface),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillToggle(
    String label,
    IconData icon,
    bool isEnabled,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.primary.withAlpha(20)
              : (isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariant),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.border),
            width: isEnabled ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isEnabled
                  ? AppColors.primary
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isEnabled
                    ? AppColors.primary
                    : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary),
                fontWeight: isEnabled ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateLearningSettings({
    required String level,
    required String goalType,
    required int dailyWords,
    required bool listeningEnabled,
    required bool hanziEnabled,
  }) async {
    isUpdatingGoal.value = true;
    try {
      // Calculate dailyMinutes based on words (words is primary, 1 word = 1 minute)
      final dailyMinutes = _wordsToMinutes(dailyWords);
      final dailyNewLimit = dailyWords;

      // SAVE TO LOCAL STORAGE FIRST (primary source for user preferences)
      _storage.userDailyNewLimit = dailyNewLimit;
      _storage.userLevel = level;

      // Calculate focus weights
      final listening = listeningEnabled ? 1.0 : 0.0;
      final hanzi = hanziEnabled ? 1.0 : 0.0;
      final total = listening + hanzi + 1.0;
      final focusWeights = {
        'listening': listening / total,
        'hanzi': hanzi / total,
        'meaning': 1.0 / total,
      };

      await _meRepo.updateProfile({
        'currentLevel': level,
        'goalType': goalType,
        'dailyMinutesTarget': dailyMinutes,
        'dailyNewLimit': dailyNewLimit,
        'focusWeights': focusWeights,
      });

      // Sync both user profile AND today data to update UI immediately
      await Future.wait([
        _authService.fetchCurrentUser(),
        _todayStore.syncNow(force: true),
      ]);
      HMToast.success('Đã cập nhật cài đặt học tập');
    } catch (e) {
      // Even if API fails, local storage is already saved
      HMToast.error(S.errorUnknown);
    } finally {
      isUpdatingGoal.value = false;
    }
  }

  /// Show simple slider to adjust daily word count
  /// All users can choose up to 100 words/day
  Future<void> adjustDailyWordCount() async {
    final currentGoal = dailyGoalTarget;
    final RxInt selectedGoal = RxInt(currentGoal);

    // All users have the same max limit
    const maxWords = 100;
    final divisions = ((maxWords - 5) / 5).round();

    final result = await Get.bottomSheet<int>(
      Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bottomPadding = MediaQuery.of(context).padding.bottom;

          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title row with close button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Điều chỉnh mục tiêu từ',
                          style: AppTypography.titleLarge.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Số từ mới học mỗi ngày',
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Goal selector with Obx
                      Obx(
                        () => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Display current selection
                            Center(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${selectedGoal.value}',
                                      style: AppTypography.displaySmall
                                          .copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    TextSpan(
                                      text: ' ${S.words}/ngày',
                                      style: AppTypography.titleMedium.copyWith(
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Slider
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor: isDark
                                    ? AppColors.surfaceVariantDark
                                    : AppColors.surfaceVariant,
                                thumbColor: AppColors.primary,
                                overlayColor: AppColors.primary.withAlpha(25),
                                trackHeight: 6,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 12,
                                ),
                              ),
                              child: Slider(
                                value: selectedGoal.value.toDouble().clamp(
                                  5,
                                  maxWords.toDouble(),
                                ),
                                min: 5,
                                max: maxWords.toDouble(),
                                divisions: divisions,
                                onChanged: (value) {
                                  selectedGoal.value = value.round();
                                },
                              ),
                            ),

                            // Labels
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '5 ${S.words}',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.textTertiaryDark
                                        : AppColors.textTertiary,
                                  ),
                                ),
                                Text(
                                  '$maxWords ${S.words}',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.textTertiaryDark
                                        : AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Fixed bottom buttons
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPadding + 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: HMButton(
                          text: S.cancel,
                          variant: HMButtonVariant.outline,
                          onPressed: () => Get.back(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: HMButton(
                          text: S.save,
                          onPressed: () => Get.back(result: selectedGoal.value),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );

    if (result != null && result != currentGoal) {
      isUpdatingGoal.value = true;
      // SAVE TO LOCAL STORAGE FIRST (primary source for user preferences)
      // This ensures the value persists even if API call fails
      _storage.userDailyNewLimit = result;
      // Optimistically update local override for immediate UI feedback
      _localDailyGoalOverride.value = result;

      try {
        await _meRepo.updateProfile({'dailyNewLimit': result});
        // Sync both user profile AND today data to update UI
        await Future.wait([
          _authService.fetchCurrentUser(),
          _todayStore.syncNow(force: true),
        ]);
        HMToast.success('Đã cập nhật mục tiêu từ');
      } catch (e) {
        // Revert optimistic update on error
        _localDailyGoalOverride.value = null;
        // Revert local storage to previous value
        _storage.userDailyNewLimit = currentGoal;
        HMToast.error(S.errorUnknown);
      } finally {
        isUpdatingGoal.value = false;
        // Clear override after sync completes - profile should be updated now
        _localDailyGoalOverride.value = null;
      }
    }
  }

  Future<void> logout() async {
    final confirmed = await HMBottomSheet.showConfirm(
      title: S.signOut,
      message: S.signOutConfirm,
      confirmText: S.signOut,
      cancelText: S.cancel,
    );

    if (confirmed == true) {
      await _authService.logout();
    }
  }

  Future<void> deleteAccount() async {
    // Navigate to delete account confirmation screen
    Get.toNamed(Routes.deleteAccount);
  }

  // ===== HELPER METHODS =====

  /// Convert words to minutes (1 word = 1 minute)
  int _wordsToMinutes(int words) => words;

  /// Get description for word count (1 word = 1 minute)
  String _getWordsDescription(int words) {
    switch (words) {
      case 3:
        return 'Nhẹ nhàng • ~3 phút mỗi ngày';
      case 5:
        return 'Cơ bản • ~5 phút mỗi ngày';
      case 10:
        return 'Cân bằng • ~10 phút mỗi ngày';
      case 20:
        return 'Nghiêm túc • ~20 phút mỗi ngày';
      default:
        return '~$words phút mỗi ngày';
    }
  }
}
