import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/hm_button.dart';
import '../../core/widgets/hm_app_bar.dart';
import '../../core/widgets/hm_loading.dart';
import '../../core/widgets/app_scaffold.dart';
import 'sentence_formation_controller.dart';

// Theme color for Sentence Formation (Orange/Amber)
const _kThemeColor = Color(0xFFFF8F00);
const _kThemeColorDark = Color(0xFFE65100);

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
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [const Color(0xFFFFFBF5), const Color(0xFFFFF3E0)],
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Obx(() {
            switch (controller.state.value) {
              case SentenceState.loading:
                return _buildLoading(isDark);
              case SentenceState.empty:
                return _buildEmpty(isDark);
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
          'Tiến trình hiện tại sẽ được lưu.',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Tiếp tục',
              style: AppTypography.labelLarge.copyWith(color: _kThemeColor),
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
      message: 'Đang tải bài tập...',
      icon: Icons.sort_rounded,
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : AppColors.textTertiary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school_rounded,
                size: 48,
                color: isDark ? Colors.white38 : AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa đủ từ vựng',
              style: AppTypography.titleLarge.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() => Text(
              controller.errorMessage.value.isNotEmpty
                  ? controller.errorMessage.value
                  : 'Hãy học thêm từ có câu ví dụ để luyện ghép câu',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            )),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HMButton(
                  text: 'Quay lại',
                  variant: HMButtonVariant.secondary,
                  onPressed: () => Get.back(),
                  fullWidth: false,
                ),
                const SizedBox(width: 12),
                HMButton(
                  text: 'Học từ mới',
                  onPressed: () {
                    Get.back();
                    // Navigate to learn new words
                    Get.toNamed('/practice', arguments: {'mode': 'learnNew'});
                  },
                  fullWidth: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercise(bool isDark) {
    final exercise = controller.currentExercise;
    if (exercise == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sentiment_dissatisfied_rounded,
                size: 64,
                color: isDark ? Colors.white38 : AppColors.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa đủ từ vựng',
                style: AppTypography.titleLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hãy học thêm từ có ví dụ để luyện ghép từ',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              HMButton(
                text: 'Quay lại',
                onPressed: () => Get.back(),
                fullWidth: false,
              ),
            ],
          ),
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
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isGood
                            ? [_kThemeColor, _kThemeColorDark]
                            : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                      ),
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
                      isGood ? Icons.emoji_events_rounded : Icons.trending_up_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              isGood ? 'Tuyệt vời! 🎉' : 'Tiếp tục luyện tập! 💪',
              style: AppTypography.headlineSmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Stats
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatItem(
                    icon: Icons.check_circle_rounded,
                    value: '${controller.correctCount.value}/${controller.totalAnswered.value}',
                    label: 'Đúng',
                    color: AppColors.success,
                    isDark: isDark,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  _buildStatItem(
                    icon: Icons.percent_rounded,
                    value: '$accuracy%',
                    label: 'Chính xác',
                    color: _kThemeColor,
                    isDark: isDark,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  _buildStatItem(
                    icon: Icons.timer_rounded,
                    value: controller.formattedTime,
                    label: 'Thời gian',
                    color: Colors.blue,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Luyện lại',
                  onTap: controller.restart,
                  isDark: isDark,
                  isPrimary: false,
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Hoàn tất',
                  onTap: controller.exitSession,
                  isDark: isDark,
                  isPrimary: true,
                ),
              ],
            ),
          ],
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
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? Colors.white54 : AppColors.textTertiary,
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [_kThemeColor, _kThemeColorDark],
                )
              : null,
          color: isPrimary ? null : (isDark ? Colors.white12 : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(color: isDark ? Colors.white24 : Colors.black12),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary
                  ? Colors.white
                  : (isDark ? Colors.white70 : AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
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
  });

  @override
  State<_SentenceExerciseWidget> createState() => _SentenceExerciseWidgetState();
}

