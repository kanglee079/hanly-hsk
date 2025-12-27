import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import 'practice_controller.dart';
import 'widgets/exercise_mcq_widget.dart';
import 'widgets/exercise_audio_widget.dart';
import 'widgets/exercise_matching_widget.dart';
import 'widgets/learning_content_widget.dart';
import 'widgets/practice_complete_widget.dart';
import 'widgets/srs_rating_widget.dart';
import 'widgets/wrong_answers_widget.dart';

/// Capitalize first letter
String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

/// Practice/Learning screen with various exercise types
class PracticeScreen extends GetView<PracticeController> {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: HMAppBar(
        showBackButton: true,
        onBackPressed: controller.exitSession,
        titleWidget: Obx(() => _buildAppBarTitle(isDark)),
        actions: [
          Obx(() => _buildTimer(isDark)),
        ],
      ),
      body: Obx(() {
        // Show loading
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Show empty state if no data
        if (controller.hasNoData.value) {
          return _buildEmptyState(isDark);
        }

        switch (controller.state.value) {
          case PracticeState.loading:
            return const Center(child: CircularProgressIndicator());
            
          case PracticeState.learning:
            final vocab = controller.currentVocab;
            if (vocab == null) return _buildEmptyState(isDark);
            return LearningContentWidget(
              vocab: vocab,
              isDark: isDark,
              onContinue: controller.continueToExercise,
              onPlayAudio: () => controller.playAudio(),
              onPlaySlow: () => controller.playAudio(slow: true),
              onPlayExampleSentence: (text, url, slow) => controller.playExampleSentence(
                text: text,
                audioUrl: url,
                slow: slow,
              ),
            );
            
          case PracticeState.exercise:
            return _buildExercise(isDark);
            
          case PracticeState.feedback:
            return _buildFeedback(isDark);
            
          case PracticeState.pronunciation:
            return _buildPronunciation(isDark);
            
          case PracticeState.rating:
            final vocab = controller.currentVocab;
            if (vocab == null) return _buildEmptyState(isDark);
            return SRSRatingWidget(
              vocab: vocab,
              isDark: isDark,
              onRate: controller.submitRating,
            );
            
          case PracticeState.wrongAnswerReview:
            return WrongAnswersWidget(
              isDark: isDark,
              wrongAttempts: controller.wrongMatchAttempts,
              correctCount: controller.correctCount.value,
              totalCount: controller.totalExercises.value,
              onContinue: controller.continueToComplete,
            );
            
          case PracticeState.complete:
            return PracticeCompleteWidget(
              isDark: isDark,
              correctCount: controller.correctCount.value,
              totalCount: controller.totalExercises.value,
              timeSpent: controller.elapsedSeconds.value,
              onContinue: controller.continueSession,
              onFinish: () => Get.back(),
            );
        }
      }),
    );
  }

  Widget _buildAppBarTitle(bool isDark) {
    // Access observable to satisfy Obx requirement
    final _ = controller.state.value;
    
    // For matching mode, show title instead of progress
    if (controller.mode == PracticeMode.matching) {
      final matched = controller.matchedLeft.length;
      final total = controller.currentExercise?.matchingItems?.length ?? 0;
      
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.extension_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Ghép từ',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (total > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$matched/$total',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      );
    }
    
    // Default: show progress indicator
    return _buildProgressIndicator(isDark);
  }

  Widget _buildProgressIndicator(bool isDark) {
    // LearnNew: show word progress (1/N) instead of exercise progress (avoids "loạn")
    final isLearnNew = controller.mode == PracticeMode.learnNew;
    final total = isLearnNew ? controller.vocabs.length : controller.exercises.length;
    final current = isLearnNew
        ? (total == 0 ? 0 : (controller.currentExerciseIndex.value ~/ controller.config.exercisesPerVocab) + 1).clamp(0, total)
        : controller.currentExerciseIndex.value + 1;
    final progress = total > 0 ? (current / total) : 0.0;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark 
                  ? AppColors.surfaceVariantDark 
                  : AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$current/$total',
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTimer(bool isDark) {
    final hasTimeLimit = controller.config.timeLimit > 0;
    final seconds = hasTimeLimit 
        ? controller.remainingSeconds.value 
        : controller.elapsedSeconds.value;
    
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    
    final isUrgent = hasTimeLimit && seconds <= 10;
    
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Streak indicator
          if (controller.streak.value >= 3)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department, 
                    color: AppColors.secondary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${controller.streak.value}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          // Timer
          Text(
            '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
            style: AppTypography.labelMedium.copyWith(
              color: isUrgent 
                  ? AppColors.error 
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
              fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercise(bool isDark) {
    final exercise = controller.currentExercise;
    if (exercise == null) {
      return const Center(child: Text('Không có bài tập'));
    }

    switch (exercise.type) {
      case ExerciseType.hanziToMeaning:
      case ExerciseType.meaningToHanzi:
      case ExerciseType.hanziToPinyin:
      case ExerciseType.fillBlank:
        return ExerciseMCQWidget(
          exercise: exercise,
          isDark: isDark,
          selectedAnswer: controller.selectedAnswer.value,
          hasAnswered: controller.hasAnswered.value,
          isCorrect: controller.isCorrect.value,
          onSelectAnswer: controller.selectAnswer,
          onPlayAudio: () => controller.playAudio(),
        );
        
      case ExerciseType.audioToHanzi:
      case ExerciseType.audioToMeaning:
        return ExerciseAudioWidget(
          exercise: exercise,
          isDark: isDark,
          selectedAnswer: controller.selectedAnswer.value,
          hasAnswered: controller.hasAnswered.value,
          isCorrect: controller.isCorrect.value,
          isPlaying: controller.isPlayingAudio.value,
          hasPlayed: controller.hasPlayedAudio.value,
          onSelectAnswer: controller.selectAnswer,
          onPlayAudio: () => controller.playAudio(),
          onPlaySlow: () => controller.playAudio(slow: true),
        );
        
      case ExerciseType.matchingPairs:
        return ExerciseMatchingWidget(
          exercise: exercise,
          isDark: isDark,
          matchedLeft: controller.matchedLeft,
          matchedRight: controller.matchedRight,
          selectedLeft: controller.selectedLeft.value,
          selectedRight: controller.selectedRight.value,
          showWrongMatch: controller.showWrongMatch.value,
          wrongLeft: controller.wrongLeft.value,
          wrongRight: controller.wrongRight.value,
          onSelectLeft: (i) => controller.selectMatchingItem(isLeft: true, index: i),
          onSelectRight: (i) => controller.selectMatchingItem(isLeft: false, index: i),
        );
        
      case ExerciseType.sentenceOrder:
        // TODO: Implement sentence ordering
        return _buildPlaceholder('Sắp xếp câu', isDark);
        
      case ExerciseType.strokeWriting:
        // TODO: Implement stroke writing
        return _buildPlaceholder('Luyện viết', isDark);
        
      case ExerciseType.speakWord:
        return _buildPronunciation(isDark);
    }
  }

  Widget _buildFeedback(bool isDark) {
    final vocab = controller.currentVocab;
    final isCorrect = controller.lastAnswerCorrect.value;
    final correctAnswer = controller.lastCorrectAnswerDisplay.value;
    
    return SafeArea(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Feedback icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isCorrect 
                    ? AppColors.success.withAlpha(30) 
                    : AppColors.error.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCorrect ? Icons.check_rounded : Icons.close_rounded,
                size: 56,
                color: isCorrect ? AppColors.success : AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            
            // Message
            Text(
              isCorrect ? 'Chính xác! 🎉' : 'Chưa đúng',
              style: AppTypography.headlineMedium.copyWith(
                color: isCorrect ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Reinforce word (Hanzi + Pinyin + Meaning) for clarity
            if (vocab != null) ...[
              const SizedBox(height: 14),
              Text(
                vocab.hanzi,
                style: AppTypography.hanziLarge.copyWith(
                  fontSize: 44,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                vocab.pinyin,
                style: AppTypography.pinyin.copyWith(
                  fontSize: 18,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _capitalize(vocab.meaningVi),
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            
            // Show correct answer if wrong
            if (!isCorrect && correctAnswer.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Đáp án đúng:',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                correctAnswer,
                style: AppTypography.titleLarge.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            
            const Spacer(),
            
            // Continue button
            HMButton(
              text: 'Tiếp tục',
              onPressed: () {
                HapticFeedback.lightImpact();
                controller.nextExercise();
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPronunciation(bool isDark) {
    final vocab = controller.currentVocab;
    if (vocab == null) return const SizedBox.shrink();
    
    return SafeArea(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              vocab.hanzi,
              style: AppTypography.hanziLarge.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              vocab.pinyin,
              style: AppTypography.pinyin.copyWith(
                fontSize: 24,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Audio button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAudioButton(
                  icon: Icons.volume_up_rounded,
                  label: 'Nghe',
                  onTap: () => controller.playAudio(),
                  isDark: isDark,
                ),
                const SizedBox(width: 16),
                _buildAudioButton(
                  icon: Icons.slow_motion_video_rounded,
                  label: 'Chậm',
                  onTap: () => controller.playAudio(slow: true),
                  isDark: isDark,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Mic button
            Obx(() {
              final isListening = controller.isListening.value;
              return GestureDetector(
                onTap: controller.startListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isListening ? 90 : 80,
                  height: isListening ? 90 : 80,
                  decoration: BoxDecoration(
                    color: isListening ? AppColors.error : AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: isListening ? [
                      BoxShadow(
                        color: AppColors.error.withAlpha(100),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ] : null,
                  ),
                  child: Icon(
                    isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    size: isListening ? 40 : 36,
                    color: Colors.white,
                  ),
                ),
              );
            }),
            
            const SizedBox(height: 12),
            
            Obx(() {
              if (controller.isListening.value) {
                return Text(
                  'Đang nghe...',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                );
              }
              if (controller.hasPronunciationResult.value) {
                final passed = controller.isPronunciationPassed.value;
                return Column(
                  children: [
                    Icon(
                      passed ? Icons.check_circle : Icons.info_outline,
                      color: passed ? AppColors.success : AppColors.warning,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${controller.pronunciationScore.value} điểm',
                      style: AppTypography.titleMedium.copyWith(
                        color: passed ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }
              return Text(
                'Nhấn mic và đọc từ',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                ),
              );
            }),
            
            const Spacer(),
            
            // Bottom buttons
            Obx(() {
              if (controller.hasPronunciationResult.value) {
                return HMButton(
                  text: 'Tiếp tục',
                  onPressed: controller.continuePronunciation,
                );
              }
              return HMButton(
                text: 'Bỏ qua',
                variant: HMButtonVariant.outline,
                onPressed: controller.skipPronunciation,
              );
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String title, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 64,
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đang phát triển...',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 32),
          HMButton(
            text: 'Bỏ qua',
            variant: HMButtonVariant.outline,
            onPressed: controller.skipExercise,
          ),
        ],
      ),
    );
  }

  /// Empty state when no vocabulary available
  Widget _buildEmptyState(bool isDark) {
    final message = controller.noDataMessage.value;
    final isSuccess = message.contains('🎉'); // Check if it's a success message
    
    return SafeArea(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            
            // Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isSuccess 
                    ? AppColors.success.withAlpha(30) 
                    : AppColors.warning.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.celebration_rounded : Icons.inbox_rounded,
                size: 64,
                color: isSuccess ? AppColors.success : AppColors.warning,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              isSuccess ? 'Hoàn thành!' : 'Không có dữ liệu',
              style: AppTypography.headlineMedium.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const Spacer(),
            
            // Back button
            HMButton(
              text: 'Quay lại',
              onPressed: () => Get.back(),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

