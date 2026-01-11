import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/hm_button.dart';
import '../../core/widgets/hm_text_field.dart';
import '../../core/widgets/hm_app_bar.dart';
import '../../core/widgets/hm_loading.dart';
import 'link_account_controller.dart';

class LinkAccountScreen extends GetView<LinkAccountController> {
  const LinkAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: HMAppBar(
          title: 'Liên kết tài khoản',
          showBackButton: true,
        ),
        body: SafeArea(
        child: Obx(() {
          switch (controller.currentStep.value) {
            case LinkAccountStep.email:
              return _EmailStep(controller: controller, isDark: isDark);
            case LinkAccountStep.verify:
              return _VerifyStep(controller: controller, isDark: isDark);
            case LinkAccountStep.success:
              return _SuccessStep(controller: controller, isDark: isDark);
            case LinkAccountStep.error:
              return _ErrorStep(controller: controller, isDark: isDark);
          }
        }),
      ),
      ),
    );
  }
}

class _EmailStep extends StatelessWidget {
  final LinkAccountController controller;
  final bool isDark;

  const _EmailStep({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.link_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Liên kết email',
            style: AppTypography.headlineMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Liên kết email để backup dữ liệu và đồng bộ giữa các thiết bị',
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          // Benefits
          _buildBenefit(
            icon: Icons.cloud_upload_rounded,
            title: 'Backup an toàn',
            subtitle: 'Dữ liệu học được lưu trữ trên cloud',
            isDark: isDark,
          ),
          _buildBenefit(
            icon: Icons.devices_rounded,
            title: 'Đồng bộ thiết bị',
            subtitle: 'Học trên iPhone, iPad, hoặc thiết bị mới',
            isDark: isDark,
          ),
          _buildBenefit(
            icon: Icons.restore_rounded,
            title: 'Khôi phục dễ dàng',
            subtitle: 'Đổi điện thoại không mất tiến độ học',
            isDark: isDark,
          ),
          
          const SizedBox(height: 32),
          
          // Email input
          HMTextField(
            controller: controller.emailController,
            hintText: 'Nhập email của bạn',
            prefixIcon: const Icon(Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
          ),
          
          const SizedBox(height: 24),
          
          // Submit button
          Obx(() => controller.isLoading.value
            ? const Center(child: HMLoadingIndicator.small())
            : HMButton(
                text: 'Gửi mã xác nhận',
                onPressed: controller.emailValid.value 
                    ? controller.requestLink 
                    : null,
                icon: const Icon(Icons.send_rounded, size: 20),
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
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
}

class _VerifyStep extends StatelessWidget {
  final LinkAccountController controller;
  final bool isDark;

  const _VerifyStep({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 40,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Kiểm tra email',
            style: AppTypography.headlineMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chúng tôi đã gửi mã xác nhận đến email của bạn. Vui lòng nhập mã để hoàn tất.',
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          // Token input
          HMTextField(
            controller: controller.tokenController,
            hintText: 'Nhập mã xác nhận',
            prefixIcon: const Icon(Icons.pin_outlined),
            keyboardType: TextInputType.text,
          ),
          
          const SizedBox(height: 16),
          
          // Resend link
          TextButton(
            onPressed: controller.resendCode,
            child: Text(
              'Gửi lại mã',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Verify button
          Obx(() => controller.isLoading.value
            ? const Center(child: HMLoadingIndicator.small())
            : HMButton(
                text: 'Xác nhận',
                onPressed: controller.tokenValid.value 
                    ? controller.verifyToken 
                    : null,
                icon: const Icon(Icons.check_circle_rounded, size: 20),
              ),
          ),
        ],
      ),
    );
  }
}

class _SuccessStep extends StatelessWidget {
  final LinkAccountController controller;
  final bool isDark;

  const _SuccessStep({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 60,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'Liên kết thành công!',
            style: AppTypography.headlineMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          Obx(() => Text(
            controller.wasMerged.value
                ? 'Dữ liệu đã được merge với tài khoản có sẵn.\n${controller.mergeMessage.value}'
                : 'Tài khoản của bạn đã được liên kết. Giờ bạn có thể đăng nhập trên các thiết bị khác.',
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          )),
          
          const SizedBox(height: 48),
          
          HMButton(
            text: 'Hoàn tất',
            onPressed: controller.done,
          ),
        ],
      ),
    );
  }
}

class _ErrorStep extends StatelessWidget {
  final LinkAccountController controller;
  final bool isDark;

  const _ErrorStep({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_rounded,
              size: 60,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'Có lỗi xảy ra',
            style: AppTypography.headlineMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Obx(() => Text(
            controller.errorMessage.value,
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          )),
          
          const SizedBox(height: 48),
          
          HMButton(
            text: 'Thử lại',
            onPressed: controller.resendCode,
          ),
        ],
      ),
    );
  }
}
