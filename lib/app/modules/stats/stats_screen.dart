import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/me_repo.dart';
import 'stats_controller.dart';

/// Stats and achievements screen
class StatsScreen extends GetView<StatsController> {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: HMAppBar(title: 'Thống kê'),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const HMLoadingContent(
            message: 'Đang tải thống kê...',
            icon: Icons.bar_chart_rounded,
          );
        }

        return SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tab selector
              _buildTabSelector(isDark),
              const SizedBox(height: 24),

              // Tab content
              Obx(() {
                switch (controller.selectedTab.value) {
                  case 0:
                    return _buildStatsTab(isDark);
                  case 1:
                    return _buildAchievementsTab(isDark);
                  case 2:
                    return _buildCalendarTab(isDark);
                  default:
                    return const SizedBox.shrink();
                }
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTabSelector(bool isDark) {
    return Obx(() => Row(
          children: [
            _TabButton(
              label: 'Tổng quan',
              isSelected: controller.selectedTab.value == 0,
              onTap: () => controller.setTab(0),
            ),
            const SizedBox(width: 8),
            _TabButton(
              label: 'Huy hiệu',
              isSelected: controller.selectedTab.value == 1,
              onTap: () => controller.setTab(1),
            ),
            const SizedBox(width: 8),
            _TabButton(
              label: 'Lịch học',
              isSelected: controller.selectedTab.value == 2,
              onTap: () => controller.setTab(2),
            ),
          ],
        ));
  }

  Widget _buildStatsTab(bool isDark) {
    final stats = controller.stats.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview cards
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.book_outlined,
                value: '${stats?.totalWords ?? 0}',
                label: 'Từ đã học',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_outline,
                value: '${stats?.masteredWords ?? 0}',
                label: 'Đã thuộc',
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department,
                value: '${stats?.currentStreak ?? 0}',
                label: 'Streak hiện tại',
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.timer_outlined,
                value: '${stats?.totalMinutes ?? 0}',
                label: 'Phút học',
                color: AppColors.warning,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Detail stats
        Text(
          'Chi tiết',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        HMCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _StatRow(
                label: 'Streak dài nhất',
                value: '${stats?.longestStreak ?? 0} ngày',
                icon: Icons.emoji_events_outlined,
              ),
              const Divider(height: 24),
              _StatRow(
                label: 'Tổng số phiên học',
                value: '${stats?.totalSessions ?? 0}',
                icon: Icons.play_circle_outline,
              ),
              const Divider(height: 24),
              _StatRow(
                label: 'Độ chính xác TB',
                value: '${stats?.averageAccuracy.toStringAsFixed(0) ?? 0}%',
                icon: Icons.analytics_outlined,
              ),
              const Divider(height: 24),
              _StatRow(
                label: 'Tổng lượt ôn tập',
                value: '${stats?.totalReviews ?? 0}',
                icon: Icons.refresh,
              ),
              const Divider(height: 24),
              _StatRow(
                label: 'Phiên hoàn hảo',
                value: '${stats?.perfectSessions ?? 0}',
                icon: Icons.star_outline,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsTab(bool isDark) {
    final unlocked = controller.unlockedAchievements;
    final locked = controller.lockedAchievements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Unlocked section
        if (unlocked.isNotEmpty) ...[
          Text(
            'Đã mở khóa (${unlocked.length})',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...unlocked.map((a) => _AchievementCard(achievement: a, isDark: isDark)),
          const SizedBox(height: 24),
        ],

        // Locked section
        if (locked.isNotEmpty) ...[
          Text(
            'Chưa mở (${locked.length})',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...locked.map((a) => _AchievementCard(
                achievement: a,
                isDark: isDark,
                isLocked: true,
              )),
        ],

        if (unlocked.isEmpty && locked.isEmpty)
          HMEmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'Chưa có huy hiệu',
            description: 'Học tập để mở khóa huy hiệu!',
          ),
      ],
    );
  }

  Widget _buildCalendarTab(bool isDark) {
    final calendar = controller.calendar;

    if (calendar.isEmpty) {
      return HMEmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'Chưa có dữ liệu',
        description: 'Bắt đầu học để xem lịch sử!',
      );
    }

    // Group by month
    final Map<String, List<CalendarDay>> byMonth = {};
    for (final day in calendar) {
      final key = '${day.date.year}-${day.date.month.toString().padLeft(2, '0')}';
      byMonth.putIfAbsent(key, () => []);
      byMonth[key]!.add(day);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: byMonth.entries.map((entry) {
        final monthKey = entry.key;
        final days = entry.value;
        final parts = monthKey.split('-');
        final monthName = _getMonthName(int.parse(parts[1]));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$monthName ${parts[0]}',
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildMonthGrid(days, isDark),
            const SizedBox(height: 24),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMonthGrid(List<CalendarDay> days, bool isDark) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: days.map((day) {
        final completed = day.completed;
        final hasActivity = day.minutes > 0;

        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: completed
                ? AppColors.success
                : hasActivity
                    ? AppColors.success.withAlpha(100)
                    : (isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariant),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '${day.date.day}',
              style: AppTypography.labelSmall.copyWith(
                color: completed || hasActivity
                    ? Colors.white
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
                fontSize: 10,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];
    return months[month];
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? null
                : Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelMedium.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return HMCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isDark;
  final bool isLocked;

  const _AchievementCard({
    required this.achievement,
    required this.isDark,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLocked
            ? (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant)
            : (isDark ? AppColors.surfaceDark : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocked
              ? Colors.transparent
              : AppColors.primary.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isLocked
                  ? Colors.grey.withAlpha(50)
                  : AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: TextStyle(
                  fontSize: 24,
                  color: isLocked ? Colors.grey : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: AppTypography.titleMedium.copyWith(
                    color: isLocked
                        ? AppColors.textSecondary
                        : (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
                if (achievement.target != null && !achievement.unlocked) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: achievement.progressPercent,
                    backgroundColor: isDark
                        ? AppColors.borderDark
                        : AppColors.border,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${achievement.progress ?? 0}/${achievement.target}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Status
          if (achievement.unlocked)
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 24,
            ),
        ],
      ),
    );
  }
}

