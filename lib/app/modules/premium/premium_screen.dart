import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../core/constants/toast_messages.dart';
import '../../data/models/subscription_model.dart';
import 'premium_controller.dart';

/// Premium screen - API-integrated with new pricing plans
class PremiumScreen extends GetView<PremiumController> {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AppScaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF1A1A2E), const Color(0xFF0F0F1A)]
                    : [const Color(0xFFF8FAFF), AppColors.white],
              ),
            ),
          ),

          // Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header with close button
                _buildHeader(isDark),

                Expanded(
                  child: Obx(() {
                    // Show loading skeleton
                    if (controller.isLoading.value) {
                      return _buildLoadingState(isDark);
                    }

                    // Show content
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          // Wave header
                          _WaveHeader(width: size.width),

                          const SizedBox(height: 24),

                          // If user is already premium, show status
                          if (controller.isPremium)
                            _buildPremiumStatus(isDark),

                          // Title
                          Text(
                            controller.isPremium
                                ? 'Bạn đã là Premium!'
                                : 'Học Không Giới Hạn',
                            style: AppTypography.headlineMedium.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              controller.isPremium
                                  ? 'Cảm ơn bạn đã ủng hộ HanLy!'
                                  : 'Học không giới hạn • Thống kê chi tiết • Tất cả đề thi HSK',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Key Premium Features Highlight
                          _buildKeyFeaturesHighlight(isDark),

                          const SizedBox(height: 32),

                          // Benefits grid
                          _buildBenefitsGrid(isDark),

                          const SizedBox(height: 32),

                          // Comparison table
                          _buildComparisonTable(isDark),

                          // Only show pricing if not premium
                          if (!controller.isPremium) ...[
                            const SizedBox(height: 32),

                            // Pricing plans
                            _buildPricingPlans(isDark),

                            const SizedBox(height: 16),

                            // Cancel anytime note
                            Text(
                              'Hủy bất cứ lúc nào. Không tính phí ẩn.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ],

                          SizedBox(height: 100 + bottomPadding),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Fixed CTA button at bottom
          Positioned(
            left: 20,
            right: 20,
            bottom: bottomPadding + 20,
            child: Obx(() => Column(
                  children: [
                    if (!controller.isPremium)
                      HMButton(
                        text: controller.ctaButtonText,
                        onPressed: controller.purchase,
                        isLoading: controller.isPurchasing.value,
                        fullWidth: true,
                      )
                    else
                      HMButton(
                        text: 'Đã kích hoạt',
                        onPressed: () => Get.back(),
                        variant: HMButtonVariant.secondary,
                        fullWidth: true,
                      ),
                    const SizedBox(height: 12),
                    // Footer links
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _FooterLink(
                          text: 'Khôi phục',
                          isLoading: controller.isRestoring.value,
                          onTap: controller.restorePurchases,
                        ),
                        const _FooterDot(),
                        _FooterLink(
                          text: 'Điều khoản',
                          onTap: () {
                            HMToast.info(ToastMessages.settingsFeatureComingSoon);
                          },
                        ),
                        const _FooterDot(),
                        _FooterLink(
                          text: 'Bảo mật',
                          onTap: () {
                            HMToast.info(ToastMessages.settingsFeatureComingSoon);
                          },
                        ),
                      ],
                    ),
                  ],
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          // Pro badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  'PREMIUM',
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              Icons.close_rounded,
              size: 28,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 100),
            HMSkeleton(width: double.infinity, height: 120, borderRadius: BorderRadius.circular(20)),
            const SizedBox(height: 24),
            const HMSkeleton(width: 200, height: 32),
            const SizedBox(height: 16),
            const HMSkeleton(width: 250, height: 20),
            const SizedBox(height: 32),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: List.generate(
                  6, (_) => HMSkeleton(width: 100, height: 100, borderRadius: BorderRadius.circular(16))),
            ),
            const SizedBox(height: 32),
            HMSkeleton(width: double.infinity, height: 200, borderRadius: BorderRadius.circular(16)),
            const SizedBox(height: 32),
            ...List.generate(3, (_) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: HMSkeleton(width: double.infinity, height: 80, borderRadius: BorderRadius.circular(16)),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumStatus(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPlanDisplayName(controller.subscription.value?.plan),
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (controller.expiryText.isNotEmpty)
                  Text(
                    controller.expiryText,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Đang hoạt động',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPlanDisplayName(String? plan) {
    switch (plan) {
      case 'monthly':
        return 'Premium Hàng tháng';
      case 'yearly':
        return 'Premium Hàng năm';
      case 'lifetime':
        return 'Premium Trọn đời';
      default:
        return 'Premium';
    }
  }

  Widget _buildPricingPlans(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(() => Column(
            children: List.generate(controller.plans.length, (index) {
              final plan = controller.plans[index];
              return Padding(
                padding:
                    EdgeInsets.only(bottom: index < controller.plans.length - 1 ? 12 : 0),
                child: _PlanCard(
                  plan: plan,
                  isSelected: controller.selectedPlanIndex.value == index,
                  isDark: isDark,
                  onTap: () => controller.selectPlan(index),
                ),
              );
            }),
          )),
    );
  }

  Widget _buildBenefitsGrid(bool isDark) {
    final benefits = [
      _BenefitItem(
        icon: Icons.all_inclusive_rounded,
        title: 'Học từ mới\nkhông giới hạn',
        color: const Color(0xFF2196F3),
      ),
      _BenefitItem(
        icon: Icons.auto_awesome_rounded,
        title: 'Ôn tập\ntổng hợp',
        color: const Color(0xFF9C27B0),
      ),
      _BenefitItem(
        icon: Icons.quiz_rounded,
        title: 'Ôn thi HSK\nđầy đủ',
        color: const Color(0xFF00BCD4),
      ),
      _BenefitItem(
        icon: Icons.shield_rounded,
        title: 'Bảo vệ\nstreak',
        color: const Color(0xFF4CAF50),
      ),
      _BenefitItem(
        icon: Icons.analytics_rounded,
        title: 'Thống kê\nchi tiết',
        color: const Color(0xFFFF9800),
      ),
      _BenefitItem(
        icon: Icons.download_rounded,
        title: 'Tải offline\n6 cấp độ',
        color: const Color(0xFF9C27B0),
      ),
      _BenefitItem(
        icon: Icons.sports_esports_rounded,
        title: 'Game 30s\n10 lượt/ngày',
        color: const Color(0xFFE91E63),
      ),
      _BenefitItem(
        icon: Icons.block_rounded,
        title: 'Không\nquảng cáo',
        color: const Color(0xFFF44336),
      ),
      _BenefitItem(
        icon: Icons.support_agent_rounded,
        title: 'Hỗ trợ\nưu tiên',
        color: const Color(0xFF00BCD4),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95, // Slightly taller for better text display
        ),
        itemCount: benefits.length,
        itemBuilder: (context, index) {
          final benefit = benefits[index];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceVariantDark
                  : benefit.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isDark ? AppColors.borderDark : benefit.color.withOpacity(0.2),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  benefit.icon,
                  color: benefit.color,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  benefit.title,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSmall.copyWith(
                    color:
                        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildComparisonTable(bool isDark) {
    final features = [
      _FeatureRow('Từ mới mỗi ngày', '30 từ', 'Không giới hạn'),
      _FeatureRow('Flashcards', '10 thẻ/ngày', 'Không giới hạn'),
      _FeatureRow('Ôn tập tổng hợp', '✗', '✓'),
      _FeatureRow('Ôn thi HSK', '1 đề/level', 'Tất cả đề'),
      _FeatureRow('Game 30s', '3 lượt/ngày', '10 lượt/ngày'),
      _FeatureRow('Bảo vệ streak', '✗', '3 lần/tháng'),
      _FeatureRow('Thống kê chi tiết', '7 ngày', '365 ngày'),
      _FeatureRow('Tải offline', 'HSK1-2', 'HSK1-6'),
      _FeatureRow('Quảng cáo', 'Có', 'Không'),
      _FeatureRow('Hỗ trợ', 'Email', 'Ưu tiên'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Tính năng',
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Free',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PRO',
                        textAlign: TextAlign.center,
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Feature rows
            ...features.asMap().entries.map((entry) {
              final index = entry.key;
              final feature = entry.value;
              final isLast = index == features.length - 1;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: isDark ? AppColors.borderDark : AppColors.border,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        feature.name,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        feature.freeValue,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: feature.freeValue == '✗'
                              ? AppColors.error
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        feature.proValue,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: feature.proValue == '✓' || feature.proValue == '∞'
                              ? AppColors.success
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyFeaturesHighlight(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withAlpha(20),
              AppColors.primary.withAlpha(10),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withAlpha(40),
            width: 1.5,
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
                    color: AppColors.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tính năng Premium độc quyền',
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFeatureHighlight(
              '📚 Học từ mới không giới hạn',
              'Free: 30 từ/ngày • Premium: Không giới hạn',
              isDark,
            ),
            const SizedBox(height: 12),
            _buildFeatureHighlight(
              '📊 Thống kê chi tiết 365 ngày',
              'Theo dõi tiến độ học tập dài hạn',
              isDark,
            ),
            const SizedBox(height: 12),
            _buildFeatureHighlight(
              '🎯 Tất cả đề thi HSK',
              'Free: 1 đề/level • Premium: Tất cả đề',
              isDark,
            ),
            const SizedBox(height: 12),
            _buildFeatureHighlight(
              '🛡️ Bảo vệ streak 3 lần/tháng',
              'Không lo mất streak khi quên học',
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureHighlight(String title, String subtitle, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WaveHeader extends StatelessWidget {
  final double width;

  const _WaveHeader({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _WavePainter(),
        size: Size(width - 40, 120),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient with gold accent
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1E40AF),
          Color(0xFF3B82F6),
          Color(0xFF60A5FA),
        ],
      ).createShader(bgRect);

    final rrect = RRect.fromRectAndRadius(bgRect, const Radius.circular(20));
    canvas.drawRRect(rrect, bgPaint);

    // Draw multiple wave layers
    for (int i = 0; i < 4; i++) {
      _drawWaveLayer(canvas, size, i);
    }

    // Draw crown icon placeholder
    final crownPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      35,
      crownPaint,
    );
  }

  void _drawWaveLayer(Canvas canvas, Size size, int index) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final colors = [
      const Color(0xFFFFD700).withAlpha(40),
      const Color(0xFF60A5FA).withAlpha(50),
      const Color(0xFFBFDBFE).withAlpha(40),
      const Color(0xFFFFFFFF).withAlpha(30),
    ];
    paint.color = colors[index];

    final path = Path();
    final yOffset = 25.0 + index * 18.0;
    final amplitude = 12.0 + index * 4.0;
    final frequency = 0.012 - index * 0.002;

    path.moveTo(0, yOffset);

    for (double x = 0; x <= size.width; x++) {
      final y = yOffset +
          amplitude * math.sin(frequency * x * math.pi + index * 0.5) +
          amplitude * 0.5 * math.cos(frequency * 2 * x * math.pi + index * 0.3);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlanCard extends StatelessWidget {
  final PremiumPlanModel plan;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.border),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Popular badge
            if (plan.popular)
              Positioned(
                top: -28,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'PHỔ BIẾN NHẤT',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

            // Discount badge
            if (plan.discount != null)
              Positioned(
                top: -28,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-${plan.discount}%',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

            Row(
              children: [
                // Radio indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.borderLightDark : AppColors.border),
                      width: 2,
                    ),
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AppColors.white,
                        )
                      : null,
                ),

                const SizedBox(width: 16),

                // Plan info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getSubtitle(),
                        style: AppTypography.bodySmall.copyWith(
                          color: plan.discount != null
                              ? AppColors.success
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary),
                          fontWeight: plan.discount != null ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (plan.formattedOriginalPrice != null) ...[
                      Text(
                        plan.formattedOriginalPrice!,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          plan.formattedPrice,
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (plan.period != 'lifetime')
                          Text(
                            '/${plan.period == 'month' ? 'tháng' : 'năm'}',
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getSubtitle() {
    if (plan.discount != null) {
      return 'Tiết kiệm ${plan.discount}%';
    }
    if (plan.period == 'lifetime') {
      return 'Thanh toán 1 lần duy nhất';
    }
    return 'Thanh toán ${plan.period == 'month' ? 'hàng tháng' : 'hàng năm'}';
  }
}

class _BenefitItem {
  final IconData icon;
  final String title;
  final Color color;

  _BenefitItem({
    required this.icon,
    required this.title,
    required this.color,
  });
}

class _FeatureRow {
  final String name;
  final String freeValue;
  final String proValue;

  _FeatureRow(this.name, this.freeValue, this.proValue);
}

class _FooterLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isLoading;

  const _FooterLink({
    required this.text,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                text,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
      ),
    );
  }
}

class _FooterDot extends StatelessWidget {
  const _FooterDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: AppColors.textTertiary,
        shape: BoxShape.circle,
      ),
    );
  }
}
