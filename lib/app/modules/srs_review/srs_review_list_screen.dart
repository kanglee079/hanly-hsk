import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/vocab_model.dart';
import '../../routes/app_routes.dart';
import 'srs_review_list_controller.dart';

/// SRS Review List Screen - Shows list of words due for review
class SrsReviewListScreen extends GetView<SrsReviewListController> {
  const SrsReviewListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(isDark),

            // Content
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const HMLoadingContent(
                    message: 'Đang tải danh sách ôn tập...',
                    icon: Icons.schedule_rounded,
                  );
                }

                if (controller.reviewQueue.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                return RefreshIndicator(
                  onRefresh: controller.refresh,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: controller.reviewQueue.length,
                    itemBuilder: (context, index) {
                      final vocab = controller.reviewQueue[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _VocabReviewCard(
                          vocab: vocab,
                          onTap: () => controller.openWordDetail(vocab),
                          isDark: isDark,
                        ),
                      );
                    },
                  ),
                );
              }),
            ),

            // Bottom action button
            _buildBottomButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                      'Cần ôn hôm nay (${controller.reviewQueue.length})',
                      style: AppTypography.titleLarge.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                const SizedBox(height: 2),
                Text(
                  'Ôn tập để củng cố kiến thức',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Không có từ nào cần ôn!',
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn đã hoàn thành tất cả ôn tập hôm nay.\nHãy học thêm từ mới!',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            HMButton(
              text: 'Học từ mới',
              onPressed: () {
                Get.back();
                Get.toNamed(Routes.practice, arguments: {'mode': 'learn_new'});
              },
              variant: HMButtonVariant.outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
      ),
      child: SafeArea(
        top: false,
        child: Obx(() {
          final count = controller.reviewQueue.length;

          return Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF818CF8)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: count > 0
                    ? () {
                        HapticFeedback.mediumImpact();
                        controller.startReview();
                      }
                    : null,
                child: Center(
                  child: controller.isStartingReview.value
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: HMLoadingIndicator.small(color: Colors.white),
                        )
                      : Text(
                          'Ôn tập $count từ SRS',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Vocab card for review list - matches design exactly
class _VocabReviewCard extends StatelessWidget {
  final VocabModel vocab;
  final VoidCallback onTap;
  final bool isDark;

  const _VocabReviewCard({
    required this.vocab,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Determine urgency level based on how overdue the word is
    final now = DateTime.now();
    final dueDate = vocab.dueDate;
    final daysOverdue = dueDate != null 
        ? now.difference(dueDate).inDays 
        : 0;

    Color urgencyColor;
    String urgencyLabel;
    if (daysOverdue > 3) {
      urgencyColor = AppColors.error;
      urgencyLabel = 'Cần ôn';
    } else {
      urgencyColor = AppColors.warning;
      urgencyLabel = 'Đến hạn';
    }
    
    final String timeLabel = _getDueDateText(dueDate, daysOverdue);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark 
                ? AppColors.borderDark 
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            // Hanzi - simple text, no box
            SizedBox(
              width: 56,
              child: Text(
                vocab.hanzi,
                style: AppTypography.hanziLarge.copyWith(
                  fontSize: 32,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pinyin + HSK badge row
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          vocab.pinyin,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(40),
                          ),
                        ),
                        child: Text(
                          vocab.level,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Meaning
                  Text(
                    vocab.meaningVi,
                    style: AppTypography.titleSmall.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Urgency indicator column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Urgency badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: urgencyColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '!',
                        style: TextStyle(
                          color: urgencyColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        urgencyLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: urgencyColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Time label
                Text(
                  timeLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDueDateText(DateTime? dueDate, int daysOverdue) {
    if (dueDate == null) return 'Hôm nay';
    if (daysOverdue > 1) return 'Quá hạn $daysOverdue ngày';
    if (daysOverdue == 1) return 'Quá hạn 1 ngày';
    return 'Hôm nay';
  }
}

