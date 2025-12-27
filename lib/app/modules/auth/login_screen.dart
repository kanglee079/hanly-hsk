import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/hm_button.dart';
import '../../core/widgets/hm_text_field.dart';
import 'auth_controller.dart';

/// Login screen with email + password
class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Logo and title
              _buildHeader(isDark),
              
              const SizedBox(height: 48),
              
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
                textInputAction: TextInputAction.done,
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
                onSubmitted: (_) => controller.login(),
              )),
              
              const SizedBox(height: 32),
              
              // Login button
              Obx(() => HMButton(
                text: 'Đăng nhập',
                onPressed: controller.login,
                isLoading: controller.isLoading.value,
                size: HMButtonSize.large,
              )),
              
              const SizedBox(height: 24),
              
              // Register link
              _buildRegisterLink(isDark),
              
              const SizedBox(height: 48),
              
              // Social login placeholder
              _buildSocialLoginPlaceholder(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        // App logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '漢',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Chào mừng trở lại!',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Đăng nhập để tiếp tục học tiếng Trung',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegisterLink(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Chưa có tài khoản? ',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: controller.goToRegister,
          child: Text(
            'Đăng ký ngay',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLoginPlaceholder(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: isDark ? Colors.white24 : Colors.black12,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'hoặc',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: isDark ? Colors.white24 : Colors.black12,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Apple button (placeholder)
        _buildSocialButton(
          icon: Icons.apple,
          label: 'Tiếp tục với Apple',
          isDark: isDark,
          comingSoon: true,
        ),
        
        const SizedBox(height: 12),
        
        // Google button (placeholder)
        _buildSocialButton(
          icon: Icons.g_mobiledata,
          label: 'Tiếp tục với Google',
          isDark: isDark,
          comingSoon: true,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required bool isDark,
    bool comingSoon = false,
  }) {
    return Opacity(
      opacity: comingSoon ? 0.5 : 1,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isDark ? Colors.white70 : AppColors.textPrimary,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: isDark ? Colors.white70 : AppColors.textPrimary,
              ),
            ),
            if (comingSoon) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Sắp ra mắt',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
