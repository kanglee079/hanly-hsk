import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../routes/app_routes.dart';

/// Premium upsell bottom sheet - shown when user hits premium limits
///
/// Features:
/// - Displays feature-specific message
/// - Shows current usage limits
/// - CTA to go to premium screen
/// - Smooth animations
class PremiumUpsellSheet extends StatelessWidget {
  final String? feature;
  final String message;
  final int? limit;
  final int? used;
  final int? remaining;

  const PremiumUpsellSheet({
    super.key,
    this.feature,
    required this.message,
    this.limit,
    this.used,
    this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Crown icon with animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.orange.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    size: 44,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                _getTitle(),
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Usage info
              if (limit != null && used != null) ...[
                const SizedBox(height: 20),
                _buildUsageInfo(context),
              ],

              const SizedBox(height: 28),

              // Premium benefits
              _buildBenefits(context),

              const SizedBox(height: 28),

              // CTA button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.toNamed(Routes.premium);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Nâng cấp Premium',
                        style: AppTypography.button.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Maybe later button
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Để sau',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (feature) {
      case 'flashcards':
        return 'Đã hết lượt ôn tập';
      case 'game':
        return 'Đã hết lượt chơi game';
      case 'exam':
        return 'Đã hết lượt thi thử';
      case 'comprehensive':
        return 'Ôn tập tổng hợp';
      default:
        return 'Nâng cấp Premium';
    }
  }

  Widget _buildUsageInfo(BuildContext context) {
    final usedCount = used ?? 0;
    final limitCount = limit ?? 0;
    final progress = limitCount > 0
        ? (usedCount / limitCount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red.shade400,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đã sử dụng $usedCount/$limitCount lượt hôm nay',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.red.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.red.shade400,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefits(BuildContext context) {
    final benefits = [
      ('Ôn tập không giới hạn', Icons.all_inclusive_rounded),
      ('Tất cả đề thi HSK', Icons.quiz_rounded),
      ('Không quảng cáo', Icons.block_rounded),
      ('Bảo vệ streak', Icons.local_fire_department_rounded),
    ];

    return Column(
      children: benefits.map((benefit) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(benefit.$2, size: 16, color: Colors.green.shade600),
              ),
              const SizedBox(width: 12),
              Text(
                benefit.$1,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
