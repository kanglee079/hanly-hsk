import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/vocab_model.dart';
import '../../../data/models/today_model.dart';

/// Capitalize first letter
String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

/// SRS rating widget for review sessions
class SRSRatingWidget extends StatelessWidget {
  final VocabModel vocab;
  final bool isDark;
  final Function(ReviewRating) onRate;

  const SRSRatingWidget({
    super.key,
    required this.vocab,
    required this.isDark,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Vocab display
            Text(
              vocab.hanzi,
              style: AppTypography.hanziLarge.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontSize: 72,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              vocab.pinyin,
              style: AppTypography.pinyin.copyWith(
                fontSize: 22,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              _capitalize(vocab.meaningVi),
              style: AppTypography.headlineSmall.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Current state info
            if (vocab.state != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStateIcon(vocab.state),
                      size: 18,
                      color: _getStateColor(vocab.state),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      vocab.stateDisplay,
                      style: AppTypography.labelMedium.copyWith(
                        color: _getStateColor(vocab.state),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (vocab.reps != null && vocab.reps! > 0) ...[
                      const SizedBox(width: 12),
                      Text(
                        '• ${vocab.reps} lần ôn',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            
            // Question
            Text(
              'Bạn nhớ từ này như thế nào?',
              style: AppTypography.bodyLarge.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Rating buttons
            Row(
              children: [
                _buildRatingButton(
                  rating: ReviewRating.again,
                  label: 'Quên',
                  subtitle: '<1 phút',
                  color: AppColors.ratingAgain,
                ),
                const SizedBox(width: 8),
                _buildRatingButton(
                  rating: ReviewRating.hard,
                  label: 'Khó',
                  subtitle: '~10 phút',
                  color: AppColors.ratingHard,
                ),
                const SizedBox(width: 8),
                _buildRatingButton(
                  rating: ReviewRating.good,
                  label: 'Ổn',
                  subtitle: '~1 ngày',
                  color: AppColors.ratingGood,
                ),
                const SizedBox(width: 8),
                _buildRatingButton(
                  rating: ReviewRating.easy,
                  label: 'Dễ',
                  subtitle: '~4 ngày',
                  color: AppColors.ratingEasy,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Hint
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Đánh giá trung thực giúp thuật toán SRS hoạt động tốt hơn',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingButton({
    required ReviewRating rating,
    required String label,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onRate(rating);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(80),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withAlpha(200),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStateIcon(String? state) {
    switch (state) {
      case 'new':
        return Icons.fiber_new_rounded;
      case 'learning':
        return Icons.school_rounded;
      case 'review':
        return Icons.refresh_rounded;
      case 'mastered':
        return Icons.verified_rounded;
      default:
        return Icons.fiber_new_rounded;
    }
  }

  Color _getStateColor(String? state) {
    switch (state) {
      case 'new':
        return AppColors.primary;
      case 'learning':
        return AppColors.warning;
      case 'review':
        return AppColors.primary;
      case 'mastered':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}

