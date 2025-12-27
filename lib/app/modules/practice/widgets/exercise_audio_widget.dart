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

/// Audio-based exercise widget (Audio → Hanzi or Audio → Meaning)
class ExerciseAudioWidget extends StatelessWidget {
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
            
            // Audio controls
            _buildAudioSection(),
            
            const SizedBox(height: 32),
            
            // Question text
            Text(
              exercise.type == ExerciseType.audioToHanzi
                  ? 'Chọn chữ Hán đúng:'
                  : 'Chọn nghĩa đúng:',
              style: AppTypography.bodyLarge.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Options
            ..._buildOptions(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSection() {
    return Column(
      children: [
        // Main audio button
        GestureDetector(
          onTap: onPlayAudio,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isPlaying ? 120 : 100,
            height: isPlaying ? 120 : 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withAlpha(200),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(isPlaying ? 100 : 50),
                  blurRadius: isPlaying ? 30 : 20,
                  spreadRadius: isPlaying ? 5 : 0,
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
              size: isPlaying ? 56 : 48,
              color: Colors.white,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Audio hint
        if (!hasPlayed)
          Text(
            '👆 Nhấn để nghe',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          Text(
            'Nhấn lại để nghe',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Slow playback button
        if (onPlaySlow != null)
          GestureDetector(
            onTap: onPlaySlow,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.slow_motion_video_rounded,
                    size: 18,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nghe chậm',
                    style: AppTypography.labelMedium.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
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
      
      // Determine if this is a Hanzi or meaning option
      final isHanziOption = exercise.type == ExerciseType.audioToHanzi;
      
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
            padding: EdgeInsets.symmetric(
              horizontal: 20, 
              vertical: isHanziOption ? 20 : 16,
            ),
            decoration: BoxDecoration(
              color: bgColor ?? (isDark ? AppColors.surfaceDark : AppColors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor ?? (isDark ? AppColors.borderDark : AppColors.border),
                width: isSelected || (hasAnswered && isCorrectOption) ? 2 : 1,
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
                        : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index),
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
                    isHanziOption ? option : _capitalize(option),
                    style: isHanziOption
                        ? AppTypography.hanziSmall.copyWith(fontSize: 24, color: textColor)
                        : AppTypography.bodyLarge.copyWith(color: textColor),
                    textAlign: isHanziOption ? TextAlign.center : TextAlign.left,
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
}

