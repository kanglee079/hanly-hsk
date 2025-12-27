import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../core/constants/strings_vi.dart';
import 'delete_account_controller.dart';

/// Delete Account confirmation screen
class DeleteAccountScreen extends GetView<DeleteAccountController> {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.all(8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Warning icon
                    _buildWarningIcon(isDark),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      S.deleteAccountTitle,
                      style: AppTypography.headlineLarge.copyWith(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Description
                    Text(
                      S.deleteAccountDescription,
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // What you will lose section
                    _buildWhatYouWillLose(isDark),

                    const SizedBox(height: 32),

                    // Confirmation input
                    _buildConfirmationInput(isDark),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            _buildBottomButtons(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningIcon(bool isDark) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.error.withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.15),
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.warning_rounded,
            color: AppColors.error,
            size: 36,
          ),
        ),
      ),
    );
  }

  Widget _buildWhatYouWillLose(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.whatYouWillLose,
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),

          // SRS Progress
          Obx(() => _buildLossItem(
                icon: Icons.trending_up_rounded,
                iconColor: AppColors.error,
                title: S.srsProgress,
                subtitle: S.srsProgressDesc(controller.reviewCount.value),
                isDark: isDark,
              )),

          _buildDivider(isDark),

          // Saved Collections
          Obx(() => _buildLossItem(
                icon: Icons.folder_outlined,
                iconColor: AppColors.error,
                title: S.savedCollections,
                subtitle: S.savedCollectionsDesc(controller.deckCount.value),
                isDark: isDark,
              )),

          _buildDivider(isDark),

          // Premium Status
          Obx(() => _buildLossItem(
                icon: Icons.workspace_premium_outlined,
                iconColor: AppColors.error,
                title: S.premiumStatus,
                subtitle: controller.isPremium.value
                    ? S.premiumStatusDesc
                    : S.noPremiumStatus,
                isDark: isDark,
              )),
        ],
      ),
    );
  }

  Widget _buildLossItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
      ),
    );
  }

  Widget _buildConfirmationInput(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.typeDeleteToConfirm,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        HMTextField(
          controller: controller.confirmTextController,
          hintText: 'DELETE',
          onChanged: (_) => controller.validateInput(),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(Get.context!).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.background,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Delete button
          Obx(() => HMButton(
                text: S.permanentlyDelete,
                icon: const Icon(Icons.close, size: 18, color: AppColors.white),
                onPressed: controller.canDelete.value
                    ? controller.confirmDelete
                    : null,
                isLoading: controller.isDeleting.value,
                variant: HMButtonVariant.danger,
              )),

          const SizedBox(height: 12),

          // Keep account button
          HMButton(
            text: S.keepMyAccount,
            variant: HMButtonVariant.text,
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }
}

