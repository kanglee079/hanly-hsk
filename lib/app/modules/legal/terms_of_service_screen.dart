import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: const HMAppBar(
        title: 'Điều khoản sử dụng',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            
            Text(
              'Cập nhật: 18/01/2026',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildSection(
              title: '1. Chấp nhận điều khoản',
              content: 'Bằng việc tải và sử dụng HanLy, bạn đồng ý với các điều khoản sử dụng này. '
                  'Nếu không đồng ý, vui lòng không sử dụng app.',
              isDark: isDark,
            ),
            
            _buildSection(
              title: '2. Sử dụng dịch vụ',
              content: 'Bạn được phép:\n\n'
                  '• Sử dụng app cho mục đích học tập cá nhân\n'
                  '• Tạo tài khoản để backup dữ liệu\n'
                  '• Đóng góp để hỗ trợ phát triển app\n\n'
                  'Bạn KHÔNG được:\n\n'
                  '• Sử dụng app cho mục đích thương mại\n'
                  '• Copy, phân phối lại nội dung học liệu\n'
                  '• Tấn công, hack hoặc làm gián đoạn dịch vụ',
              isDark: isDark,
            ),
            
            _buildSection(
              title: '3. Tài khoản của bạn',
              content: 'Bạn chịu trách nhiệm:\n\n'
                  '• Giữ bí mật thông tin đăng nhập\n'
                  '• Thông báo nếu phát hiện tài khoản bị xâm nhập\n'
                  '• Không chia sẻ tài khoản với người khác',
              isDark: isDark,
            ),
            
            _buildSection(
              title: '4. Miễn trừ trách nhiệm',
              content: 'HanLy được cung cấp "nguyên trạng". Chúng tôi:\n\n'
                  '• Không đảm bảo app luôn hoạt động 100% mượt mà\n'
                  '• Không chịu trách nhiệm nếu bạn không đạt điểm thi HSK như mong muốn\n'
                  '• Có quyền tạm ngừng dịch vụ để bảo trì\n'
                  '• Có quyền thay đổi điều khoản (sẽ thông báo trước)',
              isDark: isDark,
            ),
            
            _buildSection(
              title: '5. Thay đổi điều khoản',
              content: 'Chúng tôi có thể cập nhật điều khoản này. '
                  'Các thay đổi quan trọng sẽ được thông báo qua app hoặc email.',
              isDark: isDark,
            ),
            
            _buildSection(
              title: '6. Liên hệ',
              content: 'Nếu có thắc mắc:\n\n'
                  'Email: support@hanly.app\n'
                  'Chúng tôi luôn lắng nghe ý kiến của bạn!',
              isDark: isDark,
            ),
            
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
