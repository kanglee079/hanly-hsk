import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: const HMAppBar(
        title: 'Liên hệ',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            const SizedBox(height: 24),

            const Icon(
              Icons.support_agent_rounded,
              size: 80,
              color: AppColors.primary,
            ),

            const SizedBox(height: 24),

            Text(
              'Chúng tôi luôn sẵn sàng hỗ trợ!',
              style: AppTypography.headlineSmall.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Có thắc mắc hoặc đề xuất? Liên hệ với chúng tôi qua các kênh sau:',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Contact methods
            _buildContactCard(
              icon: Icons.email_rounded,
              title: 'Email',
              subtitle: 'support@hanly.app',
              action: 'Gửi email',
              onTap: () => _launchEmail('support@hanly.app'),
              isDark: isDark,
            ),

            _buildContactCard(
              icon: Icons.facebook_rounded,
              title: 'Facebook',
              subtitle: 'facebook.com/hanly.app',
              action: 'Mở Facebook',
              onTap: () => _launchUrl('https://facebook.com/hanly.app'),
              isDark: isDark,
            ),

            _buildContactCard(
              icon: Icons.telegram_rounded,
              title: 'Telegram',
              subtitle: '@hanly_support',
              action: 'Mở Telegram',
              onTap: () => _launchUrl('https://t.me/hanly_support'),
              isDark: isDark,
            ),

            _buildContactCard(
              icon: Icons.question_answer_rounded,
              title: 'FAQ',
              subtitle: 'Câu hỏi thường gặp',
              action: 'Xem FAQ',
              onTap: () => _launchUrl('https://hanly.app/faq'),
              isDark: isDark,
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(10),
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: AppColors.primary.withAlpha(30)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Thời gian phản hồi: trong vòng 48 giờ',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
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

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String action,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HMCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email?subject=Góp ý HanLy');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await Clipboard.setData(ClipboardData(text: email));
      HMToast.success('Đã copy email: $email');
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      HMToast.error('Không thể mở link');
    }
  }
}
