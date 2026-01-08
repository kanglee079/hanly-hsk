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

/// MCQ widget with single page Chinese book style
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
                      // Question section
                      _buildQuestionSection(),

                      const SizedBox(height: 20),

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

                      const SizedBox(height: 16),

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

  Widget _buildQuestionSection() {
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
    // Compact layout: Hanzi + Audio in row to save vertical space
    return Column(
      children: [
        // Row with Hanzi + Pinyin + Audio button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hanzi + Pinyin
            Column(
              children: [
                Text(
                  widget.exercise.questionHanzi ?? '',
                  style: AppTypography.hanziLarge.copyWith(
                    color: _colors.textPrimary,
                    fontSize: 56,
                    height: 1.1,
                  ),
                ),
                if (widget.exercise.questionPinyin != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _colors.accentGold.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.exercise.questionPinyin!,
                      style: AppTypography.pinyin.copyWith(
                        fontSize: 20,
                        color: _colors.accentGold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // Audio button next to hanzi
            if (widget.exercise.questionAudioUrl != null && widget.onPlayAudio != null) ...[
              const SizedBox(width: 20),
              GestureDetector(
                onTap: widget.onPlayAudio,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _colors.accentGold.withAlpha(25),
                    shape: BoxShape.circle,
                    border: Border.all(color: _colors.accentGold.withAlpha(60), width: 1.5),
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: _colors.accentGold,
                    size: 24,
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 14),
        Text(
          _getQuestionText(),
          style: AppTypography.titleMedium.copyWith(
            fontSize: 16,
            color: _colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMeaningQuestion() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: _colors.accentGold.withAlpha(15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _colors.accentGold.withAlpha(50)),
          ),
          child: Text(
            _capitalize(widget.exercise.questionMeaning ?? ''),
            style: AppTypography.headlineMedium.copyWith(
              color: _colors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 24,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Chọn chữ Hán đúng:',
          style: AppTypography.titleMedium.copyWith(
            fontSize: 17,
            color: _colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFillBlankQuestion() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 160),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _colors.accentGold.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _colors.accentGold.withAlpha(30)),
              ),
              child: Text(
                widget.exercise.questionSentence ?? '',
                style: TextStyle(
                  fontFamily: 'NotoSansSC',
                  fontSize: 17,
                  color: _colors.textPrimary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (widget.exercise.questionMeaning != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.exercise.questionMeaning!,
                  style: AppTypography.bodySmall.copyWith(
                    color: _colors.textTertiary,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Điền từ phù hợp:',
              style: AppTypography.bodyMedium.copyWith(
                color: _colors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
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
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
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
              constraints: const BoxConstraints(minHeight: 58),
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isOptionChinese ? 12 : 14,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor,
                  width: isSelected || (widget.hasAnswered && isCorrectOption) ? 2.5 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  // Option letter - larger
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withAlpha(50)
                          : _colors.borderColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.primary : textColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Option text - larger fonts
                  Expanded(
                    child: Text(
                      isOptionChinese ? option : _capitalize(option),
                      style: isOptionChinese
                          ? TextStyle(
                              fontFamily: 'NotoSansSC',
                              fontSize: 26,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            )
                          : AppTypography.titleMedium.copyWith(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: isSelected || (widget.hasAnswered && isCorrectOption)
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Result icon - larger
                  if (widget.hasAnswered && (isCorrectOption || isSelected))
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
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
                          size: 28,
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
}
