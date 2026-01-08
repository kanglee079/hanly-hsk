import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import 'pronunciation_controller.dart';

/// Pronunciation practice screen with speech recognition
class PronunciationScreen extends GetView<PronunciationController> {
  const PronunciationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: HMAppBar(
        showBackButton: true,
        onBackPressed: controller.goBack,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LUYỆN PHÁT ÂM',
              style: AppTypography.labelSmall.copyWith(
                color: (isDark ? Colors.white : AppColors.textTertiary)
                    .withValues(alpha: 0.7),
                letterSpacing: 1.2,
                fontSize: 10,
              ),
            ),
            Text(
              'Pronunciation',
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Obx(() {
            if (controller.words.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${controller.currentIndex.value + 1}/${controller.words.length}',
                  style: AppTypography.labelMedium.copyWith(
                    color: const Color(0xFF4CAF50),
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                    const Color(0xFF0F3460),
                  ]
                : [
                    const Color(0xFFF0FDF4),
                    const Color(0xFFDCFCE7),
                    const Color(0xFFBBF7D0),
                  ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Obx(() {
            if (controller.isLoading.value) {
              return _buildLoadingState(isDark);
            }

            if (controller.words.isEmpty) {
              return _buildEmptyState(isDark);
            }

            if (controller.isSessionComplete.value) {
              return _buildSessionComplete(isDark);
            }

            return _buildPracticeView(context, isDark);
          }),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HMLoadingIndicator(
            size: 48,
            color: isDark ? Colors.white : const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tải từ vựng...',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
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
              Icons.mic_off_rounded,
              size: 80,
              color: isDark ? Colors.white38 : AppColors.textTertiary,
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có từ để luyện',
              style: AppTypography.titleLarge.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy học thêm từ mới trước nhé!',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeView(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Progress bar
        _buildProgressBar(isDark),
        
        const SizedBox(height: 16),

        // Word card
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildWordCard(isDark),
                const SizedBox(height: 24),
                _buildRecordingSection(isDark),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        
        // Bottom actions
        _buildBottomActions(isDark),
      ],
    );
  }

  Widget _buildProgressBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Obx(() {
        final progress = controller.words.isNotEmpty
            ? controller.currentIndex.value / controller.words.length
            : 0.0;
        
        return Column(
          children: [
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: isDark ? Colors.white54 : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(controller.practiceSeconds.value),
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark ? Colors.white54 : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '${controller.passedCount.value}',
                      style: AppTypography.labelMedium.copyWith(
                        color: const Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' / ${controller.totalAttempts.value} đạt',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark ? Colors.white54 : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress bar
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: MediaQuery.of(Get.context!).size.width * 0.9 * progress,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildWordCard(bool isDark) {
    return Obx(() {
      final word = controller.currentWord;
      if (word == null) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Hanzi
            Text(
              word.hanzi,
              style: TextStyle(
                fontFamily: 'NotoSansSC',
                fontSize: 56,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            
            // Pinyin
            Text(
              word.pinyin,
              style: AppTypography.titleLarge.copyWith(
                color: const Color(0xFF4CAF50),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            
            // Meaning
            Text(
              word.meaningVi,
              style: AppTypography.bodyLarge.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Audio buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAudioButton(
                  icon: Icons.volume_up_rounded,
                  label: 'Chuẩn',
                  onTap: () => controller.playAudio(slow: false),
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _buildAudioButton(
                  icon: Icons.slow_motion_video_rounded,
                  label: 'Chậm',
                  onTap: () => controller.playAudio(slow: true),
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAudioButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4CAF50), size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: const Color(0xFF4CAF50),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingSection(bool isDark) {
    return Obx(() {
      final isRecording = controller.isRecording.value;
      final hasResult = controller.hasResult.value;
      
      if (hasResult) {
        return _buildResultSection(isDark);
      }
      
      return Column(
        children: [
          // Microphone button with animation
          GestureDetector(
            onTap: isRecording ? controller.stopRecording : controller.startRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isRecording ? 120 : 100,
              height: isRecording ? 120 : 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isRecording
                      ? [const Color(0xFFEF5350), const Color(0xFFE53935)]
                      : [const Color(0xFF4CAF50), const Color(0xFF43A047)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isRecording 
                        ? const Color(0xFFE53935) 
                        : const Color(0xFF4CAF50)).withValues(alpha: 0.4),
                    blurRadius: isRecording ? 30 : 20,
                    spreadRadius: isRecording ? 5 : 0,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Sound wave animation
                  if (isRecording)
                    _SoundWaveAnimation(level: controller.soundLevel.value),
                  
                  Icon(
                    isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    size: 44,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Recording status
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isRecording
                ? Column(
                    key: const ValueKey('recording'),
                    children: [
                      Text(
                        'Đang ghi âm... ${controller.recordingCountdown.value}s',
                        style: AppTypography.titleMedium.copyWith(
                          color: const Color(0xFFE53935),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (controller.recognizedText.value.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '"${controller.recognizedText.value}"',
                            style: TextStyle(
                              fontFamily: 'NotoSansSC',
                              fontSize: 18,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                    ],
                  )
                : Text(
                    key: const ValueKey('idle'),
                    'Nhấn để bắt đầu ghi âm',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
          ),
          
          // Speech not available warning
          if (!controller.isSpeechAvailable.value)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, 
                      color: AppColors.warning, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Nhận diện giọng nói không khả dụng',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildResultSection(bool isDark) {
    return Obx(() {
      final score = controller.currentScore.value;
      final passed = controller.isPassed.value;
      final emoji = controller.feedbackEmoji.value;
      final feedbackText = controller.feedback.value;
      final recognizedText = controller.recognizedText.value;
      
      final resultColor = passed 
          ? const Color(0xFF4CAF50) 
          : (score >= 50 ? AppColors.warning : AppColors.error);
      
      return Column(
        children: [
          // Result card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: resultColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // Emoji and score
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$score điểm',
                            style: AppTypography.titleLarge.copyWith(
                              color: resultColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            feedbackText,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // What was recognized
                if (recognizedText.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nhận diện:',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? Colors.white54 : AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '"$recognizedText"',
                          style: TextStyle(
                            fontFamily: 'NotoSansSC',
                            fontSize: 18,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Retry button
          if (!passed)
            TextButton.icon(
              onPressed: controller.retryWord,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Thử lại'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4CAF50),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildBottomActions(bool isDark) {
    return Obx(() {
      final hasResult = controller.hasResult.value;
      
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Row(
          children: [
            // Skip button
            if (!hasResult)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: controller.skipWord,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white70 : AppColors.textSecondary,
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Bỏ qua'),
                  ),
                ),
              ),
            
            // Next/Continue button
            if (hasResult) ...[
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: controller.nextWord,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          controller.isLastWord ? 'Hoàn thành' : 'Tiếp theo',
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
            ],
          ],
        ),
      );
    });
  }

  Widget _buildSessionComplete(bool isDark) {
    final passRate = controller.totalAttempts.value > 0
        ? (controller.passedCount.value / controller.totalAttempts.value) * 100
        : 0.0;
    final isGood = passRate >= 70;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                  const Color(0xFF0F3460),
                ]
              : [
                  const Color(0xFFF0FDF4),
                  const Color(0xFFDCFCE7),
                  const Color(0xFFBBF7D0),
                ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Success icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isGood
                        ? [const Color(0xFF4CAF50).withValues(alpha: 0.2), 
                           const Color(0xFF4CAF50).withValues(alpha: 0.1)]
                        : [AppColors.warning.withValues(alpha: 0.2), 
                           AppColors.warning.withValues(alpha: 0.1)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isGood 
                          ? const Color(0xFF4CAF50) 
                          : AppColors.warning).withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  isGood ? Icons.celebration_rounded : Icons.school_rounded,
                  size: 48,
                  color: isGood ? const Color(0xFF4CAF50) : AppColors.warning,
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                isGood ? 'Tuyệt vời! 🎉' : 'Tiếp tục luyện tập! 💪',
                style: AppTypography.headlineMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Bạn đã hoàn thành phiên luyện phát âm!',
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Stats card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      icon: Icons.check_circle_rounded,
                      value: '${controller.passedCount.value}/${controller.totalAttempts.value}',
                      label: 'Đạt',
                      color: const Color(0xFF4CAF50),
                      isDark: isDark,
                    ),
                    Container(
                      width: 1,
                      height: 48,
                      color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                    ),
                    _buildStatItem(
                      icon: Icons.speed_rounded,
                      value: controller.averageScore.value.toStringAsFixed(0),
                      label: 'Điểm TB',
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                    Container(
                      width: 1,
                      height: 48,
                      color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                    ),
                    _buildStatItem(
                      icon: Icons.timer_rounded,
                      value: _formatTime(controller.practiceSeconds.value),
                      label: 'Thời gian',
                      color: AppColors.warning,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              
              const Spacer(flex: 3),
              
              // Action buttons
              HMButton(
                text: 'Luyện lại',
                onPressed: controller.restartSession,
                icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
              ),
              
              const SizedBox(height: 12),
              
              HMButton(
                text: 'Hoàn thành',
                variant: HMButtonVariant.outline,
                onPressed: controller.goBack,
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? Colors.white54 : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// Sound wave animation widget
class _SoundWaveAnimation extends StatelessWidget {
  final double level;

  const _SoundWaveAnimation({required this.level});

  @override
  Widget build(BuildContext context) {
    final normalizedLevel = (level + 10) / 40; // Normalize to 0-1 range
    
    return CustomPaint(
      size: const Size(120, 120),
      painter: _SoundWavePainter(
        level: normalizedLevel.clamp(0.0, 1.0),
      ),
    );
  }
}

class _SoundWavePainter extends CustomPainter {
  final double level;

  _SoundWavePainter({required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw concentric circles based on sound level
    for (int i = 1; i <= 3; i++) {
      final radius = 30 + (level * 20 * i);
      final opacity = (1 - (i * 0.25)) * level;
      paint.color = Colors.white.withValues(alpha: opacity.clamp(0.0, 0.5));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SoundWavePainter oldDelegate) => level != oldDelegate.level;
}
