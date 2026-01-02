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

/// Multiple choice question widget with inline feedback and smooth animations
class ExerciseMCQWidget extends StatefulWidget {
  final Exercise exercise;
  final bool isDark;
  final int selectedAnswer;
  final bool hasAnswered;
  final bool isCorrect;
  final Function(int) onSelectAnswer;
  final VoidCallback? onPlayAudio;
  final VoidCallback onContinue;

  const ExerciseMCQWidget({
    super.key,
    required this.exercise,
    required this.isDark,
    required this.selectedAnswer,
    required this.hasAnswered,
    required this.isCorrect,
    required this.onSelectAnswer,
    this.onPlayAudio,
    required this.onContinue,
  });

  @override
  State<ExerciseMCQWidget> createState() => _ExerciseMCQWidgetState();
}

class _ExerciseMCQWidgetState extends State<ExerciseMCQWidget>
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
          // Main content area (question + options) - takes all available space
          Expanded(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Question (compact)
                  _buildQuestion(),

                  const SizedBox(height: 16),

                  // Options - uses Flexible to scale to available space
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final optionCount = widget.exercise.options.length;
                        // Calculate max height per option based on available space
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

  Widget _buildQuestion() {
    switch (widget.exercise.type) {
      case ExerciseType.hanziToMeaning:
      case ExerciseType.hanziToPinyin:
        return _buildHanziQuestion();
      case ExerciseType.meaningToHanzi:
        return _buildMeaningQuestion();
      case ExerciseType.fillBlank:
        return _buildFillBlankQuestion();
      default:
        return _buildHanziQuestion();
    }
  }

  Widget _buildHanziQuestion() {
    return Column(
      children: [
        // Hanzi
        Text(
          widget.exercise.questionHanzi ?? '',
          style: AppTypography.hanziLarge.copyWith(
            color: widget.isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimary,
          ),
        ),

        // Pinyin (optional hint)
        if (widget.exercise.type == ExerciseType.hanziToMeaning &&
            widget.exercise.questionPinyin != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.exercise.questionPinyin!,
            style: AppTypography.pinyin.copyWith(
              fontSize: 18,
              color: widget.isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiary,
            ),
          ),
        ],

        // Audio button
        if (widget.exercise.questionAudioUrl != null &&
            widget.onPlayAudio != null) ...[
          const SizedBox(height: 16),
          _buildAudioButton(),
        ],

        // Question text
        const SizedBox(height: 24),
        Text(
          _getQuestionText(),
          style: AppTypography.bodyLarge.copyWith(
            color: widget.isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMeaningQuestion() {
    return Column(
      children: [
        // Meaning
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _capitalize(widget.exercise.questionMeaning ?? ''),
            style: AppTypography.headlineMedium.copyWith(
              color: widget.isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 24),
        Text(
          'Chọn chữ Hán đúng:',
          style: AppTypography.bodyLarge.copyWith(
            color: widget.isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFillBlankQuestion() {
    return Column(
      children: [
        // Sentence with blank
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            widget.exercise.questionSentence ?? '',
            style: AppTypography.titleLarge.copyWith(
              color: widget.isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Translation
        if (widget.exercise.questionMeaning != null) ...[
          const SizedBox(height: 12),
          Text(
            _capitalize(widget.exercise.questionMeaning!),
            style: AppTypography.bodyMedium.copyWith(
              color: widget.isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: 24),
        Text(
          'Điền từ phù hợp:',
          style: AppTypography.bodyLarge.copyWith(
            color: widget.isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioButton() {
    return GestureDetector(
      onTap: widget.onPlayAudio,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.volume_up_rounded,
          color: AppColors.primary,
          size: 28,
        ),
      ),
    );
  }

  String _getQuestionText() {
    switch (widget.exercise.type) {
      case ExerciseType.hanziToMeaning:
        return 'Chọn nghĩa đúng:';
      case ExerciseType.hanziToPinyin:
        return 'Chọn pinyin đúng:';
      case ExerciseType.meaningToHanzi:
        return 'Chọn chữ Hán đúng:';
      case ExerciseType.fillBlank:
        return 'Điền từ phù hợp:';
      default:
        return 'Chọn đáp án đúng:';
    }
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
              constraints: BoxConstraints(maxHeight: maxHeight),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                boxShadow: isSelected && !widget.hasAnswered
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(30),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
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
                        String.fromCharCode(65 + index), // A, B, C, D
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
                      _formatOption(option),
                      style: _getOptionTextStyle(
                        option,
                      ).copyWith(color: textColor),
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

  String _formatOption(String option) {
    // Capitalize Vietnamese text
    if (widget.exercise.type == ExerciseType.hanziToMeaning ||
        widget.exercise.type == ExerciseType.audioToMeaning) {
      return _capitalize(option);
    }
    return option;
  }

  TextStyle _getOptionTextStyle(String option) {
    // Use Hanzi style for Chinese characters
    if (widget.exercise.type == ExerciseType.meaningToHanzi ||
        widget.exercise.type == ExerciseType.audioToHanzi ||
        widget.exercise.type == ExerciseType.fillBlank) {
      return AppTypography.hanziSmall.copyWith(fontSize: 22);
    }
    // Use pinyin style for pinyin options
    if (widget.exercise.type == ExerciseType.hanziToPinyin) {
      return AppTypography.pinyin.copyWith(fontSize: 18);
    }
    return AppTypography.bodyLarge;
  }
}
