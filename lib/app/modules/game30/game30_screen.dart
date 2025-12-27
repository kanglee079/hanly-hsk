import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import 'game30_controller.dart';

/// 30s Game Screen - Fast-paced vocabulary quiz
class Game30Screen extends GetView<Game30Controller> {
  const Game30Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A) // Dark navy
          : const Color(0xFFF8FAFC), // Lighter slate gray
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Đang tải câu hỏi...',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            );
          }

          if (controller.isGameOver.value) {
            return _buildGameOverScreen(context, isDark);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final timerSize = isSmallScreen ? 90.0 : 110.0;
              final cardPadding = isSmallScreen ? 16.0 : 20.0;

              return Column(
                children: [
                  // Header
                  _buildHeader(isDark, isSmallScreen),

                  SizedBox(height: isSmallScreen ? 8 : 16),

                  // Timer + Score Row
                  _buildTimerScoreRow(isDark, timerSize, isSmallScreen),

                  SizedBox(height: isSmallScreen ? 12 : 20),

                  // Vocab Card
                  Expanded(
                    child: _buildVocabCard(isDark, cardPadding, isSmallScreen),
                  ),

                  SizedBox(height: isSmallScreen ? 12 : 16),

                  // Answer Options
                  _buildAnswerOptions(isDark, isSmallScreen),

                  SizedBox(height: isSmallScreen ? 16 : 24),
                ],
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildTimerScoreRow(bool isDark, double timerSize, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Timer Ring
          _buildTimerRing(isDark, timerSize),
          
          const SizedBox(width: 20),
          
          // Score + Streak Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withAlpha(100),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withAlpha(20),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 20,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${controller.score.value}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              )),
              
              const SizedBox(height: 8),
              
              // Streak Badge
              Obx(() {
                if (controller.streak.value == 0) {
                  return const SizedBox.shrink();
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'x${controller.streak.value}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (controller.streakMultiplier > 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${controller.streakMultiplier}x',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool isSmallScreen) {
    final buttonSize = isSmallScreen ? 40.0 : 44.0;
    final iconSize = isSmallScreen ? 20.0 : 22.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: isSmallScreen ? 8 : 12,
      ),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: controller.exitGame,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 30 : 8),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.close_rounded,
                size: iconSize,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
          ),

          const Spacer(),

          // Title
          Column(
            children: [
              Text(
                'GAME 30 GIÂY',
                style: AppTypography.labelMedium.copyWith(
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Obx(() => Text(
                '${controller.correctCount.value}/${controller.correctCount.value + controller.wrongCount.value}',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
              )),
            ],
          ),

          const Spacer(),

          // Pause button
          GestureDetector(
            onTap: controller.togglePause,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 30 : 8),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Obx(() => Icon(
                    controller.isPaused.value
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    size: iconSize,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerRing(bool isDark, double size) {
    return Obx(() {
      final progress = controller.remainingSeconds.value / 30;
      final isLow = controller.remainingSeconds.value <= 10;
      final isCritical = controller.remainingSeconds.value <= 5;

      // Softer colors - no harsh red
      Color ringColor;
      if (isCritical) {
        ringColor = const Color(0xFFEF4444); // Softer red-orange
      } else if (isLow) {
        ringColor = const Color(0xFFF59E0B); // Amber
      } else {
        ringColor = AppColors.primary;
      }

      return Stack(
        alignment: Alignment.center,
        children: [
          // Clean background ring - no outer glow
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _TimerRingPainter(
                progress: progress,
                color: ringColor,
                backgroundColor: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                strokeWidth: 8,
              ),
            ),
          ),
          // Timer text - always consistent color
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${controller.remainingSeconds.value}',
                style: TextStyle(
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.w800,
                  color: isCritical
                      ? ringColor
                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
              Text(
                'GIÂY',
                style: TextStyle(
                  fontSize: size * 0.1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildVocabCard(bool isDark, double padding, bool isSmallScreen) {
    return Obx(() {
      final vocab = controller.currentVocab;
      if (vocab == null) return const SizedBox();

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [Colors.white, const Color(0xFFF8FAFC)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 40 : 12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Audio button - top right
              if (vocab.audioUrl != null && vocab.audioUrl!.isNotEmpty)
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: controller.playAudio,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),

              // Main content
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hanzi - main focus
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            vocab.hanzi,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 56 : 72,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 12 : 16),

                      // Pinyin hint - styled nicely
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(isDark ? 25 : 15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          vocab.pinyin,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAnswerOptions(bool isDark, bool isSmallScreen) {
    return Obx(() {
      final options = controller.quizOptions;
      if (options.isEmpty) return const SizedBox();

      final horizontalPadding = isSmallScreen ? 12.0 : 20.0;
      final gap = isSmallScreen ? 8.0 : 12.0;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          children: [
            // Row 1
            Row(
              children: [
                Expanded(
                  child: _AnswerButton(
                    label: options[0],
                    letter: 'A',
                    index: 0,
                    controller: controller,
                    isDark: isDark,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: _AnswerButton(
                    label: options.length > 1 ? options[1] : '',
                    letter: 'B',
                    index: 1,
                    controller: controller,
                    isDark: isDark,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ],
            ),
            SizedBox(height: gap),
            // Row 2
            Row(
              children: [
                Expanded(
                  child: _AnswerButton(
                    label: options.length > 2 ? options[2] : '',
                    letter: 'C',
                    index: 2,
                    controller: controller,
                    isDark: isDark,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: _AnswerButton(
                    label: options.length > 3 ? options[3] : '',
                    letter: 'D',
                    index: 3,
                    controller: controller,
                    isDark: isDark,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildGameOverScreen(BuildContext context, bool isDark) {
    return Obx(() {
      // Calculate performance rating
      final score = controller.score.value;
      final correctCount = controller.correctCount.value;
      final totalAnswered = controller.totalAnswered.value;
      final accuracy = totalAnswered > 0 ? (correctCount / totalAnswered * 100).round() : 0;

      // Dynamic feedback based on performance
      final PerformanceLevel level = _getPerformanceLevel(score, accuracy);

      return SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Dynamic icon based on performance
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: level.gradientColors,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: level.gradientColors[0].withAlpha(100),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                level.icon,
                color: Colors.white,
                size: 48,
              ),
            ),

            const SizedBox(height: 32),

            Text(
              level.title,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              level.message,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),

            // Accuracy indicator
            if (totalAnswered > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: level.gradientColors[0].withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: level.gradientColors[0].withAlpha(80),
                  ),
                ),
                child: Text(
                  'Độ chính xác: $accuracy%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: level.gradientColors[0],
                  ),
                ),
              ),
            ],

          const SizedBox(height: 40),

          // Stats
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 50 : 15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatColumn(
                      value: '${controller.score.value}',
                      label: 'Điểm',
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                    _StatColumn(
                      value: '${controller.correctCount.value}',
                      label: 'Đúng',
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                    _StatColumn(
                      value: 'x${controller.maxStreak.value}',
                      label: 'Chuỗi cao',
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                  ],
                )),
          ),

          const SizedBox(height: 40),

          // Buttons
          HMButton(
            text: 'Chơi lại',
            onPressed: controller.restartGame,
          ),
          const SizedBox(height: 12),
          HMButton(
            text: 'Thoát',
            variant: HMButtonVariant.outline,
            onPressed: controller.exitGame,
          ),

            const SizedBox(height: 40),
          ],
        ),
      );
    });
  }

  PerformanceLevel _getPerformanceLevel(int score, int accuracy) {
    if (score == 0) {
      return PerformanceLevel(
        title: 'Hãy thử lại!',
        message: 'Đừng nản, luyện tập nhiều sẽ tiến bộ thôi!',
        icon: Icons.refresh_rounded,
        gradientColors: [const Color(0xFF94A3B8), const Color(0xFF64748B)],
      );
    } else if (score < 50 || accuracy < 30) {
      return PerformanceLevel(
        title: 'Cần cố gắng!',
        message: 'Hãy ôn tập thêm từ vựng nhé!',
        icon: Icons.trending_up_rounded,
        gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      );
    } else if (score < 100 || accuracy < 50) {
      return PerformanceLevel(
        title: 'Khá tốt!',
        message: 'Bạn đang tiến bộ, tiếp tục nhé!',
        icon: Icons.thumb_up_rounded,
        gradientColors: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
      );
    } else if (score < 200 || accuracy < 70) {
      return PerformanceLevel(
        title: 'Tốt lắm!',
        message: 'Bạn đã nắm vững khá nhiều từ vựng!',
        icon: Icons.star_rounded,
        gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
      );
    } else if (score < 300 || accuracy < 85) {
      return PerformanceLevel(
        title: 'Xuất sắc!',
        message: 'Bạn thật giỏi! Tiếp tục phát huy!',
        icon: Icons.emoji_events_rounded,
        gradientColors: [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
      );
    } else {
      return PerformanceLevel(
        title: 'Siêu sao!',
        message: 'Không thể tin được! Bạn là bậc thầy!',
        icon: Icons.auto_awesome_rounded,
        gradientColors: [const Color(0xFFEC4899), const Color(0xFF8B5CF6)],
      );
    }
  }
}

/// Performance level data class
class PerformanceLevel {
  final String title;
  final String message;
  final IconData icon;
  final List<Color> gradientColors;

  PerformanceLevel({
    required this.title,
    required this.message,
    required this.icon,
    required this.gradientColors,
  });
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final String letter;
  final int index;
  final Game30Controller controller;
  final bool isDark;
  final bool isSmallScreen;

  const _AnswerButton({
    required this.label,
    required this.letter,
    required this.index,
    required this.controller,
    required this.isDark,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) {
      return const SizedBox();
    }

    // Fixed height to prevent UI jumping
    final fixedHeight = isSmallScreen ? 85.0 : 100.0;

    return Obx(() {
      final isSelected = controller.selectedAnswer.value == index;
      final hasAnswered = controller.hasAnswered.value;
      final isCorrect = controller.quizOptions.isNotEmpty &&
          index < controller.quizOptions.length &&
          controller.quizOptions[index] == controller.currentVocab?.meaningVi;

      Color bgColor;
      Color textColor;
      Color borderColor;
      Color letterBgColor;
      Color letterTextColor;

      if (hasAnswered) {
        if (isCorrect) {
          bgColor = AppColors.primary;
          textColor = Colors.white;
          borderColor = AppColors.primary;
          letterBgColor = Colors.white.withAlpha(50);
          letterTextColor = Colors.white;
        } else if (isSelected) {
          bgColor = const Color(0xFFEF4444).withAlpha(25);
          textColor = const Color(0xFFDC2626);
          borderColor = const Color(0xFFEF4444);
          letterBgColor = const Color(0xFFEF4444).withAlpha(30);
          letterTextColor = const Color(0xFFDC2626);
        } else {
          bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
          textColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);
          borderColor = isDark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0);
          letterBgColor = isDark
              ? const Color(0xFF334155)
              : const Color(0xFFF1F5F9);
          letterTextColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);
        }
      } else if (isSelected) {
        bgColor = AppColors.primary.withAlpha(15);
        textColor = AppColors.primary;
        borderColor = AppColors.primary;
        letterBgColor = AppColors.primary;
        letterTextColor = Colors.white;
      } else {
        bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
        textColor = isDark ? Colors.white : const Color(0xFF0F172A);
        borderColor = isDark
            ? const Color(0xFF334155)
            : const Color(0xFFE2E8F0);
        letterBgColor = isDark
            ? const Color(0xFF334155)
            : const Color(0xFFF1F5F9);
        letterTextColor = isDark ? Colors.white60 : const Color(0xFF64748B);
      }

      final letterSize = isSmallScreen ? 24.0 : 28.0;
      final fontSize = isSmallScreen ? 14.0 : 16.0;

      return GestureDetector(
        onTap: hasAnswered ? null : () => controller.selectAnswer(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: fixedHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isSelected || (hasAnswered && isCorrect) ? 2.5 : 1.5,
            ),
            boxShadow: hasAnswered && isCorrect
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(60),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 40 : 10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Letter badge with icon overlay
              Container(
                width: letterSize,
                height: letterSize,
                decoration: BoxDecoration(
                  color: letterBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: hasAnswered && (isCorrect || (isSelected && !isCorrect))
                      ? Icon(
                          isCorrect ? Icons.check_rounded : Icons.close_rounded,
                          size: letterSize * 0.55,
                          color: isCorrect ? Colors.white : const Color(0xFFDC2626),
                        )
                      : Text(
                          letter,
                          style: TextStyle(
                            fontSize: letterSize * 0.5,
                            fontWeight: FontWeight.w700,
                            color: letterTextColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              // Answer text - use Expanded to prevent overflow
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _TimerRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.strokeWidth = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
