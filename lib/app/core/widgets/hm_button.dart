import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/app_shadows.dart';

enum HMButtonVariant { primary, secondary, outline, text, danger }
enum HMButtonSize { small, medium, large }

/// Reusable button with variants
class HMButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final HMButtonVariant variant;
  final HMButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final Widget? icon;
  final bool iconRight;
  final bool fullWidth;

  const HMButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = HMButtonVariant.primary,
    this.size = HMButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.iconRight = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = !isDisabled && !isLoading && onPressed != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
        decoration: variant == HMButtonVariant.primary && enabled
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(_getRadius()),
                boxShadow: AppShadows.button,
              )
            : null,
        child: SizedBox(
          width: fullWidth ? double.infinity : null,
          height: _getHeight(),
          child: _buildButton(context, isDark, enabled),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, bool isDark, bool enabled) {
    final buttonStyle = _getButtonStyle(isDark, enabled);

    Widget child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(_getLoadingColor(isDark)),
            ),
          )
        : _buildContent(isDark, enabled);

    switch (variant) {
      case HMButtonVariant.primary:
      case HMButtonVariant.secondary:
      case HMButtonVariant.danger:
        return ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: buttonStyle,
          child: child,
        );
      case HMButtonVariant.outline:
        return OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: buttonStyle,
          child: child,
        );
      case HMButtonVariant.text:
        return TextButton(
          onPressed: enabled ? onPressed : null,
          style: buttonStyle,
          child: child,
        );
    }
  }

  Widget _buildContent(bool isDark, bool enabled) {
    final textStyle = _getTextStyle().copyWith(
      color: _getTextColor(isDark, enabled),
    );

    if (icon == null) {
      return Text(text, style: textStyle);
    }

    final children = [
      icon!,
      const SizedBox(width: 8),
      Text(text, style: textStyle),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: iconRight ? children.reversed.toList() : children,
    );
  }

  Color _getTextColor(bool isDark, bool enabled) {
    if (!enabled) {
      // For disabled state, still keep text visible
      switch (variant) {
        case HMButtonVariant.primary:
        case HMButtonVariant.danger:
          return AppColors.textOnPrimary;
        case HMButtonVariant.secondary:
          return isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
        case HMButtonVariant.outline:
        case HMButtonVariant.text:
          return isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
      }
    }

    switch (variant) {
      case HMButtonVariant.primary:
      case HMButtonVariant.danger:
        return AppColors.textOnPrimary;
      case HMButtonVariant.secondary:
        return isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
      case HMButtonVariant.outline:
      case HMButtonVariant.text:
        return AppColors.primary;
    }
  }

  ButtonStyle _getButtonStyle(bool isDark, bool enabled) {
    Color bgColor;
    Color fgColor;
    BorderSide? border;

    switch (variant) {
      case HMButtonVariant.primary:
        bgColor = enabled ? AppColors.primary : AppColors.primary.withAlpha(180);
        fgColor = AppColors.textOnPrimary;
        break;
      case HMButtonVariant.secondary:
        bgColor = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
        fgColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
        break;
      case HMButtonVariant.outline:
        bgColor = Colors.transparent;
        fgColor = enabled ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary);
        border = BorderSide(
          color: enabled 
              ? AppColors.primary 
              : (isDark ? AppColors.borderDark : AppColors.border),
          width: 1.5,
        );
        break;
      case HMButtonVariant.text:
        bgColor = Colors.transparent;
        fgColor = AppColors.primary;
        break;
      case HMButtonVariant.danger:
        bgColor = enabled ? AppColors.error : AppColors.error.withAlpha(180);
        fgColor = AppColors.textOnPrimary;
        break;
    }

    return ButtonStyle(
      backgroundColor: WidgetStateProperty.all(bgColor),
      foregroundColor: WidgetStateProperty.all(fgColor),
      elevation: WidgetStateProperty.all(0),
      padding: WidgetStateProperty.all(_getPadding()),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getRadius()),
          side: border ?? BorderSide.none,
        ),
      ),
    );
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case HMButtonSize.small:
        return AppTypography.buttonSmall;
      case HMButtonSize.medium:
      case HMButtonSize.large:
        return AppTypography.button;
    }
  }

  double _getHeight() {
    switch (size) {
      case HMButtonSize.small:
        return AppSpacing.buttonHeightSmall;
      case HMButtonSize.medium:
        return AppSpacing.buttonHeight;
      case HMButtonSize.large:
        return AppSpacing.buttonHeightLarge;
    }
  }

  double _getRadius() {
    switch (size) {
      case HMButtonSize.small:
        return AppSpacing.radiusSm;
      case HMButtonSize.medium:
        return AppSpacing.radiusMd;
      case HMButtonSize.large:
        return AppSpacing.radiusLg;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case HMButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case HMButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case HMButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  Color _getLoadingColor(bool isDark) {
    switch (variant) {
      case HMButtonVariant.primary:
      case HMButtonVariant.danger:
        return AppColors.textOnPrimary;
      case HMButtonVariant.secondary:
        return isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
      case HMButtonVariant.outline:
      case HMButtonVariant.text:
        return AppColors.primary;
    }
  }
}
