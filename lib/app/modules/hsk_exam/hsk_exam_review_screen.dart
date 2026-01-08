import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/hsk_exam_model.dart';
import '../../data/repositories/hsk_exam_repo.dart';

/// HSK Exam review screen - shows answers with explanations
class HskExamReviewScreen extends StatefulWidget {
  const HskExamReviewScreen({super.key});

  @override
  State<HskExamReviewScreen> createState() => _HskExamReviewScreenState();
}

class _HskExamReviewScreenState extends State<HskExamReviewScreen> {
  final HskExamRepo _examRepo = Get.find<HskExamRepo>();

  ExamReview? review;
  bool isLoading = true;
  String? errorMessage;

  String get testId => Get.arguments?['testId'] as String? ?? '';
  String get attemptId => Get.arguments?['attemptId'] as String? ?? '';

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  Future<void> _loadReview() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      review = await _examRepo.getAttemptReview(testId, attemptId);
      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        errorMessage = 'Không thể tải đáp án. Vui lòng thử lại.';
        isLoading = false;
      });
    }
  }

  String _formatTimeSpent(int seconds) {
    if (seconds <= 0) {
      return 'Chưa có dữ liệu';
    }
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }

  /// Map optionId to label (A, B, C) based on question options
  String? _getOptionLabel(String questionId, String optionId) {
    if (review == null) return null;
    
    // Find question in test
    ExamQuestion? question;
    for (final section in review!.test.sections) {
      final found = section.questions.firstWhere(
        (q) => q.id == questionId,
        orElse: () => ExamQuestion(id: '', type: '', prompt: ''),
      );
      if (found.id.isNotEmpty) {
        question = found;
        break;
      }
    }
    
    if (question == null || question.id.isEmpty) return null;
    
    // Find option index
    final index = question.options.indexWhere((opt) => opt.id == optionId);
    if (index == -1) return null;
    
    // Return label (A, B, C, D)
    return String.fromCharCode(65 + index);
  }
  
  /// Get display text for option
  /// Backend returns label (A, B, C) directly, but we check if it's optionId and map it
  String _getDisplayOption(String questionId, String optionValue) {
    // If it's already a single letter (A, B, C), return as is (backend returns label)
    if (optionValue.length == 1 && 
        optionValue.codeUnitAt(0) >= 65 && 
        optionValue.codeUnitAt(0) <= 90) {
      return optionValue;
    }
    
    // If backend returns optionId instead of label, try to map it
    final label = _getOptionLabel(questionId, optionValue);
    return label ?? optionValue;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        title: Text(
          'Xem đáp án',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: HMLoadingIndicator(size: 36, color: AppColors.primary),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(errorMessage!, style: AppTypography.bodyMedium),
            const SizedBox(height: 16),
            HMButton(text: 'Thử lại', onPressed: _loadReview),
          ],
        ),
      );
    }

    if (review == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(isDark),
          const SizedBox(height: 24),
          _buildStatsRow(isDark),
          const SizedBox(height: 24),
          Text(
            'Chi tiết đáp án',
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...review!.answers.asMap().entries.map((entry) {
            final index = entry.key;
            final answer = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildAnswerCard(index + 1, answer, isDark),
            );
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    final attempt = review!.attempt;
    final correctCount = review!.answers.where((a) => a.isCorrect).length;
    final totalCount = review!.answers.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: attempt.passed
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (attempt.passed
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444))
                .withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Score circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${attempt.scorePercent}%',
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attempt.testTitle ?? 'Đề thi ${attempt.level}',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Đúng $correctCount/$totalCount câu',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withAlpha(230),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              attempt.passed ? 'Đạt' : 'Chưa đạt',
              style: AppTypography.labelMedium.copyWith(
                color: attempt.passed
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    final attempt = review!.attempt;
    final correctCount = review!.answers.where((a) => a.isCorrect).length;
    final wrongCount = review!.answers.where((a) => !a.isCorrect).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            '$correctCount',
            'Câu đúng',
            const Color(0xFF10B981),
            isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            '$wrongCount',
            'Câu sai',
            const Color(0xFFEF4444),
            isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            _formatTimeSpent(attempt.timeSpent),
            'Thời gian',
            AppColors.primary,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
      String value, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color:
                  isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(int questionNumber, AnswerReview answer, bool isDark) {
    final isCorrect = answer.isCorrect;
    final didNotAnswer =
        answer.selectedOption.isEmpty || answer.selectedOption == '-';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCorrect
              ? const Color(0xFF10B981).withAlpha(80)
              : const Color(0xFFEF4444).withAlpha(80),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isCorrect
                  ? const Color(0xFF10B981).withAlpha(20)
                  : const Color(0xFFEF4444).withAlpha(20),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCorrect
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                  child: Center(
                    child: Icon(
                      isCorrect ? Icons.check_rounded : Icons.close_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Câu $questionNumber',
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (!isCorrect)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Đáp án: ${_getDisplayOption(answer.questionId, answer.correctOption)}',
                      style: AppTypography.labelMedium.copyWith(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Your answer
                Row(
                  children: [
                    Text(
                      'Bạn chọn: ',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: didNotAnswer
                            ? AppColors.surfaceVariant
                            : (isCorrect
                                ? const Color(0xFF10B981).withAlpha(26)
                                : const Color(0xFFEF4444).withAlpha(26)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        didNotAnswer 
                            ? 'Không chọn' 
                            : _getDisplayOption(answer.questionId, answer.selectedOption),
                        style: AppTypography.labelMedium.copyWith(
                          color: didNotAnswer
                              ? AppColors.textTertiary
                              : (isCorrect
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444)),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                if (answer.explanation != null &&
                    answer.explanation!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceVariantDark
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 18,
                          color: const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            answer.explanation!,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
