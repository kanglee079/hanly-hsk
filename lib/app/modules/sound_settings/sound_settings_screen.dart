import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import 'sound_settings_controller.dart';

class SoundSettingsScreen extends GetView<SoundSettingsController> {
  const SoundSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: HMAppBar(
        title: 'Âm thanh & Rung',
        showBackButton: true,
        actions: [
          Obx(() => controller.isSaving.value
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          const SizedBox(height: 8),

          // Sound Effects
          HMCard(
            padding: const EdgeInsets.all(16),
            child: Obx(() => Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: controller.soundEnabled.value
                        ? AppColors.primary.withAlpha(25)
                        : AppColors.textTertiary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    controller.soundEnabled.value
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    size: 24,
                    color: controller.soundEnabled.value
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hiệu ứng âm thanh',
                        style: AppTypography.bodyLarge.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Phát âm khi trả lời đúng/sai',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: controller.soundEnabled.value,
                  activeTrackColor: AppColors.primary,
                  onChanged: controller.toggleSound,
                ),
              ],
            )),
          ),

          const SizedBox(height: 12),

          // Haptics
          HMCard(
            padding: const EdgeInsets.all(16),
            child: Obx(() => Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: controller.hapticsEnabled.value
                        ? AppColors.primary.withAlpha(25)
                        : AppColors.textTertiary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.vibration_rounded,
                    size: 24,
                    color: controller.hapticsEnabled.value
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rung phản hồi',
                        style: AppTypography.bodyLarge.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rung nhẹ khi tương tác',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: controller.hapticsEnabled.value,
                  activeTrackColor: AppColors.primary,
                  onChanged: controller.toggleHaptics,
                ),
              ],
            )),
          ),

          const SizedBox(height: 12),

          // Vietnamese Support
          HMCard(
            padding: const EdgeInsets.all(16),
            child: Obx(() => Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: controller.vietnameseSupport.value
                        ? AppColors.primary.withAlpha(25)
                        : AppColors.textTertiary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.translate_rounded,
                    size: 24,
                    color: controller.vietnameseSupport.value
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hỗ trợ tiếng Việt',
                        style: AppTypography.bodyLarge.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hiển thị nghĩa tiếng Việt',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: controller.vietnameseSupport.value,
                  activeTrackColor: AppColors.primary,
                  onChanged: controller.toggleVietnamese,
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }
}
