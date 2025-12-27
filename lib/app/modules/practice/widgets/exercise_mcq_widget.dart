import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/exercise_model.dart';

/// Capitalize first letter
String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

/// Multiple choice question widget
class ExerciseMCQWidget extends StatelessWidget {
  final Exercise exercise;
  final bool isDark;
  final int selectedAnswer;
  final bool hasAnswered;
  final bool isCorrect;
  final Function(int) onSelectAnswer;
  final VoidCallback? onPlayAudio;

  const ExerciseMCQWidget({
    super.key,
    required this.exercise,
    required this.isDark,
    required this.selectedAnswer,
    required this.hasAnswered,
    required this.isCorrect,
    required this.onSelectAnswer,
    this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            
            // Question
            _buildQuestion(),
            
            const SizedBox(height: 40),
            
            // Options
            ..._buildOptions(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    switch (exercise.type) {
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
          exercise.questionHanzi ?? '',
          style: AppTypography.hanziLarge.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        
        // Pinyin (optional hint)
        if (exercise.type == ExerciseType.hanziToMeaning && 
            exercise.questionPinyin != null) ...[
          const SizedBox(height: 8),
          Text(
            exercise.questionPinyin!,
            style: AppTypography.pinyin.copyWith(
              fontSize: 18,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
          ),
        ],
        
        // Audio button
        if (exercise.questionAudioUrl != null && onPlayAudio != null) ...[
          const SizedBox(height: 16),
          _buildAudioButton(),
        ],
        
        // Question text
        const SizedBox(height: 24),
        Text(
          _getQuestionText(),
          style: AppTypography.bodyLarge.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
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
            color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _capitalize(exercise.questionMeaning ?? ''),
            style: AppTypography.headlineMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(height: 24),
        Text(
          'Chọn chữ Hán đúng:',
          style: AppTypography.bodyLarge.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
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
            color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            exercise.questionSentence ?? '',
            style: AppTypography.titleLarge.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        // Translation
        if (exercise.questionMeaning != null) ...[
          const SizedBox(height: 12),
          Text(
            _capitalize(exercise.questionMeaning!),
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        
        const SizedBox(height: 24),
        Text(
          'Điền từ phù hợp:',
          style: AppTypography.bodyLarge.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioButton() {
    return GestureDetector(
      onTap: onPlayAudio,
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
    switch (exercise.type) {
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

  List<Widget> _buildOptions() {
    return List.generate(exercise.options.length, (index) {
      final option = exercise.options[index];
      final isSelected = selectedAnswer == index;
      final isCorrectOption = index == exercise.correctIndex;
      
      Color? bgColor;
      Color? borderColor;
      Color textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
      
      if (hasAnswered) {
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
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: hasAnswered ? null : () {
            HapticFeedback.lightImpact();
            onSelectAnswer(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: bgColor ?? (isDark ? AppColors.surfaceDark : AppColors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor ?? (isDark ? AppColors.borderDark : AppColors.border),
                width: isSelected || (hasAnswered && isCorrectOption) ? 2 : 1,
              ),
              boxShadow: isSelected && !hasAnswered ? [
                BoxShadow(
                  color: AppColors.primary.withAlpha(30),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
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
                        : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: AppTypography.titleSmall.copyWith(
                        color: isSelected 
                            ? AppColors.primary 
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
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
                    style: _getOptionTextStyle(option).copyWith(color: textColor),
                  ),
                ),
                
                // Result icon
                if (hasAnswered) ...[
                  if (isCorrectOption)
                    const Icon(Icons.check_circle, color: AppColors.success, size: 24)
                  else if (isSelected)
                    const Icon(Icons.cancel, color: AppColors.error, size: 24),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  String _formatOption(String option) {
    // Capitalize Vietnamese text
    if (exercise.type == ExerciseType.hanziToMeaning || 
        exercise.type == ExerciseType.audioToMeaning) {
      return _capitalize(option);
    }
    return option;
  }

  TextStyle _getOptionTextStyle(String option) {
    // Use Hanzi style for Chinese characters
    if (exercise.type == ExerciseType.meaningToHanzi ||
        exercise.type == ExerciseType.audioToHanzi ||
        exercise.type == ExerciseType.fillBlank) {
      return AppTypography.hanziSmall.copyWith(fontSize: 22);
    }
    // Use pinyin style for pinyin options
    if (exercise.type == ExerciseType.hanziToPinyin) {
      return AppTypography.pinyin.copyWith(fontSize: 18);
    }
    return AppTypography.bodyLarge;
  }
}

