import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../constants/app_icons.dart';

/// Streak display configuration based on streak value
class StreakConfig {
  final String message;
  final String encouragement;
  final Color iconColor;
  final Color iconBgColor;
  final Color glowColor;
  final Color borderColor;
  final bool showFireAnimation;
  final int fireIntensity; // 0-3

  const StreakConfig({
    required this.message,
    required this.encouragement,
    required this.iconColor,
    required this.iconBgColor,
    required this.glowColor,
    required this.borderColor,
    this.showFireAnimation = false,
    this.fireIntensity = 0,
  });

  /// Get streak config based on streak value
  factory StreakConfig.fromStreak(int streak, {bool hasStudiedToday = true}) {
    if (streak == 0) {
      return const StreakConfig(
        message: 'Chưa có chuỗi',
        encouragement: 'Học ngay để bắt đầu chuỗi! 🚀',
        iconColor: Color(0xFF9CA3AF), // Gray
        iconBgColor: Color(0xFFF3F4F6),
        glowColor: Colors.transparent,
        borderColor: Color(0xFFE5E7EB),
        showFireAnimation: false,
        fireIntensity: 0,
      );
    } else if (streak == 1) {
      return StreakConfig(
        message: hasStudiedToday ? 'Khởi đầu tốt!' : 'Giữ chuỗi!',
        encouragement: hasStudiedToday 
            ? 'Tiếp tục vào ngày mai nhé!' 
            : '⚠️ Học ngay để giữ chuỗi!',
        iconColor: const Color(0xFFF59E0B), // Amber
        iconBgColor: const Color(0xFFFEF3C7),
        glowColor: const Color(0xFFFBBF24),
        borderColor: const Color(0xFFFCD34D),
        showFireAnimation: true,
        fireIntensity: 1,
      );
    } else if (streak <= 3) {
      return StreakConfig(
        message: 'Đang tiến bộ!',
        encouragement: hasStudiedToday 
            ? 'Còn ${7 - streak} ngày nữa đạt tuần!' 
            : '⚠️ Học ngay để giữ $streak ngày!',
        iconColor: const Color(0xFFF59E0B), // Amber
        iconBgColor: const Color(0xFFFEF3C7),
        glowColor: const Color(0xFFFBBF24),
        borderColor: const Color(0xFFFCD34D),
        showFireAnimation: true,
        fireIntensity: 1,
      );
    } else if (streak <= 7) {
      return StreakConfig(
        message: streak == 7 ? 'Đạt 1 tuần! 🎉' : 'Giữ lửa cháy!',
        encouragement: hasStudiedToday 
            ? 'Tuyệt vời! Tiếp tục phát huy!' 
            : '⚠️ Đừng để lửa tắt! Học ngay!',
        iconColor: const Color(0xFFF97316), // Orange
        iconBgColor: const Color(0xFFFFEDD5),
        glowColor: const Color(0xFFF97316),
        borderColor: const Color(0xFFFB923C),
        showFireAnimation: true,
        fireIntensity: 2,
      );
    } else if (streak <= 14) {
      return StreakConfig(
        message: streak == 14 ? 'Đạt 2 tuần! 🏆' : 'Đang cháy hết mình! 🔥',
        encouragement: hasStudiedToday 
            ? 'Không gì cản nổi bạn!' 
            : '⚠️ Chuỗi $streak ngày sắp mất!',
        iconColor: const Color(0xFFEF4444), // Red
        iconBgColor: const Color(0xFFFEE2E2),
        glowColor: const Color(0xFFEF4444),
        borderColor: const Color(0xFFF87171),
        showFireAnimation: true,
        fireIntensity: 2,
      );
    } else if (streak <= 30) {
      return StreakConfig(
        message: streak == 30 ? 'Đạt 1 tháng! 👑' : 'Siêu nhân! 🦸',
        encouragement: hasStudiedToday 
            ? 'Bạn là nguồn cảm hứng!' 
            : '⚠️ Đừng phá kỷ lục $streak ngày!',
        iconColor: const Color(0xFFDC2626), // Deep Red
        iconBgColor: const Color(0xFFFECACA),
        glowColor: const Color(0xFFEF4444),
        borderColor: const Color(0xFFEF4444),
        showFireAnimation: true,
        fireIntensity: 3,
      );
    } else {
      return StreakConfig(
        message: 'Huyền thoại! 👑',
        encouragement: hasStudiedToday 
            ? '$streak ngày - Bạn là huyền thoại!' 
            : '⚠️ Huyền thoại $streak ngày sắp mất!',
        iconColor: const Color(0xFFB91C1C), // Intense Red
        iconBgColor: const Color(0xFFFCA5A5),
        glowColor: const Color(0xFFDC2626),
        borderColor: const Color(0xFFDC2626),
        showFireAnimation: true,
        fireIntensity: 3,
      );
    }
  }
}

