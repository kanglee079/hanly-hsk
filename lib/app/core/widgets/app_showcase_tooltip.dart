import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Beautiful custom tooltip for Showcase tutorials
/// Features:
/// - Glassmorphism effect with blur
/// - Gradient accent bar
/// - Emoji support
/// - Step indicator
/// - Smooth animations
class AppShowcaseTooltip extends StatelessWidget {
  final String title;
  final String description;
  final String? emoji;
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;

  const AppShowcaseTooltip({
    super.key,
    required this.title,
    required this.description,
    this.emoji,
    this.currentStep = 1,
    this.totalSteps = 1,
    this.onNext,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.06),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.95),
                      Colors.white.withValues(alpha: 0.85),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient accent bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.6),
                      Colors.purple.withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with emoji and step indicator
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Emoji badge
                        if (emoji != null)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.2),
                                  AppColors.primary.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              emoji!,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),

                        if (emoji != null) const SizedBox(width: 14),

                        // Title and step indicator
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTypography.titleMedium.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Step indicator
                              Row(
                                children: [
                                  for (int i = 0; i < totalSteps; i++)
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      width: i == currentStep - 1 ? 20 : 8,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: i == currentStep - 1
                                            ? AppColors.primary
                                            : (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.2,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.1,
                                                    )),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Description
                    Text(
                      description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.85)
                            : AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Action buttons
                    Row(
                      children: [
                        // Skip button
                        if (onSkip != null)
                          TextButton(
                            onPressed: onSkip,
                            style: TextButton.styleFrom(
                              foregroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : AppColors.textTertiary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            child: Text(
                              'Bỏ qua',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        const Spacer(),

                        // Next/Done button
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onNext,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      currentStep == totalSteps
                                          ? 'Hoàn tất'
                                          : 'Tiếp',
                                      style: AppTypography.labelMedium.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (currentStep < totalSteps) ...[
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple Showcase description widget builder for use with tooltipBuilder
Widget buildShowcaseTooltip({
  required BuildContext context,
  required String title,
  required String description,
  String? emoji,
  int currentStep = 1,
  int totalSteps = 1,
}) {
  return AppShowcaseTooltip(
    title: title,
    description: description,
    emoji: emoji,
    currentStep: currentStep,
    totalSteps: totalSteps,
  );
}
