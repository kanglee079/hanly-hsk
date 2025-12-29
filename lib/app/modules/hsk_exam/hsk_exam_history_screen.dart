import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../core/constants/toast_messages.dart';
import '../../core/utils/date_format.dart';
import '../../data/models/hsk_exam_model.dart';
import '../../data/repositories/hsk_exam_repo.dart';
import '../../routes/app_routes.dart';

/// HSK Exam history screen
class HskExamHistoryScreen extends StatefulWidget {
  const HskExamHistoryScreen({super.key});

  @override
  State<HskExamHistoryScreen> createState() => _HskExamHistoryScreenState();
}

class _HskExamHistoryScreenState extends State<HskExamHistoryScreen> {
  final HskExamRepo _examRepo = Get.find<HskExamRepo>();

  List<ExamAttemptSummary> attempts = [];
  bool isLoading = true;
  String selectedLevel = 'all';

  final levels = ['all', 'HSK1', 'HSK2', 'HSK3', 'HSK4', 'HSK5', 'HSK6'];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => isLoading = true);
    try {
      attempts = await _examRepo.getHistory(
        level: selectedLevel == 'all' ? null : selectedLevel,
      );
    } catch (e) {
      HMToast.error(ToastMessages.examHistoryLoadError);
    }
    setState(() => isLoading = false);
  }

  void _selectLevel(String level) {
    if (selectedLevel != level) {
      setState(() => selectedLevel = level);
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(isDark),

            // Level filter
            _buildLevelFilter(isDark),

            // Content
            Expanded(
              child: isLoading
                  ? _buildLoadingState(isDark)
                  : attempts.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildHistoryList(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Lịch sử thi',
            style: AppTypography.headlineSmall.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelFilter(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: AppSpacing.screenPadding.copyWith(top: 0, bottom: 16),
      child: Row(
        children: levels.map((level) {
          final isSelected = selectedLevel == level;
          final label = level == 'all' ? 'Tất cả' : level;
          return GestureDetector(
            onTap: () => _selectLevel(level),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: List.generate(5, (_) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HMSkeleton(
              width: double.infinity,
              height: 90,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        }),
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
              Icons.history_rounded,
              size: 64,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có lịch sử thi',
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hoàn thành một bài thi để xem kết quả ở đây',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(bool isDark) {
    return ListView.builder(
      padding: AppSpacing.screenPadding.copyWith(top: 0),
      itemCount: attempts.length,
      itemBuilder: (context, index) {
        final attempt = attempts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildAttemptCard(attempt, isDark),
        );
      },
    );
  }

  Widget _buildAttemptCard(ExamAttemptSummary attempt, bool isDark) {
    return HMCard(
      onTap: () {
        Get.toNamed(Routes.hskExamReview, arguments: {
          'testId': attempt.testId,
          'attemptId': attempt.id,
        });
      },
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Score indicator
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: attempt.passed
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
            ),
            child: Center(
              child: Text(
                '${attempt.scorePercent}%',
                style: AppTypography.titleMedium.copyWith(
                  color: attempt.passed ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attempt.testTitle ?? 'Đề thi ${attempt.level}',
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${attempt.level} • ${attempt.timeSpentFormatted} • ${DateFormatUtil.formatRelative(attempt.completedAt)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: attempt.passed
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              attempt.passed ? 'Đạt' : 'Chưa đạt',
              style: AppTypography.labelSmall.copyWith(
                color: attempt.passed ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

