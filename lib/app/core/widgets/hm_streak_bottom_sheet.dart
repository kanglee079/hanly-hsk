import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'hm_button.dart';
import 'hm_streak_widget.dart';

/// Streak bottom sheet showing detailed streak info
/// Shows: current streak, best streak, calendar, tips
class HMStreakBottomSheet extends StatefulWidget {
  final int streak;
  final int bestStreak;
  final String? streakRank;
  final bool hasStudiedToday;
  final int completedMinutes;
  final int dailyGoalMinutes;
  final List<StreakDayData> weeklyData;
  final VoidCallback? onStartLearning;

  const HMStreakBottomSheet({
    super.key,
    required this.streak,
    this.bestStreak = 0,
    this.streakRank,
    this.hasStudiedToday = true,
    this.completedMinutes = 0,
    this.dailyGoalMinutes = 15,
    this.weeklyData = const [],
    this.onStartLearning,
  });

  /// Show the streak bottom sheet
  static void show({
    required int streak,
    int bestStreak = 0,
    String? streakRank,
    bool hasStudiedToday = true,
    int completedMinutes = 0,
    int dailyGoalMinutes = 15,
    List<StreakDayData> weeklyData = const [],
    VoidCallback? onStartLearning,
  }) {
    Get.bottomSheet(
      HMStreakBottomSheet(
        streak: streak,
        bestStreak: bestStreak,
        streakRank: streakRank,
        hasStudiedToday: hasStudiedToday,
        completedMinutes: completedMinutes,
        dailyGoalMinutes: dailyGoalMinutes,
        weeklyData: weeklyData,
        onStartLearning: onStartLearning,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<HMStreakBottomSheet> createState() => _HMStreakBottomSheetState();
}

class _HMStreakBottomSheetState extends State<HMStreakBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = StreakConfig.fromStreak(
      widget.streak,
      hasStudiedToday: widget.hasStudiedToday,
    );

    // Calculate max height (80% of screen)
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.8;
    
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar - fixed at top
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
          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated streak display - more compact
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: HMStreakWidget(
                      streak: widget.streak,
                      streakRank: widget.streakRank,
                      hasStudiedToday: widget.hasStudiedToday,
                      size: StreakWidgetSize.large,
                      showMessage: true,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats row
                  _buildStatsRow(isDark),

                  const SizedBox(height: 20),

                  // Weekly calendar
                  _buildWeeklyCalendar(isDark, config),

                  const SizedBox(height: 20),

                  // Streak milestones
                  _buildMilestones(isDark, config),

                  const SizedBox(height: 20),

                  // Tips section - more compact
                  _buildTips(isDark, config),

                  // Action button (if not studied today)
                  if (!widget.hasStudiedToday && widget.streak > 0) ...[
                    const SizedBox(height: 20),
                    _buildWarningCard(isDark),
                    const SizedBox(height: 12),
                    HMButton(
                      text: '🔥 Học ngay để giữ chuỗi!',
                      onPressed: () {
                        Get.back();
                        widget.onStartLearning?.call();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            isDark,
            icon: Icons.local_fire_department,
            iconColor: AppColors.streak,
            label: 'Hiện tại',
            value: '${widget.streak}',
            unit: 'ngày',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            isDark,
            icon: Icons.emoji_events,
            iconColor: AppColors.secondary,
            label: 'Kỷ lục',
            value: '${widget.bestStreak > 0 ? widget.bestStreak : widget.streak}',
            unit: 'ngày',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            isDark,
            icon: Icons.timer,
            iconColor: AppColors.primary,
            label: 'Hôm nay',
            value: '${widget.completedMinutes}',
            unit: '/${widget.dailyGoalMinutes}p',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    bool isDark, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: unit,
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar(bool isDark, StreakConfig config) {
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final today = DateTime.now().weekday; // 1 = Monday

    // Generate 7 days with data
    List<StreakDayData> weekData = [];
    if (widget.weeklyData.isNotEmpty) {
      weekData = widget.weeklyData;
    } else {
      // Generate dummy data if not provided
      for (int i = 1; i <= 7; i++) {
        weekData.add(StreakDayData(
          dayOfWeek: i,
          isCompleted: i < today, // Past days completed
          isToday: i == today,
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tuần này',
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final dayData = weekData.length > index
                ? weekData[index]
                : StreakDayData(dayOfWeek: index + 1, isCompleted: false);
            final isToday = dayData.isToday;
            final isCompleted = dayData.isCompleted;

            return Column(
              children: [
                Text(
                  days[index],
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiary,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? config.iconColor
                        : (isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.surfaceVariant),
                    shape: BoxShape.circle,
                    border: isToday
                        ? Border.all(color: config.iconColor, width: 2)
                        : null,
                  ),
                  child: isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 20,
                        )
                      : isToday
                          ? Icon(
                              widget.hasStudiedToday
                                  ? Icons.check_rounded
                                  : Icons.remove_rounded,
                              color: config.iconColor,
                              size: 20,
                            )
                          : null,
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMilestones(bool isDark, StreakConfig config) {
    final milestones = [
      _Milestone(days: 7, label: '1 tuần', emoji: '🎯', reached: widget.streak >= 7),
      _Milestone(days: 14, label: '2 tuần', emoji: '⭐', reached: widget.streak >= 14),
      _Milestone(days: 30, label: '1 tháng', emoji: '🏆', reached: widget.streak >= 30),
      _Milestone(days: 100, label: '100 ngày', emoji: '👑', reached: widget.streak >= 100),
    ];

    // Find next milestone
    final nextMilestone = milestones.firstWhere(
      (m) => !m.reached,
      orElse: () => milestones.last,
    );
    
    final daysLeft = nextMilestone.days - widget.streak;
    final progress = (widget.streak / nextMilestone.days).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mốc tiếp theo',
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                config.iconColor.withAlpha(20),
                config.iconColor.withAlpha(5),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: config.iconColor.withAlpha(50),
            ),
          ),
          child: Row(
            children: [
              Text(nextMilestone.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextMilestone.label,
                      style: AppTypography.titleMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Còn $daysLeft ngày nữa',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress circle
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                      backgroundColor: isDark
                          ? AppColors.borderDark
                          : AppColors.border,
                      valueColor: AlwaysStoppedAnimation(config.iconColor),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: AppTypography.labelMedium.copyWith(
                        color: config.iconColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTips(bool isDark, StreakConfig config) {
    final tips = [
      '💡 Học mỗi ngày chỉ 5 phút cũng đủ giữ chuỗi',
      '⏰ Đặt lịch nhắc nhở để không quên',
      '🎯 Mục tiêu nhỏ mỗi ngày tốt hơn cố gắng nhiều 1 ngày',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mẹo giữ chuỗi',
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ...tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                tip,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildWarningCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.warning.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chuỗi ${widget.streak} ngày sắp mất!',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Học ngay hôm nay để giữ chuỗi',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Milestone {
  final int days;
  final String label;
  final String emoji;
  final bool reached;

  const _Milestone({
    required this.days,
    required this.label,
    required this.emoji,
    required this.reached,
  });
}

/// Data for a single day in streak calendar
class StreakDayData {
  final int dayOfWeek; // 1-7 (Mon-Sun)
  final bool isCompleted;
  final bool isToday;
  final int minutes;

  const StreakDayData({
    required this.dayOfWeek,
    this.isCompleted = false,
    this.isToday = false,
    this.minutes = 0,
  });
}

