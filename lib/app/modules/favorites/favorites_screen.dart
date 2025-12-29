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
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Padding(
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
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 200),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: const Icon(
                            Icons.delete_outline,
                            color: AppColors.white,
                            size: 28,
                          ),
                        );
                      },
                    ),
                  ),
                  onDismissed: (_) => controller.removeFavorite(vocab),
                  child: HMCard(
                    onTap: () => controller.openVocabDetail(vocab),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Animated hanzi container
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 400 + (index * 30)),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.7 + (value * 0.3),
                              child: Transform.rotate(
                                angle: (1 - value) * 0.1,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.getHskColor(vocab.levelInt).withAlpha(40),
                                  AppColors.getHskColor(vocab.levelInt).withAlpha(20),
                                ],
                              ),
                              borderRadius: AppSpacing.borderRadiusMd,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.getHskColor(vocab.levelInt).withAlpha(20),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                vocab.hanzi,
                                style: AppTypography.hanziSmall.copyWith(
                                  fontSize: 24,
                                  color: AppColors.getHskColor(vocab.levelInt),
                                  fontWeight: FontWeight.w600,
                                ),
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
                                vocab.pinyin,
                                style: AppTypography.pinyinSmall.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vocab.meaningVi,
                                style: AppTypography.bodyMedium.copyWith(
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
                        // Animated heart icon
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 500 + (index * 40)),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.5 + (value * 0.5),
                              child: Transform.rotate(
                                angle: (1 - value) * 0.2,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.favorite.withAlpha(15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: AppColors.favorite,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
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

