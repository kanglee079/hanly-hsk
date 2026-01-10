import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/strings_vi.dart';
import '../../../core/widgets/widgets.dart';
import '../explore_controller.dart';

/// Filter bottom sheet for Explore
class ExploreFilterSheet extends StatelessWidget {
  final ExploreController controller;

  const ExploreFilterSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word Type
          Text(
            S.wordType,
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  HMChip(
                    label: S.all,
                    isSelected: controller.selectedWordType.value.isEmpty,
                    onTap: () => controller.applyFilters(wordType: ''),
                  ),
                  ...controller.wordTypes.map((type) => HMChip(
                        label: type,
                        isSelected: controller.selectedWordType.value == type,
                        onTap: () => controller.applyFilters(wordType: type),
                      )),
                ],
              )),

          const SizedBox(height: 24),

          // Topics
          Text(
            S.topics,
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  HMChip(
                    label: S.all,
                    isSelected: controller.selectedTopic.value.isEmpty,
                    onTap: () => controller.applyFilters(topic: ''),
                  ),
                  ...controller.topics.map((topic) => HMChip(
                        label: topic,
                        isSelected: controller.selectedTopic.value == topic,
                        onTap: () => controller.applyFilters(topic: topic),
                      )),
                ],
              )),

          const SizedBox(height: 24),

          // Sort
          Text(
            S.sort,
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  HMChip(
                    label: S.sortByOrder,
                    isSelected: controller.sortBy.value == 'order_in_level',
                    onTap: () => controller.applyFilters(sort: 'order_in_level'),
                  ),
                  HMChip(
                    label: S.sortByFrequency,
                    isSelected: controller.sortBy.value == 'frequency_rank',
                    onTap: () => controller.applyFilters(sort: 'frequency_rank'),
                  ),
                  HMChip(
                    label: S.sortByDifficulty,
                    isSelected: controller.sortBy.value == 'difficulty_score',
                    onTap: () => controller.applyFilters(sort: 'difficulty_score'),
                  ),
                ],
              )),

          const SizedBox(height: 32),

          // Buttons
          Row(
            children: [
              Expanded(
                child: HMButton(
                  text: S.clearFilter,
                  variant: HMButtonVariant.outline,
                  onPressed: () {
                    controller.clearFilters();
                    Get.back();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HMButton(
                  text: S.applyFilter,
                  onPressed: () => Get.back(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
