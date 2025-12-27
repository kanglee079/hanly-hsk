import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/next_action_engine.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Next Action CTA Card
/// Single prominent button showing user what to do next
class HMNextActionCard extends StatelessWidget {
  final RecommendedAction action;
  final VoidCallback onTap;
  final bool isCompact;

  const HMNextActionCard({
    super.key,
    required this.action,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isCompact ? 16 : 20),
        decoration: BoxDecoration(
          gradient: _getGradient(),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: _getPrimaryColor().withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon only (removed ETA badge)
            Container(
              width: isCompact ? 40 : 48,
              height: isCompact ? 40 : 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  action.icon,
                  style: TextStyle(fontSize: isCompact ? 20 : 24),
                ),
              ),
            ),
            
            SizedBox(height: isCompact ? 12 : 16),
            
            // Title
            Text(
              action.title,
              style: (isCompact ? AppTypography.titleMedium : AppTypography.titleLarge).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Subtitle
            Text(
              action.subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            
            SizedBox(height: isCompact ? 16 : 20),
            
            // CTA Button
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isCompact ? 12 : 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    action.primaryButtonText,
                    style: AppTypography.labelLarge.copyWith(
                      color: _getPrimaryColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: _getPrimaryColor(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPrimaryColor() {
    switch (action.priority) {
      case ActionPriority.critical:
        return const Color(0xFFFF6B6B);
      case ActionPriority.high:
        return AppColors.primary;
      case ActionPriority.medium:
        return const Color(0xFF4ECDC4);
      case ActionPriority.low:
        return const Color(0xFF95E1D3);
    }
  }

  LinearGradient _getGradient() {
    switch (action.priority) {
      case ActionPriority.critical:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B6B),
            Color(0xFFFF8E53),
          ],
        );
      case ActionPriority.high:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        );
      case ActionPriority.medium:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4ECDC4),
            Color(0xFF44A08D),
          ],
        );
      case ActionPriority.low:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF95E1D3),
            Color(0xFF4ECDC4),
          ],
        );
    }
  }
}