class _SentenceExerciseWidgetState extends State<_SentenceExerciseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  // Exercise state
  late List<_TokenState> _wordBank;
  final List<_TokenState> _answerArea = [];
  bool _hasChecked = false;
  bool _isCorrect = false;
  List<bool>? _tokenCorrectness;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initTokens();
  }

  void _initAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
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
    return FadeTransition(
      opacity: _fadeIn,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Streak indicator (if any)
          if (widget.streak > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.withAlpha(40)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        size: 18, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.streak} liên tiếp!',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Prompt section
                  _buildPromptSection(),

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

          // Bottom section
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildPromptSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: widget.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          // Target word with audio
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _kThemeColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kThemeColor.withAlpha(40)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.exercise.questionHanzi ?? '',
                      style: const TextStyle(
                        fontFamily: 'NotoSansSC',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: _kThemeColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.exercise.questionPinyin ?? '',
                      style: AppTypography.bodyLarge.copyWith(
                        color: _kThemeColor.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Audio button
              GestureDetector(
                onTap: () => widget.onPlayAudio(slow: false),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: widget.isSpeaking
                        ? const LinearGradient(colors: [_kThemeColor, _kThemeColorDark])
                        : null,
                    color: widget.isSpeaking ? null : (widget.isDark ? Colors.white12 : Colors.grey.shade100),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                    size: 22,
                    color: widget.isSpeaking
                        ? Colors.white
                        : (widget.isDark ? Colors.white70 : AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Instruction
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.translate_rounded, size: 16, color: _kThemeColor),
              const SizedBox(width: 6),
              Text(
                'Sắp xếp từ để dịch câu sau',
                style: AppTypography.labelMedium.copyWith(
                  color: _kThemeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Vietnamese meaning
          Text(
            widget.exercise.questionMeaning ?? '',
            style: AppTypography.titleMedium.copyWith(
              color: widget.isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 18,
              color: widget.isDark ? Colors.white54 : AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              'Câu trả lời của bạn',
              style: AppTypography.labelMedium.copyWith(
                color: widget.isDark ? Colors.white54 : AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hasChecked
                  ? (_isCorrect ? AppColors.success : AppColors.error)
                  : (widget.isDark ? Colors.white24 : Colors.black12),
              width: _hasChecked ? 2 : 1,
            ),
            boxShadow: widget.isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: _answerArea.isEmpty
              ? Center(
                  child: Text(
                    'Nhấn vào từ bên dưới để ghép câu',
                    style: AppTypography.bodyMedium.copyWith(
                      color: widget.isDark ? Colors.white38 : AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
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
            Icon(
              Icons.inventory_2_outlined,
              size: 18,
              color: widget.isDark ? Colors.white54 : AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              'Kho từ',
              style: AppTypography.labelMedium.copyWith(
                color: widget.isDark ? Colors.white54 : AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: _wordBank.isEmpty
              ? Center(
                  child: Text(
                    'Tất cả từ đã được sử dụng',
                    style: AppTypography.bodySmall.copyWith(
                      color: widget.isDark ? Colors.white38 : AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: List.generate(_wordBank.length, (index) {
                    final token = _wordBank[index];
                    return _buildToken(
                      token.text,
                      onTap: () => _onTokenTapInBank(index),
                      isInAnswer: false,
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
    bool isCorrect = false,
    bool isWrong = false,
  }) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isCorrect) {
      bgColor = AppColors.success.withAlpha(15);
      borderColor = AppColors.success;
      textColor = AppColors.success;
    } else if (isWrong) {
      bgColor = AppColors.error.withAlpha(15);
      borderColor = AppColors.error;
      textColor = AppColors.error;
    } else if (isInAnswer) {
      bgColor = _kThemeColor.withAlpha(12);
      borderColor = _kThemeColor.withAlpha(60);
      textColor = _kThemeColor;
    } else {
      bgColor = widget.isDark ? Colors.white.withAlpha(10) : Colors.white;
      borderColor = widget.isDark ? Colors.white24 : Colors.black12;
      textColor = widget.isDark ? Colors.white : AppColors.textPrimary;
    }

    return GestureDetector(
      onTap: _hasChecked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(widget.isDark ? 20 : 8),
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
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            if (_hasChecked && (isCorrect || isWrong)) ...[
              const SizedBox(width: 8),
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 20,
                color: isCorrect ? AppColors.success : AppColors.error,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [const Color(0xFFFFFBF5), const Color(0xFFFFF3E0)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Feedback
            if (_hasChecked)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: (_isCorrect ? AppColors.success : AppColors.error).withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: _isCorrect ? AppColors.success : AppColors.error,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCorrect ? 'Chính xác! 🎉' : 'Chưa đúng rồi!',
                        style: AppTypography.titleSmall.copyWith(
                          color: _isCorrect ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Buttons - using HMButton for consistency
            Row(
              children: [
                if (!_isCorrect && _hasChecked)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: HMButton(
                        text: 'Làm lại',
                        variant: HMButtonVariant.secondary,
                        onPressed: _reset,
                      ),
                    ),
                  ),
                Expanded(
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
              ],
            ),
          ],
        ),
        ),
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
