import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/collection_model.dart';
import 'collections_controller.dart';

/// All Collections screen with grid layout and level filtering
class CollectionsScreen extends GetView<CollectionsController> {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: HMAppBar(
        showBackButton: true,
        title: 'Bộ sưu tập',
      ),
      body: Column(
        children: [
          // Level filter tabs
          _buildLevelTabs(isDark),

          // Collections grid
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildLoadingSkeleton();
              }

              if (controller.filteredCollections.isEmpty) {
                return HMEmptyState(
                  icon: Icons.collections_bookmark_outlined,
                  title: 'Không có bộ sưu tập',
                  description: 'Chưa có bộ sưu tập nào cho cấp độ này',
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refresh,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: controller.filteredCollections.length,
                  itemBuilder: (context, index) {
                    final collection = controller.filteredCollections[index];
                    return _CollectionGridCard(
                      collection: collection,
                      isDark: isDark,
                      onTap: () => controller.openCollection(collection),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelTabs(bool isDark) {
    final levels = ['Tất cả', 'HSK1', 'HSK2', 'HSK3', 'HSK4', 'HSK5', 'HSK6'];

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Obx(() => ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final level = levels[index];
          final isSelected = controller.selectedLevel.value == (index == 0 ? '' : level);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => controller.filterByLevel(index == 0 ? '' : level),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant),
                  borderRadius: BorderRadius.circular(20),
                  border: !isSelected
                      ? Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                        )
                      : null,
                ),
                child: Text(
                  level,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      )),
    );
  }

  Widget _buildLoadingSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => HMSkeleton(
        width: double.infinity,
        height: double.infinity,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _CollectionGridCard extends StatelessWidget {
  final CollectionModel collection;
  final bool isDark;
  final VoidCallback onTap;

  const _CollectionGridCard({
    required this.collection,
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
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
            // Badge with level
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: collection.badgeColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    collection.badge,
                    style: AppTypography.labelSmall.copyWith(
                      color: collection.badgeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    collection.level ?? 'HSK',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Title
            Text(
              collection.title,
              style: AppTypography.titleSmall.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Subtitle
            Text(
              collection.subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Word count & progress
            Row(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 14,
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${collection.wordCount} từ',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
