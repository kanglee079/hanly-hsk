import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../services/tutorial_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Global wrapper for ShowcaseView functionality
/// Wrap each screen with this to enable tutorial showcases
class AppShowcaseWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onFinish;
  final VoidCallback? onStart;
  final bool autoPlay;
  final Duration autoPlayDelay;

  const AppShowcaseWrapper({
    super.key,
    required this.child,
    this.onFinish,
    this.onStart,
    this.autoPlay = false,
    this.autoPlayDelay = const Duration(seconds: 3),
  });

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onFinish: () {
        onFinish?.call();
      },
      onStart: (_, __) {
        onStart?.call();
      },
      autoPlay: autoPlay,
      autoPlayDelay: autoPlayDelay,
      blurValue: 0,
      enableAutoScroll: true,
      builder: (context) => child,
    );
  }
}

/// Custom tooltip widget matching app design
class AppShowcaseTooltip extends StatelessWidget {
  final String title;
  final String description;
  final String? emoji;
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final bool isLast;

  const AppShowcaseTooltip({
    super.key,
    required this.title,
    required this.description,
    this.emoji,
    required this.currentStep,
    required this.totalSteps,
    this.onNext,
    this.onSkip,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          Row(
            children: [
              if (emoji != null) ...[
                Text(emoji!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: LinearProgressIndicator(
                  value: currentStep / totalSteps,
                  backgroundColor: isDark
                      ? AppColors.borderDark
                      : AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$currentStep/$totalSteps',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            description,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isLast)
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Bỏ qua',
                    style: AppTypography.button.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Text(
                  isLast ? 'Hoàn tất' : 'Tiếp theo',
                  style: AppTypography.button,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Extension to easily start showcase from any context
extension ShowcaseExtension on BuildContext {
  void startShowcase(List<GlobalKey> keys) {
    ShowCaseWidget.of(this).startShowCase(keys);
  }

  void dismissShowcase() {
    ShowCaseWidget.of(this).dismiss();
  }

  void nextShowcase() {
    ShowCaseWidget.of(this).next();
  }

  void previousShowcase() {
    ShowCaseWidget.of(this).previous();
  }
}

/// Helper class to build Showcase widgets with consistent styling
class ShowcaseHelper {
  static Widget buildShowcase({
    required GlobalKey key,
    required Widget child,
    required String title,
    required String description,
    String? emoji,
    int currentStep = 1,
    int totalSteps = 1,
    bool isLast = false,
    VoidCallback? onNext,
    VoidCallback? onSkip,
    ShapeBorder? targetShapeBorder,
    EdgeInsets targetPadding = const EdgeInsets.all(8),
    bool disposeOnTap = false,
    bool disableDefaultTargetGestures = false,
  }) {
    return Showcase.withWidget(
      key: key,
      height: 250,
      width: 300,
      targetShapeBorder:
          targetShapeBorder ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      targetPadding: targetPadding,
      overlayOpacity: 0.7,
      disposeOnTap: disposeOnTap,
      disableDefaultTargetGestures: disableDefaultTargetGestures,
      container: AppShowcaseTooltip(
        title: title,
        description: description,
        emoji: emoji,
        currentStep: currentStep,
        totalSteps: totalSteps,
        isLast: isLast,
        onNext: onNext,
        onSkip: onSkip,
      ),
      child: child,
    );
  }
}
