import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/hm_button.dart';
import '../../core/widgets/hm_text_field.dart';
import '../../core/widgets/hm_app_bar.dart';
import '../../core/widgets/app_scaffold.dart';
import 'auth_controller.dart';

/// Register screen with email + password
class RegisterScreen extends GetView<AuthController> {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: const HMAppBar(
        title: 'Đăng ký',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            
            // Header
            _buildHeader(isDark),
            
            const SizedBox(height: 32),
            
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
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
            )),
            
            const SizedBox(height: 16),
            
            // Password field
            Obx(() => HMTextField(
              controller: controller.passwordController,
              labelText: 'Mật khẩu',
              hintText: '••••••••',
              obscureText: controller.obscurePassword.value,
              textInputAction: TextInputAction.next,
              errorText: controller.passwordError.value.isEmpty 
                  ? null 
                  : controller.passwordError.value,
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
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
            )),
            
            const SizedBox(height: 8),
            
            // Password requirements
            _buildPasswordRequirements(isDark),
            
            const SizedBox(height: 16),
            
            // Confirm password field
            Obx(() => HMTextField(
              controller: controller.confirmPasswordController,
              labelText: 'Xác nhận mật khẩu',
              hintText: '••••••••',
              obscureText: controller.obscureConfirmPassword.value,
              textInputAction: TextInputAction.done,
              errorText: controller.confirmPasswordError.value.isEmpty 
                  ? null 
                  : controller.confirmPasswordError.value,
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.obscureConfirmPassword.value 
                      ? Icons.visibility_outlined 
                      : Icons.visibility_off_outlined,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
                onPressed: controller.toggleConfirmPasswordVisibility,
              ),
              onSubmitted: (_) => controller.register(),
            )),
            
            const SizedBox(height: 32),
            
            // Register button
            Obx(() => HMButton(
              text: 'Tạo tài khoản',
              onPressed: controller.register,
              isLoading: controller.isLoading.value,
              size: HMButtonSize.large,
            )),
            
            const SizedBox(height: 24),
            
            // Login link
            Row(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Text(
          'Tạo tài khoản mới',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Bắt đầu hành trình học tiếng Trung',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements(bool isDark) {
    return Obx(() {
      final password = controller.password.value;
      
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.05) 
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yêu cầu mật khẩu:',
              style: AppTypography.labelSmall.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _buildRequirement('Ít nhất 8 ký tự', password.length >= 8, isDark),
            _buildRequirement('Chữ hoa (A-Z)', password.contains(RegExp(r'[A-Z]')), isDark),
            _buildRequirement('Chữ thường (a-z)', password.contains(RegExp(r'[a-z]')), isDark),
            _buildRequirement('Số (0-9)', password.contains(RegExp(r'[0-9]')), isDark),
            _buildRequirement('Ký tự đặc biệt (!@#...)', password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')), isDark),
          ],
        ),
      );
    });
  }

  Widget _buildRequirement(String text, bool isMet, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: isMet 
                ? const Color(0xFF10B981) 
                : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: isMet 
                  ? const Color(0xFF10B981) 
                  : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
