import 'package:flutter/material.dart';
import '../../data/models/dashboard_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Forecast widget showing upcoming review counts
class HMForecastWidget extends StatelessWidget {
  final List<ForecastDay> days;
  final int tomorrowCount;
  final bool isLoading;

  const HMForecastWidget({
    super.key,
    required this.days,
    required this.tomorrowCount,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildSkeleton();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dự báo ôn tập',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Số từ cần ôn trong 7 ngày tới',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Tomorrow highlight
          if (tomorrowCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Text('📅', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        children: [
                          const TextSpan(text: 'Ngày mai: '),
                          TextSpan(
                            text: '$tomorrowCount từ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                          const TextSpan(text: ' cần ôn'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // 7-day chart
          if (days.isNotEmpty) _buildChart(),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final maxCount = days.map((d) => d.reviewCount).reduce((a, b) => a > b ? a : b);
    final normalizedMax = maxCount > 0 ? maxCount : 1;
    
    // Fixed heights for layout
    const double countLabelHeight = 14.0;
    const double barMaxHeight = 28.0;
    const double barMinHeight = 4.0;
    const double dayLabelHeight = 12.0;
    const double spacing = 2.0;
    const double totalHeight = countLabelHeight + barMaxHeight + dayLabelHeight + spacing * 2;

    return SizedBox(
      height: totalHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value;
          final barHeight = day.reviewCount > 0 
              ? (day.reviewCount / normalizedMax) * (barMaxHeight - barMinHeight) + barMinHeight
              : barMinHeight;
          final date = DateTime.tryParse(day.dateKey);
          final dayName = _getDayName(date);

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 2,
                right: index == days.length - 1 ? 0 : 2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Count label - fixed height
                  SizedBox(
                    height: countLabelHeight,
                    child: day.reviewCount > 0
                        ? Text(
                            '${day.reviewCount}',
                            style: AppTypography.labelSmall.copyWith(
                              color: index == 0 ? AppColors.warning : AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: index == 0 ? FontWeight.w600 : FontWeight.normal,
                            ),
                          )
                        : null,
                  ),
                  SizedBox(height: spacing),
                  // Bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? AppColors.warning
                          : (day.reviewCount > 0 
                              ? AppColors.primary.withValues(alpha: 0.6)
                              : AppColors.border),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  SizedBox(height: spacing),
                  // Day label - fixed height
                  SizedBox(
                    height: dayLabelHeight,
                    child: Text(
                      dayName,
                      style: AppTypography.labelSmall.copyWith(
                        color: index == 0 ? AppColors.warning : AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: index == 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  /// Get Vietnamese day name (T2, T3, T4, T5, T6, T7, CN)
  String _getDayName(DateTime? date) {
    if (date == null) return '';
    const dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return dayNames[(date.weekday - 1) % 7];
  }

  Widget _buildSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
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
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 150,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

