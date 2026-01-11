import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../services/tutorial_service.dart';
import 'hsk_exam_controller.dart';

/// HSK Exam Prep main screen - Professional & Clean design
class HskExamScreen extends GetView<HskExamController> {
  const HskExamScreen({super.key});

  // Get registered keys from TutorialService
  GlobalKey get _statsKey =>
      Get.find<TutorialService>().registerKey('hsk_stats');
  GlobalKey get _levelSelectKey =>
      Get.find<TutorialService>().registerKey('hsk_level_select');
  GlobalKey get _practiceKey =>
      Get.find<TutorialService>().registerKey('hsk_practice');
  GlobalKey get _historyKey =>
      Get.find<TutorialService>().registerKey('hsk_history');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(isDark),

                Padding(
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Stats overview
                      Showcase(
                        key: _statsKey,
                        title: 'Thống kê thi HSK',
                        description:
                            'Xem số đề đã làm, điểm trung bình và tì lệ đậu.',
                        overlayOpacity: 0.7,
                        targetShapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Obx(() => _buildStatsRow(isDark)),
                      ),

                      const SizedBox(height: 20),

                      // Level selector
                      Showcase(
                        key: _levelSelectKey,
                        title: 'Chọn cấp độ',
                        description:
                            'Chọn cấp HSK bạn muốn thi thử từ HSK1 đến HSK6.',
                        overlayOpacity: 0.7,
                        targetShapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildLevelSelector(isDark),
                      ),

                      const SizedBox(height: 20),

                      // Mock tests section
                      Showcase(
                        key: _practiceKey,
                        title: 'Làm bài thi thử',
                        description:
                            'Đề thi mô phỏng thật với các dạng câu hỏi chuẩn HSK.',
                        overlayOpacity: 0.7,
                        targetShapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildMockTestsSection(isDark),
                      ),

                      const SizedBox(height: 20),

                      // Tips section
                      _buildTipsSection(isDark),

                      const SizedBox(height: 100), // Bottom nav padding
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header - clean style matching Today/Learn tabs
  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ôn thi HSK',
                style: AppTypography.headlineSmall.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Luyện đề & chuẩn bị kỳ thi',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          // History button
          Showcase(
            key: _historyKey,
            title: 'Lịch sử thi',
            description:
                'Xem lại các bài thi đã làm và phân tích điểm mạnh/yếu.',
            overlayOpacity: 0.7,
            targetShapeBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: GestureDetector(
              onTap: controller.viewHistory,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Lịch sử',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Stats row - simple and clean without icons
  Widget _buildStatsRow(bool isDark) {
    return HMCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _buildStatItem(
            value: '${controller.totalAttempts}',
            label: 'Lần thi',
            isDark: isDark,
          ),
          _buildStatDivider(isDark),
          _buildStatItem(
            value: '${controller.averageScore}%',
            label: 'TB điểm',
            isDark: isDark,
          ),
          _buildStatDivider(isDark),
          _buildStatItem(
            value: '${controller.bestScore}%',
            label: 'Cao nhất',
            isDark: isDark,
            isHighlight: true,
          ),
          _buildStatDivider(isDark),
          _buildStatItem(
            value: '${controller.passRate}%',
            label: 'Tỉ lệ đạt',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required bool isDark,
    bool isHighlight = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: isHighlight
                  ? AppColors.primary
                  : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isDark ? AppColors.borderDark : AppColors.border,
    );
  }

  /// Level selector - horizontal chips
  Widget _buildLevelSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cấp độ',
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildLevelChip('all', 'Tất cả', isDark),
              ...controller.availableLevels.map(
                (level) => _buildLevelChip(level, level, isDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelChip(String value, String label, bool isDark) {
    return Obx(() {
      final isSelected = controller.selectedLevel.value == value;
      return GestureDetector(
        onTap: () => controller.selectLevel(value),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariant),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      );
    });
  }

  /// Mock tests section
  Widget _buildMockTestsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Đề thi thử',
              style: AppTypography.titleSmall.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: controller.viewAllTests,
              child: Text(
                'Xem tất cả',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Mock test cards
        Obx(() {
          if (controller.isLoadingTests.value) {
            return _buildLoadingSkeleton(isDark);
          }

          final tests = controller.tests;
          if (tests.isEmpty) {
            return _buildEmptyState('Chưa có đề thi cho cấp độ này', isDark);
          }

          return Column(
            children: tests.take(5).map((test) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildMockTestCard(
                  testId: test.id,
                  title: test.title,
                  level: test.level,
                  questions: test.totalQuestions,
                  duration: test.totalDuration,
                  bestScore: test.bestScore,
                  isDark: isDark,
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return Column(
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: HMSkeleton(
            width: double.infinity,
            height: 76,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Text(
        message,
        style: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildMockTestCard({
    required String testId,
    required String title,
    required String level,
    required int questions,
    required int duration,
    required int? bestScore,
    required bool isDark,
  }) {
    return HMCard(
      onTap: () => controller.startMockTest(testId),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Level badge - clean gradient
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getLevelColor(level),
                  _getLevelColor(level).withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                level.replaceAll('HSK', ''),
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '$questions câu • $duration phút${bestScore != null ? ' • Cao nhất: $bestScore%' : ''}',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Arrow
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiary,
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'HSK1':
        return const Color(0xFF22C55E);
      case 'HSK2':
        return const Color(0xFF84CC16);
      case 'HSK3':
        return const Color(0xFFEAB308);
      case 'HSK4':
        return const Color(0xFFF97316);
      case 'HSK5':
        return const Color(0xFFEC4899);
      case 'HSK6':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.primary;
    }
  }

  /// Tips section - clean list
  Widget _buildTipsSection(bool isDark) {
    final tips = [
      'Làm quen với format đề thi trước khi thi thật',
      'Phần nghe: Đọc câu hỏi trước khi audio phát',
      'Phần đọc: Đọc lướt câu hỏi trước, rồi tìm đáp án',
      'Không dành quá nhiều thời gian cho 1 câu',
    ];

    return HMCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mẹo thi HSK',
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => _buildTipItem(tip, isDark)),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
