import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/hm_button.dart';
import '../../core/widgets/hm_text_field.dart';
import 'auth_controller.dart';

/// Login screen with email + password - Clean & Compact design
class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top section - Logo & Header
                        Column(
                          children: [
                            SizedBox(height: constraints.maxHeight * 0.06),
                            _buildLogo(),
                            const SizedBox(height: 20),
                            _buildHeader(isDark),
                          ],
                        ),
                        
                        // Middle section - Form
                        Column(
                          children: [
                            const SizedBox(height: 32),
                            _buildForm(isDark),
                            const SizedBox(height: 24),
                            
                            // Login button
                            Obx(() => HMButton(
                              text: 'Đăng nhập',
                              onPressed: controller.login,
                              isLoading: controller.isLoading.value,
                              size: HMButtonSize.large,
                            )),
                            
                            const SizedBox(height: 20),
                            _buildRegisterLink(isDark),
                          ],
                        ),
                        
                        // Bottom section - Social login
                        Column(
                          children: [
                            const SizedBox(height: 24),
                            _buildSocialLogin(isDark),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '漢',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Text(
          'Chào mừng trở lại!',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Đăng nhập để tiếp tục học tiếng Trung',
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
          hintText: '••••••••',
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
          onSubmitted: (_) => controller.login(),
        )),
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

  Widget _buildSocialLogin(bool isDark) {
    return Column(
      children: [
        // Divider with "hoặc"
        Row(
          children: [
            Expanded(child: Divider(color: isDark ? Colors.white12 : AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'hoặc',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                ),
              ),
            ),
            Expanded(child: Divider(color: isDark ? Colors.white12 : AppColors.border)),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Social buttons row
        Row(
          children: [
            Expanded(
              child: _buildSocialButton(
                icon: Icons.apple,
                label: 'Apple',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSocialButton(
                icon: Icons.g_mobiledata_rounded,
                label: 'Google',
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Opacity(
      opacity: 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isDark ? Colors.white70 : AppColors.textPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
