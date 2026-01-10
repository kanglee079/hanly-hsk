import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/book_page_scaffold.dart';
import '../../core/widgets/hm_button.dart';
import '../../core/widgets/hm_app_bar.dart';
import '../../core/widgets/hm_loading.dart';
import '../../core/widgets/app_scaffold.dart';
import 'sentence_formation_controller.dart';

// Theme color for Sentence Formation (Orange/Amber)
const _kThemeColor = Color(0xFFFF8F00);

/// Sentence Formation Practice Screen
/// Beautiful UI for arranging Chinese words to form correct sentences
class SentenceFormationScreen extends GetView<SentenceFormationController> {
  const SentenceFormationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: _buildAppBar(isDark),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF2D1B00)]
                : [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Obx(() {
            switch (controller.state.value) {
              case SentenceState.loading:
                return _buildLoading(isDark);
              case SentenceState.playing:
              case SentenceState.feedback:
                return _buildExercise(isDark);
              case SentenceState.complete:
                return _buildComplete(isDark);
            }
          }),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return HMAppBar(
      showBackButton: true,
      onBackPressed: () => _showExitConfirmation(isDark),
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'GHÉP TỪ',
            style: AppTypography.labelSmall.copyWith(
              color: (isDark ? Colors.white : AppColors.textTertiary)
                  .withValues(alpha: 0.7),
              letterSpacing: 1.2,
              fontSize: 10,
            ),
          ),
          Text(
            'Sentence Formation',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        Obx(() {
          if (controller.exercises.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _kThemeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${controller.currentIndex.value + 1}/${controller.exercises.length}',
                style: AppTypography.labelMedium.copyWith(
                  color: _kThemeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showExitConfirmation(bool isDark) {
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
              style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.exitSession();
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

  Widget _buildLoading(bool isDark) {
    return const HMLoadingContent(
      message: 'Đang tải bài tập ghép từ...',
      icon: Icons.sort_rounded,
    );
  }

  Widget _buildExercise(bool isDark) {
    final exercise = controller.currentExercise;
    if (exercise == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_dissatisfied_rounded,
              size: 64,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Không có bài tập phù hợp',
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy học thêm từ vựng có ví dụ để luyện đặt câu',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            HMButton(
              text: 'Quay lại',
              onPressed: () => Get.back(),
            ),
          ],
        ),
      );
    }

    return _SentenceExerciseWidget(
      key: ValueKey('exercise_${controller.currentIndex.value}'),
      exercise: exercise,
      vocab: controller.currentVocab,
      isDark: isDark,
      hasAnswered: controller.hasAnswered.value,
      isCorrect: controller.isCorrect.value,
      onCorrect: controller.onCorrectAnswer,
      onIncorrect: controller.onIncorrectAnswer,
      onContinue: controller.nextExercise,
      onPlayAudio: ({bool slow = false}) => controller.playAudio(slow: slow),
      isSpeaking: controller.isSpeaking.value,
      streak: controller.streak.value,
      xpEarned: controller.xpEarned.value,
    );
  }

  Widget _buildComplete(bool isDark) {
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
                      color: isGood ? _kThemeColor : const Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isGood ? _kThemeColor : const Color(0xFFF59E0B))
                              .withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      isGood ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              isGood ? 'Tuyệt vời! 🎉' : 'Cố gắng thêm! 💪',
              style: AppTypography.headlineSmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Độ chính xác: $accuracy%',
              style: AppTypography.titleMedium.copyWith(
                color: isGood ? _kThemeColor : const Color(0xFFF59E0B),
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
                      onTap: controller.exitSession,
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
              ? _kThemeColor
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
                    color: _kThemeColor.withValues(alpha: 0.3),
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

/// The actual sentence reorder exercise widget
class _SentenceExerciseWidget extends StatefulWidget {
  final dynamic exercise;
  final dynamic vocab;
  final bool isDark;
  final bool hasAnswered;
  final bool isCorrect;
  final VoidCallback onCorrect;
  final VoidCallback onIncorrect;
  final VoidCallback onContinue;
  final Future<void> Function({bool slow}) onPlayAudio;
  final bool isSpeaking;
  final int streak;
  final int xpEarned;

  const _SentenceExerciseWidget({
    super.key,
    required this.exercise,
    this.vocab,
    required this.isDark,
    required this.hasAnswered,
    required this.isCorrect,
    required this.onCorrect,
    required this.onIncorrect,
    required this.onContinue,
    required this.onPlayAudio,
    required this.isSpeaking,
    required this.streak,
    required this.xpEarned,
  });

  @override
  State<_SentenceExerciseWidget> createState() => _SentenceExerciseWidgetState();
}

class _SentenceExerciseWidgetState extends State<_SentenceExerciseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleBook;

  // Exercise state
  late List<_TokenState> _wordBank;
  final List<_TokenState> _answerArea = [];
  bool _hasChecked = false;
  bool _isCorrect = false;
  List<bool>? _tokenCorrectness;

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
    final words = widget.exercise.sentenceWords ?? <String>[];
    _wordBank = List.generate(words.length, (i) {
      return _TokenState(
        id: 'token_$i',
        text: words[i] as String,
        originalIndex: i,
      );
    });
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

    final correctWords = widget.exercise.sentenceWords ?? [];

    _isCorrect = _answerArea.length == correctWords.length;
    if (_isCorrect) {
      for (int i = 0; i < _answerArea.length; i++) {
        if (_answerArea[i].originalIndex != i) {
          _isCorrect = false;
          break;
        }
      }
    }

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

  void _showCorrectAnswer() {
    setState(() {
      _wordBank.clear();
      _answerArea.clear();

      final words = widget.exercise.sentenceWords ?? <String>[];
      for (int i = 0; i < words.length; i++) {
        _answerArea.add(_TokenState(
          id: 'token_$i',
          text: words[i] as String,
          originalIndex: i,
        ));
      }

      _tokenCorrectness = List.filled(words.length, true);
      _isCorrect = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) widget.onContinue();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Streak & XP indicators
          if (widget.streak > 0 || widget.xpEarned > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.streak > 0)
                    _buildBadge(
                      icon: Icons.local_fire_department_rounded,
                      color: Colors.orange,
                      text: '${widget.streak}',
                    ),
                  if (widget.streak > 0 && widget.xpEarned > 0)
                    const SizedBox(width: 12),
                  if (widget.xpEarned > 0)
                    _buildBadge(
                      icon: Icons.star_rounded,
                      color: AppColors.secondary,
                      text: '+${widget.xpEarned} XP',
                    ),
                ],
              ),
            ),

          // Book content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                      _buildPrompt(),
                      const SizedBox(height: 20),
                      _buildAnswerArea(),
                      const Spacer(),
                      _buildWordBank(),
                      const SizedBox(height: 12),
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

  Widget _buildBadge({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrompt() {
    return Column(
      children: [
        // Target word hint
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.exercise.questionHanzi ?? '',
                    style: TextStyle(
                      fontFamily: 'NotoSansSC',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.exercise.questionPinyin ?? '',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary.withAlpha(180),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Audio button
            GestureDetector(
              onTap: () => widget.onPlayAudio(slow: false),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.isSpeaking
                      ? AppColors.primary.withAlpha(30)
                      : _colors.borderColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.isSpeaking
                        ? AppColors.primary
                        : _colors.borderColor.withAlpha(50),
                  ),
                ),
                child: Icon(
                  widget.isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                  size: 18,
                  color: widget.isSpeaking ? AppColors.primary : _colors.textSecondary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Instruction
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.translate_rounded, size: 16, color: _colors.accentGold),
            const SizedBox(width: 6),
            Text(
              'Sắp xếp từ để dịch câu sau',
              style: AppTypography.labelMedium.copyWith(
                color: _colors.accentGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Vietnamese meaning to translate
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _colors.accentGold.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _colors.accentGold.withAlpha(30)),
          ),
          child: Text(
            widget.exercise.questionMeaning ?? 'Dịch câu này',
            style: AppTypography.titleMedium.copyWith(
              color: _colors.textPrimary,
              fontWeight: FontWeight.w500,
              height: 1.4,
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
          constraints: const BoxConstraints(minHeight: 70),
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
          constraints: const BoxConstraints(minHeight: 50),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              if (_hasChecked && (isCorrect || isWrong)) ...[
                const SizedBox(width: 6),
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 18,
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: widget.isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isCorrect ? 'Chính xác! 🎉' : 'Chưa đúng. Thử lại!',
                    style: AppTypography.titleMedium.copyWith(
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
                      height: 52,
                      child: HMButton(
                        text: 'Làm lại',
                        variant: HMButtonVariant.secondary,
                        onPressed: _reset,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: SizedBox(
                  height: 52,
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
