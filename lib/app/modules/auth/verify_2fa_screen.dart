import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/hm_button.dart';
import '../../core/widgets/hm_app_bar.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../services/auth_session_service.dart';
import 'auth_controller.dart';

/// 2FA verification screen
class Verify2FAScreen extends GetView<AuthController> {
  const Verify2FAScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = Get.find<AuthSessionService>();

    return AppScaffold(
      appBar: const HMAppBar(
        title: 'Xác thực 2 bước',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            
            // Icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Nhập mã xác thực',
              style: AppTypography.headlineSmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Obx(() => Text(
              'Mã 6 số đã được gửi đến\n${authService.pending2FAEmail.value}',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            )),
            
            const SizedBox(height: 32),
            
            // Code input
            _buildCodeInput(isDark),
            
            // Error text
            Obx(() {
              if (controller.codeError.value.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  controller.codeError.value,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }),
            
            const SizedBox(height: 32),
            
            // Verify button
            Obx(() => HMButton(
              text: 'Xác thực',
              onPressed: controller.verify2FA,
              isLoading: controller.isLoading.value,
              size: HMButtonSize.large,
            )),
            
            const SizedBox(height: 24),
            
            // Resend code
            _buildResendButton(isDark),
            
            const SizedBox(height: 16),
            
            // Info text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.05) 
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mã xác thực sẽ hết hạn sau 5 phút',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeInput(bool isDark) {
    return TextField(
      controller: controller.codeController,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      style: AppTypography.headlineMedium.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
        letterSpacing: 16,
        fontWeight: FontWeight.bold,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: InputDecoration(
        counterText: '',
        hintText: '000000',
        hintStyle: AppTypography.headlineMedium.copyWith(
          color: isDark ? Colors.white24 : Colors.black12,
          letterSpacing: 16,
        ),
        filled: true,
        fillColor: isDark 
            ? Colors.white.withValues(alpha: 0.05) 
            : AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
      ),
      onChanged: (value) {
        controller.codeError.value = '';
        // Auto-submit when 6 digits entered
        if (value.length == 6) {
          controller.verify2FA();
        }
      },
    );
  }

  Widget _buildResendButton(bool isDark) {
    return Obx(() => TextButton(
      onPressed: controller.isLoading.value ? null : controller.resend2FA,
      child: Text(
        'Gửi lại mã xác thực',
        style: AppTypography.bodyMedium.copyWith(
          color: controller.isLoading.value 
              ? AppColors.textTertiary 
              : AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    ));
  }
}