/// Reusable Streak Widget with fire animation
/// Used in Today, Learn, Me screens
class HMStreakWidget extends StatefulWidget {
  final int streak;
  final String? streakRank; // 'top5', 'top10', 'top25', 'top50', ''
  final bool hasStudiedToday;
  final bool isAtRisk;           // 🆕 Streak sắp mất (< 6h còn lại)
  final String? timeUntilLose;   // 🆕 Thời gian còn lại: "5 giờ 30 phút"
  final VoidCallback? onTap;
  final StreakWidgetSize size;
  final bool showMessage;

  const HMStreakWidget({
    super.key,
    required this.streak,
    this.streakRank,
    this.hasStudiedToday = true,
    this.isAtRisk = false,
    this.timeUntilLose,
    this.onTap,
    this.size = StreakWidgetSize.medium,
    this.showMessage = true,
  });

  @override
  State<HMStreakWidget> createState() => _HMStreakWidgetState();
}

enum StreakWidgetSize { small, medium, large }

class _HMStreakWidgetState extends State<HMStreakWidget>
    with TickerProviderStateMixin {
  late AnimationController _fireController;
  late AnimationController _glowController;
  late AnimationController _bounceController;
  late Animation<double> _fireAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Fire flicker animation
    _fireController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fireAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fireController, curve: Curves.easeInOut),
    );

    // Glow pulse animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Bounce animation for tap
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Start animations if streak > 0
    if (widget.streak > 0) {
      _fireController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(HMStreakWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streak != oldWidget.streak) {
      if (widget.streak > 0) {
        _fireController.repeat(reverse: true);
        _glowController.repeat(reverse: true);
      } else {
        _fireController.stop();
        _glowController.stop();
      }
    }
  }

  @override
  void dispose() {
    _fireController.dispose();
    _glowController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = StreakConfig.fromStreak(
      widget.streak,
      hasStudiedToday: widget.hasStudiedToday,
    );

    return GestureDetector(
      onTapDown: (_) => _bounceController.forward(),
      onTapUp: (_) {
        _bounceController.reverse();
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      onTapCancel: () => _bounceController.reverse(),
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: child,
          );
        },
        child: _buildWidget(isDark, config),
      ),
    );
  }

  Widget _buildWidget(bool isDark, StreakConfig config) {
    switch (widget.size) {
      case StreakWidgetSize.small:
        return _buildSmallWidget(isDark, config);
      case StreakWidgetSize.medium:
        return _buildMediumWidget(isDark, config);
      case StreakWidgetSize.large:
        return _buildLargeWidget(isDark, config);
    }
  }

  /// Small badge - used in headers
  Widget _buildSmallWidget(bool isDark, StreakConfig config) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? config.iconBgColor.withAlpha(80)
                : config.iconBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: config.borderColor.withAlpha(
                (config.showFireAnimation ? 100 + (55 * _glowAnimation.value).toInt() : 100),
              ),
            ),
            boxShadow: config.showFireAnimation
                ? [
                    BoxShadow(
                      color: config.glowColor.withAlpha((30 * _glowAnimation.value).toInt()),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFireIcon(config, size: 16),
              const SizedBox(width: 4),
              Text(
                '${widget.streak}',
                style: AppTypography.labelMedium.copyWith(
                  color: config.iconColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Medium card - used in Today screen
  Widget _buildMediumWidget(bool isDark, StreakConfig config) {
    final streakRankDisplay = _getStreakRankDisplay(widget.streakRank);

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(
              color: widget.streak > 0
                  ? config.borderColor.withAlpha(
                      (100 + (55 * _glowAnimation.value).toInt()),
                    )
                  : (isDark ? AppColors.borderDark : const Color(0xFFE5E7EB)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 20 : 8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              if (config.showFireAnimation)
                BoxShadow(
                  color: config.glowColor.withAlpha((20 * _glowAnimation.value).toInt()),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
            ],
          ),
          child: Stack(
            children: [
              // Corner decoration
              Positioned(
                top: 0,
                left: 0,
                child: CustomPaint(
                  size: const Size(60, 60),
                  painter: _CornerGradientPainter(
                    color: config.iconColor,
                    opacity: widget.streak > 0 ? 0.15 : 0.08,
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Fire icon with animation
                    _buildFireIconContainer(config, isDark, size: 40),
                    const SizedBox(width: 12),
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.streak} ngày liên tiếp',
                            style: AppTypography.titleSmall.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.showMessage) ...[
                            const SizedBox(height: 2),
                            Text(
                              !widget.hasStudiedToday && widget.streak > 0
                                  ? config.encouragement
                                  : config.message,
                              style: AppTypography.bodySmall.copyWith(
                                color: !widget.hasStudiedToday && widget.streak > 0
                                    ? AppColors.warning
                                    : (isDark
                                        ? AppColors.textTertiaryDark
                                        : AppColors.textTertiary),
                                fontSize: 12,
                                fontWeight: !widget.hasStudiedToday && widget.streak > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Rank badge
                    if (streakRankDisplay.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceVariantDark
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          streakRankDisplay,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    // Arrow indicator
                    const SizedBox(width: 8),
                    SvgPicture.asset(
                      AppIcons.chevronRight,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Large card - used in Progress screen
  Widget _buildLargeWidget(bool isDark, StreakConfig config) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Column(
          children: [
            // Fire icon with streak number
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnimatedFire(config, size: 48),
                const SizedBox(width: 8),
                Text(
                  '${widget.streak}',
                  style: AppTypography.displayLarge.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 56,
                  ),
                ),
              ],
            ),
            Text(
              'Ngày liên tiếp',
              style: AppTypography.titleLarge.copyWith(
                color: config.iconColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              !widget.hasStudiedToday && widget.streak > 0
                  ? config.encouragement
                  : config.message,
              style: AppTypography.bodyMedium.copyWith(
                color: !widget.hasStudiedToday && widget.streak > 0
                    ? AppColors.warning
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
                fontWeight: !widget.hasStudiedToday && widget.streak > 0
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _buildFireIcon(StreakConfig config, {double size = 22}) {
    return AnimatedBuilder(
      animation: _fireAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (0.1 * _fireAnimation.value * (config.showFireAnimation ? 1 : 0)),
          child: SvgPicture.asset(
            AppIcons.streakFlame,
            width: size,
            height: size,
            colorFilter: ColorFilter.mode(config.iconColor, BlendMode.srcIn),
          ),
        );
      },
    );
  }

  Widget _buildFireIconContainer(StreakConfig config, bool isDark, {double size = 40}) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isDark
                ? config.iconBgColor.withAlpha(80)
                : config.iconBgColor,
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: config.showFireAnimation
                ? [
                    BoxShadow(
                      color: config.glowColor.withAlpha((30 * _glowAnimation.value).toInt()),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: _buildFireIcon(config, size: size * 0.55),
        );
      },
    );
  }

  Widget _buildAnimatedFire(StreakConfig config, {double size = 48}) {
    if (!config.showFireAnimation) {
      return Text('🔥', style: TextStyle(fontSize: size * 0.8));
    }

    return AnimatedBuilder(
      animation: _fireAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  width: size * 1.5,
                  height: size * 1.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: config.glowColor.withAlpha((40 * _glowAnimation.value).toInt()),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                );
              },
            ),
            // Fire emoji with scale animation
            Transform.scale(
              scale: 1.0 + (0.15 * _fireAnimation.value),
              child: Text(
                '🔥',
                style: TextStyle(fontSize: size * 0.8),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getStreakRankDisplay(String? streakRank) {
    switch (streakRank) {
      case 'top5':
        return 'Top 5%';
      case 'top10':
        return 'Top 10%';
      case 'top25':
        return 'Top 25%';
      case 'top50':
        return 'Top 50%';
      default:
        return '';
    }
  }
}

/// Corner gradient painter for decorative effect
class _CornerGradientPainter extends CustomPainter {
  final Color color;
  final double opacity;

  _CornerGradientPainter({
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.5,
        colors: [
          color.withAlpha((opacity * 255).toInt()),
          color.withAlpha(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerGradientPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.opacity != opacity;
  }
}

