import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/date_format.dart';
import '../../data/models/study_modes_model.dart';
import '../../services/tutorial_service.dart';
import 'learn_controller.dart';

/// Learn tab screen - matches design with dynamic data from API
class LearnScreen extends GetView<LearnController> {
  const LearnScreen({super.key});

  // Get registered keys from TutorialService
  GlobalKey get _quickReviewKey =>
      Get.find<TutorialService>().registerKey('learn_quick_review');
  GlobalKey get _studyModesKey =>
      Get.find<TutorialService>().registerKey('learn_study_modes');
  GlobalKey get _comprehensiveKey =>
      Get.find<TutorialService>().registerKey('learn_comprehensive');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          // Loading state
          if (controller.isLoading.value &&
              controller.studyModesData.value == null) {
            return _buildLoadingState(isDark);
          }

          // Error state
          if (controller.errorMessage.value.isNotEmpty &&
              controller.studyModesData.value == null) {
            return _buildErrorState(isDark);
          }

          // Content
          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== HEADER =====
                    _buildHeader(isDark),

                    Padding(
                      padding: AppSpacing.screenPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // ===== ÔN TẬP NHANH =====
                          Showcase(
                            key: _quickReviewKey,
                            title: 'Ôn tập nhanh',
                            description:
                                'Xem nhanh các từ cần ôn hôm nay và bắt đầu ôn ngay!',
                            overlayOpacity: 0.7,
                            targetShapeBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: _buildQuickReviewBanner(isDark),
                          ),

                          const SizedBox(height: 12),

                          // ===== CHẾ ĐỘ HỌC - GRID 2x2 =====
                          Showcase(
                            key: _studyModesKey,
                            title: 'Chế độ học',
                            description:
                                'Chọn chế độ học phù hợp: Flashcard, Trắc nghiệm, Viết, Nghe.',
                            overlayOpacity: 0.7,
                            targetShapeBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: _buildModeGrid(isDark, constraints),
                          ),

                          const SizedBox(height: 12),

                          // ===== ÔN TẬP TỔNG HỢP =====
                          Showcase(
                            key: _comprehensiveKey,
                            title: 'Ôn tập tổng hợp',
                            description:
                                'Kết hợp tất cả các chế độ để ôn tập toàn diện.',
                            overlayOpacity: 0.7,
                            targetShapeBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: _buildComprehensiveCard(isDark),
                          ),

                          // Bottom padding for glass nav bar
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Header skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              HMSkeleton(width: 150, height: 14),
              HMSkeleton(
                width: 60,
                height: 36,
                borderRadius: BorderRadius.circular(20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          HMSkeleton(width: 180, height: 28),
          const SizedBox(height: 24),
          // Quick review skeleton
          HMSkeleton(
            width: double.infinity,
            height: 72,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 16),
          // Grid skeleton
          Row(
            children: [
              Expanded(
                child: HMSkeleton(
                  height: 160,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HMSkeleton(
                  height: 160,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: HMSkeleton(
                  height: 160,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HMSkeleton(
                  height: 160,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Comprehensive skeleton
          HMSkeleton(
            width: double.infinity,
            height: 140,
            borderRadius: BorderRadius.circular(24),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage.value,
              style: AppTypography.bodyLarge.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            HMButton(
              text: 'Thử lại',
              onPressed: controller.refresh,
              icon: const Icon(
                CupertinoIcons.refresh,
                size: 18,
                color: Colors.white,
              ),
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: AppSpacing.screenPadding.copyWith(top: 8, bottom: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title + Date stacked
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormatUtil.formatDayFull(DateTime.now()).toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiary,
                    letterSpacing: 0.8,
                    fontSize: 10,
                  ),
                ),
                Text(
                  'Chế độ học',
                  style: AppTypography.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Streak badge
          _buildStreakBadge(isDark),
        ],
      ),
    );
  }

  Widget _buildStreakBadge(bool isDark) {
    return HMStreakWidget(
      streak: controller.streak,
      streakRank: controller.streakRank,
      hasStudiedToday: controller.hasStudiedToday,
      isAtRisk: !controller.hasStudiedToday && controller.streak > 0,
      onTap: controller.showStreakDetails,
      size: StreakWidgetSize.small,
      showMessage: false,
    );
  }

  Widget _buildQuickReviewBanner(bool isDark) {
    final quickReview = controller.quickReview;
    final isAvailable = quickReview?.available ?? false;

    return Obx(() {
      final isLoadingWords = controller.isLoadingWords.value;

      return GestureDetector(
        onTap: isLoadingWords ? null : controller.startQuickReview,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceVariantDark
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppColors.borderDark
                  : AppColors.primary.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Lightning icon in blue circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.bolt, color: AppColors.white, size: 24),
              ),
              const SizedBox(width: 14),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Ôn tập nhanh',
                          style: AppTypography.titleMedium.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (quickReview != null &&
                            quickReview.wordCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${quickReview.wordCount}',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAvailable
                          ? 'Quick Review • ~${quickReview?.estimatedMinutes ?? 3}m'
                          : 'Không có từ cần ôn',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Play button or loading
              if (isLoadingWords)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: HMLoadingIndicator.small(color: AppColors.primary),
                )
              else
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? (isDark
                              ? AppColors.textPrimaryDark.withValues(alpha: 0.1)
                              : AppColors.textPrimary.withValues(alpha: 0.08))
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAvailable
                        ? Icons.play_arrow_rounded
                        : Icons.check_circle_outline,
                    color: isAvailable
                        ? (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary)
                        : AppColors.success,
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildModeGrid(bool isDark, BoxConstraints constraints) {
    // Calculate card dimensions
    final availableWidth = constraints.maxWidth - 40; // padding
    final cardWidth = (availableWidth - 12) / 2;
    final cardHeight = cardWidth * 1.05;

    final modes = controller.mainStudyModes;

    // Fallback modes if API hasn't returned yet
    if (modes.isEmpty) {
      return _buildStaticModeGrid(isDark, cardHeight);
    }

    // Build dynamic grid from API
    return Column(
      children: [
        // Row 1
        Row(
          children: [
            if (modes.isNotEmpty)
              Expanded(
                child: SizedBox(
                  height: cardHeight,
                  child: _DynamicModeCard(
                    mode: modes[0],
                    onTap: () => controller.startModeById(modes[0].id),
                    isDark: isDark,
                    isLoading: controller.isLoadingWords.value,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            if (modes.length > 1)
              Expanded(
                child: SizedBox(
                  height: cardHeight,
                  child: _DynamicModeCard(
                    mode: modes[1],
                    onTap: () => controller.startModeById(modes[1].id),
                    isDark: isDark,
                    isLoading: controller.isLoadingWords.value,
                  ),
                ),
              )
            else
              const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2
        Row(
          children: [
            if (modes.length > 2)
              Expanded(
                child: SizedBox(
                  height: cardHeight,
                  child: _DynamicModeCard(
                    mode: modes[2],
                    onTap: () => controller.startModeById(modes[2].id),
                    isDark: isDark,
                    isLoading: controller.isLoadingWords.value,
                  ),
                ),
              )
            else
              const Expanded(child: SizedBox()),
            const SizedBox(width: 12),
            if (modes.length > 3)
              Expanded(
                child: SizedBox(
                  height: cardHeight,
                  child: _DynamicModeCard(
                    mode: modes[3],
                    onTap: () => controller.startModeById(modes[3].id),
                    isDark: isDark,
                    isLoading: controller.isLoadingWords.value,
                  ),
                ),
              )
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildStaticModeGrid(bool isDark, double cardHeight) {
    // Static fallback while loading
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: _ModeCard(
                  icon: Icons.sort_rounded,
                  iconBgColor: const Color(0xFFFFF8E1),
                  iconColor: const Color(0xFFFF8F00),
                  title: 'Ghép từ',
                  subtitle: 'Sắp xếp từ thành câu',
                  duration: '~5m',
                  onTap: () => controller.startMode(LearnMode.srsVocabulary),
                  isDark: isDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: _ModeCard(
                  icon: Icons.headphones_rounded,
                  iconBgColor: const Color(0xFFE3F2FD),
                  iconColor: const Color(0xFF2196F3),
                  title: 'Luyện Nghe',
                  subtitle: 'Nghe & chọn đáp án',
                  duration: '~5m',
                  onTap: () => controller.startMode(LearnMode.listening),
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: _ModeCard(
                  icon: Icons.record_voice_over_rounded,
                  iconBgColor: const Color(0xFFE8F5E9),
                  iconColor: const Color(0xFF4CAF50),
                  title: 'Phát âm',
                  subtitle: 'Luyện nói',
                  duration: '~5m',
                  onTap: () => controller.startMode(LearnMode.pronunciation),
                  isDark: isDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: _ModeCard(
                  icon: Icons.hub_rounded,
                  iconBgColor: const Color(0xFFF3E5F5),
                  iconColor: const Color(0xFF9C27B0),
                  title: 'Ghép Cặp',
                  subtitle: 'Ghép từ với nghĩa',
                  duration: '~8m',
                  onTap: () => controller.startMode(LearnMode.matching),
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComprehensiveCard(bool isDark) {
    final mode = controller.comprehensiveMode;

    return Obx(() {
      final isLoading = controller.isLoadingWords.value;

      return GestureDetector(
        onTap: isLoading
            ? null
            : () => controller.startMode(LearnMode.comprehensive),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF2D2B55), const Color(0xFF1E1B3A)]
                  : [const Color(0xFFF5F3FF), const Color(0xFFEDE9FE)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF3D3A6D) : const Color(0xFFDDD6FE),
            ),
          ),
          child: Row(
            children: [
              // Left content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode?.name ?? 'Ôn tập tổng hợp',
                      style: AppTypography.titleMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode?.nameEn ?? 'Comprehensive Review',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Bottom row: duration badge + start button
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Duration badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Text(
                            '~${mode?.estimatedMinutes ?? 15} phút',
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Start button
                        if (isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: HMLoadingIndicator.small(color: AppColors.primary),
                          )
                        else
                          Text(
                            'Bắt đầu →',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right: 3D-like icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Dynamic mode card - builds from API data
class _DynamicModeCard extends StatelessWidget {
  final StudyModeModel mode;
  final VoidCallback onTap;
  final bool isDark;
  final bool isLoading;

  const _DynamicModeCard({
    required this.mode,
    required this.onTap,
    required this.isDark,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getModeColors(mode.id);

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Icon + Duration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon with colored background
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? colors.iconColor.withValues(alpha: 0.15)
                        : colors.bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _buildModeIcon(
                      mode.id,
                      mode.icon,
                      colors.iconColor,
                    ),
                  ),
                ),
                // Duration badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceVariantDark
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '~${mode.estimatedMinutes}m',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Title - Use mapped display names
            Text(
              _getDisplayName(mode.id),
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Subtitle - Use mapped subtitles
            Text(
              _getDisplaySubtitle(mode.id),
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Show word count if available
            if (mode.wordCount > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${mode.wordCount} từ',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeIcon(String modeId, String iconEmoji, Color iconColor) {
    // Use Material icons based on mode
    IconData iconData;
    switch (modeId) {
      case 'srs_vocabulary':
      case 'sentence_formation':
      case 'sentence_reorder':
        iconData = Icons.sort_rounded; // Sentence reorder icon for Ghép từ
        break;
      case 'listening':
        iconData = Icons.headphones_rounded;
        break;
      case 'writing':
      case 'pronunciation':
        iconData = Icons.record_voice_over_rounded;
        break;
      case 'matching':
        iconData = Icons.hub_rounded;
        break;
      default:
        iconData = Icons.school;
    }
    return Icon(iconData, color: iconColor, size: 24);
  }

  /// Get display name for mode (override API names)
  String _getDisplayName(String modeId) {
    switch (modeId) {
      case 'srs_vocabulary':
      case 'sentence_formation':
      case 'sentence_reorder':
        return 'Ghép từ'; // Sentence Formation - replaced Flashcard
      case 'listening':
        return 'Luyện Nghe';
      case 'writing':
      case 'pronunciation':
        return 'Phát âm';
      case 'matching':
        return 'Ghép Cặp'; // Word Matching
      case 'comprehensive':
        return 'Ôn tập tổng hợp';
      default:
        return modeId;
    }
  }

  /// Get display subtitle for mode
  String _getDisplaySubtitle(String modeId) {
    switch (modeId) {
      case 'srs_vocabulary':
      case 'sentence_formation':
      case 'sentence_reorder':
        return 'Sắp xếp từ thành câu'; // Updated subtitle
      case 'listening':
        return 'Nghe & chọn đáp án';
      case 'writing':
      case 'pronunciation':
        return 'Luyện nói';
      case 'matching':
        return 'Ghép từ với nghĩa'; // Updated subtitle
      case 'comprehensive':
        return 'Comprehensive Review';
      default:
        return '';
    }
  }

  _ModeColors _getModeColors(String modeId) {
    switch (modeId) {
      case 'srs_vocabulary':
      case 'sentence_formation':
      case 'sentence_reorder':
        // Orange/Amber for Ghép từ (Sentence Formation)
        return _ModeColors(
          bgColor: const Color(0xFFFFF8E1), // Amber light
          iconColor: const Color(0xFFFF8F00), // Amber
        );
      case 'listening':
        // Blue for Listening
        return _ModeColors(
          bgColor: const Color(0xFFE3F2FD),
          iconColor: const Color(0xFF2196F3),
        );
      case 'writing':
      case 'pronunciation':
        // Green for Pronunciation
        return _ModeColors(
          bgColor: const Color(0xFFE8F5E9),
          iconColor: const Color(0xFF4CAF50),
        );
      case 'matching':
        // Purple for Matching
        return _ModeColors(
          bgColor: const Color(0xFFF3E5F5),
          iconColor: const Color(0xFF9C27B0),
        );
      default:
        return _ModeColors(
          bgColor: const Color(0xFFE3F2FD),
          iconColor: AppColors.primary,
        );
    }
  }
}

class _ModeColors {
  final Color bgColor;
  final Color iconColor;

  _ModeColors({required this.bgColor, required this.iconColor});
}

/// Static mode card widget - for fallback
class _ModeCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String duration;
  final VoidCallback onTap;
  final bool isDark;

  const _ModeCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Icon + Duration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon with colored background
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? iconColor.withValues(alpha: 0.15)
                        : iconBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                // Duration badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceVariantDark
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    duration,
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Title
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Subtitle
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
