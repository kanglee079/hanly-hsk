import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  // Tutorial keys
  static final GlobalKey headerKey = GlobalKey();
  static final GlobalKey nextActionKey = GlobalKey();
  static final GlobalKey progressRingKey = GlobalKey();
  static final GlobalKey quickActionsKey = GlobalKey();
  static final GlobalKey dueTodayKey = GlobalKey();
  static final GlobalKey weeklyChartKey = GlobalKey();
  
  // Flag to prevent multiple registrations
  static bool _keysRegistered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Register tutorial keys (only once)
    if (!_keysRegistered) {
      _keysRegistered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<TutorialService>()) {
          final tutorialService = Get.find<TutorialService>();
          tutorialService.registerKey('today_header', headerKey);
          tutorialService.registerKey('next_action_card', nextActionKey);
          tutorialService.registerKey('progress_ring', progressRingKey);
          tutorialService.registerKey('quick_actions', quickActionsKey);
          tutorialService.registerKey('due_today_section', dueTodayKey);
          tutorialService.registerKey('weekly_chart', weeklyChartKey);
        }
      });
    }

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
                  KeyedSubtree(
                    key: headerKey,
                    child: _buildCompactHeader(isDark),
                  ),

                  const SizedBox(height: 12),

                  // ===== NÚT HỌC CHÍNH (CTA) =====
                  Obx(() => KeyedSubtree(
                    key: nextActionKey,
                    child: _buildNextActionCard(),
                  )),

                  const SizedBox(height: 12),

                  // ===== THỐNG KÊ COMPACT =====
                  Obx(() => KeyedSubtree(
                    key: progressRingKey,
                    child: _buildCompactStatsRow(isDark),
                  )),

                  const SizedBox(height: 12),

                  // ===== STREAK WIDGET =====
                  Obx(() => _buildStreakWidget(isDark)),

                  const SizedBox(height: 16),

                  // ===== HÀNH ĐỘNG NHANH =====
                  Obx(() => KeyedSubtree(
                    key: quickActionsKey,
                    child: _buildQuickActionsRow(isDark),
                  )),

                  const SizedBox(height: 16),

                  // ===== CỦNG CỐ TỪ VỪA HỌC =====
                  Obx(() => _buildLearnedTodaySection()),

                  const SizedBox(height: 12),

                  // ===== CẦN ÔN HÔM NAY =====
                  Obx(() => KeyedSubtree(
                    key: dueTodayKey,
                    child: _buildDueTodaySection(isDark),
                  )),

                  const SizedBox(height: 12),

                  // ===== DỰ BÁO ÔN TẬP =====
                  Obx(() => _buildForecastSection()),

                  const SizedBox(height: 16),

                  // ===== BIỂU ĐỒ TUẦN =====
                  Obx(() => KeyedSubtree(
                    key: weeklyChartKey,
                    child: _buildWeeklyProgressChart(isDark),
                  )),

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
    
    if (streak <= 0 && !isAtRisk) return const SizedBox.shrink();
    
    return GestureDetector(
      onTap: controller.showStreakDetails,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isAtRisk && !hasStudiedToday
                ? [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)]
                : [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isAtRisk && !hasStudiedToday
                ? AppColors.warning.withValues(alpha: 0.4)
                : AppColors.streak.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Streak fire icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('🔥', style: TextStyle(fontSize: 22)),
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
                        '$streak ngày streak',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (hasStudiedToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                    isAtRisk && !hasStudiedToday
                        ? 'Học ngay để giữ streak!'
                        : 'Tiếp tục phát huy nhé! 💪',
                    style: AppTypography.bodySmall.copyWith(
                      color: isAtRisk && !hasStudiedToday
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
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
    final goal = data?.dailyNewLimit ?? 20;
    final completedMinutes = data?.completedMinutes ?? 0;
    final goalMinutes = data?.dailyGoalMinutes ?? 30;

    final wordsProgress = goal > 0 ? (wordsLearned / goal).clamp(0.0, 1.0) : 0.0;
    final timeProgress = goalMinutes > 0 ? (completedMinutes / goalMinutes).clamp(0.0, 1.0) : 0.0;

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
                      isDark ? AppColors.surfaceDark : AppColors.border.withAlpha(80),
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
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
                      isDark ? AppColors.surfaceDark : AppColors.border.withAlpha(80),
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
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                  ),
                ),
                // Center content - Minutes
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$completedMinutes',
                      style: AppTypography.displaySmall.copyWith(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'PHÚT',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
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
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        '${goalMinutes}m',
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
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
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        '$wordsLearned/$goal',
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
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
        HMNextActionCard(
          action: action,
          onTap: controller.executeNextAction,
        ),
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
      message = data.reviewOverloadInfo?.message ?? 
          'Có ${data.reviewQueue.length} từ cần ôn. Hãy ôn bớt để học tiếp!';
    } else {
      bgColor = AppColors.secondary.withAlpha(15);
      borderColor = AppColors.secondary.withAlpha(40);
      textColor = AppColors.secondary;
      icon = '🎯';
      title = 'Cần master từ đã học';
      final req = data.unlockRequirement;
      message = req?.message ?? 'Hãy ôn tập để master ${req?.wordsToMaster ?? 0} từ còn lại.';
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
    
    // Không ẩn nếu count > 0 (có từ trong local cache)
    if (count == 0 && !isLoading) {
      return const SizedBox.shrink();
    }
    
    return HMLearnedTodayWidget(
      items: items,
      count: count,
      isLoading: isLoading,
      showEvenIfEmpty: count > 0, // Show header even if items list is empty
      onTapReview: count > 0 ? () => controller.startSession(SessionMode.reviewToday) : null,
      onTapItem: (item) {
        Get.toNamed(Routes.wordDetail, arguments: {'vocabId': item.id});
      },
    );
  }
  
  /// Build forecast section
  Widget _buildForecastSection() {
    final days = controller.forecastDays;
    final tomorrowCount = controller.tomorrowReviewCount;
    final isLoading = controller.isLoadingForecast.value;
    
    if (days.isEmpty && !isLoading) {
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
    final weeklyNewCount = weeklyProgress.fold(0, (sum, day) => sum + day.newCount);
    final weeklyReviewCount = weeklyProgress.fold(0, (sum, day) => sum + day.reviewCount);
    final weeklyMinutes = weeklyProgress.fold(0, (sum, day) => sum + day.minutes);
    
    // Calculate average accuracy ONLY from days with activity
    // (days without activity shouldn't drag down the average)
    final daysWithActivity = weeklyProgress.where((day) => 
        day.newCount > 0 || day.reviewCount > 0 || day.minutes > 0
    ).toList();
    final avgAccuracy = daysWithActivity.isNotEmpty 
        ? daysWithActivity.fold(0, (sum, day) => sum + day.accuracy) ~/ daysWithActivity.length
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
    const double totalHeight = barMaxHeight + labelHeight + dayLabelHeight + spacing * 2;

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
                onTap: () => HMWeeklyStatsSheet.show(
                  weeklyProgress: weeklyProgress,
                ),
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
                  color: avgAccuracy >= 80 ? AppColors.success : AppColors.warning,
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
                            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
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
    final data = controller.todayData.value;
    final dueCount = data?.dueCount ?? 0;

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
                icon: Icons.history,
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
    final data = controller.todayData.value;
    final loading = controller.isLoading.value;
    final dueItems = data?.reviewQueue.take(5).toList() ?? [];
    final totalDue = data?.reviewQueue.length ?? 0;

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
          ...dueItems.map((vocab) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DueVocabCard(vocab: vocab, isDark: isDark),
              )),
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
  Widget _buildSectionHeader(String title, int count, String action, VoidCallback onAction, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      color: iconColor ?? (isDark
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
    final daysOverdue = dueDate != null 
        ? now.difference(dueDate).inDays 
        : 0;
    
    final isUrgent = daysOverdue > 3;
    final urgencyColor = isUrgent ? AppColors.error : AppColors.warning;
    final urgencyLabel = isUrgent ? 'Cần ôn' : 'Đến hạn';
    final timeLabel = _getDueDateText(dueDate, daysOverdue);

    return GestureDetector(
      onTap: () => Get.toNamed(
        Routes.wordDetail,
        arguments: {'vocab': vocab},
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark 
                ? AppColors.borderDark 
                : const Color(0xFFE2E8F0),
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
                            horizontal: 8, vertical: 2),
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
                    vocab.meaningVi,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
