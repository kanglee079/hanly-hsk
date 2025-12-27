import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Mini audio player for vocabulary pronunciation
class HMAudioMiniPlayer extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback? onPlayNormal;
  final VoidCallback? onPlaySlow;
  final VoidCallback? onStop;
  final String? label;
  final bool showSlowButton;
  final bool slowAvailable;

  const HMAudioMiniPlayer({
    super.key,
    this.isPlaying = false,
    this.isLoading = false,
    this.onPlayNormal,
    this.onPlaySlow,
    this.onStop,
    this.label,
    this.showSlowButton = true,
    this.slowAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play button
          _AudioButton(
            icon: isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
            isActive: isPlaying,
            isLoading: isLoading && !showSlowButton,
            onTap: isPlaying ? onStop : onPlayNormal,
            label: '1.0x',
            isEnabled: true,
          ),
          if (showSlowButton) ...[
            const SizedBox(width: 8),
            _AudioButton(
              icon: Icons.slow_motion_video_rounded,
              isActive: false,
              isLoading: isLoading,
              onTap: slowAvailable ? onPlaySlow : null,
              label: '0.75x',
              isEnabled: slowAvailable,
            ),
          ],
          if (label != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label!,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AudioButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final bool isLoading;
  final VoidCallback? onTap;
  final String label;
  final bool isEnabled;

  const _AudioButton({
    required this.icon,
    required this.isActive,
    required this.isLoading,
    this.onTap,
    required this.label,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isEnabled 
        ? (isActive ? AppColors.textOnPrimary : AppColors.primary)
        : AppColors.textTertiary;
    
    final bgColor = isActive 
        ? AppColors.primary 
        : (isEnabled ? AppColors.surface : AppColors.surface.withAlpha(100));

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                )
              else
                Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
