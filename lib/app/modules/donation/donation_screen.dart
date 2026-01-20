import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/hm_button.dart';
import '../../core/widgets/hm_app_bar.dart';
import '../../core/widgets/hm_loading.dart';
import '../../routes/app_routes.dart';
import 'donation_controller.dart';

class DonationScreen extends GetView<DonationController> {
  const DonationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: HMBackButton(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        '💝',
                        style: TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ủng hộ HanLy',
                        style: AppTypography.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Giúp app ngày càng tốt hơn!',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'HanLy là app miễn phí hoàn toàn! 🎉',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nếu bạn thấy app hữu ích, hãy ủng hộ để mình tiếp tục phát triển thêm nhiều tính năng hay ho nhé! ❤️',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Chọn mức ủng hộ',
                    style: AppTypography.titleLarge.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Options
                  ...controller.options.map((option) => Obx(() => 
                    _DonationCard(
                      option: option,
                      isSelected: controller.selectedOption.value == option.id,
                      onTap: () => controller.selectOption(option.id),
                      isDark: isDark,
                      formatAmount: controller.formatAmount,
                    ),
                  )),
                  
                  const SizedBox(height: 24),
                  
                  // Donate button
                  Obx(() => controller.isLoading.value
                    ? const Center(child: HMLoadingIndicator.small())
                    : HMButton(
                        text: 'Ủng hộ ngay',
                        onPressed: controller.selectedOption.value.isNotEmpty 
                            ? controller.donate 
                            : null,
                        icon: const Icon(Icons.favorite_rounded, size: 20),
                      ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Footer
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Mọi đóng góp đều ý nghĩa! 🙏',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () => Get.toNamed(Routes.aboutUs),
                              child: Text(
                                'Về chúng tôi',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Text(
                              '•',
                              style: TextStyle(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Get.toNamed(Routes.contactUs),
                              child: Text(
                                'Liên hệ',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final DonationOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final String Function(int) formatAmount;

  const _DonationCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFf5576c).withAlpha(15)
              : (isDark ? AppColors.surfaceDark : AppColors.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFf5576c) : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFf5576c).withAlpha(25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFf5576c).withAlpha(20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  option.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Amount
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFFf5576c)
                    : AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${formatAmount(option.amount)}đ',
                style: AppTypography.titleSmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
