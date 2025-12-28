import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../services/tutorial_service.dart';

/// Tutorial overlay widget that highlights target elements
/// with a spotlight effect and shows instructional tooltips
class HMTutorialOverlay extends StatefulWidget {
  final Widget child;

  const HMTutorialOverlay({
    super.key,
    required this.child,
  });

  @override
  State<HMTutorialOverlay> createState() => _HMTutorialOverlayState();
}

class _HMTutorialOverlayState extends State<HMTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  int _lastStepIndex = -1;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Auto-scroll to target element
  Future<void> _scrollToTarget(TutorialService service, TutorialStep step) async {
    if (_isScrolling) return;
    _isScrolling = true;
    
    try {
      if (step.needsScroll) {
        await service.scrollToTarget(step.targetKey);
        // Wait a bit for scroll animation to complete
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } finally {
      _isScrolling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Obx(() {
          final tutorialService = Get.find<TutorialService>();
          if (!tutorialService.isShowingTutorial.value) {
            _lastStepIndex = -1;
            return const SizedBox.shrink();
          }

          final step = tutorialService.currentStep;
          if (step == null) return const SizedBox.shrink();

          final currentIndex = tutorialService.currentStepIndex.value;
          
          // Auto-scroll when step changes
          if (_lastStepIndex != currentIndex) {
            _lastStepIndex = currentIndex;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToTarget(tutorialService, step).then((_) {
                // Trigger rebuild after scroll to update target rect
                if (mounted) setState(() {});
              });
            });
          }

          // Start animation
          if (!_animationController.isAnimating &&
              _animationController.status != AnimationStatus.completed) {
            _animationController.forward();
          }

          final targetKey = tutorialService.getKey(step.targetKey);
          Rect? targetRect;

          if (targetKey != null && targetKey.currentContext != null) {
            final renderBox =
                targetKey.currentContext!.findRenderObject() as RenderBox?;
            if (renderBox != null && renderBox.hasSize) {
              final position = renderBox.localToGlobal(Offset.zero);
              targetRect = Rect.fromLTWH(
                position.dx,
                position.dy,
                renderBox.size.width,
                renderBox.size.height,
              );
            }
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SizedBox.expand(
              child: _TutorialContent(
              step: step,
              targetRect: targetRect,
              pulseAnimation: _pulseAnimation,
              onNext: () {
                _animationController.reset();
                tutorialService.nextStep();
                _animationController.forward();
              },
              onSkip: tutorialService.skipTutorial,
              onPrevious: tutorialService.currentStepIndex.value > 0
                  ? () {
                      _animationController.reset();
                      tutorialService.previousStep();
                      _animationController.forward();
                    }
                  : null,
              progress: tutorialService.progress,
              stepText: tutorialService.stepCountText,
            ),
            ),
          );
        }),
      ],
    );
  }
}

class _TutorialContent extends StatelessWidget {
  final TutorialStep step;
  final Rect? targetRect;
  final Animation<double> pulseAnimation;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback? onPrevious;
  final double progress;
  final String stepText;

  const _TutorialContent({
    required this.step,
    required this.targetRect,
    required this.pulseAnimation,
    required this.onNext,
    required this.onSkip,
    required this.onPrevious,
    required this.progress,
    required this.stepText,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dark overlay with spotlight cutout
          if (targetRect != null)
            _SpotlightOverlay(
              targetRect: targetRect!,
              pulseAnimation: pulseAnimation,
            )
          else
            Container(
              color: Colors.black.withAlpha(180),
            ),

          // Tooltip card
          _buildTooltip(context, screenSize, bottomPadding),
        ],
      ),
    );
  }

  Widget _buildTooltip(
      BuildContext context, Size screenSize, double bottomPadding) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate tooltip position
    double top = 0;
    double left = 20;
    double right = 20;
    const tooltipHeight = 200.0;

    if (targetRect != null) {
      switch (step.position) {
        case TutorialPosition.bottom:
          top = targetRect!.bottom + 20;
          break;
        case TutorialPosition.top:
          top = targetRect!.top - tooltipHeight - 20;
          break;
        case TutorialPosition.center:
          top = (screenSize.height - tooltipHeight) / 2;
          break;
        case TutorialPosition.left:
        case TutorialPosition.right:
          top = targetRect!.center.dy - tooltipHeight / 2;
          break;
      }

      // Clamp to screen bounds
      top = top.clamp(50.0, screenSize.height - tooltipHeight - bottomPadding - 100);
    } else {
      // Center on screen
      top = (screenSize.height - tooltipHeight) / 2;
    }

    return Positioned(
      top: top,
      left: left,
      right: right,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.9, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.surfaceVariant,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    stepText,
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Emoji and title
              Row(
                children: [
                  if (step.emoji != null) ...[
                    Text(
                      step.emoji!,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      step.title,
                      style: AppTypography.titleLarge.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                step.description,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // Buttons - use MainAxisAlignment instead of Spacer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side - Skip button or empty space
                  if (step.showSkip && !step.isLast)
                    TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        'Bỏ qua',
                        style: AppTypography.labelLarge.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 60),
                  
                  // Right side - Previous + Next buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onPrevious != null)
                        TextButton(
                          onPressed: onPrevious,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text(
                            'Quay lại',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      if (onPrevious != null) const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(100, 44),
                        ),
                        child: Text(
                          step.isLast ? 'Bắt đầu!' : 'Tiếp tục',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Spotlight overlay with animated pulse effect
class _SpotlightOverlay extends StatelessWidget {
  final Rect targetRect;
  final Animation<double> pulseAnimation;

  const _SpotlightOverlay({
    required this.targetRect,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        // Add padding to spotlight
        final padding = 12.0 * pulseAnimation.value;
        final spotlightRect = Rect.fromLTRB(
          targetRect.left - padding,
          targetRect.top - padding,
          targetRect.right + padding,
          targetRect.bottom + padding,
        );

        return CustomPaint(
          size: Size.infinite,
          painter: _SpotlightPainter(
            spotlightRect: spotlightRect,
            borderRadius: 16.0,
          ),
        );
      },
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect spotlightRect;
  final double borderRadius;

  _SpotlightPainter({
    required this.spotlightRect,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withAlpha(180);

    // Create path for the entire screen
    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create path for the spotlight cutout
    final spotlightPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        spotlightRect,
        Radius.circular(borderRadius),
      ));

    // Subtract spotlight from full screen
    final combinedPath = Path.combine(
      PathOperation.difference,
      fullPath,
      spotlightPath,
    );

    canvas.drawPath(combinedPath, paint);

    // Draw spotlight border
    final borderPaint = Paint()
      ..color = AppColors.primary.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        spotlightRect,
        Radius.circular(borderRadius),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return spotlightRect != oldDelegate.spotlightRect;
  }
}

