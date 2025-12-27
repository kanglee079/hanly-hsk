import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/strings_vi.dart';
import '../../core/widgets/widgets.dart';
import 'favorites_controller.dart';

/// Favorites screen
class FavoritesScreen extends GetView<FavoritesController> {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: const HMAppBar(title: S.favorites),
      body: Obx(() {
        if (controller.isLoading.value) {
          return ListView.builder(
            padding: AppSpacing.screenPadding,
            itemCount: 5,
            itemBuilder: (context, index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: HMSkeletonCard(height: 80),
            ),
          );
        }

        if (controller.favorites.isEmpty) {
          return HMEmptyState(
            icon: Icons.favorite_border_rounded,
            title: S.noFavorites,
            description: S.noFavoritesDesc,
          );
        }

        return ListView.builder(
          padding: AppSpacing.screenPadding,
          itemCount: controller.favorites.length,
          itemBuilder: (context, index) {
            final vocab = controller.favorites[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
                key: Key(vocab.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: AppSpacing.borderRadiusLg,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.white,
                  ),
                ),
                onDismissed: (_) => controller.removeFavorite(vocab),
                child: HMCard(
                  onTap: () => controller.openVocabDetail(vocab),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.getHskColor(vocab.levelInt).withAlpha(25),
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                        child: Center(
                          child: Text(
                            vocab.hanzi,
                            style: AppTypography.hanziSmall.copyWith(
                              fontSize: 20,
                              color: AppColors.getHskColor(vocab.levelInt),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vocab.pinyin,
                              style: AppTypography.pinyinSmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                              ),
                            ),
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
                      const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.favorite,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

