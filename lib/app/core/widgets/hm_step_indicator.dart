import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Step indicator for multi-step flows
class HMStepIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep; // 1-indexed
  final List<String>? stepLabels;

  const HMStepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(totalSteps, (index) {
            final stepNum = index + 1;
            final isCompleted = stepNum < currentStep;
            final isCurrent = stepNum == currentStep;

            return Expanded(
              child: Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted || isCurrent
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.border),
                      ),
                    ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppColors.primary
                          : isCurrent
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.surfaceVariantDark
                                  : AppColors.surfaceVariant),
                      border: isCurrent && !isCompleted
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.textOnPrimary,
                              size: 16,
                            )
                          : Text(
                              stepNum.toString(),
                              style: AppTypography.labelMedium.copyWith(
                                color: isCurrent
                                    ? AppColors.textOnPrimary
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary),
                              ),
                            ),
                    ),
                  ),
                  if (index < totalSteps - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.border),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        if (stepLabels != null && stepLabels!.length == totalSteps) ...[
          const SizedBox(height: 8),
          Row(
            children: List.generate(totalSteps, (index) {
              final stepNum = index + 1;
              final isCurrent = stepNum == currentStep;
              final isCompleted = stepNum < currentStep;

              return Expanded(
                child: Text(
                  stepLabels![index],
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSmall.copyWith(
                    color: isCurrent || isCompleted
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary),
                    fontWeight:
                        isCurrent ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

/// Linear step indicator (progress bar style)
class HMLinearStepIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const HMLinearStepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = currentStep / totalSteps;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bước $currentStep/$totalSteps',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: AppTypography.labelMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor:
                isDark ? AppColors.surfaceVariantDark : AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

