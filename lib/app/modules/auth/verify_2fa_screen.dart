import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/hm_button.dart';
import '../../services/auth_session_service.dart';
import 'auth_controller.dart';

/// 2FA verification screen - Clean & Compact design
class Verify2FAScreen extends GetView<AuthController> {
  const Verify2FAScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = Get.find<AuthSessionService>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
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
                      _buildHeader(isDark, authService),
                      
                      const SizedBox(height: 32),
                      
                      // Code input
                      _buildCodeInput(isDark),
                      
                      // Error text
                      Obx(() {
                        if (controller.codeError.value.isEmpty) {
                          return const SizedBox(height: 8);
                        }
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
                      
                      const SizedBox(height: 24),
                      
                      // Verify button
                      Obx(() => HMButton(
                        text: 'Xác thực',
                        onPressed: controller.verify2FA,
                        isLoading: controller.isLoading.value,
                        size: HMButtonSize.large,
                      )),
                      
                      const SizedBox(height: 16),
                      
                      // Resend code
                      Center(child: _buildResendButton(isDark)),
                      
                      const SizedBox(height: 32),
                      
                      // Info card
                      _buildInfoCard(isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildHeader(bool isDark, AuthSessionService authService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon & Title row
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.shield_rounded,
                size: 24,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xác thực 2 bước',
                    style: AppTypography.headlineSmall.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                    authService.pending2FAEmail.value,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Text(
          'Nhập mã 6 số đã được gửi đến email của bạn',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeInput(bool isDark) {
    return TextField(
      controller: controller.codeController,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      autofocus: true,
      style: AppTypography.headlineMedium.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
        letterSpacing: 12,
        fontWeight: FontWeight.bold,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: InputDecoration(
        counterText: '',
        hintText: '• • • • • •',
        hintStyle: AppTypography.headlineMedium.copyWith(
          color: isDark ? Colors.white24 : Colors.black12,
          letterSpacing: 8,
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
          vertical: 18,
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
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
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

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.04) 
            : AppColors.surfaceVariant.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 18,
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
          ),
          const SizedBox(width: 10),
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
    );
  }
}
