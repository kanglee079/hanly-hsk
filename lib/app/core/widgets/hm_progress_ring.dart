import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Circular progress ring
class HMProgressRing extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? backgroundColor;
  final Widget? child;
  final Widget? centerWidget;
  final String? centerText;
  final String? subText;
  final bool animate;
  final Duration animationDuration;
  final Curve animationCurve;

  const HMProgressRing({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 10,
    this.progressColor,
    this.backgroundColor,
    this.child,
    this.centerWidget,
    this.centerText,
    this.subText,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 240),
    this.animationCurve = Curves.easeOutCubic,
  });

  @override
  State<HMProgressRing> createState() => _HMProgressRingState();
}

class _HMProgressRingState extends State<HMProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _progressAnim;
  double _lastProgress = 0;

  @override
  void initState() {
    super.initState();
    _lastProgress = widget.progress.clamp(0.0, 1.0);
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _progressAnim = AlwaysStoppedAnimation(_lastProgress);
  }

  @override
  void didUpdateWidget(covariant HMProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.progress.clamp(0.0, 1.0);

    if (!widget.animate) {
      _controller.stop();
      _progressAnim = AlwaysStoppedAnimation(next);
      _lastProgress = next;
      return;
    }

    if (next == _lastProgress) return;

    _controller.duration = widget.animationDuration;
    _progressAnim = Tween<double>(begin: _lastProgress, end: next).animate(
      CurvedAnimation(parent: _controller, curve: widget.animationCurve),
    );
    _lastProgress = next;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: widget.animate ? _controller : const AlwaysStoppedAnimation(0),
        builder: (context, _) {
          final p = widget.animate
              ? _progressAnim.value
              : widget.progress.clamp(0.0, 1.0);

          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ProgressRingPainter(
                  progress: p,
                  strokeWidth: widget.strokeWidth,
                  progressColor: widget.progressColor ?? AppColors.primary,
                  backgroundColor: widget.backgroundColor ??
                      (isDark ? AppColors.surfaceVariantDark : AppColors.border),
                ),
              ),
              if (widget.child != null)
                widget.child!
              else if (widget.centerWidget != null)
                widget.centerWidget!
              else if (widget.centerText != null || widget.subText != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.centerText != null)
                      Text(
                        widget.centerText!,
                        style: AppTypography.headlineMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                    if (widget.subText != null)
                      Text(
                        widget.subText!,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

