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
          'Tạo tài khoản',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Bắt đầu hành trình học tiếng Trung',
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
          textInputAction: TextInputAction.next,
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
        )),
        
        const SizedBox(height: 10),
        
        // Password requirements (compact)
        _buildPasswordRequirements(isDark),
        
        const SizedBox(height: 14),
        
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
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
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
      ],
    );
  }

  Widget _buildPasswordRequirements(bool isDark) {
    return Obx(() {
      final password = controller.password.value;
      
      final requirements = [
        _PasswordReq('8+ ký tự', password.length >= 8),
        _PasswordReq('A-Z', password.contains(RegExp(r'[A-Z]'))),
        _PasswordReq('a-z', password.contains(RegExp(r'[a-z]'))),
        _PasswordReq('0-9', password.contains(RegExp(r'[0-9]'))),
        _PasswordReq('!@#', password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))),
      ];
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.04) 
              : AppColors.surfaceVariant.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: requirements.map((req) => _buildReqChip(req, isDark)).toList(),
        ),
      );
    });
  }

  Widget _buildReqChip(_PasswordReq req, bool isDark) {
    final color = req.isMet 
        ? AppColors.success 
        : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          req.isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 3),
        Text(
          req.label,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontSize: 10,
          ),
        ),
      ],
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

class _PasswordReq {
  final String label;
  final bool isMet;
  
  _PasswordReq(this.label, this.isMet);
}
