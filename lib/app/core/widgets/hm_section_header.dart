import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Unified section header widget used across the app
/// Provides consistent styling for section titles with optional trailing widget and count badge
class HMSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const HMSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.trailing,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget header = Row(
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (count != null && count! > 0) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: AppTypography.labelSmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (trailing != null) trailing!,
        if (onTap != null && trailing == null)
          Icon(
            Icons.chevron_right,
            size: 20,
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
          ),
      ],
    );

    if (onTap != null) {
      header = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: header,
      );
    }

    if (padding != null) {
      return Padding(padding: padding!, child: header);
    }

    return header;
  }
}

/// Compact section header for smaller spaces
class HMSectionHeaderCompact extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const HMSectionHeaderCompact({
    super.key,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Text(
            title,
            style: AppTypography.labelLarge.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
          if (onTap != null && trailing == null)
            Icon(
              Icons.chevron_right,
              size: 18,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
        ],
      ),
    );
  }
}

