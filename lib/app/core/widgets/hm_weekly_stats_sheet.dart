import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/today_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../utils/logger.dart';

/// Weekly stats bottom sheet - shows detailed weekly learning stats
class HMWeeklyStatsSheet extends StatelessWidget {
  final List<DayProgress> weeklyProgress;
  final bool isDark;

  const HMWeeklyStatsSheet({
    super.key,
    required this.weeklyProgress,
    this.isDark = false,
  });

  /// Show the bottom sheet
  static void show({
    required List<DayProgress> weeklyProgress,
  }) {
    // Debug log to see raw data
    Logger.d('HMWeeklyStatsSheet', 'weeklyProgress data:');
    for (final day in weeklyProgress) {
      Logger.d('HMWeeklyStatsSheet', 
        '  ${day.date}: minutes=${day.minutes}, newCount=${day.newCount}, '
        'reviewCount=${day.reviewCount}, accuracy=${day.accuracy}');
    }
    
    final isDark = Get.isDarkMode;
    Get.bottomSheet(
      HMWeeklyStatsSheet(
        weeklyProgress: weeklyProgress,
        isDark: isDark,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // Calculate stats
  int get totalNewCount => weeklyProgress.fold(0, (sum, day) => sum + day.newCount);
  int get totalReviewCount => weeklyProgress.fold(0, (sum, day) => sum + day.reviewCount);
  int get totalMinutes => weeklyProgress.fold(0, (sum, day) => sum + day.minutes);
  int get avgAccuracy {
    final daysWithActivity = weeklyProgress.where((d) => d.minutes > 0).toList();
    if (daysWithActivity.isEmpty) return 0;
    return daysWithActivity.fold(0, (sum, day) => sum + day.accuracy) ~/ daysWithActivity.length;
  }
  int get activeDays => weeklyProgress.where((d) => d.minutes > 0).length;
  int get maxMinutes => weeklyProgress.map((e) => e.minutes).fold(0, (a, b) => a > b ? a : b);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thống kê tuần này',
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$activeDays ngày hoạt động',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary cards
                  _buildSummaryCards(),
                  
                  const SizedBox(height: 24),
                  
                  // Daily breakdown
                  Text(
                    'Chi tiết từng ngày',
                    style: AppTypography.titleSmall.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Day list
                  ...weeklyProgress.reversed.map((day) => _buildDayRow(day)),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
              ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
              : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
        ),
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.auto_stories,
                  value: '$totalNewCount',
                  label: 'Từ mới',
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.refresh,
                  value: '$totalReviewCount',
                  label: 'Ôn tập',
                  color: AppColors.secondary,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.timer_outlined,
                  value: '${totalMinutes}p',
                  label: 'Tổng thời gian',
                  color: AppColors.streak,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.gps_fixed,
                  value: '$avgAccuracy%',
                  label: 'Độ chính xác',
                  color: avgAccuracy >= 80 ? AppColors.success : AppColors.warning,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow(DayProgress day) {
    final hasActivity = day.minutes > 0;
    final isToday = day.isToday;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday
            ? (isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.08))
            : (isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8FAFC)),
        borderRadius: AppSpacing.borderRadiusMd,
        border: isToday 
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) 
            : null,
      ),
      child: Row(
        children: [
          // Day name & date
          SizedBox(
            width: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      day.dayLabel,
                      style: AppTypography.labelLarge.copyWith(
                        color: isToday 
                            ? AppColors.primary 
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  _formatDate(day.date),
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          
          // Progress bar
          Expanded(
            child: Container(
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: maxMinutes > 0 ? day.minutes / maxMinutes : 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: hasActivity
                        ? LinearGradient(
                            colors: isToday
                                ? [AppColors.primary, const Color(0xFF818CF8)]
                                : [AppColors.success, const Color(0xFF34D399)],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          
          // Stats
          SizedBox(
            width: 100,
            child: hasActivity
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _MiniStat(
                        value: '${day.minutes}p',
                        color: AppColors.primary,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _MiniStat(
                        value: '+${day.newCount}',
                        color: AppColors.success,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _MiniStat(
                        value: '${day.accuracy}%',
                        color: day.accuracy >= 80 ? AppColors.success : AppColors.warning,
                        isDark: isDark,
                      ),
                    ],
                  )
                : Text(
                    'Chưa học',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    fontSize: 10,
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

class _MiniStat extends StatelessWidget {
  final String value;
  final Color color;
  final bool isDark;

  const _MiniStat({
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: AppTypography.labelSmall.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
    );
  }
}

