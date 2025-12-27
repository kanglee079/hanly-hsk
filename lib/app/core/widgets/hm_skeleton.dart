import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Skeleton loading placeholder
class HMSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const HMSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  /// Circle skeleton
  const HMSkeleton.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = null;

  @override
  State<HMSkeleton> createState() => _HMSkeletonState();
}

class _HMSkeletonState extends State<HMSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCircle = widget.width == widget.height && widget.borderRadius == null;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: isCircle
                ? BorderRadius.circular(widget.height / 2)
                : (widget.borderRadius ?? AppSpacing.borderRadiusSm),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
              colors: [
                isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase,
                isDark
                    ? AppColors.shimmerHighlightDark
                    : AppColors.shimmerHighlight,
                isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton card for list loading
class HMSkeletonCard extends StatelessWidget {
  final double height;

  const HMSkeletonCard({
    super.key,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      padding: AppSpacing.cardInsets,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Row(
        children: [
          const HMSkeleton.circle(size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HMSkeleton(
                  width: 120,
                  height: 16,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                const SizedBox(height: 8),
                HMSkeleton(
                  width: 200,
                  height: 12,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

