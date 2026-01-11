import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import 'listening_controller.dart';

/// Listening Practice Screen - Beautiful audio-focused learning
class ListeningScreen extends GetView<ListeningController> {
  const ListeningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: HMAppBar(
        showBackButton: true,
        onBackPressed: () => _showExitConfirmation(context, isDark),
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LUYỆN NGHE',
              style: AppTypography.labelSmall.copyWith(
                color: (isDark ? Colors.white : AppColors.textTertiary)
                    .withValues(alpha: 0.7),
                letterSpacing: 1.2,
                fontSize: 10,
              ),
            ),
            Text(
              'Listening Practice',
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Obx(() {
            if (controller.vocabs.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${controller.currentIndex.value + 1}/${controller.vocabs.length}',
                  style: AppTypography.labelMedium.copyWith(
                    color: const Color(0xFF2196F3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Obx(() {
            if (controller.isLoading.value) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HMLoadingIndicator(
                      size: 48,
                      color: isDark ? Colors.white : const Color(0xFF2196F3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Đang tải bài nghe...',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (controller.vocabs.isEmpty) {
              return _buildEmptyState(isDark);
            }

            if (controller.hasFinished.value) {
              return _buildFinishedState(isDark);
            }

            return _buildQuestionContent(context, isDark);
          }),
        ),
      ),
    );
  }

  /// Show exit confirmation dialog
  void _showExitConfirmation(BuildContext context, bool isDark) {
    // Skip confirmation if not started or already finished
    if (controller.isLoading.value || 
        controller.vocabs.isEmpty ||
        controller.hasFinished.value) {
      controller.goBack();
      return;
    }

    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Thoát bài tập?',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Tiến trình hiện tại sẽ không được lưu.',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Tiếp tục',
              style: AppTypography.labelLarge.copyWith(color: const Color(0xFF2196F3)),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.goBack();
            },
            child: Text(
              'Thoát',
              style: AppTypography.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.headphones_rounded,
              size: 80,
              color: isDark ? Colors.white38 : AppColors.textTertiary,
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa đủ từ vựng',
              style: AppTypography.titleLarge.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy học thêm ít nhất 4 từ để bắt đầu luyện nghe',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            HMButton(
              text: 'Quay lại',
              onPressed: controller.goBack,
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishedState(bool isDark) {
    final accuracy = (controller.accuracy * 100).round();
    final isGood = accuracy >= 70;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Result icon with animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isGood
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isGood
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B))
                              .withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      isGood
                          ? Icons.headphones_rounded
                          : Icons.refresh_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              isGood ? 'Tuyệt vời! 🎧' : 'Cố gắng thêm! 💪',
              style: AppTypography.headlineSmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Độ chính xác: $accuracy%',
              style: AppTypography.titleMedium.copyWith(
                color: isGood
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${controller.correctCount.value}/${controller.totalAnswered.value} câu đúng',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 48),
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.refresh_rounded,
                      label: 'Luyện lại',
                      onTap: controller.restart,
                      isDark: isDark,
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Hoàn tất',
                      onTap: controller.goBack,
                      isDark: isDark,
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionContent(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Progress bar
        Obx(() => _buildProgressBar(isDark)),

        const SizedBox(height: 16),

        // Audio card - fixed at top
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Obx(() => _buildAudioCard(isDark)),
        ),

        const SizedBox(height: 24),

        // Answer options - takes remaining space
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Obx(() => _buildAnswerOptions(isDark)),
          ),
        ),

        // Bottom area - compact button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Obx(() {
            final hasAnswered = controller.hasAnswered.value;
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: hasAnswered ? 1 : 0,
              child: IgnorePointer(
                ignoring: !hasAnswered,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: controller.nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.currentIndex.value < controller.vocabs.length - 1
                              ? 'Tiếp theo'
                              : 'Xem kết quả',
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildProgressBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(controller.vocabs.length, (index) {
              final isCurrent = index == controller.currentIndex.value;
              final isPast = index < controller.currentIndex.value;
              return Container(
                width: isCurrent ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? const Color(0xFF2196F3)
                      : isPast
                          ? const Color(0xFF2196F3).withValues(alpha: 0.5)
                          : (isDark ? Colors.white24 : Colors.black12),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioCard(bool isDark) {
    final isPlaying = controller.isPlayingAudio.value;
    final hasPlayed = controller.hasPlayedAudio.value;

    return GestureDetector(
      onTap: controller.playAudio,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hasPlayed
                ? const Color(0xFF2196F3).withValues(alpha: 0.3)
                : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fixed size container for audio icon - prevents layout shift
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Animated glow effect (doesn't change size)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withValues(alpha: isPlaying ? 0.5 : 0.3),
                          blurRadius: isPlaying ? 30 : 20,
                          spreadRadius: isPlaying ? 4 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      isPlaying ? Icons.volume_up_rounded : Icons.headphones_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Instruction text - single line, no subtitle to prevent overflow
            Text(
              isPlaying
                  ? 'Đang phát...'
                  : hasPlayed
                      ? 'Nhấn để nghe lại'
                      : 'Nhấn để nghe',
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOptions(bool isDark) {
    final options = controller.answerOptions;
    final selectedIdx = controller.selectedAnswer.value;
    final hasAnswered = controller.hasAnswered.value;
    final correctIdx = controller.correctAnswerIndex;

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: options.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = selectedIdx == index;
        final isCorrectAnswer = index == correctIdx;

        Color bgColor;
        Color borderColor;
        Color textColor;

        if (!hasAnswered) {
          // Not answered yet
          bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
          borderColor = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08);
          textColor = isDark ? Colors.white : AppColors.textPrimary;
        } else if (isCorrectAnswer) {
          // Correct answer (always show green)
          bgColor = const Color(0xFF10B981).withValues(alpha: 0.15);
          borderColor = const Color(0xFF10B981);
          textColor = const Color(0xFF10B981);
        } else if (isSelected && !isCorrectAnswer) {
          // Wrong selection
          bgColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
          borderColor = const Color(0xFFEF4444);
          textColor = const Color(0xFFEF4444);
        } else {
          // Other options after answering
          bgColor = isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.5);
          borderColor = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05);
          textColor = isDark ? Colors.white38 : AppColors.textTertiary;
        }

        return GestureDetector(
          onTap: hasAnswered ? null : () {
            HapticFeedback.lightImpact();
            controller.selectAnswer(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                // Option letter
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: hasAnswered && isCorrectAnswer
                        ? const Color(0xFF10B981)
                        : hasAnswered && isSelected && !isCorrectAnswer
                            ? const Color(0xFFEF4444)
                            : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: hasAnswered && (isCorrectAnswer || isSelected)
                        ? Icon(
                            isCorrectAnswer ? Icons.check_rounded : Icons.close_rounded,
                            size: 18,
                            color: Colors.white,
                          )
                        : Text(
                            String.fromCharCode(65 + index), // A, B, C, D
                            style: AppTypography.labelMedium.copyWith(
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Answer text - only bold after answered
                Expanded(
                  child: Text(
                    option.meaningVi,
                    style: AppTypography.bodyLarge.copyWith(
                      color: textColor,
                      fontWeight: hasAnswered && (isSelected || isCorrectAnswer)
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFF2196F3)
              : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white24
                      : Colors.black.withValues(alpha: 0.1),
                ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary
                  ? Colors.white
                  : (isDark ? Colors.white70 : AppColors.textSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isPrimary
                    ? Colors.white
                    : (isDark ? Colors.white : AppColors.textPrimary),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

