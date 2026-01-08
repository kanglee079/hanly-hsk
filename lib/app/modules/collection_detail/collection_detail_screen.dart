import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/vocab_model.dart';
import 'collection_detail_controller.dart';

/// Collection detail screen - shows vocabs in a collection
class CollectionDetailScreen extends GetView<CollectionDetailController> {
  const CollectionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: HMAppBar(
        title: controller.collection.value?.title ?? 'Collection',
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingState();
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return _buildErrorState(isDark);
        }

        return _buildContent(context, isDark);
      }),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: 6,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: HMSkeletonCard(height: 80),
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
              Icons.error_outline_rounded,
              size: 64,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage.value,
              style: AppTypography.bodyLarge.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            HMButton(
              text: 'Thử lại',
              onPressed: controller.refreshData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: _buildHeader(isDark),
        ),

        // Vocab list
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= controller.vocabs.length) {
                  // Loading more indicator
                  return Obx(() {
                    if (controller.isLoadingMore.value) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: HMLoadingIndicator.small()),
                      );
                    }
                    return const SizedBox.shrink();
                  });
                }

                final vocab = controller.vocabs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _VocabCard(
                    vocab: vocab,
                    isDark: isDark,
                    onTap: () => controller.openVocabDetail(vocab),
                  ),
                );
              },
              childCount: controller.vocabs.length + 1,
            ),
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    final collection = controller.collection.value;
    if (collection == null) return const SizedBox.shrink();

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: collection.badgeColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              collection.badge,
              style: AppTypography.labelSmall.copyWith(
                color: collection.badgeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            collection.title,
            style: AppTypography.displaySmall.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          // Subtitle
          Text(
            collection.subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _StatBadge(
                icon: Icons.library_books_outlined,
                value: '${collection.wordCount}',
                label: 'từ vựng',
                isDark: isDark,
              ),
              const SizedBox(width: 16),
              Obx(() {
                final pagination = controller.pagination.value;
                if (pagination != null) {
                  return _StatBadge(
                    icon: Icons.format_list_numbered,
                    value: '${pagination.page}/${pagination.totalPages}',
                    label: 'trang',
                    isDark: isDark,
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),

          const SizedBox(height: 24),

          // Divider
          Divider(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isDark;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _VocabCard extends StatelessWidget {
  final VocabModel vocab;
  final bool isDark;
  final VoidCallback onTap;

  const _VocabCard({
    required this.vocab,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Hanzi
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.getHskColor(vocab.levelInt).withAlpha(20),
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Center(
                child: Text(
                  vocab.hanzi.length > 2 
                      ? vocab.hanzi.substring(0, 2) 
                      : vocab.hanzi,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.getHskColor(vocab.levelInt),
                    fontWeight: FontWeight.w600,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vocab.hanzi,
                          style: AppTypography.titleMedium.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.getHskColor(vocab.levelInt).withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          vocab.level,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.getHskColor(vocab.levelInt),
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vocab.pinyin,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vocab.meaningVi,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Arrow
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

