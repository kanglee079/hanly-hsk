import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'hm_button.dart';

/// Empty state placeholder
class HMEmptyState extends StatelessWidget {
  /// Material icon (used if iconWidget is null)
  final IconData? icon;
  
  /// SVG path (used if iconWidget is null and svgPath is provided)
  final String? svgPath;
  
  /// Custom icon widget (takes precedence over icon and svgPath)
  final Widget? iconWidget;
  
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HMEmptyState({
    super.key,
    this.icon,
    this.svgPath,
    this.iconWidget,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  }) : assert(icon != null || svgPath != null || iconWidget != null,
            'Either icon, svgPath, or iconWidget must be provided');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: _buildIconContent(isDark),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTypography.headlineSmall.copyWith(
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              HMButton(
                text: actionLabel!,
                onPressed: onAction,
                fullWidth: false,
                size: HMButtonSize.small,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildIconContent(bool isDark) {
    final iconColor = isDark ? AppColors.textTertiaryDark : AppColors.textTertiary;
    
    // Priority: iconWidget > svgPath > icon
    if (iconWidget != null) {
      return iconWidget!;
    }
    
    if (svgPath != null) {
      return SvgPicture.asset(
        svgPath!,
        width: 36,
        height: 36,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      );
    }
    
    return Icon(
      icon,
      size: 36,
      color: iconColor,
    );
  }
}

