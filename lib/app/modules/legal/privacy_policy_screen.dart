import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: const HMAppBar(
        title: 'Chính sách bảo mật',
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
              title: '1. Thông tin chúng tôi thu thập',
              content: 'HanLy thu thập các thông tin sau:\n\n'
                  '• Email và mật khẩu khi bạn tạo tài khoản\n'
                  '• Tiến trình học tập (từ vựng đã học, điểm số, streak)\n'
                  '• Thông tin thiết bị (để xác thực anonymous user)\n'
                  '• Cài đặt cá nhân (level, mục tiêu học tập)',
              isDark: isDark,
            ),
            
            _buildSection(
              title: '2. Cách chúng tôi sử dụng thông tin',
              content: 'Thông tin của bạn được sử dụng để:\n\n'
                  '• Cung cấp dịch vụ học từ vựng cá nhân hóa\n'
                  '• Đồng bộ tiến trình học giữa các thiết bị\n'
                  '• Gửi thông báo nhắc nhở học (nếu bạn bật)\n'
                  '• Cải thiện chất lượng app',
              isDark: isDark,
            ),
            
            _buildSection(
              title: '3. Bảo mật dữ liệu',
              content: 'Chúng tôi cam kết:\n\n'
                  '• Mã hóa mật khẩu trước khi lưu\n'
                  '• Không chia sẻ thông tin cá nhân với bên thứ ba\n'
                  '• Lưu trữ dữ liệu trên server an toàn\n'
                  '• Xóa dữ liệu khi bạn yêu cầu xóa tài khoản',
              isDark: isDark,
            ),
            
            _buildSection(
              title: '4. Quyền của bạn',
              content: 'Bạn có quyền:\n\n'
                  '• Xem và chỉnh sửa thông tin cá nhân bất cứ lúc nào\n'
                  '• Xóa tài khoản và toàn bộ dữ liệu\n'
                  '• Tắt thông báo bất cứ lúc nào\n'
                  '• Yêu cầu xuất dữ liệu cá nhân',
              isDark: isDark,
            ),
            
            _buildSection(
              title: '5. Liên hệ',
              content: 'Nếu có thắc mắc về chính sách bảo mật:\n\n'
                  'Email: support@hanly.app\n'
                  'Chúng tôi sẽ phản hồi trong vòng 48 giờ.',
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
