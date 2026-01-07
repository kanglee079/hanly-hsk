import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/book_page_scaffold.dart';
import '../../../core/widgets/hm_button.dart';
import '../../../data/models/exercise_model.dart';

/// Capitalize first letter
String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

/// Check if text contains Chinese characters
bool _isChineseText(String text) {
  if (text.isEmpty) return false;
  for (int i = 0; i < text.length; i++) {
    final code = text.codeUnitAt(i);
    if ((code >= 0x4E00 && code <= 0x9FFF) ||
        (code >= 0x3400 && code <= 0x4DBF) ||
        (code >= 0x20000 && code <= 0x2A6DF)) {
      return true;
    }
  }
  return false;
}

/// Audio exercise widget with single page Chinese book style
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
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleBook;
  late List<Animation<double>> _optionAnimations;

  BookPageColors get _colors => BookPageColors(isDark: widget.isDark);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _scaleBook = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );

    final optionCount = widget.exercise.options.length;
    _optionAnimations = List.generate(optionCount, (index) {
      final start = 0.2 + (index * 0.1);
      final end = start + 0.4;
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(
          start.clamp(0.0, 1.0),
          end.clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Book content - single page
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: AnimatedBuilder(
                animation: _scaleBook,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.9 + (_scaleBook.value * 0.1),
                    child: Opacity(
                      opacity: _fadeIn.value,
                      child: child,
                    ),
                  );
                },
                child: BookPageScaffold(
                  isDark: widget.isDark,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      // Audio section
                      _buildAudioSection(),

                      const SizedBox(height: 16),

                      // Divider
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _colors.borderColor.withAlpha(0),
                              _colors.borderColor,
                              _colors.borderColor.withAlpha(0),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Question text
                      Text(
                        widget.exercise.type == ExerciseType.audioToHanzi
                            ? 'Chọn chữ Hán đúng:'
                            : 'Chọn nghĩa đúng:',
                        style: AppTypography.bodyMedium.copyWith(
                          color: _colors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Options section
                      Expanded(
                        child: _buildOptionsSection(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom section
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildAudioSection() {
    return Column(
      children: [
        // Main audio button
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
                  color: AppColors.primary.withAlpha(widget.isPlaying ? 100 : 40),
                  blurRadius: widget.isPlaying ? 24 : 16,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                widget.isPlaying ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                key: ValueKey(widget.isPlaying),
                size: 36,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Hint and slow button row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Slow button
            if (widget.onPlaySlow != null) ...[
              GestureDetector(
                onTap: widget.onPlaySlow,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _colors.borderColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _colors.borderColor.withAlpha(50)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.slow_motion_video_rounded, size: 14, color: _colors.accentGold),
                      const SizedBox(width: 4),
                      Text(
                        'Chậm',
                        style: AppTypography.labelSmall.copyWith(color: _colors.accentGold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Hint
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                !widget.hasPlayed ? '👆 Nhấn để nghe' : 'Nhấn lại để nghe',
                key: ValueKey(widget.hasPlayed),
                style: AppTypography.bodySmall.copyWith(
                  color: !widget.hasPlayed
                      ? _colors.accentGold
                      : _colors.textTertiary,
                  fontWeight: !widget.hasPlayed ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _buildOptions(),
    );
  }

  List<Widget> _buildOptions() {
    final optionCount = widget.exercise.options.length;

    return List.generate(optionCount, (index) {
      final option = widget.exercise.options[index];
      final isSelected = widget.selectedAnswer == index;
      final isCorrectOption = index == widget.exercise.correctIndex;
      final isLast = index == optionCount - 1;
      final isOptionChinese = _isChineseText(option);

      Color bgColor;
      Color borderColor;
      Color textColor = _colors.textPrimary;

      if (widget.hasAnswered) {
        if (isCorrectOption) {
          bgColor = AppColors.success.withAlpha(20);
          borderColor = AppColors.success;
          textColor = AppColors.success;
        } else if (isSelected) {
          bgColor = AppColors.error.withAlpha(20);
          borderColor = AppColors.error;
          textColor = AppColors.error;
        } else {
          bgColor = _colors.borderColor.withAlpha(10);
          borderColor = _colors.borderColor.withAlpha(50);
        }
      } else if (isSelected) {
        bgColor = AppColors.primary.withAlpha(15);
        borderColor = AppColors.primary;
      } else {
        bgColor = _colors.borderColor.withAlpha(10);
        borderColor = _colors.borderColor.withAlpha(50);
      }

      return AnimatedBuilder(
        animation: _optionAnimations[index],
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(20 * (1 - _optionAnimations[index].value), 0),
            child: Opacity(
              opacity: _optionAnimations[index].value,
              child: child,
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
          child: GestureDetector(
            onTap: widget.hasAnswered
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    widget.onSelectAnswer(index);
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: isOptionChinese ? 10 : 12,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: isSelected || (widget.hasAnswered && isCorrectOption) ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Option letter
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withAlpha(40)
                          : _colors.borderColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : textColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Option text
                  Expanded(
                    child: Text(
                      isOptionChinese ? option : _capitalize(option),
                      style: isOptionChinese
                          ? TextStyle(
                              fontFamily: 'NotoSansSC',
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            )
                          : AppTypography.bodyMedium.copyWith(
                              color: textColor,
                              fontSize: 15,
                            ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Result icon
                  if (widget.hasAnswered && (isCorrectOption || isSelected))
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(scale: value, child: child);
                        },
                        child: Icon(
                          isCorrectOption ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: isCorrectOption ? AppColors.success : AppColors.error,
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildBottomSection() {
    return Container(
      height: 110,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: widget.hasAnswered
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(opacity: value, child: child);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: widget.isCorrect ? AppColors.success : AppColors.error,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isCorrect ? 'Chính xác!' : 'Chưa đúng',
                        style: AppTypography.titleSmall.copyWith(
                          color: widget.isCorrect ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
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
            )
          : const SizedBox.shrink(),
    );
  }
}
