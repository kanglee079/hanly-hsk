import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../services/auth_session_service.dart';
import 'edit_profile_controller.dart';

class EditProfileScreen extends GetView<EditProfileController> {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = Get.find<AuthSessionService>();

    return AppScaffold(
      appBar: HMAppBar(
        title: 'Chỉnh sửa hồ sơ',
        showBackButton: true,
        actions: [
          Obx(
            () => TextButton(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.saveProfile,
              child: Text(
                'Lưu',
                style: TextStyle(
                  color: controller.isLoading.value
                      ? AppColors.textTertiary
                      : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Avatar Section
              Obx(() {
                final user = authService.currentUser.value;
                final avatarUrl = user?.avatarUrl;
                final selectedImage = controller.selectedImage.value;
                final isUploading = controller.isUploadingAvatar.value;

                return GestureDetector(
                  onTap: isUploading ? null : controller.pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withAlpha(50),
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: selectedImage != null
                              ? Image.file(selectedImage, fit: BoxFit.cover)
                              : (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? HMCachedImage(
                                  imageUrl: avatarUrl,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                )
                              : _buildAvatarPlaceholder(isDark),
                        ),
                      ),

                      // Loading overlay with progress
                      if (isUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Obx(() {
                                final progress =
                                    controller.uploadProgress.value;
                                final percent = (progress * 100).toInt();
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: progress > 0 ? progress : null,
                                      color: Colors.white,
                                      strokeWidth: 3,
                                      backgroundColor: Colors.white24,
                                    ),
                                    if (progress > 0)
                                      Text(
                                        '$percent%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),

                      // Edit badge
                      if (!isUploading)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.backgroundDark
                                    : AppColors.background,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),

              Obx(
                () => controller.isUploadingAvatar.value
                    ? Text(
                        'Đang tải ảnh lên...',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                        ),
                      )
                    : Text(
                        'Nhấn để thay đổi ảnh đại diện',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
              ),

              const SizedBox(height: 40),

              // Display Name Field
              HMTextField(
                controller: controller.displayNameController,
                labelText: 'Tên hiển thị',
                hintText: 'Nhập tên của bạn',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
              ),

              const SizedBox(height: 24),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(10),
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: Border.all(color: AppColors.primary.withAlpha(30)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ảnh đại diện và tên hiển thị sẽ được hiển thị trong bảng xếp hạng',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
      child: Icon(
        Icons.person_rounded,
        size: 60,
        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
      ),
    );
  }
}
