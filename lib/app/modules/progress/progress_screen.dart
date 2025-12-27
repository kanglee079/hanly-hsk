import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import 'progress_controller.dart';

/// Progress screen showing streak, calendar, and next goal
class ProgressScreen extends GetView<ProgressController> {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: HMAppBar(
        title: 'Tiến độ',
        actions: [
          IconButton(
            onPressed: () {
              // Settings
            },
            icon: Icon(
              Icons.settings_outlined,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Streak section
              _buildStreakSection(isDark),

              const SizedBox(height: 24),

              // Stats row
              _buildStatsRow(isDark),

              const SizedBox(height: 24),

              // Calendar
              _buildCalendarCard(isDark),

              const SizedBox(height: 24),

              // Next goal card
              _buildNextGoalCard(isDark),

              const SizedBox(height: 24),

              // Quote
              _buildQuote(isDark),

              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStreakSection(bool isDark) {
    return Column(
      children: [
        // Use the large HMStreakWidget with consistent props
        HMStreakWidget(
          streak: controller.streak.value,
          streakRank: controller.streakRank.value,
          hasStudiedToday: controller.hasStudiedToday.value,
          isAtRisk: !controller.hasStudiedToday.value && controller.streak.value > 0,
          onTap: controller.showStreakDetails, // Open details sheet
          size: StreakWidgetSize.large,
          showMessage: true,
        ),

        const SizedBox(height: 16),

        // Freeze badge (if equipped)
        if (controller.hasStreakFreeze.value)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.hsk2.withAlpha(30)
                  : AppColors.hsk2.withAlpha(20),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.hsk2.withAlpha(50),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('❄️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'Đã trang bị đóng băng',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.hsk2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              label: 'KÝ TỰ',
              value: '${controller.totalWords.value}',
              icon: Icons.translate,
              isDark: isDark,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          Expanded(
            child: _StatColumn(
              label: 'THỜI GIAN',
              value: '${controller.totalMinutes.value}p',
              icon: Icons.access_time_filled,
              isDark: isDark,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          Expanded(
            child: _StatColumn(
              label: 'CHÍNH XÁC',
              value: '${controller.accuracy.value}%',
              icon: Icons.check_circle,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(bool isDark) {
    return HMCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Month header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() => Text(
                    controller.currentMonthLabel.value,
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  )),
              Row(
                children: [
                  GestureDetector(
                    onTap: controller.previousMonth,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        size: 20,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: controller.nextMonth,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Day headers
          Row(
            children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
                .map((d) => Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 12),

          // Calendar grid
          Obx(() => _buildCalendarGrid(isDark)),

          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ít',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 8),
              ...[0.2, 0.4, 0.6, 1.0].map((intensity) => Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha((intensity * 255).round()),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
              const SizedBox(width: 8),
              Text(
                'Nhiều',
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
    );
  }

  Widget _buildCalendarGrid(bool isDark) {
    final days = controller.calendarDays;

    // Split into weeks (7 days each)
    List<List<CalendarDayData>> weeks = [];
    for (int i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, (i + 7 > days.length) ? days.length : i + 7));
    }

    return Column(
      children: weeks.map((week) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: week.map((day) {
              if (day.day == 0) {
                // Empty cell for padding
                return Expanded(child: Container());
              }

              final isToday = day.isToday;
              final hasActivity = day.minutes > 0;
              final intensity = day.intensity;

              return Expanded(
                child: Container(
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: hasActivity
                        ? AppColors.primary.withAlpha((intensity * 255).round())
                        : (isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.surfaceVariant),
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: AppTypography.labelMedium.copyWith(
                        color: hasActivity || isToday
                            ? (intensity > 0.5 ? Colors.white : AppColors.primary)
                            : (isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiary),
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNextGoalCard(bool isDark) {
    final nextGoal = controller.nextGoal.value;
    final progress = controller.goalProgress.value;
    final target = controller.goalTarget.value;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4F46E5),
            Color(0xFF7C3AED),
          ],
        ),
        borderRadius: AppSpacing.borderRadiusXl,
      ),
      child: Row(
        children: [
          // Trophy icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('🏆', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mục tiêu tiếp theo',
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white.withAlpha(200),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nextGoal,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: target > 0 ? progress / target : 0,
                    backgroundColor: Colors.white.withAlpha(50),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Progress text
          Text(
            '$progress/$target',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuote(bool isDark) {
    return Column(
      children: [
        Text(
          '"三人行，必有我师焉"',
          style: AppTypography.hanziMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tam nhân hành, tất hữu ngã sư yên',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              value,
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
}

