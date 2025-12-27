import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Reusable chip widget
class HMChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? selectedBackgroundColor;
  final Color? textColor;
  final Color? selectedTextColor;
  final Widget? icon;
  final bool showCloseIcon;
  final VoidCallback? onClose;

  const HMChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.textColor,
    this.selectedTextColor,
    this.icon,
    this.showCloseIcon = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isSelected
        ? (selectedBackgroundColor ?? AppColors.primarySurface)
        : (backgroundColor ??
            (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant));

    final txtColor = isSelected
        ? (selectedTextColor ?? AppColors.primary)
        : (textColor ??
            (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: AppSpacing.chipHeight,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.chipPaddingH,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppSpacing.borderRadiusFull,
          border: isSelected
              ? Border.all(color: AppColors.primary.withAlpha(51))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.chip.copyWith(color: txtColor),
            ),
            if (showCloseIcon) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClose,
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: txtColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Segmented chips row
class HMSegmentedChips extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int>? onChanged;
  final bool scrollable;

  const HMSegmentedChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    this.onChanged,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final chips = List.generate(
      labels.length,
      (index) => HMChip(
        label: labels[index],
        isSelected: index == selectedIndex,
        onTap: () => onChanged?.call(index),
      ),
    );

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips
              .map((chip) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: chip,
                  ))
              .toList(),
        ),
      );
    }

    return Row(
      children: chips
          .map((chip) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: chip,
              ))
          .toList(),
    );
  }
}

