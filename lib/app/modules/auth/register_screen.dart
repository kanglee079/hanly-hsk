import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/hm_button.dart';
import '../../core/widgets/hm_text_field.dart';
import '../../core/widgets/app_scaffold.dart';
import 'auth_controller.dart';

/// Register screen with email + password - Clean & Compact design
class RegisterScreen extends GetView<AuthController> {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Fixed top - Back button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    _buildBackButton(isDark),
                  ],
                ),
              ),
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      _buildHeader(isDark),
                      
                      const SizedBox(height: 32),
                      
                      // Form
                      _buildForm(isDark),
                      
                      const SizedBox(height: 24),
                      
                      // Register button
                      Obx(() => HMButton(
                        text: 'Tạo tài khoản',
                        onPressed: controller.register,
                        isLoading: controller.isLoading.value,
                        size: HMButtonSize.large,
                      )),
                      
                      const SizedBox(height: 32),
                      
                      // Login link
                      _buildLoginLink(isDark),
                    ],
                  ),
                ),
              ),
            ],
        ),
      ),
    );
  }

  Widget _buildBackButton(bool isDark) {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : AppColors.border,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tạo tài khoản backup',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Đăng ký để backup dữ liệu và đồng bộ giữa các thiết bị',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(bool isDark) {
    return Column(
      children: [
        // Email field
        Obx(() => HMTextField(
          controller: controller.emailController,
          labelText: 'Email',
          hintText: 'your@email.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          errorText: controller.emailError.value.isEmpty 
              ? null 
              : controller.emailError.value,
          prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
        )),
        
        const SizedBox(height: 14),
        
        // Password field
        Obx(() => HMTextField(
          controller: controller.passwordController,
          labelText: 'Mật khẩu',
          hintText: 'Tối thiểu 6 ký tự',
          obscureText: controller.obscurePassword.value,
          textInputAction: TextInputAction.done,
          errorText: controller.passwordError.value.isEmpty 
              ? null 
              : controller.passwordError.value,
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              controller.obscurePassword.value 
                  ? Icons.visibility_outlined 
                  : Icons.visibility_off_outlined,
              color: AppColors.textTertiary,
              size: 20,
            ),
            onPressed: controller.togglePasswordVisibility,
          ),
          onSubmitted: (_) => controller.register(),
        )),
        
        const SizedBox(height: 10),
        
        // Password hint (simplified)
        _buildPasswordHint(isDark),
      ],
    );
  }

  Widget _buildPasswordHint(bool isDark) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.04) 
              : AppColors.surfaceVariant.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
      children: [
        Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mật khẩu dùng để backup dữ liệu khi đổi máy',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                fontSize: 12,
              ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildLoginLink(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Đã có tài khoản? ',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: controller.goToLogin,
          child: Text(
            'Đăng nhập',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

