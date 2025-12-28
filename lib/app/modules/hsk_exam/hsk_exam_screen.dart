import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import 'hsk_exam_controller.dart';

/// HSK Exam Prep main screen - Professional & Clean design
class HskExamScreen extends GetView<HskExamController> {
  const HskExamScreen({super.key});

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
                // Header - clean and minimal like other tabs
                _buildHeader(isDark),

                Padding(
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Stats overview - compact style
                      Obx(() => _buildStatsRow(isDark)),

                      const SizedBox(height: 20),

                      // Level selector
                      _buildLevelSelector(isDark),

                      const SizedBox(height: 20),

                      // Mock tests section
                      _buildMockTestsSection(isDark),

                      const SizedBox(height: 20),

                      // Practice section
                      _buildPracticeSection(isDark),

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
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Luyện đề & chuẩn bị kỳ thi',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          // History button - minimal style
          GestureDetector(
            onTap: controller.viewHistory,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Lịch sử',
                style: AppTypography.labelMedium.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
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
                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
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
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () {},
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
                  isPremium: test.isPremium,
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
    required bool isPremium,
    required int? bestScore,
    required bool isDark,
  }) {
    final isLocked = isPremium && !controller.isPremium;

    return HMCard(
      onTap: isLocked ? controller.showPremiumUpgrade : () => controller.startMockTest(testId),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.titleSmall.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPremium)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'PRO',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$questions câu • $duration phút${bestScore != null ? ' • Cao nhất: $bestScore%' : ''}',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Arrow
          Icon(
            isLocked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
            size: 20,
            color: isLocked
                ? AppColors.warning
                : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
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

  /// Practice section - grid of practice types
  Widget _buildPracticeSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Luyện tập theo phần',
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPracticeCard(
                title: 'Nghe hiểu',
                subtitle: 'Luyện nghe đề thi',
                color: const Color(0xFF3B82F6),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPracticeCard(
                title: 'Đọc hiểu',
                subtitle: 'Luyện đọc đề thi',
                color: const Color(0xFF22C55E),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPracticeCard({
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return HMCard(
      onTap: () {},
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
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
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
