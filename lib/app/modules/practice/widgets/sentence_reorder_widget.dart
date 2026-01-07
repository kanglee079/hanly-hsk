import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/book_page_scaffold.dart';
import '../../../core/widgets/hm_button.dart';
import '../../../data/models/exercise_model.dart';

/// Token model for sentence reorder exercise
class ReorderToken {
  final String id;
  final String text;
  final int correctOrder;

  const ReorderToken({
    required this.id,
    required this.text,
    required this.correctOrder,
  });
}

/// Sentence reorder exercise widget
/// User arranges shuffled Chinese tokens to form correct sentence
class SentenceReorderWidget extends StatefulWidget {
  final Exercise exercise;
  final bool isDark;
  final VoidCallback onCorrect;
  final VoidCallback onIncorrect;
  final VoidCallback onContinue;

  const SentenceReorderWidget({
    super.key,
    required this.exercise,
    required this.isDark,
    required this.onCorrect,
    required this.onIncorrect,
    required this.onContinue,
  });

  @override
  State<SentenceReorderWidget> createState() => _SentenceReorderWidgetState();
}

class _SentenceReorderWidgetState extends State<SentenceReorderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleBook;

  // Exercise state
  late List<_TokenState> _wordBank;
  final List<_TokenState> _answerArea = [];
  bool _hasChecked = false;
  bool _isCorrect = false;
  List<bool>? _tokenCorrectness; // null = not checked, true/false = correct/wrong

  BookPageColors get _colors => BookPageColors(isDark: widget.isDark);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initTokens();
  }

  void _initAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _scaleBook = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  void _initTokens() {
    final words = widget.exercise.sentenceWords ?? [];
    // Words are in correct order from generator
    // Create tokens with originalIndex = correct position
    _wordBank = List.generate(words.length, (i) {
      return _TokenState(
        id: 'token_$i',
        text: words[i],
        originalIndex: i, // This is the correct position
      );
    });
    // Shuffle the word bank for the exercise
    _wordBank.shuffle();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTokenTapInBank(int index) {
    if (_hasChecked) return;
    HapticFeedback.lightImpact();
    setState(() {
      final token = _wordBank.removeAt(index);
      _answerArea.add(token);
    });
  }

  void _onTokenTapInAnswer(int index) {
    if (_hasChecked) return;
    HapticFeedback.lightImpact();
    setState(() {
      final token = _answerArea.removeAt(index);
      _wordBank.add(token);
    });
  }

  void _checkAnswer() {
    HapticFeedback.mediumImpact();
    
    // Check if answer is correct by comparing originalIndex with position
    // If token at position i has originalIndex == i, it's in correct position
    final correctWords = widget.exercise.sentenceWords ?? [];
    
    // Check if all tokens are in correct positions
    _isCorrect = _answerArea.length == correctWords.length;
    if (_isCorrect) {
      for (int i = 0; i < _answerArea.length; i++) {
        if (_answerArea[i].originalIndex != i) {
          _isCorrect = false;
          break;
        }
      }
    }
    
    // Calculate per-token correctness for visual feedback
    _tokenCorrectness = List.generate(_answerArea.length, (i) {
      return _answerArea[i].originalIndex == i;
    });

    setState(() {
      _hasChecked = true;
    });

    if (_isCorrect) {
      widget.onCorrect();
    } else {
      widget.onIncorrect();
    }
  }

  void _reset() {
    HapticFeedback.lightImpact();
    setState(() {
      _wordBank.addAll(_answerArea);
      _answerArea.clear();
      _wordBank.shuffle();
      _hasChecked = false;
      _isCorrect = false;
      _tokenCorrectness = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Book content
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Vietnamese prompt
                      _buildPrompt(),

                      const SizedBox(height: 24),

                      // Answer area
                      _buildAnswerArea(),

                      const Spacer(),

                      // Word bank
                      _buildWordBank(),

                      const SizedBox(height: 16),
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

  Widget _buildPrompt() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.translate_rounded, size: 16, color: _colors.accentGold),
            const SizedBox(width: 6),
            Text(
              'Sắp xếp từ tạo câu đúng',
              style: AppTypography.labelMedium.copyWith(
                color: _colors.accentGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _colors.accentGold.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _colors.accentGold.withAlpha(30)),
          ),
          child: Text(
            widget.exercise.questionMeaning ?? 'Dịch câu này',
            style: AppTypography.bodyLarge.copyWith(
              color: _colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_rounded, size: 14, color: _colors.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Câu trả lời của bạn:',
              style: AppTypography.labelSmall.copyWith(
                color: _colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _colors.borderColor.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hasChecked
                  ? (_isCorrect ? AppColors.success : AppColors.error)
                  : _colors.borderColor.withAlpha(50),
              width: _hasChecked ? 2 : 1,
            ),
          ),
          child: _answerArea.isEmpty
              ? Center(
                  child: Text(
                    'Nhấn vào từ bên dưới để thêm vào đây',
                    style: AppTypography.bodySmall.copyWith(
                      color: _colors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_answerArea.length, (index) {
                    final token = _answerArea[index];
                    final isCorrectToken = _tokenCorrectness != null &&
                        index < _tokenCorrectness!.length &&
                        _tokenCorrectness![index];
                    final isWrongToken = _tokenCorrectness != null &&
                        index < _tokenCorrectness!.length &&
                        !_tokenCorrectness![index];

                    return _buildToken(
                      token.text,
                      onTap: () => _onTokenTapInAnswer(index),
                      isInAnswer: true,
                      isCorrect: isCorrectToken,
                      isWrong: isWrongToken,
                      index: index,
                    );
                  }),
                ),
        ),
      ],
    );
  }

  Widget _buildWordBank() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2_outlined, size: 14, color: _colors.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Kho từ:',
              style: AppTypography.labelSmall.copyWith(
                color: _colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _colors.pageBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _colors.borderColor.withAlpha(40)),
          ),
          child: _wordBank.isEmpty
              ? Center(
                  child: Text(
                    'Tất cả từ đã được sử dụng',
                    style: AppTypography.bodySmall.copyWith(
                      color: _colors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_wordBank.length, (index) {
                    final token = _wordBank[index];
                    return _buildToken(
                      token.text,
                      onTap: () => _onTokenTapInBank(index),
                      isInAnswer: false,
                      index: index,
                    );
                  }),
                ),
        ),
      ],
    );
  }

  Widget _buildToken(
    String text, {
    required VoidCallback onTap,
    required bool isInAnswer,
    required int index,
    bool isCorrect = false,
    bool isWrong = false,
  }) {
    Color bgColor;
    Color borderColor;
    Color textColor = _colors.textPrimary;

    if (isCorrect) {
      bgColor = AppColors.success.withAlpha(20);
      borderColor = AppColors.success;
      textColor = AppColors.success;
    } else if (isWrong) {
      bgColor = AppColors.error.withAlpha(20);
      borderColor = AppColors.error;
      textColor = AppColors.error;
    } else if (isInAnswer) {
      bgColor = AppColors.primary.withAlpha(15);
      borderColor = AppColors.primary.withAlpha(50);
    } else {
      bgColor = _colors.borderColor.withAlpha(20);
      borderColor = _colors.borderColor.withAlpha(60);
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey('${isInAnswer ? 'ans' : 'bank'}_$index'),
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: _hasChecked ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(widget.isDark ? 30 : 10),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontFamily: 'NotoSansSC',
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              if (_hasChecked && (isCorrect || isWrong)) ...[
                const SizedBox(width: 6),
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 16,
                  color: isCorrect ? AppColors.success : AppColors.error,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      height: 120,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Feedback
          if (_hasChecked)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: _isCorrect ? AppColors.success : AppColors.error,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isCorrect ? 'Chính xác!' : 'Chưa đúng. Thử lại!',
                    style: AppTypography.titleSmall.copyWith(
                      color: _isCorrect ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Buttons
          Row(
            children: [
              if (!_isCorrect && _hasChecked)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      height: 50,
                      child: HMButton(
                        text: 'Làm lại',
                        variant: HMButtonVariant.secondary,
                        onPressed: _reset,
                      ),
                    ),
                  ),
                ),
              Expanded(
                flex: _isCorrect || !_hasChecked ? 1 : 1,
                child: SizedBox(
                  height: 50,
                  child: HMButton(
                    text: _hasChecked
                        ? (_isCorrect ? 'Tiếp tục' : 'Xem đáp án')
                        : 'Kiểm tra',
                    onPressed: _answerArea.isEmpty && !_hasChecked
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            if (_hasChecked) {
                              if (_isCorrect) {
                                widget.onContinue();
                              } else {
                                // Show correct answer
                                _showCorrectAnswer();
                              }
                            } else {
                              _checkAnswer();
                            }
                          },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCorrectAnswer() {
    // Move all tokens back and arrange in correct order
    setState(() {
      _wordBank.clear();
      _answerArea.clear();
      
      // Words are already in correct order from generator
      final words = widget.exercise.sentenceWords ?? [];
      for (int i = 0; i < words.length; i++) {
        _answerArea.add(_TokenState(
          id: 'token_$i',
          text: words[i],
          originalIndex: i,
        ));
      }
      
      _tokenCorrectness = List.filled(words.length, true);
      _isCorrect = true;
    });
    
    // Allow user to continue after seeing correct answer
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) widget.onContinue();
    });
  }
}

class _TokenState {
  final String id;
  final String text;
  final int originalIndex;

  _TokenState({
    required this.id,
    required this.text,
    required this.originalIndex,
  });
}

