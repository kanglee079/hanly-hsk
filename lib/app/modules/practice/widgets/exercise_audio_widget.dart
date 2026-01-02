import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/hm_button.dart';
import '../../../data/models/exercise_model.dart';

/// Capitalize first letter
String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

/// Audio-based exercise widget (Audio → Hanzi or Audio → Meaning)
class ExerciseAudioWidget extends StatefulWidget {
  final Exercise exercise;
  final bool isDark;
  final int selectedAnswer;
  final bool hasAnswered;
  final bool isCorrect;
  final bool isPlaying;
  final bool hasPlayed;
  final Function(int) onSelectAnswer;
  final VoidCallback onPlayAudio;
  final VoidCallback? onPlaySlow;
  final VoidCallback onContinue;

  const ExerciseAudioWidget({
    super.key,
    required this.exercise,
    required this.isDark,
    required this.selectedAnswer,
    required this.hasAnswered,
    required this.isCorrect,
    required this.isPlaying,
    required this.hasPlayed,
    required this.onSelectAnswer,
    required this.onPlayAudio,
    this.onPlaySlow,
    required this.onContinue,
  });

  @override
  State<ExerciseAudioWidget> createState() => _ExerciseAudioWidgetState();
}

class _ExerciseAudioWidgetState extends State<ExerciseAudioWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late List<Animation<double>> _optionAnimations;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Create staggered animations for each option
    final optionCount = widget.exercise.options.length;
    _optionAnimations = List.generate(optionCount, (index) {
      final start = index * 0.15;
      final end = start + 0.4;
      return CurvedAnimation(
        parent: _entryController,
        curve: Interval(
          start.clamp(0.0, 1.0),
          end.clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );
    });

    // Start entry animation
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Main content area - takes all available space
          Expanded(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Audio controls
                  _buildAudioSection(),

                  const SizedBox(height: 12),

                  // Question text
                  Text(
                    widget.exercise.type == ExerciseType.audioToHanzi
                        ? 'Chọn chữ Hán đúng:'
                        : 'Chọn nghĩa đúng:',
                    style: AppTypography.bodyLarge.copyWith(
                      color: widget.isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Options - uses Flexible to scale to available space
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final optionCount = widget.exercise.options.length;
                        final availableHeight = constraints.maxHeight;
                        final maxOptionHeight =
                            (availableHeight / optionCount) - 8;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: _buildOptions(
                            maxOptionHeight.clamp(50.0, 70.0),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom section - ANIMATED: 0 height before answer, expands after
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    // Only render content when answered to avoid layout issues during animation
    if (!widget.hasAnswered) {
      return const SizedBox.shrink();
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: AppSpacing.screenPadding.copyWith(top: 12, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Inline feedback message
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isCorrect
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: widget.isCorrect ? AppColors.success : AppColors.error,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isCorrect ? 'Chính xác!' : 'Chưa đúng',
                  style: AppTypography.titleSmall.copyWith(
                    color: widget.isCorrect
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Continue button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: HMButton(
                text: 'Tiếp tục',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onContinue();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSection() {
    return Column(
      children: [
        // Main audio button - FIXED SIZE to prevent jitter
        GestureDetector(
          onTap: widget.onPlayAudio,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primary.withAlpha(200)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(
                    widget.isPlaying ? 120 : 40,
                  ),
                  blurRadius: widget.isPlaying ? 25 : 15,
                  spreadRadius: 0, // Fixed - no spread change to prevent jitter
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                widget.isPlaying
                    ? Icons.volume_up_rounded
                    : Icons.play_arrow_rounded,
                key: ValueKey(widget.isPlaying),
                size: 36,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Audio hint
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: !widget.hasPlayed
              ? Text(
                  '👆 Nhấn để nghe',
                  key: const ValueKey('hint'),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : Text(
                  'Nhấn lại để nghe',
                  key: const ValueKey('replay'),
                  style: AppTypography.bodySmall.copyWith(
                    color: widget.isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiary,
                  ),
                ),
        ),

        const SizedBox(height: 12),

        // Slow playback button
        if (widget.onPlaySlow != null)
          GestureDetector(
            onTap: widget.onPlaySlow,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isDark
                      ? AppColors.borderDark
                      : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.slow_motion_video_rounded,
                    size: 18,
                    color: widget.isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nghe chậm',
                    style: AppTypography.labelMedium.copyWith(
                      color: widget.isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildOptions(double maxHeight) {
    return List.generate(widget.exercise.options.length, (index) {
      final option = widget.exercise.options[index];
      final isSelected = widget.selectedAnswer == index;
      final isCorrectOption = index == widget.exercise.correctIndex;

      Color? bgColor;
      Color? borderColor;
      Color textColor = widget.isDark
          ? AppColors.textPrimaryDark
          : AppColors.textPrimary;

      if (widget.hasAnswered) {
        if (isCorrectOption) {
          bgColor = AppColors.success.withAlpha(30);
          borderColor = AppColors.success;
          textColor = AppColors.success;
        } else if (isSelected) {
          bgColor = AppColors.error.withAlpha(30);
          borderColor = AppColors.error;
          textColor = AppColors.error;
        }
      } else if (isSelected) {
        borderColor = AppColors.primary;
        bgColor = AppColors.primary.withAlpha(15);
      }

      // Determine if this is a Hanzi or meaning option
      final isHanziOption = widget.exercise.type == ExerciseType.audioToHanzi;

      return AnimatedBuilder(
        animation: _optionAnimations[index],
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - _optionAnimations[index].value)),
            child: Opacity(
              opacity: _optionAnimations[index].value,
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: GestureDetector(
            onTap: widget.hasAnswered
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    widget.onSelectAnswer(index);
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isHanziOption ? 20 : 16,
              ),
              decoration: BoxDecoration(
                color:
                    bgColor ??
                    (widget.isDark ? AppColors.surfaceDark : AppColors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      borderColor ??
                      (widget.isDark ? AppColors.borderDark : AppColors.border),
                  width: isSelected || (widget.hasAnswered && isCorrectOption)
                      ? 2
                      : 1,
                ),
              ),
              child: Row(
                children: [
                  // Option letter
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withAlpha(30)
                          : (widget.isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.surfaceVariant),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index),
                        style: AppTypography.titleSmall.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : (widget.isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Option text
                  Expanded(
                    child: Text(
                      isHanziOption ? option : _capitalize(option),
                      style: isHanziOption
                          ? AppTypography.hanziSmall.copyWith(
                              fontSize: 24,
                              color: textColor,
                            )
                          : AppTypography.bodyLarge.copyWith(color: textColor),
                      textAlign: isHanziOption
                          ? TextAlign.center
                          : TextAlign.left,
                    ),
                  ),

                  // Result icon with elastic animation
                  if (widget.hasAnswered) ...[
                    if (isCorrectOption)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(scale: value, child: child);
                        },
                        child: const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 24,
                        ),
                      )
                    else if (isSelected)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.scale(scale: value, child: child);
                        },
                        child: const Icon(
                          Icons.cancel,
                          color: AppColors.error,
                          size: 24,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
