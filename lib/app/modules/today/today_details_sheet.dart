import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/hm_button.dart';
import '../../core/widgets/hm_progress_ring.dart';
import '../../core/utils/date_format.dart';
import '../../data/models/today_model.dart';

/// Bottom sheet showing today's learning details
class TodayDetailsSheet extends StatelessWidget {
  final TodayModel? data;
  final VoidCallback onStartSession;

  const TodayDetailsSheet({
    super.key,
    required this.data,
    required this.onStartSession,
  });

  /// Show the bottom sheet
  static Future<void> show({
    required TodayModel? data,
    required VoidCallback onStartSession,
  }) async {
    await Get.bottomSheet(
      TodayDetailsSheet(data: data, onStartSession: onStartSession),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Calculate total remaining
    final newCount = data?.newQueue.length ?? 0;
    final reviewCount = data?.reviewQueue.length ?? 0;
    final totalRemaining = newCount + reviewCount;

    // Calculate progress percentage
    final newLearned = data?.newLearned ?? 0;
    final reviewed = data?.reviewed ?? 0;
    final totalDone = newLearned + reviewed;
    final totalItems = totalDone + totalRemaining;
    final progressPercent =
        totalItems > 0 ? (totalDone / totalItems * 100).round() : 0;

    return Container(
      // Limit max height to 90% of screen
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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

          // Header with close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const SizedBox(width: 36), // Balance for close button
                Expanded(
                  child: Text(
                    'Chi tiết hôm nay',
                    textAlign: TextAlign.center,
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

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date
                  Text(
                    DateFormatUtil.formatDayFull(now).toUpperCase(),
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatUtil.formatMonthDay(now),
                    style: AppTypography.headlineMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Progress ring - smaller for better fit
                  HMProgressRing(
                    progress: progressPercent / 100,
                    size: 140,
                    strokeWidth: 12,
                    backgroundColor: isDark
                        ? AppColors.surfaceVariantDark
                        : const Color(0xFFE2E8F0),
                    centerWidget: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$progressPercent%',
                          style: AppTypography.displaySmall.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Hoàn thành',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Remaining text
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                      children: [
                        const TextSpan(text: 'Bạn còn '),
                        TextSpan(
                          text: '$totalRemaining mục',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ' cần học trong hôm nay.'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2x2 Grid of cards
                  Row(
                    children: [
                      Expanded(
                        child: _DetailCard(
                          icon: Icons.auto_awesome,
                          iconColor: AppColors.primary,
                          value: '$newCount',
                          title: 'Từ mới',
                          subtitle: 'Học từ mới',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DetailCard(
                          icon: Icons.history,
                          iconColor: AppColors.error,
                          value: '$reviewCount',
                          title: 'Ôn tập',
                          subtitle: 'Ôn tập',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DetailCard(
                          icon: Icons.headphones,
                          iconColor: AppColors.hsk2,
                          value: '${(newCount * 0.5).round()}',
                          title: 'Luyện nghe',
                          subtitle: 'Listening',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DetailCard(
                          icon: Icons.edit,
                          iconColor: AppColors.success,
                          value: '${(newCount * 0.2).round()}',
                          title: 'Tập viết',
                          subtitle: 'Tập viết Hanzi',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Quick Adjustments header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Điều chỉnh nhanh',
                        style: AppTypography.titleSmall.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Reset adjustments
                        },
                        child: Text(
                          'Đặt lại',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Fixed bottom button
          Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 16),
            child: HMButton(
              text: 'Bắt đầu học',
              icon: const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
              iconRight: true,
              onPressed: () {
                Get.back();
                onStartSession();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String title;
  final String subtitle;
  final bool isDark;

  const _DetailCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const Spacer(),
              Text(
                value,
                style: AppTypography.headlineSmall.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.labelSmall.copyWith(
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
