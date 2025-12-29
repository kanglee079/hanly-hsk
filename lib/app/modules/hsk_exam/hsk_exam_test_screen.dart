import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../core/widgets/hm_bottom_sheet.dart';
import '../../core/constants/toast_messages.dart';
import '../../data/models/hsk_exam_model.dart';
import '../../data/repositories/hsk_exam_repo.dart';
import '../../services/audio_service.dart';
import '../../routes/app_routes.dart';

/// HSK Exam test-taking screen
class HskExamTestScreen extends StatefulWidget {
  const HskExamTestScreen({super.key});

  @override
  State<HskExamTestScreen> createState() => _HskExamTestScreenState();
}

class _HskExamTestScreenState extends State<HskExamTestScreen>
    with TickerProviderStateMixin {
  final HskExamRepo _examRepo = Get.find<HskExamRepo>();
  late final AudioService _audioService;

  // Test data
  MockTestModel? test;
  ExamAttempt? attempt;
  bool isLoading = true;
  String? errorMessage;

  // Current state
  int currentSectionIndex = 0;
  int currentQuestionIndex = 0;
  Map<String, String> answers = {}; // questionId -> optionLabel (A, B, C) - backend expects label

  // Timer
  Timer? _timer;
  int remainingSeconds = 0;

  // Animation
  late AnimationController _resultAnimController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  String get testId => Get.arguments?['testId'] as String? ?? '';

  @override
  void initState() {
    super.initState();
    _audioService = Get.find<AudioService>();
    _resultAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _resultAnimController,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _resultAnimController,
      curve: Curves.easeIn,
    );
    _loadTest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resultAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadTest() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _examRepo.getTestDetail(testId);
      setState(() {
        test = result.test;
        attempt = result.attempt;
        remainingSeconds = result.attempt.remainingSeconds;
        isLoading = false;
      });
      _startTimer();
    } catch (e) {
      setState(() {
        errorMessage = 'Không thể tải đề thi. Vui lòng thử lại.';
        isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        _timer?.cancel();
        _submitTest(autoSubmit: true);
      }
    });
  }

  ExamSection? get currentSection {
    if (test == null || test!.sections.isEmpty) return null;
    if (currentSectionIndex >= test!.sections.length) return null;
    return test!.sections[currentSectionIndex];
  }

  ExamQuestion? get currentQuestion {
    final section = currentSection;
    if (section == null || section.questions.isEmpty) return null;
    if (currentQuestionIndex >= section.questions.length) return null;
    return section.questions[currentQuestionIndex];
  }

  int get totalQuestions {
    if (test == null) return 0;
    return test!.sections.fold(0, (sum, s) => sum + s.questions.length);
  }

  int get currentQuestionNumber {
    int count = 0;
    for (int i = 0; i < currentSectionIndex; i++) {
      count += test!.sections[i].questions.length;
    }
    return count + currentQuestionIndex + 1;
  }

  int get answeredCount => answers.length;

  /// Select an answer - stores the option label (A, B, C) as backend expects label
  void _selectAnswer(String optionLabel) {
    final question = currentQuestion;
    if (question == null) return;
    setState(() {
      answers[question.id] = optionLabel;
    });
  }

  void _nextQuestion() {
    final section = currentSection;
    if (section == null) return;

    if (currentQuestionIndex < section.questions.length - 1) {
      setState(() => currentQuestionIndex++);
    } else if (currentSectionIndex < test!.sections.length - 1) {
      setState(() {
        currentSectionIndex++;
        currentQuestionIndex = 0;
      });
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() => currentQuestionIndex--);
    } else if (currentSectionIndex > 0) {
      setState(() {
        currentSectionIndex--;
        currentQuestionIndex =
            test!.sections[currentSectionIndex].questions.length - 1;
      });
    }
  }

  Future<void> _submitTest({bool autoSubmit = false}) async {
    if (attempt == null || test == null) return;

    if (!autoSubmit) {
      final confirm = await _showConfirmDialog();
      if (confirm != true) return;
    }

    // Show elegant loading
    _showLoadingDialog();

    try {
      final answersData = answers.entries
          .map((e) => {'questionId': e.key, 'selectedOption': e.value})
          .toList();

      final timeSpent = (test!.totalDuration * 60) - remainingSeconds;

      // Debug: Log answers being sent
      debugPrint('=== SUBMITTING ANSWERS ===');
      for (final answer in answersData) {
        debugPrint('Q: ${answer['questionId']} -> Answer: ${answer['selectedOption']}');
      }
      debugPrint('Total: ${answersData.length} answers');

      final result = await _examRepo.submitTest(
        testId: test!.id,
        attemptId: attempt!.id,
        answers: answersData,
        timeSpent: timeSpent,
      );
      
      // Debug: Log result
      debugPrint('=== RESULT RECEIVED ===');
      debugPrint('Score: ${result.score}/${result.maxScore}');
      debugPrint('Passed: ${result.passed}');
      for (final answer in result.answers) {
        debugPrint('Q: ${answer.questionId} -> Selected: ${answer.selectedOption}, Correct: ${answer.correctOption}, IsCorrect: ${answer.isCorrect}');
      }

      Get.back(); // Close loading
      _timer?.cancel();
      _showResultScreen(result, timeSpent);
    } catch (e) {
      Get.back();
      HMToast.error(ToastMessages.examSubmitError);
    }
  }

  void _showLoadingDialog() {
    final isDark = Get.isDarkMode;
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Đang nộp...',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(128),
    );
  }

  Future<bool?> _showConfirmDialog() {
    final unanswered = totalQuestions - answeredCount;
    final isDark = Get.isDarkMode;

    return HMBottomSheet.show<bool>(
      title: 'Nộp bài?',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (unanswered > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Còn $unanswered câu chưa trả lời',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          if (unanswered > 0) const SizedBox(height: 12),
          Text(
            'Đã trả lời: $answeredCount/$totalQuestions câu',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: HMButton(
                  text: 'Tiếp tục làm',
                  variant: HMButtonVariant.outline,
                  onPressed: () => Get.back(result: false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HMButton(
                  text: 'Nộp bài',
                  onPressed: () => Get.back(result: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showResultScreen(ExamResult result, int timeSpent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Start animation
    _resultAnimController.reset();
    _resultAnimController.forward();

    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: AnimatedBuilder(
            animation: _resultAnimController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.5 + (_scaleAnimation.value * 0.5),
                child: Opacity(
                  opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: result.passed
                              ? [const Color(0xFF34D399), const Color(0xFF10B981)]
                              : [const Color(0xFFF87171), const Color(0xFFEF4444)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (result.passed
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444))
                                .withAlpha(80),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        result.passed
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Score with animation
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: result.scorePercent),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Text(
                        '$value%',
                        style: AppTypography.displayMedium.copyWith(
                          color: result.passed
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          fontWeight: FontWeight.bold,
                          fontSize: 52,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 4),

                  Text(
                    result.passed ? 'Chúc mừng bạn đã đạt!' : 'Chưa đạt yêu cầu',
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats row
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceVariantDark
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildResultStat(
                            '${result.score}/${result.maxScore}', 'Điểm', isDark),
                        _buildDivider(isDark),
                        _buildResultStat('${result.passingScore}%', 'Yêu cầu', isDark),
                        _buildDivider(isDark),
                        _buildResultStat(
                            '$answeredCount/$totalQuestions', 'Trả lời', isDark),
                      ],
                    ),
                  ),

                  if (result.isNewBest) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withAlpha(60),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Kỷ lục mới!',
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Get.back();
                            Get.back();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Về danh sách'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back();
                            Get.back();
                            Get.toNamed(Routes.hskExamReview, arguments: {
                              'testId': test!.id,
                              'attemptId': result.attemptId,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Xem đáp án'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    );
  }

  Widget _buildResultStat(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 36,
      color: isDark ? AppColors.borderDark : AppColors.border,
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return _buildLoadingScreen(isDark);
    }

    if (errorMessage != null) {
      return _buildErrorScreen(isDark);
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          _buildProgressBar(isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildQuestionCard(isDark),
            ),
          ),
          _buildNavigationBar(isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () async {
          final confirm = await HMBottomSheet.showConfirm(
            title: 'Thoát bài thi?',
            message: 'Tiến độ của bạn sẽ bị mất.',
            confirmText: 'Thoát',
            cancelText: 'Tiếp tục',
            isDanger: true,
          );
          if (confirm == true) Get.back();
        },
      ),
      title: Column(
        children: [
          Text(
            test?.title ?? 'Đề thi HSK',
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          Text(
            'Câu $currentQuestionNumber/$totalQuestions',
            style: AppTypography.labelSmall.copyWith(
              color:
                  isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: remainingSeconds < 300
                ? AppColors.error.withAlpha(26)
                : (isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _formatTime(remainingSeconds),
            style: AppTypography.titleSmall.copyWith(
              color: remainingSeconds < 300
                  ? AppColors.error
                  : (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(bool isDark) {
    final progress =
        totalQuestions > 0 ? currentQuestionNumber / totalQuestions : 0.0;
    return Container(
      height: 4,
      color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(color: AppColors.primary),
      ),
    );
  }

  Widget _buildQuestionCard(bool isDark) {
    final question = currentQuestion;
    final section = currentSection;

    if (question == null || section == null) {
      return Center(
        child: Text(
          'Không có câu hỏi',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
      );
    }

    final hasPrompt = question.prompt.isNotEmpty;
    final hasContext = question.context != null && question.context!.isNotEmpty;
    final hasPassage = question.passage != null && question.passage!.isNotEmpty;
    final isFillBlank = question.type == 'reading_fill_blank';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: section.isListening
                ? const Color(0xFF3B82F6).withAlpha(26)
                : const Color(0xFF22C55E).withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            section.isListening ? 'Nghe hiểu' : 'Đọc hiểu',
            style: AppTypography.labelMedium.copyWith(
              color: section.isListening
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF22C55E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Audio player if listening
        if (question.hasAudio) ...[
          _buildAudioPlayer(question.audioUrl!, isDark),
          const SizedBox(height: 16),
        ],

        // Context with blank highlight for fill-in-blank
        if (hasContext) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceVariantDark
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: isFillBlank
                  ? Border.all(
                      color: AppColors.primary.withAlpha(80),
                      width: 1.5,
                    )
                  : null,
            ),
            child: isFillBlank
                ? _buildFillBlankText(question.context!, isDark)
                : Text(
                    question.context!,
                    style: AppTypography.titleSmall.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      height: 1.6,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
        ],

        // Passage for reading comprehension
        if (hasPassage) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceVariantDark
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              question.passage!,
              style: AppTypography.bodyMedium.copyWith(
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Question prompt
        if (hasPrompt)
          Text(
            question.prompt,
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          )
        else
          Text(
            _getDefaultPrompt(question.type),
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),

        const SizedBox(height: 20),

        // Options
        ...question.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final label = String.fromCharCode(65 + index); // A, B, C, D
          final isSelected = answers[question.id] == label; // Compare with label

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildOptionCard(label, option, isSelected, isDark),
          );
        }),
      ],
    );
  }

  /// Build text with highlighted blank for fill-in-blank questions
  Widget _buildFillBlankText(String text, bool isDark) {
    // Replace ____ or _____ with highlighted blank
    final parts = text.split(RegExp(r'_{2,}'));
    if (parts.length <= 1) {
      return Text(
        text,
        style: AppTypography.titleSmall.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          height: 1.6,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: AppTypography.titleSmall.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          height: 1.6,
        ),
        children: [
          for (int i = 0; i < parts.length; i++) ...[
            TextSpan(text: parts[i]),
            if (i < parts.length - 1)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Text(
                    '?',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _getDefaultPrompt(String type) {
    switch (type) {
      case 'listening_single':
        return 'Chọn đáp án đúng:';
      case 'listening_dialogue':
        return 'Nghe hội thoại và chọn đáp án đúng:';
      case 'reading_match':
        return 'Chọn nghĩa đúng:';
      case 'reading_fill_blank':
        return 'Chọn từ phù hợp để điền vào chỗ trống:';
      case 'reading_comprehension':
        return 'Đọc đoạn văn và trả lời câu hỏi:';
      default:
        return 'Chọn đáp án đúng:';
    }
  }

  Widget _buildAudioPlayer(String audioUrl, bool isDark) {
    return HMCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _audioService.play(audioUrl),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withAlpha(200)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhấn để nghe audio',
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Bạn có thể nghe nhiều lần',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    String label,
    QuestionOption option,
    bool isSelected,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => _selectAnswer(label), // Send label (A, B, C) to backend
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(26)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.border),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariant),
              ),
              child: Center(
                child: Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.text ?? '',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar(bool isDark) {
    final isFirst = currentSectionIndex == 0 && currentQuestionIndex == 0;
    final isLast = currentSectionIndex == (test?.sections.length ?? 1) - 1 &&
        currentQuestionIndex ==
            ((test?.sections[currentSectionIndex].questions.length ?? 1) - 1);

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPadding > 0 ? bottomPadding : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: HMButton(
              text: 'Trước',
              variant: HMButtonVariant.outline,
              onPressed: isFirst ? null : _previousQuestion,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: HMButton(
              text: isLast ? 'Nộp bài' : 'Tiếp',
              onPressed: isLast ? () => _submitTest() : _nextQuestion,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Đang tải đề thi...',
              style: AppTypography.bodyMedium.copyWith(
                color:
                    isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(
                  color:
                      isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              HMButton(
                text: 'Thử lại',
                onPressed: _loadTest,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
