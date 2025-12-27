import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';

/// Premium screen - UI only, no IAP
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedPlan = 0; // 0 = yearly, 1 = monthly

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    final benefits = [
      _Benefit(
        icon: Icons.all_inclusive_rounded,
        title: 'Ôn tập không giới hạn',
        subtitle: 'Học từ mới mỗi ngày không giới hạn',
      ),
      _Benefit(
        icon: Icons.auto_awesome_rounded,
        title: 'Phân tích chữ Hán nâng cao',
        subtitle: 'Phân tích nét viết & gốc chữ chi tiết',
      ),
      _Benefit(
        icon: Icons.cloud_download_rounded,
        title: 'Chế độ Offline',
        subtitle: 'Tải audio & hình ảnh để học mọi lúc',
      ),
      _Benefit(
        icon: Icons.insights_rounded,
        title: 'Thống kê thông minh',
        subtitle: 'Theo dõi tiến độ & heatmap chi tiết',
      ),
    ];

    return AppScaffold(
      body: Stack(
        children: [
          // Background
          Container(
            color: isDark ? AppColors.backgroundDark : AppColors.white,
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 28,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Wave header
                        _WaveHeader(width: size.width),

                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'Mở Khóa Tiềm Năng',
                          style: AppTypography.displayMedium.copyWith(
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
                            'Nâng cao trải nghiệm học tiếng Trung với các tính năng Premium độc quyền.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Benefits
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: benefits
                                .map((b) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: _BenefitRow(
                                          benefit: b, isDark: isDark),
                                    ))
                                .toList(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Pricing plans
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              // Yearly plan
                              _PlanCard(
                                isSelected: _selectedPlan == 0,
                                isBestValue: true,
                                title: 'Hàng năm',
                                price: '1.299.000 ₫',
                                subtitle: '7 ngày dùng thử miễn phí',
                                perMonth: 'Chỉ 108.000 ₫ / tháng',
                                isDark: isDark,
                                onTap: () => setState(() => _selectedPlan = 0),
                              ),

                              const SizedBox(height: 12),

                              // Monthly plan
                              _PlanCard(
                                isSelected: _selectedPlan == 1,
                                isBestValue: false,
                                title: 'Hàng tháng',
                                price: '149.000 ₫',
                                subtitle: 'Thanh toán hàng tháng',
                                isDark: isDark,
                                onTap: () => setState(() => _selectedPlan = 1),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Cancel anytime note
                        Text(
                          'Không tính phí cho đến khi hết thời gian dùng thử.\nHủy bất cứ lúc nào.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiary,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // CTA Button
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          child: HMButton(
                            text: 'Dùng thử 7 ngày miễn phí →',
                            onPressed: () {
                              HMToast.info('Tính năng đang phát triển');
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Footer links
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _FooterLink(
                              text: 'Khôi phục',
                              onTap: () {
                                HMToast.info('Tính năng đang phát triển');
                              },
                            ),
                            _FooterDot(),
                            _FooterLink(
                              text: 'Điều khoản',
                              onTap: () {
                                HMToast.info('Tính năng đang phát triển');
                              },
                            ),
                            _FooterDot(),
                            _FooterLink(
                              text: 'Bảo mật',
                              onTap: () {
                                HMToast.info('Tính năng đang phát triển');
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _WavePainter(),
        size: Size(width - 40, 140),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1E40AF), // Deep blue
          Color(0xFF3B82F6), // Bright blue
        ],
      ).createShader(bgRect);
    
    final rrect = RRect.fromRectAndRadius(bgRect, const Radius.circular(16));
    canvas.drawRRect(rrect, bgPaint);

    // Draw multiple wave layers
    for (int i = 0; i < 5; i++) {
      _drawWaveLayer(canvas, size, i);
    }
  }

  void _drawWaveLayer(Canvas canvas, Size size, int index) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Different shades of blue/white for each layer
    final colors = [
      const Color(0xFF60A5FA).withAlpha(60),
      const Color(0xFF93C5FD).withAlpha(50),
      const Color(0xFFBFDBFE).withAlpha(40),
      const Color(0xFFDBEAFE).withAlpha(35),
      const Color(0xFFFFFFFF).withAlpha(30),
    ];
    paint.color = colors[index];

    final path = Path();
    final yOffset = 30.0 + index * 20.0;
    final amplitude = 15.0 + index * 5.0;
    final frequency = 0.015 - index * 0.002;

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

class _Benefit {
  final IconData icon;
  final String title;
  final String subtitle;

  _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _BenefitRow extends StatelessWidget {
  final _Benefit benefit;
  final bool isDark;

  const _BenefitRow({required this.benefit, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            benefit.icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                benefit.title,
                style: AppTypography.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                benefit.subtitle,
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

class _PlanCard extends StatelessWidget {
  final bool isSelected;
  final bool isBestValue;
  final String title;
  final String price;
  final String subtitle;
  final String? perMonth;
  final bool isDark;
  final VoidCallback onTap;

  const _PlanCard({
    required this.isSelected,
    required this.isBestValue,
    required this.title,
    required this.price,
    required this.subtitle,
    this.perMonth,
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
            // Best value badge
            if (isBestValue)
              Positioned(
                top: -28,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'GIÁ TỐT NHẤT',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
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
                          : (isDark
                              ? AppColors.borderLightDark
                              : AppColors.border),
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
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (perMonth != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          perMonth!,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.labelSmall.copyWith(
                        color: isBestValue
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiary),
                      ),
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
}

class _FooterLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _FooterLink({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
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

