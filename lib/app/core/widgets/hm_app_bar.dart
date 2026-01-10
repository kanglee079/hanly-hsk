import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Custom app bar with consistent styling
class HMAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;

  const HMAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: AppTypography.headlineSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                )
              : null),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ??
          (isDark ? AppColors.backgroundDark : AppColors.background),
      elevation: elevation,
      leading: leading ??
          (showBackButton && canPop ? HMBackButton(onPressed: onBackPressed) : null),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Unified back button for consistent styling across the app
/// Use this widget for all back buttons
class HMBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final bool showBackground;

  const HMBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.size = 40,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);

    return Center(
      child: GestureDetector(
        onTap: onPressed ?? () => Get.back(),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          margin: const EdgeInsets.only(left: 8),
          decoration: showBackground
              ? BoxDecoration(
                  color: (isDark ? AppColors.surfaceDark : AppColors.surface)
                      .withAlpha(200),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: 1,
                  ),
                )
              : null,
          child: Center(
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: iconColor,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating back button for use on top of content (e.g., detail screens)
class HMFloatingBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const HMFloatingBackButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      child: GestureDetector(
        onTap: onPressed ?? () => Get.back(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.backgroundDark : AppColors.background)
                .withAlpha(230),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 40 : 15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            size: 18,
          ),
        ),
      ),
    );
  }
}
