import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/strings_vi.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/date_format.dart';
import '../../routes/app_routes.dart';
import '../../data/models/vocab_model.dart';
import '../../services/tutorial_service.dart';
import 'today_controller.dart';

/// Today tab screen - matches the provided design exactly
class TodayScreen extends GetView<TodayController> {
  const TodayScreen({super.key});

  // Get registered keys from TutorialService
  GlobalKey get _nextActionKey =>
      Get.find<TutorialService>().registerKey('today_next_action');
  GlobalKey get _progressRingKey =>
      Get.find<TutorialService>().registerKey('today_progress_ring');
  GlobalKey get _streakKey =>
      Get.find<TutorialService>().registerKey('today_streak');
  GlobalKey get _quickActionsKey =>
      Get.find<TutorialService>().registerKey('today_quick_actions');
  GlobalKey get _learnedTodayKey =>
      Get.find<TutorialService>().registerKey('today_learned');
  GlobalKey get _dueTodayKey =>
      Get.find<TutorialService>().registerKey('today_due');
  GlobalKey get _forecastKey =>
      Get.find<TutorialService>().registerKey('today_forecast');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildScreenContent(context, isDark);
  }

  Widget _buildScreenContent(BuildContext context, bool isDark) {
    return AppScaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.loadTodayData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: AppSpacing.screenPadding.copyWith(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== HEADER COMPACT =====
                  _buildCompactHeader(isDark),

                  const SizedBox(height: 12),

                  // ===== NÚT HỌC CHÍNH (CTA) =====
                  Showcase(
                    key: _nextActionKey,
                    title: 'Hành động tiếp theo',
                    description:
                        'Đây là thẻ gợi ý hành động bạn nên làm tiếp. Nhấn vào để bắt đầu học ngay!',
                    overlayOpacity: 0.7,
                    targetShapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Obx(() => _buildNextActionCard()),
                  ),

                  const SizedBox(height: 12),

                  // ===== THỐNG KÊ COMPACT =====
                  Showcase(
                    key: _progressRingKey,
                    title: 'Tiến độ hôm nay',
                    description:
                        'Vòng tròn hiển thị số từ đã học và thời gian đã học trong ngày.',
                    overlayOpacity: 0.7,
                    targetShapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Obx(() {
                      controller.todayData.value;
                      controller.localLearnedCount.value;
                      controller.learnedTodayData.value;
                      return _buildCompactStatsRow(isDark);
                    }),
                  ),

                  const SizedBox(height: 12),

                  // ===== STREAK WIDGET =====
                  Showcase(
                    key: _streakKey,
                    title: 'Chuỗi ngày học',
                    description:
                        'Duy trì streak để nhận phần thưởng và điểm xếp hạng cao hơn!',
                    overlayOpacity: 0.7,
                    targetShapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Obx(() => _buildStreakWidget(isDark)),
                  ),

                  const SizedBox(height: 16),

                  // ===== HÀNH ĐỘNG NHANH =====
                  Showcase(
                    key: _quickActionsKey,
                    title: 'Ôn tập & Luyện tập',
                    description:
                        'Chọn Ôn tập SRS để ôn từ cũ, hoặc Game 30s để kiếm XP nhanh!',
                    overlayOpacity: 0.7,
                    targetShapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Obx(() => _buildQuickActionsRow(isDark)),
                  ),

                  const SizedBox(height: 16),

                  // ===== CỦNG CỐ TỪ VỪA HỌC =====
                  Showcase(
                    key: _learnedTodayKey,
                    title: 'Củng cố từ vừa học',
                    description:
                        'Nhấn "Ôn tập" để củng cố ngay các từ bạn vừa học hôm nay.',
                    overlayOpacity: 0.7,
                    targetShapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Obx(() => _buildLearnedTodaySection()),
                  ),

                  const SizedBox(height: 12),

                  // ===== CẦN ÔN HÔM NAY =====
                  Showcase(
                    key: _dueTodayKey,
                    title: 'Cần ôn hôm nay',
                    description:
                        'Danh sách từ đến hạn ôn theo thuật toán SRS. Nhấn "Xem tất cả" để bắt đầu!',
                    overlayOpacity: 0.7,
                    targetShapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Obx(() => _buildDueTodaySection(isDark)),
                  ),

                  const SizedBox(height: 12),

                  // ===== DỰ BÁO ÔN TẬP =====
                  Showcase(
                    key: _forecastKey,
                    title: 'Dự báo ôn tập',
                    description:
                        'Xem trước số từ cần ôn trong 7 ngày tới để lên kế hoạch học tập.',
                    overlayOpacity: 0.7,
                    targetShapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Obx(() => _buildForecastSection()),
                  ),

                  const SizedBox(height: 16),

                  // ===== BIỂU ĐỒ TUẦN =====
                  Obx(() => _buildWeeklyProgressChart(isDark)),

                  // Bottom padding for glass nav bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Section title - unified style across all sections
  Widget _buildSectionTitle(String title, bool isDark, {int? count}) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (count != null && count > 0) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Compact header - just date and title on same row
  Widget _buildCompactHeader(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title + Date
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormatUtil.formatDayFull(DateTime.now()).toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiary,
                letterSpacing: 0.8,
                fontSize: 10,
              ),
            ),
            Text(
              S.today,
              style: AppTypography.titleLarge.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Streak widget - displayed below progress ring
  Widget _buildStreakWidget(bool isDark) {
    final streak = controller.streak;
    final hasStudiedToday = controller.hasStudiedToday;
    final isAtRisk = controller.isStreakAtRisk;

    // For new users (streak = 0), show welcome widget
    final isNewUser = streak <= 0 && !isAtRisk;

    return GestureDetector(
      onTap: isNewUser ? null : controller.showStreakDetails,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isNewUser
                ? (isDark
                      ? [const Color(0xFF1E3A5F), const Color(0xFF2D4A6F)]
                      : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)])
                : isAtRisk && !hasStudiedToday
                ? (isDark
                      ? [const Color(0xFF422006), const Color(0xFF4D2C0D)]
                      : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)])
                : (isDark
                      ? [const Color(0xFF3D2F14), const Color(0xFF4D3D1F)]
                      : [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)]),
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isNewUser
                ? AppColors.primary.withValues(alpha: 0.3)
                : isAtRisk && !hasStudiedToday
                ? AppColors.warning.withValues(alpha: 0.4)
                : AppColors.streak.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Streak/Welcome icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  isNewUser ? '👋' : '🔥',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Streak info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isNewUser
                            ? 'Bắt đầu hành trình!'
                            : '$streak ngày streak',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (hasStudiedToday && !isNewUser) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '✓ Đã học',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isNewUser
                        ? 'Học từ đầu tiên để bắt đầu streak!'
                        : isAtRisk && !hasStudiedToday
                        ? 'Học ngay để giữ streak!'
                        : 'Tiếp tục phát huy nhé! 💪',
                    style: AppTypography.bodySmall.copyWith(
                      color: isNewUser
                          ? (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.primary)
                          : isAtRisk && !hasStudiedToday
                          ? AppColors.warning
                          : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            // Arrow (only show if not new user)
            if (!isNewUser)
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  /// Build stats card with dual-ring progress indicator (like the design)
  Widget _buildCompactStatsRow(bool isDark) {
    final data = controller.todayData.value;
    final loading = controller.isLoading.value;

    if (loading) {
      return const HMSkeletonCard(height: 160);
    }

    // Sử dụng learnedTodayCount (bao gồm cả local cache)
    final wordsLearned = controller.learnedTodayCount;
    // Use goals from controller (User Profile source of truth)
    final goal = controller.dailyNewLimit;
    final completedMinutes = data?.completedMinutes ?? 0;
    final goalMinutes = controller.dailyGoalMinutes;

    final wordsProgress = goal > 0
        ? (wordsLearned / goal).clamp(0.0, 1.0)
        : 0.0;
    final timeProgress = goalMinutes > 0
        ? (completedMinutes / goalMinutes).clamp(0.0, 1.0)
        : 0.0;

    return HMCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // Dual ring progress indicator
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring background (Time goal)
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark
                          ? AppColors.surfaceDark
                          : AppColors.border.withAlpha(80),
                    ),
                  ),
                ),
                // Outer ring progress (Time)
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: timeProgress,
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                // Inner ring background (Words)
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark
                          ? AppColors.surfaceDark
                          : AppColors.border.withAlpha(80),
                    ),
                  ),
                ),
                // Inner ring progress (Words)
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: wordsProgress,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryLight,
                    ),
                  ),
                ),
                // Center content - Minutes
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$completedMinutes',
                      style: AppTypography.displaySmall.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'PHÚT',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Legend row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Goal legend
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mục tiêu',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        '${goalMinutes}m',
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(width: 32),

              // Words legend
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Từ mới',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        '$wordsLearned/$goal',
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build the Next Action CTA card
  Widget _buildNextActionCard() {
    final action = controller.nextAction.value;
    if (action == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Show lock warning banner if new learning is blocked
        _buildLockWarningBanner(),
        HMNextActionCard(action: action, onTap: controller.executeNextAction),
      ],
    );
  }

  /// Build warning banner when learning is locked
  Widget _buildLockWarningBanner() {
    final data = controller.todayData.value;
    if (data == null || !data.isNewQueueLocked) {
      return const SizedBox.shrink();
    }

    final isReviewOverload = data.isBlockedByReviewOverload;
    final isMasteryRequired = data.isBlockedByMastery;

    if (!isReviewOverload && !isMasteryRequired) {
      return const SizedBox.shrink();
    }

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final String icon;
    final String title;
    final String message;

    if (isReviewOverload) {
      bgColor = AppColors.warning.withAlpha(15);
      borderColor = AppColors.warning.withAlpha(40);
      textColor = AppColors.warning;
      icon = '⚠️';
      title = 'Quá tải ôn tập';
      message =
          data.reviewOverloadInfo?.message ??
          'Có ${data.reviewQueue.length} từ cần ôn. Hãy ôn bớt để học tiếp!';
    } else {
      bgColor = AppColors.secondary.withAlpha(15);
      borderColor = AppColors.secondary.withAlpha(40);
      textColor = AppColors.secondary;
      icon = '🎯';
      title = 'Cần master từ đã học';
      final req = data.unlockRequirement;
      message =
          req?.message ??
          'Hãy ôn tập để master ${req?.wordsToMaster ?? 0} từ còn lại.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(
                    color: textColor.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build learned today section
  /// Hiển thị từ đã học hôm nay với nút Ôn tập (củng cố)
  Widget _buildLearnedTodaySection() {
    final items = controller.learnedTodayItems;
    final count = controller.learnedTodayCount; // Includes local cache
    final isLoading = controller.isLoadingLearnedToday.value;

    // Luôn hiển thị section này để user biết tính năng tồn tại
    // và tutorial có thể highlight được
    return HMLearnedTodayWidget(
      items: items,
      count: count,
      isLoading: isLoading,
      showEvenIfEmpty: true, // Luôn hiển thị, kể cả khi chưa học từ nào
      onTapReview: count > 0
          ? () => controller.startSession(SessionMode.reviewToday)
          : null,
      onTapItem: (item) {
        Get.toNamed(Routes.wordDetail, arguments: {'vocabId': item.id});
      },
    );
  }

  /// Build forecast section
  Widget _buildForecastSection() {
    // IMPORTANT: Explicitly observe reactive values for Obx to work
    final localForecast = controller.localForecastMap;
    final hasLocal = controller.hasLocalData.value;

    final days = controller.forecastDays;
    final isLoading = controller.isLoadingForecast.value;

    // OFFLINE-FIRST: Get tomorrow count from local data if available
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowKey =
        '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    final localTomorrowCount = localForecast[tomorrowKey] ?? 0;
    final serverTomorrowCount =
        controller.forecastData.value?.tomorrowReviewCount ?? 0;
    final tomorrowCount = hasLocal ? localTomorrowCount : serverTomorrowCount;

    if (days.isEmpty && !isLoading && !hasLocal) {
      return const SizedBox.shrink();
    }

    return HMForecastWidget(
      days: days,
      tomorrowCount: tomorrowCount,
      isLoading: isLoading,
    );
  }

  Widget _buildWeeklyProgressChart(bool isDark) {
    final data = controller.todayData.value;
    final weeklyProgress = data?.weeklyProgress ?? [];

    // If no data, show placeholder
    if (weeklyProgress.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate weekly stats
    final weeklyNewCount = weeklyProgress.fold(
      0,
      (sum, day) => sum + day.newCount,
    );
    final weeklyReviewCount = weeklyProgress.fold(
      0,
      (sum, day) => sum + day.reviewCount,
    );
    final weeklyMinutes = weeklyProgress.fold(
      0,
      (sum, day) => sum + day.minutes,
    );

    // Calculate average accuracy ONLY from days with activity
    // (days without activity shouldn't drag down the average)
    final daysWithActivity = weeklyProgress
        .where(
          (day) => day.newCount > 0 || day.reviewCount > 0 || day.minutes > 0,
        )
        .toList();
    final avgAccuracy = daysWithActivity.isNotEmpty
        ? daysWithActivity.fold(0, (sum, day) => sum + day.accuracy) ~/
              daysWithActivity.length
        : 0;

    // Calculate max minutes for scaling
    final maxMinutes = weeklyProgress
        .map((e) => e.minutes)
        .fold(0, (a, b) => a > b ? a : b);

    // Heights that adapt to content
    const double barMaxHeight = 60.0;
    const double labelHeight = 16.0;
    const double dayLabelHeight = 16.0;
    const double spacing = 6.0;
    const double totalHeight =
        barMaxHeight + labelHeight + dayLabelHeight + spacing * 2;

    return HMCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tuần này',
                style: AppTypography.titleSmall.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // View details button
              GestureDetector(
                onTap: () =>
                    HMWeeklyStatsSheet.show(weeklyProgress: weeklyProgress),
                child: Text(
                  'Xem thêm',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Weekly summary stats row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceVariantDark
                  : const Color(0xFFF8FAFC),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _WeekStatItem(
                  value: '$weeklyNewCount',
                  label: 'Từ mới',
                  color: AppColors.primary,
                  isDark: isDark,
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
                _WeekStatItem(
                  value: '$weeklyReviewCount',
                  label: 'Ôn tập',
                  color: AppColors.secondary,
                  isDark: isDark,
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
                _WeekStatItem(
                  value: '${weeklyMinutes}p',
                  label: 'Thời gian',
                  color: AppColors.streak,
                  isDark: isDark,
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
                _WeekStatItem(
                  value: '$avgAccuracy%',
                  label: 'Độ chính xác',
                  color: avgAccuracy >= 80
                      ? AppColors.success
                      : AppColors.warning,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Chart container with fixed height
          SizedBox(
            height: totalHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklyProgress.map((day) {
                final barHeight = maxMinutes > 0
                    ? (day.minutes / maxMinutes) * barMaxHeight
                    : 0.0;
                final isToday = day.isToday;

                return Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Minutes label - fixed height container
                      SizedBox(
                        height: labelHeight,
                        child: day.minutes > 0
                            ? Text(
                                '${day.minutes}',
                                style: TextStyle(
                                  color: isToday
                                      ? AppColors.primary
                                      : (isDark
                                            ? AppColors.textTertiaryDark
                                            : AppColors.textTertiary),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              )
                            : null,
                      ),
                      SizedBox(height: spacing),
                      // Bar
                      Container(
                        width: 20,
                        height: barHeight > 0 ? barHeight : 4,
                        decoration: BoxDecoration(
                          gradient: isToday
                              ? const LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    AppColors.primary,
                                    Color(0xFF818CF8),
                                  ],
                                )
                              : null,
                          color: isToday
                              ? null
                              : (day.minutes > 0
                                    ? (isDark
                                          ? AppColors.surfaceVariantDark
                                          : const Color(0xFFE2E8F0))
                                    : (isDark
                                          ? AppColors.borderDark
                                          : AppColors.border)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: spacing),
                      // Day label - fixed height
                      SizedBox(
                        height: dayLabelHeight,
                        child: Text(
                          day.dayLabel,
                          style: TextStyle(
                            color: isToday
                                ? AppColors.primary
                                : (isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textTertiary),
                            fontWeight: isToday
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow(bool isDark) {
    // IMPORTANT: Must explicitly observe reactive values for Obx to work
    // Reading these .value properties ensures Obx rebuilds when they change
    final localCount = controller.localDueCount.value;
    final hasLocal = controller.hasLocalData.value;
    final serverCount = controller.todayData.value?.dueCount ?? 0;

    // OFFLINE-FIRST: Once local data is initialized, ALWAYS use it
    // Local is updated immediately after review, server may be stale
    // hasLocal flag distinguishes "0 words due" from "not loaded yet"
    final dueCount = hasLocal ? localCount : serverCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        _buildSectionTitle('Ôn tập & Luyện tập', isDark),
        const SizedBox(height: 12),

        // Row: Ôn tập SRS + Game 30s
        Row(
          children: [
            // Ôn tập SRS - từ cần ôn theo lịch (từ ngày trước)
            Expanded(
              child: _QuickActionCard(
                icon: Icons.history_rounded,
                title: 'Ôn tập SRS',
                subtitle: dueCount > 0 ? 'Từ cũ cần ôn' : 'Không có từ',
                badge: dueCount > 0 ? '$dueCount' : null,
                badgeColor: AppColors.error,
                onTap: dueCount > 0
                    ? () => controller.startSession(SessionMode.review)
                    : null,
                isDark: isDark,
                isDisabled: dueCount == 0,
              ),
            ),
            const SizedBox(width: 12),
            // Game 30s
            Expanded(
              child: _QuickActionCard(
                icon: Icons.bolt,
                title: S.game30s,
                subtitle: 'Kiếm XP nhanh',
                iconColor: AppColors.streak,
                onTap: () => controller.startSession(SessionMode.game30),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // NOTE: "Củng cố từ vừa học" đã có trong _buildLearnedTodaySection()
  // với HMLearnedTodayWidget - KHÔNG trùng lặp ở đây

  Widget _buildDueTodaySection(bool isDark) {
    // IMPORTANT: Explicitly read reactive values for Obx to work
    final hasLocal = controller.hasLocalData.value;
    final localQueue = controller.localReviewQueue;
    final serverQueue = controller.todayData.value?.reviewQueue ?? [];
    final loading = controller.isLoading.value;

    // OFFLINE-FIRST: Use local data once initialized
    final reviewQueue = hasLocal ? localQueue : serverQueue;
    final dueItems = reviewQueue.take(5).toList();
    final totalDue = reviewQueue.length;

    if (loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(S.dueToday, totalDue, 'Xem tất cả', () {
            // Navigate to SRS Review List (not direct session)
            Get.toNamed(Routes.srsReviewList);
          }, isDark),
          const SizedBox(height: 12),
          const HMSkeletonCard(height: 72),
          const SizedBox(height: 8),
          const HMSkeletonCard(height: 72),
        ],
      );
    }

    final Widget content;

    if (dueItems.isEmpty) {
      content = Column(
        key: const ValueKey('due_empty'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(S.dueToday, isDark),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: AppSpacing.borderRadiusXl,
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 32,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tuyệt vời! Không có từ cần ôn',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      content = Column(
        key: ValueKey('due_list_$totalDue'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(S.dueToday, totalDue, 'Xem tất cả', () {
            // Navigate to SRS Review List (not direct session)
            Get.toNamed(Routes.srsReviewList);
          }, isDark),
          const SizedBox(height: 12),
          ...dueItems.map(
            (vocab) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DueVocabCard(vocab: vocab, isDark: isDark),
            ),
          ),
        ],
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        final offsetAnim = Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(anim);
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(position: offsetAnim, child: child),
        );
      },
      child: content,
    );
  }

  /// Section header with title, count badge, and action link
  Widget _buildSectionHeader(
    String title,
    int count,
    String action,
    VoidCallback onAction,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        GestureDetector(
          onTap: onAction,
          child: Text(
            action,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool isDark;
  final bool isDisabled;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor,
    this.iconColor,
    this.onTap,
    required this.isDark,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = isDisabled || onTap == null;
    final opacity = disabled ? 0.5 : 1.0;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: opacity,
        child: HMCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceVariant,
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: Icon(
                      icon,
                      color:
                          iconColor ??
                          (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary),
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor ?? AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge!,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
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
      ),
    );
  }
}

/// Due vocab card - matches SRS review list design
class _DueVocabCard extends StatelessWidget {
  final VocabModel vocab;
  final bool isDark;

  const _DueVocabCard({required this.vocab, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Determine urgency based on due date
    final now = DateTime.now();
    final dueDate = vocab.dueDate;
    final daysOverdue = dueDate != null ? now.difference(dueDate).inDays : 0;

    final isUrgent = daysOverdue > 3;
    final urgencyColor = isUrgent ? AppColors.error : AppColors.warning;
    final urgencyLabel = isUrgent ? 'Cần ôn' : 'Đến hạn';
    final timeLabel = _getDueDateText(dueDate, daysOverdue);

    return GestureDetector(
      onTap: () => Get.toNamed(Routes.wordDetail, arguments: {'vocab': vocab}),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            // Hanzi - simple text, no box
            SizedBox(
              width: 56,
              child: Text(
                vocab.hanzi,
                style: AppTypography.hanziLarge.copyWith(
                  fontSize: 32,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pinyin + HSK badge row
                  Row(
                    children: [
                      Text(
                        vocab.pinyin,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(40),
                          ),
                        ),
                        child: Text(
                          vocab.level,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Meaning
                  Text(
                    vocab.meaningViCapitalized,
                    style: AppTypography.titleSmall.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Urgency indicator column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Urgency badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: urgencyColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '!',
                        style: TextStyle(
                          color: urgencyColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        urgencyLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: urgencyColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Time label
                Text(
                  timeLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDueDateText(DateTime? dueDate, int daysOverdue) {
    if (dueDate == null) return 'Hôm nay';
    if (daysOverdue > 1) return 'Quá hạn $daysOverdue ngày';
    if (daysOverdue == 1) return 'Quá hạn 1 ngày';
    return 'Hôm nay';
  }
}

/// Weekly stat item widget
class _WeekStatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _WeekStatItem({
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
