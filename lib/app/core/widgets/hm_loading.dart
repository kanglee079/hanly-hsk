import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Beautiful animated loading indicator for the app
/// Use this instead of CircularProgressIndicator for consistent styling
class HMLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final String? message;
  final bool showMessage;

  const HMLoadingIndicator({
    super.key,
    this.size = 48,
    this.color,
    this.message,
    this.showMessage = false,
  });

  /// Small variant for inline loading
  const HMLoadingIndicator.small({
    super.key,
    this.color,
  })  : size = 24,
        message = null,
        showMessage = false;

  /// Medium variant for cards/sections
  const HMLoadingIndicator.medium({
    super.key,
    this.color,
    this.message,
  })  : size = 36,
        showMessage = false;

  @override
  State<HMLoadingIndicator> createState() => _HMLoadingIndicatorState();
}

class _HMLoadingIndicatorState extends State<HMLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.color ?? AppColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_rotationController, _pulseAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _LoadingPainter(
                    progress: _rotationController.value,
                    color: color,
                    strokeWidth: widget.size / 12,
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.showMessage && widget.message != null) ...[
          SizedBox(height: widget.size / 3),
          Text(
            widget.message!,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _LoadingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _LoadingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle (faded)
    final bgPaint = Paint()
      ..color = color.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Animated arc
    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [
          color.withAlpha(0),
          color,
        ],
        transform: GradientRotation(progress * math.pi * 2 - math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      progress * math.pi * 2 - math.pi / 2,
      math.pi * 1.5,
      false,
      arcPaint,
    );

    // Leading dot
    final dotAngle = progress * math.pi * 2 + math.pi;
    final dotX = center.dx + radius * math.cos(dotAngle);
    final dotY = center.dy + radius * math.sin(dotAngle);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(dotX, dotY), strokeWidth / 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _LoadingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Full-screen loading overlay with beautiful animation
class HMLoadingOverlay extends StatefulWidget {
  final String? message;
  final List<String>? messages; // Rotating messages for long loading
  final bool isVisible;
  final Widget? child;
  final Color? backgroundColor;

  const HMLoadingOverlay({
    super.key,
    this.message,
    this.messages,
    required this.isVisible,
    this.child,
    this.backgroundColor,
  });

  @override
  State<HMLoadingOverlay> createState() => _HMLoadingOverlayState();
}

class _HMLoadingOverlayState extends State<HMLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    if (widget.isVisible) {
      _fadeController.forward();
    }

    // Rotate messages if provided
    if (widget.messages != null && widget.messages!.length > 1) {
      _startMessageRotation();
    }
  }

  void _startMessageRotation() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && widget.isVisible && widget.messages != null) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % widget.messages!.length;
        });
        _startMessageRotation();
      }
    });
  }

  @override
  void didUpdateWidget(HMLoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _fadeController.forward();
      } else {
        _fadeController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.child != null) {
      return Stack(
        children: [
          widget.child!,
          if (widget.isVisible) _buildOverlay(context),
        ],
      );
    }

    return widget.isVisible ? _buildOverlay(context) : const SizedBox.shrink();
  }

  Widget _buildOverlay(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final message = widget.messages != null
        ? widget.messages![_currentMessageIndex]
        : widget.message;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: widget.backgroundColor ??
            (isDark
                ? AppColors.backgroundDark.withAlpha(240)
                : AppColors.background.withAlpha(240)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated container
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 60 : 20),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HMLoadingIndicator(size: 56),
                      if (message != null) ...[
                        const SizedBox(height: 20),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            message,
                            key: ValueKey(message),
                            style: AppTypography.bodyLarge.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline loading state with shimmer effect for content areas
class HMLoadingContent extends StatelessWidget {
  final String? message;
  final double height;
  final IconData? icon;

  const HMLoadingContent({
    super.key,
    this.message,
    this.height = 200,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value * 0.3,
                    child: Transform.scale(scale: 0.8 + value * 0.2, child: child),
                  );
                },
                child: Icon(
                  icon,
                  size: 48,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
            ],
            const HMLoadingIndicator.medium(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dots loading animation (for buttons or inline)
class HMLoadingDots extends StatefulWidget {
  final Color? color;
  final double dotSize;

  const HMLoadingDots({
    super.key,
    this.color,
    this.dotSize = 8,
  });

  @override
  State<HMLoadingDots> createState() => _HMLoadingDotsState();
}

class _HMLoadingDotsState extends State<HMLoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final scale = 0.5 + 0.5 * math.sin(value * math.pi);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.dotSize / 3),
              width: widget.dotSize,
              height: widget.dotSize,
              decoration: BoxDecoration(
                color: color.withAlpha((scale * 255).round()),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
