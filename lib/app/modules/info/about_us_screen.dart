import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../routes/app_routes.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: const HMAppBar(
        title: 'Về chúng tôi',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(50),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '漢',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'HanLy - Học Tiếng Trung HSK',
              style: AppTypography.headlineMedium.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Phiên bản 1.0.0',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 32),

            // Mission
            _buildSection(
              icon: Icons.flag_rounded,
              title: 'Sứ mệnh',
              content: 'Giúp người Việt học tiếng Trung dễ dàng và hiệu quả hơn thông qua công nghệ. '
                  'HanLy cam kết luôn miễn phí 100% cho mọi người.',
              isDark: isDark,
            ),

            _buildSection(
              icon: Icons.auto_awesome_rounded,
              title: 'Đặc biệt',
              content: '• Offline-first: Tất cả từ vựng có sẵn\n'
                  '• SRS thông minh: Học ít nhớ lâu\n'
                  '• Miễn phí hoàn toàn: Không ads, không paywall\n'
                  '• Cộng đồng: Được xây dựng bởi người học, cho người học',
              isDark: isDark,
            ),

            _buildSection(
              icon: Icons.favorite_rounded,
              title: 'Cảm ơn',
              content: 'Đặc biệt cảm ơn tất cả người dùng đã tin tưởng và ủng hộ HanLy. '
                  'Mọi đóng góp đều giúp chúng tôi tiếp tục phát triển app tốt hơn!',
              isDark: isDark,
            ),

            const SizedBox(height: 24),

            // Contact button
            HMButton(
              text: 'Liên hệ với chúng tôi',
              icon: const Icon(Icons.email_rounded, size: 18),
              onPressed: () => Get.toNamed(Routes.contactUs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
